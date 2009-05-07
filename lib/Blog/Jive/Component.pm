package Blog::Jive::Component;

use Moose::Role;
use Carp::Clan;

has jive => qw/is ro required 1 isa Blog::Jive/;
has kit => qw/is ro lazy_build 1 isa Blog::Jive::Kit/;
sub _build_kit {
    return shift->jive->kit,
}

1;

__END__

use Project::Kanjio::Resource;

use File::Assets;
use JS::YUI::Loader;
use JS::jQuery::Loader;
use Template;
use URI;
use URI::QueryParam;
use CGI::FormBuilderX::More;
use Image::Magick;
use Imager;
use SVG::Parser;
use SVG;
my $svg_parser = SVG::Parser->new("--nocredits" => 1);

sub build_uri {
    my $self = shift;
    return $self->kanjio->uri;
}

sub build_tt {
    my $self = shift;
    return {
        DEBUG => Template::Constants::DEBUG_ALL,
        DEBUG => undef,
        INCLUDE_PATH => [ $self->kanjio->assets_tt_dir->stringify ],
        PRE_PROCESS => [ qw/common.tt.html/ ],
    }
}

sub tt_context {
    my $self = shift;
    return (
        kanjio => $self->kanjio,
        assets => File::Assets->new(base => $self->kanjio->rsc),
        yui => JS::YUI::Loader->new_from_internet,
        jquery => JS::jQuery::Loader->new_from_internet(cache => $self->kanjio->rsc->child("%l")),
    );
}

sub render_index_page {
    my $self = shift;
    return $self->_render_page(rsc => "index.html", input => "index.tt.html", context => {
            form => scalar $self->search_form->prepare,
    }, @_);
}

sub render_about_page {
    my $self = shift;
    return $self->_render_page(rsc => "about.html", input => "about.tt.html", context => {
        CPAN_powered_by => [ map {
            my $name = $_;
            chomp $name;
            my $uri = $name;
            { name => $name, uri => URI->new("http://search.cpan.org/perldoc/$uri") };

        } split m/\n/, <<_END_ ],
Moose
Catalyst
KinoSearch
CGI::FormBuilderX::More
Carp::Clan::Share
Catalyst::View::JSON
Catalyst::View::TT
Catalyst::Plugin::Assets
Catalyst::Plugin::Static::Simple
Config::JFDI
DBIx::Deploy
DBIx::Class
Data::Page::Navigation
File::Assets
File::Copy
File::Find
File::Spec::Link
File::Temp
IO::Uncompress::Bunzip2
JS::YUI::Loader
JSON
Lingua::JA::Kana
Math::Random::OO
Path::Class
Path::Resource
SVG
SVG::Parser
Scalar::Util
Template
_END_
    }, @_);
}

sub render_kanji_page {
    my $self = shift;
    my %given = @_;

    croak "Wasn't given kanji" unless $given{kanji};

    my $kanji = $self->kanjio->kanji($given{kanji});
    return $self->_render_page(rsc => $kanji->page_rsc, input => "kanji.tt.html", context => {
        kanji => $kanji,
    }, @_);
}

sub _render_page {
    my $self = shift;
    my %given = @_;

    my $rsc = $given{rsc} or croak "Wasn't given resource";
    $rsc = $self->kanjio->rsc->child($rsc) unless blessed $rsc;
    my $input = $given{input} or croak "Wasn't given input";
    my $context = $given{context} || {};

    $given{force} = 1 if $self->kanjio->testing;

    if ($given{force} || ! -f $rsc->file || ! -s _) {
        $self->process_tt(input => $input, output => $rsc, context => $context);
    }

    return $rsc;
}

sub search_form {
    my $self = shift;
    my %given = @_;

    my $action = $self->uri(qw/search/);

    my $form = CGI::FormBuilderX::More->new(
        fields => [qw/query/],
        params => $given{params},
        action => "$action",
        method => qq/get/,
        submit => ["Submit Comment"],
        validate_with_result => 1,
        validate => sub {
           my ($form, $result) = @_;
        },
    );

    return $form;
}

sub render_svg_image {
    my $self = shift;
    my %given = @_;

    my $svg = $given{svg};
    my $image = $given{image} || $given{png};

    my ($svg_file, $tmp);
    if (blessed $svg && $svg->can("xmlify")) {
        $svg = \$svg->xmlify;
    }
    if (ref $svg eq "SCALAR") {
        $tmp = File::Temp->new(SUFFIX => ".svg");
        print $tmp $$svg, "\n";
        $svg_file = Path::Class::File->new($tmp->filename);
    }
    else {
        $svg_file = "$svg";
    }

    $image = $image->file if blessed $image && $image->can("file");

    $image->parent->mkpath unless -d $image->parent;
    system("inkscape", $svg_file, "-e", "$image", qw/-z -D/);
    system("convert", "$image", qw/-antialias/, @{ $given{convert} }, "$image") if $given{convert};
    if ($given{process}) {
        my $in = Image::Magick->new;
        $in->Read($image);
        my $out = $given{process}->($in);
        $out->Write($image) if $out;
    }
}

