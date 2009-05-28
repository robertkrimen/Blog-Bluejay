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
use Blog::Jive::Carp;

use Path::Class();

has home => qw/reader _home lazy_build 1/;
sub _build_home {
    my $self = shift;
    return $ENV{BLOG_JIVE_HOME} if defined $ENV{BLOG_JIVE_HOME};
    $self->guessed_home( 1 );
    # TODO Check for .bluejay (or whatever)
    # TODO Use Find::HomeDir (or whatever)
    return Path::Class::dir( $ENV{HOME}, '.blog-jive' );
}
has guessed_home => qw/is rw isa Bool default 0/; # TODO Invalid if called before ->home
sub home_exists {
    my $self = shift;
    return -e $self->home;
}
sub home {
    return shift->home_dir( @_ );
}
sub home_dir {
    return shift->path_mapper->dir( '/' );
}
has path_mapper => qw/is ro lazy_build 1/, handles => [qw/ dir file /];
sub _build_path_mapper {
    require Path::Mapper;
    my $self = shift;
    return Path::Mapper->new( base => $self->_home );
}

has uri => qw/is rw isa URI::PathAbstract lazy 1/, default => sub { croak "No URI was set" };
sub set_uri {
    require URI::PathAbstract;
    my $self = shift;
    $self->uri( URI::PathAbstract->new( shift ) );
}

sub BUILD {
    my $self = shift;
    my $given = shift;
    $self->set_uri( $given->{uri} ) if $given->{uri};
}

#has journal => qw/is ro lazy_build 1/;
#sub _build_journal {
#    require Blog::Jive::Journal;
#    my $self = shift;
#    return Blog::Jive::Journal->new( jive => $self );
#}

has cabinet => qw/is ro lazy_build 1/;
sub _build_cabinet {
    require Blog::Jive::Cabinet;
    require Document::TriPart::Cabinet::Storage::Disk;
    my $self = shift;
    my $storage = Document::TriPart::Cabinet::Storage::Disk->new( dir => $self->dir( 'assets/document' ) );
    my $cabinet = Blog::Jive::Cabinet->new( jive => $self, storage => $storage );
    return $cabinet;
}

use Scalar::Util qw/weaken/;

has schema_file => qw/is ro lazy_build 1/;
sub _build_schema_file {
    my $self = shift;
    return $self->file( 'run/bluejay.sqlite' );
}

has deploy => qw/is ro lazy_build 1/;
sub _build_deploy {
    require DBIx::Deploy;
    my $self = shift;
    my $deploy;
    $deploy = DBIx::Deploy->create(
        engine => "SQLite",
        database => [ $self->schema_file ],
        create => \<<_END_,
[% PRIMARY_KEY = "INTEGER PRIMARY KEY AUTOINCREMENT" %]
[% KEY = "INTEGER" %]

id INTEGER PRIMARY KEY AUTOINCREMENT,
insert_dtime DATE NOT NULL DEFAULT current_timestamp,

[% CLEAR %]
--
CREATE TABLE post (

    id                  [% PRIMARY_KEY %],
    uuid                TEXT NOT NULL,
    creation        DATE NOT NULL,
    modification            DATE,
    header              TEXT NULL,

    folder              TEXT,
    title               TEXT,
    abstract            TEXT,

    UNIQUE (uuid)
);
_END_
    );
};
has schema => qw/is ro lazy_build 1/;
sub _build_schema {
    require Blog::Jive::Schema;
    my $self = shift;
    my $schema = Blog::Jive::Schema->connect( $self->deploy->information );
    $schema->jive($self);
    weaken $schema->{jive};
    return $schema;
}

has modeler => qw/is ro lazy_build 1/;
sub _build_modeler {
    require Blog::Jive::Model;
    my $self = shift;
    my $model = Blog::Jive::Modeler->new( jive => $self, schema => $self->schema, namespace => '+Blog::Jive::Model' );
    return $model;
};

sub model {
    my $self = shift;
    return $self->modeler->model( @_ );
}

has assets => qw/is ro lazy_build 1/;
sub _build_assets {
    require Blog::Jive::Assets;
    my $self = shift;
    # TODO Implement overwrite option
    return Blog::Jive::Assets->new( base => $self->home );
}

has tt => qw/is ro lazy_build 1/;
sub _build_tt {
    require Template;
    my $self = shift;
    return Template->new({
        INCLUDE_PATH => [ $self->dir( 'assets/document' ) ],
    });
}

has journal => qw/is ro lazy_build 1/, handles => [qw/ post posts create_post /];
sub _build_journal {
    require Blog::Jive::Model::Journal;
    my $self = shift;
    return Blog::Jive::Model::Journal->new( jive => $self );
}

#has kit => qw/is ro lazy_build 1/, handles => [qw/ home home_dir /];
#sub _build_kit {
#    require Blog::Jive::Kit;
#    my $self = shift;
#    my @give;
#    push @give, uri => $self->uri if $self->uri;
#    return Blog::Jive::Kit->new( jive => $self, @give );
#}

#has status => qw/is ro lazy_build 1/;
#sub _build_status {
#    require Blog::Jive::Status;
#    my $self = shift;
#    # TODO Implement overwrite option
#    return Blog::Jive::Status->new( jive => $self );
#}

#sub ready {
#    my $self = shift;
#    return $self->status->check_home ? 0 : 1;
#}

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
