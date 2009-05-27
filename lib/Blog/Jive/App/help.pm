package Blog::Jive::App::help;

use Getopt::Chain::Declare::under 'help';

use Text::Chomped;

sub usage {
    return chomped <<_END_
Usage: blog-jive [--home=HOME] COMMAND [OPTIONS]
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

    synopsis    A Blog::Jive command-line synopsis

---

    You can control the blog home directory with the --home option:

        blog-jive --home <home> ...

    Or by setting BLOG_JIVE_HOME

        BLOG_JIVE_HOME=<home> blog-jive ...

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

    To setup a new blog in \$HOME/.blog-jive, run:
    
        blog-jive setup

    Create a new post with:

        blog-jive edit <title>

    Edit a post with:
    
        blog-jive edit <uuid>

    Launch your blog server with:

        blog-jive server

    To see this help again:

        blog-jive help synopsis

    For more help:

        blog-jive help

_END_
}

on 'synopsis' => undef, sub {
    my $ctx = shift;
    do_synopsis $ctx;
};

no Getopt::Chain::Declare::under;

1;
