%% Copyright 2019 Octavo Labs AG Zurich Switzerland (http://octavolabs.com)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(vmq_message_store).
-include("vmq_server.hrl").
-export([
    start/0,
    stop/0,
    write/2,
    read/2,
    delete/1,
    delete/2,
    find/1
]).

start() ->
    {ok, Opts} = application:get_env(vmq_generic_offline_msg_store, msg_store_opts),

    Username = case proplists:get_value(username, Opts, undefined) of
                    undefined -> undefined;
                    User when is_atom(User) -> atom_to_list(User)
                end,
    Password = case proplists:get_value(password, Opts, undefined) of
                    undefined -> undefined;
                    Pass when is_atom(Pass) -> atom_to_list(Pass)
                end,
    {Database, _} = string:to_integer(proplists:get_value(database, Opts, "2")),
    Port = proplists:get_value(port, Opts, 26379),
    SentinelHosts = vmq_schema_util:parse_list(proplists:get_value(host, Opts, "[\"localhost\"]")),
    SentinelEndpoints = lists:foldr(fun(Host, Acc) -> [{Host, Port} | Acc]end, [], SentinelHosts),
    
    ConnectOpts = [{sentinel, [{endpoints, SentinelEndpoints},
                               {timeout, proplists:get_value(connect_timeout, Opts, 5000)}]
                    },
                   {username, Username},
                   {password, Password},
                   {database, Database},
                   {name, {local, vmq_offline_store_redis_client}}],
    eredis:start_link(ConnectOpts).

stop() ->
    eredis:stop(vmq_offline_store_redis_client).

write(SubscriberId, Msg) ->
    vmq_redis:query(vmq_offline_store_redis_client, ["RPUSH", term_to_binary(SubscriberId), term_to_binary(Msg)], ?RPUSH, ?MSG_STORE_WRITE).

read(_SubscriberId, _MsgRef) ->
    {error, not_supported}.

delete(SubscriberId) ->
    vmq_redis:query(vmq_offline_store_redis_client, ["DEL", term_to_binary(SubscriberId)], ?DEL, ?MSG_STORE_DELETE).

delete(SubscriberId, _MsgRef) ->
    vmq_redis:query(vmq_offline_store_redis_client, ["LPOP", term_to_binary(SubscriberId), 1], ?LPOP, ?MSG_STORE_DELETE).

find(SubscriberId) ->
    case vmq_redis:query(vmq_offline_store_redis_client, ["LRANGE", term_to_binary(SubscriberId), "0", "-1"], ?FIND, ?MSG_STORE_FIND) of
        {ok, MsgsInB} ->
            DMsgs = lists:foldr(fun(MsgB, Acc) ->
            Msg = binary_to_term(MsgB),
            D = #deliver{msg = Msg, qos = Msg#vmq_msg.qos},
            [D | Acc] end, [], MsgsInB),
            {ok, DMsgs};
        Res -> Res
    end.
