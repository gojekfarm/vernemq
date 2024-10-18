-ifndef(VMQ_SERVER_HRL).
-define(VMQ_SERVER_HRL, true).
-include_lib("vmq_commons/include/vmq_types.hrl").

-type plugin_id() :: {plugin, atom(), pid()}.

-record(retain_msg, {
    payload :: binary(),
    properties :: any(),
    expiry_ts ::
        undefined
        | msg_expiry_ts()
}).
-type retain_msg() :: #retain_msg{}.

-type deliver() :: #deliver{}.

-type subscription() :: {topic(), subinfo()}.
-define(INTERNAL_CLIENT_ID, '$vmq_internal_client_id').

-record(trie_node, {node_id, edge_count = 0, topic}).

%% These reason codes are used internally within vernemq and are not
%% *real* MQTT reason codes.
-define(DISCONNECT_KEEP_ALIVE, disconnect_keep_alive).
-define(DISCONNECT_MIGRATION, disconnect_migration).
-define(CLIENT_DISCONNECT, mqtt_client_disconnect).

-type disconnect_reasons() ::
    ?NOT_AUTHORIZED
    | ?NORMAL_DISCONNECT
    | ?SESSION_TAKEN_OVER
    | ?ADMINISTRATIVE_ACTION
    | ?DISCONNECT_KEEP_ALIVE
    | ?DISCONNECT_MIGRATION
    | ?BAD_AUTHENTICATION_METHOD
    | ?PROTOCOL_ERROR
    | ?RECEIVE_MAX_EXCEEDED
    | ?CLIENT_DISCONNECT.

-type duration_ms() :: non_neg_integer().
-type session_ctrl() :: #{throttle => duration_ms()}.
-type aop_success_fun() :: fun(
    (msg(), list(), session_ctrl()) ->
        {ok, msg()}
        | {ok, msg(), session_ctrl()}
        | {error, atom()}
).

-type reg_view_fold_fun() :: fun(
    (node() | {subscriber_id(), qos(), client_id() | any()}, any()) -> any()
).

-define(SADD, sadd).
-define(SREM, srem).
-define(SMEMBERS, smembers).
-define(PIPELINE, pipeline).
-define(FUNCTION, function).
-define(FUNCTION_LOAD, 'function:load').
-define(FCALL, fcall).
-define(REMAP_SUBSCRIBER, remap_subscriber).
-define(SUBSCRIBE, subscribe).
-define(UNSUBSCRIBE, unsubscribe).
-define(DELETE_SUBSCRIBER, delete_subscriber).
-define(FETCH_SUBSCRIBER, fetch_subscriber).
-define(FETCH_MATCHED_TOPIC_SUBSCRIBERS, fetch_matched_topic_subscribers).
-define(ENQUEUE_MSG, enqueue_msg).
-define(POLL_MAIN_QUEUE, poll_main_queue).
-define(GET_LIVE_NODES, get_live_nodes).
-define(RPUSH, rpush).
-define(DEL, del).
-define(FIND, find).
-define(LPOP, lpop).
-define(MSG_STORE_WRITE, msg_store_write).
-define(MSG_STORE_DELETE, msg_store_delete).
-define(MSG_STORE_FIND, msg_store_find).
-define(SHARED_SUBS_ETS_TABLE, vmq_shared_subs_local).
-define(LOCAL_SHARED_SUBS, local_shared_subs).
-define(MIGRATE_OFFLINE_QUEUE, migrate_offline_queue).
-define(REAP_SUBSCRIBERS, reap_subscribers).
-define(SCARD, scard).
-define(ENSURE_NO_LOCAL_CLIENT, ensure_no_local_client).
-define(WRITE_OFFLINE_MESSAGE, write_offline_message).
-define(POP_OFFLINE_MESSAGE, pop_offline_message).
-define(DELETE_SUBS_OFFLINE_MESSAGES, delete_subs_offline_messages).

-define(PRODUCER, "producer").
-define(CONSUMER, "consumer").

-define(REMOTE_SESSION_TAKEN_OVER, remote_session_taken_over).
-define(INVALID_PUBREC_ERROR, invalid_pubrec_error).
-define(INVALID_PUBCOMP_ERROR, invalid_pubcomp_error).
-define(PUBLISH_AUTH_ERROR, publish_not_authorized_3_1_1).
-define(TCP_CLOSED, tcp_closed).
-define(EXIT_SIGNAL_RECEIVED, exit_signal_received).
-define(UNEXPECTED_FRAME_TYPE, unexpected_frame_type).
-define(NORMAL, normal).
-endif.
