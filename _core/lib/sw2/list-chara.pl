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
require $set::data_class;

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
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
foreach (keys %::in) {
  $::in{$_} =~ s/</&lt;/g;
  $::in{$_} =~ s/>/&gt;/g;
}
if(!($mode eq 'mylist' || $::in{'tag'} || $::in{'group'} || $::in{'name'} || $::in{'player'} || $::in{'race'} || $::in{'exp-min'} || $::in{'exp-max'} || $::in{'class'} || $::in{'faith'} || $::in{'image'} || $::in{'fellow'})){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
  $INDEX->param(simpleList => 1) if $set::simplelist;
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
  'faith',
  'image',
  'fellow',
  ){
  push( @q_links, $_.'='.uri_escape_utf8(decode('utf8', param($_))) ) if param($_);
}
my $q_links = @q_links ? '&'.join('&', @q_links) : '';

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
if($set::simpleindex && $index_mode) { #グループ見出しのみ
  $INDEX->param(simpleIndex => 1);
}
else { #通常
  open (my $FH, "<", $set::listfile);
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
  @list = grep { $_ !~ /^(?:[^<]*?<>){17}[^<0]/ } @list;
}

## グループ検索
my $group_query = $::in{'group'};
my %groups = groupArrayToHash();
$groups{'all'}{'name'} = 'すべて' if $::in{'group'} eq 'all';
$INDEX->param(Groups => groupArrayToList $group_query);

if($group_query && $::in{'group'} ne 'all') {
  if($group_query eq $set::group_default){ @list = grep { $_ =~ /^(?:[^<]*?<>){6}(\Q$group_query\E)?</ } @list; }
  else { @list = grep { $_ =~ /^(?:[^<]*?<>){6}\Q$group_query\E</ } @list; }
}
$INDEX->param(group => $groups{$group_query}{'name'});

## タグ検索
my $tag_query = decode('utf8', $::in{'tag'});
if($tag_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){16}[^<]*? \Q$tag_query\E / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = decode('utf8', $::in{'name'});
if($name_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){4}[^<]*?\Q$name_query\E/i } @list; }
$INDEX->param(name => $name_query);

## PL名検索
my $pl_query = decode('utf8', $::in{'player'});
if($pl_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){5}[^<]*?\Q$pl_query\E/i } @list; }
$INDEX->param(player => $pl_query);

## 種族検索
my $race_query = decode('utf8', $::in{'race'});
if($race_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){9}\Q$race_query\E/ } @list; }
$INDEX->param(race => $race_query);

## 経験点検索
my $exp_min_query = $::in{'exp-min'};
my $exp_max_query = $::in{'exp-max'};
if($exp_min_query) { @list = grep { (split(/<>/))[7] >= $exp_min_query } @list; }
if($exp_max_query) { @list = grep { (split(/<>/))[7] <= $exp_max_query } @list; }
$INDEX->param(expMin => $exp_min_query);
$INDEX->param(expMax => $exp_max_query);
if   ($exp_min_query eq $exp_max_query){ $INDEX->param(exp => $exp_min_query); }
elsif($exp_min_query || $exp_max_query){ $INDEX->param(exp => $exp_min_query.'～'.$exp_max_query); }

## 技能検索
my @class_name = @data::class_list;
my @class_query = split('\s', decode('utf8', $::in{'class'}));
if(@class_query){
  my %num;
  my $i = 0;
  foreach (@class_name){ $num{$_} = $i; $i++; }
  foreach my $class (@class_query){
    my $op = ''; my $lv = '';
    (my $name = $class) =~ s/(>=?|<=?)?([0-9]+)$/$op = $1;$lv = $2;''/e;
    if($lv ne ''){
      if   ($op eq '>='){ @list = grep { (split '/' ,(split /<>/)[13])[$num{$name}] >= $lv } @list; }
      elsif($op eq '<='){ @list = grep { (split '/' ,(split /<>/)[13])[$num{$name}] <= $lv } @list; }
      elsif($op eq '>' ){ @list = grep { (split '/' ,(split /<>/)[13])[$num{$name}] >  $lv } @list; }
      elsif($op eq '<' ){ @list = grep { (split '/' ,(split /<>/)[13])[$num{$name}] <  $lv } @list; }
      else              { @list = grep { (split '/' ,(split /<>/)[13])[$num{$name}] == $lv } @list; }
    }
    else { @list = grep { (split '/' ,(split /<>/)[13])[$num{$name}] >= 1 } @list; }
  }
}
$INDEX->param(class => "@class_query");

