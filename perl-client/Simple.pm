#!/usr/bin/perl -Ilib

package Simple;

use strict;
use warnings;
use Net::AMQP;
use Net::AMQP::Protocol;
use Net::AMQP::Common qw(:all);
use IO::Socket::INET;
use Data::Dumper;

our $remote;
our $debug = 1;

sub connect {
    my $spec = shift;
    Net::AMQP::Protocol->load_xml_spec('../../net-amqp/spec/amqp0-8.xml');

    $remote = IO::Socket::INET->new(
        Proto    => "tcp",
        PeerAddr => $spec->{RemoteAddress},
        PeerPort => $spec->{RemotePort}->{default},
      )
      or carp(
        "cannot connect to RabbitMQ, check the config section in your program");

    print $remote Net::AMQP::Protocol->header;
    callbacks( _read(), $spec );    # Connection::Start
    callbacks( _read(), $spec );    # Connection::StartOk
    callbacks( _read(), $spec );    # Connection::TuneOk
    callbacks( _read(), $spec );    # Channel::OpenOk
}

sub queue {
    my $queue = shift;
    my %opts = (
        ticket       => 0,
        queue        => $queue,
        consumer_tag => '',                 # auto-generated
                                            #no_local     => 0,
        no_ack       => 1,
        exclusive    => 0,

        #nowait       => 0, # do not send the ConsumeOk response
    );
    my $output =
      Net::AMQP::Frame::Method->new(
        method_frame => Net::AMQP::Protocol::Queue::Declare->new(%opts) );
    my $frame =
      $output->isa("Net::AMQP::Protocol::Base") ? $output->frame_wrap : $output;
    $frame->channel(2);
    _print($frame);
    $output =
      Net::AMQP::Frame::Method->new(
        method_frame => Net::AMQP::Protocol::Basic::Consume->new(%opts) );
    $frame =
      $output->isa("Net::AMQP::Protocol::Base") ? $output->frame_wrap : $output;
    $frame->channel(2);
    _print($frame);
}

sub poll {
    my @frames = _read();
    my @result;
    foreach my $frame (@frames){
        if ( $frame->isa('Net::AMQP::Frame::Body') ) {
            push(@result, $frame->{payload});
        }
    }
    return @result;
}


sub _read {

    my $data;
    my $stack;

    # read lentgh (in Bytes)
    read( $remote, $data, 8 );
    $stack .= $data;
    my ( $type_id, $channel, $length ) = unpack 'CnN', substr $data, 0, 7, '';

    # read until $length bytes read
    while ( $length > 0 ) {
        $length -= read( $remote, $data, $length );
        $stack .= $data;
    }

    my @frames = Net::AMQP->parse_raw_frames( \$stack );
    print STDERR "<-- " . Dumper(@frames) if $debug;
    print STDERR "-----------\n" if $debug;
    return @frames;
}

sub callbacks {
    my @frames = shift;
    my $spec   = shift;
  FRAMES:
    foreach my $frame (@frames) {
        if ( $frame->isa('Net::AMQP::Frame::Method') ) {
            my $method_frame = $frame->method_frame;
            if ( $frame->channel == 0 ) {
                if (
                    $method_frame->isa(
                        'Net::AMQP::Protocol::Connection::Start')
                  )
                {
                    _print(
                        Net::AMQP::Protocol::Connection::StartOk->new(
                            client_properties => {
                                platform    => 'Perl/Norbu09',
                                product     => 'NetAMQP',
                                information => 'http://springtimesoft.com/',
                                version     => '1.0',
                            },
                            mechanism => 'AMQPLAIN',
                            response  => {
                                LOGIN    => $spec->{Username}->{default},
                                PASSWORD => $spec->{Password}->{default}
                            },
                            locale => 'en_US',
                        )
                    );
                    next FRAMES;
                }
                elsif (
                    $method_frame->isa('Net::AMQP::Protocol::Connection::Tune')
                  )
                {
                    _print(
                        Net::AMQP::Protocol::Connection::TuneOk->new(
                            channel_max => 0,
                            frame_max   => 131072,
                            heartbeat   => 0,
                        )
                    );
                    _print(
                        Net::AMQP::Frame::Method->new(
                            method_frame =>
                              Net::AMQP::Protocol::Connection::Open->new(
                                virtual_host => $spec->{VirtualHost}->{default},
                                capabilities => '',
                                insist       => 1,
                              ),
                        )
                    );
                    next FRAMES;
                }
                elsif (
                    $method_frame->isa(
                        'Net::AMQP::Protocol::Connection::OpenOk')
                  )
                {
                    my $output =
                      Net::AMQP::Frame::Method->new( method_frame =>
                          Net::AMQP::Protocol::Channel::Open->new(), );
                    my $frame =
                        $output->isa("Net::AMQP::Protocol::Base")
                      ? $output->frame_wrap
                      : $output;
                    $frame->channel(2);
                    _print($frame);
                    next FRAMES;
                }
            }
        }
    }
}

sub pub {
    my($queue, $message) = @_;
    
    my %method_opts = (
        ticket      => 0,
        #exchange    => '', # default exchange
        routing_key => $queue, # route to my queue
        mandatory   => 1,
        #immediate   => 0,
    );

    my %content_opts = (
        content_type     => 'application/octet-stream',
        #content_encoding => '',
        #headers          => {},
        delivery_mode    => 1, # non-persistent
        priority         => 1,
        #correlation_id   => '',
        #reply_to         => '',
        #expiration       => '',
        #message_id       => '',
        #timestamp        => time,
        #type             => '',
        #user_id          => '',
        #app_id           => '',
        #cluster_id       => '',
    );

    my $output = Net::AMQP::Protocol::Basic::Publish->new(%method_opts);
    my $frame = $output->isa("Net::AMQP::Protocol::Base") ? $output->frame_wrap : $output;
    $frame->channel(2);
    _print($frame);
    $output = Net::AMQP::Frame::Header->new(
        weight       => 0,
        body_size    => length($message),
        header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(%content_opts),
    );
    $frame = $output->isa("Net::AMQP::Protocol::Base") ? $output->frame_wrap : $output;
    $frame->channel(2);
    _print($frame);
    $output = Net::AMQP::Frame::Body->new(payload => $message);
    $frame = $output->isa("Net::AMQP::Protocol::Base") ? $output->frame_wrap : $output;
    $frame->channel(2);
    _print($frame);

}


sub _print {
    my $output = shift;
    if ( $output->isa("Net::AMQP::Protocol::Base") ) {
        $output = $output->frame_wrap;
    }
    $output->channel(0) unless defined $output->channel;

    print STDERR "--> " . Dumper($output) . "\n" if $debug;
    print $remote $output->to_raw_frame();
}

1;
