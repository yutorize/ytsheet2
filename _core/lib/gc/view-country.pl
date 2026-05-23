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
  nameKeys          => [qw/countryName/],
  unescapeLinesKeys => [qw/freeNote freeHistory/],
  unescapeSkipRe    => qr/^image|URL$/,
  convertViewMap    => [qw/freeNote freeHistory/],
  #updateSub => \&data_update_country,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{countryName} = noiseText(6,14);
    $pc->{group} = $pc->{areaTags} = $pc->{tags} = '';

    $pc->{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc->{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }

  $pc->{historyNum} = 0;
  $pc->{history0Result}   = noiseText(1,3);
}

### 国特徴 --------------------------------------------------
{
  my @row;
  foreach (1..$pc{characteristicNum}){
    next if (!existsRow "characteristic${_}",'Name','Food','Tech','Horse','Mineral','Forest','Funds','Note');
    push(@row, {
      NAME   => $pc{"characteristic${_}Name"},
      FOOD   => $pc{"characteristic${_}Food"},
      TECH   => $pc{"characteristic${_}Tech"},
      HORSE  => $pc{"characteristic${_}Horse"},
      MINERAL=> $pc{"characteristic${_}Mineral"},
      FOREST => $pc{"characteristic${_}Forest"},
      FUNDS  => $pc{"characteristic${_}Funds"},
      NOTE   => $pc{"characteristic${_}Note"},
    });
  }
  $SHEET->param(Characteristics => \@row);
}
### メンバー --------------------------------------------------
{
  my @row;
  foreach (1..$pc{memberNum}){
    next if (!existsRow "member${_}",'Name','Class','Style','Note');
    my $name = $pc{"member${_}Name"};
    if($pc{"member${_}URL"}){ $name = '<a href="'.$pc{"member${_}URL"}.'">'.$name.'</a>' }
    push(@row, {
      NAME  => $name,
      CLASS => $pc{"member${_}Class"},
      STYLE => $pc{"member${_}Style"},
      NOTE  => $pc{"member${_}Note"},
    });
  }
  $SHEET->param(Members => \@row);
}
### アカデミーサポート --------------------------------------------------
{
  my @row;
  foreach (1..$pc{academySupportNum}){
    next if (!existsRow "academySupport${_}",'Name','Class','Style','Cost','Note');
    push(@row, {
      NAME   => $pc{"academySupport${_}Name"},
      LV     => $pc{"academySupport${_}Lv"},
      TIMING => $pc{"academySupport${_}Timing"},
      TARGET => $pc{"academySupport${_}Target"},
      COST   => $pc{"academySupport${_}Cost"},
      NOTE   => $pc{"academySupport${_}Note"},
    });
  }
  $SHEET->param(AcademySupports => \@row);
}
### アーティファクト --------------------------------------------------
{
  my @row;
  foreach (1..$pc{artifactNum}){
    next if (!existsRow "artifact${_}",'Name','Class','Style','Cost','Note');
    push(@row, {
      NAME    => $pc{"artifact${_}Name"},
      TIMING  => $pc{"artifact${_}Timing"},
      TARGET  => $pc{"artifact${_}Target"},
      LV      => $pc{"artifact${_}Lv"},
      COST    => $pc{"artifact${_}Cost"},
      QUANTITY=> $pc{"artifact${_}Quantity"} || 0,
      NOTE    => $pc{"artifact${_}Note"},
    });
  }
  $SHEET->param(Artifacts => \@row);
}
### 部隊 --------------------------------------------------
{
  my @row;
  foreach (1..$pc{forceNum}){
    next if (!existsRow "force${_}",'Type','Lv','CostFood','CostTech','CostHorse','CostMineral','CostForest','CostFunds','Note');
    push(@row, {
      TYPE   => $pc{"force${_}Type"},
      LV     => $pc{"force${_}Lv"},
      FOOD   => $pc{"force${_}CostFood"},
      TECH   => $pc{"force${_}CostTech"},
      HORSE  => $pc{"force${_}CostHorse"},
      MINERAL=> $pc{"force${_}CostMineral"},
      FOREST => $pc{"force${_}CostForest"},
      FUNDS  => $pc{"force${_}CostFunds"},
      NOTE   => $pc{"force${_}Note"},
    });
  }
  $SHEET->param(Forces => \@row);
}

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = "シート作成（爵位：$pc{makePeerage}）";
$pc{history0Counts} = $set::peerageRank{$pc{makePeerage}}{counts};
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Counts','Gm','Member','Note');
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
    COUNTS => $pc{'history'.$_.'Counts'},
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);
$SHEET->param(historyCountsTotal   => commify $pc{countsTotal}   );

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "レベル:$pc{level}　爵位:$pc{peerage}　ロード:$pc{lordName}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
