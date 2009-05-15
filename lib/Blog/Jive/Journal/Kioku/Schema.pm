package Blog::Jive::Journal::Kioku::Schema;

package Blog::Jive::Journal::Kioku::Schema::Post;

use strict;
use warnings;

use Moose;

has uuid => qw/is ro isa Str/;
has [qw/ folder title abstract /] => qw/is ro isa Str/;
has [qw/ creation /] => qw/is ro isa DateTime/;
has [qw/ modification /] => qw/is ro isa Maybe[DateTime]/;

1;
