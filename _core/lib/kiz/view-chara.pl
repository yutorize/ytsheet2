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
  generateType => 'KizunaBulletPC',
  unescapeLinesKeys => [qw/freeNote freeHistory/],
  unescapeSkipRe    => qr/^(?:partner[12]Url|(?:p[12]_)?(?:image))/,
  updateSub      => \&upgradeCharaData,
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
  
  $pc->{class}  = noiseText(4);
  $pc->{negaiOutside} = noiseText(2);
  $pc->{negaiInside}  = noiseText(2);
  $pc->{endurance} = noiseText(1,2);
  $pc->{operation} = noiseText(1,2);
  $pc->{enduranceAdd}  = 0;
  $pc->{operationAdd}  = 0;
  $pc->{enduranceGrow} = 0;
  $pc->{operationGrow} = 0;
  $pc->{enduranceFormula} = noiseText(5,7);
  $pc->{operationFormula} = noiseText(5,7);
  
  foreach(1..3){
    $pc->{'bloodarts'.$_.'Name'}     = noiseText(5,10);
    $pc->{'bloodarts'.$_.'Timing'}   = noiseText(3,4);
    $pc->{'bloodarts'.$_.'Target'}   = noiseText(2,5);
    $pc->{'bloodarts'.$_.'Note'}     = noiseText(10,15);
  }
  $pc->{kizuatoNum} = int(rand 3) + 1;
  foreach(1..$pc->{kizuatoNum}){
    $pc->{'kizuato'.$_.'Name'}     = noiseText(5,10);
    $pc->{'kizuato'.$_.'DramaTiming'}   = noiseText(3,4);
    $pc->{'kizuato'.$_.'DramaTarget'}   = noiseText(2,5);
    $pc->{'kizuato'.$_.'DramaHitogara'} = noiseText(4,8);
    $pc->{'kizuato'.$_.'DramaLimited'}  = noiseText(2,4);
    $pc->{'kizuato'.$_.'DramaNote'}     = noiseText(10,15);
    $pc->{'kizuato'.$_.'BattleTiming'}   = noiseText(3,4);
    $pc->{'kizuato'.$_.'BattleTarget'}   = noiseText(2,5);
    $pc->{'kizuato'.$_.'BattleCost'}     = noiseText(2,5);
    $pc->{'kizuato'.$_.'BattleLimited'}  = noiseText(2,4);
    $pc->{'kizuato'.$_.'BattleNote'}     = noiseText(10,15);
  }
  $pc->{historyNum} = 0;
  $pc->{history0Exp} = noiseText(1,3);
}

### パートナーデータ取得 --------------------------------------------------
sub setPartnerData {
  my ($pc) = @_;
  setupPartnerDataCommon($pc,
    max => $partnerMax,
    updateSub => \&upgradeCharaData,
    onPartner => sub {
      my ($pc, $pr, $num) = @_;
      $pc->{"partner${num}Name"}         = $pr->{characterName};
      $pc->{"partner${num}NameRuby"}     = $pr->{characterNameRuby};
      $pc->{"partner${num}Class"}        = $pr->{class};
      $pc->{"partner${num}Age"}          = $pr->{age};
      $pc->{"partner${num}Gender"}       = $pr->{gender};
      $pc->{"partner${num}NegaiOutside"} = $pr->{negaiOutside};
      $pc->{"partner${num}NegaiInside"}  = $pr->{negaiInside};
      if($num == 1){
        $pc->{fromPartner1MarkerPosition} = $pr->{'toPartner'.$pc->{partnerOrder}.'MarkerPosition'};
        $pc->{fromPartner1MarkerColor}    = $pr->{'toPartner'.$pc->{partnerOrder}.'MarkerColor'};
        $pc->{fromPartner1Emotion1}       = $pr->{'toPartner'.$pc->{partnerOrder}.'Emotion1'};
        $pc->{fromPartner1Emotion2}       = $pr->{'toPartner'.$pc->{partnerOrder}.'Emotion2'};
      }
      else {
        my $toNum = ($pc->{class} eq 'オーナー') ? 1 : ($pc->{class} eq 'ハウンド') ? 2 : 0;
        $pc->{fromPartner2MarkerPosition} = $pr->{'toPartner'.$toNum.'MarkerPosition'};
        $pc->{fromPartner2MarkerColor}    = $pr->{'toPartner'.$toNum.'MarkerColor'};
        $pc->{fromPartner2Emotion1}       = $pr->{'toPartner'.$toNum.'Emotion1'};
        $pc->{fromPartner2Emotion2}       = $pr->{'toPartner'.$toNum.'Emotion2'};
      }
    },
    onForbidden => sub {
      my ($pc, $pr, $num) = @_;
      $pc->{"partner${num}Name"}  = noiseText(6,14);
      if($pr->{forbidden} ne 'battle'){
        $pc->{"partner${num}Age"}          = noiseTextTag(noiseText(2));
        $pc->{"partner${num}Gender"}       = noiseTextTag(noiseText(2));
        $pc->{"partner${num}NegaiOutside"} = noiseTextTag(noiseText(2));
        $pc->{"partner${num}NegaiInside"}  = noiseTextTag(noiseText(2));
      }
    },
  );
}

