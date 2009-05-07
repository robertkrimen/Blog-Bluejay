package CatalystXPathCatalog;

use Moose;

has _catalog => qw/is ro required 1 isa HashRef/, default => sub { {} };

sub BUILD {
    my $self = shift;
    my $given = shift;

    $self->add( $given->{catalog} ) if $given->{catalog};
}

sub _normalize_path($) {
    my $path = shift;
    s/^\/+//, s/\/+$//, s/\/+/\// for $path;
    return $path;
}

sub dispatch {
    my $self = shift;
    my $catalyst = shift;
    my $path = shift;

    $path = $catalyst->request->path unless defined $path;
    $path = _normalize_path $path;

    return unless my $entry = $self->_catalog->{$path};

    $catalyst->stash( %$entry );

    return 1;
}

sub add {
    my $self = shift;
    if (1 == @_) {
        my $catalog = shift;
        for (split m/\n+/, $catalog) {
            next if m/^\s*$/ || m/^\s*#/;                                               
            my ($path, $template, $comment) = m/^\s*([^#\s]+)(?:\s*([^#\s]+))?(?:\s*#\s*(.*))?$/;
            $self->add( $path => ( template => $template ) );
        }
        # TODO Warn on cannot parse
    }
    else {
        my $path = shift;
        $path = _normalize_path $path;
        my $entry = $self->_catalog->{$path} ||= {};
        my $given = ref $_[0] eq 'HASH' ? shift : { @_ };
        $entry->{$_} = $given->{$_} for keys %$given;
    }
}

sub clear {
    my $self = shift;
    die "Not implemented";
}

1;
