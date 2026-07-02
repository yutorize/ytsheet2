################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_syndrome;

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'DoubleCross3PC',
  unescapeLinesKeys => [qw/freeNote freeHistory/],
  unescapeSkipKeys  => [qw/stage/],
  convertViewMap    => [qw/freeNote/],
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
    $pc->{group} = $pc->{stage} = $pc->{tags} = '';
  
    $pc->{age}    = noiseText(1,2);
    $pc->{gender} = noiseText(1,2);
    $pc->{sign}   = noiseText(3);
    $pc->{height} = noiseText(2);
    $pc->{weight} = noiseText(2);
    $pc->{blood}  = noiseText(2,3);
    
    $pc->{cover} = noiseText(3,8);
    
    $pc->{freeNote} = '';
    foreach(1..int(rand 3)+2){
      $pc->{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }
  
  $pc->{works} = noiseText(3,8);
  
  $pc->{expUsedStatus} = noiseText(2);
  $pc->{expUsedSkill}  = noiseText(2);
  $pc->{expUsedEffect} = noiseText(2);
  $pc->{expUsedItem}   = noiseText(2);
  $pc->{expUsedMemory} = noiseText(2);
  $pc->{expUsed}       = noiseText(2);
  $pc->{expSpent}      = noiseText(2);
  $pc->{expRest}       = noiseText(2);
  $pc->{expTotal}      = noiseText(2);
  
  if($forbidden ne 'battle'){
    $pc->{lifepathOrigin}          = noiseText(3,5);
    $pc->{lifepathExperience}      = noiseText(3,5);
    $pc->{lifepathEncounter}       = noiseText(3,5);
    $pc->{lifepathOriginNote}      = noiseText(8,16);
    $pc->{lifepathExperienceNote}  = noiseText(8,16);
    $pc->{lifepathEncounterNote}   = noiseText(8,16);
  }
  $pc->{lifepathAwaken}          = noiseText(2);
  $pc->{lifepathImpulse}         = noiseText(2);
  $pc->{lifepathAwakenNote}      = noiseText(8,16);
  $pc->{lifepathImpulseNote}     = noiseText(8,16);
  $pc->{lifepathOtherNote}       = noiseText(8,16);
  $pc->{lifepathAwakenEncroach}  = noiseText(1);
  $pc->{lifepathImpulseEncroach} = noiseText(1);
  $pc->{lifepathOtherEncroach}   = noiseText(1);
  $pc->{baseEncroach} = noiseText(1,2);
  $pc->{lifepathUrgeCheck} = '';
  
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
  $pc->{moveTotal}       = noiseText(1,2);
  $pc->{dashTotal}       = noiseText(1,2);
  $pc->{stockTotal}      = noiseText(1,2);
  $pc->{savingTotal}     = noiseText(1,2);
  $pc->{maxHpAdd}      = '';
  $pc->{initiativeAdd} = '';
  $pc->{moveAdd}       = '';
  $pc->{dashAdd}       = '';
  $pc->{stockAdd}      = '';
  $pc->{savingAdd}     = '';
  
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
  
  foreach(1..7){
    $pc->{'lois'.$_.'Relation'} = noiseText(2,4);
    $pc->{'lois'.$_.'Name'}     = noiseText(3,10);
    $pc->{'lois'.$_.'Note'}     = noiseText(3,16);
    $pc->{'lois'.$_.'EmoPosi'}  = noiseText(2,3);
    $pc->{'lois'.$_.'EmoNega'}  = noiseText(2,3);
    $pc->{'lois'.$_.'EmoPosiCheck'} = $pc->{'lois'.$_.'EmoNegaCheck'} = $pc->{'lois'.$_.'Color'} = $pc->{'lois'.$_.'State'} = '';
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
    foreach my $i (3..4){
      $pc->{'combo'.$_.'Condition'.$i} = '';
      $pc->{'combo'.$_.'Dice'.$i}  = '';
      $pc->{'combo'.$_.'Crit'.$i}  = '';
      $pc->{'combo'.$_.'Atk'.$i}   = '';
      $pc->{'combo'.$_.'Fixed'.$i} = '';
    }
  }
  $pc->{weaponNum} = $pc->{armorNum} = $pc->{itemNum} = $pc->{vehicleNum} = $pc->{magicNum} = $pc->{historyNum} = 0;
  $pc->{history0Exp} = noiseText(1,3);
}

