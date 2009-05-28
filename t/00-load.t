#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Blog::Bluejay' );
}

diag( "Testing Blog::Bluejay $Blog::Bluejay::VERSION, Perl $], $^X" );
