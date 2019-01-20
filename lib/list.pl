################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";
use Encode;
use HTML::Template;

my $LOGIN_ID = check;

my $mode = param('mode');
my $sort = param('sort');

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);


$INDEX->param(modeList => 1);

$INDEX->param(LOGIN_ID => $LOGIN_ID);

$INDEX->param(mode => $mode);

my $index_mode;
if(!($mode eq 'mylist' || param('tag') || param('group') || param('name') || param('image'))){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
}

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

## ファイル読み込み
my %grouplist;
open (my $FH, "<", $set::listfile);
my @list = sort { (split(/<>/,$b))[3] <=> (split(/<>/,$a))[3] } <$FH>;
close($FH);

## グループ
my %group_sort;
my %group_name;
my %group_text;
foreach (@set::groups){
  $group_sort{@$_[0]} = @$_[1];
  $group_name{@$_[0]} = @$_[2];
  $group_text{@$_[0]} = @$_[3];
}
$group_name{'all'} = 'すべて' if param('group') eq 'all';

## ランク
my %rank_sort;
foreach (@set::adventurer_rank){
  $rank_sort{@$_[0]} = @$_[1];
}
$rank_sort{''} = -1;

## グループ検索
my $group_query = param('group');
if($group_query && param('group') ne 'all') {
  if($group_query eq $set::group_default){ @list = grep { (split(/<>/))[6] =~ /^$group_query$|^$/ } @list; }
  else { @list = grep { (split(/<>/))[6] eq $group_query } @list; }
  
}
$INDEX->param(group => $group_name{$group_query});

## タグ検索
my $tag_query = Encode::decode('utf8', param('tag'));
if($tag_query) { @list = grep { (split(/<>/))[16] =~ / $tag_query / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = Encode::decode('utf8', param('name'));
if($name_query) { @list = grep { (split(/<>/))[4] =~ /$name_query/ } @list; }
$INDEX->param(name => $name_query);

## 画像フィルタ
if(param('image') == 1) { @list = grep { (split(/<>/))[15] } @list; }

## リストを回す
my %count; my %pl_flag;
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $player, $group,
    $exp, $rank, $race, $gender, $age, $faith,
    $classes, $session, $image, $tag, $hide, $fellow
  ) = (split /<>/, $_)[0..18];
  
  if($mode eq 'mylist'){
    if(grep {$_ eq $id} @mylist){
    } else {
      next;
    }
  }
  
  if (
       !($set::masterid && $set::masterid eq $LOGIN_ID)
    && !($mode eq 'mylist')
    && !$tag_query
  ){
    next if $hide;
  }
  
  $group = $set::group_default if !$group;
  
  $race =~ s/（.*）//;
  $race = "<div>$race</div>" if length($race) >= 5;
  
  my $m_flag; my $f_flag;
  foreach('男','♂','雄','オス','爺','漢') { $m_flag = 1 if $gender =~ /$_/; }
  foreach('女','♀','雌','メス','婆','娘') { $f_flag = 1 if $gender =~ /$_/; }
  if($m_flag && $f_flag){ $gender = '？' }
  elsif($m_flag){ $gender = '♂' }
  elsif($f_flag){ $gender = '♀' }
  elsif($gender){ $gender = '？' }
  else { $gender = '？' }
  
  $age =~ tr/０-９/0-9/;
  
  my @levels = (split /\//, $classes);
  my $level = max(@levels);
  my @class_name = (
    'ファイター',
    'グラップラー',
    'フェンサー',
    'シューター',
    'ソーサラー',
    'コンジャラー',
    'プリースト',
    'フェアリーテイマー',
    'マギテック',
    'スカウト',
    'レンジャー',
    'セージ',
    'エンハンサー',
    'バード',
    'ライダー',
    'アルケミスト',
    'ウォーリーダー',
    'ミスティック',
    'デーモンルーラー',
    'フィジカルマスター',
    'グリモワール',
    'アリストクラシー',
    'アーティザン'
  );
  my %lv;
  @lv{@class_name} = @levels;
  my $class;
  foreach (sort {$lv{$b} <=> $lv{$a}} keys %lv){
    $class .= $_.$lv{$_} if $lv{$_};
  }
  $class = class_color($class);
  
  if($fellow != 1) { $fellow = 0; }
  
  my ($min,$hour,$day,$mon,$year) = (localtime($updatetime))[1..5];
  $year += 1900; $mon++;
  $updatetime = sprintf("<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>",$year,$mon,$day,$hour,$min);
  
  my $sort_data;
  if    ($sort eq 'name'){ ($sort_data = $name) =~ s/^“.*”//; }
  elsif ($sort eq 'rank'){  $sort_data = $rank_sort{$rank}; }
  
  $name =~ s/^“(.*)”(.*)/<span>“$1”<\/span><span>$2<\/span>/;
  
  my @characters;
  push(@characters, {
    "SORT" => $sort_data,
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
  
  $group = 'all' if param('group') eq 'all';
  
  $count{'PC'}{$group}++;
  $count{'PL'}{$group}++ if !$pl_flag{$group}{$player};
  $pl_flag{$group}{$player} = 1;
  push(@{$grouplist{$group}}, @characters) if !($index_mode && $count{'PC'}{$group} > $set::list_maxline && $set::list_maxline);
}




my @characterlists; 
foreach (sort {$group_sort{$a} <=> $group_sort{$b}} keys %grouplist){
  ## ソート
  if   ($sort eq 'name'){ @{$grouplist{$_}} = sort { $a->{'SORT'} cmp $b->{'SORT'} } @{$grouplist{$_}}; }
  elsif($sort eq 'pl')  { @{$grouplist{$_}} = sort { $a->{'PLAYER'} cmp $b->{'PLAYER'} } @{$grouplist{$_}}; }
  elsif($sort eq 'race'){ @{$grouplist{$_}} = sort { $a->{'RACE'} cmp $b->{'RACE'} } @{$grouplist{$_}}; }
  elsif($sort eq 'gender'){ @{$grouplist{$_}} = sort { $a->{'GENDER'} cmp $b->{'GENDER'} } @{$grouplist{$_}}; }
  elsif($sort eq 'rank'){ @{$grouplist{$_}} = sort { $b->{'SORT'} <=> $a->{'SORT'} } @{$grouplist{$_}}; }
  elsif($sort eq 'lv')  { @{$grouplist{$_}} = sort { $b->{'LV'} <=> $a->{'LV'} } @{$grouplist{$_}}; }
  elsif($sort eq 'exp') { @{$grouplist{$_}} = sort { $b->{'EXP'} <=> $a->{'EXP'} } @{$grouplist{$_}}; }
  elsif($sort eq 'date'){ @{$grouplist{$_}} = sort { $b->{'DATE'} <=> $a->{'DATE'} } @{$grouplist{$_}}; }
  
  push(@characterlists, {
    "ID" => $_,
    "NAME" => $group_name{$_},
    "TEXT" => $group_text{$_},
    "NUM-PC" => $count{'PC'}{$_},
    "NUM-PL" => $count{'PL'}{$_},
    "Characters" => [@{$grouplist{$_}}],
  });
}

$INDEX->param(Lists => \@characterlists);


$INDEX->param(title => $set::title);
$INDEX->param(ver => $main::ver);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;