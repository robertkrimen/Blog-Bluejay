package Blog::Bluejay::Catalyst;

use strict;
use warnings;

use Blog::Bluejay;

use Catalyst::Runtime '5.70';

use parent qw/Catalyst/;
use Catalyst qw/-Debug
                ConfigLoader
                Static::Simple/;
our $VERSION = '0.01';

my @include_path;

__PACKAGE__->config(
    name => 'Blog::Bluejay::Catalyst',
    root => __PACKAGE__->path_to( qw/assets root/ ),
    'static' => {
        dirs => [qw/ static /],
    },
    'View::TT' => {
        INCLUDE_PATH => [
            ( -e 'assets_embed' ? Path::Class::File->new( qw/assets_embed tt/ )->absolute : () ),
            __PACKAGE__->path_to( qw/assets tt/ ),
            __PACKAGE__->path_to( qw/assets content/ )
        ],
        CATALYST_VAR => 'Catalyst',
    },
);

__PACKAGE__->setup();

sub bluejay {
    my $self = shift;
    return $self->model( 'Bluejay' );
}

sub layout {
    my $self = shift;
    return $self->bluejay->layout;
}

sub journal {
    my $self = shift;
    return $self->bluejay->journal;
}

1;
