package Blog::Bluejay::Journal;

use strict;
use warnings;

use Moose;
use Carp::Clan; # TODO Carp::Clan::Share

with qw/Blog::Bluejay::Component/;

has overview => qw/is ro lazy_build 1/;
sub _build_overview {
    require Blog::Bluejay::Journal::Overview;
    my $self = shift;
    return Blog::Bluejay::Journal::Overview->new( journal => $self );
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
    require Blog::Bluejay::Journal::Month;
    my $self = shift;
    my $month = shift;
    $month = Blog::Bluejay::Journal::Month->parse($month, journal => $self);
    return $month;
}

1;

