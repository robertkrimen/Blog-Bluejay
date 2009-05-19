package Blog::Jive::Catalyst::Model::Jive;

use strict;
use warnings;

use base qw/Catalyst::Model/;

use Moose;
use URI::PathAbstract;

has jive => qw/is rw/;
sub ACCEPT_CONTEXT {
    my ( $self, $ctx ) = @_;
    return $self->jive || do {
        my $jive = Blog::Jive->new( home => $ENV{BLOG_JIVE_HOME}, uri => URI::PathAbstract->new( $ctx->request->base ) );
        $self->jive( $jive );
    };
}

1;