## 信仰検索
my $faith_query = decode('utf8', $::in{'faith'});
if($faith_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){12}[^<]*?\Q$faith_query\E/ } @list; }
$INDEX->param(faith => $faith_query);

## ランク
my $rank_query = decode('utf8', $::in{'rank'});
my %rank_sort;
my @rank_list;
foreach (@set::adventurer_rank){
  $rank_sort{@$_[0]} = @$_[1];
  push(@rank_list, {
    "NAME" => @$_[0],
    "SELECTED" => $rank_query eq @$_[0] ? 'selected' : '',
  });
}
$rank_sort{''} = -1;
$INDEX->param(Ranks => \@rank_list);

if($rank_query eq 'none') {
  @list = grep { $_ =~ /^(?:[^<]*?<>){8}</ } @list;
  $INDEX->param(rankNoneSelected => "selected");
  $INDEX->param(rank => 'なし');
}
elsif($rank_query) {
  @list = grep { $_ =~ /^(?:[^<]*?<>){8}\Q$rank_query\E</ } @list;
  $INDEX->param(rank => $rank_query);
}

## 画像フィルタ
if($::in{'image'} == 1) {
  @list = grep { $_ =~ /^(?:[^<]*?<>){15}[^<0]/ } @list;
  $INDEX->param(image => 1);
}
elsif($::in{'image'} eq 'N') {
  @list = grep { $_ !~ /^(?:[^<]*?<>){15}[^<0]/ } @list;
  $INDEX->param(image => 1);
}

