package Blog::Jive::Catalyst::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

use Moose;
use YUI::Loader;
use jQuery::Loader;
use File::Assets;
use CatalystXPathCatalog;
use Blog::Jive;

has catalog => qw/is ro lazy_build 1/;
sub _build_catalog {
    my $catalog = CatalystXPathCatalog->new( catalog => <<_END_ );
/           index.tt.html
#/journal    journal/home.tt.html
_END_
    return $catalog;
}

sub auto :Private {
    my ( $self, $ctx ) = @_;
    my $stash = $ctx->stash;
    my $yui = $stash->{yui} = YUI::Loader->new_from_internet;
    my $jquery = $stash->{jquery} = jQuery::Loader->new_from_internet;
    my $assets = $stash->{assets} = File::Assets->new( base => { dir =>  $ctx->path_to, uri => $ctx->uri_for, } );

    if ($ctx->request->path =~ m/journal(\/|$)/) {
        my $jive = Blog::Jive->new;
        $jive->kit->uri( URI::PathAbstract->new( $ctx->request->base ) );
        my $journal = $jive->journal;
        $ctx->stash->{journal} = $journal;
    }

    return 1;
}

sub default :Path {
    my ( $self, $ctx ) = @_;

    $ctx->forward( 'not_found' ) unless $self->catalog->dispatch( $ctx );
}

sub journal :Local {
    my ( $self, $ctx ) = @_;

    my $journal = $ctx->stash->{journal};

    $ctx->stash(
        template => 'journal/home.tt.html',
        posts => [ $journal->posts ],
    );
}

sub journal_month :Regex('^journal/(\d{4})/(\d{1,2})') {
    my ( $self, $ctx ) = @_;

    my $journal = $ctx->stash->{journal};
    my ($year, $month) = @{ $ctx->request->captures };

    $month = $journal->month( "$year-$month" );
    $ctx->stash(
        template => 'journal/month.tt.html',
        posts => [ $month->posts ],
    );
}

sub journal_post :Regex('^journal/.*-([A-Fa-f\d]{8}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{4}-[A-Fa-f\d]{12})') {
    my ( $self, $ctx ) = @_;

    my $journal = $ctx->stash->{journal};
    my ($uuid) = @{ $ctx->request->captures };

    my $post = $journal->post( $uuid );
    $ctx->stash(
        template => 'journal/post.tt.html',
        post => $post,
    );
}

sub not_found :Private {
    my ( $self, $ctx ) = @_;
    $ctx->response->body( 'Page not found' );
    $ctx->response->status(404);
}

sub end : ActionClass('RenderView') {}

1;
