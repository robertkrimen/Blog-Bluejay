package Blog::Bluejay::App::help;

use Getopt::Chain::Declare::under 'help';

use Text::Chomped;

sub usage {
    return chomped <<_END_
Usage: blog-bluejay [--home=HOME] COMMAND [OPTIONS]
_END_
}

sub do_usage ($) {
    my $ctx = shift;
    $ctx->print( <<_END_ );
@{[ usage ]}

        setup
        edit
        publish

        list 
        assets <key>

_END_
}

on '' => undef, sub {
    my $ctx = shift;
    return unless $ctx->last;
    $ctx->print( <<_END_ );
@{[ usage ]}

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

on 'edit' => undef, sub {
    my $ctx = shift;
    $ctx->print( <<_END_ );
_END_
};

sub do_synopsis ($) {
    my $ctx = shift;
    $ctx->print( <<_END_ );
@{[ usage ]}

    To setup a new blog in \$HOME/.blog-bluejay, run:
    
        blog-bluejay setup

    Create a new post with:

        blog-bluejay edit <title>

    Edit a post with:
    
        blog-bluejay edit <uuid>

    Launch your blog server with:

        blog-bluejay server

    To see this help again:

        blog-bluejay help synopsis

    For more help:

        blog-bluejay help

_END_
}

on 'synopsis' => undef, sub {
    my $ctx = shift;
    do_synopsis $ctx;
};

no Getopt::Chain::Declare::under;

1;
