################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_magi;

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'MamonoScramblePC',
  unescapeLinesKeys => [qw/freeNote freeHistory/],
  updateSub => \&data_update_chara,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{aka} = '';
    $pc->{characterName} = noiseText(6,14);
    $pc->{group} = $pc->{stage} = $pc->{tags} = '';
  
    $pc->{taxa}  = noiseText(2,6);
    $pc->{home}  = noiseText(2,6);
    $pc->{origin} = noiseText(2);
    $pc->{background} = noiseText(2,5);
    $pc->{clanEmotion} = noiseText(2,5);
    $pc->{address} = noiseText(5,7);
    
    $pc->{freeNote} = '';
    foreach(1..int(rand 3)+2){
      $pc->{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }
  
  $pc->{statusPhysical} = noiseText(1,2);
  $pc->{statusSpecial } = noiseText(1,2);
  $pc->{statusSocial  } = noiseText(1,2);

  foreach(1..4){
    $pc->{'magi'.$_.'Name'}   = noiseText(5,10);
    $pc->{'magi'.$_.'Timing'} = noiseText(3,4);
    $pc->{'magi'.$_.'Target'} = noiseText(2,5);
    $pc->{'magi'.$_.'Cond'}   = noiseText(3,4);
    $pc->{'magi'.$_.'Note'}   = noiseText(10,15);
  }
  $pc->{historyNum} = 0;
  $pc->{history0Exp} = noiseText(1,3);
}

### 特性 --------------------------------------------------
foreach my $type ('Physical','Special','Social'){
  my @attribute;
  foreach (1 .. $pc{attributeRows}){
    next if(
      $_ > 4
      && !$pc{'attributePhysical'.$_}
      && !$pc{'attributeSpecial'.$_}
      && !$pc{'attributeSocial'.$_}
    );
    $pc{'attribute'.$type.$_} &&= "《$pc{'attribute'.$type.$_}》";
    push(@attribute, { NAME => $pc{'attribute'.$type.$_} });
  }
  $SHEET->param('Attribute'.$type => \@attribute);
}

### マギ --------------------------------------------------
my @magi;
foreach (1 .. 4){
  #next if !existsRow "magi$_",'','Timing','Target','Cond','Note';
  my $magi = $pc{"magi$_"};
  my ($name, $baseName) = ($magi,'');
  if($pc{"magi${_}NC"}){
    $name = $pc{"magi${_}Name"};
    $baseName = "<b class=\"base-name\">《${magi}》</b> " if $magi ne 'その他';
  }
  push(@magi, {
    NAME   => ($name ? "《${name}》" : ''),
    TIMING => ($data::pcMagiData{$magi}{timing} // $pc{"magi${_}Timing"}),
    TARGET => ($data::pcMagiData{$magi}{target} // $pc{"magi${_}Target"}),
    COND   => ($data::pcMagiData{$magi}{cond  } // $pc{"magi${_}Cond"}),
    NOTE   => $baseName.($data::pcMagiData{$magi}{note} // $pc{"magi${_}Note"}),
  });
}
$SHEET->param(Magi => \@magi);

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
#$pc{history0Title} = 'キャラクター作成';
foreach (1 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Level','Gm','Member','Note');
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
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、]+/$1　/g;
  foreach my $mem (split(/　/,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  push(@history, {
    "NUM"    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    "DATE"   => $pc{'history'.$_.'Date'},
    "TITLE"  => $pc{'history'.$_.'Title'},
    "LEVEL"  => $pc{'history'.$_.'Level'},
    "GM"     => $pc{'history'.$_.'Gm'},
    "MEMBER" => $members,
    "NOTE"   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "強度:$pc{level}　分類:$pc{taxa}　出身地:$pc{home}　根源:$pc{origin}　経緯:$pc{background}　クランへの感情:$pc{clanEmotion}　住所:$pc{address}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
