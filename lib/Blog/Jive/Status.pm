package Blog::Jive::Status;

use warnings;
use strict;

use Moose;

use URI::PathAbstract;

with qw/Blog::Jive::Component/;

sub report {
    my $self = shift;

    my @report;
    push @report, $self->check_home;
    push @report, $self->check_assets;

    return @report;
}

sub check_home {
    my $self = shift;
    
    my $home = $self->jive->home;

    return 'home-not-exist' unless -e $home;
    return 'home-not-directory' unless -d _;
    return 'home-not-permitted' unless -r _ && -x _ && -w _;
    return;
}

sub check_assets {

}

1;
