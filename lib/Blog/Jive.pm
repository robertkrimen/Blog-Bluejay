package Blog::Jive;

use warnings;
use strict;

=head1 NAME

Blog::Jive 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=cut

use lib qw/_lib/;

use Moose;

use Path::Class;

has home => qw/reader _home lazy_build 1/;
sub _build_home {
    my $self = shift;
    $self->guessed_home( 1 );
    return dir( $ENV{HOME}, '.blog-jive' ); # TODO Use Find::HomeDir or whatever...
}
has guessed_home => qw/is rw isa Bool default 0/; # TODO Invalid if called before ->home

has uri => qw/is ro/; # For configuring the kit, hackish?

sub BUILD {
    my $self = shift;
    my $given = shift;
}

has kit => qw/is ro lazy_build 1/, handles => [qw/ home home_dir /];
sub _build_kit {
    require Blog::Jive::Kit;
    my $self = shift;
    my @give;
    push @give, uri => $self->uri if $self->uri;
    return Blog::Jive::Kit->new( jive => $self, @give );
}

has journal => qw/is ro lazy_build 1/;
sub _build_journal {
    require Blog::Jive::Journal;
    my $self = shift;
    return Blog::Jive::Journal->new( jive => $self );
}

has assets => qw/is ro lazy_build 1/;
sub _build_assets {
    require Blog::Jive::Assets;
    my $self = shift;
    # TODO Implement overwrite option
    return Blog::Jive::Assets->new( base => $self->kit->home );
}

has status => qw/is ro lazy_build 1/;
sub _build_status {
    require Blog::Jive::Status;
    my $self = shift;
    # TODO Implement overwrite option
    return Blog::Jive::Status->new( jive => $self );
}

sub ready {
    my $self = shift;
    return $self->status->check_home ? 0 : 1;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-project-jive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-jive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Blog::Jive


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Project-jive>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Project-jive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Project-jive>

=item * Search CPAN

L<http://search.cpan.org/dist/Project-jive/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Blog::Jive
