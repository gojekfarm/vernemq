-module(vmq_redis_queue_reaper).
-author("dhruvjain").

-behaviour(gen_server).

-include("vmq_server.hrl").

%% API functions
-export([start_link/0]).

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
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================
init([]) ->
    SentinelEndpoints = vmq_schema_util:parse_list(application:get_env(vmq_server, redis_sentinel_endpoints, "[{\"127.0.0.1\", 26379}]")),
    RedisDB = application:get_env(vmq_server, redis_database, 0),
    {ok, _Pid} = eredis:start_link([{sentinel, [{endpoints, SentinelEndpoints}]}, {database, RedisDB}, {name, {local, redis_queue_reaper_client}}]),

    LuaDir = application:get_env(vmq_server, redis_lua_dir, "./etc/lua"),
    {ok, QueueReaperScript} = file:read_file(LuaDir ++ "/reap_queues.lua"),
    {ok, <<"reap_queues">>} = vmq_redis:query(redis_queue_reaper_client, [?FUNCTION, "LOAD", "REPLACE", QueueReaperScript], ?FUNCTION_LOAD, ?REAP_QUEUES),

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
handle_info({reap_queues, DeadNode}, State) ->
    case vmq_redis:query(redis_queue_reaper_client, [?FCALL,
                              ?REAP_QUEUES,
                              1,
                              DeadNode,
                              node()
                             ], ?FCALL, ?REAP_QUEUES) of
        {ok, ClientList} when is_list(ClientList) ->
            lager:info("~p", [ClientList]),
            lists:foreach(fun([MP, ClientId]) ->
                                SubscriberId = {binary_to_list(MP), ClientId},
                                lager:info("~p", [SubscriberId]),
                                {ok, QueuePresent, QPid} = vmq_queue_sup_sup:start_queue(SubscriberId, false),
                                case QueuePresent of
                                    true -> ok;
                                    false -> vmq_queue:init_offline_queue(QPid)
                                end
                          end, ClientList),
            erlang:send_after(100, self(), {reap_queues, DeadNode});
        {ok, undefined} ->
            ok;
        Res ->
            lager:error("~p", [Res]),
            ok
    end,
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

