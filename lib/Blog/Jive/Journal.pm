package Blog::Jive::Journal;

use strict;
use warnings;

use Moose;
use Carp::Clan;

with qw/Blog::Jive::Component/;

use Blog::Jive::Journal::Schema;
use Blog::Jive::Journal::Model;
use Blog::Jive::Journal::Month;
use Blog::Jive::Journal::Overview;

use Text::MultiMarkdown qw/markdown/;
use Scalar::Util qw/weaken/;
use Document::TriPart::Cabinet;
use Document::TriPart::Cabinet::Storage::Disk;

has uri => qw/is ro lazy_build 1/;
sub _build_uri {
    my $self = shift;
    return $self->jive->kit->uri->child(qw//);
}

has schema_file => qw/is ro lazy_build 1/;
sub _build_schema_file {
    my $self = shift;
    return $self->kit->file( 'run/journal.sqlite' );
}

has deploy => qw/is ro lazy_build 1/;
sub _build_deploy {
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
    my $self = shift;
    my $schema = Blog::Jive::Journal::Schema->connect( $self->deploy->information );
    $schema->journal($self);
    weaken $schema->{journal};
    return $schema;
}

has modeler => qw/is ro lazy_build 1/;
sub _build_modeler {
    my $self = shift;
    my $model = Blog::Jive::Journal::Modeler->new( journal => $self, schema => $self->schema, namespace => '+Blog::Jive::Journal::Model' );
    return $model;
};

has cabinet => qw/is ro lazy_build 1/;
sub _build_cabinet {
    my $self = shift;
    my $storage = Document::TriPart::Cabinet::Storage::Disk->new( dir => $self->journal_dir );
    my $cabinet = Blog::Jive::Journal::Cabinet->new( jive => $self->jive, storage => $storage );
    return $cabinet;
}

has journal_dir => qw/is ro lazy_build 1/;
sub _build_journal_dir {
    my $self = shift;
    return $self->jive->kit->dir( 'assets/journal');
}

has tt => qw/is ro lazy_build 1/;
sub _build_tt {
    my $self = shift;
    return Template->new({
        INCLUDE_PATH => [ $self->journal_dir.'' ],
    });
}

has overview => qw/is ro lazy_build 1/;
sub _build_overview {
    my $self = shift;
    return Blog::Jive::Journal::Overview->new( journal => $self );
}

sub uuid_path {
    return shift->cabinet->storage->uuid_path( @_ );
}

sub posts {
    my $self = shift;
    return $self->modeler->model( 'Post' )->search( @_ );
}

sub post {
    my $self = shift;
    my $uuid = shift;
    my ($post) = $self->modeler->model( 'Post' )->search( { uuid => $uuid } )->slice( 0 );
    return $post;
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
    my $self = shift;
    my $month = shift;
    $month = Blog::Jive::Journal::Month->parse($month, journal => $self);
    return $month;
}

package Blog::Jive::Journal::Cabinet;

use Moose;

extends qw/Document::TriPart::Cabinet/;

with qw/Blog::Jive::Component/;

has '+document_class' => (default => 'Blog::Jive::Journal::Cabinet::Document');

#after save => sub {
#    my $self = shift;
#    my $document = shift;
#    # TODO Move this to ::Journal or ::Journal::Cabinet ?
#    $self->jive->journal->commit( $document );
#};

package Blog::Jive::Journal::Cabinet::Document;

use Moose;

extends qw/Document::TriPart::Cabinet::Document/;

after save => sub {
    my $self = shift;

    my $creation = $self->creation;
    my $modification = $self->modification;
    my $uuid = $self->uuid;
    my $header = $self->header;

    $self->cabinet->jive->journal->modeler->model( 'Post' )->update_or_create( {
        uuid => $self->uuid,
        creation => $creation,
        modification => $modification,
        title => $header->{title},
        folder => $header->{folder},
    } );
};

1;
