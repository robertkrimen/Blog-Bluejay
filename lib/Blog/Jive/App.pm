package Blog::Jive::App;

use strict;
use warnings;

use Blog::Jive;

use Data::UUID::LibUUID;
use Carp;
use Path::Abstract;
use DateTime;
use Getopt::Chain;
use Term::Prompt;
use File::Find();
local $Term::Prompt::MULTILINE_INDENT = undef;
use Text::ASCIITable;

my @jive;

{
    my $jive;
    sub jive {
        return $jive ||= Blog::Jive->new( @_ );
    }

    sub journal {
        return jive->journal;
    }

    sub cabinet {
        return journal->cabinet;
    }
}

sub abort(@) {
    print join "", @_, "\n" if @_;
    exit -1;
}

sub folder_title {

    return unless @_;

    my $folder;
    if (($folder = $_[0]) =~ s/^\.//) {
        shift @_;
    }
    else {
        $folder = "Unfiled";
    }

    return unless @_;

    my $title = join " ", @_;

    return ($folder, $title);
}


sub find {
    my @criteria = @_;

    return unless @criteria;

    my $criteria = $criteria[0];
    my ($folder, $title) = folder_title @criteria;

    my ($search, $post, $count);
    $search = journal->posts(
        [ 
            { title => $criteria },
            { folder => $folder, title => $title },
            { uuid => { -like => "$criteria%" } },
        ],
        {}
    );

    $count = $search->count;
    ($post) = $search->slice(0, 0) if 1 == $count;

    return wantarray ? ($post, $search, $count) : $post;
}

######
# Do #
######

sub do_list {
    my $search = shift;

    $search = scalar journal->posts unless $search;
    my @posts = $search->search( undef, { order_by => [qw/ creation /] } )->all;

    my $tb = Text::ASCIITable->new({ hide_HeadLine => 1 });
    $tb->setCols( '', '', '' );
    $tb->addRow( $_->uuid, $_->title, $_->folder ) for @posts;
    print $tb;
}

sub do_new {
    my ($folder, $title) = @_;
    my $document = cabinet->create;
    $document->header->{title} = $title;
    $document->header->{folder} = $folder;
    $document->edit;
    return $document;
}

sub do_find {
    my @criteria = @_;

    unless (@criteria) {
        do_list;
        return;
    }

    my ($post, $search, $count) = find @criteria;

    abort "No post found matching your criteria" unless $count;

    choose $search if $count > 1;

    return $post;
}

sub do_choose {
    my $search = shift;

    print "Too many posts found matching your criteria\n";

    list $search;
}

sub prompt_yn ($$) {
    return prompt Y => shift, '', shift;
}

#######
# Run #
#######

use Getopt::Chain::Declare;

start [qw/ home=s /], sub {
    my $context = shift;
    if (defined ( my $home = $context->option( 'home' ) ) ) {
        push @jive, home => $home;
    }
};

on 'setup' => undef, sub {
    my $context = shift;

    print <<_END_ and return if 1;
Don't overwrite your work, fool!
_END_

    print <<_END_;

I will setup in @{[ journal->kit->home_dir ]}
_END_
    if ( prompt_yn 'Is this okay? Y/n', 'Y' ) {

        jive->assets->deploy;

        print "\n";
        my $home = jive->home;
        $home = readlink $home if -l $home;
        File::Find::find( { no_chdir => 1, wanted => sub {
        
            return if $_ eq $home;
            my $size;
            $size = -s _ if -f $_;

            print "\t", substr $_, 1 + length $home;
            print " $size" if defined $size;
            print "\n";

        } }, $home );
        print "\n";

    }
    else {
        print "Aborting deploy\n";
    }

    
};

on 'publish' => undef, sub {
};

on 'edit *' => undef, sub {
    shift;
    return do_list unless @_;

    my ($post, $search, $count) = find @_;

    if ($post) {
        $post->edit;
    }
    else {
        return do_choose $search if $count > 1;
        return unless my ($folder, $title) = folder_title @_;
        if (prompt_yn "Post \"$title\" not found. Do you want to start it? y/N", 'N') {
            my $post = do_new $folder, $title;
        }
    }
};

