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

my $secret = shift;

my $dup_path = '/home/mattn/tmp/dup-unite-issue-lingr.db';

my %dup;
unless ($ENV{DEBUG}) {
    tie %dup, 'GDBM_File', $dup_path, &GDBM_WRCREAT, 0640;
}

my $ua = Furl->new(agent => $0, timeout => 10);
$ua->env_proxy;
my $res = $ua->get('https://api.github.com/repos/Shougo/unite.vim/issues');
$res->is_success or die;
my $dat = decode_json($res->content);
for my $issue (@{$dat}) {
    next if $dup{$issue->{id}}++;

    my $msg = sprintf("%s\n%s",
        $issue->{title},
        $issue->{html_url});
    print "$msg\n";

    my $res = $ua->post('http://lingr.com/api/room/say', [], [
        room => 'vim',
        bot  => 'vim_jp',
        bot_verifier => sha1_hex('vim_jp' . $secret),
        text => encode_utf8($msg),
    ]) if $secret;
}
