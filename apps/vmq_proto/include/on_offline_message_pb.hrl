%% -*- coding: utf-8 -*-
%% Automatically generated, do not edit
%% Generated by gpb_compile version 4.19.1

-ifndef(on_offline_message_pb).
-define(on_offline_message_pb, true).

-define(on_offline_message_pb_gpb_version, "4.19.1").

-ifndef('ONOFFLINEMESSAGE_PB_H').
-define('ONOFFLINEMESSAGE_PB_H', true).
-record('OnOfflineMessage',
        {client_id = <<>>       :: unicode:chardata() | undefined, % = 1, optional
         mountpoint = <<>>      :: unicode:chardata() | undefined, % = 2, optional
         qos = 0                :: integer() | undefined, % = 3, optional, 32 bits
         topic = <<>>           :: unicode:chardata() | undefined, % = 4, optional
         payload = <<>>         :: iodata() | undefined, % = 5, optional
         retain = false         :: boolean() | 0 | 1 | undefined % = 6, optional
        }).
-endif.

-endif.
