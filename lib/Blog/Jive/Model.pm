package Blog::Jive::Model;

use strict;
use warnings;

package Blog::Jive::Modeler;

use Moose;

extends qw/DBICx::Modeler/;

with qw/Blog::Jive::Component/;

package Blog::Jive::Modeler::Model;

use Moose::Role;

has jive => qw/is ro lazy_build 1/;
sub _build_jive {
    return shift->_model__modeler->jive; # Doing this sort of access in the model is horribly ugly
}

package Blog::Jive::Model::Post;

use DBICx::Modeler::Model;

with qw/Blog::Jive::Modeler::Model/;

use DateTimeX::Easy qw/datetime/;

has uri => qw/is ro lazy_build 1/;
sub _build_uri {
    my $self = shift;
    return $self->jive->uri->child( qw/ post /, join '-', lc $self->safe_title, $self->uuid );
}

has safe_title => qw/is ro lazy_build 1 isa Str/;
sub _build_safe_title {
    my $self = shift;
    my $title = $self->title;
    $title =~ s/[^A-Za-z0-9]+/-/g;
    $title =~ s/^-+//g;
    $title =~ s/-+$//g;
    return $title;
}

has document => qw/is ro lazy_build 1/, handles => [qw/ edit /];
sub _build_document {
    my $self = shift;
    return $self->jive->cabinet->load( $self->uuid );
}

has assets_dir => qw/is ro lazy_build 1/;
sub _build_assets_dir {
    my $self = shift;
    return $self->jive->cabinet->storage->assets_dir( $self->uuid );
}

has creation => qw/is ro lazy_build 1/;
sub _build_creation {
    my $self = shift;
    return datetime( $self->_model__column_creation );
}

has local_creation => qw/is ro lazy_build 1/;
sub _build_local_creation {
    my $self = shift;
    return $self->creation->set_time_zone( 'local' );
}

has body => qw/is ro lazy_build 1/;
sub _build_body {
    my $self = shift;
    return Blog::Jive::Model::Post::Body->new( post => $self );
}

package Blog::Jive::Model::Post::Body;

use Moose;

{
    my $markdown;
    sub _markdown() {
        require Text::MultiMarkdown;
        return $markdown ||= Text::MultiMarkdown->new;
    }
}

has post => qw/is ro required 1/;

sub raw {
    my $self = shift;
    return $self->post->document->body;
}

has render => qw/is ro lazy_build 1/;
sub _build_render {
    my $self = shift;

    my $header = $self->post->document->header;
    my $type = $header->{type} || $header->{content_type} || ''; # TODO Make this configurable
    $type = 'tt-markdown' if $type =~ m/text\/.*markdown/;

    my $render = $self->raw;
    if ($type =~ m/\btt\b/) {
        my $tt = $self->post->jive->tt;
        my $ASSETS = join '/', $self->post->assets_dir->dir_list(-3);
        my $input = \$render;
        my $output;
        $tt->process( $input, { post => $self, ASSETS => $ASSETS }, \$output ) or die $tt->error;
        $render = $output;
    }

    if ($type =~ m/\bmarkdown\b/) {
        $render = _markdown->markdown( $render );
        $render =~ s{(\n)<pre><code>(\s*)}{$1<pre class="code"><code>$2}g; # TODO Urgh, ...
    }

    return $render;
}


1;