## フェローフィルタ
if($::in{'fellow'} == 1) {
  @list = grep {  $_ =~ /^(?:[^<]*?<>){18}[^<0]/ } @list;
  $INDEX->param(fellow => 1);
}
elsif($::in{'fellow'} eq 'N') {
  @list = grep { $_ !~ /^(?:[^<]*?<>){18}[^<0]/ } @list;
  $INDEX->param(fellow => 1);
}
### ソート --------------------------------------------------
if   ($sort eq 'name')  { my @tmp = map { sortName((split /<>/)[4]) } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'pl')    { my @tmp = map { (split /<>/)[5]           } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'rank')  { my @tmp = map { sortRank((split /<>/)[8]) } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
elsif($sort eq 'lv')    { my @tmp = map { sortLv((split /<>/)[13])  } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
elsif($sort eq 'exp')   { my @tmp = map { (split /<>/)[7]           } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
elsif($sort eq 'date')  { my @tmp = map { (split /<>/)[3]           } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }

sub sortName { $_[0] =~ s/^“.*”//; return $_[0]; }
sub sortRank { return $rank_sort{$_[0]}; }
sub sortLv   { my @levels = (split /\//, $_[0]); return max(@levels); }

### リストを回す --------------------------------------------------
my %count; my %pl_flag;
my %grouplist;
my $page = $::in{'page'} ? $::in{'page'} : 1;
my $pagestart = $page * $set::pagemax - $set::pagemax;
my $pageend   = $page * $set::pagemax - 1;
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $player, $group,
    $exp, $rank, $race, $gender, $age, $faith,
    $classes, $session, $image, $tag, $hide, $fellow
  ) = (split /<>/, $_)[0..18];
  
  #グループ
  $group = $set::group_default if (!$group || !$groups{$group});
  $group = 'all' if $::in{'group'} eq 'all';
  
  #カウント
  $count{'PC'}{$group}++;
  $count{'PL'}{$group}++ if !$pl_flag{$group}{$player};
  $pl_flag{$group}{$player} = 1;

  #表示域以外は弾く
  if (
    ( $index_mode && $count{'PC'}{$group} > $set::list_maxline && $set::list_maxline) || #TOPページ
    (!$index_mode && $set::pagemax && ($count{'PC'}{$group} < $pagestart || $count{'PC'}{$group} > $pageend)) #それ以外
  ){
    next;
  }

  #名前
  $name =~ s/^“(.*)”(.*)$/<span>“$1”<\/span><span>$2<\/span>/;
  
  ## シンプルリスト
  if($index_mode && $set::simplelist){
    #出力用配列へ
    my @characters;
    push(@characters, {
      "ID" => $id,
      "NAME" => $name,
      "PLAYER" => $player,
      "GROUP" => $group,
      "EXP" => $exp,
      "LV" => max((split /\//, $classes)),
      "RANK" => $rank,
      "HIDE" => $hide,
    });
    push(@{$grouplist{$group}}, @characters);
  }
  ## 通常リスト
  else {
    #技能レベル
    my @levels = (split /\//, $classes);
    my $level = max(@levels);
    my %lv;
    @lv{@class_name} = @levels;
    my $class;
    foreach (sort {$lv{$b} <=> $lv{$a}} keys %lv){
      $class .= $_.$lv{$_} if $lv{$_};
    }
    $class = class_color($class);
    
    #種族
    $race =~ s/（.*）|［.*］//;
    $race = "<div>$race</div>" if length($race) >= 5;
    
    #性別
    $gender = genderConvert($gender);
    
    #年齢
    $age =~ s/^(.+?)[\(（].*?[）\)]$/$1/;
    $age =~ tr/０-９/0-9/;
    
    #フェロー
    if($fellow != 1) { $fellow = 0; }
    
    #更新日時
    my ($min,$hour,$day,$mon,$year) = (localtime($updatetime))[1..5];
    $year += 1900; $mon++;
    $updatetime = sprintf("<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>",$year,$mon,$day,$hour,$min);

    #出力用配列へ
    my @characters;
    push(@characters, {
      "ID" => $id,
      "NAME" => $name,
      "PLAYER" => $player,
      "GROUP" => $group,
      "EXP" => $exp,
      "LV" => $level,
      "CLASS" => $class,
      "RACE" => $race,
      "GENDER" => $gender,
      "AGE" => $age,
      "FAITH" => $faith,
      "RANK" => $rank,
      "FELLOW" => $fellow,
      "DATE" => $updatetime,
      "HIDE" => $hide,
    });
    push(@{$grouplist{$group}}, @characters);
  }
}

### 出力用配列 --------------------------------------------------
my @characterlists;
foreach (sort {$groups{$a}{'sort'} <=> $groups{$b}{'sort'}} keys %grouplist){
  ## ページネーション
  my $navbar;
  if($set::pagemax && !$index_mode && $::in{'group'}){
    my $lastpage = ceil($count{'PC'}{$_} / $set::pagemax);
    foreach(1 .. $lastpage){
      if($_ == $page){
        $navbar .= '<b>'.$_.'</b> ';
      }
      elsif(
        ($_ <= $page + 4 && $_ >= $page - 4) ||
        $_ == 1 ||
        $_ == $lastpage
      ){
        $navbar .= '<a href="./?group='.$::in{'group'}.$q_links.'&page='.$_.'&sort='.$::in{'sort'}.'">'.$_.'</a> '
      }
      else { $navbar .= '...' }
    }
    $navbar =~ s/\.{3,}/... /g;
  }
  $navbar = '<div class="navbar">'.$navbar.'</div>' if $navbar;
  
  ##
  push(@characterlists, {
    "ID" => $_,
    "NAME" => $groups{$_}{'name'},
    "TEXT" => $groups{$_}{'text'},
    "NUM-PC" => $count{'PC'}{$_},
    "NUM-PL" => $count{'PL'}{$_},
    "Characters" => [@{$grouplist{$_}}],
    "NAV" => $navbar,
  });
}

$INDEX->param(qLinks => $q_links);

$INDEX->param(Lists => \@characterlists);


$INDEX->param(title => $set::title);
$INDEX->param(ver => $::ver);
$INDEX->param(coreDir => $::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;