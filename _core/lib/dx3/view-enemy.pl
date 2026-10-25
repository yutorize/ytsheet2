################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
require $set::data_syndrome;

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'DoubleCross3Enemy',
  defaultPieceImage => "$::core_dir/skin/dx3/img/default.png",
  nameKeys => [qw/enemyName aka/],
  unescapeLinesKeys => [qw/freeNote/],
  unescapeSkipKeys  => [qw/stage/],
  convertViewMap    => [qw/freeNote/],
  updateSub => \&upgradeEnemyData,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{aka} = '';
    $pc->{enemyName} = noiseText(6,14);
    $pc->{group} = $pc->{stage} = $pc->{tags} = '';
  }

  $pc->{breed}       = noiseText(3);
  $pc->{syndrome1}   = noiseText(4,8);
  $pc->{syndrome2}   = noiseText(4,8);
  $pc->{syndrome3}   = noiseText(4,8);

  foreach my $name ('Body','Sense','Mind','Social'){
    $pc->{'sttTotal'.$name} = noiseText(1);
    $pc->{'sttBase' .$name} = noiseText(1);
    $pc->{'sttWorks'.$name} = noiseText(1);
    $pc->{'sttGrow' .$name} = noiseText(1);
    $pc->{'sttAdd'  .$name} = noiseText(1);
  }
  $pc->{maxHpTotal}      = noiseText(1,2);
  $pc->{initiativeTotal} = noiseText(1,2);
  $pc->{armorTotal}      = noiseText(1,2);
  $pc->{encroachTotal}   = noiseText(1,3);
  
  foreach my $name ('Melee','Ranged','RC','Negotiate','Dodge','Percept','Will','Procure'){
    $pc->{'skillTotal'.$name} = noiseText(1);
  }
  foreach my $name ('Ride','Art','Know','Info'){
    $pc->{'skill'.$name.'Num'} = 1;
    foreach my $num (1 .. $pc->{'skill'.$name.'Num'}){
      $pc->{'skill'.$name.$num.'Name'} = noiseText(4,8);
      $pc->{'skillTotal'.$name.$num} = noiseText(1);
    }
  }

  $pc->{effectNum} = int(rand 4) + 8;
  foreach(1..$pc->{effectNum}){
    $pc->{'effect'.$_.'Type'}     = '';
    $pc->{'effect'.$_.'Name'}     = noiseText(5,10);
    $pc->{'effect'.$_.'Lv'}       = noiseText(1);
    $pc->{'effect'.$_.'Timing'}   = noiseText(4,7);
    $pc->{'effect'.$_.'Skill'}    = noiseText(2,6);
    $pc->{'effect'.$_.'Dfclty'}   = noiseText(1,2);
    $pc->{'effect'.$_.'Target'}   = noiseText(2,5);
    $pc->{'effect'.$_.'Range'}    = noiseText(2,3);
    $pc->{'effect'.$_.'Encroach'} = noiseText(1);
    $pc->{'effect'.$_.'Restrict'} = noiseText(2,3);
    $pc->{'effect'.$_.'Note'}     = noiseText(10,20);
  }
  $pc->{comboNum} = int(rand 3) + 1;
  foreach(1..$pc->{comboNum}){
    $pc->{'combo'.$_.'Name'}     = noiseText(5,10);
    $pc->{'combo'.$_.'Combo'}    = noiseText(10,30);
    $pc->{'combo'.$_.'Timing'}   = noiseText(4,7);
    $pc->{'combo'.$_.'Skill'}    = noiseText(2,6);
    $pc->{'combo'.$_.'Dfclty'}   = noiseText(1,2);
    $pc->{'combo'.$_.'Target'}   = noiseText(2,5);
    $pc->{'combo'.$_.'Range'}    = noiseText(2,3);
    $pc->{'combo'.$_.'Encroach'} = noiseText(1);
    $pc->{'combo'.$_.'Note'}     = noiseText(10,20);
    foreach my $i (1..2){
      $pc->{'combo'.$_.'Condition'.$i} = noiseText(3,4);
      $pc->{'combo'.$_.'Dice'.$i}  = noiseText(1,3);
      $pc->{'combo'.$_.'Crit'.$i}  = noiseText(1,3);
      $pc->{'combo'.$_.'Atk'.$i}   = noiseText(1,3);
      $pc->{'combo'.$_.'Fixed'.$i} = noiseText(1,3);
    }
    foreach my $i (3..5){
      $pc->{'combo'.$_.'Condition'.$i} = '';
      $pc->{'combo'.$_.'Dice'.$i}  = '';
      $pc->{'combo'.$_.'Crit'.$i}  = '';
      $pc->{'combo'.$_.'Atk'.$i}   = '';
      $pc->{'combo'.$_.'Fixed'.$i} = '';
    }
  }
  $pc->{weaponNum} =
  $pc->{armorNum} =
  $pc->{vehicleNum} =
  $pc->{itemNum} = 0;

  $pc->{freeNote} = '';
}

