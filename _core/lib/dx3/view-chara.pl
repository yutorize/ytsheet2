################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_syndrome;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  path => ['./', $::core_dir."/skin/dx3", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  loop_context_vars => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### キャラクターデータ読み込み #######################################################################
our %pc = pcDataGet();

### 閲覧禁止データ --------------------------------------------------
if($pc{'forbidden'} && !$pc{'yourAuthor'}){
  my $author = $pc{'playerName'};
  my $protect   = $pc{'protect'};
  my $forbidden = $pc{'forbidden'};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{'aka'} = '';
    $pc{'characterName'} = noiseText(6,14);
    $pc{'group'} = $pc{'stage'} = $pc{'tags'} = '';
  
    $pc{'age'}    = noiseText(1,2);
    $pc{'gender'} = noiseText(1,2);
    $pc{'sign'}   = noiseText(3);
    $pc{'height'} = noiseText(2);
    $pc{'weight'} = noiseText(2);
    $pc{'blood'}  = noiseText(2,3);
    
    $pc{'cover'} = noiseText(3,8);
    
    $pc{'freeNote'} = '';
    foreach(1..int(rand 3)+2){
      $pc{'freeNote'} .= '　'.noiseText(18,40)."\n";
    }
    $pc{'freeHistory'} = '';
  }
  
  $pc{'works'} = noiseText(3,8);
  
  $pc{'expUsedStatus'} = noiseText(2);
  $pc{'expUsedSkill'}  = noiseText(2);
  $pc{'expUsedEffect'} = noiseText(2);
  $pc{'expUsedItem'}   = noiseText(2);
  $pc{'expUsedMemory'} = noiseText(2);
  $pc{'expUsed'}       = noiseText(2);
  $pc{'expRest'}       = noiseText(2);
  $pc{'expTotal'}      = noiseText(2);
  
  if($forbidden ne 'battle'){
    $pc{'lifepathOrigin'}          = noiseText(3,5);
    $pc{'lifepathExperience'}      = noiseText(3,5);
    $pc{'lifepathEncounter'}       = noiseText(3,5);
    $pc{'lifepathOriginNote'}      = noiseText(8,16);
    $pc{'lifepathExperienceNote'}  = noiseText(8,16);
    $pc{'lifepathEncounterNote'}   = noiseText(8,16);
  }
  $pc{'lifepathAwaken'}          = noiseText(2);
  $pc{'lifepathImpulse'}         = noiseText(2);
  $pc{'lifepathAwakenNote'}      = noiseText(8,16);
  $pc{'lifepathImpulseNote'}     = noiseText(8,16);
  $pc{'lifepathOtherNote'}       = noiseText(8,16);
  $pc{'lifepathAwakenEncroach'}  = noiseText(1);
  $pc{'lifepathImpulseEncroach'} = noiseText(1);
  $pc{'lifepathOtherEncroach'}   = noiseText(1);
  $pc{'baseEncroach'} = noiseText(1,2);
  $pc{'lifepathUrgeCheck'} = '';
  
  $pc{'breed'}       = noiseText(3);
  $pc{'syndrome1'}   = noiseText(4,8);
  $pc{'syndrome2'}   = noiseText(4,8);
  $pc{'syndrome3'}   = noiseText(4,8);
  
  foreach my $name ('Body','Sense','Mind','Social'){
    $pc{'sttTotal'.$name} = noiseText(1);
    $pc{'sttBase' .$name} = noiseText(1);
    $pc{'sttWorks'.$name} = noiseText(1);
    $pc{'sttGrow' .$name} = noiseText(1);
    $pc{'sttAdd'  .$name} = noiseText(1);
  }
  $pc{'maxHpTotal'}      = noiseText(1,2);
  $pc{'initiativeTotal'} = noiseText(1,2);
  $pc{'moveTotal'}       = noiseText(1,2);
  $pc{'dashTotal'}       = noiseText(1,2);
  $pc{'stockTotal'}      = noiseText(1,2);
  $pc{'savingTotal'}     = noiseText(1,2);
  
  foreach my $name ('Melee','Ranged','RC','Negotiate','Dodge','Percept','Will','Procure'){
    $pc{'skillTotal'.$name} = noiseText(1);
  }
  foreach my $name ('Ride','Art','Know','Info'){
    $pc{'skill'.$name.'Num'} = 1;
    foreach my $num (1 .. $pc{'skill'.$name.'Num'}){
      $pc{'skill'.$name.$num.'Name'} = noiseText(4,8);
      $pc{'skillTotal'.$name.$num} = noiseText(1);
    }
  }
  
  foreach(1..7){
    $pc{'lois'.$_.'Relation'} = noiseText(2,4);
    $pc{'lois'.$_.'Name'}     = noiseText(3,10);
    $pc{'lois'.$_.'Note'}     = noiseText(3,16);
    $pc{'lois'.$_.'EmoPosi'}  = noiseText(2,3);
    $pc{'lois'.$_.'EmoNega'}  = noiseText(2,3);
    $pc{'lois'.$_.'EmoPosiCheck'} = $pc{'lois'.$_.'EmoNegaCheck'} = $pc{'lois'.$_.'Color'} = $pc{'lois'.$_.'State'} = '';
  }
  
  $pc{'effectNum'} = int(rand 4) + 8;
  foreach(1..$pc{'effectNum'}){
    $pc{'effect'.$_.'Type'}     = '';
    $pc{'effect'.$_.'Name'}     = noiseText(5,10);
    $pc{'effect'.$_.'Lv'}       = noiseText(1);
    $pc{'effect'.$_.'Timing'}   = noiseText(4,7);
    $pc{'effect'.$_.'Skill'}    = noiseText(2,6);
    $pc{'effect'.$_.'Dfclty'}   = noiseText(1,2);
    $pc{'effect'.$_.'Target'}   = noiseText(2,5);
    $pc{'effect'.$_.'Range'}    = noiseText(2,3);
    $pc{'effect'.$_.'Encroach'} = noiseText(1);
    $pc{'effect'.$_.'Restrict'} = noiseText(2,3);
    $pc{'effect'.$_.'Note'}     = noiseText(10,20);
  }
  $pc{'comboNum'} = int(rand 3) + 1;
  foreach(1..$pc{'comboNum'}){
    $pc{'combo'.$_.'Name'}     = noiseText(5,10);
    $pc{'combo'.$_.'Combo'}    = noiseText(10,30);
    $pc{'combo'.$_.'Timing'}   = noiseText(4,7);
    $pc{'combo'.$_.'Skill'}    = noiseText(2,6);
    $pc{'combo'.$_.'Dfclty'}   = noiseText(1,2);
    $pc{'combo'.$_.'Target'}   = noiseText(2,5);
    $pc{'combo'.$_.'Range'}    = noiseText(2,3);
    $pc{'combo'.$_.'Encroach'} = noiseText(1);
    $pc{'combo'.$_.'Note'}     = noiseText(10,20);
    foreach my $i (1..2){
      $pc{'combo'.$_.'Condition'.$i} = noiseText(3,4);
      $pc{'combo'.$_.'Dice'.$i}  = noiseText(1,3);
      $pc{'combo'.$_.'Crit'.$i}  = noiseText(1,3);
      $pc{'combo'.$_.'Atk'.$i}   = noiseText(1,3);
      $pc{'combo'.$_.'Fixed'.$i} = noiseText(1,3);
    }
    foreach my $i (3..4){
      $pc{'combo'.$_.'Condition'.$i} = '';
      $pc{'combo'.$_.'Dice'.$i}  = '';
      $pc{'combo'.$_.'Crit'.$i}  = '';
      $pc{'combo'.$_.'Atk'.$i}   = '';
      $pc{'combo'.$_.'Fixed'.$i} = '';
    }
  }
  $pc{'weaponNum'} = $pc{'armorNum'} = $pc{'itemNum'} = $pc{'magicNum'} = $pc{'historyNum'} = 0;
  $pc{'history0Exp'} = noiseText(1,3);
  
  $pc{'playerName'} = $author;
  $pc{'protect'} = $protect;
  $pc{'forbidden'} = $forbidden;
  $pc{'forbiddenMode'} = 1;
}