sub render_image_favicon {
    my $self = shift;
    my %given = @_;

    my $image_file = $given{image};
    $image_file = $image_file->file if $image_file->can("file");
    my $favicon_file = $given{favicon};
    $favicon_file = $favicon_file->file if $favicon_file->can("file");

    $favicon_file->parent->mkpath unless -d $favicon_file->parent;
    my $favicon = Imager->new;
    $favicon->read(file => "$image_file") or die $favicon->errstr;
    $favicon->write(file => "$favicon_file") or die $favicon->errstr;
}

has _point_image_rsc => qw/is ro required 1 lazy 1/, default => sub { {} };
sub point_image_rsc {
    my $self = shift;
    my $size = shift || 4;
    my $state = shift || "off";

    local $_ = $size;
    ($size) = m/^\s*(\d+)\s*$/ or croak "Don't understand size $_";

    local $_ = lc $state;
    ($state) = m/^\s*(on|off|over)\s*$/ or croak "Don't understand state $_";

    my $key = "$size-$state";

    return $self->_point_image_rsc->{$key} ||= Project::Kanjio::Resource->new(
        rsc => $self->kanjio->rsc->child("$key.png"),
        force => 1,
        do => sub {
            my $rsc = shift;
            my $fill = $state ne "on" ? "white" : "black";
            $self->render_svg_image(image => $rsc, svg => \<<_END_);
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="100%" height="100%" version="1.1"
xmlns="http://www.w3.org/2000/svg">
<circle cx="0" cy="0" r="$size" style="fill: $fill"/>
</svg>
_END_
#<rect x="-8" y="-8" width="16" height="16" style="fill: none; stroke:#999; stroke-width:1;"/>
        },
    );
}

sub spacer_image_rsc {
    my $self = shift;
    my $rsc = $self->kanjio->rsc->child("spacer.gif");
    unless (-f $rsc->file && -s _) {
        my $image = Imager->new(xsize=>1, ysize=>1, channels => 4);
        $image->box(filled => 1, color => "#ffffff00") or die $image->errstr;
        $image->write(file => $rsc->file) or die $image->errstr;
    }
    return $rsc;
}

has question_mark_svg_file => qw/is ro required 1 lazy 1 isa Path::Class::File/, default => sub {
    my $self = shift;
    return $self->kanjio->assets_dir->file(qw/Question_mark.svg/);
};
has question_mark_svg => qw/is ro required 1 lazy 1 isa SVG/, default => sub {
    my $self = shift;
    return $svg_parser->parsefile($self->question_mark_svg_file->stringify);
};
has _question_mark_image_rsc => qw/is ro required 1 lazy 1/, default => sub { {} };
sub question_mark_image_rsc {
    my $self = shift;
    my $size = shift;
    my $rsc = $self->_question_mark_image_rsc->{$size} ||= do {
        croak "Don't understand size $size" unless $size =~ m/^\d+$/;
        $self->kanjio->rsc->child("question-mark-$size.png");
    };
    unless (-f $rsc->file && -s _) {
        my $svg_file = $self->question_mark_svg_file;
        croak "Question mark file $svg_file doesn't exist?" unless -e $svg_file;
        $self->render_svg_image(svg => $self->question_mark_svg_file, image => $rsc->file,
            convert => [-resize => "${size}x${size}", -size => "${size}x${size}", qw/xc:none +swap -gravity center -composite/]);
    };
    return $rsc;
}

1;

__END__

has render_page_resource => qw/is ro required 1 lazy 1 isa HashRef/, default => sub { {} };

sub setup_render_page {
    my $self = shift;
    if (! ref $_[0] && ref $_[1] eq "CODE") {
        my %given = @_;
        while (my ($name, $context) = each %given) {
            $self->render_page_resource->{$name} = Project::Kanjio::Resource->new(
                rsc => $self->kanjio->rsc->child("$name.html"),
                do => sub {
                    my $rsc = shift;
                    $self->process_tt(input => "$name.tt.html", output => $rsc, context => $context->($self));
                },
            );
        }
    }
    else {
        croak "Don't know what to do!";
    }
}

1;
