package Blog::Bluejay::App::Catalyst;

use strict;
use warnings;

our $TEST;

sub do_setup ($) {
    my $ctx = shift;

    unless ( -f $ctx->bluejay->file( 'assets/tt/frame.tt.html' ) ) { # TODO Make this stronger
        $ctx->bluejay->assets->deploy;
    }
}

sub run_script ($$) {
    my $ctx = shift;
    my $script = shift;

    Blog::Bluejay::App::Catalyst::do_setup $ctx;

    $ENV{BLOG_BLUEJAY_HOME} = $ctx->bluejay->home;
    $ENV{$_} or $ENV{$_} = $ctx->bluejay->home for qw/BLOG_BLUEJAY_CATALYST_HOME/;

    return if $Blog::Bluejay::App::Catalyst::TEST;

    my @arguments = $ctx->arguments;
    shift @arguments;

    exec( $^X => qw{ -w -MBlog::Bluejay::Script -e Blog::Bluejay::Script::run }, $script, @arguments );
}

package Blog::Bluejay::App::server;

use Getopt::Chain::Declare::under 'server';

on '' => undef, sub {
    my $ctx = shift;

    Blog::Bluejay::App::Catalyst::run_script $ctx, 'server';
};

no Getopt::Chain::Declare::under;

package Blog::Bluejay::App::fastctgi;

use Getopt::Chain::Declare::under 'fastcgi';

on '' => undef, sub {
    my $ctx = shift;

    Blog::Bluejay::App::Catalyst::run_script $ctx, 'fastcgi';
};

no Getopt::Chain::Declare::under;

1;

