package Blog::Jive::Catalyst::Controller::Root;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

__PACKAGE__->config->{namespace} = '';

use Moose;
use YUI::Loader;
use jQuery::Loader;
use File::Assets;
use Blog::Jive;
use Text::Lorem::More;

has catalog => qw/is ro lazy_build 1/;
sub _build_catalog {
    require CatalystXPathCatalog;
    my $catalog = CatalystXPathCatalog->new( catalog => <<_END_ );
/           index.tt.html
/mock       mock/index.tt.html
_END_
    return $catalog;
}

sub auto :Private {
    my ( $self, $ctx ) = @_;
    my $stash = $ctx->stash;
    my $yui = $stash->{yui} = YUI::Loader->new_from_internet;
    my $jquery = $stash->{jquery} = jQuery::Loader->new_from_internet;
    my $assets = $stash->{assets} = File::Assets->new( base => { dir =>  $ctx->path_to, uri => $ctx->uri_for, } );

    if ( 1 ) {
        my $jive = $ctx->model( 'Jive' );
        $ctx->stash(
            jive => $jive,
            journal => $jive->journal,
        );
    }

    return 1;
}

sub default :Private {
    my ( $self, $ctx ) = @_;

    $ctx->forward( 'not_found' ) unless $self->catalog->dispatch( $ctx );
}

sub mock :Local {
    my ( $self, $ctx ) = @_;

    $ctx->stash(
        lorem => Text::Lorem::More->new,
    );
    
    $ctx->forward( 'not_found' ) unless $self->catalog->dispatch( $ctx );
}

sub index :Private {
    my ( $self, $ctx ) = @_;

    my $journal = $ctx->stash->{journal};

    $ctx->stash(
        template => 'page/posts.tt.html',
        posts => [ $journal->posts ],
    );
}

#sub journal :Local {
#    my ( $self, $ctx ) = @_;

#    my $journal = $ctx->stash->{journal};

#    $ctx->stash(
#        template => 'journal/home.tt.html',
#        posts => [ $journal->posts ],
#    );
#}

#sub journal_month :Regex('^journal/(\d{4})/(\d{1,2})') {
#    my ( $self, $ctx ) = @_;

#    my $journal = $ctx->stash->{journal};
#    my ($year, $month) = @{ $ctx->request->captures };

#    $month = $journal->month( "$year-$month" );
#    $ctx->stash(
#        template => 'journal/month.tt.html',
#        posts => [ $month->posts ],
#    );
#}

sub journal_post :Regex('^post/.*-([A-Fa-f\d]{8}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{12})') {
    my ( $self, $ctx ) = @_;

    my $journal = $ctx->stash->{journal};
    my ($uuid) = @{ $ctx->request->captures };

    my $post = $journal->post( $uuid );
    $ctx->stash(
        template => 'page/post.tt.html',
        post => $post,
    );
}

sub feed_atom :Path('feed/atom') {
    my ( $self, $ctx ) = @_;

    use XML::Atom::SimpleFeed;

    my $feed = XML::Atom::SimpleFeed->new(
        title   => '$title',
        link    => $ctx->uri_for,
        link    => { rel => 'self', href => $ctx->uri_for( 'feed/atom' ) },
        author  => '$author',
    );

    my $journal = $ctx->stash->{journal};

    $ctx->stash(
        posts => [ $journal->posts ],
    );

    for my $post ($journal->posts) {
        $feed->add_entry(
            title     => $post->title,
            link      => $post->uri,
            id        => 'urn:uuid:' . $post->uuid,
            summary   => '$description',
            updated   => $post->local_creation,
        );
    }

    $ctx->response->content_type( 'application/atom+xml; charset=utf-8' );
    $ctx->response->body( $feed->as_string );
}

sub not_found :Private {
    my ( $self, $ctx ) = @_;
    $ctx->response->body( 'Page not found' );
    $ctx->response->status(404);
}

sub end : ActionClass('RenderView') {}

1;
