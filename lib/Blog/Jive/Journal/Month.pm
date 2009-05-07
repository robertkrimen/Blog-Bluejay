package Blog::Jive::Journal::Month;

use Moose;

has journal => qw/is ro required 1 isa Blog::Jive::Journal/;

has year => qw/is ro required 1 isa Int/;
has month => qw/is ro required 1 isa Int/;

has uri => qw/is ro lazy_build 1/;
sub _build_uri {
    my $self = shift;
    return $self->journal->uri->child( join '/', $self->year, $self->month );
}


sub parse {
    my $class = shift;
    my $month = shift;

    die "Wasn't given month to parse" unless $month;
    die "Unable to parse month $month" unless my ($year, $month_) = $month =~ m/\s*(\d{4})[^\d]*(\d{1,2})\s*$/;

    return __PACKAGE__->new( month => $month_, year => $year, @_ );
}

sub year_month {
    my $self = shift;
    return join '-', $self->year, $self->month;
}

sub posts {
    my $self = shift;
    my $year_month = $self->year_month;
    return $self->journal->posts->search({ creation => { -like => "$year_month%" } });
}

1;
