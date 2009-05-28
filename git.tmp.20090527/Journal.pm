package Blog::Jive::Journal;

use strict;
use warnings;

use Moose;
use Carp::Clan; # TODO Carp::Clan::Share

with qw/Blog::Jive::Component/;

has overview => qw/is ro lazy_build 1/;
sub _build_overview {
    require Blog::Jive::Journal::Overview;
    my $self = shift;
    return Blog::Jive::Journal::Overview->new( journal => $self );
}

sub uuid_path {
    return shift->cabinet->storage->uuid_path( @_ );
}

sub posts_for_home {
    my $self = shift;
    return $self->posts->slice(0, 9);
}

sub posts_for_index {
    my $self = shift;
    return $self->posts;
}

sub posts_for_month {
    my $self = shift;
    return $self->month( @_ )->posts;
}

sub month {
    require Blog::Jive::Journal::Month;
    my $self = shift;
    my $month = shift;
    $month = Blog::Jive::Journal::Month->parse($month, journal => $self);
    return $month;
}

1;