### 種別 --------------------------------------------------
if($pc{makeType} eq 'gospel'){
  $SHEET->param(makeTypeGospel  => 1);
}
else {
  $SHEET->param(makeTypeNormal  => 1);
}
if   ($pc{class} eq 'オーナー'){
  $SHEET->param(classO  => 1);
  $SHEET->param(head_p1 => 'パートナー'.($pc{partner2On}?'１':''));
  $SHEET->param(head_p2 => 'パートナー２');
  $SHEET->param(class_p2 => 'marker');
}
elsif($pc{class} eq 'ハウンド'){
  $SHEET->param(classH  => 1);
  $SHEET->param(head_p1 => 'パートナー');
  $SHEET->param(head_p2 => 'アナザー');
  $SHEET->param(class_p2 => 'another');
}
else {
  $SHEET->param(head_p1 => 'パートナー');
  $SHEET->param(head_p2 => noiseText(2));
}

### 能力値 --------------------------------------------------
if(!$pc{forbiddenMode}){
  $SHEET->param(enduranceFormula => "$pc{enduranceType}+$pc{enduranceOutside}+$pc{enduranceInside}".(addNum $pc{enduranceAdd}).(addNum $pc{enduranceGrow}));
  $SHEET->param(operationFormula => "$pc{operationType}+$pc{operationOutside}+$pc{operationInside}".(addNum $pc{operationAdd}).(addNum $pc{operationGrow}));
}

### キズナ --------------------------------------------------
my @kizuna;
foreach (1 .. $pc{kizunaNum}){
  next if !existsRow "kizuna$_",'Name','Note','Hibi','Ware';
  push(@kizuna, {
    "NAME" => $pc{'kizuna'.$_.'Name'},
    "NOTE" => $pc{'kizuna'.$_.'Note'},
    "HIBI" => ($pc{'kizuna'.$_.'Hibi'}?'hibi':''),
    "WARE" => ($pc{'kizuna'.$_.'Ware'}?'ware':''),
  });
}
$SHEET->param(Kizuna => \@kizuna);

### 傷号 --------------------------------------------------
my @shougou;
foreach (1 .. 3){
  if($pc{'shougou'.$_}){
    push(@shougou, {
      "NUM"  => $_,
      "NAME" => "［$pc{'shougou'.$_}］",
    });
  }
  else {
    push(@shougou, {
      "NUM"  => '',
      "NAME" => '',
    });
  }
}
$SHEET->param(Shougou => \@shougou) if ($pc{shougou1} || $pc{shougou2} || $pc{shougou3});

### キズアト --------------------------------------------------
my @kizuato;
foreach (1 .. $pc{kizuatoNum}){
  next if !(existsRow "kizuato$_",'Name',
    'DramaTiming','DramaTarget','DramaHitogara','DramaLimited','DramaNote',
    'BattleTiming','BattleTarget','BattleCost','BattleLimited','BattleNote');
  push(@kizuato, {
    "NAME"     => $pc{'kizuato'.$_.'Name'},
    "D-TIMING"   => $pc{'kizuato'.$_.'DramaTiming'},
    "D-TARGET"   => textTarget($pc{'kizuato'.$_.'DramaTarget'}),
    "D-HITOGARA" => textHitogara($pc{'kizuato'.$_.'DramaHitogara'}),
    "D-LIMITED"  => $pc{'kizuato'.$_.'DramaLimited'},
    "D-NOTE"     => $pc{'kizuato'.$_.'DramaNote'},
    "B-TIMING"   => $pc{'kizuato'.$_.'BattleTiming'},
    "B-TARGET"   => textTarget($pc{'kizuato'.$_.'BattleTarget'}),
    "B-COST"     => $pc{'kizuato'.$_.'BattleCost'},
    "B-LIMITED"  => $pc{'kizuato'.$_.'BattleLimited'},
    "B-NOTE"     => $pc{'kizuato'.$_.'BattleNote'},
  });
}
$SHEET->param(Kizuato => \@kizuato);

sub textHitogara {
  my $text = shift;
  $text =~ s#[:：](.+?)$#：<span>$1</span>#;
  return $text;
}
sub textTarget {
  my $text = shift;
  $text =~ s#[(（](.+?)[)）]#<span>($1)</span>#;
  return $text;
}

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
#$pc{history0Title} = 'キャラクター作成';
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
    "NUM"    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    "DATE"   => $pc{'history'.$_.'Date'},
    "TITLE"  => $pc{'history'.$_.'Title'},
    "GROW"   => ($pc{'history'.$_.'Grow'} eq 'endurance' ? '耐久値+2'
               : $pc{'history'.$_.'Grow'} eq 'operation' ? '作戦力+1'
               : ''),
    "GM"     => $pc{'history'.$_.'Gm'},
    "MEMBER" => $members,
    "NOTE"   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "種別:$pc{class}　ネガイ:$pc{negaiOutside}／$pc{negaiInside}　性別:$pc{gender}　年齢:$pc{age}　所属:$pc{belong}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
