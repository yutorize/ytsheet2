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

### テンプレート読み込み ##################################################
#my $template = HTML::Template->new(filename => "template.html", utf8 => 1,);
my $INDEX;
open (my $FH, "<:utf8", $set::skin_tmpl ) or die "Couldn't open template file: $!\n";
$INDEX = HTML::Template->new( filehandle => *$FH , die_on_bad_params => 0, case_sensitive => 1);
close($FH);

$INDEX->param(modeList => 1);
$INDEX->param(LOGIN_ID => $LOGIN_ID);

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

## タグ検索
my $tag_query = Encode::decode('utf8', param('tag'));
if($tag_query) { @list = grep { (split(/<>/))[16] =~ / $tag_query / } @list; }
$INDEX->param(tag => $tag_query);

## リストを回す
foreach (@list) {
  my (
    $id, undef, undef, $updatetime, $name, $player, $group,
    $exp, $honor, $race, $gender, $age, $faith,
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
  else { $gender = '' }
  
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
    $class .= '<span>'.$_.$lv{$_}.'</span>' if $lv{$_};
  }
  
  if($fellow != 1) { $fellow = 0; }
  
  my @characters;
  push(@characters, {
    "ID" => $id,
    "NAME" => $name,
    "PLAYER" => $player,
    "GROUP" => $group,
    "EXP" => $exp,
    "LV" => $level,
    "CLASS" => $class,
    "HONOR" => $honor,
    "RACE" => $race,
    "GENDER" => $gender,
    "AGE" => $age,
    "FAITH" => $faith,
    "FELLOW" => $fellow,
    "HIDE" => $hide,
  });
  
  push(@{$grouplist{$group}}, @characters);
}

my %group_name;
my %group_text;
foreach (@set::groups){
  $group_name{@$_[0]} = @$_[2];
  $group_text{@$_[0]} = @$_[3];
}
my @characterlists; 
foreach (keys %grouplist){
  push(@characterlists, {
    "NAME" => $group_name{$_},
    "TEXT" => $group_text{$_},
    "Characters" => [@{$grouplist{$_}}],
  });
}

$INDEX->param(Lists => \@characterlists);


$INDEX->param(title => $set::title);
$INDEX->param(ver => $main::ver);

### 出力 ##################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;
print "<!-- @mylist -->";

1;