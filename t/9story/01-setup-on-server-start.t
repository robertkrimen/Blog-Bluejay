#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Blog::Bluejay;
use Blog::Bluejay::App;

my ($scratch, $bluejay);

$scratch = Directory::Scratch->new;
$bluejay = Blog::Bluejay->new( home => $scratch->dir( qw/.blog-bluejay/ ) );
$ENV{BLOG_BLUEJAY_HOME} = $bluejay->home;
$Blog::Bluejay::App::catalyst::TEST = 1;

ok( ! $bluejay->home_exists );

Blog::Bluejay::App->new->run([qw/ server /]);

ok( $bluejay->home_exists );
ok( -f $bluejay->file( 'assets/tt/frame.tt.html' ) );