### 簡易表示 --------------------------------------------------
if($::in{simple}){ $SHEET->param(simpleMode => 1); }

### ステージ --------------------------------------------------
if($pc{stage} =~ /クロウリングケイオス/){ $SHEET->param(ccOn => 1); }

### ワークス --------------------------------------------------
$SHEET->param(isFH => $pc{works} =~ /[FＦ][HＨ]/i);

### ブリード --------------------------------------------------
my $breedPrefix = ($pc{breed} ? $pc{breed} : $pc{syndrome3} ? 'トライ' : $pc{syndrome2} ? 'クロス' : $pc{syndrome1} ? 'ピュア' : '');
$SHEET->param(breed => isNoiseText(removeTags $breedPrefix) ? $breedPrefix : $breedPrefix ? "$breedPrefix<span class=\"shorten\">ブリード</span>" : '');

### 能力値 --------------------------------------------------
$SHEET->param('sttWorks'.ucfirst($pc{sttWorks}) => 1);
foreach my $name ('Body','Sense','Mind','Social') {
  $SHEET->param('sttBaseBreakdown'.$name => $pc{syndrome2} ? "$pc{'sttSyn1'.$name}＋$pc{'sttSyn2'.$name}" : "$pc{'sttSyn1'.$name}×2");
}

### 技能 --------------------------------------------------
foreach my $name ('Melee','Ranged','RC','Negotiate','Dodge','Percept','Will','Procure'){
  $SHEET->param('skillTotal'.$name => ($pc{'skillAdd'.$name} ? "<span class=\"small\">+$pc{'skillAdd'.$name}=</span>" : '').$pc{'skillTotal'.$name});
}
my @skills;
my @skillRide;
my @skillArt;
my @skillKnow;
my @skillInfo;
foreach (1 .. max($pc{skillRideNum},$pc{skillArtNum},$pc{skillKnowNum},$pc{skillInfoNum})){
  next if (
    !$pc{'skillRide'.$_.'Name'} && !$pc{'skillArt' .$_.'Name'} && !$pc{'skillKnow'.$_.'Name'} && !$pc{'skillInfo'.$_.'Name'}
    && !$pc{'skillTotalRide'.$_} && !$pc{'skillTotalArt'.$_} && !$pc{'skillTotalKnow'.$_} && !$pc{'skillTotalInfo'.$_}
  );
  push(@skills, {
    RIDE => $pc{'skillRide'.$_.'Name'}, RIDELV => $pc{'skillTotalRide'.$_},
    ART  => $pc{'skillArt' .$_.'Name'}, ARTLV  => $pc{'skillTotalArt' .$_},
    KNOW => $pc{'skillKnow'.$_.'Name'}, KNOWLV => $pc{'skillTotalKnow'.$_},
    INFO => $pc{'skillInfo'.$_.'Name'}, INFOLV => $pc{'skillTotalInfo'.$_},
  });
  push(@skillRide, { NAME => $pc{'skillRide'.$_.'Name'}, LV => $pc{'skillTotalRide'.$_} }) if $pc{'skillRide'.$_.'Name'};
  push(@skillArt , { NAME => $pc{'skillArt' .$_.'Name'}, LV => $pc{'skillTotalArt' .$_} }) if $pc{'skillArt' .$_.'Name'};
  push(@skillKnow, { NAME => $pc{'skillKnow'.$_.'Name'}, LV => $pc{'skillTotalKnow'.$_} }) if $pc{'skillKnow'.$_.'Name'};
  push(@skillInfo, { NAME => $pc{'skillInfo'.$_.'Name'}, LV => $pc{'skillTotalInfo'.$_} }) if $pc{'skillInfo'.$_.'Name'};
}
$SHEET->param(Skills => \@skills);
$SHEET->param(SkillRide => \@skillRide);
$SHEET->param(SkillArt => \@skillArt);
$SHEET->param(SkillKnow => \@skillKnow);
$SHEET->param(SkillInfo => \@skillInfo);

