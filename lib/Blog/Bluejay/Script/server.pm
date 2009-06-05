package Blog::Bluejay::Script::server;

use strict;
use warnings;

BEGIN {
    $ENV{CATALYST_ENGINE} ||= 'HTTP';
    $ENV{CATALYST_SCRIPT_GEN} = 33;
    require Catalyst::Engine::HTTP;
}

use Blog::Bluejay::Script;

sub run {
    my $self = shift;
    my @argv = @_;

    my $debug             = 0;
    my $fork              = 0;
    my $help              = 0;
    my $host              = undef;
    my $port              = $ENV{BLOG_BLUEJAY_CATALYST_PORT} || $ENV{CATALYST_PORT} || 3000;
    my $keepalive         = 0;
    my $restart           = $ENV{BLOG_BLUEJAY_CATALYST_RELOAD} || $ENV{CATALYST_RELOAD} || 0;
    my $restart_delay     = 1;
    my $restart_regex     = '(?:/|^)(?!\.#).+(?:\.yml$|\.yaml$|\.conf|\.pm)$';
    my $restart_directory = undef;
    my $follow_symlinks   = 0;
    my $background        = 0;

    {
        local @ARGV = @argv;
        GetOptions(
            'debug|d'             => \$debug,
            'fork|f'              => \$fork,
            'help|?'              => \$help,
            'host=s'              => \$host,
            'port=s'              => \$port,
            'keepalive|k'         => \$keepalive,
            'restart|r'           => \$restart,
            'restartdelay|rd=s'   => \$restart_delay,
            'restartregex|rr=s'   => \$restart_regex,
            'restartdirectory=s@' => \$restart_directory,
            'followsymlinks'      => \$follow_symlinks,
            'background'          => \$background,
        );
    }

    $help and pod2usage( <<'_END_' );
=head1 SYNOPSIS

 Options:
   -d -debug          force debug mode
   -f -fork           handle each request in a new process
                      (defaults to false)
   -? -help           display this help and exits
      -host           host (defaults to all)
   -p -port           port (defaults to 3000)
   -k -keepalive      enable keep-alive connections
   -r -restart        restart when files get modified
                      (defaults to false)
   -rd -restartdelay  delay between file checks
   -rr -restartregex  regex match files that trigger
                      a restart when modified
                      (defaults to '\.yml$|\.yaml$|\.conf|\.pm$')
   -restartdirectory  the directory to search for
                      modified files, can be set mulitple times
                      (defaults to '[SCRIPT_DIR]/..')
   -follow_symlinks   follow symlinks in search directories
                      (defaults to false. this is a no-op on Win32)
   -background        run the process in the background
 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro
=cut
_END_

    if ( $restart && $ENV{CATALYST_ENGINE} eq 'HTTP' ) {
        $ENV{CATALYST_ENGINE} = 'HTTP::Restarter';
    }
    if ( $debug ) {
        $ENV{CATALYST_DEBUG} = 1;
    }

    launch( $port, $host, {
        argv              => \@argv,
        'fork'            => $fork,
        keepalive         => $keepalive,
        restart           => $restart,
        restart_delay     => $restart_delay,
        restart_regex     => qr/$restart_regex/,
        restart_directory => $restart_directory,
        follow_symlinks   => $follow_symlinks,
        background        => $background,
    } );
}

1;
