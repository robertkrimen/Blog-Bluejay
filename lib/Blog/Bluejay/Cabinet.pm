package Blog::Bluejay::Cabinet;

use Moose;

extends qw/Document::TriPart::Cabinet/;

with qw/Blog::Bluejay::Component/;

has '+document_class' => (default => 'Blog::Bluejay::Cabinet::Document');

package Blog::Bluejay::Cabinet::Document;

use Moose;

extends qw/Document::TriPart::Cabinet::Document/;

after save => sub {
    my $self = shift;

    my $creation = $self->creation;
    my $modification = $self->modification;
    my $uuid = $self->uuid;
    my $header = $self->header;

    $self->cabinet->bluejay->model( 'Post' )->update_or_create( {
        uuid => $self->uuid,
        creation => $creation,
        modification => $modification,
        title => $header->{title},
        folder => $header->{folder},
    } );
};

1;

