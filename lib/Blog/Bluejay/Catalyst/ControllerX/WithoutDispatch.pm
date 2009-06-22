package Blog::Bluejay::Catalyst::ControllerX::WithoutDispatch;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

use Moose;
use YUI::Loader;
use jQuery::Loader;
use File::Assets;

sub prepare {
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

sub action_index {
    my ( $self, $ctx ) = @_;

    if ( my $home = $ctx->layout->home ) {
        $self->action_home( $ctx );
    }
    else {
        $self->action_journal( $ctx );
    }
}

sub action_home {
    my ( $self, $ctx ) = @_;

    $ctx->layout->home->render( $ctx );
}

sub action_journal {
    my ( $self, $ctx ) = @_;

    $ctx->layout->journal->render( $ctx );
}

sub action_about {
    my ( $self, $ctx ) = @_;

    $ctx->layout->about->render( $ctx );
}

sub action_contact {
    my ( $self, $ctx ) = @_;

    $ctx->layout->contact->render( $ctx );
}

sub action_journal_post {
    my ( $self, $ctx, $uuid ) = @_;

    my $post = $ctx->journal->post( $uuid );
    $ctx->stash(
        template => 'page/post.tt.html',
        post => $post,
    );
}

sub action_journal_post_asset {
    my ( $self, $ctx, $uuid, $asset) = @_;

    my $post = $ctx->journal->post( $uuid );
    $asset = $post->asset( $asset );
    return unless $asset->render;

    $ctx->serve_static_file( $asset->file );
    return 1;
}

sub action_feed_atom {
    my ( $self, $ctx ) = @_;

    use XML::Atom::SimpleFeed;

    my $feed = XML::Atom::SimpleFeed->new(
        title   => '$title',
        link    => $ctx->uri_for,
        link    => { rel => 'self', href => $ctx->uri_for( 'feed/atom' ) },
        author  => '$author',
    );

    my $journal = $ctx->journal;

    my @posts = $journal->published;

    $ctx->stash(
        posts => \@posts,
    );

    for my $post (@posts) {
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

sub action_not_found {
    my ( $self, $ctx ) = @_;

    $ctx->response->body( 'Page not found' );
    $ctx->response->status( 404 );
}

1;
