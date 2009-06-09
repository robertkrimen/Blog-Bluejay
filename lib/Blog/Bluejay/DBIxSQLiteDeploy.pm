package Blog::Bluejay::DBIxSQLiteDeploy;

use Moose;

has schema_parser => qw/is ro lazy_build 1/;
sub _build_schema_parser {
    require SQL::Script;
    return SQL::Script->new( split_by => qr/\n\s*-{2,4}\n/ );
};

has tt => qw/is ro lazy_build 1/;
sub _build_tt {
    require Template;
    return Template->new({});
};

has schema => qw/is ro/;
has connection => qw/is ro required 1/;

sub create {
    my $class = shift;
    my %given = @_;

    my $connection = Blog::Bluejay::DBIxSQLiteDeploy::Connection->parse( delete $given{connection} );

    return $class->new( connection => $connection, %given );
}

sub deploy {
    my $self = shift;

    my $connection = $self->connection;

    if ( my $schema = $self->schema ) {

        unless ( $connection->database_exists ) {
            {
                my $input = $schema;
                my $output;
                $self->tt->process( \$input, {}, \$output ) or die $self->tt->error;
                $schema = $output;
            }
            $self->schema_parser->read( \$schema );
            my @statements = $self->schema_parser->statements;
            {
                my $dbh = $connection->connect;
                for my $statement ( @statements ) {
                    chomp $statement;
                    $dbh->do( $statement ) or die $dbh->errstr;
                }
                $dbh->disconnect;
            }
        }
    }

    $connection->disconnect; # TODO huh?

    return $connection->information;
}

sub information {
    my $self = shift;
    my %given = @_;
    $given{deploy} = 1 unless exists $given{deploy};
    $self->deploy if $given{deploy};
    return $self->connection->information;
}

1;

package Blog::Bluejay::DBIxSQLiteDeploy::Connection;

use strict;
use warnings;

use Moose;

use Carp;

has [qw/ source database username password attributes /] => qw/is ro/;
has handle => qw/ is ro lazy_build 1 /;
sub _build_handle {
    my $self = shift;
    return $self->connect;
}

sub dbh {
    return shift->handle;
}

sub open {
    return shift->handle;
}

sub close {
    my $self = shift;
    if ( $self->{handle} ) {
        $self->handle->disconnect;
        $self->meta->get_attribute( 'handle' )->clear_value( $self );
    }
}

sub disconnect {
    my $self = shift;
    return $self->close;
}

sub connect {
    my $self = shift;
    require DBI;
    return DBI->connect( $self->information );
}

before connect => sub {
    my $self = shift;
    my $database = Path::Class::Dir->new( $self->database );
    $database->parent->mkpath unless -d $database->parent;
};

sub connectable {
    my $self = shift;

    my ($source, $username, $password, $attributes) = $self->information;
    $attributes ||= {};
    $attributes->{$_} = 0 for qw/PrintWarn PrintError RaiseError/;
    my $dbh = DBI->connect($source, $username, $password, $attributes);
    my $success = $dbh && ! $dbh->err && $dbh->ping;
    $dbh->disconnect if $dbh;
    return $success;
}


sub database_exists {
    my $self = shift;
    return -f $self->database && -s _ ? 1 : 0;
}

sub parse {
    my $class = shift;
    my $given = shift;

    my ( $database, $attributes );
    if ( ref $given eq "ARRAY" ) {
        ( $database, $attributes ) = @{ $given };
    }
    elsif ( ref $given eq "HASH" ) {
        ( $database, $attributes ) = @{ $given }{qw/ database attributes /};
    }
    elsif ( blessed $given && $given->isa( __PACKAGE__ ) ) {
        return $given;
    }
    elsif ( $given ) {
        $database = $given;
    }
    else {
        croak "Don't know what to do with @_";
    }

    my $source = "dbi:SQLite:dbname=$database";

    return $class->new( source => $source, database => $database, attributes => $attributes );
}

sub information {
    my $self = shift;
    my @information = ( $self->source, $self->username, $self->password, $self->attributes );
    return wantarray ? @information : \@information;
}

1;
