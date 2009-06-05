package Blog::Bluejay::Script::cgi;

use strict;
use warnings;

BEGIN { $ENV{CATALYST_ENGINE} ||= 'CGI' }

use Blog::Bluejay::Script;

sub run {
    my $self = shift;
    my @argv = @_;

    launch();
}

1;
