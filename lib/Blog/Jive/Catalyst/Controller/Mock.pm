package Blog::Jive::Catalyst::Controller::Mock;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

use Moose;

has catalog => qw/is ro lazy_build 1/;
sub _build_catalog {
    require CatalystXPathCatalog;
    my $catalog = CatalystXPathCatalog->new( catalog => <<_END_ );
/mock       mock/index.tt.html
_END_
    return $catalog;
}

sub default :Private {
    my ( $self, $ctx ) = @_;

    $ctx->stash( # TODO Meh.
        lorem => Text::Lorem::More->new,
    );
    
    $ctx->forward( '/not_found' ) unless $self->catalog->dispatch( $ctx );
}

1;
