package Blog::Bluejay::Assets::Embed;

use strict;
use warnings;

{
    my %catalog = (

'tt/status/status.tt.html' => \<<_END_,
[% BLOCK tree %]
<li>
    [% node.name %]
    [% IF node.branch %]
    <ul>
        [% FOREACH child = node.children %]
            [% INCLUDE tree parent = node, node = child %]
        [% END %]
    </ul>
    [% END %]
</li>
[% END %]

[% WRAPPER frame.tt.html %]

[% status = bluejay.status.check_home %]
[% IF status %]
[% ELSE %]
<code><pre>

    The home directory for this installation is <b>[% bluejay.home %]</b>

</pre></code>

<ul>
[% INCLUDE tree node = tree %]
</ul>

[% END %]

[% END %]

_END_

    );
    sub catalog {
        \%catalog
    }
}

1;
