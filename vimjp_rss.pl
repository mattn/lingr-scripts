#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Furl;
use JSON;
use GDBM_File;
use Digest::SHA1 qw/sha1_hex/;
use HTML::Entities;
use Encode;
use URI;
use XML::Feed;
use XML::Feed::Deduper;

my $secret = shift;

my $dup_path = '/home/mattn/tmp/dup-vimjp-rss-lingr.db';

my $feed = XML::Feed->parse(URI->new('http://vim-jp.org/rss.xml'));
my $deduper = XML::Feed::Deduper->new(
    path => $dup_path,
);

my $ua = Furl->new(agent => $0, timeout => 10, ssl_opts => { SSL_verify_mode => 0 });
$ua->env_proxy;
for my $entry ($deduper->dedup($feed->entries)) {
    my $link = $entry->link;
    next unless $link =~ /\/blog\//;
    my $body = $entry->title;
    $body = decode_entities($body);
    my $msg = sprintf("%s\n%s",
        $body,
        $entry->link);
    print "$msg\n";

	my $res = $ua->post('http://lingr.com/api/room/say', [], [
	    room => 'vim',
	    bot  => 'vim_jp',
	    bot_verifier => sha1_hex('vim_jp' . $secret),
	    text => encode_utf8($msg),
	]) if $secret;
}
