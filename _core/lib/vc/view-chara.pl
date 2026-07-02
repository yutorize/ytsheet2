################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_class;

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'VisionConnectPC',
  unescapeLinesKeys => [qw/freeNote freeHistory/],
  updateSub => \&upgradeCharaData,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{aka} = '';
    $pc->{characterName} = noiseText(6,14);
    $pc->{group} = $pc->{areaTags} = $pc->{tags} = '';
    
    $pc->{age}    = noiseText(1,2);
    $pc->{gender} = noiseText(1,2);
    $pc->{eye}    = noiseText(1,6);
    $pc->{skin}   = noiseText(1,6);
    $pc->{hair}   = noiseText(1,6);
    $pc->{height} = noiseText(2,4);

    $pc->{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc->{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }

  $pc->{level} = noiseText(1);
  
  $pc->{race}  = noiseText(3,8);
  $pc->{class} = noiseText(3,8);
  $pc->{style1} = noiseText(3,8);
  $pc->{style2} = noiseText(3,8);
  $pc->{vitality} = noiseText(1);
  $pc->{technic}  = noiseText(1);
  $pc->{clever}   = noiseText(1);
  $pc->{carisma}  = noiseText(1);
  $pc->{hpMax}  = noiseText(1,2);
  $pc->{staminaAdd}  = 0;
  $pc->{staminaMax}  = noiseText(1);
  $pc->{staminaHalf}  = noiseText(1);

  foreach my $type ('Base','Race','Subtotal','Weapon','Head','Body','Acc1','Acc2','Other','Total'){
    $pc->{'battle'.$type.'Name'} = noiseText(3,10);
    foreach my $stt ('Acc','Spl','Eva','Atk','Det','Def','Mdf','Ini','Str'){
      $pc->{'battle'.$type.$stt} = noiseText(1);
    }
  }
  foreach my $num (1..2){
    $pc->{'speciality'.$num.'Name'} = noiseText(3,8);
    $pc->{'speciality'.$num.'Note'} = noiseText(8,22);
  }
  $pc->{goodsNum} = int(rand 4)+2;
  foreach my $num (1..$pc->{goodsNum}){
    $pc->{'goods'.$num.'Name'} = noiseText(3,8);
    $pc->{'goods'.$num.'Type'} = noiseText(2,5);
    $pc->{'goods'.$num.'Note'} = noiseText(8,22);
  }
  $pc->{itemNum} = int(rand 4)+1;
  foreach my $num (1..$pc->{itemNum}){
    $pc->{'item'.$num.'Name'} = noiseText(3,8);
    $pc->{'item'.$num.'Type'} = noiseText(2,5);
    $pc->{'item'.$num.'Note'} = noiseText(8,22);
  }

  $pc->{resultPoint} = noiseText(1,3);

  $pc->{historyNum} = 0;
  $pc->{history0Result}   = noiseText(1,3);
}

### グッズ --------------------------------------------------
my @goods;
foreach my $num (1 .. $pc{goodsNum}){
  next if !existsRow "goods$num",'Name','Type','Note';
  push(@goods, {
    NAME => textName($pc{'goods'.$num.'Name'}),
    TYPE => textType($pc{'goods'.$num.'Type'}),
    NOTE => $pc{'goods'.$num.'Note'},
  });
}
$SHEET->param(Goods => \@goods);

sub textName {
  my $text = shift;
  my $check = $text;
  $check =~ s|<rp>(.+?)</rp>||g;
  $check =~ s|<rt>(.+?)</rt>||g;
  $check =~ s|<.+?>||g;
  if   (length($check) >= 11) { return '<span class="thinest">'.$text.'</span>'; }
  elsif(length($check) >= 10) { return '<span class="thiner">'.$text.'</span>'; }
  elsif(length($check) >=  9) { return '<span class="thin">'.$text.'</span>'; }
  return $text;
}
sub textType {
  my $text = shift;
  if(length($text) >= 5) { return '<span class="thinest">'.$text.'</span>'; }
  elsif(length($text) >= 4) { return '<span class="thin">'.$text.'</span>'; }
  return $text;
}

