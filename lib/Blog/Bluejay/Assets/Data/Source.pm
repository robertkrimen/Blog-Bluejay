package Blog::Bluejay::Assets::Data::Source;
1;
__DATA__
script/blog_bluejay_catalyst_server.pl
#!/usr/bin/env perl

BEGIN {
    $ENV{CATALYST_ENGINE} ||= 'HTTP';
    $ENV{CATALYST_SCRIPT_GEN} = 33;
    require Catalyst::Engine::HTTP;
}

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

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

my @argv = @ARGV;

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

pod2usage(1) if $help;

if ( $restart && $ENV{CATALYST_ENGINE} eq 'HTTP' ) {
    $ENV{CATALYST_ENGINE} = 'HTTP::Restarter';
}
if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
}

# This is require instead of use so that the above environment
# variables can be set at runtime.
require Blog::Bluejay::Catalyst;

Blog::Bluejay::Catalyst->run( $port, $host, {
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

1;

=head1 NAME

blog_bluejay_catalyst_server.pl - Catalyst Testserver

=head1 SYNOPSIS

blog_bluejay_catalyst_server.pl [options]

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

=head1 DESCRIPTION

Run a Catalyst Testserver for this application.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__ASSET__
script/blog_bluejay_catalyst_cgi.pl
#!/usr/bin/env perl

BEGIN { $ENV{CATALYST_ENGINE} ||= 'CGI' }

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Blog::Bluejay::Catalyst;

Blog::Bluejay::Catalyst->run;

1;

=head1 NAME

blog_bluejay_catalyst_cgi.pl - Catalyst CGI

=head1 SYNOPSIS

See L<Catalyst::Manual>

=head1 DESCRIPTION

Run a Catalyst application as a cgi script.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT


This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__ASSET__
script/blog_bluejay_catalyst_fastcgi.pl
#!/usr/bin/env perl

BEGIN { $ENV{CATALYST_ENGINE} ||= 'FastCGI' }

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Blog::Bluejay::Catalyst;

my $help = 0;
my ( $listen, $nproc, $pidfile, $manager, $detach, $keep_stderr );

GetOptions(
    'help|?'      => \$help,
    'listen|l=s'  => \$listen,
    'nproc|n=i'   => \$nproc,
    'pidfile|p=s' => \$pidfile,
    'manager|M=s' => \$manager,
    'daemon|d'    => \$detach,
    'keeperr|e'   => \$keep_stderr,
);

pod2usage(1) if $help;

Blog::Bluejay::Catalyst->run(
    $listen,
    {   nproc   => $nproc,
        pidfile => $pidfile,
        manager => $manager,
        detach  => $detach,
	keep_stderr => $keep_stderr,
    }
);

1;

=head1 NAME

blog_bluejay_catalyst_fastcgi.pl - Catalyst FastCGI

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

=head1 DESCRIPTION

Run a Catalyst application as fastcgi.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__ASSET__
script/blog_bluejay_catalyst_test.pl
#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catalyst::Test 'Blog::Bluejay::Catalyst';

my $help = 0;

GetOptions( 'help|?' => \$help );

pod2usage(1) if ( $help || !$ARGV[0] );

print request($ARGV[0])->content . "\n";

1;

=head1 NAME

blog_bluejay_catalyst_test.pl - Catalyst Test

=head1 SYNOPSIS

blog_bluejay_catalyst_test.pl [options] uri

 Options:
   -help    display this help and exits

 Examples:
   blog_bluejay_catalyst_test.pl http://localhost/some_action
   blog_bluejay_catalyst_test.pl /some_action

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst action from the command line.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__ASSET__
script/blog_bluejay_catalyst_create.pl
#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
eval "use Catalyst::Helper;";

if ($@) {
  die <<END;
To use the Catalyst development tools including catalyst.pl and the
generated script/myapp_create.pl you need Catalyst::Helper, which is
part of the Catalyst-Devel distribution. Please install this via a
vendor package or by running one of -

  perl -MCPAN -e 'install Catalyst::Devel'
  perl -MCPANPLUS -e 'install Catalyst::Devel'
END
}

my $force = 0;
my $mech  = 0;
my $help  = 0;

GetOptions(
    'nonew|force'    => \$force,
    'mech|mechanize' => \$mech,
    'help|?'         => \$help
 );

pod2usage(1) if ( $help || !$ARGV[0] );

my $helper = Catalyst::Helper->new( { '.newfiles' => !$force, mech => $mech } );

pod2usage(1) unless $helper->mk_component( 'Blog::Bluejay::Catalyst', @ARGV );

1;

=head1 NAME

blog_bluejay_catalyst_create.pl - Create a new Catalyst Component

=head1 SYNOPSIS

blog_bluejay_catalyst_create.pl [options] model|view|controller name [helper] [options]

 Options:
   -force        don't create a .new file where a file to be created exists
   -mechanize    use Test::WWW::Mechanize::Catalyst for tests if available
   -help         display this help and exits

 Examples:
   blog_bluejay_catalyst_create.pl controller My::Controller
   blog_bluejay_catalyst_create.pl -mechanize controller My::Controller
   blog_bluejay_catalyst_create.pl view My::View
   blog_bluejay_catalyst_create.pl view MyView TT
   blog_bluejay_catalyst_create.pl view TT TT
   blog_bluejay_catalyst_create.pl model My::Model
   blog_bluejay_catalyst_create.pl model SomeDB DBIC::Schema MyApp::Schema create=dynamic\
   dbi:SQLite:/tmp/my.db
   blog_bluejay_catalyst_create.pl model AnotherDB DBIC::Schema MyApp::Schema create=static\
   dbi:Pg:dbname=foo root 4321

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Create a new Catalyst Component.

Existing component files are not overwritten.  If any of the component files
to be created already exist the file will be written with a '.new' suffix.
This behavior can be suppressed with the C<-force> option.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__ASSET__
assets/tt/footer.tt.html
__ASSET__
assets/tt/title.tt.html
__ASSET__
assets/tt/frame.tt.html
[% assets.include("http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js", -100) %]
[% assets.include("http://yui.yahooapis.com/combo?2.7.0/build/reset-fonts-grids/reset-fonts-grids.css&2.7.0/build/base/base-min.css", 'css', -100) %]
[% assets.include("static/css.css", 0) %]

[% DEFAULT title = template.title %]
[% DEFAULT default_title = "" %]
[% DEFAULT title = default_title %]

[% CLEAR -%]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>[% title %]</title>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
[% assets.export("css") %]
</head>
<body>

<div id="doc">

[% INCLUDE header.tt.html %]

[% content %]
    
[% INCLUDE footer.tt.html %]

</div>

[% assets.export("js") %]

</body>
</html>
__ASSET__
assets/tt/post.tt.html
[% DEFAULT post_meta = 0 %]
[% CLEAR -%]
<div>
    <div class="post">

        <div class="post-header">

            <div class="post-meta post-meta-1">

                <div class="datetime">

                    <div class="datetime-weekday">[% post.local_creation.strftime("%A") %]</div>

                    <div class="clear"></div>

                    <div class="datetime-month-day-year">
                        <div class="datetime-month">
                            [% post.local_creation.strftime("%B %d %Y") %]
                        </div>
                    </div>

                    <div class="clear"></div>

                    <div class="datetime-time">[% post.local_creation.strftime("%H:%M %P") %]</div>

                    <div class="clear"></div>

                </div>

            </div>

            <div class="post-title"><a href="[% post.uri %]">[% post.title %]</a></div>

        </div>

        <div class="post-body">
            [% post.body.render %]
        </div>

        <div class="clear"></div>

    </div>
</div>
__ASSET__
assets/tt/header.tt.html
<div class="header yui-gf">
    [% FOREACH page = bluejay.layout.pages %]
    <a href="[% page.uri %]">[% page.label %]</a>
    [% END %]
<!--    <a href="[% Catalyst.uri_for( '/' ) %]">home</a>-->
<!--    <div class="yui-u first">-->
<!--    </div>-->
<!--    <div class="yui-u">-->
<!--|+        <span class="header-title">+|-->
<!--|+        <a href="[% Catalyst.uri_for( '/' ) %]">+|-->
<!--|+            [% INCLUDE title.tt.html %]+|-->
<!--|+        </a>+|-->
<!--|+        </span>+|-->
<!--    </div>-->
</div>
__ASSET__
assets/tt/posts.tt.html
[% FOREACH post = posts %]
[% INCLUDE post.tt.html post_meta = loop.count % 4 %]
[% IF ! loop.last %]
<div class="post-separator"></div>
[% END %]
<div class="clear"></div>
[% END %]
__ASSET__
assets/tt/page/post.tt.html
[% DEFAULT title = "$post.title &bull;" %]
[% CLEAR -%]
[% WRAPPER frame.tt.html %]
[% INCLUDE post.tt.html %]
[% END %]
__ASSET__
assets/tt/page/posts.tt.html
[% WRAPPER frame.tt.html %]
[% INCLUDE posts.tt.html %]
[% END %]
__ASSET__
assets/root/static/css.css
body {
    font-family: Verdana, Arial, sans-serif;
    background-color: #fff;
}

a, a:hover, a:active, a:visited {
    text-decoration: none;
    font-weight: bold;
    font-weight: normal;
    color: #436b95;
}

a:hover {
    text-decoration: underline;
}

.post-meta {
    float: right;
/*    color: #666;*/
    font-size: 0.85em;
    line-height: 1.2;
    margin: 0px 0px 10px 20px;
    width: 13em;
    padding: 5px;
}

.post-meta-1, .post-meta-1 a {
    background: #def none repeat scroll 0 0;
    color: #345;
}

.datetime {
}

/*.datetime {*/
/*    float: right;*/
/*    color: #666;*/
/*    font-size: 14px;*/
/*    line-height: 1.2;*/
/*    margin: 15px -10px 20px 20px;*/
/*    margin: 0px -10px 20px 20px;*/
/*    margin: 0px 0px 10px 20px;*/
/*|+    background: #eee;+|*/
/*|+    background: #eee;+|*/
/*|+    border: 2px solid #eef;+|*/
/*|+    border-bottom: 2px solid #eee;+|*/
/*    padding: 5px;*/
/*}*/

.datetime-time {
    float: left;
    font-size: 12px;
/*    margin-left: 10px;*/
}

.datetime-weekday {
    float: left;
/*    color: #666;*/
    font-size: 16px;
/*    margin-bottom: 0.1em;*/
    font-variant: small-caps;
/*    text-transform: uppercase;*/
}

.datetime-month-day-year {
    float: left;
    overflow: hidden;
    font-size: 12px;
    font-weight: bold;
/*    background-color: #999;*/
/*    color: #eee;*/
    line-height: 12px;
    padding: 3px 0;
}

.post {
    color: #333;
    font-size: 14px;
    border-bottom: 1px dotted #ddd;
}

.post-title {
    font-size: 28px;
    font-weight: bold;
}

.post-header {
    margin-bottom: 0.5em;
}

.post-title a {
}

.post-body pre.code {
/*    background: #ffe;*/
    margin-left: 1em;
    border-left: 4px solid #ccc;
/*    border-top: 2px dotted #ccc;*/
/*    border-bottom: 2px dotted #ccc;*/
    margin-bottom: 1em;
    padding: 10px 10px;
/*    color: #000;*/
}
.post-separator {
    margin-top: 10px;
}

.clear {
    clear: both;
}

.header {
    margin: 1em 0;
    border-bottom: 2px solid #ccc;
}

.header-title {
    font-size: 24px;
    margin-left: 2em;
}

.header-home {
    background-color: #436b95;
    background-color: #7ad;
    position: relative;
/*    width: 24px;*/
/*    height: 24px;*/
    
}
__ASSET__
