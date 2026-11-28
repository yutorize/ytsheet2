use strict;
use warnings;
use utf8;
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

local %ENV = (
  REQUEST_METHOD => 'GET', QUERY_STRING => '', SERVER_NAME => 'example.test',
  SERVER_PORT => 80, SCRIPT_NAME => '/sw2.5/index.cgi',
);
local *fetchJson = sub { die '同じ設置先の読み込みで外部のJSON取得が呼ばれました。' };

my $dataDir = tempdir(CLEANUP => 1).'/';
local $set::passfile = $dataDir.'charpass.cgi';
local $set::lib_type{a} = { dataDir => $dataDir };
local $set::image_maxcount = 1;
my $sheetDir = $dataDir.'anonymous/1234';
make_path($sheetDir);
writeFile($set::passfile, "testid<><>1234<>a<>\n");

my $log = '2026-01-01-12-00-00';
my %data = (
  type => 'a', category => 'magic', protect => 'password',
  magicNum => 2, magicOrder => '7,4', magicLastNumber => 7,
  magicName => '先頭の魔法', magic2_magicName => '単体で参照する魔法',
  magicPageTitle => '魔法集', magicClass => '真語魔法', magicDescription => '共通の由来',
);
writeFile("$sheetDir/data.cgi", dataLines(\%data));
writeFile("$sheetDir/logs.cgi", "=$log=\n".dataLines({ %data, magic2_magicName => '変更前の魔法' }));

my $canonicalURL = CGI->new()->url.'?id=testid';
my $directoryURL = 'http://example.test/sw2.5/?magic=4&id=testid#magic-4';
for my $url ("$canonicalURL&magic=4", $directoryURL){
  my %imported = importSheetData($url);
  is($imported{magicName}, '単体で参照する魔法', '固定番号の魔法を読み込む');
  is($imported{artsName}, $imported{magicName}, '選択した魔法名を使用する');
  is($imported{magicNum}, 1, '単体のデータになる');
  is_deeply([@imported{qw/magicClass magicDescription/}], ['真語魔法', '共通の由来'], '共通欄を引き継ぐ');
  ok(!exists($imported{magic2_magicName}) && !exists($imported{magicPageTitle}), '複数件用の欄を除く');
}

my %whole = importSheetData($canonicalURL);
is($whole{magicNum}, 2, 'シート全体のURLは全件を読み込む');
my %history = importSheetData("$canonicalURL&magic=4&log=$log");
is($history{magicName}, '変更前の魔法', '指定された過去ログから魔法を読み込む');
my %missing = importSheetData("$canonicalURL&magic=5", softError => 1);
like($missing{_error}, qr/指定された番号の魔法/, '存在しない番号はエラーになる');
my %bad = importSheetData("$canonicalURL&magic=0", softError => 1);
like($bad{_error}, qr/魔法番号/, '不正な番号はエラーになる');

$data{forbidden} = 'all';
writeFile("$sheetDir/data.cgi", dataLines(\%data));
my %forbidden = importSheetData("$canonicalURL&magic=4&log=$log", softError => 1);
like($forbidden{_error}, qr/閲覧・編集に制限/, '過去ログでも最新の閲覧制限を適用する');

done_testing;

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
