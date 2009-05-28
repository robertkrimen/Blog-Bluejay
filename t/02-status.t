#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Blog::Bluejay;

my ($scratch, $bluejay);

ok( 1 ) and exit;

__END__

$scratch = Directory::Scratch->new;
$bluejay = Blog::Bluejay->new( home => $scratch->dir( qw/home/ ) );

is( $bluejay->status->check_home, 'home-missing' );
ok( ! $bluejay->guessed_home );

# TODO: Check accessible, is directory

$bluejay->assets->deploy;

is( $bluejay->status->check_home, undef );
