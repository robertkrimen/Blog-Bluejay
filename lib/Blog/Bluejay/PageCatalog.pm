package Blog::Bluejay::PageCatalog;

use warnings;
use strict;

use Moose;
use Blog::Bluejay::Carp

with qw/Blog::Bluejay::Component/;

use Path::Abstract;

has _catalog => qw/is ro required 1 isa HashRef/, default => sub { {} };

sub BUILD {
    my $self = shift;
    my $given = shift;

    $self->set( $given->{catalog} ) if $given->{catalog};
}

sub _normalize_path($) {
    my $path = shift;
    return Path::Abstract->new( $path );
}

sub get {
    my $self = shift;
    my $path = shift;

    $path = _normalize_path $path;
    return unless my $entry = $self->_catalog->{$path};
    return $entry;
}

sub set {
    my $self = shift;
    if (1 == @_ && ref $_[0] eq 'HASH') {
        my $catalog = shift;
        while (my ($key, $value) = each %$catalog) {
            $self->set( $key => $value );
        }
    }
    else {
        my $path = shift;

        $path = _normalize_path $path;
        if (@_ == 1 && ! defined $_[0]) {
            delete $self->_catalog->{$path};
            return;
        }
        my $given = ref $_[0] eq 'HASH' ? shift : { @_ };
        my $entry = $self->new_entry( $path, $given );
        $self->_catalog->{$path} = $entry;
    }
}

sub new_entry {
    my $self = shift;
    my $path = shift;
    my $entry = shift;

    return Blog::Bluejay::PageCatalog::Entry->new( path => $path, entry => $entry, catalog => $self );
}

package Blog::Bluejay::PageCatalog::Entry;

use Moose;

has path => qw/is ro required 1/;
has entry => qw/is ro required 1 isa HashRef/;
has catalog => qw/is ro required 1 isa Blog::Bluejay::PageCatalog/;
has bluejay => qw/is ro lazy_build 1/;
sub _build_bluejay {
    return shift->catalog->bluejay;
}
has template => qw/is rw isa Str lazy_build 1/;
sub _build_template {
    my $self = shift;
    return join '', 'page/', $self->path, '.tt.html';
#    my $template = $self->name; # TODO Urgh!
#    
##    $template->extension( '.tt.html' ); # TODO Configurable?
#    return $template.'';
}


sub get {
    my $self = shift;
    return $self->entry unless @_;
    return $self->entry->{shift()};
}

1;
