package Blog::Jive::Catalyst;

use strict;
use warnings;

use Blog::Jive;

use Catalyst::Runtime '5.70';

use parent qw/Catalyst/;
use Catalyst qw/-Debug
                ConfigLoader
                Static::Simple/;
our $VERSION = '0.01';

my @include_path;

__PACKAGE__->config(
    name => 'Blog::Jive::Catalyst',
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

1;
