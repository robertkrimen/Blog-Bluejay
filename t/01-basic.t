#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Blog::Bluejay;

{
    local $ENV{BLOG_BLUEJAY_HOME} = 'null';

    my $bluejay = Blog::Bluejay->new;
    is( $bluejay->home, 'null' );
}
