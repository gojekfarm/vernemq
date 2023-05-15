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

-module(vmq_cluster).

-include_lib("vmq_commons/include/vmq_types.hrl").

-export([
    nodes/0,
    status/0,
    is_ready/0,
    if_ready/2,
    if_ready/3,
    netsplit_statistics/0,
    check_ready/0
]).

%% table is owned by vmq_cluster_mon
-define(VMQ_CLUSTER_STATUS, vmq_status).

%%%===================================================================
%%% API
%%%===================================================================

-spec nodes() -> [any()].
nodes() ->
    [
        Node
     || [{Node, true}] <-
            ets:match(?VMQ_CLUSTER_STATUS, '$1'),
        Node /= ready
    ].

status() ->
    [
        {Node, Ready}
     || [{Node, Ready}] <-
            ets:match(?VMQ_CLUSTER_STATUS, '$1'),
        Node /= ready
    ].

-spec is_ready() -> boolean().
is_ready() ->
    [{ready, {Ready, _, _}}] = ets:lookup(?VMQ_CLUSTER_STATUS, ready),
    Ready.

-spec netsplit_statistics() -> {non_neg_integer(), non_neg_integer()}.
netsplit_statistics() ->
    case catch ets:lookup(?VMQ_CLUSTER_STATUS, ready) of
        [{ready, {_Ready, NetsplitDetectedCount, NetsplitResolvedCount}}] ->
            {NetsplitDetectedCount, NetsplitResolvedCount};
        % we don't have a vmq_status ETS table
        {'EXIT', {badarg, _}} ->
            {error, vmq_status_table_down}
    end.

-spec if_ready(_, _) -> any().
if_ready(Fun, Args) ->
    case is_ready() of
        true ->
            apply(Fun, Args);
        false ->
            {error, not_ready}
    end.
-spec if_ready(_, _, _) -> any().
if_ready(Mod, Fun, Args) ->
    case is_ready() of
        true ->
            apply(Mod, Fun, Args);
        false ->
            {error, not_ready}
    end.

check_ready() ->
    Nodes = [node()],
    check_ready(Nodes).

%%%===================================================================
%%% Internal functions
%%%===================================================================

check_ready(Nodes) ->
    check_ready(Nodes, []),
    ets:foldl(
        fun
            ({ready, _}, _) ->
                ignore;
            ({Node, _IsReady}, _) ->
                case lists:member(Node, Nodes) of
                    true ->
                        ignore;
                    false ->
                        %% Node is not part of the cluster anymore
                        lager:warning("remove supervision for node ~p", [Node]),
                        ets:delete(?VMQ_CLUSTER_STATUS, Node)
                end
        end,
        ok,
        ?VMQ_CLUSTER_STATUS
    ),
    ok.

check_ready([Node | Rest], Acc) ->
    IsReady =
        case rpc:call(Node, erlang, whereis, [vmq_server_sup]) of
            Pid when is_pid(Pid) -> true;
            _ -> false
        end,
    check_ready(Rest, [{Node, IsReady} | Acc]);
check_ready([], Acc) ->
    OldObj =
        case ets:lookup(?VMQ_CLUSTER_STATUS, ready) of
            [] -> {true, 0, 0};
            [{ready, Obj}] -> Obj
        end,
    NewObj =
        case {all_nodes_alive(Acc), OldObj} of
            {true, {true, NetsplitDetectedCnt, NetsplitResolvedCnt}} ->
                % Cluster was consistent, is still consistent
                {true, NetsplitDetectedCnt, NetsplitResolvedCnt};
            {true, {false, NetsplitDetectedCnt, NetsplitResolvedCnt}} ->
                % Cluster was inconsistent, netsplit resolved
                {true, NetsplitDetectedCnt, NetsplitResolvedCnt + 1};
            {false, {true, NetsplitDetectedCnt, NetsplitResolvedCnt}} ->
                % Cluster was consistent, but isn't anymore
                {false, NetsplitDetectedCnt + 1, NetsplitResolvedCnt};
            {false, {false, NetsplitDetectedCnt, NetsplitResolvedCnt}} ->
                % Cluster was inconsistent, is still inconsistent
                {false, NetsplitDetectedCnt, NetsplitResolvedCnt}
        end,
    ets:insert(?VMQ_CLUSTER_STATUS, [{ready, NewObj} | Acc]).

-spec all_nodes_alive([{NodeName :: atom(), IsReady :: boolean()}]) -> boolean().
all_nodes_alive([{_NodeName, _IsReady = false} | _]) -> false;
all_nodes_alive([{_NodeName, _IsReady = true} | Rest]) -> all_nodes_alive(Rest);
all_nodes_alive([]) -> true.
