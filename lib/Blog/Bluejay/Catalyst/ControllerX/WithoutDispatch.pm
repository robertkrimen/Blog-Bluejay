package Blog::Bluejay::Catalyst::ControllerX::WithoutDispatch;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

use Moose;
use Blog::Bluejay::Carp;


use YUI::Loader;
use jQuery::Loader;
use File::Assets;
use DateTimeX::Easy qw/datetime/;

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

sub action_page {
    my ( $self, $ctx, $page ) = @_;

    unless ( ref $page ) {
        my $path = $page;
        $page = $ctx->bluejay->page( $path ) or die "Couldn't find page for path \"$path\"";
    }

    $ctx->stash(
        page => $page,
        template => $page->template,
    );
}

sub action_index {
    my ( $self, $ctx ) = @_;

    if ( $ctx->bluejay->index_is_journal ) {
        $self->action_journal( $ctx );
    }
    else {
        $self->action_page( $ctx, 'home' );
    }
}

sub action_journal {
    my ( $self, $ctx ) = @_;

    $self->action_page( $ctx, 'journal' );
    $ctx->stash(
        posts => [ $ctx->bluejay->journal->published ],
    );
}

sub action_journal_year {
    my ( $self, $ctx, $year ) = @_;

    $self->action_page( $ctx, 'journal' );
    $ctx->stash(
        posts => [ $ctx->bluejay->journal->published->search( { creation => { -like => "$year-%" } } ) ],
    );
}

sub action_journal_month {
    my ( $self, $ctx, $month ) = @_;

    $month = datetime $_ or croak "Don't understand month $_" for $month;

    $self->action_page( $ctx, 'journal' );
    $ctx->stash(
        posts => [ $ctx->bluejay->journal->published->search( { creation => { -like => $month->strftime( '%Y-%m-%%' ) } } ) ],
    );
}

sub action_journal_post {
    my ( $self, $ctx, $uuid ) = @_;

    $uuid = $ctx->stash->{uuid} unless defined $uuid;
    my $post = $ctx->journal->post( $uuid );
    $ctx->stash(
        template => 'page/post.tt.html',
        post => $post,
    );
}

sub action_journal_post_asset {
    my ( $self, $ctx, $uuid, $asset) = @_;

    $uuid = $ctx->stash->{uuid} unless defined $uuid;
    my $post = $ctx->journal->post( $uuid );
    $asset = $post->asset( $asset );
    return unless $asset->render;

    $ctx->serve_static_file( $asset->file );
    return 1;
}

#sub action_journal_month {
#    my ( $self, $ctx, $month ) = @_;

#    $ctx->response->body( $month );
#}

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
#            summary   => '$description',
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
