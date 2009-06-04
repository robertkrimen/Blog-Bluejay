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

    return if $Blog::Bluejay::App::Catalyst::TEST;

    $script = $ctx->bluejay->file( join '/', qw/script/, $script ); # TODO Fix this... Path::Mapper maybe?

    die "Script \"$script\" does not exist" unless -f $script;
    die "Script \"$script\" is not executable" unless -r _ && -x _;

    my @arguments = $ctx->arguments;
    shift @arguments;

    exec( $^X => $script => @arguments );
}

package Blog::Bluejay::App::server;

use Getopt::Chain::Declare::under 'server';

on '' => undef, sub {
    my $ctx = shift;

    Blog::Bluejay::App::Catalyst::run_script $ctx, 'blog_bluejay_catalyst_server.pl';
};

no Getopt::Chain::Declare::under;

package Blog::Bluejay::App::fastctgi;

use Getopt::Chain::Declare::under 'fastcgi';

on '' => undef, sub {
    my $ctx = shift;

    Blog::Bluejay::App::Catalyst::run_script $ctx, 'blog_bluejay_catalyst_fastcgi.pl';
};

no Getopt::Chain::Declare::under;

1;

