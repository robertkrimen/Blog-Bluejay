package Blog::Bluejay::GetoptChain::help;

use strict;
use warnings;

use Getopt::Chain::Declare::under 'help';

on '' => sub {
    my $ctx = shift;
    return unless $ctx->last;
    $ctx->print( <<_END_ );
@{[ $ctx->usage ]}

    catalyst ( fastcgi | server | cgi ) ...
        Start a Catalyst service (similar to _fastcgi.pl, etc.)
        Any remaining arguments will be passed to the service launcher

    edit ( title | uuid | luid )
        Edit an existing post with the given title/uuid/luid, or
        create a new post with given title

    post <post>
        Show information about a post

    post-render <post>
        Render a post

    assets <post>
        List the assets for a post

    asset-render <asset>
        Render an asset

    posts
        Show a list of posts

    posts-reload
        Scan and reload posts from the document directory

    status
        Show blog status

Specifying a <post>:

    A post is designated by an exact title, an exact or partial uuid, or an luid

Specifying an <asset>:

    An asset is designated by: <post>/<path>
    Where: <post> is specified by an exact uuid, partial uuid, or luid
           <path> Should be the path of the asset under the post

You can get more help via:

    synopsis    A Blog::Bluejay command-line synopsis

---

    You can control the blog home directory with the --home option:

        blog-bluejay --home <home> ...

    Or by setting BLOG_BLUEJAY_HOME

        BLOG_BLUEJAY_HOME=<home> blog-bluejay ...

_END_
};

on 'edit' => sub {
    my $ctx = shift;
    $ctx->print( <<_END_ );
_END_
};

on 'synopsis' => sub {
    my $ctx = shift;
    $ctx->show_synopsis;
};

no Getopt::Chain::Declare::under;

1;
