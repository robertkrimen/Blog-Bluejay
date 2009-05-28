package Blog::Bluejay::Catalyst::Controller::Root;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

__PACKAGE__->config->{namespace} = '';

use Moose;
use YUI::Loader;
use jQuery::Loader;
use File::Assets;
use Blog::Bluejay;
use Text::Lorem::More;

sub auto :Private {
    my ( $self, $ctx ) = @_;

    my $stash = $ctx->stash;
    my $yui = $stash->{yui} = YUI::Loader->new_from_internet;
    my $jquery = $stash->{jquery} = jQuery::Loader->new_from_internet;
    my $assets = $stash->{assets} = File::Assets->new( base => { dir =>  $ctx->path_to, uri => $ctx->uri_for, } );

    $ctx->stash(
        bluejay => $ctx->bluejay,
        journal => $ctx->journal,
        layout => $ctx->layout,
    );

    return 1;
}

sub index :Private {
    my ( $self, $ctx ) = @_;

    if ( my $home = $ctx->layout->home ) {
        $home->render( $ctx );
    }
    else {
        $ctx->forward( 'journal' );
    }
}

sub journal :Local {
    my ( $self, $ctx ) = @_;

    $ctx->layout->journal->render( $ctx );
}

sub about :Local {
    my ( $self, $ctx ) = @_;

    $ctx->layout->about->render( $ctx );
}

sub contact :Local {
    my ( $self, $ctx ) = @_;

    $ctx->layout->contact->render( $ctx );
}

sub journal_post :Regex('^journal/.*-([A-Fa-f\d]{8}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{12})') {
    my ( $self, $ctx ) = @_;

    my ($uuid) = @{ $ctx->request->captures };

    my $post = $ctx->journal->post( $uuid );
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

    my $journal = $ctx->journal;

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

