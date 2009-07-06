-module(dumper).

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

dump() ->
    {ok, Conn} = start(),
    dumper:dump(Conn).

dump(Conn) ->
    case erabbit:dump(Conn) of
        {ok, empty} ->
            timer:sleep(1000),
            dumper:dump(Conn);
        {ok, Payload} ->
            io:format("got: ~s~n", [Payload]),
            timer:sleep(1000),
            dumper:dump(Conn);
        {err, _} ->
            io:format("got an error - committing suicide!"),
            erabbit:stop(Conn)
    end.