### エフェクト --------------------------------------------------
my @effects;
my @simpleEffects;
my @simpleDLoises;
my @simpleELoises;
foreach (1 .. $pc{effectNum}){
  next if !existsRow "effect$_",'Name','Lv','Timing','Skill','Dfclty','Target','Range','Encroach','Restrict','Note','Exp';
  my $type = $pc{'effect'.$_.'Type'};
  push(@effects, {
    TYPE     => $type,
    NAME     => shrinkText(13,15,17,21,$pc{'effect'.$_.'Name'}),
    LV       => ($type =~ /^[de]lois$/ ? '―' : $pc{'effect'.$_.'Lv'}),
    TIMING   => ($type eq 'dlois' ? '―' : renderTiming($pc{'effect'.$_.'Timing'})),
    SKILL    => ($type eq 'dlois' ? '―' : renderSkill($pc{'effect'.$_.'Skill'})),
    DFCLTY   => ($type eq 'dlois' ? '―' : shrinkText(3,4,4,4,$pc{'effect'.$_.'Dfclty'})),
    TARGET   => ($type eq 'dlois' ? '―' : shrinkText(6,7,8,8,$pc{'effect'.$_.'Target'})),
    RANGE    => ($type eq 'dlois' ? '―' : $pc{'effect'.$_.'Range'}),
    ENCROACH => ($type =~ /^[de]lois$/ ? '―' : shrinkText(3,4,4,4,$pc{'effect'.$_.'Encroach'})),
    RESTRICT => ($type eq 'dlois' ? '―' : $type eq 'elois' ? '衝動：' : '').$pc{'effect'.$_.'Restrict'},
    NOTE     => $pc{'effect'.$_.'Note'},
  });
  if($type eq 'dlois'){
    unless(isBracketed($pc{'effect'.$_.'Name'})){ $pc{'effect'.$_.'Name'} = "「$pc{'effect'.$_.'Name'}」"; }
    push(@simpleDLoises, { NAME => $pc{'effect'.$_.'Name'} });
  }
  elsif($type eq 'elois'){
    unless(isBracketed($pc{'effect'.$_.'Name'})){ $pc{'effect'.$_.'Name'} = "「$pc{'effect'.$_.'Name'}」"; }
    push(@simpleELoises, { NAME => $pc{'effect'.$_.'Name'} });
  }
  else {
    unless(isBracketed($pc{'effect'.$_.'Name'})){ $pc{'effect'.$_.'Name'} = "《$pc{'effect'.$_.'Name'}》"; }
    push(@simpleEffects, { NAME => $pc{'effect'.$_.'Name'}, LV => $pc{'effect'.$_.'Lv'} });
  }
}
$SHEET->param(Effects => \@effects);
$SHEET->param(SimpleEffects => \@simpleEffects);
$SHEET->param(SimpleDLoises => \@simpleDLoises);
$SHEET->param(SimpleELoises => \@simpleELoises);
sub renderTiming {
  my $text = shift;
  $text =~ s#([^<])[／\/]#$1<hr class="dotted">#g;
  $text =~ s#(オート|メジャー|マイナー)(アクション)?#<span class="thin">$1<span class="shorten">アクション</span></span>#g;
  $text =~ s#リアク?(ション)?#<span class="thin">リア<span class="shorten">クション</span></span>#g;
  $text =~ s#(セットアップ|クリンナップ)(プロセス)?#<span class="thiner">$1<span class="shorten">プロセス</span></span>#g;
  return $text;
}
sub renderSkill {
  my $text = shift;
  $text =~ s#(〈.*?〉|【.*?】)#<span>$1</span>#g;
  $text =~ s#(シンドローム)#<span class="thin">$1</span>#g;
  return $text;
}
sub shrinkText {
  my $thin    = shift;
  my $thiner  = shift;
  my $thinest = shift;
  my $small   = shift;
  my $text = shift;
  my $check = $text;
  $check =~ s|<rp>(.+?)</rp>||g;
  $check =~ s|<rt>(.+?)</rt>||g;
  $check =~ s|<.+?>||g;
  if(length($check) >= $small) {
    return '<span class="thinest small">'.$text.'</span>';
  }
  if(length($check) >= $thinest) {
    return '<span class="thinest">'.$text.'</span>';
  }
  elsif(length($check) >= $thiner) {
    return '<span class="thiner">'.$text.'</span>';
  }
  elsif(length($check) >= $thin) {
    return '<span class="thin">'.$text.'</span>';
  }
  return $text;
}

