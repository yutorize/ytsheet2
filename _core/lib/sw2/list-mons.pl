################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use Encode;
use HTML::Template;

my $LOGIN_ID = check;

my $mode = param('mode');

require $set::data_mons;

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

$INDEX->param(modeMonsList => 1);
$INDEX->param(modeMylist => 1) if $mode eq 'mylist';
$INDEX->param(typeName => '魔物');

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(mode => $mode);
$INDEX->param(type => 'm');

### データ処理 #######################################################################################
### クエリ --------------------------------------------------
my $index_mode;
if(!($mode eq 'mylist' || param('tag') || param('taxa') || param('name'))){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
}

### ファイル読み込み --------------------------------------------------
## マイリスト取得
my @mylist;
if($mode eq 'mylist'){
  $INDEX->param( playerName => (getplayername($LOGIN_ID))[0] );
  open (my $FH, "<", $set::passfile);
  while(<$FH>){
    my @data = (split /<>/, $_)[0,1];
    if($data[1] eq "\[$LOGIN_ID\]"){ push(@mylist, $data[0]) }
  }
  close($FH);
}

## リスト取得
open (my $FH, "<", $set::monslist);
my @list = <$FH>;
close($FH);

### フィルタ処理 --------------------------------------------------
## マイリスト
if($mode eq 'mylist'){
  my $regex = join('|', @mylist);
  @list = grep { (split(/<>/))[0] =~ /^(?:$regex)$/ } @list;
}
## 非表示除外
elsif (
     !($set::masterid && $set::masterid eq $LOGIN_ID)
  && !($mode eq 'mylist')
  && !param('tag')
){
  @list = grep { !(split(/<>/))[16] } @list;
}

## 分類検索
my $taxa_query = Encode::decode('utf8', param('taxa'));
if($taxa_query) {
  @list = grep { (split(/<>/))[6] eq $taxa_query } @list;
  
}
$INDEX->param(group => $taxa_query);

## タグ検索
my $tag_query = Encode::decode('utf8', param('tag'));
if($tag_query) { @list = grep { (split(/<>/))[15] =~ / $tag_query / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = Encode::decode('utf8', param('name'));
if($name_query) { @list = grep { (split(/<>/))[4] =~ /$name_query/ } @list; }
$INDEX->param(name => $name_query);

### リストを回す --------------------------------------------------
my %count;
my %grouplist;
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $author, $taxa, $lv,
    $intellect, $perception, $disposition, $sin, $initiative, $weakness,
    $image, $tag, $hide
  ) = (split /<>/, $_)[0..16];
  
  #カウント
  $count{$taxa}++;
  #最大表示制限
  next if ($index_mode && $count{$taxa} > $set::list_maxline && $set::list_maxline);
  
  #更新日時
  my ($min,$hour,$day,$mon,$year) = (localtime($updatetime))[1..5];
  $year += 1900; $mon++;
  $updatetime = sprintf("<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>",$year,$mon,$day,$hour,$min);
  
  #出力用配列へ
  my @characters;
  push(@characters, {
    "ID" => $id,
    "NAME" => $name,
    "AUTHOR" => $author,
    "TAXA" => $taxa,
    "LV" => $lv,
    "DATE" => $updatetime,
    "HIDE" => $hide,
  });
  
  push(@{$grouplist{$taxa}}, @characters);
}

### 出力用配列 --------------------------------------------------
my @characterlists; 
@data::taxa = sort{$a->[1] <=> $b->[1]} @data::taxa;
foreach (@data::taxa){
  my $name = $_->[0];
  ## ソート
  unless($index_mode && $set::list_maxline){
    @{$grouplist{$name}} = sort { $a->{'LV'} <=> $b->{'LV'} } @{$grouplist{$name}};
  }
  ## ページネーション
  next if !$count{$name};
  push(@characterlists, {
    "URL" => uri_escape_utf8($name),
    "NAME" => $name,
    "NUM" => $count{$name},
    "Characters" => [@{$grouplist{$name}}],
  });
}

$INDEX->param("Lists" => \@characterlists);


$INDEX->param("title" => $set::title);
$INDEX->param("ver" => $::ver);
$INDEX->param("coreDir" => $::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;