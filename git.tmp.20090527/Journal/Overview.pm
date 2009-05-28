package Blog::Jive::Journal::Overview;

use Moose;

has journal => qw/is ro required 1 isa Blog::Jive::Journal/;

has posts => qw/is ro lazy_build 1 isa ArrayRef/;
sub _build_posts {
    my $self = shift;
    return [ $self->journal->posts ];
}

has home => qw/is ro lazy_build 1/;
sub _build_home {
    my $self = shift;

    my $posts = $self->posts;
    my $count = scalar @$posts;
    my $uri = $self->journal->uri->clone;

    return { label => "Home", uri => $uri, count => $count };
}

has index => qw/is ro lazy_build 1/;
sub _build_index {
    my $self = shift;

    my $posts = $self->posts;
    $posts = [ @$posts[ 0 .. 9 ] ] if @$posts > 9;
    my $count = scalar @$posts;
    my $uri = $self->journal->uri->child( qw/index/ );

    return { label => "All", uri => $uri, count => $count };
}

has month_overview => qw/is ro lazy_build 1 isa HashRef/;
sub _build_month_overview {
    my $self = shift;

    my $posts = $self->posts;
    my %overview;

    my %month;
    for my $post (@$posts) {
        push @{ $month{$post->creation->strftime('%Y-%m')} }, $post;
    }
    my @month;
    my %_month;
    for (reverse sort keys %month) {
        my %__month = ( $self->_build_month($_, $month{$_}) );
        push @month, \%__month;
        $_month{$_} = \%__month;
    }

    $overview{month_order} = \@month;
    $overview{month} = \%_month;

    return \%overview;
}

sub _build_month {
    my $self = shift;
    my $month = shift;
    my $posts = shift;

    my $count = scalar @$posts;

    my ($yr, $mo) = split m/-/, $month;

    my $datetime = DateTime->new(year => $yr, month => $mo);
    my $month_year = $datetime->strftime('%B %Y');

    my $uri = $self->journal->uri->child("$yr/$mo");

    return (label => $month_year, month => $month, yr => $yr, mo => $mo, uri => $uri, count => $count);
}

sub month {
    return shift->month_overview->{month};
}

sub month_order {
    return shift->month_overview->{month_order};
}

1;
