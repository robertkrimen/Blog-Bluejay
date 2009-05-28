package Blog::Bluejay::Assets::Embed;

use strict;
use warnings;

{
    my %catalog = (

'tt/status/status.tt.html' => \<<_END_,
[% INSERT tt/status/status.tt.html %]
_END_

    );
    sub catalog {
        \%catalog
    }
}

1;
