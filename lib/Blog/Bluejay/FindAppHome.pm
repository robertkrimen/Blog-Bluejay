package Blog::Bluejay::FindAppHome;

use strict;
use warnings;

use Cwd;
use Path::Class;

sub find {
    my $self = shift;
    my $package = shift;

    # Make an $INC{ $key } style string from the (application) package name
    (my $file = "$package.pm") =~ s{::}{/}g;

    if ( my $inc_entry = $INC{$file} ) {

        # Look for an uninstalled application

        # Find the @INC entry in which $file was found
        (my $path = $inc_entry) =~ s/$file$//;
        $path ||= cwd() if !defined $path || !length $path;
        my $home = dir($path)->absolute->cleanup;

        # Pop off /lib and /blib if they're there
        $home = $home->parent while $home =~ /b?lib$/;

        # Check if we have the right dir
        if ( $self->check( $home ) ) {

            # Clean up relative path: MyApp/script/.. -> MyApp

            my $dir;
            my @dir_list = $home->dir_list();
            while (($dir = pop(@dir_list)) && $dir eq '..') {
                $home = dir($home)->parent->parent;
            }

            return $home->stringify;
        }
    }

    return undef;
}

sub check {
    my $self = shift;
    my $dir = shift;

    # Does the dir contain a Makefile.PL or Build.PL?
    for (qw/ Makefile.PL Build.PL /) {
        return 1 if -f $dir->file( $_ );
    }

    return 0;
}

1;
