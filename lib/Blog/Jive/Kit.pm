package Blog::Jive::Kit;

use warnings;
use strict;

use Moose;

use URI::PathAbstract;

with qw/Blog::Jive::Component/;

has path_mapper => qw/is ro lazy_build 1/, handles => [qw/ dir file /];
sub _build_path_mapper {
    my $self = shift;
    return Path::Mapper->new( base => $self->jive->_home );
}

has uri => qw/is rw lazy_build 1/;
sub _build_uri {
    return URI::PathAbstract->new( 'http://example.com' );
}

sub home {
    return shift->home_dir( @_ );
}

sub home_dir {
    return shift->path_mapper->dir( '/' );
}

1;

__END__

use Moose;
use MooseX::ClassAttribute;
use Framework::Om qw/-name jive -identifier jive/,
    'Config::JFDI' => {},
    'Starter' => {},
    'URI', => {},
    'Render::TT' => {},
;
# TODO Setup manifest

use Blog::Jive;

has jive => qw/is ro isa Blog::Jive lazy_build 1/;
sub _build_jive {
    my $self = shift;
    return Blog::Jive->new( kit => $self );
}

sub render_journal_page {
    my $self = shift;

    $self->render({
        path => '/journal/',
        process => { plugin => 'Render::TT', template => 'journal/home.tt.html' },
        post_process => 'journal/index.tt.html',
    });
}

sub render_journal_index_page {
    my $self = shift;

    $self->render({
        path => '/journal/index',
        process => { plugin => 'Render::TT', template => 'journal/index.tt.html' },
        post_process => 'journal/index/index.tt.html',
    });
}

sub render_journal_month_page {
    my $self = shift;
    my $month = shift;
    my %given = @_;

    my $month_overview = $self->jive->journal->overview->{month}->{$month};

    $self->render({
        path => '/journal/index',
        process => { plugin => 'Render::TT', template => 'journal/month.tt.html' },
        post_process => $month_overview->{rsc}->child( 'index.html' ),
        stash => { posts => [ $self->jive->journal->posts_for_month( $month ) ] },
    });
}

sub render_journal_post_page {
    my $self = shift;
    my $post = shift;
    my %given = @_;

    $self->render({
        path => '/journal/post',
        process => { plugin => 'Render::TT', template => 'journal/post.tt.html' },
        post_process => $post->rsc->child( 'index.html' ),
        stash => { post  => $post },
    });
}

sub render_journal_post_pi_page {
    my $self = shift;
    my $post = shift;
    my %given = @_;

    $self->render({
        path => '/journal/post',
        process => { plugin => 'Render::TT', template => 'journal/post.tt.html' },
        post_process => $post->rsc->child( 'index.html' ),
        stash => { post  => $post },
    });
}

#sub _render_journal_page {
#    my $self = shift;
#    my $overview = shift;
#    my $template = shift;
#    my %given = @_;

#    my $context = $given{context} ||= {};
#    $context->{$_} = $overview->{$_} for keys %$overview;

#    return $self->_render_page(rsc => $overview->{rsc}->child('index.html'), template => $template, %given);
#}

#sub render_journal_post_page {
#    my $self = shift;
#    my $post = shift;
#    my %given = @_;

#    my $context = $given{context} ||= {};
#    $context->{post} ||= $post;

#    return $self->_render_page(rsc => $post->rsc->child('index.html'), template => "journal/post.tt.html", %given);
#}

#sub render_journal_post_pi_page {
#    my $self = shift;
#    my $post = shift;
#    my %given = @_;

#    my $context = $given{context} ||= {};
#    $context->{post} ||= $post;

#    return $self->_render_page(rsc => $post->rsc->child('pi/index.html'), template => "journal/post_pi.tt.html", %given);
#}

after build => sub {
    my $self = shift;

    $self->render_journal_page;
    $self->render_journal_index_page;

    my @posts = $self->jive->journal->posts;
    for my $post (@posts) {
#        symlink { relative => 1 }, 
#            $post->rsc->file,
#            $post->rsc->file->parent->file( $post->uri->last ),
#        ;
#        $self->ui->render_journal_post_page( $post );
#        $self->ui->render_journal_post_pi_page( $post );
    }

    my $overview = $self->jive->journal->overview;

    for my $month (@{ $overview->{month_order} }) {
        $self->render_journal_month_page( $month->{month} );
    }
};

1;
