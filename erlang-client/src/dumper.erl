-module(dumper).

-include_lib("rabbitmq_server/include/rabbit.hrl").
-include_lib("rabbitmq_server/include/rabbit_framing.hrl").
-include("amqp_client.hrl").
-compile([export_all]).

start() ->
    Q = <<"login">>,
    X = <<"test">>,
    {ok, {Channel, Connection}} = setup_channel(),
    %Tag = lib_amqp:subscribe(Channel, Q, self(), false),
    %receive
    %    #'basic.consume_ok'{consumer_tag = Tag} -> ok
    %after 2000 ->
    %    exit(did_not_receive_subscription_message)
    %end,
    %lib_amqp:publish(Channel, X, Q, <<"foobar">>),
    %io:format("** subscription setup to: ~s~n", [Q]),
    %timer:sleep(5000),
    %receive
    %    {#'basic.deliver'{}, Content} ->
    %        %% no_ack set to false, but don't send ack
    %        #content{payload_fragments_rev = Payload} = Content,
    %        io:format("!! Got: ~s~n", [Payload]),
    %        ok
    %after 2000 ->
    %    exit(did_not_receive_first_message)
    %end,
    %lib_amqp:teardown(Connection, Channel).

%     timer:sleep(5000),
     Content = lib_amqp:get(Channel, Q),
     case Content of
         #content{payload_fragments_rev = Payload} ->
             io:format("!! Got: ~s~n", [Payload]);
         'basic.get_empty' ->
             io:format("!! Got nothing~n")
     end.

setup_channel() ->
    io:format("** starting ...~n"),
    Connection = lib_amqp:start_connection("localhost"),
    io:format("** Connection started~n"),
    Channel = lib_amqp:start_channel(Connection),
    io:format("** Channel started~n"),
    {ok, {Channel, Connection}}.

