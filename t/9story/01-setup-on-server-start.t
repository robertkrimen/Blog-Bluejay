#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Blog::Jive;
use Blog::Jive::App;

my ($scratch, $jive);

$scratch = Directory::Scratch->new;
$jive = Blog::Jive->new( home => $scratch->dir( qw/.blog-jive/ ) );
$ENV{BLOG_JIVE_HOME} = $jive->home;
$Blog::Jive::App::Catalyst::TEST = 1;

ok( ! $jive->home_exists );

Blog::Jive::App->new->run([qw/ server /]);

ok( $jive->home_exists );
ok( -f $jive->kit->file( 'assets/tt/frame.tt.html' ) );

