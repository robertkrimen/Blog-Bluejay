package Blog::Jive::Journal::Model;

use strict;
use warnings;

package Blog::Jive::Journal::Modeler;

use Moose;

extends qw/DBICx::Modeler/;

has journal => qw/is ro required 1 isa Blog::Jive::Journal/;

package Blog::Jive::Journal::Model::Post;

use DateTimeX::Easy qw/datetime/;
use DBICx::Modeler::Model;

has uri => qw/is ro lazy_build 1/;
sub _build_uri {
    my $self = shift;
    return $self->_model__modeler->journal->uri->child( qw/ post /, join '-', lc $self->safe_title, $self->uuid );
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
    return $self->_model__modeler->journal->cabinet->load( $self->uuid );
}

has assets_dir => qw/is ro lazy_build 1/;
sub _build_assets_dir {
    my $self = shift;
    return $self->_model__modeler->journal->cabinet->storage->assets_dir( $self->uuid );
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
    return Blog::Jive::Journal::Model::Post::Body->new( post => $self );
}

package Blog::Jive::Journal::Model::Post::Body;

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

    my $journal = $self->post->_model__modeler->journal;
    my $header = $self->post->document->header;
    my $content_type = $header->{content_type} || '';
    my $ASSETS = join '/', $self->post->assets_dir->dir_list(-3);
    my $raw = $self->raw;
    my $render;

    $journal->tt->process(\$raw, { post => $self, ASSETS => $ASSETS }, \$render) or die $journal->tt->error;
    if ($content_type =~ m/\b(?:multi-)?markdown\b/) {
        $render = _markdown->markdown( $render );
    }
        $render =~ s{(\n)<pre><code>(\s*)}{$1<pre class="code"><code>$2}g;
    return $render;
}


1;
