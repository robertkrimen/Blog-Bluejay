package Blog::Bluejay::Status;

use warnings;
use strict;

use Moose;

with qw/Blog::Bluejay::Component/;

sub report {
    my $self = shift;

    my @report;
    push @report, $self->check_home;
    push @report, $self->check_layout;

    return @report;
}

sub check_home {
    my $self = shift;
    
    my $home = $self->bluejay->home;

    return 'home-missing' unless -e $home;
    return 'home-not-directory' unless -d _;
    return 'home-not-accessible' unless -r _ && -x _ && -w _;
    return;
}

sub check_layout {
    my $self = shift;

}

1;
