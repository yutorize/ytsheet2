################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;

my $mode = $::in{'mode'};
my $sort = $::in{'sort'};

$ENV{HTML_TEMPLATE_ROOT} = $::core_dir;

### データ読み込み ###################################################################################

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir."/skin/ar2e", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);


$INDEX->param(modeList => 1);
$INDEX->param(modeMylist => 1) if $mode eq 'mylist';
$INDEX->param(typeName => 'キャラ');

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(mode => $mode);

### データ処理 #######################################################################################
### クエリ --------------------------------------------------
my $index_mode;
if(!($mode eq 'mylist' || $::in{'tag'} || $::in{'group'} || $::in{'name'} || $::in{'player'} || $::in{'race'} || $::in{'exp-min'} || $::in{'exp-max'} || $::in{'class'} || $::in{'geis'} || $::in{'image'})){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
  $INDEX->param(simpleMode => 1) if $set::simplelist;
}
my @q_links;
foreach(
  'mode',
  'tag',
  #'group',
  'name',
  'player',
  'race',
  'exp-min',
  'exp-max',
  'class',
  'geis',
  'image',
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
  while(<$FH>){
    my @data = (split /<>/, $_)[0,1];
    if($data[1] eq "\[$LOGIN_ID\]"){ push(@mylist, $data[0]) }
  }
  close($FH);
}

## リスト取得
open (my $FH, "<", $set::listfile);
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
  && !$::in{'tag'}
){
  @list = grep { !(split(/<>/))[9] } @list;
}

## グループ
my %group_sort;
my %group_name;
my %group_text;
foreach (@set::groups){
  $group_sort{@$_[0]} = @$_[1];
  $group_name{@$_[0]} = @$_[2];
  $group_text{@$_[0]} = @$_[3];
}
$group_name{'all'} = 'すべて' if $::in{'group'} eq 'all';

## グループ検索
my $group_query = $::in{'group'};
if($group_query && $::in{'group'} ne 'all') {
  if($group_query eq $set::group_default){ @list = grep { (split(/<>/))[6] =~ /^$group_query$|^$/ } @list; }
  else { @list = grep { (split(/<>/))[6] eq $group_query } @list; }
}
$INDEX->param(group => $group_name{$group_query});

