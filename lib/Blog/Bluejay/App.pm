package Blog::Bluejay::App;

use strict;
use warnings;

use Data::UUID::LibUUID;
use Carp;
use Path::Abstract;
use DateTime;
use Getopt::Chain;
use Document::TriPart::Cabinet::UUID;
use Term::Prompt;
use File::Find();
local $Term::Prompt::MULTILINE_INDENT = undef;
use Text::ASCIITable;

our $PRINT = sub { print @_ };

package Blog::Bluejay::AppContext;

use Moose;

extends qw/Getopt::Chain::Context/;

sub bluejay {
    return &Blog::Bluejay::App::bluejay;
}

sub print {
    shift;
    $PRINT->( @_ );
}

package Blog::Bluejay::App;

sub blog_bluejay_class() { return $ENV{BLOG_BLUEJAY} || 'Blog::Bluejay' }

my @bluejay;

{
    my $bluejay;
    sub bluejay {
        return $bluejay ||= do {
            my $class = blog_bluejay_class;
            eval "require $class;" or die "Couldn't require Blog::Bluejay class \"$class\": $@"; # TODO Class::Inspector
            $class->new( @bluejay, @_ );
        };
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


sub find ($@) {
    my $ctx = shift;
    my @criteria = @_;

    return unless @criteria;

    my $criteria = $criteria[0];
    my ($folder, $title) = folder_title @criteria;

    my ($search, $post, $count);
    $search = $ctx->bluejay->posts(
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

sub do_list ($;$) {
    my $ctx = shift;
    my $search = shift;

    $search = scalar $ctx->bluejay->posts unless $search;
    my @posts = $search->search( undef, { order_by => [qw/ creation /] } )->all;

    my $tb = Text::ASCIITable->new({ hide_HeadLine => 1 });
    $tb->setCols( '', '', '' );
    $tb->addRow( $_->uuid, $_->title, $_->folder ) for @posts;
    $ctx->print( $tb );
}

sub do_usage ($) {
    my $ctx = shift;
    Blog::Bluejay::App::help::do_usage $ctx;
}

sub do_new ($$$) {
    my ($ctx, $folder, $title) = @_;

    my $document = $ctx->bluejay->cabinet->create;
    $document->header->{title} = $title;
    $document->header->{folder} = $folder;
    $document->edit;
    return $document;
}

sub do_find ($@) {
    my $ctx = shift;
    my @criteria = @_;

    unless (@criteria) {
        do_list $ctx;
        return;
    }

    my ($post, $search, $count) = find $ctx, @criteria;

    abort "No post found matching your criteria" unless $count;

    choose $search if $count > 1;

    return $post;
}

sub do_choose ($$) {
    my $ctx = shift;
    my $search = shift;

    $ctx->print( "Too many posts found matching your criteria\n" );

    list $search;
}

sub prompt_yn ($$) {
    return prompt Y => shift, '', shift;
}

sub do_no_command ($) {
    my $ctx = shift;

    if ( bluejay->home_exists ) {
        do_usage $ctx;
        do_list $ctx;
    }
    else {
        &Blog::Bluejay::App::help::do_synopsis( $ctx );
    }

    exit -1;
}

#######
# Run #
#######

use Getopt::Chain::Declare;

context 'Blog::Bluejay::AppContext';

start [qw/ home=s /], sub {
    my $ctx = shift;

    if (defined ( my $home = $ctx->option( 'home' ) ) ) {
        push @bluejay, home => $home;
    }

    $ctx->stash(
        bluejay => bluejay,
    );

    if ( $ctx->last ) {
        do_no_command $ctx;
    }
};

on 'setup *' => undef, sub {
    my $ctx = shift;

    my ($home, $yes);

    if ( @_ ) {
        $home = Path::Class::dir( shift );
        $ctx->bluejay->home( $home );
    }
    else {
        $home = $ctx->bluejay->home;
    }
    $home = $home->absolute;

    if ( -e $ctx->bluejay->file( 'assets/.protect' ) ) {
        $ctx->print( <<_END_ );
Don't overwrite your work, fool!
_END_
        return
    }

    if (-d $home) {
        $ctx->print( <<_END_ );
\"$home\" already exists and is a directory, do you want to setup anyway?
_END_
        if ( prompt_yn 'Is this okay? Y/n', 'Y' ) {
            $yes = 1;
        }
        else {
            $ctx->print( <<_END_ );
Aborting deploy
_END_
            exit -1;
        }
    }
    elsif (-f $home) {
        $ctx->print( <<_END_ );
\"$home\" already exists and is a file, cannot continue setup

Aborting deploy
_END_
        exit -1;
    }

    unless ($yes) {
        $ctx->print( <<_END_ );
I will setup in \"$home\"
_END_
        $yes = prompt_yn 'Is this okay? Y/n', 'Y';
    }

    unless ($yes) {
        $ctx->print( <<_END_ );
Aborting deploy
_END_
        exit -1;
    }

    $ctx->bluejay->assets->deploy;

    $ctx->print( "\n" );
    $home = readlink $home if -l $home;
    File::Find::find( { no_chdir => 1, wanted => sub {
    
        return if $_ eq $home;
        my $size;
        $size = -s _ if -f $_;

        $ctx->print( "\t", substr $_, 1 + length $home );
        $ctx->print( " $size" ) if defined $size;
        $ctx->print( "\n" );

    } }, $home );
    $ctx->print( "\n" );

    $ctx->print( <<_END_ );

To control your blog, you can either setup the following script:

    #!/bin/sh
    # $0 --home "$home" \$*
    # Take out the leading comment on the previous line

... or use the following alias:

    # alias "my-blog"="$0 --home \\"$home\\""

_END_
};

on 'publish' => undef, sub {
    my $ctx = shift;
};

on 'edit *' => undef, sub {
    my $ctx = shift;

    return do_list $ctx unless @_;

    my ($post, $search, $count) = find $ctx, @_;

    if ($post) {
        $post->edit;
    }
    else {
        return do_choose $ctx, $search if $count > 1;
        return unless my ($folder, $title) = folder_title @_;
        if (prompt_yn "Post \"$title\" not found. Do you want to start it? y/N", 'Y') {
            my $post = do_new $ctx, $folder, $title;
        }
    }
};

on 'load' => undef, sub {
    my $ctx = shift;

    $ctx->bluejay->dir( 'assets/document' )->recurse(callback => sub {
        my $file = shift;
        return unless -d $file;
        return unless $file->dir_list(-1) =~ m/^($Document::TriPart::Cabinet::UUID::re)$/;
        my $uuid = $1;
        warn "$uuid => $file\n";
        my $document = $ctx->bluejay->cabinet->load( $uuid );
        $document->save;
    });
};

on 'status' => undef, sub {
    my $ctx = shift;

    my ($problem);
    $ctx->print( "home = ", bluejay->home);
    $ctx->print( " (guessed)") if $ctx->bluejay->guessed_home;
    $ctx->print( " ($problem)") if defined ($problem = $ctx->bluejay->status->check_home); 
    $ctx->print( "\n" );
};

on 'list' => undef, sub {
    my $ctx = shift;

    do_list $ctx;
};

require Blog::Bluejay::App::catalyst;
require Blog::Bluejay::App::help;

on qr/.*/ => undef, sub {
    my $ctx = shift;
    my $command = $ctx->command;

    if ($command) {
        $ctx->print( "blog-bluejay: Unknown command \"$command\"\n\n" );
    }

    do_usage $ctx;
    do_list $ctx;
    exit -1;
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
#                my $dir = $bluejay->kit->home_dir->subdir( qw/assets journal/ );
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
