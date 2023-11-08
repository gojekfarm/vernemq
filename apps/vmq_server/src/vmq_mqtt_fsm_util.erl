%% Copyright 2018 Erlio GmbH Basel Switzerland (http://erl.io)
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

-module(vmq_mqtt_fsm_util).
-include("vmq_server.hrl").
-include_lib("vmq_commons/include/vmq_types.hrl").

-export([
    send/2,
    send_after/2,
    msg_ref/0,
    plugin_receive_loop/2,
    to_vmq_subtopics/2,
    peertoa/1,
    terminate_reason/1,
    terminate_proto_reason/1
]).

-define(TO_SESSION, to_session_fsm).

-spec msg_ref() -> msg_ref().
msg_ref() ->
    GUID =
        case get(guid) of
            undefined ->
                {{node(), self(), erlang:timestamp()}, 0};
            {S, I} ->
                {S, I + 1}
        end,
    put(guid, GUID),
    erlang:md5(term_to_binary(GUID)).

-spec send(pid(), any()) -> ok.
send(SessionPid, Msg) ->
    SessionPid ! {?TO_SESSION, Msg},
    ok.

-spec send_after(non_neg_integer(), any()) -> reference().
send_after(Time, Msg) ->
    erlang:send_after(Time, self(), {?TO_SESSION, Msg}).

-spec plugin_receive_loop(pid(), atom()) -> no_return().
plugin_receive_loop(PluginPid, PluginMod) ->
    receive
        {?TO_SESSION, {mail, QPid, new_data}} ->
            vmq_queue:active(QPid),
            plugin_receive_loop(PluginPid, PluginMod);
        {?TO_SESSION, {mail, QPid, Msgs, _, _}} ->
            lists:foreach(
                fun
                    (
                        #deliver{
                            qos = QoS,
                            msg = #vmq_msg{
                                routing_key = RoutingKey,
                                payload = Payload,
                                retain = IsRetain,
                                dup = IsDup
                            }
                        }
                    ) ->
                        PluginPid ! {deliver, RoutingKey, Payload, QoS, IsRetain, IsDup};
                    (Msg) ->
                        lager:warning("dropped message ~p for plugin ~p", [Msg, PluginMod]),
                        ok
                end,
                Msgs
            ),
            vmq_queue:notify(QPid),
            plugin_receive_loop(PluginPid, PluginMod);
        {?TO_SESSION, {info_req, {Ref, CallerPid}, _}} ->
            CallerPid ! {Ref, {error, i_am_a_plugin}},
            plugin_receive_loop(PluginPid, PluginMod);
        disconnect ->
            ok;
        {'DOWN', _MRef, process, PluginPid, Reason} ->
            case (Reason == normal) or (Reason == shutdown) of
                true ->
                    ok;
                false ->
                    lager:warning("plugin queue loop for ~p stopped due to ~p", [PluginMod, Reason])
            end;
        Other ->
            exit({unknown_msg_in_plugin_loop, Other})
    end.

-spec to_vmq_subtopics(
    [mqtt5_subscribe_topic() | mqtt_subscribe_topic()], subscription_id() | undefined
) -> [subscription()].
to_vmq_subtopics(Topics, SubId) ->
    lists:map(
        fun
            ({T, QoS}) ->
                {T, QoS};
            (
                #mqtt_subscribe_topic{
                    topic = T, qos = QoS, non_persistence = NonPersistence, non_retry = Retry
                }
            ) ->
                %% MQTTv4 style topics
                SubOpts = #{non_persistence => NonPersistence, non_retry => Retry},
                {T, {QoS, SubOpts}};
            (
                #mqtt5_subscribe_topic{
                    topic = T, qos = QoS, rap = Rap, retain_handling = RH, no_local = NL
                }
            ) ->
                SubOpts = #{rap => Rap, retain_handling => RH, no_local => NL},
                case SubId of
                    undefined ->
                        {T, {QoS, SubOpts}};
                    _ ->
                        {T, {QoS, SubOpts#{sub_id => SubId}}}
                end
        end,
        Topics
    ).

-spec peertoa(peer()) -> string().
peertoa({IP, Port}) ->
    case IP of
        {_, _, _, _} ->
            io_lib:format("~s:~p", [inet:ntoa(IP), Port]);
        {_, _, _, _, _, _, _, _} ->
            io_lib:format("[~s]:~p", [inet:ntoa(IP), Port])
    end.

-spec terminate_reason(any()) -> any().
terminate_reason(?ADMINISTRATIVE_ACTION) -> normal;
terminate_reason(?CLIENT_DISCONNECT) -> normal;
terminate_reason(?DISCONNECT_KEEP_ALIVE) -> normal;
terminate_reason(?DISCONNECT_MIGRATION) -> normal;
terminate_reason(?NORMAL_DISCONNECT) -> normal;
terminate_reason(?SESSION_TAKEN_OVER) -> normal;
terminate_reason(?REMOTE_SESSION_TAKEN_OVER) -> normal;
terminate_reason(?INVALID_PUBREC_ERROR) -> normal;
terminate_reason(?INVALID_PUBCOMP_ERROR) -> normal;
terminate_reason(Reason) -> Reason.

-spec terminate_proto_reason(any()) -> any().
terminate_proto_reason(Reason) ->
    case Reason of
        not_authorized -> 'REASON_NOT_AUTHORIZED';
        normal_disconnect -> 'REASON_NORMAL_DISCONNECT';
        session_taken_over -> 'REASON_SESSION_TAKEN_OVER';
        administrative_action -> 'REASON_ADMINISTRATIVE_ACTION';
        disconnect_keep_alive -> 'REASON_DISCONNECT_KEEP_ALIVE';
        disconnect_migration -> 'REASON_DISCONNECT_MIGRATION';
        bad_authentication_method -> 'REASON_BAD_AUTHENTICATION_METHOD';
        remote_session_taken_over -> 'REASON_REMOTE_SESSION_TAKEN_OVER';
        mqtt_client_disconnect -> 'REASON_MQTT_CLIENT_DISCONNECT';
        receive_max_exceeded -> 'REASON_RECEIVE_MAX_EXCEEDED';
        protocol_error -> 'REASON_PROTOCOL_ERROR';
        publish_not_authorized_3_1_1 -> 'REASON_PUBLISH_AUTH_ERROR';
        invalid_pubrec_error -> 'REASON_INVALID_PUBREC_ERROR';
        invalid_pubcomp_error -> 'REASON_INVALID_PUBCOMP_ERROR';
        unexpected_frame_type -> 'REASON_UNEXPECTED_FRAME_TYPE';
        exit_signal_recived -> 'REASON_EXIT_SIGNAL_RECIVED';
        tcp_closed -> 'REASON_TCP_CLOSED';
        normal -> 'REASON_NORMAL_DISCONNECT';
        _ -> 'REASON_UNSPECIFIED'
    end.
