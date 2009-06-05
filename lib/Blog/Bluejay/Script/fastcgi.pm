package Blog::Bluejay::Script::fastcgi;

use strict;
use warnings;

BEGIN { $ENV{CATALYST_ENGINE} ||= 'FastCGI' }

use Blog::Bluejay::Script;

sub run {
    my $self = shift;
    my @argv = @_;

    my $help = 0;
    my ( $listen, $nproc, $pidfile, $manager, $detach, $keep_stderr );

    {
        local @ARGV = @argv;
        GetOptions(
            'help|?'      => \$help,
            'listen|l=s'  => \$listen,
            'nproc|n=i'   => \$nproc,
            'pidfile|p=s' => \$pidfile,
            'manager|M=s' => \$manager,
            'daemon|d'    => \$detach,
            'keeperr|e'   => \$keep_stderr,
        );
    }

    $help and pod2usage( <<'_END_' );
=head1 SYNOPSIS

blog_bluejay_catalyst_fastcgi.pl [options]

 Options:
   -? -help      display this help and exits
   -l -listen    Socket path to listen on
                 (defaults to standard input)
                 can be HOST:PORT, :PORT or a
                 filesystem path
   -n -nproc     specify number of processes to keep
                 to serve requests (defaults to 1,
                 requires -listen)
   -p -pidfile   specify filename for pid file
                 (requires -listen)
   -d -daemon    daemonize (requires -listen)
   -M -manager   specify alternate process manager
                 (FCGI::ProcManager sub-class)
                 or empty string to disable
   -e -keeperr   send error messages to STDOUT, not
                 to the webserver
=cut
_END_

    launch( $listen, {
        nproc   => $nproc,
        pidfile => $pidfile,
        manager => $manager,
        detach  => $detach,
        keep_stderr => $keep_stderr,
    } );
}

1;
