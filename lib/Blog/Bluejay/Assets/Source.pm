package Blog::Bluejay::Assets::Source;

use strict;
use warnings;

use Blog::Bluejay::Assets::Data::Source;

{
    my $catalog;
    sub catalog {
        return $catalog ||= do {
            my %catalog;
            my ($path, $content);
            while (<Blog::Bluejay::Assets::Data::Source::DATA>) {
                if ( ! $path ) {
                    chomp; $path = $_;
                    $content = '';
                }
                elsif (m/^__ASSET__$/) {
                    my $__ = $content;
                    $catalog{$path} = \$__;
                    undef $path;
                    undef $content;
                }
                else {
                    $content .= $_;
                }
            }
            \%catalog;
        };
    }
}

1;