## タグ検索
my $tag_query = decode('utf8', $::in{'tag'});
if($tag_query) { @list = grep { (split(/<>/))[8] =~ / $tag_query / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = decode('utf8', $::in{'name'});
if($name_query) { @list = grep { (split(/<>/))[4] =~ /$name_query/ } @list; }
$INDEX->param(name => $name_query);

## PL名検索
my $pl_query = decode('utf8', $::in{'player'});
if($pl_query) { @list = grep { (split(/<>/))[5] =~ /$pl_query/ } @list; }
$INDEX->param(player => $pl_query);

## 種族検索
my $race_query = decode('utf8', $::in{'race'});
if($race_query) { @list = grep { (split(/<>/))[10] =~ /^$race_query/ } @list; }
$INDEX->param(race => $race_query);

## 経験点検索
my $exp_min_query = $::in{'exp-min'};
my $exp_max_query = $::in{'exp-max'};
if($exp_min_query) { @list = grep { (split(/<>/))[13] >= $exp_min_query } @list; }
if($exp_max_query) { @list = grep { (split(/<>/))[13] <= $exp_max_query } @list; }
$INDEX->param(expMin => $exp_min_query);
$INDEX->param(expMax => $exp_max_query);

## クラス検索
my @class_query = split('\s', decode('utf8', $::in{'class'}));
foreach my $q (@class_query) { @list = grep { (split(/<>/))[15] =~ /$q/ } @list; }
$INDEX->param(class => "@class_query");

## 誓約検索
my @geis_query = split('\s', decode('utf8', $::in{'geis'}));
foreach my $q (@geis_query) { @list = grep { (split(/<>/))[16] =~ /$q/ } @list; }
$INDEX->param(geis => "@geis_query");

## 画像フィルタ
if($::in{'image'} == 1) {
  @list = grep { (split(/<>/))[7] } @list;
  $INDEX->param(image => 1);
}
elsif($::in{'image'} eq 'N') {
  @list = grep { !(split(/<>/))[7] } @list;
  $INDEX->param(image => 1);
}

### リストを回す --------------------------------------------------
my %count; my %pl_flag;
my %grouplist;
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $player, $group, #0-6
    $image, $tag, $hide, #7-9
    $race, $gender, $age, #10-12
    $exp, $level, #13-14
    $classes, #15
    $geis, #16
  ) = (split /<>/, $_)[0..16];
  
  #グループ
  $group = $set::group_default if (!$group || !$group_name{$group});
  $group = 'all' if $::in{'group'} eq 'all';
  
  #カウント
  $count{'PC'}{$group}++;
  $count{'PL'}{$group}++ if !$pl_flag{$group}{$player};
  $pl_flag{$group}{$player} = 1;
  #最大表示制限
  next if ($index_mode && $count{'PC'}{$group} > $set::list_maxline && $set::list_maxline);
  
  #クラス
  (my $class_m, my $class_s, my $class_t) = (split '/', $classes);
  my @geises;
  push(@geises, "<div>$_</div>") foreach (split '/', $geis);
  
  #種族
  $race =~ s/（.*）|［.*］//;
  $race = "<div>$race</div>" if length($race) >= 5;
  
  #性別
  my $m_flag; my $f_flag;
  $gender =~ s/^(.+?)[\(（].*?[）\)]$/$1/;
  if($gender =~ /男|♂|雄|オス|爺|漢|(?<!fe)male|(?<!wo)man/i) { $m_flag = 1 }
  if($gender =~ /女|♀|雌|メス|婆|娘|female|woman/i)           { $f_flag = 1 }
  if($m_flag && $f_flag){ $gender = '？' }
  elsif($m_flag){ $gender = '♂' }
  elsif($f_flag){ $gender = '♀' }
  elsif($gender){ $gender = '？' }
  else { $gender = '？' }
  
  #年齢
  $age =~ s/^(.+?)[\(（].*?[）\)]$/$1/;
  $age =~ tr/０-９/0-9/;
  
  #ソート用データ
  my $sort_data;
  if    ($sort eq 'name'){ ($sort_data = $name) =~ s/^“.*”//; }
  #名前
  $name =~ s/^“(.*)”(.*)$/<span>“$1”<\/span><span>$2<\/span>/;
  
  #更新日時
  my ($min,$hour,$day,$mon,$year) = (localtime($updatetime))[1..5];
  $year += 1900; $mon++;
  $updatetime = sprintf("<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>",$year,$mon,$day,$hour,$min);
  
  #出力用配列へ
  my @characters;
  push(@characters, {
    "SORT" => $sort_data,
    "ID" => $id,
    "NAME" => $name,
    "PLAYER" => $player,
    "GROUP" => $group,
    "RACE" => $race,
    "GENDER" => $gender,
    "AGE" => $age,
    "EXP" => $exp,
    "LV" => $level,
    "MAIN" => $class_m,
    "SUPPORT" => $class_s,
    "TITLE" => $class_t,
    "GEIS" => join('',@geises),
    "DATE" => $updatetime,
    "HIDE" => $hide,
  });

  push(@{$grouplist{$group}}, @characters);
}

### 出力用配列 --------------------------------------------------
my @characterlists; 
my $page = $::in{'page'} ? $::in{'page'} : 1;
my $pagestart = $page * $set::pagemax - $set::pagemax;
my $pageend   = $page * $set::pagemax - 1;
foreach (sort {$group_sort{$a} <=> $group_sort{$b}} keys %grouplist){
  ## ソート
  if   ($sort eq 'name'){ @{$grouplist{$_}} = sort { $a->{'SORT'} cmp $b->{'SORT'} } @{$grouplist{$_}}; }
  elsif($sort eq 'pl')  { @{$grouplist{$_}} = sort { $a->{'PLAYER'} cmp $b->{'PLAYER'} } @{$grouplist{$_}}; }
  elsif($sort eq 'race'){ @{$grouplist{$_}} = sort { $a->{'RACE'} cmp $b->{'RACE'} } @{$grouplist{$_}}; }
  elsif($sort eq 'gender'){ @{$grouplist{$_}} = sort { $a->{'GENDER'} cmp $b->{'GENDER'} } @{$grouplist{$_}}; }
  elsif($sort eq 'lv')  { @{$grouplist{$_}} = sort { $b->{'LV'} <=> $a->{'LV'} } @{$grouplist{$_}}; }
  elsif($sort eq 'exp') { @{$grouplist{$_}} = sort { $b->{'EXP'} <=> $a->{'EXP'} } @{$grouplist{$_}}; }
  elsif($sort eq 'date'){ @{$grouplist{$_}} = sort { $b->{'DATE'} <=> $a->{'DATE'} } @{$grouplist{$_}}; }
  
  ## ページネーション
  my $navbar;
  if($set::pagemax && !$index_mode && $::in{'group'}){
    my $pageend = ($count{'PC'}{$_}-1 < $pageend) ? $count{'PC'}{$_}-1 : $pageend;
    @{$grouplist{$_}} = @{$grouplist{$_}}[$pagestart .. $pageend];
    foreach(1 .. ceil($count{'PC'}{$_} / $set::pagemax)){
      if($_ == $page){  $navbar .= '<b>'.$_.'</b> '}
      else { $navbar .= '<a href="./?group='.$::in{'group'}.'&'.$q_links.'&page='.$_.'&sort='.$::in{'sort'}.'">'.$_.'</a> ' }
    }
  }
  $navbar = '<div class="navbar">'.$navbar.'</div>' if $navbar;
  
  ##
  push(@characterlists, {
    "ID" => $_,
    "NAME" => $group_name{$_},
    "TEXT" => $group_text{$_},
    "NUM-PC" => $count{'PC'}{$_},
    "NUM-PL" => $count{'PL'}{$_},
    "Characters" => [@{$grouplist{$_}}],
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