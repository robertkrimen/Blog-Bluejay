package Blog::Jive::App::Catalyst;

our $TEST;

sub do_setup ($) {
    my $ctx = shift;

    unless ( -f $ctx->jive->file( 'assets/tt/frame.tt.html' ) ) { # TODO Make this stronger
        $ctx->jive->assets->deploy;
    }
}

package Blog::Jive::App::server;

use Getopt::Chain::Declare::under 'server';

on '' => undef, sub {
    my $ctx = shift;

    Blog::Jive::App::Catalyst::do_setup $ctx;

    my $jive = $ctx->jive;

    $ENV{BLOG_JIVE_HOME} = $jive->home;
    $ENV{BLOG_JIVE_CATALYST_HOME} = $jive->home;

    return if $Blog::Jive::App::Catalyst::TEST;

    require Blog::Jive::Catalyst;

    # ---

    my $debug             = 0;
    my $fork              = 0;
    my $help              = 0;
    my $host              = undef;
    my $port              = $ENV{BLOG_JIVE_CATALYST_PORT} || $ENV{CATALYST_PORT} || 3000;
    my $keepalive         = 0;
    my $restart           = $ENV{BLOG_JIVE_CATALYST_RELOAD} || $ENV{CATALYST_RELOAD} || 0;
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

    Blog::Jive::Catalyst->run( $port, $host, {
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

