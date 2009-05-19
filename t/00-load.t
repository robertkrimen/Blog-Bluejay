#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Blog::Jive' );
}

diag( "Testing Blog::Jive $Blog::Jive::VERSION, Perl $], $^X" );
