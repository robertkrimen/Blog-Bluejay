#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Blog::Jive;

my ($scratch, $jive);

$scratch = Directory::Scratch->new;
$jive = Blog::Jive->new( home => $scratch->dir( qw/.blog-jive/ ) );

ok( ! $jive->home_exists );

my $document = $jive->journal->cabinet->create;
$document->edit( \"" );

ok( $jive->home_exists );
