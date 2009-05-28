package Blog::Jive::Catalyst::Controller::Status;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

#sub report {
#    my ( $self, $ctx ) = @_;
#    my $report;
#    unless ($report = $ctx->stash->{status_report}) {
#        $report = [ $ctx->model( 'Jive' )->status->report ];
#    }
#    return @{ $report };
#}

#sub default :Private {
#    my ( $self, $ctx ) = @_;
#    
#    my @report = $self->report( $ctx );
#}

#sub raw :Local {
#    my ( $self, $ctx ) = @_;

#    my @report = $self->report( $ctx );
#    if (! @report ) {
#        @report = ( "Everything looks okay" );
#    }

#    $ctx->response->content_type( 'text/plain' );
#    $ctx->response->body( join "\n", @report, "" );
#}

sub _tree($);
sub _tree($) {
    my $entity = shift;

    return if $entity =~ m/\.swp$/;
    return if $entity =~ m/assets\/content/;

    my %node;
    if (-f $entity) {
        $node{branch} = 0;
        $entity = Path::Class::File->new( $entity );
        $node{name} = $entity->basename;
    }
    elsif (-d $entity) {
        $node{branch} = 1;
        $entity = Path::Class::Dir->new( $entity );
        $node{name} = $entity->dir_list(-1);
        my @children;
        for ($entity->children) {
            push @children, _tree $_;
        }
        $node{children} = \@children;
    }
    else {
        return ();
#        croak "Uhh, what is $entity?";
    }

    $node{entity} = $entity;
    return \%node;
}

sub default :Private {
    my ( $self, $ctx ) = @_;
    
    my $jive = $ctx->stash->{jive};

    if ( $jive->ready ) {
        $ctx->stash(
            tree => _tree $jive->home,
        );
    }

    $ctx->stash(
#        template => $jive->assets->embed->{'tt/status/status.tt.html'},
        template => 'status/status.tt.html',
    );
}

1;
