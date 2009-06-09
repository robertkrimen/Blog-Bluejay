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

sub about :Local {
    my ( $self, $ctx ) = @_;

    return $self->action_about( $ctx );
}

sub contact :Local {
    my ( $self, $ctx ) = @_;

    return $self->action_contact( $ctx );
}

sub journal_post_asset :Regex('^journal/.*-([A-Fa-f\d]{8}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{12})/asset(/.*)?') {
    my ( $self, $ctx ) = @_;

    my ($uuid, $asset) = @{ $ctx->request->captures };

    if ( ! $asset || $asset eq '/' ) {
        $ctx->response->redirect( $ctx->uri_for( "journal/$uuid" ) );
        $ctx->detach;
    }

    unless ( $self->action_journal_post_asset( $ctx, $uuid, $asset ) ) {
        return $self->action_not_found( $ctx );
    }
}

sub journal_post :Regex('^journal/.*-([A-Fa-f\d]{8}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{12})') {
    my ( $self, $ctx ) = @_;

    my ($uuid) = @{ $ctx->request->captures };

    return $self->action_journal_post( $ctx, $uuid );
}

sub feed_atom :Path('feed/atom') {
    my ( $self, $ctx ) = @_;

    return $self->action_feed_atom( $ctx );
}

sub default :Path {
    my ( $self, $ctx ) = @_;

    return $self->action_not_found( $ctx );
}

sub not_found :Private {
    my ( $self, $ctx ) = @_;

    return $self->action_not_found( $ctx );
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


