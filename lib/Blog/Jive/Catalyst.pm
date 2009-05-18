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

__PACKAGE__->config(
    name => 'Blog::Jive::Catalyst',
    root => __PACKAGE__->path_to( qw/assets root/ ),
    'static' => {
        dirs => [qw/ static /],
    },
    'View::TT' => {
        INCLUDE_PATH => [ __PACKAGE__->path_to( qw/assets tt/ ), __PACKAGE__->path_to( qw/assets journal/ ) ],
        CATALYST_VAR => 'Catalyst',
    },
);

__PACKAGE__->setup();

1;
