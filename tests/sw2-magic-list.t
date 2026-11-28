use strict;
use warnings;
use utf8;
use Cwd qw/abs_path getcwd/;
use Encode qw/encode_utf8/;
use File::Copy qw/copy/;
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;
use FindBin;
use Test::More;
no warnings 'once';

plan skip_all => 'CGI が必要です' unless eval { require CGI; require CGI::Cookie; 1 };
binmode Test::More->builder->output, ':encoding(UTF-8)';
binmode Test::More->builder->failure_output, ':encoding(UTF-8)';

our $core_dir = "$FindBin::Bin/../_core";
require "$core_dir/lib/subroutine.pl";
require "$core_dir/lib/sw2/subroutine-sw2.pl";
require "$core_dir/lib/sw2/calc-arts.pl";

my $workspace = tempdir(CLEANUP => 1);
my $installDir = "$workspace/sw2.5";
my $legacyDir = "$installDir/data/arts/anonymous/1002";
make_path($legacyDir);
symlink abs_path($core_dir), "$workspace/_core" or die $!;
copy("$FindBin::Bin/../sw2.5/index.cgi", "$installDir/index.cgi") or die $!;
writeFile("$installDir/config.cgi", "1;\n");
writeFile("$installDir/data/charpass.cgi", "legacy<><>1002<>a<>\n");

my %form = (
  magicName => '九', magicLevel => '9', magic2_magicName => '五', magic2_magicLevel => '５',
  magic3_magicName => '一', magic3_magicLevel => '1', magic4_magicName => '空欄', magic4_magicLevel => ' ',
  magicMinor => 1,
);
my ($indexed) = listRow('indexed', 1001, %form, magicFormOrder => '3,1,2,4');
my ($reordered) = listRow('reordered', 1003, %form, magicFormOrder => '2,4,1,3');
is((split /<>/, $indexed)[7], '真語魔法／1～9／小魔法', '一覧の保存値は最小レベル～最大レベル');
is((split /<>/, $reordered)[7], (split /<>/, $indexed)[7], '並べ替えで範囲は変わらない');

my ($legacy, $saved) = listRow('legacy', 1002, magicClass => '秘奥魔法', magicFormOrder => '1,2',
  magicName => '七', magicLevel => '7', magic2_magicName => '三', magic2_magicLevel => '3');
my @legacyFields = split /<>/, $legacy;
$legacyFields[7] = '秘奥魔法／7';
$legacy = join '<>', @legacyFields[0 .. 12], '';
writeFile("$legacyDir/data.cgi", join '', map { "$_<>$saved->{$_}\n" }
  grep { defined($saved->{$_}) && $saved->{$_} ne '' } keys %$saved);

my ($equal) = listRow('equal', 1004, magicFormOrder => '1,2', magicName => '同じ五', magicLevel => '5',
  magic2_magicName => '同じ五の全角', magic2_magicLevel => '５');
my ($mixed) = listRow('mixed', 1005, magicClass => '練技', magicFormOrder => '1,2,3',
  magicName => '範囲', magicLevel => '3-7', magic2_magicName => '高いレベル', magic2_magicLevel => '12',
  magic3_magicName => '超越', magic3_magicLevel => '超');
my ($single) = listRow('single', 1006, magicName => '単体', magicLevel => '2');
my ($secret) = listRow('secret', 1007, %form, magicFormOrder => '1,2,3,4', forbidden => 'all');
writeFile("$installDir/data/artslist.cgi", join "\n", $indexed, $reordered, $legacy, $equal, $mixed, $single, $secret, '');

my $html = requestList();
is(subcategory($html, 'indexed'), '真語魔法／1～9レベル／小魔法', 'レベル範囲と小魔法の指定を表示する');
is(subcategory($html, 'legacy'), '秘奥魔法／ランク3～7', '旧形式の複数魔法からランク範囲を取得する');
is(subcategory($html, 'equal'), '真語魔法／5レベル', '同じレベルが複数あっても一つの値を表示する');
is(subcategory($html, 'mixed'), '練技／3～12レベル／超', '数値の範囲と超越の表記を表示する');
is(subcategory($html, 'single'), '真語魔法／2レベル', '既存の単体の表示形式を維持する');
is(subcategory($html, 'secret'), '真語魔法／1～9レベル／小魔法', '内容を秘匿するシートも一覧には範囲を表示する');

for my $query ('真語魔法／1', '真語魔法／5', '真語魔法／９', '5／小魔法'){
  my $results = requestList($query);
  is(subcategory($results, 'indexed'), subcategory($results, 'reordered'), "順序に関係なく $query を検索できる");
  ok(defined subcategory($results, 'indexed'), "$query で複数魔法を検索できる");
}
ok(!defined subcategory(requestList('真語魔法／6'), 'indexed'), '範囲内の未登録の値ではヒットしない');
ok(defined subcategory(requestList('秘奥魔法／3'), 'legacy'), '旧形式でも全件のレベルを検索できる');
ok(!defined subcategory(requestList('真語魔法／5'), 'secret'), '個別データを秘匿するシートの検索には一覧の表示値を使う');

done_testing;

sub listRow {
  my ($id, $number, %fields) = @_;
  local $::mode_save = 1;
  local $::file = $number;
  local $::now = 1767268800;
  local $::updatedLine;
  my %data = dataCalc({
    id => $id, birthTime => $::now, category => 'magic', magicClass => '真語魔法', %fields,
  });
  return ($::updatedLine, \%data);
}

sub setUpdatatLineImage { return ''; }

sub requestList {
  my ($query) = @_;
  local %ENV = (
    %ENV, REQUEST_METHOD => 'GET', QUERY_STRING => 'type=a&category=magic',
    SERVER_NAME => 'example.test', SERVER_PORT => 80, SCRIPT_NAME => '/sw2.5/index.cgi', HTTP_COOKIE => '',
  );
  $ENV{QUERY_STRING} .= '&sub='.CGI::escape(encode_utf8($query)) if defined $query;
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

sub subcategory {
  my ($html, $id) = @_;
  my ($row) = $html =~ m{href="\./\?id=\Q$id\E">((?:(?!<tr).)*)}s;
  my ($sub) = ($row // '') =~ m{<td class="sub">([^\n]*)};
  return defined($sub) ? removeTags($sub) : undef;
}

sub writeFile {
  my ($path, $content) = @_;
  open my $file, '>:encoding(UTF-8)', $path or die "$path: $!";
  print {$file} $content;
  close $file or die "$path: $!";
}
