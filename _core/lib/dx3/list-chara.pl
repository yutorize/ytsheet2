################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use Encode;
use HTML::Template;

my $LOGIN_ID = check;

my $mode = param('mode');
my $sort = param('sort');

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir],
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);


$INDEX->param(modeList => 1);

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(mode => $mode);

my $index_mode;
if(!($mode eq 'mylist' || param('tag') || param('group') || param('name') || param('exp-min') || param('exp-max') || param('syndrome') || param('works') || param('faith') || param('image'))){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
  $INDEX->param(simpleMode => 1) if $set::simplelist;
}
my @q_links;
foreach(
  'tag',
  #'group',
  'name',
  'race',
  'exp-min',
  'exp-max',
  'class',
  'faith',
  'image',
  'fellow',
  ){
  push( @q_links, $_.'='.uri_escape_utf8(Encode::decode('utf8', param($_))) ) if param($_);
}
my $q_links = join('&', @q_links);

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

## グループ検索
my $group_query = param('group');
if($group_query && param('group') ne 'all') {
  if($group_query eq $set::group_default){ @list = grep { (split(/<>/))[6] =~ /^$group_query$|^$/ } @list; }
  else { @list = grep { (split(/<>/))[6] eq $group_query } @list; }
  
}
$INDEX->param(group => $group_name{$group_query});

## タグ検索
my $tag_query = Encode::decode('utf8', param('tag'));
if($tag_query) { @list = grep { (split(/<>/))[17] =~ / $tag_query / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = Encode::decode('utf8', param('name'));
if($name_query) { @list = grep { (split(/<>/))[4] =~ /$name_query/ } @list; }
$INDEX->param(name => $name_query);

## 経験点検索
my $exp_min_query = param('exp-min');
my $exp_max_query = param('exp-max');
if($exp_min_query) { @list = grep { (split(/<>/))[7] >= $exp_min_query } @list; }
if($exp_max_query) { @list = grep { (split(/<>/))[7] <= $exp_max_query } @list; }
$INDEX->param(expMin => $exp_min_query);
$INDEX->param(expMax => $exp_max_query);

## ワークス検索
my $works_query = Encode::decode('utf8', param('works'));
if($works_query) { @list = grep { (split(/<>/))[12] =~ /$works_query/ } @list; }
$INDEX->param(works => $works_query);

## シンドローム検索
my @syndrome_query = split(/ |　/, Encode::decode('utf8', param('syndrome')));
foreach my $q (@syndrome_query) { @list = grep { (split(/<>/))[13] =~ /$q/ } @list; }
$INDEX->param(syndrome => "@syndrome_query");

## Dロイス検索
my @dlois_query = split(/ |　/, Encode::decode('utf8', param('dlois')));
foreach my $q (@dlois_query) { @list = grep { (split(/<>/))[14] =~ /$q/ } @list; }
$INDEX->param(dlois => "@dlois_query");

## 非表示除外
if (
     !($set::masterid && $set::masterid eq $LOGIN_ID)
  && !($mode eq 'mylist')
  && !$tag_query
){
  @list = grep { !(split(/<>/))[18] } @list;
}

## 画像フィルタ
if(param('image') == 1) {
  @list = grep { (split(/<>/))[16] } @list;
  $INDEX->param(image => 1);
}
elsif(param('image') eq 'N') {
  @list = grep { !(split(/<>/))[16] } @list;
  $INDEX->param(image => 1);
}

## リストを回す
my %count; my %pl_flag;
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $player, $group, #0-6
    $exp, $gender, $age, $sign, $blood, $works, #7-12
    $syndrome, $dlois, #13-14
    $session, $image, $tag, $hide #15-18
  ) = (split /<>/, $_)[0..18];
  
  if($mode eq 'mylist'){
    if(grep {$_ eq $id} @mylist){
    } else {
      next;
    }
  }
  
  $group = $set::group_default if !$group;
  
  my $m_flag; my $f_flag;
  if($gender =~ /男|♂|雄|オス|爺|漢/) { $m_flag = 1 }
  if($gender =~ /女|♀|雌|メス|婆|娘/) { $f_flag = 1 }
  if($m_flag && $f_flag){ $gender = '？' }
  elsif($m_flag){ $gender = '♂' }
  elsif($f_flag){ $gender = '♀' }
  elsif($gender){ $gender = '？' }
  else { $gender = '？' }
  
  $age =~ tr/０-９/0-9/;
  
  my @syndromes;
  push(@syndromes, "<span>$_</span>") foreach (split '/', $syndrome);
  my @dloises;
  push(@dloises, "<span>$_</span>") foreach (split '/', $dlois);
  
  my $sort_data;
  if    ($sort eq 'name'){ ($sort_data = $name) =~ s/^“.*”//; }
  
  $name =~ s/^“(.*)”(.*)/<span>“$1”<\/span><span>$2<\/span>/;
  
  $group = 'all' if param('group') eq 'all';
  
  $count{'PC'}{$group}++;
  $count{'PL'}{$group}++ if !$pl_flag{$group}{$player};
  $pl_flag{$group}{$player} = 1;
  
  if (!($index_mode && $count{'PC'}{$group} > $set::list_maxline && $set::list_maxline)){
    my ($min,$hour,$day,$mon,$year) = (localtime($updatetime))[1..5];
    $year += 1900; $mon++;
    $updatetime = sprintf("<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>",$year,$mon,$day,$hour,$min);
    
    
    my @characters;
    push(@characters, {
      "SORT" => $sort_data,
      "ID" => $id,
      "NAME" => $name,
      "PLAYER" => $player,
      "GROUP" => $group,
      "EXP" => $exp,
      "AGE" => $age,
      "GENDER" => $gender,
      "SIGN" => $sign,
      "BLOOD" => $blood,
      "WORKS" => $works,
      "SYNDROME" => join('',@syndromes),
      "DLOIS" => join(' ',@dloises),
      "DATE" => $updatetime,
      "HIDE" => $hide,
    });

    push(@{$grouplist{$group}}, @characters);
  }
}

my @characterlists; 
my $page = param('page') ? param('page') : 1;
my $pagestart = $page * $set::pagemax - $set::pagemax;
my $pageend   = $page * $set::pagemax - 1;
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
  
  my $navbar;
  if($set::pagemax && !$index_mode && param('group')){
    my $pageend = ($count{'PC'}{$_}-1 < $pageend) ? $count{'PC'}{$_}-1 : $pageend;
    @{$grouplist{$_}} = @{$grouplist{$_}}[$pagestart .. $pageend];
    foreach(1 .. ceil($count{'PC'}{$_} / $set::pagemax)){
      if($_ == $page){  $navbar .= '<b>'.$_.'</b> '}
      else { $navbar .= '<a href="./?group='.param('group').'&'.$q_links.'&page='.$_.'&sort='.param('sort').'">'.$_.'</a> ' }
    }
  }
  $navbar = '<div class="navbar">'.$navbar.'</div>' if $navbar;
  
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