### ステージ --------------------------------------------------
if($pc{stage} =~ /クロウリングケイオス/){ $SHEET->param(ccOn => 1); }

### ワークス --------------------------------------------------
$SHEET->param(isFH => $pc{works} =~ /[FＦ][HＨ]/i);

### ブリード --------------------------------------------------
my $breedPrefix = ($pc{breed} ? $pc{breed} : $pc{syndrome3} ? 'トライ' : $pc{syndrome2} ? 'クロス' : $pc{syndrome1} ? 'ピュア' : '');
$SHEET->param(breed => isNoiseText(removeTags $breedPrefix) ? $breedPrefix : $breedPrefix ? "$breedPrefix<span class=\"shorten\">ブリード</span>" : '');

### 侵蝕率基本値 --------------------------------------------------
if ($pc{encroachFixed}) {
  $pc{'lifepathOtherEncroach'} = undef;
  $pc{'lifepathOtherNote'} = undef;
}
$SHEET->param(hasEncroachOffset => $pc{'lifepathOtherEncroach'} || $pc{'lifepathOtherNote'} ? 1 : 0);

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
foreach (1 .. max($pc{skillRideNum},$pc{skillArtNum},$pc{skillKnowNum},$pc{skillInfoNum})){
  next if (
    !$pc{'skillRide'.$_.'Name'} && !$pc{'skillArt' .$_.'Name'} && !$pc{'skillKnow'.$_.'Name'} && !$pc{'skillInfo'.$_.'Name'}
    && !$pc{'skillTotalRide'.$_} && !$pc{'skillTotalArt'.$_} && !$pc{'skillTotalKnow'.$_} && !$pc{'skillTotalInfo'.$_}
  );
  push(@skills, {
    RIDE => $pc{'skillRide'.$_.'Name'}, RIDELV => ($pc{'skillAddRide'.$_}?"<span class=\"small\">+$pc{'skillAddRide'.$_}=</span>":'').$pc{'skillTotalRide'.$_},
    ART  => $pc{'skillArt' .$_.'Name'}, ARTLV  => ($pc{'skillAddArt'.$_} ?"<span class=\"small\">+$pc{'skillAddArt'.$_}=</span>" :'').$pc{'skillTotalArt'.$_},
    KNOW => $pc{'skillKnow'.$_.'Name'}, KNOWLV => ($pc{'skillAddKnow'.$_}?"<span class=\"small\">+$pc{'skillAddKnow'.$_}=</span>":'').$pc{'skillTotalKnow'.$_},
    INFO => $pc{'skillInfo'.$_.'Name'}, INFOLV => ($pc{'skillAddInfo'.$_}?"<span class=\"small\">+$pc{'skillAddInfo'.$_}=</span>":'').$pc{'skillTotalInfo'.$_},
  });
}
$SHEET->param(Skills => \@skills);

