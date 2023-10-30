%% -*- coding: utf-8 -*-
%% Automatically generated, do not edit
%% Generated by gpb_compile version 4.20.0

-ifndef(on_client_offline_pb).
-define(on_client_offline_pb, true).

-define(on_client_offline_pb_gpb_version, "4.20.0").

-ifndef('EVENTSSIDECAR.V1.ONCLIENTOFFLINE_PB_H').
-define('EVENTSSIDECAR.V1.ONCLIENTOFFLINE_PB_H', true).
-record('eventssidecar.v1.OnClientOffline',
    % = 1, optional
    {
        timestamp = undefined :: on_client_offline_pb:'google.protobuf.Timestamp'() | undefined,
        % = 2, optional
        client_id = <<>> :: unicode:chardata() | undefined,
        % = 3, optional
        mountpoint = <<>> :: unicode:chardata() | undefined,
        % = 4, optional, enum eventssidecar.v1.OnClientOffline.Reason
        reason = 'REASON_UNSPECIFIED' ::
            'REASON_UNSPECIFIED'
            | 'REASON_NOT_AUTHORIZED'
            | 'REASON_NORMAL_DISCONNECT'
            | 'REASON_SESSION_TAKEN_OVER'
            | 'REASON_ADMINISTRATIVE_ACTION'
            | 'REASON_DISCONNECT_KEEP_ALIVE'
            | 'REASON_DISCONNECT_MIGRATION'
            | 'REASON_BAD_AUTHENTICATION_METHOD'
            | 'REASON_REMOTE_SESSION_TAKEN_OVER'
            | 'REASON_MQTT_CLIENT_DISCONNECT'
            | 'REASON_RECEIVE_MAX_EXCEEDED'
            | 'REASON_PROTOCOL_ERROR'
            | integer()
            | undefined
    }
).
-endif.

-ifndef('GOOGLE.PROTOBUF.TIMESTAMP_PB_H').
-define('GOOGLE.PROTOBUF.TIMESTAMP_PB_H', true).
-record('google.protobuf.Timestamp',
    % = 1, optional, 64 bits
    {
        seconds = 0 :: integer() | undefined,
        % = 2, optional, 32 bits
        nanos = 0 :: integer() | undefined
    }
).
-endif.

-endif.
