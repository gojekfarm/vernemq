%% -*- coding: utf-8 -*-
%% @private
%% Automatically generated, do not edit
%% Generated by gpb_compile version 4.19.1
%% Version source: git
-module(on_unsubscribe_pb).

-export([encode_msg/1, encode_msg/2, encode_msg/3]).
-export([decode_msg/2, decode_msg/3]).
-export([merge_msgs/2, merge_msgs/3, merge_msgs/4]).
-export([verify_msg/1, verify_msg/2, verify_msg/3]).
-export([get_msg_defs/0]).
-export([get_msg_names/0]).
-export([get_group_names/0]).
-export([get_msg_or_group_names/0]).
-export([get_enum_names/0]).
-export([find_msg_def/1, fetch_msg_def/1]).
-export([find_enum_def/1, fetch_enum_def/1]).
-export([enum_symbol_by_value/2, enum_value_by_symbol/2]).
-export([get_service_names/0]).
-export([get_service_def/1]).
-export([get_rpc_names/1]).
-export([find_rpc_def/2, fetch_rpc_def/2]).
-export([fqbin_to_service_name/1]).
-export([service_name_to_fqbin/1]).
-export([fqbins_to_service_and_rpc_name/2]).
-export([service_and_rpc_name_to_fqbins/2]).
-export([fqbin_to_msg_name/1]).
-export([msg_name_to_fqbin/1]).
-export([fqbin_to_enum_name/1]).
-export([enum_name_to_fqbin/1]).
-export([get_package_name/0]).
-export([uses_packages/0]).
-export([source_basename/0]).
-export([get_all_source_basenames/0]).
-export([get_all_proto_names/0]).
-export([get_msg_containment/1]).
-export([get_pkg_containment/1]).
-export([get_service_containment/1]).
-export([get_rpc_containment/1]).
-export([get_enum_containment/1]).
-export([get_proto_by_msg_name_as_fqbin/1]).
-export([get_proto_by_service_name_as_fqbin/1]).
-export([get_proto_by_enum_name_as_fqbin/1]).
-export([get_protos_by_pkg_name_as_fqbin/1]).
-export([gpb_version_as_string/0, gpb_version_as_list/0]).
-export([gpb_version_source/0]).

-include("on_unsubscribe_pb.hrl").
-include("gpb.hrl").

%% enumerated types

-export_type([]).

%% message types
-type 'OnUnsubscribe'() :: #'OnUnsubscribe'{}.

-export_type(['OnUnsubscribe'/0]).
-type '$msg_name'() :: 'OnUnsubscribe'.
-type '$msg'() :: 'OnUnsubscribe'().
-export_type(['$msg_name'/0, '$msg'/0]).

-spec encode_msg('$msg'()) -> binary().
encode_msg(Msg) when tuple_size(Msg) >= 1 -> encode_msg(Msg, element(1, Msg), []).

-spec encode_msg('$msg'(), '$msg_name'() | list()) -> binary().
encode_msg(Msg, MsgName) when is_atom(MsgName) -> encode_msg(Msg, MsgName, []);
encode_msg(Msg, Opts) when tuple_size(Msg) >= 1, is_list(Opts) -> encode_msg(Msg, element(1, Msg), Opts).

-spec encode_msg('$msg'(), '$msg_name'(), list()) -> binary().
encode_msg(Msg, MsgName, Opts) ->
    case proplists:get_bool(verify, Opts) of
        true -> verify_msg(Msg, MsgName, Opts);
        false -> ok
    end,
    TrUserData = proplists:get_value(user_data, Opts),
    case MsgName of 'OnUnsubscribe' -> encode_msg_OnUnsubscribe(id(Msg, TrUserData), TrUserData) end.


encode_msg_OnUnsubscribe(Msg, TrUserData) -> encode_msg_OnUnsubscribe(Msg, <<>>, TrUserData).


