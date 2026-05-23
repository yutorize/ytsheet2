################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
# なし

my $partnerMax = 2; #パートナーの最大人数

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'BloodPathPC',
  unescapeLinesKeys => [qw/freeNote freeHistory/],
  unescapeSkipRe    => qr/^(?:partner[12]Url|(?:p[12]_)?(?:image))/,
  updateSub      => \&data_update_chara,
  beforeUnescape => \&setPartnerData,
  partnerMax => $partnerMax,
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
  
    $pc->{factor}  = noiseText(2,3);
    $pc->{age}    = noiseText(1,2);
    $pc->{gender} = noiseText(1,2);
    
    $pc->{partner1Name} = noiseText(6,14);
    $pc->{partner2Name} = noiseText(6,14);
    
    $pc->{freeNote} = '';
    foreach(1..int(rand 3)+2){
      $pc->{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }
  
  $pc->{factorCore}  = noiseText(2);
  $pc->{factorStyle} = noiseText(2);
  $pc->{level} = noiseText(1,2);
  $pc->{statusMain1} = noiseText(1,2);
  $pc->{statusMain2} = noiseText(1,2);
  $pc->{endurance}  = noiseText(1,2);
  $pc->{initiative} = noiseText(1,2);
  $pc->{enduranceAdd}  = 0;
  $pc->{initiativeAdd} = 0;
  $pc->{enduranceGrow}  = 0;
  $pc->{initiativeGrow} = 0;
  
  $pc->{scarName} = noiseText(4,6);
  $pc->{scarNote} = noiseText(10,15);
  
  foreach(1..3){
    $pc->{'bloodarts'.$_.'Name'}     = noiseText(5,10);
    $pc->{'bloodarts'.$_.'Timing'}   = noiseText(3,4);
    $pc->{'bloodarts'.$_.'Target'}   = noiseText(2,5);
    $pc->{'bloodarts'.$_.'Note'}     = noiseText(10,15);
  }
  $pc->{artsNum} = int(rand 3) + 3;
  foreach('S',1..$pc->{artsNum}){
    $pc->{'arts'.$_.'Name'}     = noiseText(5,10);
    $pc->{'arts'.$_.'Timing'}   = noiseText(3,4);
    $pc->{'arts'.$_.'Target'}   = noiseText(2,5);
    $pc->{'arts'.$_.'Cost'}     = noiseText(2,5);
    $pc->{'arts'.$_.'Limited'}  = noiseText(2,4);
    $pc->{'arts'.$_.'Note'}     = noiseText(10,15);
  }
  $pc->{weaponNum} = $pc->{armorNum} = $pc->{itemNum} = $pc->{historyNum} = 0;
  $pc->{history0Exp} = noiseText(1,3);
}

### パートナーデータ取得 --------------------------------------------------
sub setPartnerData {
  my ($pc) = @_;
  setupPartnerDataCommon($pc,
    max => $partnerMax,
    updateSub => \&data_update_chara,
    onPartner => sub {
      my ($pc, $pr, $num) = @_;
      $pc->{"partner${num}Name"}     = $pr->{characterName};
      $pc->{"partner${num}NameRuby"} = $pr->{characterNameRuby};
      $pc->{"partner${num}Factor"}   = $pr->{factorCore}.'／'.$pr->{factorStyle};
      $pc->{"partner${num}Age"}      = ($pr->{factor} eq '吸血鬼' ? $pr->{ageApp}.'／' : '').$pr->{age};
      $pc->{"partner${num}Gender"}   = $pr->{gender};
      $pc->{"partner${num}Missing"}  = $pr->{missing};
      if($pr->{convertSource} eq 'キャラクターシート倉庫'){
        $pc->{"partner${num}Url"} = './?url='.$pc->{"partner${num}Url"};
      }
      elsif($num == 1){
        $pc->{fromPartner1SealPosition} = $pr->{'toPartner'.$pc->{partnerOrder}.'SealPosition'};
        $pc->{fromPartner1SealShape}    = $pr->{'toPartner'.$pc->{partnerOrder}.'SealShape'};
        $pc->{fromPartner1Emotion1}     = $pr->{'toPartner'.$pc->{partnerOrder}.'Emotion1'};
        $pc->{fromPartner1Emotion2}     = $pr->{'toPartner'.$pc->{partnerOrder}.'Emotion2'};
      }
      else {
        my $toNum = ($pc->{factor} eq '人間') ? 1 : ($pc->{factor} eq '吸血鬼') ? 2 : 0;
        $pc->{fromPartner2SealPosition} = $pr->{'toPartner'.$toNum.'SealPosition'};
        $pc->{fromPartner2SealShape}    = $pr->{'toPartner'.$toNum.'SealShape'};
        $pc->{fromPartner2Emotion1}     = $pr->{'toPartner'.$toNum.'Emotion1'};
        $pc->{fromPartner2Emotion2}     = $pr->{'toPartner'.$toNum.'Emotion2'};
      }
    },
    onForbidden => sub {
      my ($pc, $pr, $num) = @_;
      $pc->{"partner${num}Name"} = noiseText(6,14);
      $pc->{"partner${num}Factor"} = noiseTextTag(noiseText(2)).'／'.noiseTextTag(noiseText(2));
      if($pr->{forbidden} ne 'battle'){
        $pc->{"partner${num}Age"}     = noiseTextTag(noiseText(2));
        $pc->{"partner${num}Gender"}  = noiseTextTag(noiseText(2));
        $pc->{"partner${num}Missing"} = noiseTextTag(noiseText(2));
      }
    },
  );
}