### コンボ --------------------------------------------------
my @combos;
foreach (1 .. $pc{comboNum}){
  next if !existsRow "combo$_",'Name','Combo','Timing','Skill','Dfclty','Target','Range','Encroach','Note','Dice1','Crit1','Atk1','Fixed1';
  my $blankrow = 0;
  if(!$pc{'combo'.$_.'Condition2'}){ $blankrow++; }
  if(!$pc{'combo'.$_.'Condition3'}){ $blankrow++; }
  if(!$pc{'combo'.$_.'Condition4'}){ $blankrow++; }
  if(!$pc{'combo'.$_.'Condition5'}){ $blankrow++; }
  push(@combos, {
    NAME     => shrinkText(15,17,19,23,$pc{'combo'.$_.'Name'}),
    COMBO    => textCombo($pc{'combo'.$_.'Combo'}),
    TIMING   => renderTiming($pc{'combo'.$_.'Timing'}),
    SKILL    => textComboSkill($pc{'combo'.$_.'Skill'}),
    DFCLTY   => shrinkText(3,4,4,4,$pc{'combo'.$_.'Dfclty'}),
    TARGET   => shrinkText(6,7,8,8,$pc{'combo'.$_.'Target'}),
    RANGE    => $pc{'combo'.$_.'Range'},
    ENCROACH => shrinkText(3,4,4,4,$pc{'combo'.$_.'Encroach'}),
    NOTE     => $pc{'combo'.$_.'Note'},
    CONDITION1 => $pc{'combo'.$_.'Condition1'},
    DICE1      => $pc{'combo'.$_.'Dice1'},
    CRIT1      => $pc{'combo'.$_.'Crit1'},
    ATK1       => $pc{'combo'.$_.'Atk1'},
    FIXED1     => $pc{'combo'.$_.'Fixed1'},
    CONDITION2 => $pc{'combo'.$_.'Condition2'},
    DICE2      => $pc{'combo'.$_.'Dice2'},
    CRIT2      => $pc{'combo'.$_.'Crit2'},
    ATK2       => $pc{'combo'.$_.'Atk2'},
    FIXED2     => $pc{'combo'.$_.'Fixed2'},
    CONDITION3 => $pc{'combo'.$_.'Condition3'},
    DICE3      => $pc{'combo'.$_.'Dice3'},
    CRIT3      => $pc{'combo'.$_.'Crit3'},
    ATK3       => $pc{'combo'.$_.'Atk3'},
    FIXED3     => $pc{'combo'.$_.'Fixed3'},
    CONDITION4 => $pc{'combo'.$_.'Condition4'},
    DICE4      => $pc{'combo'.$_.'Dice4'},
    CRIT4      => $pc{'combo'.$_.'Crit4'},
    ATK4       => $pc{'combo'.$_.'Atk4'},
    FIXED4     => $pc{'combo'.$_.'Fixed4'},
    CONDITION5 => $pc{'combo'.$_.'Condition5'},
    DICE5      => $pc{'combo'.$_.'Dice5'},
    CRIT5      => $pc{'combo'.$_.'Crit5'},
    ATK5       => $pc{'combo'.$_.'Atk5'},
    FIXED5     => $pc{'combo'.$_.'Fixed5'},
    MANUAL     => $pc{'combo'.$_.'DBManual'},
    BLANKROW   => $blankrow,
  });
}
$SHEET->param(Combos => \@combos);
sub textCombo {
  my $text = shift;
  if($text =~ /《.*?》/){
    $text =~ s#(《.*?》)#<span class="thin">$1</span>#g
  }
  elsif($text){
    my @array = split(/[+＋]/, $text);
    $text = '<span class="thin">'.join('</span>＋<span class="thin">',@array).'</span>';
  }
  
  return $text;
}
sub textComboSkill {
  my $text = shift;
  $text =~ s#(.+)[:：](.+)#$1:<span>$2</span>#g;
  return $text;
}

