package Blog::Jive::Model::Journal;

use Moose;

has jive => qw/is ro required 1/;

sub posts {
    my $self = shift;
    my @search = @_;
    
    @search = ( undef, { order_by => 'creation DESC' } ) unless @search;

    return $self->jive->model( 'Post' )->search( @search );
}

sub post {
    my $self = shift;
    my $uuid = shift;

    my ($post) = $self->jive->model( 'Post' )->search( { uuid => $uuid } )->slice( 0 );
    return $post;
}

sub create_post {
    my $self = shift;
    
}

1;