### ファクター --------------------------------------------------
if   ($pc{factor} eq '人間'){
  $SHEET->param(typeH  => 1);
  $SHEET->param(head_statusMain1 => '<i class="spade">♠</i>技');
  $SHEET->param(head_statusMain2 => '<i class="club" >♣</i>情');
  $SHEET->param(enduranceFormula  => "($pc{statusMain1}×2+$pc{statusMain2})" . addNum($pc{enduranceAdd}) . addNum($pc{enduranceGrow}));
  $SHEET->param(initiativeFormula => "($pc{statusMain2}+10)" . addNum($pc{initiativeAdd}) . addNum($pc{initiativeGrow}));
  $SHEET->param(head_p1 => '血契'.($pc{partner2On}?'１':''));
  $SHEET->param(head_p2 => '血契２');
  $SHEET->param(class_p2 => 'seal');
}
elsif($pc{factor} eq '吸血鬼'){
  $SHEET->param(typeV  => 1);
  $SHEET->param(head_statusMain1 => '<i class="heart">♥</i>血');
  $SHEET->param(head_statusMain2 => '<i class="dia"  >♦</i>想');
  $SHEET->param(enduranceFormula  => "($pc{statusMain1}+20)" . addNum($pc{enduranceAdd}) . addNum($pc{enduranceGrow}));
  $SHEET->param(initiativeFormula => "($pc{statusMain2}+4)" . addNum($pc{initiativeAdd}) . addNum($pc{initiativeGrow}));
  $SHEET->param(head_p1 => '血契');
  $SHEET->param(head_p2 => '連血鬼');
  $SHEET->param(class_p2 => 'union');
}
else {
  $SHEET->param(head_p1 => '血契');
  $SHEET->param(head_p2 => noiseText(2));
}
### パートナー --------------------------------------------------

### 血威 --------------------------------------------------
my @bloodarts;
foreach (1 .. 3){
  next if !existsRow "bloodarts$_",'Name','Timing','Target','Note';
  push(@bloodarts, {
    NAME   => $pc{'bloodarts'.$_.'Name'},
    LV     => $pc{'bloodarts'.$_.'Lv'},
    TIMING => $pc{'bloodarts'.$_.'Timing'},
    TARGET => textTarget($pc{'bloodarts'.$_.'Target'}),
    NOTE   => $pc{'bloodarts'.$_.'Note'},
  });
}
$SHEET->param(Bloodarts => \@bloodarts);

### 特技 --------------------------------------------------
my @arts;
foreach (1 .. $pc{artsNum}){
  next if !existsRow "arts$_",'Name','Timing','Target','Cost','Limited','Note';
  push(@arts, {
    NAME    => $pc{'arts'.$_.'Name'},
    LV      => $pc{'arts'.$_.'Lv'},
    TIMING  => $pc{'arts'.$_.'Timing'},
    TARGET  => textTarget($pc{'arts'.$_.'Target'}),
    COST    => textCost($pc{'arts'.$_.'Cost'}),
    LIMITED => textCost($pc{'arts'.$_.'Limited'}),
    NOTE    => $pc{'arts'.$_.'Note'},
  });
}
if( $pc{scarName} && ($pc{artsSLv} || $pc{artsSLv} || $pc{artsSTiming} || $pc{artsSTarget} || $pc{artsSCost} || $pc{artsSLimited} || $pc{artsSNote}) ){
  push(@arts, {
    NAME    => '<b class="arts-scar-head">傷号:</b><span>'.$pc{scarName}.'</span>',
    LV      => $pc{artsSLv},
    TIMING  => $pc{artsSTiming},
    TARGET  => textTarget($pc{artsSTarget}),
    COST    => textCost($pc{artsSCost}),
    LIMITED => textCost($pc{artsSLimited}),
    NOTE    => $pc{artsSNote},
  });
}
$SHEET->param(Arts => \@arts);

sub textTarget {
  my $text = shift;
  $text =~ s#[(（](.+?)[)）]#<span>($1)</span>#;
  return $text;
}
sub textCost {
  my $text = shift;
  $text =~ s#^(.+?)((?:絵札)?[0-9０-９].*?)$#<span>$1</span><span>$2</span>#;
  return $text;
}

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
if($pc{endurancePreGrow }){ $pc{history0Grow} .= "耐久値+$pc{endurancePreGrow }" }
if($pc{history0Grow     }){ $pc{history0Grow} .= " " }
if($pc{initiativePreGrow}){ $pc{history0Grow} .= "先制値+$pc{initiativePreGrow}" }
if($pc{history0Grow}){
  $pc{history0Title} = 'キャラクター作成';
}
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Grow','Gm','Member','Note');
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
    NUM    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE   => $pc{'history'.$_.'Date'},
    TITLE  => $pc{'history'.$_.'Title'},
    GROW   => ($pc{'history'.$_.'Grow'} eq 'endurance'  ? '耐久値+5'
             : $pc{'history'.$_.'Grow'} eq 'initiative' ? '先制値+2'
             : $pc{'history'.$_.'Grow'}),
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "ファクター:$pc{factor}／$pc{factorCore}／$pc{factorStyle}　性別:$pc{gender}　年齢:$pc{age}　".($pc{factor} eq '吸血鬼' ? '欠落':'喪失').":$pc{missing}　所属:$pc{belong}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
