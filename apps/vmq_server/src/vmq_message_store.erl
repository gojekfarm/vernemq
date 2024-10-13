-module(vmq_message_store).

-behaviour(supervisor).

-include("vmq_server.hrl").

%% Supervisor callbacks
-export([init/1]).

%% API
-export([
    start/0,
    write/2,
    read/2,
    delete/1,
    delete/2,
    find/1
]).

start() ->
    Ret = supervisor:start_link({local, ?MODULE}, ?MODULE, []),
    load_redis_functions(),
    Ret.

load_redis_functions() ->
    LuaDir = application:get_env(vmq_server, redis_lua_dir, "./etc/lua"),

    {ok, PopOfflineMessageScript} = file:read_file(LuaDir ++ "/pop_offline_message.lua"),
    {ok, WriteOfflineMessageScript} = file:read_file(LuaDir ++ "/write_offline_message.lua"),
    {ok, DeleteSubsOfflineMessagesScript} = file:read_file(LuaDir ++ "/delete_subs_offline_messages.lua"),

    {ok, <<"pop_offline_message">>} = vmq_redis:query(
        vmq_message_store_redis_client,
        [?FUNCTION, "LOAD", "REPLACE", PopOfflineMessageScript],
        ?FUNCTION_LOAD,
        ?POP_OFFLINE_MESSAGE
    ),
    {ok, <<"write_offline_message">>} = vmq_redis:query(
        vmq_message_store_redis_client,
        [?FUNCTION, "LOAD", "REPLACE", WriteOfflineMessageScript],
        ?FUNCTION_LOAD,
        ?WRITE_OFFLINE_MESSAGE
    ),
    {ok, <<"delete_subs_offline_messages">>} = vmq_redis:query(
        vmq_message_store_redis_client,
        [?FUNCTION, "LOAD", "REPLACE", DeleteSubsOfflineMessagesScript],
        ?FUNCTION_LOAD,
        ?DELETE_SUBS_OFFLINE_MESSAGES
    ).

write(SubscriberId, Msg) ->
    %  TODO: Handle the return value(errors & negative) to generate offline messages metrics
    vmq_redis:query(
        vmq_message_store_redis_client,
        [
            ?FCALL,
            ?WRITE_OFFLINE_MESSAGE,
            1,
            term_to_binary(SubscriberId), 
            term_to_binary(Msg)
        ],
        ?FCALL,
        ?WRITE_OFFLINE_MESSAGE
    ).

read(_SubscriberId, _MsgRef) ->
    {error, not_supported}.

delete(SubscriberId) ->
    %  TODO: Handle the return value(errors & negatives) to generate offline messages metrics
    vmq_redis:query(
        vmq_message_store_redis_client,
        [
            ?FCALL,
            ?DELETE_SUBS_OFFLINE_MESSAGES,
            1,
            term_to_binary(SubscriberId)
        ],
        ?FCALL,
        ?DELETE_SUBS_OFFLINE_MESSAGES
    ).

delete(SubscriberId, _MsgRef) ->
    %  TODO: Handle the return value(errors & negatives) to generate offline messages metrics
    vmq_redis:query(
        vmq_message_store_redis_client,
        [
            ?FCALL,
            ?POP_OFFLINE_MESSAGE,
            1,
            term_to_binary(SubscriberId)
        ],
        ?FCALL,
        ?POP_OFFLINE_MESSAGE
    ).

find(SubscriberId) ->
    case
        vmq_redis:query(
            vmq_message_store_redis_client,
            ["LRANGE", term_to_binary(SubscriberId), "0", "-1"],
            ?FIND,
            ?MSG_STORE_FIND
        )
    of
        {ok, MsgsInB} ->
            DMsgs = lists:foldr(
                fun(MsgB, Acc) ->
                    Msg = binary_to_term(MsgB),
                    D = #deliver{msg = Msg, qos = Msg#vmq_msg.qos},
                    [D | Acc]
                end,
                [],
                MsgsInB
            ),
            {ok, DMsgs};
        Res ->
            Res
    end.

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

-spec init([]) ->
    {'ok',
        {{'one_for_one', 5, 10}, [
            {atom(), {atom(), atom(), list()}, permanent, pos_integer(), worker, [atom()]}
        ]}}.
init([]) ->
    StoreCfgs = application:get_env(vmq_server, message_store, [
        {redis, [
            {connect_options, "[{sentinel, [{endpoints, [{\"localhost\", 26379}]}]},{database,2}]"}
        ]}
    ]),
    Redis = proplists:get_value(redis, StoreCfgs),
    Username =
        case proplists:get_value(username, Redis, undefined) of
            undefined -> undefined;
            User when is_atom(User) -> atom_to_list(User)
        end,
    Password =
        case proplists:get_value(password, Redis, undefined) of
            undefined -> undefined;
            Pass when is_atom(Pass) -> atom_to_list(Pass)
        end,

    {ok,
        {{one_for_one, 5, 10}, [
            {eredis,
                {eredis, start_link, [
                    [
                        {username, Username},
                        {password, Password},
                        {name, {local, vmq_message_store_redis_client}}
                        | vmq_schema_util:parse_list(proplists:get_value(connect_options, Redis))
                    ]
                ]},
                permanent, 5000, worker, [eredis]}
        ]}}.