### ロイス --------------------------------------------------
my @loises;
foreach (1 .. 7){
  my $color;
  if   ($pc{'lois'.$_.'Color'} =~ /^(BK|BLA|黒)/i){ $color = 'hsla(  0,  0%,  0%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(BL|青)/i    ){ $color = 'hsla(220,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(GR|緑)/i    ){ $color = 'hsla(120,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(OR|橙)/i    ){ $color = 'hsla( 30,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(PU|紫)/i    ){ $color = 'hsla(270,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(RE|赤)/i    ){ $color = 'hsla(  0,100%, 50%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(WH|白)/i    ){ $color = 'hsla(  0,  0%,100%,0.2)'; }
  elsif($pc{'lois'.$_.'Color'} =~ /^(YE|黄)/i    ){ $color = 'hsla( 60,100%, 50%,0.2)'; }
  $color = $color ? "background-color:${color};" : '';
  if (!($pc{'lois'.$_.'Relation'} || $pc{'lois'.$_.'Name'} || $pc{'lois'.$_.'Note'}) || $pc{'lois'.$_.'Relation'} =~ /[DＤEＥ]ロイス|^[DＤEＥ]$/) {
    $pc{'lois'.$_.'State'} = '';
  }

  # 感情の内容もチェックもなく、状態ももたないなら、感情を無効にする.
  my $noEmotion = !($pc{'lois'.$_.'EmoPosi'} || $pc{'lois'.$_.'EmoPosiCheck'} || $pc{'lois'.$_.'EmoNega'} || $pc{'lois'.$_.'EmoNegaCheck'} || $pc{'lois'.$_.'State'});

  push(@loises, {
    "RELATION" => $pc{'lois'.$_.'Relation'},
    "NAME"     => $pc{'lois'.$_.'Name'},
    "POSI"     => $pc{'lois'.$_.'EmoPosi'},
    "NEGA"     => $pc{'lois'.$_.'EmoNega'},
    "P-CHECK"  => ($noEmotion ? 'empty' : $pc{'lois'.$_.'EmoPosiCheck'} ? 'checked' : ''),
    "N-CHECK"  => ($noEmotion ? 'empty' : $pc{'lois'.$_.'EmoNegaCheck'} ? 'checked' : ''),
    "NO-EMO"   => $noEmotion,
    "COLOR"    => $pc{'lois'.$_.'Color'},
    "COLOR-BG" => $color,
    "NOTE"     => $pc{'lois'.$_.'Note'},
    "S"        => $pc{'lois'.$_.'S'},
    "STATE"    => $pc{'lois'.$_.'State'},
  });
  if($pc{'lois'.$_.'Name'} =~ /起源種|オリジナルレネゲイド/){ $SHEET->param(encroachOrOn => 'checked'); }
}
$SHEET->param(Loises => \@loises);

### メモリー --------------------------------------------------
my @memories;
foreach (1 .. 3){
  next if !existsRow "memory$_",'Name','Relation';
  push(@memories, {
    RELATION => $pc{'memory'.$_.'Relation'},
    NAME     => $pc{'memory'.$_.'Name'},
    EMOTION  => $pc{'memory'.$_.'Emo'},
    NOTE     => $pc{'memory'.$_.'Note'},
  });
}
$SHEET->param(Memories => \@memories);

### エフェクト --------------------------------------------------
my @effects;
foreach (1 .. $pc{effectNum}){
  next if !existsRow "effect$_",'Name','Lv','Timing','Skill','Dfclty','Target','Range','Encroach','Restrict','Note','Exp';
  push(@effects, {
    TYPE     => $pc{'effect'.$_.'Type'},
    NAME     => shrinkText(13,15,17,21,$pc{'effect'.$_.'Name'}),
    LV       => $pc{'effect'.$_.'Lv'},
    TIMING   => renderTiming($pc{'effect'.$_.'Timing'}),
    SKILL    => renderSkill($pc{'effect'.$_.'Skill'}),
    DFCLTY   => shrinkText(3,4,4,4,$pc{'effect'.$_.'Dfclty'}),
    TARGET   => shrinkText(6,7,8,8,$pc{'effect'.$_.'Target'}),
    RANGE    => $pc{'effect'.$_.'Range'},
    ENCROACH => shrinkText(3,4,4,4,$pc{'effect'.$_.'Encroach'}),
    RESTRICT => $pc{'effect'.$_.'Restrict'},
    NOTE     => $pc{'effect'.$_.'Note'},
    EXP      => ($pc{'effect'.$_.'Exp'} > 0 ? '+' : '').$pc{'effect'.$_.'Exp'},
  });
}
$SHEET->param(Effects => \@effects);
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

### 術式 --------------------------------------------------
my @magics;
foreach (1 .. $pc{magicNum}){
  next if !existsRow "magic$_",'Name','Type','Exp','Activate','Encroach','Note';
  push(@magics, {
    NAME     => $pc{'magic'.$_.'Name'},
    TYPE     => shrinkText(5,5,5,5,$pc{'magic'.$_.'Type'}),
    EXP      => $pc{'magic'.$_.'Exp'},
    ACTIVATE => $pc{'magic'.$_.'Activate'},
    ENCROACH => $pc{'magic'.$_.'Encroach'},
    NOTE     => $pc{'magic'.$_.'Note'},
  });
}
$SHEET->param(Magics => \@magics);

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
    STOCK => $pc{'weapon'.$_.'Stock'},
    EXP   => $pc{'weapon'.$_.'Exp'},
    TYPE  => textType($pc{'weapon'.$_.'Type'}),
    SKILL => renderSkill(shrinkText(4,5,6,7,$pc{'weapon'.$_.'Skill'})),
    ACC   => $pc{'weapon'.$_.'Acc'},
    ATK   => $pc{'weapon'.$_.'Atk'},
    GUARD => $pc{'weapon'.$_.'Guard'},
    RANGE => $pc{'weapon'.$_.'Range'},
    NOTE  => $pc{'weapon'.$_.'Note'},
  });
}
$SHEET->param(Weapons => \@weapons);
sub textType {
  my $text = shift;
  my @texts = split(/[／\/]/, $text);
  foreach (@texts){ shrinkText(5,6,7,8,$_) }
  return join('<hr class="dotted">', @texts);
}

