package Blog::Bluejay::App::Journal;

use strict;
use warnings;

use Blog::Bluejay;

use Getopt::Chain;
use Data::UUID::LibUUID;
use Carp;
use Path::Abstract;
use DateTime;
use Getopt::Chain;
use Term::Prompt;
use Text::ASCIITable;

local $Term::Prompt::MULTILINE_INDENT = undef;

my $bluejay = Blog::Bluejay->new;
my $journal = $bluejay->journal;
my $cabinet = $journal->cabinet;

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
    $search = $journal->posts(
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

    $search = scalar $journal->posts unless $search;
    my @posts = $search->search( undef, { order_by => [qw/ creation /] } )->all;

    my $tb = Text::ASCIITable->new({ hide_HeadLine => 1 });
    $tb->setCols( '', '', '' );
    $tb->addRow( $_->uuid, $_->title, $_->folder ) for @posts;
    print $tb;
}

sub do_new {
    my ($folder, $title) = @_;
    my $document = $cabinet->create;
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

#######
# Run #
#######

sub run {

    Getopt::Chain->process(

        commands => {

            DEFAULT => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments;

                if (defined (my $command = $context->command)) {
                    print <<_END_;
    Unknown command: $command
_END_
                }

                print <<_END_;
    Usage: $0 <command>

        new
        edit <criteria> ...
        list 
        assets <key>

_END_
                do_list unless @_;
            },

            new => {
                options => [qw/link=s/],

                run => sub {
                    my $context = shift;

                    my ($folder, $title) = folder_title @_ or abort "Missing a title";

                    if (my $post = do_new $folder, $title) {
                    }
                },
            },

            edit => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments; # TODO Should pass in remaining arguments

                return do_list unless @_;

                my ($post, $search, $count) = find @_;

                if ($post) {
                    $post->edit;
                }
                else {
                    return do_choose $search if $count > 1;
                    return unless my ($folder, $title) = folder_title @_;
                    if (prompt y => "Post \"$title\" not found. Do you want to start it?", undef, 'N') {
                        my $post = new $folder, $title;
                    }
                }
            },

            assets => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments;

                return unless my $post = do_find @_;

                my $assets_dir = $post->assets_dir;

                if (-d $assets_dir) {
                    print "$assets_dir already exists\n";
                }
                else {
                    $assets_dir->mkpath;
                }
            },

            link => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments;

                return do_list unless @_;

                my $criteria = shift;

                return unless my $post = find $criteria;

                $post->link(@_);
            },

            'link-all' => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments;

                return do_list unless @_;

                my @posts = $cabinet->model->search(post => {});
                for (@posts) {
                    $_->link(@_);
                }
            },

            list => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments;

                my $search;
                (undef, $search) = find @_ if $_;

                do_list $search;
            },

            retitle => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments;
            },
            
        },
    );

}

1;

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

