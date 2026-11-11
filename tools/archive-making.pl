#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
require "$FindBin::Bin/../_core/lib/sw2/making-log.pl";

die "使い方: perl tools/archive-making.pl ログファイル [残す件数 分割単位]\n"
  unless @ARGV == 1 || @ARGV == 3;
my ($file, $keep, $unit) = @ARGV;
die "現行ログが見つかりません。\n" unless -f $file;
my $moved = eval {
  YtSheet::MakingLog->new(
    file => File::Spec->rel2abs($file),
    keep => $keep // 1000, unit => $unit // 1000,
  )->archive;
};
die $@ if $@;
print "$moved 件を過去ログへ退避しました。\n";
