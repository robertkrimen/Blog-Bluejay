package Blog::Bluejay::GetoptChain::help;

use strict;
use warnings;

use Getopt::Chain::Declare::under 'help';

on '' => sub {
    my $ctx = shift;
    return unless $ctx->last;
    $ctx->print( <<_END_ );
@{[ $ctx->usage ]}

    edit       Edit a blog post
    server     Launch a blog server via Catalyst::Engine::HTTP
    setup      Create an empty blog and deploy assets

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