### 置換 #############################################################################################
if($pc{'ver'}){
  foreach (keys %pc) {
    next if($_ =~ /^image/);
    if($_ =~ /^(?:freeNote|freeHistory)$/){
      $pc{$_} = tagUnescapeLines($pc{$_});
    }
    $pc{$_} = tagUnescape($pc{$_});

    $pc{$_} = noiseTextTag $pc{$_} if $pc{'forbiddenMode'};
  }
}
else {
  $pc{'freeNote'} = $pc{'freeNoteView'} if $pc{'freeNoteView'};
}

### アップデート --------------------------------------------------
if($pc{'ver'}){
  %pc = data_update_chara(\%pc);
}

### カラー設定 --------------------------------------------------
setColors();

### 出力準備 #########################################################################################
### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param(id => $::in{'id'});

if($::in{'url'}){
  $SHEET->param(convertMode => 1);
  $SHEET->param(convertUrl => $::in{'url'});
}

### キャラクター名 --------------------------------------------------
$SHEET->param(characterName => "<ruby>$pc{'characterName'}<rp>(</rp><rt>$pc{'characterNameRuby'}</rt><rp>)</rp></ruby>") if $pc{'characterNameRuby'};

### 二つ名 --------------------------------------------------
$SHEET->param(aka => "<ruby>$pc{'aka'}<rp>(</rp><rt>$pc{'akaRuby'}</rt><rp>)</rp></ruby>") if $pc{'akaRuby'};

### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $::in{'id'}))[0];
  $SHEET->param(playerName => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{'playerName'}.'</a>');
}
### グループ --------------------------------------------------
if($::in{'url'}){
  $SHEET->param(group => '');
}
else {
  if(!$pc{'group'}) {
    $pc{'group'} = $set::group_default;
    $SHEET->param(group => $set::group_default);
  }
  foreach (@set::groups){
    if($pc{'group'} eq @$_[0]){
      $SHEET->param(groupName => @$_[2]);
      last;
    }
  }
}

### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{'tags'})){
  push(@tags, {
    "URL"  => uri_escape_utf8($_),
    "TEXT" => $_,
  });
}
$SHEET->param(Tags => \@tags);

### セリフ --------------------------------------------------
$pc{'words'} =~ s/<br>/\n/g;
$pc{'words'} =~ s/^([「『（])/<span class="brackets">$1<\/span>/gm;
$pc{'words'} =~ s/(.+?(?:[，、。？」』）]|$))/<span>$1<\/span>/g;
$pc{'words'} =~ s/\n<span>　/\n<span>/g;
$pc{'words'} =~ s/\n/<br>/g;
$SHEET->param(words => $pc{'words'});
$SHEET->param(wordsX => ($pc{'wordsX'} eq '左' ? 'left:0;' : 'right:0;'));
$SHEET->param(wordsY => ($pc{'wordsY'} eq '下' ? 'bottom:0;' : 'top:0;'));

### ステージ --------------------------------------------------
if($pc{'stage'} =~ /クロウリングケイオス/){ $SHEET->param(ccOn => 1); }

### ブリード --------------------------------------------------
my $breedPrefix = ($pc{'breed'} ? $pc{'breed'} : $pc{'syndrome3'} ? 'トライ' : $pc{'syndrome2'} ? 'クロス' : $pc{'syndrome1'} ? 'ピュア' : '');
$SHEET->param(breed => $breedPrefix ? "$breedPrefix<span>ブリード</span>" : '');

### 能力値 --------------------------------------------------
my %status = (0=>'body', 1=>'sense', 2=>'mind', 3=>'social');
foreach my $num (keys %status){
  my $name = $status{$num};
  my $base = 0;
  $base += $data::syndrome_status{$pc{'syndrome1'}}[$num];
  $base += $pc{'syndrome2'} ? $data::syndrome_status{$pc{'syndrome2'}}[$num] : $base;
  $SHEET->param('sttBase'.ucfirst($name) => $base);
}
$SHEET->param('sttWorks'.ucfirst($pc{'sttWorks'}) => 1);

