package Blog::Bluejay::Catalyst::ControllerX::WithDispatch;

use strict;
use warnings;

use parent qw/Blog::Bluejay::Catalyst::ControllerX::WithoutDispatch/;

use Moose;
use YUI::Loader;
use jQuery::Loader;
use File::Assets;
use Blog::Bluejay;
use Text::Lorem::More;
use Document::TriPart::Cabinet;

sub auto :Private {
    my ( $self, $ctx ) = @_;

    return $self->prepare( $ctx );
}

sub index :Private {
    my ( $self, $ctx ) = @_;

    return $self->action_index( $ctx );
}

sub journal :Local {
    my ( $self, $ctx ) = @_;

    return $self->action_journal( $ctx );
}

#sub about :Local {
#    my ( $self, $ctx ) = @_;

#    return $self->action_about( $ctx );
#}

#sub contact :Local {
#    my ( $self, $ctx ) = @_;

#    return $self->action_contact( $ctx );
#}

sub journal_post :Chained('/') :PathPart('journal') :CaptureArgs(1) {
    my ( $self, $ctx, $post ) = @_;

    if ( $post =~ m/-?($Document::TriPart::Cabinet::UUID::re)$/ ) {
        $ctx->stash( uuid => $1 );
    }
    else {
        die "Don't understand $post";
    }
}

sub journal_post_ :Chained('journal_post') :PathPart('') :Args(0) {
    my ( $self, $ctx ) = @_;

    return $self->action_journal_post( $ctx );
}

sub journal_post_asset :Chained('journal_post') :PathPart('assets') {
    my ( $self, $ctx, $asset ) = @_;

    unless ( $self->action_journal_post_asset( $ctx, undef, $asset ) ) {
        return $self->action_not_found( $ctx );
    }
}

sub index_year :Regex('^(\d{4})(?:/|$)') {
    my ( $self, $ctx ) = @_;

    if ( $ctx->bluejay->index_is_journal ) {
        $ctx->forward( 'journal_year' );
    }
    else {
        $ctx->forward( 'default' );
    }
}

sub index_month :Regex('^(\d{4})/(\d{1,2})(?:/|$)') {
    my ( $self, $ctx ) = @_;

    if ( $ctx->bluejay->index_is_journal ) {
        $ctx->forward( 'journal_month' );
    }
    else {
        $ctx->forward( 'default' );
    }
}

sub journal_year :Regex('^journal/(\d{4})(?:/|$)') {
    my ( $self, $ctx ) = @_;

    my ($year) = @{ $ctx->request->captures };

    $self->action_journal_year( $ctx, "$year" );
}

sub journal_month :Regex('^journal/(\d{4})/(\d{1,2})(?:/|$)') {
    my ( $self, $ctx ) = @_;

    my ($year, $month) = @{ $ctx->request->captures };

    $self->action_journal_month( $ctx, "$year-$month-01" );
}

#sub journal_post_asset :Regex('^journal/.*-([A-Fa-f\d]{8}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{12})/asset(/.*)?') {
#    my ( $self, $ctx ) = @_;

#    my ($uuid, $asset) = @{ $ctx->request->captures };

#    if ( ! $asset || $asset eq '/' ) {
#        $ctx->response->redirect( $ctx->uri_for( "journal/$uuid" ) );
#        $ctx->detach;
#    }

#    unless ( $self->action_journal_post_asset( $ctx, $uuid, $asset ) ) {
#        return $self->action_not_found( $ctx );
#    }
#}

#sub journal_post :Regex('^journal/.*-([A-Fa-f\d]{8}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{12})/?$') {
#    my ( $self, $ctx ) = @_;

#    my ($uuid) = @{ $ctx->request->captures };

#    return $self->action_journal_post( $ctx, $uuid );
#}

sub feed_atom :Regex('(?:journal/)?feed/atom') {
    my ( $self, $ctx ) = @_;

    $self->action_feed_atom( $ctx );
}

sub default :Path {
    my ( $self, $ctx ) = @_;

    my $path = $ctx->request->path;

    if ( my $page = $ctx->bluejay->page( $path ) ) {
        $self->action_page( $ctx, $page );
    }
    else {
        $self->action_not_found( $ctx );
    }
}

sub not_found :Private {
    my ( $self, $ctx ) = @_;

    $self->action_not_found( $ctx );
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


