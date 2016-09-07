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
use Encode;
use URI;
use XML::Feed;
use XML::Feed::Deduper;

my $secret = shift;

my $dup_path = '/home/mattn/tmp/dup-qiita-feed-lingr.db';

my $feed = XML::Feed->parse(URI->new('http://qiita.com/tags/Vim/feed'));
my $deduper = XML::Feed::Deduper->new(
    path => $dup_path,
    ignore_id => 1,
);

my $ua = Furl->new(agent => $0, timeout => 10);
$ua->env_proxy;
for my $entry ($deduper->dedup($feed->entries)) {
    my $msg = sprintf("%s\n%s",
        $entry->title,
        $entry->link);
    print "$msg\n";

    my $res = $ua->post('http://lingr.com/api/room/say', [], [
        room => 'vim',
        bot  => 'vim_jp',
        bot_verifier => sha1_hex('vim_jp' . $secret),
        text => $msg,
    ]) if $secret;
}
