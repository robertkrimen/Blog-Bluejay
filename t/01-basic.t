#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Blog::Jive;

{
    local $ENV{BLOG_JIVE_HOME} = 'null';

    my $jive = Blog::Jive->new;
    is( $jive->home, 'null' );
}
