#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Blog::Bluejay;

my ($scratch, $bluejay);

$scratch = Directory::Scratch->new;
$bluejay = Blog::Bluejay->new( home => $scratch->dir( qw/.blog-bluejay/ ) );

ok( ! $bluejay->home_exists );

my $document = $bluejay->cabinet->create;
$document->edit( \"" );

ok( $bluejay->home_exists );
