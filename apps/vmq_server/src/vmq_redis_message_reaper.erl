-module(vmq_redis_message_reaper).
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
init([]) -> {ok, #state{}}.

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
handle_info({reap_messages, DeadNode}, State) ->
    MainQueue = "mainQueue::"++ atom_to_list(DeadNode),
    case vmq_redis:query(redis_queue_consumer_client_0, [?FCALL,
        ?POLL_MAIN_QUEUE,
        1,
        MainQueue,
        50
    ], ?FCALL, ?POLL_MAIN_QUEUE) of
        {ok, undefined} ->
            vmq_redis_queue_reaper ! {reap_queues, DeadNode};
        {ok, Msgs} ->
            lists:foreach(
                fun([SubBin, MsgBin, TimeInQueue]) ->
                    vmq_metrics:pretimed_measurement(
                        {?MODULE, time_spent_in_main_queue},
                        binary_to_integer(TimeInQueue)
                    ),
                    case binary_to_term(SubBin) of
                        {_, _CId} = SId ->
                            ok = vmq_reg:register_subscriber_(undefined, SId, false, #{}, 10),
                            {SubInfo, Msg} = binary_to_term(MsgBin),
                            vmq_reg:enqueue_msg({SId, SubInfo}, Msg);
                        RandSubs when is_list(RandSubs) ->
                            vmq_shared_subscriptions:publish_to_group(binary_to_term(MsgBin),
                                RandSubs,
                                {0,0});
                        UnknownMsg -> lager:error("Unknown Msg in Redis Main Queue : ~p", [UnknownMsg])
                    end
                end,
                Msgs
            ),
            erlang:send_after(0, self(), {reap_messages, DeadNode});
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

