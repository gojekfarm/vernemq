%%%-------------------------------------------------------------------
%%% @author dhruvjain
%%% @copyright (C) 2022, Gojek
%%% @doc
%%%
%%% @end
%%% Created : 21. Apr 2022 12:44 PM
%%%-------------------------------------------------------------------
-module(vmq_reg_redis_trie).

-include("vmq_server.hrl").

-behaviour(vmq_reg_view).
-behaviour(gen_server2).

%% API
-export([
    start_link/0,
    fold/4,
    add_complex_topics/1,
    add_complex_topic/2,
    delete_complex_topics/1,
    delete_complex_topic/2,
    get_complex_topics/0,
    safe_rpc/4
]).
%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-record(state, {status = init}).
-record(trie, {edge, node_id}).
-record(trie_edge, {node_id, word}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server2:start_link({local, ?MODULE}, ?MODULE, [], []).

-spec fold(subscriber_id(), topic(), fun(), any()) -> any().
fold({MP, _} = SubscriberId, Topic, FoldFun, Acc) when is_list(Topic) ->
    MatchedTopics = [Topic | match(MP, Topic)],
    case fold_matched_topics(MP, MatchedTopics, []) of
        [] ->
            case fetchSubscribers(MatchedTopics, MP) of
                {error, _} = Err -> Err;
                SubscribersList -> fold_subscriber_info(SubscriberId, SubscribersList, FoldFun, Acc)
            end;
        LocalSharedSubsList ->
            fold_local_shared_subscriber_info(
                SubscriberId, lists:flatten(LocalSharedSubsList), FoldFun, Acc
            )
    end.

fold_matched_topics(_MP, [], Acc) ->
    Acc;
fold_matched_topics(MP, [Topic | Rest], Acc) ->
    Key = {MP, Topic},
    Res = ets:select(?SHARED_SUBS_ETS_TABLE, [{{{Key, '$1'}}, [], ['$$']}]),
    case Res of
        [] ->
            vmq_metrics:incr_cache_miss(?LOCAL_SHARED_SUBS),
            fold_matched_topics(MP, Rest, Acc);
        SharedSubsWithInfo ->
            vmq_metrics:incr_cache_hit(?LOCAL_SHARED_SUBS),
            fold_matched_topics(MP, Rest, [lists:flatten(SharedSubsWithInfo) | Acc])
    end.

fetchSubscribers(Topics, MP) ->
    UnwordedTopics = [vmq_topic:unword(T) || T <- Topics],
    case
        vmq_redis:query(
            vmq_redis_client,
            [
                ?FCALL,
                ?FETCH_MATCHED_TOPIC_SUBSCRIBERS,
                0,
                MP,
                length(UnwordedTopics)
                | UnwordedTopics
            ],
            ?FCALL,
            ?FETCH_MATCHED_TOPIC_SUBSCRIBERS
        )
    of
        {ok, SubscribersList} -> SubscribersList;
        Err -> Err
    end.

fold_subscriber_info(_, [], _, Acc) ->
    Acc;
fold_subscriber_info({MP, _} = SubscriberId, [SubscriberInfoList | Rest], FoldFun, Acc) ->
    case SubscriberInfoList of
        [NodeBinary, ClientId, QoSBinary] ->
            SubscriberInfo = {
                binary_to_atom(NodeBinary), {MP, ClientId}, binary_to_term(QoSBinary)
            },
            fold_subscriber_info(
                SubscriberId, Rest, FoldFun, FoldFun(SubscriberInfo, SubscriberId, Acc)
            );
        [NodeBinary, Group, ClientId, QoSBinary] ->
            SubscriberInfo = {
                binary_to_atom(NodeBinary), Group, {MP, ClientId}, binary_to_term(QoSBinary)
            },
            fold_subscriber_info(
                SubscriberId, Rest, FoldFun, FoldFun(SubscriberInfo, SubscriberId, Acc)
            );
        _ ->
            fold_subscriber_info(SubscriberId, Rest, FoldFun, Acc)
    end.

fold_local_shared_subscriber_info(_, [], _, Acc) ->
    Acc;
fold_local_shared_subscriber_info(
    {MP, _} = SubscriberId, [{ClientId, QoS} | SubscribersList], FoldFun, Acc
) ->
    SubscriberInfo = {node(), 'constant_group', {MP, ClientId}, QoS},
    fold_local_shared_subscriber_info(
        SubscriberId, SubscribersList, FoldFun, FoldFun(SubscriberInfo, SubscriberId, Acc)
    ).

add_complex_topics(Topics) ->
    Nodes = vmq_cluster_mon:nodes(),
    Query = lists:foldl(
        fun(T, Acc) ->
            lists:foreach(
                fun(Node) -> safe_rpc(Node, ?MODULE, add_complex_topic, ["", T]) end, Nodes
            ),
            [[?SADD, "wildcard_topics", term_to_binary(T)] | Acc]
        end,
        [],
        Topics
    ),
    vmq_redis:pipelined_query(vmq_redis_client, Query, ?ADD_COMPLEX_TOPICS_OPERATION),
    ok.

add_complex_topic(MP, Topic) ->
    MPTopic = {MP, Topic},
    case ets:lookup(vmq_redis_trie_node, MPTopic) of
        [TrieNode = #trie_node{topic = undefined}] ->
            ets:insert(vmq_redis_trie_node, TrieNode#trie_node{topic = Topic});
        [#trie_node{topic = _Topic}] ->
            ignore;
        _ ->
            %% add trie path
            _ = [trie_add_path(MP, Triple) || Triple <- vmq_topic:triples(Topic)],
            %% add last node
            ets:insert(vmq_redis_trie_node, #trie_node{node_id = MPTopic, topic = Topic})
    end.

delete_complex_topics(Topics) ->
    Nodes = vmq_cluster_mon:nodes(),
    Query = lists:foldl(
        fun(T, Acc) ->
            lists:foreach(
                fun(Node) -> safe_rpc(Node, ?MODULE, delete_complex_topic, ["", T]) end, Nodes
            ),
            Acc ++ [[?SREM, "wildcard_topics", term_to_binary(T)]]
        end,
        [],
        Topics
    ),
    vmq_redis:pipelined_query(vmq_redis_client, Query, ?DELETE_COMPLEX_TOPICS_OPERATION),
    ok.

delete_complex_topic(MP, Topic) ->
    NodeId = {MP, Topic},
    case ets:lookup(vmq_redis_trie_node, NodeId) of
        [#trie_node{topic = undefined}] ->
            ok;
        [TrieNode = #trie_node{edge_count = EdgeCount}] ->
            case EdgeCount > 1 of
                true ->
                    ets:insert(vmq_redis_trie_node, TrieNode#trie_node{topic = undefined});
                false ->
                    ets:delete(vmq_redis_trie_node, NodeId),
                    trie_delete_path(MP, lists:reverse(vmq_topic:triples(Topic)))
            end;
        _ ->
            ignore
    end.

get_complex_topics() ->
    [
        vmq_topic:unword(T)
     || T <- ets:select(vmq_redis_trie_node, [
            {
                #trie_node{
                    node_id = {"", '$1'}, topic = '$1', edge_count = '_'
                },
                [{'=/=', '$1', undefined}],
                ['$1']
            }
        ])
    ].

-spec safe_rpc(Node :: node(), Mod :: module(), Fun :: atom(), [any()]) -> any().
safe_rpc(Node, Module, Fun, Args) ->
    try rpc:call(Node, Module, Fun, Args) of
        Result ->
            Result
    catch
        exit:{noproc, _NoProcDetails} ->
            {badrpc, rpc_process_down};
        Type:Reason ->
            {Type, Reason}
    end.

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    DefaultETSOpts = [
        public,
        named_table,
        {read_concurrency, true}
    ],
    _ = ets:new(?SHARED_SUBS_ETS_TABLE, DefaultETSOpts),
    _ = ets:new(vmq_redis_trie, [{keypos, 2} | DefaultETSOpts]),
    _ = ets:new(vmq_redis_trie_node, [{keypos, 2} | DefaultETSOpts]),

    initialize_trie(),

    {ok, #state{status = ready}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
initialize_trie() ->
    {ok, TopicList} = vmq_redis:query(
        vmq_redis_client, [?SMEMBERS, "wildcard_topics"], ?SMEMBERS, ?INITIALIZE_TRIE_OPERATION
    ),
    lists:foreach(
        fun(T) ->
            Topic = binary_to_term(T),
            add_complex_topic("", Topic)
        end,
        TopicList
    ),
    ok.

match(MP, Topic) when is_list(MP) and is_list(Topic) ->
    TrieNodes = trie_match(MP, Topic),
    match(MP, Topic, TrieNodes, []).

%% [MQTT-4.7.2-1] The Server MUST NOT match Topic Filters starting with a
%% wildcard character (# or +) with Topic Names beginning with a $ character.
match(MP, [<<"$", _/binary>> | _] = Topic, [#trie_node{topic = [<<"#">>]} | Rest], Acc) ->
    match(MP, Topic, Rest, Acc);
match(MP, [<<"$", _/binary>> | _] = Topic, [#trie_node{topic = [<<"+">> | _]} | Rest], Acc) ->
    match(MP, Topic, Rest, Acc);
match(MP, Topic, [#trie_node{topic = Name} | Rest], Acc) when Name =/= undefined ->
    match(MP, Topic, Rest, [Name | Acc]);
match(MP, Topic, [_ | Rest], Acc) ->
    match(MP, Topic, Rest, Acc);
match(_, _, [], Acc) ->
    Acc.

trie_add_path(MP, {Node, Word, Child}) ->
    NodeId = {MP, Node},
    Edge = #trie_edge{node_id = NodeId, word = Word},
    case ets:lookup(vmq_redis_trie_node, NodeId) of
        [TrieNode = #trie_node{edge_count = Count}] ->
            case ets:lookup(vmq_redis_trie, Edge) of
                [] ->
                    ets:insert(
                        vmq_redis_trie_node,
                        TrieNode#trie_node{edge_count = Count + 1}
                    ),
                    ets:insert(vmq_redis_trie, #trie{edge = Edge, node_id = Child});
                [_] ->
                    ok
            end;
        [] ->
            ets:insert(vmq_redis_trie_node, #trie_node{node_id = NodeId, edge_count = 1}),
            ets:insert(vmq_redis_trie, #trie{edge = Edge, node_id = Child})
    end.

trie_match(MP, Words) ->
    trie_match(MP, root, Words, []).

trie_match(MP, Node, [], ResAcc) ->
    NodeId = {MP, Node},
    ets:lookup(vmq_redis_trie_node, NodeId) ++ 'trie_match_#'(NodeId, ResAcc);
trie_match(MP, Node, [W | Words], ResAcc) ->
    NodeId = {MP, Node},
    lists:foldl(
        fun(WArg, Acc) ->
            case
                ets:lookup(
                    vmq_redis_trie,
                    #trie_edge{node_id = NodeId, word = WArg}
                )
            of
                [#trie{node_id = ChildId}] ->
                    trie_match(MP, ChildId, Words, Acc);
                [] ->
                    Acc
            end
        end,
        'trie_match_#'(NodeId, ResAcc),
        [W, <<"+">>]
    ).

'trie_match_#'({MP, _} = NodeId, ResAcc) ->
    case ets:lookup(vmq_redis_trie, #trie_edge{node_id = NodeId, word = <<"#">>}) of
        [#trie{node_id = ChildId}] ->
            ets:lookup(vmq_redis_trie_node, {MP, ChildId}) ++ ResAcc;
        [] ->
            ResAcc
    end.

trie_delete_path(_, []) ->
    ok;
trie_delete_path(MP, [{Node, Word, _} | RestPath]) ->
    NodeId = {MP, Node},
    Edge = #trie_edge{node_id = NodeId, word = Word},
    ets:delete(vmq_redis_trie, Edge),
    case ets:lookup(vmq_redis_trie_node, NodeId) of
        [TrieNode = #trie_node{edge_count = EdgeCount}] ->
            case EdgeCount > 1 of
                true ->
                    ets:insert(
                        vmq_redis_trie_node,
                        TrieNode#trie_node{edge_count = EdgeCount - 1}
                    );
                false ->
                    ets:delete(vmq_redis_trie_node, NodeId),
                    trie_delete_path(MP, RestPath)
            end;
        [] ->
            ignore
    end.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
%%%%%%%%%%%%%
%%% Tests
%%%%%%%%%%%%%

complex_acl_test_() ->
    [
        {"Complex ACL Test - Add complex topic",
            {setup, fun setup_vmq_reg_redis_trie/0, fun teardown/1, fun add_complex_acl_test/1}},
        {"Complex ACL Test - Delete complex topic",
            {setup, fun setup_vmq_reg_redis_trie/0, fun teardown/1, fun delete_complex_acl_test/1}},
        {"Complex ACL Test - Sub-topic whitelisting",
            {setup, fun setup_vmq_reg_redis_trie/0, fun teardown/1, fun subtopic_subscribe_test/1}},
        {"Complex ACL Test - Get individual complex topics",
            {setup, fun setup_vmq_reg_redis_trie/0, fun teardown/1, fun get_complex_topics_test/1}}
    ].

setup_vmq_reg_redis_trie() ->
    TABLE_OPTS = [public, named_table, {read_concurrency, true}],
    ok = application:set_env(vmq_enhanced_auth, enable_acl_hooks, true),
    ok = application:set_env(vmq_server, default_reg_view, vmq_reg_redis_trie),
    vmq_enhanced_auth:init(),
    ets:new(topic_labels, [named_table, public, {write_concurrency, true}]),
    ets:new(vmq_redis_trie_node, [{keypos, 2} | TABLE_OPTS]),
    ets:new(vmq_redis_trie, [{keypos, 2} | TABLE_OPTS]),
    vmq_reg_redis_trie.

teardown(RegView) ->
    case RegView of
        vmq_reg_redis_trie ->
            ets:delete(vmq_redis_trie),
            ets:delete(vmq_redis_trie_node);
        _ ->
            ok
    end,
    ets:delete(vmq_enhanced_auth_acl_read_all),
    ets:delete(vmq_enhanced_auth_acl_write_all),
    ets:delete(vmq_enhanced_auth_acl_read_user),
    ets:delete(vmq_enhanced_auth_acl_write_user),
    ets:delete(topic_labels),
    application:unset_env(vmq_enhanced_auth, enable_acl_hooks),
    application:unset_env(vmq_server, default_reg_view).

add_complex_acl_test(_) ->
    ACL = [<<"topic abc/xyz/# label complex_topic\n">>],
    vmq_enhanced_auth:load_from_list(ACL),
    Topic1 = [<<"abc">>, <<"xyz">>, <<"+">>, <<"1">>],
    Topic2 = [<<"abc">>, <<"xyz">>, <<"+">>, <<"2">>],
    add_complex_topic("", Topic1),
    add_complex_topic("", Topic2),
    [
        ?_assertEqual(
            {ok, [
                {Topic1, 0, {matched_acl, <<"complex_topic">>, <<"abc/xyz/#">>}}
            ]},
            vmq_enhanced_auth:auth_on_subscribe(
                <<"test">>,
                {"", <<"my-client-id">>},
                [
                    {Topic1, 0}
                ]
            )
        ),
        ?_assertEqual(
            {ok, [
                {Topic2, 0, {matched_acl, <<"complex_topic">>, <<"abc/xyz/#">>}}
            ]},
            vmq_enhanced_auth:auth_on_subscribe(
                <<"test">>,
                {"", <<"my-client-id">>},
                [
                    {Topic2, 0}
                ]
            )
        )
    ].
delete_complex_acl_test(_) ->
    ACL = [<<"topic abc/xyz/# label complex_topic\n">>],
    vmq_enhanced_auth:load_from_list(ACL),
    Topic1 = [<<"abc">>, <<"xyz">>, <<"+">>, <<"1">>],
    Topic2 = [<<"abc">>, <<"xyz">>, <<"+">>, <<"2">>],
    SubTopic = [<<"abc">>, <<"xyz">>, <<"+">>],
    add_complex_topic("", Topic1),
    add_complex_topic("", Topic2),
    delete_complex_topic("", Topic1),
    delete_complex_topic("", SubTopic),
    [
        ?_assertEqual(
            next,
            vmq_enhanced_auth:auth_on_subscribe(
                <<"test">>,
                {"", <<"my-client-id">>},
                [
                    {Topic1, 0}
                ]
            )
        ),
        ?_assertEqual(
            {ok, [
                {Topic2, 0, {matched_acl, <<"complex_topic">>, <<"abc/xyz/#">>}}
            ]},
            vmq_enhanced_auth:auth_on_subscribe(
                <<"test">>,
                {"", <<"my-client-id">>},
                [
                    {Topic2, 0}
                ]
            )
        )
    ].
subtopic_subscribe_test(_) ->
    ACL = [<<"topic abc/xyz/# label complex_topic\n">>],
    vmq_enhanced_auth:load_from_list(ACL),
    Topic = [<<"abc">>, <<"xyz">>, <<"+">>, <<"1">>, <<"+">>],
    SubTopic1 = [<<"abc">>, <<"xyz">>, <<"+">>, <<"1">>],
    SubTopic2 = [<<"abc">>, <<"xyz">>, <<"+">>],
    add_complex_topic("", Topic),
    add_complex_topic("", SubTopic1),
    [
        ?_assertEqual(
            {ok, [
                {Topic, 0, {matched_acl, <<"complex_topic">>, <<"abc/xyz/#">>}}
            ]},
            vmq_enhanced_auth:auth_on_subscribe(
                <<"test">>,
                {"", <<"my-client-id">>},
                [
                    {Topic, 0}
                ]
            )
        ),
        ?_assertEqual(
            {ok, [
                {SubTopic1, 0, {matched_acl, <<"complex_topic">>, <<"abc/xyz/#">>}}
            ]},
            vmq_enhanced_auth:auth_on_subscribe(
                <<"test">>,
                {"", <<"my-client-id">>},
                [
                    {SubTopic1, 0}
                ]
            )
        ),
        ?_assertEqual(
            next,
            vmq_enhanced_auth:auth_on_subscribe(
                <<"test">>,
                {"", <<"my-client-id">>},
                [
                    {SubTopic2, 0}
                ]
            )
        )
    ].
get_complex_topics_test(_) ->
    ACL = [<<"topic abc/xyz/# label complex_topic\n">>],
    vmq_enhanced_auth:load_from_list(ACL),
    Topic1 = [<<"abc">>, <<"xyz">>, <<"+">>, <<"1">>, <<"+">>],
    Topic2 = [<<"abc">>, <<"xyz">>, <<"+">>, <<"2">>],
    SubTopic1 = [<<"abc">>, <<"xyz">>, <<"+">>, <<"1">>],
    add_complex_topic("", Topic1),
    add_complex_topic("", Topic2),
    add_complex_topic("", SubTopic1),
    [
        ?_assertEqual(
            [
                [<<"abc/xyz/+/1/+">>],
                [<<"abc/xyz/+/1">>],
                [<<"abc/xyz/+/2">>]
            ],
            [
                [iolist_to_binary((Topic))]
             || Topic <- get_complex_topics()
            ]
        )
    ].
-endif.
