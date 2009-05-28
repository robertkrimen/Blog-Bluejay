package Blog::Bluejay::Catalyst::Model::Bluejay;

use strict;
use warnings;

use base qw/Catalyst::Model/;

use Moose;
use URI::PathAbstract;

has bluejay => qw/is rw/;
sub ACCEPT_CONTEXT {
    my ( $self, $ctx ) = @_;
    return $self->bluejay || do {
        my $bluejay = Blog::Bluejay->new( home => $ENV{BLOG_BLUEJAY_HOME}, uri => URI::PathAbstract->new( $ctx->request->base ) );
        $self->bluejay( $bluejay );
    };
}

1;
