#!/usr/bin/perl -Ilib

use strict;
use warnings;
use Simple;

my $spec = {
    RemoteAddress => '127.0.0.1',
    RemotePort    => { default => 5672 },
    Username      => { default => 'guest' },
    Password      => { default => 'guest' },
    VirtualHost   => { default => '/' },

    Logger => 0,
    Debug  => { default => {} },

    Alias     => { default => 'amqp_client' },
    AliasTCP  => { default => 'tcp_client' },
    Callbacks => { default => {} },

    channels   => { default => {} },
    is_started => { default => 0 },
};

Simple::connect($spec);
Simple::queue();
while(1){
    Simple::_read();
}
