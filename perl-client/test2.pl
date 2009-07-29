#!/usr/bin/perl -Ilib

use strict;
use warnings;
use Net::AMQP::Simple;
use Data::Dumper;

my $spec = {
    RemoteAddress => '127.0.0.1',
    RemotePort    => { default => 5672 },
    Username      => { default => 'hase' },
    Password      => { default => 'hase' },
    VirtualHost   => { default => '/hase' },

    Logger => 0,
    Debug  => { default => {} },

    Alias     => { default => 'amqp_client' },
    AliasTCP  => { default => 'tcp_client' },
    Callbacks => { default => {} },

    channels   => { default => {} },
    is_started => { default => 0 },
};

Net::AMQP::Simple::connect($spec);
#Net::AMQP::Simple::queue("log");

Net::AMQP::Simple::pub("log", "helo world");

#while(1){
#    print Dumper(Net::AMQP::Simple::poll());
#}

Net::AMQP::Simple::close();

