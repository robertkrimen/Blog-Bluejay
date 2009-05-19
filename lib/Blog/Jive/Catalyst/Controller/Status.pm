package Blog::Jive::Catalyst::Controller::Status;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

sub report {
    my ( $self, $ctx ) = @_;
    my $report;
    unless ($report = $ctx->stash->{status_report}) {
        $report = [ $ctx->model( 'Jive' )->status->report ];
    }
    return @{ $report };
}

sub default :Private {
    my ( $self, $ctx ) = @_;
    
    my @report = $self->report( $ctx );
}

sub raw :Local {
    my ( $self, $ctx ) = @_;

    my @report = $self->report( $ctx );
    if (! @report ) {
        @report = ( "Everything looks okay" );
    }

    $ctx->response->content_type( 'text/plain' );
    $ctx->response->body( join "\n", @report, "" );
}

1;
