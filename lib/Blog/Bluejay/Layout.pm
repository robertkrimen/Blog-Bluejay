package Blog::Bluejay::Layout;

use Moose;
use MooseX::AttributeHelpers;
use Blog::Bluejay::Carp

with qw/Blog::Bluejay::Component/;

has page_map => qw/is ro isa HashRef/, default => sub { {} };
sub page {
    my $self = shift;
    return $self->page_map->{shift()};
}
has _pages => qw/metaclass Collection::Array is rw isa ArrayRef lazy_build 1/, provides => {qw/
    elements pages
/};
sub _build__pages {
    my $self = shift;
    return [ sort { $a->rank <=> $b->rank } values %{ $self->page_map } ];
}

sub home { return shift->page( 'home' ) }
sub journal { return shift->page( 'journal' ) }
sub about { return shift->page( 'about' ) }
sub contact { return shift->page( 'contact' ) }

# sub home_path { '' }
# sub home_label { undef } # Could be some title or something?

sub parse {
    require Path::Abstract;
    my $self = shift;
    my $blueprint = shift;

    my ($page, $rank); # Hah!
    $rank = 0;

    for (qw/ home journal about contact /) {
        $self->_new_page( $blueprint, $_ => $page, $rank++ ) if $page = $blueprint->{$_} || $_ eq 'journal';
    }
}

sub _new_page {
    my $self = shift;
    my $blueprint = shift;
    my $name = shift;
    my $page_blueprint = shift || {};
    my $rank = shift;

    my ( $class, $label, $path );

    $class = 'Blog::Bluejay::Layout::TemplatePage';
    $label = $page_blueprint->{label};
    undef $label if defined $label && ! length $label; # Blech

    if ( $name eq 'journal' ) {
        $class = 'Blog::Bluejay::Layout::JournalPage';
        $path = '' unless $self->home;
    }
    elsif ( $name eq 'home' ) {
        $path = '';
    }

    $path = $name unless defined $path;
    $label = $name unless defined $label;

    my $page = $class->new( layout => $self, label => $label, path => Path::Abstract->new( $path ), rank => $rank );
    $self->page_map->{$name} = $page;
    return $page;
}

package Blog::Bluejay::Layout::Page;

use Moose;

has layout => qw/is ro required 1 isa Blog::Bluejay::Layout/;
has bluejay => qw/is ro lazy_build 1/;
sub _build_bluejay {
    return shift->layout->bluejay;
}
has label => qw/is rw isa Str required 1/;
has rank => qw/is rw isa Int required 1/;

# TODO This is all nice and configurable, but how do we get Catalyst to reflect it?
# Our own dispatch? Meh.

has path => qw/is rw isa Path::Abstract lazy_build 1/;
sub _build_path {
    require Path::Abstract;
    my $self = shift;
    my $path = lc $self->label;
    return Path::Abstract->new( $path );
}
has uri => qw/is rw isa URI::PathAbstract lazy_build 1/;
sub _build_uri {
    my $self = shift;
    return $self->bluejay->uri->child( $self->path );
}

package Blog::Bluejay::Layout::TemplatePage;

use Moose;

extends qw/Blog::Bluejay::Layout::Page/;

has template => qw/is rw Str lazy_build 1/;
sub _build_template {
    my $self = shift;
    my $template = $self->path->clone;
    $template->extension( '.tt.html' ); # TODO Configurable?
    return $template;
}

sub render {
    my $self = shift;
    my $catalyst = shift;

    $catalyst->stash(
        page => $self,
        template => $self->template,
    );
}

package Blog::Bluejay::Layout::JournalPage;

use Moose;

extends qw/Blog::Bluejay::Layout::Page/;

sub render {
    my $self = shift;
    my $catalyst = shift;

    $catalyst->stash(
        page => $self,
        template => 'page/posts.tt.html',
        posts => [ $self->bluejay->journal->posts ],
    );
}

1;
