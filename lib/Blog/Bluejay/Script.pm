package Blog::Bluejay::Script;

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage();
use Path::Class;

use vars qw/@EXPORT @ISA/;
use Exporter;
push @ISA, qw/Exporter/;
push @EXPORT, qw/ GetOptions pod2usage launch /;

sub pod2usage {

    my $usage = shift;
    open my $usage_file, '<', \$usage;
    Pod::Usage::pod2usage( -input => $usage_file, -exit => 1 );

}

sub launch {

    $ENV{BLOG_BLUEJAY_CATALYST_HOME} or die "BLOG_BLUEJAY_CATALYST_HOME is not set, can't launch!\n";

    # TODO File::Spec?
    my $lib = dir( $ENV{BLOG_BLUEJAY_CATALYST_HOME}, 'lib' );
    unshift @INC, $lib if -d $lib;

    my $catalyst_class = $ENV{BLOG_BLUEJAY_CATALYST};
    $catalyst_class ||= 'Blog::Bluejay::Catalyst';

    # This is require instead of use so that the environment
    # variables can be set at runtime.
    eval "require $catalyst_class;" or die $@;

    $catalyst_class->run( @_ );
}

sub run {
    my $script = shift @ARGV;

    die "No script given!\n" unless $script;

    my $script_package = join '::', __PACKAGE__, $script;

    eval "require $script_package;" or die $@;

    $script_package->run( @ARGV );
}

1;
