package Blog::Bluejay::App::catalyst;

use strict;
use warnings;

use Getopt::Chain::Declare::under 'catalyst';

our $TEST;

sub do_setup ($) {
    my $ctx = shift;

    unless ( -f $ctx->bluejay->file( 'assets/tt/frame.tt.html' ) ) { # TODO Make this stronger
        $ctx->bluejay->assets->deploy;
    }
}

sub run_script ($$@) {
    my $ctx = shift;
    my $script = shift;

    do_setup $ctx;

    $ENV{BLOG_BLUEJAY_HOME} = $ctx->bluejay->home;
    $ENV{$_} or $ENV{$_} = $ctx->bluejay->home for qw/BLOG_BLUEJAY_CATALYST_HOME/;
    if ( defined ( my $catalyst = $ctx->option( 'catalyst' ) ) ) {
        $ENV{BLOG_BLUEJAY_CATALYST} = $catalyst;
    }

    return if $TEST;

    exec( $^X => qw{ -w -MBlog::Bluejay::Script -e Blog::Bluejay::Script::run }, $script, @_ );
}

start [qw/ catalyst=s /];

on 'server --' => sub {
    my $ctx = shift;

    run_script $ctx, 'server', @_;
};

on 'fastcgi --' => sub {
    my $ctx = shift;

    run_script $ctx, 'fastcgi', @_;
};

on 'cgi --' => sub {
    my $ctx = shift;

    run_script $ctx, 'cgi', @_;
};

no Getopt::Chain::Declare::under;

1;


