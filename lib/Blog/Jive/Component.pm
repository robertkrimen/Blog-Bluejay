package Blog::Jive::Component;

use Moose::Role;

has jive => qw/is ro required 1 isa Blog::Jive/;

1;
