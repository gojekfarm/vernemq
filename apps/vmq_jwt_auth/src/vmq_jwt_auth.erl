-module(vmq_jwt_auth).

-behaviour(auth_on_register_hook).

-export([auth_on_register/5]).

-define(SecretKey, application:get_env(vmq_jwt_auth, secret_key, undefined)).


auth_on_register({_IpAddr, _Port} = Peer, {_MountPoint, _ClientId} = SubscriberId, UserName, Password, CleanSession) ->
    %% do whatever you like with the params, all that matters
    %% is the return value of this function
    %%
    %% 1. return 'ok' -> CONNECT is authenticated
    %% 2. return 'next' -> leave it to other plugins to decide
    %% 3. return {ok, [{ModifierKey, NewVal}...]} -> CONNECT is authenticated, but we might want to set some options used throughout the client session:
    %%      - {mountpoint, NewMountPoint::string}
    %%      - {clean_session, NewCleanSession::boolean}
    %% 4. return {error, invalid_credentials} -> CONNACK_CREDENTIALS is sent
    %% 5. return {error, whatever} -> CONNACK_AUTH is sent

    %% we return 'ok'
    {Result, Claims} = verify(Password, ?SecretKey),
    if
        Result =:= ok -> checkRID(Claims, getUsername(UserName));
        %else block
        true -> {error, invalid_signature}
    end.

verify(Password, SecretKey) ->
    try jwerl:verify(Password, hs256, SecretKey) of
    _ -> jwerl:verify(Password, hs256, SecretKey)
    catch
    error:Error -> {error, invalid_signature}
    end.

checkRID(Claims, UserName) ->
    case maps:find(rid, Claims) of
        {ok, Value} ->
            if Value =:= UserName -> ok;
            %else block
            true -> error
            end;
        error -> error
    end.

getUsername(Username) ->
    string:nth_lexeme(Username, 1, ":").
