use strict;
use warnings;
use utf8;
use Cwd qw/abs_path getcwd/;
use File::Copy qw/copy/;
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;
use FindBin;
use Test::More;

plan skip_all => 'CGI が必要です' unless eval { require CGI; require CGI::Cookie; 1 };
binmode Test::More->builder->output, ':encoding(UTF-8)';
binmode Test::More->builder->failure_output, ':encoding(UTF-8)';

my $workspace = tempdir(CLEANUP => 1);
my $installDir = "$workspace/sw2.5";
my $sheetDir = "$installDir/data/arts/anonymous/1234";
make_path($sheetDir);
symlink abs_path("$FindBin::Bin/../_core"), "$workspace/_core" or die $!;
copy("$FindBin::Bin/../sw2.5/index.cgi", "$installDir/index.cgi") or die $!;
writeFile("$installDir/config.cgi", "1;\n");
writeFile("$installDir/data/charpass.cgi", "testid<><>1234<>a<>\n");

my $legacy = '2026-01-01-12-00-00';
my $multiple = '2026-01-01-12-00-10';
my $god = '2026-01-01-12-00-20';
my %base = (id => 'testid', type => 'a', ver => '2.01.018', protect => 'none', category => 'magic');
writeFile("$sheetDir/logs.cgi", join '',
  "=$legacy=\n", dataLines({ %base, magicName => '追加前の魔法' }),
  "=$multiple=\n", dataLines({ %base, magicNum => 2, magicOrder => '4,7',
    magicName => '過去の魔法4', magic2_magicName => '過去の魔法7' }),
  "=$god=\n", dataLines({ %base, category => 'god', godName => '過去の神格',
    magicNum => 2, magicOrder => '4,7', magicName => '未使用の魔法4' }),
);
writeFile("$sheetDir/log-list.cgi", join '',
  "$legacy<>1767268800<>追加前\n", "$multiple<>1767268810<>並べ替え前\n",
  "$god<>1767268820<>神格\n", "latest<>1767268830<>\n",
);
writeFile("$sheetDir/data.cgi", dataLines({ %base, magicNum => 2, magicOrder => '7,4',
  magicName => '現在の魔法7', magic2_magicName => '現在の魔法4' }));

my $id = '?id=testid';
my $latestSingle = requestView("$id&magic=4");
like($latestSingle, qr/現在の魔法4/, '現在の魔法を単体で表示する');
is_deeply([logLinks($latestSingle)], [
  "$id&magic=4", "$id&log=$god", "$id&log=$multiple&magic=4", "$id&log=$legacy",
], '同じ固定番号の魔法がある履歴だけ単体表示にする');
like(requestView("$id&log=$legacy"), qr/追加前の魔法/, '追加前の履歴を開ける');
like(requestView("$id&log=$multiple&magic=4"), qr/過去の魔法4/, '並べ替え前の同じ魔法を開ける');
is_deeply([logLinks(requestView($id))], [
  $id, "$id&log=$god", "$id&log=$multiple", "$id&log=$legacy",
], '全体表示では履歴も全体表示を開く');

writeFile("$sheetDir/data.cgi", dataLines({ %base, magicNum => 1, magicOrder => '7', magicName => '現在の魔法7' }));
my $archivedSingle = requestView("$id&log=$multiple&magic=4");
is_deeply([logLinks($archivedSingle)], [
  $id, "$id&log=$god", "$id&log=$multiple&magic=4", "$id&log=$legacy",
], '最新データから削除されていた魔法は全体表示へのリンクにする');
like(requestView("$id&magic=4"), qr/^Status: 404\b/m, '削除済みの魔法を指定した単体URLは404のまま');
is_deeply([logLinks(requestView("$id&log=$legacy&magic=1"))], [
  $id, "$id&log=$god", "$id&log=$multiple", "$id&log=$legacy&magic=1",
], '旧形式の単体データも固定番号1として扱う');

done_testing;

sub requestView {
  my ($query) = @_;
  local %ENV = (
    %ENV,
    REQUEST_METHOD => 'GET', QUERY_STRING => substr($query, 1),
    SERVER_NAME => 'example.test', SERVER_PORT => 80, SCRIPT_NAME => '/sw2.5/index.cgi', HTTP_COOKIE => '',
  );
  my @includePaths = map { "-I$_" } grep { !ref } @INC;
  my $cwd = getcwd();
  chdir $installDir or die $!;
  open my $cgi, '-|', $^X, @includePaths, 'index.cgi' or die $!;
  chdir $cwd or die $!;
  binmode $cgi, ':encoding(UTF-8)';
  my $response = do { local $/; <$cgi> };
  close $cgi or die 'CGIの実行に失敗しました。';
  return $response;
}

sub logLinks {
  my ($response) = @_;
  my ($list) = $response =~ m{<aside id="loglist"[^>]*>\s*<h2>[^<]*</h2>\s*<ul>(.*?)</ul>}s;
  return map { CGI::unescapeHTML($_) } ($list // '') =~ /<a href="([^"]+)"/g;
}

sub dataLines {
  my ($data) = @_;
  return join '', map { "$_<>$data->{$_}\n" } sort keys %$data;
}

sub writeFile {
  my ($path, $content) = @_;
  open my $file, '>:encoding(UTF-8)', $path or die "$path: $!";
  print {$file} $content;
  close $file or die "$path: $!";
}
