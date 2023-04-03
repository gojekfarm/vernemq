-module(vmq_redis_cluster_liveness).
-author("dhruvjain").

-behaviour(gen_server).

-include("vmq_server.hrl").

%% API functions
-export([start_link/0, is_node_alive/1]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-record(state, {shard, interval, timer}).

%%%===================================================================
%%% API functions
%%%===================================================================

start_link() ->
    gen_server:start_link(?MODULE, [], []).

is_node_alive(Node) ->
    ets:member(vmq_cluster_nodes, Node).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================
init([]) ->
    DefaultETSOpts = [public, named_table,
        {read_concurrency, true}],
    ets:new(vmq_cluster_nodes, DefaultETSOpts),
    SentinelEndpoints = vmq_schema_util:parse_list(application:get_env(vmq_server, redis_sentinel_endpoints, "[{\"127.0.0.1\", 26379}]")),
    RedisDB = application:get_env(vmq_server, redis_database, 0),
    {ok, _Pid} = eredis:start_link([{sentinel, [{endpoints, SentinelEndpoints}]}, {database, RedisDB}, {name, {local, redis_cluster_liveness_client}}]),

    LuaDir = application:get_env(vmq_server, redis_lua_dir, "./etc/lua"),
    {ok, GetLiveNodesScript} = file:read_file(LuaDir ++ "/get_live_nodes.lua"),
    {ok, <<"get_live_nodes">>} = vmq_redis:query(redis_cluster_liveness_client, [?FUNCTION, "LOAD", "REPLACE", GetLiveNodesScript], ?FUNCTION_LOAD, ?GET_LIVE_NODES),

    erlang:send_after(500, self(), probe_liveness),
    {ok, #state{}}.

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
    Reply = ok,
    {reply, Reply, State}.

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
handle_info(probe_liveness, State) ->
    case vmq_redis:query(redis_cluster_liveness_client, [?FCALL,
                              ?GET_LIVE_NODES,
                              0,
                              node()
                             ], ?FCALL, ?GET_LIVE_NODES) of
        {ok, LiveNodes} when is_list(LiveNodes) ->
            LiveNodesAtom = lists:foldr(fun(Node, Acc) ->
                                                NodeAtom = binary_to_atom(Node),
                                                ets:insert(vmq_cluster_nodes, {NodeAtom}),
                                                [NodeAtom | Acc] end,
                                        [], LiveNodes),
            lists:foreach(fun([{Node}]) -> case lists:member(Node, LiveNodesAtom) of
                                            false -> ets:delete(vmq_cluster_nodes, Node);
                                             _ -> ok
                                         end
                                         end, ets:match(vmq_cluster_nodes, '$1'));
        Res ->
            lager:error("~p", [Res]),
            ok
    end,
    erlang:send_after(500, self(), probe_liveness),
    {noreply, State};
handle_info(_Info, State) -> {noreply, State}.

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

