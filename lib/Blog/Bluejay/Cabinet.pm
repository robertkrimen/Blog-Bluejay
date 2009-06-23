package Blog::Bluejay::Cabinet;

use Moose;

extends qw/Document::TriPart::Cabinet/;

with qw/Blog::Bluejay::Component/;

has '+document_class' => (default => 'Blog::Bluejay::Cabinet::Document');

package Blog::Bluejay::Cabinet::Document;

use Moose;

extends qw/Document::TriPart::Cabinet::Document/;

has loaded => qw/is rw/;

after load => sub {
    my $self = shift;
    $self->loaded( 1 );
};

sub luid {
    my $self = shift;
    return $self->header->{luid} unless @_;
    $self->header->{luid} = shift;
}

#before edit => sub {
#    my $self = shift;

#    for (qw/ luid /) {
#        exists $self->header->{$_} or $self->header->{$_} = $self->$_;
#    }
#};

before save => sub {
    my $self = shift;

#    if ( $self->loaded || $self->header->{luid} ) {
#        $luid = $self->luid;
#    }
#    else {
#        $luid = $self->cabinet->bluejay->luid->next;
#    }

    my $luid = $self->luid;
    $luid = $self->cabinet->bluejay->luid->next unless defined $luid && length $luid;
    $self->cabinet->bluejay->luid->take( $luid );

    $self->luid( $luid );
};

after save => sub {
    my $self = shift;

    my $creation = $self->creation;
    my $modification = $self->modification;
    my $uuid = $self->uuid;
    my $header = $self->header;

    $self->cabinet->bluejay->model( 'Post' )->update_or_create( {
        uuid => $self->uuid,
        luid => $self->luid,
        creation => $creation,
        modification => $modification,
        title => $header->{title},
# TODO description, excerpt
        status => $header->{status},
    } );
};

1;