### 防具 --------------------------------------------------
my @armors;
foreach (1 .. $pc{armorNum}){
  next if !existsRow "armor$_",'Name','Stock','Exp','Initiative','Dodge','Armor','Note';
  push(@armors, {
    NAME       => shrinkText(12,13,14,15,$pc{'armor'.$_.'Name'}),
    STOCK      => $pc{'armor'.$_.'Stock'},
    EXP        => $pc{'armor'.$_.'Exp'},
    TYPE       => shrinkText(5,6,7,8,$pc{'armor'.$_.'Type'}),
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
  next if !existsRow "vehicle$_",'Name','Stock','Exp','Skill','Atk','Initiative','Armor','Dash','Note';
  push(@vehicles, {
    NAME       => shrinkText(12,13,14,15,$pc{'vehicle'.$_.'Name'}),
    STOCK      => $pc{'vehicle'.$_.'Stock'},
    EXP        => $pc{'vehicle'.$_.'Exp'},
    TYPE       => textType($pc{'vehicle'.$_.'Type'}),
    SKILL      => renderSkill(shrinkText(4,5,6,7,$pc{'vehicle'.$_.'Skill'})),
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
  next if !existsRow "item$_",'Name','Stock','Exp','Skill','Note';
  push(@items, {
    NAME  => shrinkText(12,13,14,15,$pc{'item'.$_.'Name'}),
    STOCK => $pc{'item'.$_.'Stock'},
    EXP   => $pc{'item'.$_.'Exp'},
    TYPE  => shrinkText(5,6,7,8,$pc{'item'.$_.'Type'}),
    SKILL => renderSkill(shrinkText(4,5,6,7,$pc{'item'.$_.'Skill'})),
    NOTE  => $pc{'item'.$_.'Note'},
  });
}
$SHEET->param(Items => \@items);

### 作成方法 --------------------------------------------------
$SHEET->param(isConstruction => ($pc{createType} eq 'C') ? 1 : 0);


### 侵蝕率 --------------------------------------------------
$SHEET->param(currentEncroach => $pc{baseEncroach} =~ /^[0-9]+$/ ? $pc{baseEncroach} : 0);

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = !$pc{forbiddenMode} ? ($pc{createType} eq 'C') ? 'コンストラクション作成' : 'フルスクラッチ作成' : '作成';
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Exp','Gm','Member','Note');
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
  if($_ && !$pc{'history'.$_.'ExpApply'} && $pc{'history'.$_.'Exp'} ne '') {
    $pc{'history'.$_.'Exp'} = '<s>'.$pc{'history'.$_.'Exp'}.'</s>';
  }
  push(@history, {
    NUM    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE   => $pc{'history'.$_.'Date'},
    TITLE  => $pc{'history'.$_.'Title'},
    EXP    => $pc{'history'.$_.'Exp'},
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "性別:$pc{gender}　年齢:$pc{age}　ワークス:$pc{works}　シンドローム:$pc{syndrome1} $pc{syndrome2} $pc{syndrome3}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