on 'server' => undef, sub {
    shift;
    $ENV{BLOG_JIVE_HOME} = jive->home;
    $ENV{BLOG_JIVE_CATALYST_HOME} = jive->home;

    my $debug             = 0;
    my $fork              = 0;
    my $help              = 0;
    my $host              = undef;
    my $port              = $ENV{BLOG_JIVE_CATALYST_PORT} || $ENV{CATALYST_PORT} || 3000;
    my $keepalive         = 0;
    my $restart           = $ENV{BLOG_JIVE_CATALYST_RELOAD} || $ENV{CATALYST_RELOAD} || 0;
    my $restart_delay     = 1;
    my $restart_regex     = '(?:/|^)(?!\.#).+(?:\.yml$|\.yaml$|\.conf|\.pm)$';
    my $restart_directory = undef;
    my $follow_symlinks   = 0;
    my $background        = 0;
    my @argv;

    BEGIN {
        $ENV{CATALYST_ENGINE} ||= 'HTTP';
        $ENV{CATALYST_SCRIPT_GEN} = 33;
        require Catalyst::Engine::HTTP;
    }

    if ( $restart && $ENV{CATALYST_ENGINE} eq 'HTTP' ) {
        $ENV{CATALYST_ENGINE} = 'HTTP::Restarter';
    }
    if ( $debug ) {
        $ENV{CATALYST_DEBUG} = 1;
    }

    require Blog::Jive::Catalyst;

    Blog::Jive::Catalyst->run( $port, $host, {
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
};

on qr/.*/ => undef, sub {
    my $context = shift;
    my $command = $context->command;

    if ($command) {
        print "\nblog-jive: Unknown command \"$command\"\n";
    }

    print <<_END_;

    Usage: blog-jive <command>

        setup
        edit
        publish

        list 
        assets <key>

_END_

    do_list;
};


no Getopt::Chain::Declare;


#sub run {

#    Getopt::Chain->process(

#        commands => {

#            DEFAULT => sub {
#                my $context = shift;
#                local @_ = $context->remaining_arguments;

#                if (defined (my $command = $context->command)) {
#                    print <<_END_;
#    Unknown command: $command
#_END_
#                }

#                print <<_END_;
#    Usage: $0 <command>

#        new
#        edit <criteria> ...
#        list 
#        assets <key>

#_END_
#                do_list unless @_;
#            },

#            new => {
#                options => [qw/link=s/],

#                run => sub {
#                    my $context = shift;

#                    my ($folder, $title) = folder_title @_ or abort "Missing a title";

#                    if (my $post = do_new $folder, $title) {
#                    }
#                },
#            },

#            edit => sub {
#                my $context = shift;
#                local @_ = $context->remaining_arguments; # TODO Should pass in remaining arguments

#                return do_list unless @_;

#                my ($post, $search, $count) = find @_;

#                if ($post) {
#                    $post->edit;
#                }
#                else {
#                    return do_choose $search if $count > 1;
#                    return unless my ($folder, $title) = folder_title @_;
#                    if (prompt y => "Post \"$title\" not found. Do you want to start it?", undef, 'N') {
#                        my $post = new $folder, $title;
#                    }
#                }
#            },

#            assets => sub {
#                my $context = shift;
#                local @_ = $context->remaining_arguments;

#                return unless my $post = do_find @_;

#                my $assets_dir = $post->assets_dir;

#                if (-d $assets_dir) {
#                    print "$assets_dir already exists\n";
#                }
#                else {
#                    $assets_dir->mkpath;
#                }
#            },

#            link => sub {
#                my $context = shift;
#                local @_ = $context->remaining_arguments;

#                return do_list unless @_;

#                my $criteria = shift;

#                return unless my $post = find $criteria;

#                $post->link(@_);
#            },

#            'link-all' => sub {
#                my $context = shift;
#                local @_ = $context->remaining_arguments;

#                return do_list unless @_;

#                my @posts = $cabinet->model->search(post => {});
#                for (@posts) {
#                    $_->link(@_);
#                }
#            },

#            list => sub {
#                my $context = shift;
#                local @_ = $context->remaining_arguments;

#                my $search;
#                (undef, $search) = find @_ if $_;

#                do_list $search;
#            },

#            retitle => sub {
#                my $context = shift;
#                local @_ = $context->remaining_arguments;
#            },
#            
#        },
#    );

#}

no warnings 'void';

__PACKAGE__;

__END__

#            rescan => sub {
#                my $context = shift;
#                
#                my $dir = $jive->kit->home_dir->subdir( qw/assets journal/ );
#                $dir->recurse(callback => sub {
#                    my $file = shift;
#                    return unless -d $file;
#                    return unless $file->dir_list(-1) =~ m/^($Document::TriPart::UUID::re)$/;
#                    my $uuid = $1;
#                    warn "$uuid => $file\n";
#                    my $document = $journal->cabinet->load( $uuid );
#                    $journal->commit( $document );
#                });
#            },

#            trash => sub {
#                my $context = shift;
#                local @_ = $context->remaining_arguments;

#                return unless my $post = find @_;

#                my $title = $post->title;
#                if (prompt y => "Are you sure you want to trash \"$title\"?", undef, 'N') {
#                    $cabinet->trash_post($post);
#                }
            },

1;
