package Blog::Bluejay::Assets::Data::Source;
1;
__DATA__
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
<div>
    <div class="post">

        <div class="post-header">

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
[% INCLUDE post.tt.html %]
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

.datetime {
    float: right;
    color: #666;
    font-size: 14px;
    line-height: 1.2;
    margin: 15px -10px 20px 20px;
    margin: 0px -10px 20px 20px;
    margin: 0px 0px 10px 20px;
/*    background: #eee;*/
/*    background: #eee;*/
/*    border: 2px solid #eef;*/
/*    border-bottom: 2px solid #eee;*/
    padding: 5px;
}

.datetime-time {
    float: left;
    font-size: 12px;
/*    margin-left: 10px;*/
}

.datetime-weekday {
    float: left;
    color: #666;
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