### 技能 --------------------------------------------------
foreach my $name ('Melee','Ranged','RC','Negotiate','Dodge','Percept','Will','Procure'){
  $SHEET->param('skillTotal'.$name => ($pc{'skillAdd'.$name} ? "<span class=\"small\">+$pc{'skillAdd'.$name}=</span>" : '').$pc{'skillTotal'.$name});
}
my @skills;
foreach (1 .. max($pc{'skillRideNum'},$pc{'skillArtNum'},$pc{'skillKnowNum'},$pc{'skillInfoNum'})){
  next if (
    !$pc{'skillRide'.$_.'Name'} && !$pc{'skillArt' .$_.'Name'} && !$pc{'skillKnow'.$_.'Name'} && !$pc{'skillInfo'.$_.'Name'}
    && !$pc{'skillTotalRide'.$_} && !$pc{'skillTotalArt'.$_} && !$pc{'skillTotalKnow'.$_} && !$pc{'skillTotalInfo'.$_}
  );
  push(@skills, {
    "RIDE" => $pc{'skillRide'.$_.'Name'}, "RIDELV" => ($pc{'skillAddRide'.$_}?"<span class=\"small\">+$pc{'skillAddRide'.$_}=</span>":'').$pc{'skillTotalRide'.$_},
    "ART"  => $pc{'skillArt' .$_.'Name'}, "ARTLV"  => ($pc{'skillAddArt'.$_} ?"<span class=\"small\">+$pc{'skillAddArt'.$_}=</span>" :'').$pc{'skillTotalArt'.$_},
    "KNOW" => $pc{'skillKnow'.$_.'Name'}, "KNOWLV" => ($pc{'skillAddKnow'.$_}?"<span class=\"small\">+$pc{'skillAddKnow'.$_}=</span>":'').$pc{'skillTotalKnow'.$_},
    "INFO" => $pc{'skillInfo'.$_.'Name'}, "INFOLV" => ($pc{'skillAddInfo'.$_}?"<span class=\"small\">+$pc{'skillAddInfo'.$_}=</span>":'').$pc{'skillTotalInfo'.$_},
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
  push(@loises, {
    "RELATION" => $pc{'lois'.$_.'Relation'},
    "NAME"     => $pc{'lois'.$_.'Name'},
    "POSI"     => $pc{'lois'.$_.'EmoPosi'},
    "NEGA"     => $pc{'lois'.$_.'EmoNega'},
    "P-CHECK"  => $pc{'lois'.$_.'EmoPosiCheck'},
    "N-CHECK"  => $pc{'lois'.$_.'EmoNegaCheck'},
    "COLOR"    => $pc{'lois'.$_.'Color'},
    "COLOR-BG" => $color,
    "NOTE"     => $pc{'lois'.$_.'Note'},
    "STATE"    => $pc{'lois'.$_.'State'},
  });
  if($pc{'lois'.$_.'Name'} =~ /起源種|オリジナルレネゲイド/){ $SHEET->param(encroachOrOn => 'checked'); }
}
$SHEET->param(Loises => \@loises);

### メモリー --------------------------------------------------
my @memories;
foreach (1 .. 3){
  next if !$pc{'memory'.$_.'Gain'};
  push(@memories, {
    "RELATION" => $pc{'memory'.$_.'Relation'},
    "NAME"     => $pc{'memory'.$_.'Name'},
    "EMOTION"  => $pc{'memory'.$_.'Emo'},
    "NOTE"     => $pc{'memory'.$_.'Note'},
    "STATE"    => $pc{'memory'.$_.'State'},
  });
}
$SHEET->param(Memories => \@memories);

### エフェクト --------------------------------------------------
my @effects;
foreach (1 .. $pc{'effectNum'}){
  next if(
    !$pc{'effect'.$_.'Name'}  && !$pc{'effect'.$_.'Lv'}       && !$pc{'effect'.$_.'Timing'} &&
    !$pc{'effect'.$_.'Skill'} && !$pc{'effect'.$_.'Dfclty'}   && !$pc{'effect'.$_.'Target'} && 
    !$pc{'effect'.$_.'Range'} && !$pc{'effect'.$_.'Encroach'} && !$pc{'effect'.$_.'Restrict'} &&
    !$pc{'effect'.$_.'Note'}  && !$pc{'effect'.$_.'Exp'}
  );
  push(@effects, {
    "TYPE"     => $pc{'effect'.$_.'Type'},
    "NAME"     => textShrink(13,15,17,21,$pc{'effect'.$_.'Name'}),
    "LV"       => $pc{'effect'.$_.'Lv'},
    "TIMING"   => textTiming($pc{'effect'.$_.'Timing'}),
    "SKILL"    => textSkill($pc{'effect'.$_.'Skill'}),
    "DFCLTY"   => textShrink(3,4,4,4,$pc{'effect'.$_.'Dfclty'}),
    "TARGET"   => textShrink(6,7,8,8,$pc{'effect'.$_.'Target'}),
    "RANGE"    => $pc{'effect'.$_.'Range'},
    "ENCROACH" => textShrink(3,4,4,4,$pc{'effect'.$_.'Encroach'}),
    "RESTRICT" => $pc{'effect'.$_.'Restrict'},
    "NOTE"     => $pc{'effect'.$_.'Note'},
    "EXP"      => ($pc{'effect'.$_.'Exp'} > 0 ? '+' : '').$pc{'effect'.$_.'Exp'},
  });
}
$SHEET->param(Effects => \@effects);
sub textTiming {
  my $text = shift;
  $text =~ s#([^<])[／\/]#$1<hr class="dotted">#g;
  $text =~ s#(オート|メジャー|マイナー)(アクション)?#<span class="thin">$1<span class="shorten">アクション</span></span>#g;
  $text =~ s#リアク?(ション)?#<span class="thin">リア<span class="shorten">クション</span></span>#g;
  $text =~ s#(セットアップ|クリンナップ)(プロセス)?#<span class="thiner">$1<span class="shorten">プロセス</span></span>#g;
  return $text;
}
sub textSkill {
  my $text = shift;
  $text =~ s#(〈.*?〉|【.*?】)#<span>$1</span>#g;
  $text =~ s#(シンドローム)#<span class="thin">$1</span>#g;
  return $text;
}
sub textShrink {
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
foreach (1 .. $pc{'magicNum'}){
  next if(
    !$pc{'magic'.$_.'Name'}     && !$pc{'magic'.$_.'Type'}     && !$pc{'magic'.$_.'Exp'} &&
    !$pc{'magic'.$_.'Activate'} && !$pc{'magic'.$_.'Encroach'} && !$pc{'magic'.$_.'Note'} 
  );
  push(@magics, {
    "NAME"     => $pc{'magic'.$_.'Name'},
    "TYPE"     => textShrink(5,5,5,5,$pc{'magic'.$_.'Type'}),
    "EXP"      => $pc{'magic'.$_.'Exp'},
    "ACTIVATE" => $pc{'magic'.$_.'Activate'},
    "ENCROACH" => $pc{'magic'.$_.'Encroach'},
    "NOTE"     => $pc{'magic'.$_.'Note'},
  });
}
$SHEET->param(Magics => \@magics);

### コンボ --------------------------------------------------
my @combos;
foreach (1 .. $pc{'comboNum'}){
  next if(
    !$pc{'combo'.$_.'Name'}  && !$pc{'combo'.$_.'Combo'}    && !$pc{'combo'.$_.'Timing'} &&
    !$pc{'combo'.$_.'Skill'} && !$pc{'combo'.$_.'Dfclty'}   && !$pc{'combo'.$_.'Target'} && 
    !$pc{'combo'.$_.'Range'} && !$pc{'combo'.$_.'Encroach'} && !$pc{'combo'.$_.'Note'} && 
    !$pc{'combo'.$_.'Dice1'} && !$pc{'combo'.$_.'Crit1'} && !$pc{'combo'.$_.'Atk1'} && !$pc{'combo'.$_.'Fixed1'}
  );
  my $blankrow = 0;
  if(!$pc{'combo'.$_.'Condition2'}){ $blankrow++; }
  if(!$pc{'combo'.$_.'Condition3'}){ $blankrow++; }
  if(!$pc{'combo'.$_.'Condition4'}){ $blankrow++; }
  if(!$pc{'combo'.$_.'Condition5'}){ $blankrow++; }
  push(@combos, {
    "NAME"     => textShrink(15,17,19,23,$pc{'combo'.$_.'Name'}),
    "COMBO"    => textCombo($pc{'combo'.$_.'Combo'}),
    "TIMING"   => textTiming($pc{'combo'.$_.'Timing'}),
    "SKILL"    => textComboSkill($pc{'combo'.$_.'Skill'}),
    "DFCLTY"   => textShrink(3,4,4,4,$pc{'combo'.$_.'Dfclty'}),
    "TARGET"   => textShrink(6,7,8,8,$pc{'combo'.$_.'Target'}),
    "RANGE"    => $pc{'combo'.$_.'Range'},
    "ENCROACH" => textShrink(3,4,4,4,$pc{'combo'.$_.'Encroach'}),
    "NOTE"     => $pc{'combo'.$_.'Note'},
    "CONDITION1" => $pc{'combo'.$_.'Condition1'},
    "DICE1"      => $pc{'combo'.$_.'Dice1'},
    "CRIT1"      => $pc{'combo'.$_.'Crit1'},
    "ATK1"       => $pc{'combo'.$_.'Atk1'},
    "FIXED1"     => $pc{'combo'.$_.'Fixed1'},
    "CONDITION2" => $pc{'combo'.$_.'Condition2'},
    "DICE2"      => $pc{'combo'.$_.'Dice2'},
    "CRIT2"      => $pc{'combo'.$_.'Crit2'},
    "ATK2"       => $pc{'combo'.$_.'Atk2'},
    "FIXED2"     => $pc{'combo'.$_.'Fixed2'},
    "CONDITION3" => $pc{'combo'.$_.'Condition3'},
    "DICE3"      => $pc{'combo'.$_.'Dice3'},
    "CRIT3"      => $pc{'combo'.$_.'Crit3'},
    "ATK3"       => $pc{'combo'.$_.'Atk3'},
    "FIXED3"     => $pc{'combo'.$_.'Fixed3'},
    "CONDITION4" => $pc{'combo'.$_.'Condition4'},
    "DICE4"      => $pc{'combo'.$_.'Dice4'},
    "CRIT4"      => $pc{'combo'.$_.'Crit4'},
    "ATK4"       => $pc{'combo'.$_.'Atk4'},
    "FIXED4"     => $pc{'combo'.$_.'Fixed4'},
    "CONDITION5" => $pc{'combo'.$_.'Condition5'},
    "DICE5"      => $pc{'combo'.$_.'Dice5'},
    "CRIT5"      => $pc{'combo'.$_.'Crit5'},
    "ATK5"       => $pc{'combo'.$_.'Atk5'},
    "FIXED5"     => $pc{'combo'.$_.'Fixed5'},
    "BLANKROW"   => $blankrow,
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
foreach (1 .. $pc{'weaponNum'}){
  next if(
    !$pc{'weapon'.$_.'Name'}  && !$pc{'weapon'.$_.'Stock'} && !$pc{'weapon'.$_.'Exp'} &&
    !$pc{'weapon'.$_.'Skill'} && !$pc{'weapon'.$_.'Acc'}   && !$pc{'weapon'.$_.'Atk'} &&
    !$pc{'weapon'.$_.'Guard'} && !$pc{'weapon'.$_.'Range'} && !$pc{'weapon'.$_.'Note'} 
  );
  push(@weapons, {
    "NAME"     => textShrink(12,13,14,15,$pc{'weapon'.$_.'Name'}),
    "STOCK"    => $pc{'weapon'.$_.'Stock'},
    "EXP"      => $pc{'weapon'.$_.'Exp'},
    "TYPE"     => textType($pc{'weapon'.$_.'Type'}),
    "SKILL"    => textSkill(textShrink(4,5,6,7,$pc{'weapon'.$_.'Skill'})),
    "ACC"      => $pc{'weapon'.$_.'Acc'},
    "ATK"      => $pc{'weapon'.$_.'Atk'},
    "GUARD"    => $pc{'weapon'.$_.'Guard'},
    "RANGE"    => $pc{'weapon'.$_.'Range'},
    "NOTE"     => $pc{'weapon'.$_.'Note'},
  });
}
$SHEET->param(Weapons => \@weapons);
sub textType {
  my $text = shift;
  my @texts = split(/[／\/]/, $text);
  foreach (@texts){ textShrink(5,6,7,8,$_) }
  return join('<hr class="dotted">', @texts);
}

### 防具 --------------------------------------------------
my @armors;
foreach (1 .. $pc{'armorNum'}){
  next if(
    !$pc{'armor'.$_.'Name'}  && !$pc{'armor'.$_.'Stock'} && !$pc{'armor'.$_.'Exp'} && !$pc{'armor'.$_.'Initiative'} &&
    !$pc{'armor'.$_.'Dodge'} && !$pc{'armor'.$_.'Armor'} && !$pc{'armor'.$_.'Note'} 
  );
  push(@armors, {
    "NAME"       => textShrink(12,13,14,15,$pc{'armor'.$_.'Name'}),
    "STOCK"      => $pc{'armor'.$_.'Stock'},
    "EXP"        => $pc{'armor'.$_.'Exp'},
    "TYPE"       => textShrink(5,6,7,8,$pc{'armor'.$_.'Type'}),
    "INITIATIVE" => $pc{'armor'.$_.'Initiative'},
    "DODGE"      => $pc{'armor'.$_.'Dodge'},
    "ARMOR"      => $pc{'armor'.$_.'Armor'},
    "NOTE"       => $pc{'armor'.$_.'Note'},
  });
}
$SHEET->param(Armors => \@armors);

### ヴィークル --------------------------------------------------
my @vehicles;
foreach (1 .. $pc{'vehicleNum'}){
  next if(
    !$pc{'vehicle'.$_.'Name'}  && !$pc{'vehicle'.$_.'Stock'} && !$pc{'vehicle'.$_.'Exp'} &&
    !$pc{'vehicle'.$_.'Skill'} && !$pc{'vehicle'.$_.'Atk'}   && !$pc{'vehicle'.$_.'Initiative'} &&
    !$pc{'vehicle'.$_.'Armor'} && !$pc{'vehicle'.$_.'Dash'}  && !$pc{'vehicle'.$_.'Note'}
  );
  push(@vehicles, {
    "NAME"       => textShrink(12,13,14,15,$pc{'vehicle'.$_.'Name'}),
    "STOCK"      => $pc{'vehicle'.$_.'Stock'},
    "EXP"        => $pc{'vehicle'.$_.'Exp'},
    "TYPE"       => textType($pc{'vehicle'.$_.'Type'}),
    "SKILL"      => textSkill(textShrink(4,5,6,7,$pc{'vehicle'.$_.'Skill'})),
    "INITIATIVE" => $pc{'vehicle'.$_.'Initiative'},
    "ATK"        => $pc{'vehicle'.$_.'Atk'},
    "ARMOR"      => $pc{'vehicle'.$_.'Armor'},
    "DASH"       => $pc{'vehicle'.$_.'Dash'},
    "NOTE"       => $pc{'vehicle'.$_.'Note'},
  });
}
$SHEET->param(Vehicles => \@vehicles);

### アイテム --------------------------------------------------
my @items;
foreach (1 .. $pc{'itemNum'}){
  next if(
    !$pc{'item'.$_.'Name'}  && !$pc{'item'.$_.'Stock'} && !$pc{'item'.$_.'Exp'} &&
    !$pc{'item'.$_.'Skill'} && !$pc{'item'.$_.'Note'}
  );
  push(@items, {
    "NAME"  => textShrink(12,13,14,15,$pc{'item'.$_.'Name'}),
    "STOCK" => $pc{'item'.$_.'Stock'},
    "EXP"   => $pc{'item'.$_.'Exp'},
    "TYPE"  => textShrink(5,6,7,8,$pc{'item'.$_.'Type'}),
    "SKILL" => textSkill(textShrink(4,5,6,7,$pc{'item'.$_.'Skill'})),
    "NOTE"  => $pc{'item'.$_.'Note'},
  });
}
$SHEET->param(Items => \@items);

### 侵蝕率 --------------------------------------------------
$SHEET->param(currentEncroach => $pc{'baseEncroach'} =~ /^[0-9]+$/ ? $pc{'baseEncroach'} : 0);

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{'history0Title'} = 'キャラクター作成';
foreach (0 .. $pc{'historyNum'}){
  #next if !$pc{'history'.$_.'Title'};
  $h_num++ if $pc{'history'.$_.'Gm'};
  if ($set::log_dir && $pc{'history'.$_.'Date'} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
    my $room = $1;
    (my $date = $pc{'history'.$_.'Date'}) =~ s/[\-\/]//g;
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
  if($_ && !$pc{'history'.$_.'ExpApply'}) {
    $pc{'history'.$_.'Exp'} = '<s>'.$pc{'history'.$_.'Exp'}.'</s>';
  }
  push(@history, {
    "NUM"    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    "DATE"   => $pc{'history'.$_.'Date'},
    "TITLE"  => $pc{'history'.$_.'Title'},
    "EXP"    => $pc{'history'.$_.'Exp'},
    "GM"     => $pc{'history'.$_.'Gm'},
    "MEMBER" => $members,
    "NOTE"   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);

### バックアップ --------------------------------------------------
if($::in{'id'}){
  my($selected, $list) = getLogList($set::char_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{'yourAuthor'} || $pc{'protect'} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{'forbidden'} eq 'all' && $pc{'forbiddenMode'}){
  $SHEET->param(titleName => '非公開データ');
}
else {
  $SHEET->param(titleName => tagDelete nameToPlain($pc{'characterName'}||"“$pc{'aka'}”"));
}

### 種族名 --------------------------------------------------
$pc{'race'} =~ s/［.*］//g;
$SHEET->param(race => $pc{'race'});

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{'url'} ? "?url=$::in{'url'}" : "?id=$::in{'id'}"));
if($pc{'image'}) { $SHEET->param(ogImg => $pc{'imageURL'}); }
$SHEET->param(ogDescript => tagDelete "性別:$pc{'gender'}　年齢:$pc{'age'}　ワークス:$pc{'works'}　シンドローム:$pc{'syndrome1'} $pc{'syndrome2'} $pc{'syndrome3'}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'dx3');
$SHEET->param(sheetType => 'chara');
$SHEET->param(generateType => 'DoubleCross3PC');
$SHEET->param(defaultImage => $::core_dir.'/skin/dx3/img/default_pc.png');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{'modeDownload'}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './', });
  if($::in{'url'}){
    push(@menu, { TEXT => 'コンバート', TYPE => "href", VALUE => "./?mode=convert&url=$::in{'url'}" });
  }
  else {
    if($pc{'logId'}){
      push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => 'loglistOn()', });
      if($pc{'reqdPassword'}){ push(@menu, { TEXT => '復元', TYPE => "onclick", VALUE => "editOn()", }); }
      else                   { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{'id'}&log=$pc{'logId'}", }); }
    }
    else {
      if(!$pc{'forbiddenMode'}){
        push(@menu, { TEXT => 'パレット', TYPE => "onclick", VALUE => "chatPaletteOn()",   });
        push(@menu, { TEXT => '出力'    , TYPE => "onclick", VALUE => "downloadListOn()",  });
        push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => "loglistOn()",      });
      }
      if($pc{'reqdPassword'}){ push(@menu, { TEXT => '編集', TYPE => "onclick", VALUE => "editOn()", }); }
      else                   { push(@menu, { TEXT => '編集', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{'id'}", }); }
    }
  }
}
$SHEET->param(Menu => sheetMenuCreate @menu);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
if($pc{'modeDownload'}){
  if($pc{'forbidden'} && $pc{'yourAuthor'}){ $SHEET->param(forbidden => ''); }
  print downloadModeSheetConvert $SHEET->output;
}
else {
  print $SHEET->output;
}

1;