### 武器 --------------------------------------------------
my @weapons;
foreach (1 .. $pc{weaponNum}){
  next if !existsRow "weapon$_",'Name','Stock','Exp','Skill','Acc','Atk','Guard','Range','Note';
  push(@weapons, {
    NAME  => shrinkText(12,13,14,15,$pc{'weapon'.$_.'Name'}),
    SKILL => renderSkill(shrinkText(4,5,6,7,formatSkillName($pc{'weapon'.$_.'Skill'}))),
    ACC   => $pc{'weapon'.$_.'Acc'},
    ATK   => $pc{'weapon'.$_.'Atk'},
    GUARD => $pc{'weapon'.$_.'Guard'},
    NOTE  => $pc{'weapon'.$_.'Note'},
  });
}
$SHEET->param(Weapons => \@weapons);

### 防具 --------------------------------------------------
my @armors;
foreach (1 .. $pc{armorNum}){
  next if !existsRow "armor$_",'Name','Initiative','Dodge','Armor','Note';
  push(@armors, {
    NAME       => shrinkText(12,13,14,15,$pc{'armor'.$_.'Name'}),
    INITIATIVE => $pc{'armor'.$_.'Initiative'},
    DODGE      => $pc{'armor'.$_.'Dodge'},
    ARMOR      => $pc{'armor'.$_.'Armor'},
    NOTE       => $pc{'armor'.$_.'Note'},
  });
}
$SHEET->param(Armors => \@armors);

### ヴィークル --------------------------------------------------
my @vehicles;
foreach (1 .. $pc{vehicleNum}){
  next if !existsRow "vehicle$_",'Name','Skill','Atk','Initiative','Armor','Dash','Note';
  push(@vehicles, {
    NAME       => shrinkText(12,13,14,15,$pc{'vehicle'.$_.'Name'}),
    SKILL      => renderSkill(shrinkText(4,5,6,7,formatSkillName($pc{'vehicle'.$_.'Skill'}))),
    INITIATIVE => $pc{'vehicle'.$_.'Initiative'},
    ATK        => $pc{'vehicle'.$_.'Atk'},
    ARMOR      => $pc{'vehicle'.$_.'Armor'},
    DASH       => $pc{'vehicle'.$_.'Dash'},
    NOTE       => $pc{'vehicle'.$_.'Note'},
  });
}
$SHEET->param(Vehicles => \@vehicles);

### アイテム --------------------------------------------------
my @items;
foreach (1 .. $pc{itemNum}){
  next if !existsRow "item$_",'Name','Skill','Note';
  push(@items, {
    NAME  => shrinkText(12,13,14,15,$pc{'item'.$_.'Name'}),
    TYPE  => shrinkText(5,6,7,8,$pc{'item'.$_.'Type'}),
    SKILL => renderSkill(shrinkText(4,5,6,7,formatSkillName($pc{'item'.$_.'Skill'}))),
    NOTE  => $pc{'item'.$_.'Note'},
  });
}
$SHEET->param(Items => \@items);

sub formatSkillName {
  if($_[0] && $_[0] !~ /^(?:―|解説参照)$/){
    return "〈$_[0]〉";
  }
  return $_[0];
}
sub textType {
  my $text = shift;
  my @texts = split(/[／\/]/, $text);
  foreach (@texts){ shrinkText(5,6,7,8,$_) }
  return join('<hr class="dotted">', @texts);
}

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "シンドローム:$pc{syndrome1} $pc{syndrome2} $pc{syndrome3}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
