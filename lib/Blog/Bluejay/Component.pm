package Blog::Bluejay::Component;

use Moose::Role;

has bluejay => qw/is ro required 1 isa Blog::Bluejay/;

1;
