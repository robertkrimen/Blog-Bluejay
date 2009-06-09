package Blog::Bluejay;

use warnings;
use strict;

=head1 NAME

Blog::Bluejay 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=cut

use lib qw/_lib/;

use Moose;
use Blog::Bluejay::Carp;

use Path::Class();
use Class::Inspector;
use Scalar::Util qw/weaken/;

#sub catalyst_class { 'Blog::Bluejay::Catalyst' }

has home => qw/reader _home lazy_build 1/;
sub _build_home {
    my $self = shift;
    return $ENV{BLOG_BLUEJAY_HOME} if defined $ENV{BLOG_BLUEJAY_HOME};
    $self->guessed_home( 1 );
#    if ( Class::Inspector->loaded( 'Blog::Bluejay::Catalyst' ) ) {
#        return Blog::Bluejay::Catalyst->path_to;
#    }
    # TODO Check for .bluejay (or whatever)
    # TODO Use Find::HomeDir (or whatever)
    return Path::Class::dir( $ENV{HOME}, '.blog-bluejay' );
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
    my $self = shift;
    if ( @_ ) {
        $self->path_mapper->base( shift );
    }
    return $self->path_mapper->dir( '/' );
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

has _config => qw/is ro lazy_build 1/;
sub _build__config {
    require Config::JFDI;
    my $self = shift;
    my $config = Config::JFDI->new( name => 'bluejay', path => $self->home );
    return $config;
}
sub config {
    return shift->_config->get;
}

has cabinet => qw/is ro lazy_build 1/;
sub _build_cabinet {
    require Blog::Bluejay::Cabinet;
    require Document::TriPart::Cabinet::Storage::Disk;
    my $self = shift;
    my $storage = Document::TriPart::Cabinet::Storage::Disk->new( dir => $self->dir( 'assets/document' ) );
    my $cabinet = Blog::Bluejay::Cabinet->new( bluejay => $self, storage => $storage );
    return $cabinet;
}

has schema_file => qw/is ro lazy_build 1/;
sub _build_schema_file {
    my $self = shift;
    return $self->file( 'run/bluejay.sqlite' );
}

has deploy => qw/is ro lazy_build 1/;
sub _build_deploy {
    require Blog::Bluejay::DBIxSQLiteDeploy;
    my $self = shift;
    my $deploy;
    $deploy = Blog::Bluejay::DBIxSQLiteDeploy->create( 
        connection => [ $self->schema_file ],
        schema => <<_END_,
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
    require Blog::Bluejay::Schema;
    my $self = shift;
    my $schema = Blog::Bluejay::Schema->connect( $self->deploy->information );
    $schema->bluejay($self);
    weaken $schema->{bluejay};
    return $schema;
}

has modeler => qw/is ro lazy_build 1/;
sub _build_modeler {
    require Blog::Bluejay::Model;
    my $self = shift;
    my $model = Blog::Bluejay::Modeler->new( bluejay => $self, schema => $self->schema, namespace => '+Blog::Bluejay::Model' );
    return $model;
};

sub model {
    my $self = shift;
    return $self->modeler->model( @_ );
}

has assets => qw/is ro lazy_build 1/;
sub _build_assets {
    require Blog::Bluejay::Assets;
    my $self = shift;
    # TODO Implement overwrite option
    return Blog::Bluejay::Assets->new( base => $self->home );
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
    require Blog::Bluejay::Model::Journal;
    my $self = shift;
    return Blog::Bluejay::Model::Journal->new( bluejay => $self );
}

has layout => qw/is ro lazy_build 1/;
sub _build_layout {
    require Blog::Bluejay::Layout;
    my $self = shift;
    my $layout = Blog::Bluejay::Layout->new( bluejay => $self );
    $layout->parse( $self->config->{page} || {} ); # TODO Should this be ->{layout} ?
    return $layout;
}

sub BUILD {
    my $self = shift;
    my $given = shift;
    $self->set_uri( $given->{uri} ) if $given->{uri};
}

has inflate_map => qw/is ro required 1 lazy 1 isa HashRef/, default => sub { {} };
my %loaded_inflator;

sub inflate {
    my $self = shift;
    my $moniker = shift;

    my $inflator = $self->inflate_map->{$moniker};
    $inflator = join '::', ref $self, $moniker unless defined $inflator;

    if ( ref $inflator eq 'CODE' ) {
        return $inflator->( $moniker, @_ );
    }
    else {
        unless ( $loaded_inflator{ $inflator } ||= Class::Inspector->loaded( $inflator ) ) {
            eval "require $inflator;" or die $@
        }
        return $inflator->new( @_ );
    }
}

{
    my $markdown;
    sub _markdown() {
        require Text::MultiMarkdown;
        return $markdown ||= Text::MultiMarkdown->new;
    }
}

sub render_post_body {
    my $self = shift;
    my $body = shift;

    my $post = $body->post;
    my $header = $post->document->header;
    my $type = $header->{type} || $header->{content_type} || ''; # TODO Make this configurable
    $type = 'tt-markdown' if $type =~ m/text\/.*markdown/;

    my $render = $body->raw;
    if ($type =~ m/\btt\b/) {
        my $tt = $self->tt;
        my $ASSETS = join '/', $post->assets_dir->dir_list( -3 );
        my $input = \$render;
        my $output;
        $tt->process( $input, { post => $post, ASSETS => $ASSETS }, \$output ) or die $tt->error;
        $render = $output;
    }

    if ($type =~ m/\bmarkdown\b/) {
        $render = _markdown->markdown( $render );
        $render =~ s{(\n)<pre><code>(\s*)}{$1<pre class="code"><code>$2}g; # TODO Urgh, ...
    }

    return $render;
}

sub render_post_asset {
    my $self = shift;
    my $asset = shift;

    my $file = $asset->rsc->file;

    if ( -f $file && -s _ ) {
        return \ scalar $file->slurp;
    }

    if ( $file =~ s/\.html$/\.tt.html/ &&  -f $file && -s _ ) {
        $file = Path::Class::file $file;
        my $tt = $self->tt;
        my $input = \ scalar $file->slurp;
        my $output;
        $tt->process( $input, { post => $asset->post, asset => $asset }, \$output ) or die $tt->error;  
        $asset->rsc->file->openw->print( $output );
        return \ $output;
    }

    return undef;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-project-bluejay at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-bluejay>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Blog::Bluejay


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Project-bluejay>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Project-bluejay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Project-bluejay>

=item * Search CPAN

L<http://search.cpan.org/dist/Project-bluejay/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Blog::Bluejay
