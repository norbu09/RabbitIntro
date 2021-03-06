-module(writer).

-include("erabbit.hrl").
-compile([export_all]).

start() ->
    Q = <<"test">>,
    Conn = #erabbit_conn{},
    {ok, {Channel, Connection}} = erabbit:setup_channel(Conn),
    Conn1 = #erabbit_conn{q=Q, channel=Channel, connection = Connection},
    case erabbit:start(Conn1) of
        ok -> {ok, Conn1};
        _  -> {err, unknown}
    end.

write() ->
    {ok, Conn} = start(),
    Payload = <<"foobar">>,
    writer:write(Conn, Payload).

write(Conn) ->
    Payload = <<"foobar">>,
    writer:write(Conn, Payload).

write(Conn, Payload) ->
    case erabbit:write(Conn, Payload) of
        ok ->
            io:format("** wrote stuff~n"),
            {ok, Conn};
        _ ->
            {err, unknown}
    end.

stop(Conn) ->
    erabbit:stop(Conn),
    ok.
