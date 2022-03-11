################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;

my $mode = $::in{'mode'};

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
foreach (keys %::in) {
  $::in{$_} =~ s/</&lt;/g;
  $::in{$_} =~ s/>/&gt;/g;
}
if(!($mode eq 'mylist' || $::in{'tag'} || $::in{'taxa'} || $::in{'name'} || $::in{'lv-max'} || $::in{'lv-min'})){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
}
if(!$::in{'taxa'} && $mode ne 'mylist'){ $INDEX->param(modeTaxaAll => 1); }
my @q_links;
foreach(
  'mode',
  'tag',
  'taxa',
  'name',
  'lv-min',
  'lv-max',
  ){
  push( @q_links, $_.'='.uri_escape_utf8(decode('utf8', param($_))) ) if param($_);
}
my $q_links = join('&', @q_links);

### ファイル読み込み --------------------------------------------------
## マイリスト取得
my @mylist;
if($mode eq 'mylist'){
  $INDEX->param( playerName => (getplayername($LOGIN_ID))[0] );
  open (my $FH, "<", $set::passfile);
  while(my $line = <$FH>){
    if($line =~ /^(.+?)<>\[$LOGIN_ID\]</){ push(@mylist, $1) }
  }
  close($FH);
}

## リスト取得
my @list;
if($set::simpleindex && $index_mode){ #グループ見出しのみ
  my @grouplist;
  foreach (sort { $a->[1] cmp $b->[1] } @data::taxa){
    push(@grouplist, {
      "ID" => @$_[0],
      "NAME" => @$_[0],
    });
  }
  $INDEX->param("ListGroups" => \@grouplist);
}
else { #通常
  open (my $FH, "<", $set::monslist);
  @list = <$FH>;
  close($FH);
}
### フィルタ処理 --------------------------------------------------
## マイリスト
if($mode eq 'mylist'){
  my $regex = join('|', @mylist);
  @list = grep { $_ =~ /^(?:$regex)\</ } @list;
}
## 非表示除外
elsif (
     !($set::masterid && $set::masterid eq $LOGIN_ID)
  && !($mode eq 'mylist')
  && !$::in{'tag'}
){
  @list = grep { !(split(/<>/))[16] } @list;
}

## 分類検索
my $taxa_query = decode('utf8', $::in{'taxa'});
if($taxa_query) {
  @list = grep { $_ =~ /^(?:[^<]*?<>){6}\Q$taxa_query\E</ } @list;
}
$INDEX->param(group => $taxa_query);
my @taxalist;
foreach (sort { $a->[1] cmp $b->[1] } @data::taxa){
  push(@taxalist, {
    "NAME" => @$_[0],
    "SELECTED" => $taxa_query eq @$_[0] ? 'selected' : '',
  });
}
$INDEX->param("Taxa" => \@taxalist);

## タグ検索
my $tag_query = decode('utf8', $::in{'tag'});
if($tag_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){15}[^<]*? \Q$tag_query\E / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = decode('utf8', $::in{'name'});
if($name_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){4}[^<]*?\Q$name_query\E/i } @list; }
$INDEX->param(name => $name_query);

## レベル検索
my $lv_min_query = $::in{'lv-min'};
my $lv_max_query = $::in{'lv-max'};
if($lv_min_query) { @list = grep { (split(/<>/))[7] >= $lv_min_query } @list; }
if($lv_max_query) { @list = grep { (split(/<>/))[7] <= $lv_max_query } @list; }
$INDEX->param(lvMin => $lv_min_query);
$INDEX->param(lvMax => $lv_max_query);
if   ($lv_min_query eq $lv_max_query){ $INDEX->param(level => $lv_min_query); }
elsif($lv_min_query || $lv_max_query){ $INDEX->param(level => $lv_min_query.'～'.$lv_max_query); }

### ソート --------------------------------------------------
#if   ($sort eq 'name')  { my @tmp = map { (split /<>/)[4] } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
#elsif($sort eq 'author'){ my @tmp = map { (split /<>/)[5] } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
#elsif($sort eq 'date')  { my @tmp = map { (split /<>/)[3] } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
unless($index_mode && $set::list_maxline){
  my @tmp = map { (split /<>/)[7] } @list; @list = @list[sort {$tmp[$a] <=> $tmp[$b]} 0 .. $#tmp];
}

### リストを回す --------------------------------------------------
my %count;
my %grouplist;
my $page = $::in{'page'} ? $::in{'page'} : 1;
my $pagestart = $page * $set::pagemax - $set::pagemax;
my $pageend   = $page * $set::pagemax - 1;
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $author, $taxa, $lv,
    $intellect, $perception, $disposition, $sin, $initiative, $weakness,
    $image, $tag, $hide
  ) = (split /<>/, $_)[0..16];
  
  #グループ
  $taxa = '未分類' if (!$taxa);
  
  #カウント
  $count{$taxa}++;

  #表示域以外は弾く
  if (
    ( $index_mode && $count{$taxa} > $set::list_maxline && $set::list_maxline) || #TOPページ
    ( !$::in{'taxa'} && $mode ne 'mylist' && $count{$taxa} > $set::list_maxline && $set::list_maxline) || #検索結果（分類指定なし／マイリストでもなし）
    (!$index_mode && $set::pagemax && ($count{$taxa} < $pagestart || $count{$taxa} > $pageend)) #それ以外
  ){
    next;
  }
  
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
  next if !$count{$name};
  
  ## ページネーション
  my $navbar;
  if($set::pagemax && !$index_mode && $::in{'taxa'}){
    my $lastpage = ceil($count{$name} / $set::pagemax);
    foreach(1 .. $lastpage){
      if($_ == $page){
        $navbar .= '<b>'.$_.'</b> ';
      }
      elsif(
        ($_ <= $page + 4 && $_ >= $page - 4) ||
        $_ == 1 ||
        $_ == $lastpage
      ){
        $navbar .= '<a href="./?type=m&group='.$::in{'group'}.'&'.$q_links.'&page='.$_.'&sort='.$::in{'sort'}.'">'.$_.'</a> '
      }
      else { $navbar .= '...' }
    }
    $navbar =~ s/\.{3,}/... /g;
  }
  $navbar = '<div class="navbar">'.$navbar.'</div>' if $navbar;

  ##
  push(@characterlists, {
    "URL" => uri_escape_utf8($name),
    "NAME" => $name,
    "NUM" => $count{$name},
    "Characters" => [@{$grouplist{$name}}],
    "NAV" => $navbar,
  });
}

$INDEX->param("qLinks" => $q_links);

$INDEX->param("Lists" => \@characterlists);


$INDEX->param("title" => $set::title);
$INDEX->param("ver" => $::ver);
$INDEX->param("coreDir" => $::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;