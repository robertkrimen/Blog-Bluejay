package Blog::Bluejay::App::Catalyst;

our $TEST;

sub do_setup ($) {
    my $ctx = shift;

    unless ( -f $ctx->bluejay->file( 'assets/tt/frame.tt.html' ) ) { # TODO Make this stronger
        $ctx->bluejay->assets->deploy;
    }
}

package Blog::Bluejay::App::server;

use Getopt::Chain::Declare::under 'server';

on '' => undef, sub {
    my $ctx = shift;

    Blog::Bluejay::App::Catalyst::do_setup $ctx;

    my $bluejay = $ctx->bluejay;

    $ENV{BLOG_BLUEJAY_HOME} = $bluejay->home;
    $ENV{BLOG_BLUEJAY_CATALYST_HOME} = $bluejay->home;

    return if $Blog::Bluejay::App::Catalyst::TEST;

    require Blog::Bluejay::Catalyst;

    # ---

    my $debug             = 0;
    my $fork              = 0;
    my $help              = 0;
    my $host              = undef;
    my $port              = $ENV{BLOG_BLUEJAY_CATALYST_PORT} || $ENV{CATALYST_PORT} || 3000;
    my $keepalive         = 0;
    my $restart           = $ENV{BLOG_BLUEJAY_CATALYST_RELOAD} || $ENV{CATALYST_RELOAD} || 0;
    my $restart_delay     = 1;
    my $restart_regex     = '(?:/|^)(?!\.#).+(?:\.yml$|\.yaml$|\.conf|\.pm)$';
    my $restart_directory = undef;
    my $follow_symlinks   = 0;
    my $background        = 0;
    my @argv;

    BEGIN {
        $ENV{CATALYST_ENGINE} ||= 'HTTP';
        $ENV{CATALYST_SCRIPT_GEN} = 33;
        require Catalyst::Engine::HTTP;
    }

    if ( $restart && $ENV{CATALYST_ENGINE} eq 'HTTP' ) {
        $ENV{CATALYST_ENGINE} = 'HTTP::Restarter';
    }
    if ( $debug ) {
        $ENV{CATALYST_DEBUG} = 1;
    }

    Blog::Bluejay::Catalyst->run( $port, $host, {
        argv              => \@argv,
        'fork'            => $fork,
        keepalive         => $keepalive,
        restart           => $restart,
        restart_delay     => $restart_delay,
        restart_regex     => qr/$restart_regex/,
        restart_directory => $restart_directory,
        follow_symlinks   => $follow_symlinks,
        background        => $background,
    } );
};

no Getopt::Chain::Declare::under;

1;

