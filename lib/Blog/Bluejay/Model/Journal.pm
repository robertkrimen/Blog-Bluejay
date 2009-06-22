package Blog::Bluejay::Model::Journal;

use Moose;

has bluejay => qw/is ro required 1/;

sub posts {
    my $self = shift;
    my @search = @_;
    
    @search = ( undef, { order_by => 'creation DESC' } ) unless @search;

    return $self->bluejay->model( 'Post' )->search( @search );
}

sub published {
    my $self = shift;
    return $self->posts->search( { status => 'published' } );
}

sub post {
    my $self = shift;
    my $uuid = shift;

    my ($post) = $self->bluejay->model( 'Post' )->search( { uuid => $uuid } )->slice( 0 );
    return $post;
}

sub create_post {
    my $self = shift;
    
}

1;
