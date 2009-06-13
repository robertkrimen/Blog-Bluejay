package Blog::Bluejay::GetoptChain::Context;

use Moose;

use Text::Chomped;

extends qw/Getopt::Chain::Context/;

has bluejay => qw/is ro lazy_build 1/;
sub _build_bluejay {
    my $self = shift;

    my $bluejay_home = $self->stash->{bluejay_home};

    my @bluejay;
    push @bluejay, home => $bluejay_home if defined $bluejay_home;

    my $class = Blog::Bluejay::GetoptChain->blog_bluejay_class;
    eval "require $class;" or die "Couldn't require Blog::Bluejay class \"$class\": $@"; # TODO Class::Inspector
    $class->new( @bluejay );
}

###########
# Utility #
###########

sub print {
    my $ctx = shift;
    $Blog::Bluejay::GetoptChain::PRINT->( @_ );
}

sub exit {
    my $ctx = shift;
    my $code = shift || 0;
    exit $code;
}

########
# Help #
########

sub usage {
    return chomped <<_END_
Usage: blog-bluejay [--home=HOME] COMMAND [OPTIONS]
_END_
}

sub show_usage {
    my $ctx = shift;
    $ctx->print( <<_END_ );
@{[ $ctx->usage ]}

        setup
        edit
        publish

        list 
        assets <key>

_END_
}

sub show_synopsis {
    my $ctx = shift;
    $ctx->print( <<_END_ );
@{[ $ctx->usage ]}

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

########
# Post #
########

sub create_post {
    my ( $ctx, $title ) = @_;

    my $document = $ctx->bluejay->cabinet->create;
    $document->header->{title} = $title;
    $document->edit;
    return $document;
}

sub find_post {
    my $ctx = shift;
    my @criteria = @_;

    return unless @criteria;

    my $criteria = $criteria[0];
#    my ($folder, $title) = folder_title @criteria;

    my ($search, $post, $count);
    $search = $ctx->bluejay->posts(
        [ 
#            { title => $criteria },
#            { folder => $folder, title => $title },
            { uuid => { -like => "$criteria%" } },
        ],
        {}
    );

    $count = $search->count;
    ($post) = $search->slice(0, 0) if 1 == $count;

    return wantarray ? ($post, $search, $count) : $post;
}

sub list_posts {
    my $ctx = shift;
    my $search = shift;

    $search = scalar $ctx->bluejay->posts unless $search;
    my @posts = $search->search( undef, { order_by => [qw/ creation /] } )->all;

    my $tb = Text::ASCIITable->new({ hide_HeadLine => 1 });
    $tb->setCols( '', '', '' );
    $tb->addRow( $_->uuid, $_->title, $_->folder ) for @posts;
    $ctx->print( $tb );
}

#########
# Error #
#########

sub error_exit {
    my $ctx = shift;
    $ctx->print( @_ ) if @_;
    $ctx->exit( -1 );
}

sub error_no_post_criteria {
    my $ctx = shift;
    $ctx->list_posts;
    $ctx->error_exit;
}

sub error_no_list_posts_criteria {
    my $ctx = shift;
    $ctx->list_posts;
    $ctx->error_exit;
}

sub error_too_many_posts {
    my $ctx = shift;
    my $search = shift;

    $ctx->print( "Too many posts found matching your criteria\n" );
    $ctx->list_posts( $search );
    $ctx->error_exit;
}

sub error_usage {
    my $ctx = shift;

    if ( $ctx->bluejay->home_exists ) {
        $ctx->show_usage;
        $ctx->list_posts;
    }
    else {
        &Blog::Bluejay::GetoptChain::help::do_synopsis( $ctx );
    }

}

sub error_no_command {
    my $ctx = shift;

    $ctx->error_usage;
    $ctx->exit( -1 );
}

sub error_unknown_command {
    my $ctx = shift;

    my $command = join ' ', $ctx->path;
    $ctx->print( "blog-bluejay: Unknown command \"$command\"\n\n" );
    $ctx->error_usage;
    $ctx->error_exit;
}

1;

__END__

sub find_post {
    my $ctx = shift;
    my @criteria = @_;

    $ctx->list_posts, $ctx->exit( -1 ) unless @criteria;

    my ($post, $search, $count) = $ctx->_find_post( @criteria );

    $ctx->abort( "No post found matching your criteria" ) unless $count;

    choose $search if $count > 1;

    return $post;
}