encode_msg_OnUnsubscribe(#'OnUnsubscribe'{username = F1, client_id = F2, mountpoint = F3, topics = F4}, Bin, TrUserData) ->
    B1 = if F1 == undefined -> Bin;
            true ->
                begin
                    TrF1 = id(F1, TrUserData),
                    case is_empty_string(TrF1) of
                        true -> Bin;
                        false -> e_type_string(TrF1, <<Bin/binary, 10>>, TrUserData)
                    end
                end
         end,
    B2 = if F2 == undefined -> B1;
            true ->
                begin
                    TrF2 = id(F2, TrUserData),
                    case is_empty_string(TrF2) of
                        true -> B1;
                        false -> e_type_string(TrF2, <<B1/binary, 18>>, TrUserData)
                    end
                end
         end,
    B3 = if F3 == undefined -> B2;
            true ->
                begin
                    TrF3 = id(F3, TrUserData),
                    case is_empty_string(TrF3) of
                        true -> B2;
                        false -> e_type_string(TrF3, <<B2/binary, 26>>, TrUserData)
                    end
                end
         end,
    begin
        TrF4 = id(F4, TrUserData),
        if TrF4 == [] -> B3;
           true -> e_field_OnUnsubscribe_topics(TrF4, B3, TrUserData)
        end
    end.

e_field_OnUnsubscribe_topics([Elem | Rest], Bin, TrUserData) ->
    Bin2 = <<Bin/binary, 34>>,
    Bin3 = e_type_string(id(Elem, TrUserData), Bin2, TrUserData),
    e_field_OnUnsubscribe_topics(Rest, Bin3, TrUserData);
e_field_OnUnsubscribe_topics([], Bin, _TrUserData) -> Bin.

-compile({nowarn_unused_function,e_type_sint/3}).
e_type_sint(Value, Bin, _TrUserData) when Value >= 0 -> e_varint(Value * 2, Bin);
e_type_sint(Value, Bin, _TrUserData) -> e_varint(Value * -2 - 1, Bin).

-compile({nowarn_unused_function,e_type_int32/3}).
e_type_int32(Value, Bin, _TrUserData) when 0 =< Value, Value =< 127 -> <<Bin/binary, Value>>;
e_type_int32(Value, Bin, _TrUserData) ->
    <<N:64/unsigned-native>> = <<Value:64/signed-native>>,
    e_varint(N, Bin).

-compile({nowarn_unused_function,e_type_int64/3}).
e_type_int64(Value, Bin, _TrUserData) when 0 =< Value, Value =< 127 -> <<Bin/binary, Value>>;
e_type_int64(Value, Bin, _TrUserData) ->
    <<N:64/unsigned-native>> = <<Value:64/signed-native>>,
    e_varint(N, Bin).

-compile({nowarn_unused_function,e_type_bool/3}).
e_type_bool(true, Bin, _TrUserData) -> <<Bin/binary, 1>>;
e_type_bool(false, Bin, _TrUserData) -> <<Bin/binary, 0>>;
e_type_bool(1, Bin, _TrUserData) -> <<Bin/binary, 1>>;
e_type_bool(0, Bin, _TrUserData) -> <<Bin/binary, 0>>.

-compile({nowarn_unused_function,e_type_string/3}).
e_type_string(S, Bin, _TrUserData) ->
    Utf8 = unicode:characters_to_binary(S),
    Bin2 = e_varint(byte_size(Utf8), Bin),
    <<Bin2/binary, Utf8/binary>>.

-compile({nowarn_unused_function,e_type_bytes/3}).
e_type_bytes(Bytes, Bin, _TrUserData) when is_binary(Bytes) ->
    Bin2 = e_varint(byte_size(Bytes), Bin),
    <<Bin2/binary, Bytes/binary>>;
e_type_bytes(Bytes, Bin, _TrUserData) when is_list(Bytes) ->
    BytesBin = iolist_to_binary(Bytes),
    Bin2 = e_varint(byte_size(BytesBin), Bin),
    <<Bin2/binary, BytesBin/binary>>.

-compile({nowarn_unused_function,e_type_fixed32/3}).
e_type_fixed32(Value, Bin, _TrUserData) -> <<Bin/binary, Value:32/little>>.

-compile({nowarn_unused_function,e_type_sfixed32/3}).
e_type_sfixed32(Value, Bin, _TrUserData) -> <<Bin/binary, Value:32/little-signed>>.

-compile({nowarn_unused_function,e_type_fixed64/3}).
e_type_fixed64(Value, Bin, _TrUserData) -> <<Bin/binary, Value:64/little>>.

-compile({nowarn_unused_function,e_type_sfixed64/3}).
e_type_sfixed64(Value, Bin, _TrUserData) -> <<Bin/binary, Value:64/little-signed>>.

-compile({nowarn_unused_function,e_type_float/3}).
e_type_float(V, Bin, _) when is_number(V) -> <<Bin/binary, V:32/little-float>>;
e_type_float(infinity, Bin, _) -> <<Bin/binary, 0:16, 128, 127>>;
e_type_float('-infinity', Bin, _) -> <<Bin/binary, 0:16, 128, 255>>;
e_type_float(nan, Bin, _) -> <<Bin/binary, 0:16, 192, 127>>.

-compile({nowarn_unused_function,e_type_double/3}).
e_type_double(V, Bin, _) when is_number(V) -> <<Bin/binary, V:64/little-float>>;
e_type_double(infinity, Bin, _) -> <<Bin/binary, 0:48, 240, 127>>;
e_type_double('-infinity', Bin, _) -> <<Bin/binary, 0:48, 240, 255>>;
e_type_double(nan, Bin, _) -> <<Bin/binary, 0:48, 248, 127>>.

-compile({nowarn_unused_function,e_unknown_elems/2}).
e_unknown_elems([Elem | Rest], Bin) ->
    BinR = case Elem of
               {varint, FNum, N} ->
                   BinF = e_varint(FNum bsl 3, Bin),
                   e_varint(N, BinF);
               {length_delimited, FNum, Data} ->
                   BinF = e_varint(FNum bsl 3 bor 2, Bin),
                   BinL = e_varint(byte_size(Data), BinF),
                   <<BinL/binary, Data/binary>>;
               {group, FNum, GroupFields} ->
                   Bin1 = e_varint(FNum bsl 3 bor 3, Bin),
                   Bin2 = e_unknown_elems(GroupFields, Bin1),
                   e_varint(FNum bsl 3 bor 4, Bin2);
               {fixed32, FNum, V} ->
                   BinF = e_varint(FNum bsl 3 bor 5, Bin),
                   <<BinF/binary, V:32/little>>;
               {fixed64, FNum, V} ->
                   BinF = e_varint(FNum bsl 3 bor 1, Bin),
                   <<BinF/binary, V:64/little>>
           end,
    e_unknown_elems(Rest, BinR);
e_unknown_elems([], Bin) -> Bin.

-compile({nowarn_unused_function,e_varint/3}).
e_varint(N, Bin, _TrUserData) -> e_varint(N, Bin).

-compile({nowarn_unused_function,e_varint/2}).
e_varint(N, Bin) when N =< 127 -> <<Bin/binary, N>>;
e_varint(N, Bin) ->
    Bin2 = <<Bin/binary, (N band 127 bor 128)>>,
    e_varint(N bsr 7, Bin2).

is_empty_string("") -> true;
is_empty_string(<<>>) -> true;
is_empty_string(L) when is_list(L) -> not string_has_chars(L);
is_empty_string(B) when is_binary(B) -> false.

string_has_chars([C | _]) when is_integer(C) -> true;
string_has_chars([H | T]) ->
    case string_has_chars(H) of
        true -> true;
        false -> string_has_chars(T)
    end;
string_has_chars(B) when is_binary(B), byte_size(B) =/= 0 -> true;
string_has_chars(C) when is_integer(C) -> true;
string_has_chars(<<>>) -> false;
string_has_chars([]) -> false.


decode_msg(Bin, MsgName) when is_binary(Bin) -> decode_msg(Bin, MsgName, []).

decode_msg(Bin, MsgName, Opts) when is_binary(Bin) ->
    TrUserData = proplists:get_value(user_data, Opts),
    decode_msg_1_catch(Bin, MsgName, TrUserData).

-ifdef('OTP_RELEASE').
decode_msg_1_catch(Bin, MsgName, TrUserData) ->
    try decode_msg_2_doit(MsgName, Bin, TrUserData)
    catch
        error:{gpb_error,_}=Reason:StackTrace ->
            erlang:raise(error, Reason, StackTrace);
        Class:Reason:StackTrace -> error({gpb_error,{decoding_failure, {Bin, MsgName, {Class, Reason, StackTrace}}}})
    end.
-else.
decode_msg_1_catch(Bin, MsgName, TrUserData) ->
    try decode_msg_2_doit(MsgName, Bin, TrUserData)
    catch
        error:{gpb_error,_}=Reason ->
            erlang:raise(error, Reason,
                         erlang:get_stacktrace());
        Class:Reason ->
            StackTrace = erlang:get_stacktrace(),
            error({gpb_error,{decoding_failure, {Bin, MsgName, {Class, Reason, StackTrace}}}})
    end.
-endif.

decode_msg_2_doit('OnUnsubscribe', Bin, TrUserData) -> id(decode_msg_OnUnsubscribe(Bin, TrUserData), TrUserData).



decode_msg_OnUnsubscribe(Bin, TrUserData) -> dfp_read_field_def_OnUnsubscribe(Bin, 0, 0, 0, id(<<>>, TrUserData), id(<<>>, TrUserData), id(<<>>, TrUserData), id([], TrUserData), TrUserData).

dfp_read_field_def_OnUnsubscribe(<<10, Rest/binary>>, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData) -> d_field_OnUnsubscribe_username(Rest, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
dfp_read_field_def_OnUnsubscribe(<<18, Rest/binary>>, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData) -> d_field_OnUnsubscribe_client_id(Rest, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
dfp_read_field_def_OnUnsubscribe(<<26, Rest/binary>>, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData) -> d_field_OnUnsubscribe_mountpoint(Rest, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
dfp_read_field_def_OnUnsubscribe(<<34, Rest/binary>>, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData) -> d_field_OnUnsubscribe_topics(Rest, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
dfp_read_field_def_OnUnsubscribe(<<>>, 0, 0, _, F@_1, F@_2, F@_3, R1, TrUserData) -> #'OnUnsubscribe'{username = F@_1, client_id = F@_2, mountpoint = F@_3, topics = lists_reverse(R1, TrUserData)};
dfp_read_field_def_OnUnsubscribe(Other, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData) -> dg_read_field_def_OnUnsubscribe(Other, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData).

dg_read_field_def_OnUnsubscribe(<<1:1, X:7, Rest/binary>>, N, Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData) when N < 32 - 7 -> dg_read_field_def_OnUnsubscribe(Rest, N + 7, X bsl N + Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
dg_read_field_def_OnUnsubscribe(<<0:1, X:7, Rest/binary>>, N, Acc, _, F@_1, F@_2, F@_3, F@_4, TrUserData) ->
    Key = X bsl N + Acc,
    case Key of
        10 -> d_field_OnUnsubscribe_username(Rest, 0, 0, 0, F@_1, F@_2, F@_3, F@_4, TrUserData);
        18 -> d_field_OnUnsubscribe_client_id(Rest, 0, 0, 0, F@_1, F@_2, F@_3, F@_4, TrUserData);
        26 -> d_field_OnUnsubscribe_mountpoint(Rest, 0, 0, 0, F@_1, F@_2, F@_3, F@_4, TrUserData);
        34 -> d_field_OnUnsubscribe_topics(Rest, 0, 0, 0, F@_1, F@_2, F@_3, F@_4, TrUserData);
        _ ->
            case Key band 7 of
                0 -> skip_varint_OnUnsubscribe(Rest, 0, 0, Key bsr 3, F@_1, F@_2, F@_3, F@_4, TrUserData);
                1 -> skip_64_OnUnsubscribe(Rest, 0, 0, Key bsr 3, F@_1, F@_2, F@_3, F@_4, TrUserData);
                2 -> skip_length_delimited_OnUnsubscribe(Rest, 0, 0, Key bsr 3, F@_1, F@_2, F@_3, F@_4, TrUserData);
                3 -> skip_group_OnUnsubscribe(Rest, 0, 0, Key bsr 3, F@_1, F@_2, F@_3, F@_4, TrUserData);
                5 -> skip_32_OnUnsubscribe(Rest, 0, 0, Key bsr 3, F@_1, F@_2, F@_3, F@_4, TrUserData)
            end
    end;
dg_read_field_def_OnUnsubscribe(<<>>, 0, 0, _, F@_1, F@_2, F@_3, R1, TrUserData) -> #'OnUnsubscribe'{username = F@_1, client_id = F@_2, mountpoint = F@_3, topics = lists_reverse(R1, TrUserData)}.

d_field_OnUnsubscribe_username(<<1:1, X:7, Rest/binary>>, N, Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData) when N < 57 -> d_field_OnUnsubscribe_username(Rest, N + 7, X bsl N + Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
d_field_OnUnsubscribe_username(<<0:1, X:7, Rest/binary>>, N, Acc, F, _, F@_2, F@_3, F@_4, TrUserData) ->
    {NewFValue, RestF} = begin Len = X bsl N + Acc, <<Bytes:Len/binary, Rest2/binary>> = Rest, Bytes2 = binary:copy(Bytes), {id(Bytes2, TrUserData), Rest2} end,
    dfp_read_field_def_OnUnsubscribe(RestF, 0, 0, F, NewFValue, F@_2, F@_3, F@_4, TrUserData).

d_field_OnUnsubscribe_client_id(<<1:1, X:7, Rest/binary>>, N, Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData) when N < 57 -> d_field_OnUnsubscribe_client_id(Rest, N + 7, X bsl N + Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
d_field_OnUnsubscribe_client_id(<<0:1, X:7, Rest/binary>>, N, Acc, F, F@_1, _, F@_3, F@_4, TrUserData) ->
    {NewFValue, RestF} = begin Len = X bsl N + Acc, <<Bytes:Len/binary, Rest2/binary>> = Rest, Bytes2 = binary:copy(Bytes), {id(Bytes2, TrUserData), Rest2} end,
    dfp_read_field_def_OnUnsubscribe(RestF, 0, 0, F, F@_1, NewFValue, F@_3, F@_4, TrUserData).

d_field_OnUnsubscribe_mountpoint(<<1:1, X:7, Rest/binary>>, N, Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData) when N < 57 -> d_field_OnUnsubscribe_mountpoint(Rest, N + 7, X bsl N + Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
d_field_OnUnsubscribe_mountpoint(<<0:1, X:7, Rest/binary>>, N, Acc, F, F@_1, F@_2, _, F@_4, TrUserData) ->
    {NewFValue, RestF} = begin Len = X bsl N + Acc, <<Bytes:Len/binary, Rest2/binary>> = Rest, Bytes2 = binary:copy(Bytes), {id(Bytes2, TrUserData), Rest2} end,
    dfp_read_field_def_OnUnsubscribe(RestF, 0, 0, F, F@_1, F@_2, NewFValue, F@_4, TrUserData).

d_field_OnUnsubscribe_topics(<<1:1, X:7, Rest/binary>>, N, Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData) when N < 57 -> d_field_OnUnsubscribe_topics(Rest, N + 7, X bsl N + Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
d_field_OnUnsubscribe_topics(<<0:1, X:7, Rest/binary>>, N, Acc, F, F@_1, F@_2, F@_3, Prev, TrUserData) ->
    {NewFValue, RestF} = begin Len = X bsl N + Acc, <<Bytes:Len/binary, Rest2/binary>> = Rest, Bytes2 = binary:copy(Bytes), {id(Bytes2, TrUserData), Rest2} end,
    dfp_read_field_def_OnUnsubscribe(RestF, 0, 0, F, F@_1, F@_2, F@_3, cons(NewFValue, Prev, TrUserData), TrUserData).

skip_varint_OnUnsubscribe(<<1:1, _:7, Rest/binary>>, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData) -> skip_varint_OnUnsubscribe(Rest, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
skip_varint_OnUnsubscribe(<<0:1, _:7, Rest/binary>>, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData) -> dfp_read_field_def_OnUnsubscribe(Rest, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData).

skip_length_delimited_OnUnsubscribe(<<1:1, X:7, Rest/binary>>, N, Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData) when N < 57 -> skip_length_delimited_OnUnsubscribe(Rest, N + 7, X bsl N + Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData);
skip_length_delimited_OnUnsubscribe(<<0:1, X:7, Rest/binary>>, N, Acc, F, F@_1, F@_2, F@_3, F@_4, TrUserData) ->
    Length = X bsl N + Acc,
    <<_:Length/binary, Rest2/binary>> = Rest,
    dfp_read_field_def_OnUnsubscribe(Rest2, 0, 0, F, F@_1, F@_2, F@_3, F@_4, TrUserData).

skip_group_OnUnsubscribe(Bin, _, Z2, FNum, F@_1, F@_2, F@_3, F@_4, TrUserData) ->
    {_, Rest} = read_group(Bin, FNum),
    dfp_read_field_def_OnUnsubscribe(Rest, 0, Z2, FNum, F@_1, F@_2, F@_3, F@_4, TrUserData).

skip_32_OnUnsubscribe(<<_:32, Rest/binary>>, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData) -> dfp_read_field_def_OnUnsubscribe(Rest, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData).

skip_64_OnUnsubscribe(<<_:64, Rest/binary>>, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData) -> dfp_read_field_def_OnUnsubscribe(Rest, Z1, Z2, F, F@_1, F@_2, F@_3, F@_4, TrUserData).

read_group(Bin, FieldNum) ->
    {NumBytes, EndTagLen} = read_gr_b(Bin, 0, 0, 0, 0, FieldNum),
    <<Group:NumBytes/binary, _:EndTagLen/binary, Rest/binary>> = Bin,
    {Group, Rest}.

%% Like skipping over fields, but record the total length,
%% Each field is <(FieldNum bsl 3) bor FieldType> ++ <FieldValue>
%% Record the length because varints may be non-optimally encoded.
%%
%% Groups can be nested, but assume the same FieldNum cannot be nested
%% because group field numbers are shared with the rest of the fields
%% numbers. Thus we can search just for an group-end with the same
%% field number.
%%
%% (The only time the same group field number could occur would
%% be in a nested sub message, but then it would be inside a
%% length-delimited entry, which we skip-read by length.)
read_gr_b(<<1:1, X:7, Tl/binary>>, N, Acc, NumBytes, TagLen, FieldNum)
  when N < (32-7) ->
    read_gr_b(Tl, N+7, X bsl N + Acc, NumBytes, TagLen+1, FieldNum);
read_gr_b(<<0:1, X:7, Tl/binary>>, N, Acc, NumBytes, TagLen,
          FieldNum) ->
    Key = X bsl N + Acc,
    TagLen1 = TagLen + 1,
    case {Key bsr 3, Key band 7} of
        {FieldNum, 4} -> % 4 = group_end
            {NumBytes, TagLen1};
        {_, 0} -> % 0 = varint
            read_gr_vi(Tl, 0, NumBytes + TagLen1, FieldNum);
        {_, 1} -> % 1 = bits64
            <<_:64, Tl2/binary>> = Tl,
            read_gr_b(Tl2, 0, 0, NumBytes + TagLen1 + 8, 0, FieldNum);
        {_, 2} -> % 2 = length_delimited
            read_gr_ld(Tl, 0, 0, NumBytes + TagLen1, FieldNum);
        {_, 3} -> % 3 = group_start
            read_gr_b(Tl, 0, 0, NumBytes + TagLen1, 0, FieldNum);
        {_, 4} -> % 4 = group_end
            read_gr_b(Tl, 0, 0, NumBytes + TagLen1, 0, FieldNum);
        {_, 5} -> % 5 = bits32
            <<_:32, Tl2/binary>> = Tl,
            read_gr_b(Tl2, 0, 0, NumBytes + TagLen1 + 4, 0, FieldNum)
    end.

read_gr_vi(<<1:1, _:7, Tl/binary>>, N, NumBytes, FieldNum)
  when N < (64-7) ->
    read_gr_vi(Tl, N+7, NumBytes+1, FieldNum);
read_gr_vi(<<0:1, _:7, Tl/binary>>, _, NumBytes, FieldNum) ->
    read_gr_b(Tl, 0, 0, NumBytes+1, 0, FieldNum).

read_gr_ld(<<1:1, X:7, Tl/binary>>, N, Acc, NumBytes, FieldNum)
  when N < (64-7) ->
    read_gr_ld(Tl, N+7, X bsl N + Acc, NumBytes+1, FieldNum);
read_gr_ld(<<0:1, X:7, Tl/binary>>, N, Acc, NumBytes, FieldNum) ->
    Len = X bsl N + Acc,
    NumBytes1 = NumBytes + 1,
    <<_:Len/binary, Tl2/binary>> = Tl,
    read_gr_b(Tl2, 0, 0, NumBytes1 + Len, 0, FieldNum).

merge_msgs(Prev, New) when element(1, Prev) =:= element(1, New) -> merge_msgs(Prev, New, element(1, Prev), []).

merge_msgs(Prev, New, MsgName) when is_atom(MsgName) -> merge_msgs(Prev, New, MsgName, []);
merge_msgs(Prev, New, Opts) when element(1, Prev) =:= element(1, New), is_list(Opts) -> merge_msgs(Prev, New, element(1, Prev), Opts).

merge_msgs(Prev, New, MsgName, Opts) ->
    TrUserData = proplists:get_value(user_data, Opts),
    case MsgName of 'OnUnsubscribe' -> merge_msg_OnUnsubscribe(Prev, New, TrUserData) end.

-compile({nowarn_unused_function,merge_msg_OnUnsubscribe/3}).
merge_msg_OnUnsubscribe(#'OnUnsubscribe'{username = PFusername, client_id = PFclient_id, mountpoint = PFmountpoint, topics = PFtopics}, #'OnUnsubscribe'{username = NFusername, client_id = NFclient_id, mountpoint = NFmountpoint, topics = NFtopics},
                        TrUserData) ->
    #'OnUnsubscribe'{username =
                         if NFusername =:= undefined -> PFusername;
                            true -> NFusername
                         end,
                     client_id =
                         if NFclient_id =:= undefined -> PFclient_id;
                            true -> NFclient_id
                         end,
                     mountpoint =
                         if NFmountpoint =:= undefined -> PFmountpoint;
                            true -> NFmountpoint
                         end,
                     topics =
                         if PFtopics /= undefined, NFtopics /= undefined -> 'erlang_++'(PFtopics, NFtopics, TrUserData);
                            PFtopics == undefined -> NFtopics;
                            NFtopics == undefined -> PFtopics
                         end}.


verify_msg(Msg) when tuple_size(Msg) >= 1 -> verify_msg(Msg, element(1, Msg), []);
verify_msg(X) -> mk_type_error(not_a_known_message, X, []).

verify_msg(Msg, MsgName) when is_atom(MsgName) -> verify_msg(Msg, MsgName, []);
verify_msg(Msg, Opts) when tuple_size(Msg) >= 1 -> verify_msg(Msg, element(1, Msg), Opts);
verify_msg(X, _Opts) -> mk_type_error(not_a_known_message, X, []).

verify_msg(Msg, MsgName, Opts) ->
    TrUserData = proplists:get_value(user_data, Opts),
    case MsgName of
        'OnUnsubscribe' -> v_msg_OnUnsubscribe(Msg, [MsgName], TrUserData);
        _ -> mk_type_error(not_a_known_message, Msg, [])
    end.


-compile({nowarn_unused_function,v_msg_OnUnsubscribe/3}).
-dialyzer({nowarn_function,v_msg_OnUnsubscribe/3}).
v_msg_OnUnsubscribe(#'OnUnsubscribe'{username = F1, client_id = F2, mountpoint = F3, topics = F4}, Path, TrUserData) ->
    if F1 == undefined -> ok;
       true -> v_type_string(F1, [username | Path], TrUserData)
    end,
    if F2 == undefined -> ok;
       true -> v_type_string(F2, [client_id | Path], TrUserData)
    end,
    if F3 == undefined -> ok;
       true -> v_type_string(F3, [mountpoint | Path], TrUserData)
    end,
    if is_list(F4) ->
           _ = [v_type_string(Elem, [topics | Path], TrUserData) || Elem <- F4],
           ok;
       true -> mk_type_error({invalid_list_of, string}, F4, [topics | Path])
    end,
    ok;
v_msg_OnUnsubscribe(X, Path, _TrUserData) -> mk_type_error({expected_msg, 'OnUnsubscribe'}, X, Path).

-compile({nowarn_unused_function,v_type_string/3}).
-dialyzer({nowarn_function,v_type_string/3}).
v_type_string(S, Path, _TrUserData) when is_list(S); is_binary(S) ->
    try unicode:characters_to_binary(S) of
        B when is_binary(B) -> ok;
        {error, _, _} -> mk_type_error(bad_unicode_string, S, Path)
    catch
        error:badarg -> mk_type_error(bad_unicode_string, S, Path)
    end;
v_type_string(X, Path, _TrUserData) -> mk_type_error(bad_unicode_string, X, Path).

-compile({nowarn_unused_function,mk_type_error/3}).
-spec mk_type_error(_, _, list()) -> no_return().
mk_type_error(Error, ValueSeen, Path) ->
    Path2 = prettify_path(Path),
    erlang:error({gpb_type_error, {Error, [{value, ValueSeen}, {path, Path2}]}}).


-compile({nowarn_unused_function,prettify_path/1}).
-dialyzer({nowarn_function,prettify_path/1}).
prettify_path([]) -> top_level;
prettify_path(PathR) -> lists:append(lists:join(".", lists:map(fun atom_to_list/1, lists:reverse(PathR)))).


-compile({nowarn_unused_function,id/2}).
-compile({inline,id/2}).
id(X, _TrUserData) -> X.

-compile({nowarn_unused_function,v_ok/3}).
-compile({inline,v_ok/3}).
v_ok(_Value, _Path, _TrUserData) -> ok.

-compile({nowarn_unused_function,m_overwrite/3}).
-compile({inline,m_overwrite/3}).
m_overwrite(_Prev, New, _TrUserData) -> New.

-compile({nowarn_unused_function,cons/3}).
-compile({inline,cons/3}).
cons(Elem, Acc, _TrUserData) -> [Elem | Acc].

-compile({nowarn_unused_function,lists_reverse/2}).
-compile({inline,lists_reverse/2}).
'lists_reverse'(L, _TrUserData) -> lists:reverse(L).
-compile({nowarn_unused_function,'erlang_++'/3}).
-compile({inline,'erlang_++'/3}).
'erlang_++'(A, B, _TrUserData) -> A ++ B.


get_msg_defs() ->
    [{{msg, 'OnUnsubscribe'},
      [#field{name = username, fnum = 1, rnum = 2, type = string, occurrence = optional, opts = []},
       #field{name = client_id, fnum = 2, rnum = 3, type = string, occurrence = optional, opts = []},
       #field{name = mountpoint, fnum = 3, rnum = 4, type = string, occurrence = optional, opts = []},
       #field{name = topics, fnum = 4, rnum = 5, type = string, occurrence = repeated, opts = []}]}].


get_msg_names() -> ['OnUnsubscribe'].


get_group_names() -> [].


get_msg_or_group_names() -> ['OnUnsubscribe'].


get_enum_names() -> [].


fetch_msg_def(MsgName) ->
    case find_msg_def(MsgName) of
        Fs when is_list(Fs) -> Fs;
        error -> erlang:error({no_such_msg, MsgName})
    end.


-spec fetch_enum_def(_) -> no_return().
fetch_enum_def(EnumName) -> erlang:error({no_such_enum, EnumName}).


find_msg_def('OnUnsubscribe') ->
    [#field{name = username, fnum = 1, rnum = 2, type = string, occurrence = optional, opts = []},
     #field{name = client_id, fnum = 2, rnum = 3, type = string, occurrence = optional, opts = []},
     #field{name = mountpoint, fnum = 3, rnum = 4, type = string, occurrence = optional, opts = []},
     #field{name = topics, fnum = 4, rnum = 5, type = string, occurrence = repeated, opts = []}];
find_msg_def(_) -> error.


find_enum_def(_) -> error.


-spec enum_symbol_by_value(_, _) -> no_return().
enum_symbol_by_value(E, V) -> erlang:error({no_enum_defs, E, V}).


-spec enum_value_by_symbol(_, _) -> no_return().
enum_value_by_symbol(E, V) -> erlang:error({no_enum_defs, E, V}).



get_service_names() -> [].


get_service_def(_) -> error.


get_rpc_names(_) -> error.


find_rpc_def(_, _) -> error.



-spec fetch_rpc_def(_, _) -> no_return().
fetch_rpc_def(ServiceName, RpcName) -> erlang:error({no_such_rpc, ServiceName, RpcName}).


%% Convert a a fully qualified (ie with package name) service name
%% as a binary to a service name as an atom.
-spec fqbin_to_service_name(_) -> no_return().
fqbin_to_service_name(X) -> error({gpb_error, {badservice, X}}).


%% Convert a service name as an atom to a fully qualified
%% (ie with package name) name as a binary.
-spec service_name_to_fqbin(_) -> no_return().
service_name_to_fqbin(X) -> error({gpb_error, {badservice, X}}).


%% Convert a a fully qualified (ie with package name) service name
%% and an rpc name, both as binaries to a service name and an rpc
%% name, as atoms.
-spec fqbins_to_service_and_rpc_name(_, _) -> no_return().
fqbins_to_service_and_rpc_name(S, R) -> error({gpb_error, {badservice_or_rpc, {S, R}}}).


%% Convert a service name and an rpc name, both as atoms,
%% to a fully qualified (ie with package name) service name and
%% an rpc name as binaries.
-spec service_and_rpc_name_to_fqbins(_, _) -> no_return().
service_and_rpc_name_to_fqbins(S, R) -> error({gpb_error, {badservice_or_rpc, {S, R}}}).


fqbin_to_msg_name(<<"eventssidecar.v1.OnUnsubscribe">>) -> 'OnUnsubscribe';
fqbin_to_msg_name(E) -> error({gpb_error, {badmsg, E}}).


msg_name_to_fqbin('OnUnsubscribe') -> <<"eventssidecar.v1.OnUnsubscribe">>;
msg_name_to_fqbin(E) -> error({gpb_error, {badmsg, E}}).


-spec fqbin_to_enum_name(_) -> no_return().
fqbin_to_enum_name(E) -> error({gpb_error, {badenum, E}}).


-spec enum_name_to_fqbin(_) -> no_return().
enum_name_to_fqbin(E) -> error({gpb_error, {badenum, E}}).


get_package_name() -> 'eventssidecar.v1'.


%% Whether or not the message names
%% are prepended with package name or not.
uses_packages() -> false.


source_basename() -> "on_unsubscribe.proto".


%% Retrieve all proto file names, also imported ones.
%% The order is top-down. The first element is always the main
%% source file. The files are returned with extension,
%% see get_all_proto_names/0 for a version that returns
%% the basenames sans extension
get_all_source_basenames() -> ["on_unsubscribe.proto"].


%% Retrieve all proto file names, also imported ones.
%% The order is top-down. The first element is always the main
%% source file. The files are returned sans .proto extension,
%% to make it easier to use them with the various get_xyz_containment
%% functions.
get_all_proto_names() -> ["on_unsubscribe"].


get_msg_containment("on_unsubscribe") -> ['OnUnsubscribe'];
get_msg_containment(P) -> error({gpb_error, {badproto, P}}).


get_pkg_containment("on_unsubscribe") -> undefined;
get_pkg_containment(P) -> error({gpb_error, {badproto, P}}).


get_service_containment("on_unsubscribe") -> [];
get_service_containment(P) -> error({gpb_error, {badproto, P}}).


get_rpc_containment("on_unsubscribe") -> [];
get_rpc_containment(P) -> error({gpb_error, {badproto, P}}).


get_enum_containment("on_unsubscribe") -> [];
get_enum_containment(P) -> error({gpb_error, {badproto, P}}).


get_proto_by_msg_name_as_fqbin(<<"eventssidecar.v1.OnUnsubscribe">>) -> "on_unsubscribe";
get_proto_by_msg_name_as_fqbin(E) -> error({gpb_error, {badmsg, E}}).


-spec get_proto_by_service_name_as_fqbin(_) -> no_return().
get_proto_by_service_name_as_fqbin(E) -> error({gpb_error, {badservice, E}}).


-spec get_proto_by_enum_name_as_fqbin(_) -> no_return().
get_proto_by_enum_name_as_fqbin(E) -> error({gpb_error, {badenum, E}}).


-spec get_protos_by_pkg_name_as_fqbin(_) -> no_return().
get_protos_by_pkg_name_as_fqbin(E) -> error({gpb_error, {badpkg, E}}).



gpb_version_as_string() ->
    "4.19.1".

gpb_version_as_list() ->
    [4,19,1].

gpb_version_source() ->
    "git".
