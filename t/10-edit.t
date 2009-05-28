#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Blog::Bluejay;

my ($scratch, $bluejay, $document, $post, $uuid);

$scratch = Directory::Scratch->new;
$bluejay = Blog::Bluejay->new( home => $scratch->dir( qw/.blog-bluejay/ ) );

$document = $bluejay->cabinet->create;
ok( $uuid = $document->uuid );
$document->save;

ok( $post = $bluejay->post( $uuid ) );
is( $post->body->render, undef ); # TODO Should this always be something?
#is( $post->body->render, <<_END_ );
#_END_

$document->edit( \<<_END_ );
type: markdown
---
The *quick* brown fox jumped over the **lazy** dog
_END_

ok( $post = $bluejay->post( $uuid ) );
is( $post->body->render, <<_END_ );
<p>The <em>quick</em> brown fox jumped over the <strong>lazy</strong> dog</p>
_END_

$document->edit( \<<_END_ );
type: tt-markdown
---
[% BLOCK lorem %]
Lorem *ipsum*
[% END %]
[% CLEAR -%]
[% INCLUDE lorem %]

The *quick* brown fox jumped over the **lazy** dog
_END_

ok( $post = $bluejay->post( $uuid ) );
is( $post->body->render, <<_END_ );
<p>Lorem <em>ipsum</em></p>

<p>The <em>quick</em> brown fox jumped over the <strong>lazy</strong> dog</p>
_END_