### アイテム --------------------------------------------------
my @items;
foreach my $num (1 .. $pc{itemNum}){
  next if !existsRow "item$num",'Name','Type','Lv','Note';
  push(@items, {
    NAME => $pc{'item'.$num.'Name'},
    TYPE => textType($pc{'item'.$num.'Type'}),
    LV   => $pc{'item'.$num.'Lv'},
    NOTE => $pc{'item'.$num.'Note'},
  });
}
$SHEET->param(Items => \@items);
### 戦闘値 --------------------------------------------------
if(!$pc{forbidden}){
  foreach my $stt ('Acc','Spl','Eva','Atk','Det','Def','Mdf','Ini','Str'){
    foreach my $type ('Race','Weapon','Head','Body','Acc1','Acc2','Other'){
      $pc{'battle'.$type.$stt} &&= addNum $pc{'battle'.$type.$stt};
    }
  }
}
my @armaments;
foreach (
  ['Weapon','武器'],
  ['Head'  ,'頭防具'],
  ['Body'  ,'胴防具'],
  ['Acc1'  ,'装飾品'],
  ['Acc2'  ,'装飾品'],
){
  my $type = @{$_}[0];
  my $head = @{$_}[1];
  push(@armaments, {
    HEAD => $head,
    NAME => $pc{'battle'.$type.'Name'},
    ACC  => $pc{'battle'.$type.'Acc'},
    SPL  => $pc{'battle'.$type.'Spl'},
    EVA  => $pc{'battle'.$type.'Eva'},
    ATK  => $pc{'battle'.$type.'Atk'},
    DET  => $pc{'battle'.$type.'Det'},
    DEF  => $pc{'battle'.$type.'Def'},
    MDF  => $pc{'battle'.$type.'Mdf'},
    INI  => $pc{'battle'.$type.'Ini'},
    STR  => $pc{'battle'.$type.'Str'},
  });
}
$SHEET->param(Armaments => \@armaments);
### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = 'キャラクター作成';
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Result','Gm','Member','Note');
  $h_num++ if $pc{'history'.$_.'Gm'};
  if ($set::log_dir && $pc{'history'.$_.'Date'} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
    my $room = $1;
    (my $date = $pc{'history'.$_.'Date'}) =~ y#\-\/##d;
    $pc{'history'.$_.'Date'} = "<a href=\"$set::log_dir$date$room.html\">$pc{'history'.$_.'Date'}<\/a>";
  }
  if ($set::sessionlist && $pc{'history'.$_.'Title'} =~ s/^#([0-9]+)//){
    $pc{'history'.$_.'Title'} = "<a href=\"$set::sessionlist?num=$1\" data-num=\"$1\">$pc{'history'.$_.'Title'}<\/a>";
  }
  my $members;
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、 ]+/$1　/g;
  foreach my $mem (split(/　/,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  $pc{'history'.$_.'Money'} = formatHistoryFigures($pc{'history'.$_.'Money'});
  push(@history, {
    NUM    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE   => $pc{'history'.$_.'Date'},
    TITLE  => $pc{'history'.$_.'Title'},
    RESULT => $pc{'history'.$_.'Result'},
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);
$SHEET->param(historyExpTotal   => commify $pc{historyExpTotal}   );
$SHEET->param(payment           => commify $pc{payment}           );
$SHEET->param(historyMoneyTotal => commify $pc{historyMoneyTotal} );

### 携帯品 --------------------------------------------------
$pc{items} =~ s/[@＠]\[\s*?((?:[\+\-\*\/]?[0-9]+)+)\s*?\]/<i class="weight">$1<\/i>/g;
$SHEET->param(items => $pc{items});

### ゴールド --------------------------------------------------
if($pc{money} =~ /^(?:自動|auto)$/i){
  $SHEET->param(money => $pc{moneyTotal});
}
#if($pc{deposit} =~ /^(?:自動|auto)$/i){
#  $SHEET->param(deposit => $pc{depositTotal}.' G ／ '.$pc{debtTotal});
#}
$pc{cashbook} =~ s/(:(?:\:|&lt;|&gt;))((?:[\+\-\*\/]?[0-9]+)+)/$1.cashCheck($2)/eg;
  $SHEET->param(cashbook => $pc{cashbook});
sub cashCheck(){
  my $text = shift;
  my $num = s_eval($text);
  if   ($num > 0) { return '<b class="cash plus">'.$text.'</b>'; }
  elsif($num < 0) { return '<b class="cash minus">'.$text.'</b>'; }
  else { return '<b class="cash">'.$text.'</b>'; }
}

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "種族:$pc{race}　クラス:$pc{class}　スタイル:$pc{style1}／$pc{style2}　レベル:$pc{level}　外見:$pc{gender}／$pc{age}／$pc{height}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
