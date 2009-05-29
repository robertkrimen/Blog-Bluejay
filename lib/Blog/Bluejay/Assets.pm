package Blog::Bluejay::Assets;

use strict;
use warnings;

use Blog::Bluejay::Assets::Source;
use constant Source => 'Blog::Bluejay::Assets::Source';

use Directory::Deploy::Declare;

include <<'_END_';
run/
assets/
assets/root/
assets/root/static/
assets/tt/
_END_


# TODO: Warn about SCALAR versus ! ref

include

    map { $_ => Source->catalog->{$_} } keys %{ Source->catalog }

;

#    'assets/tt/frame.tt.html' => \<<'_END_',
#[% yui.include.fonts.grids.reset.base %]
#[% assets.include("static/css/b9.css", -100) %]
#[% assets.include("static/css/b9-home.css", -100) %]
#[% assets.include("static/css/b9-journal.css", -100) %]
#[% assets.include(jquery.uri, -100) %]

#[% DEFAULT title = template.title %]
#[% DEFAULT default_title = "b9" %]
#[% DEFAULT title = default_title %]

#[% CLEAR -%]
#<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
#<html xmlns="http://www.w3.org/1999/xhtml">
#<head>
#<title>[% title %]</title>
#<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
#[% yui.html %]
#[% assets.export("css") %]
#</head>
#<body>

#<div id="doc2">

#[% content %]
#    
#    <div class="footer">

#        <a href="mailto:robertkrimen-gmail-com">robert krimen @ gmail com</a> |
#        <a href="/">http://bravo9.com</a> |
#        &copy; 2007-2008 Robert Krimen

#    </div>

#</div>

#[% assets.export("js") %]

#</body>
#</html>
#_END_

#    'assets/tt/posts.tt.html' => \<<'_END_',
#[% CLEAR -%]
#<div class="pst-list">
#[% FOREACH post = posts %]
#    <div class="pst-post">

#        <div class="pst-header">

#            <div class="pst-title"><a href="[% post.uri %]">[% post.title %]</a></div>

#            <div class="pst-subtitle">

#                <div class="pst-creation">

#                    [% post.created.clone.set_time_zone("UTC").set_time_zone("US/Pacific").strftime("%e %B %Y %l:%M%P") %]

#                </div>
#                
#                [% clear %]

#            </div>

#        </div>

#        <div class="pst-body">
#            [% post.body.render %]
#        </div>

#    </div>
#    [% IF ! loop.last %]
#    <div class="pst-post-separator"></div>
#    [% END %]
#[% END %]
#</div>
#_END_
#    ;

no Directory::Deploy::Declare;

use Moose;

has embed => qw/is ro lazy_build 1/;
sub _build_embed {
    require Blog::Bluejay::Assets::Embed;
    Blog::Bluejay::Assets::Embed->catalog;
}
# TODO Add reporting option/return manifest

1;
