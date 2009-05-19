#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Blog::Jive;

my ($scratch, $jive);

$scratch = Directory::Scratch->new;
$jive = Blog::Jive->new( home => $scratch->dir( qw/home/ ) );

is( $jive->status->check_home, 'home-not-exist' );

$jive->assets->deploy;

is( $jive->status->check_home, undef );
