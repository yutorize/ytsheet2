################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
require $set::data_class;

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'GranCrestPC',
  unescapeLinesKeys => [qw/freeNote freeHistory/],
  unescapeSkipRe    => qr/^image|URL$/,
  convertViewMap    => [qw/freeNote freeHistory/],
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
    

    $pc->{country}  = noiseText(3,6);
    $pc->{age}    = noiseText(1,2);
    $pc->{gender} = noiseText(1,2);
    $pc->{height} = noiseText(2,3);
    $pc->{weight} = noiseText(2,3);
    
    $pc->{lifepathBirth} = noiseText(3,10);
    $pc->{lifepathExp1}  = noiseText(3,10);
    $pc->{lifepathExp2}  = noiseText(3,10);
    
    $pc->{beliefPurpose} = noiseText(3,10);
    $pc->{beliefTaboo}   = noiseText(3,10);
    $pc->{beliefQuirk}   = noiseText(3,10);

    foreach(1..5){
      $pc->{"bond${_}Name"}        = noiseText(2,10);
      $pc->{"bond${_}Relation"}    = noiseText(1,4);
      $pc->{"bond${_}EmotionMain"} = noiseText(2,3);
      $pc->{"bond${_}EmotionSub"}  = noiseText(2,3);
    }

    $pc->{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc->{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }

  $pc->{lifepathBirthType} = noiseText(3,6);
  $pc->{lifepathExp1Type} = noiseText(3,6);
  $pc->{lifepathExp2Type} = noiseText(3,6);

  $pc->{class}    = noiseText(3,6);
  $pc->{style}    = noiseText(3,8);
  $pc->{works}    = noiseText(3,8);
  $pc->{styleSub} = noiseText(3,8);

  $pc->{expRest}  = noiseText(1,3);
  $pc->{expTotal} = noiseText(1,3);
  $pc->{level} = noiseText(1);
  
  foreach my $stt ('Str','Ref','Per','Int','Mnd','Emp'){
    $pc->{"stt${stt}Make" } = noiseText(1);
    $pc->{"stt${stt}Style"} = noiseText(1);
    $pc->{"stt${stt}Works"} = noiseText(1);
    $pc->{"stt${stt}Grow" } = noiseText(1);
    $pc->{"stt${stt}Mod"  } = noiseText(1);
    $pc->{"stt${stt}Total"} = noiseText(1);
    $pc->{"stt${stt}CheckBase"} = noiseText(1);
    $pc->{"stt${stt}CheckTotal"} = noiseText(1);
    my $i = 1;
    foreach my $label (@{$set::skill{$stt}}){
      delete $pc->{"skill${stt}${i}LabelBranch"};
      delete $pc->{"skill${stt}${i}Lv"};
      $i++;
    }
  }
  foreach my $stt ('Hp','Mp','Init','Move','Fate',){
    $pc->{"stt${stt}Total" } = noiseText(1);
    $pc->{"stt${stt}Base" } = noiseText(1);
    delete $pc->{"stt${stt}Mod"};
  }
  $pc->{"sttMaxWeight"} = noiseText(1);
  $pc->{"totalWeight"} = noiseText(1);

  $pc->{classAbilityNum} = int(rand 4) + 4;
  foreach(1..$pc->{classAbilityNum}){
    $pc->{'classAbility'.$_.'Name'}     = noiseText(5,10);
    $pc->{'classAbility'.$_.'Type'}     = noiseText(2,5);
    $pc->{'classAbility'.$_.'Lv'}       = noiseText(1);
    $pc->{'classAbility'.$_.'Timing'}   = noiseText(4,7);
    $pc->{'classAbility'.$_.'Check'}    = noiseText(2,6);
    $pc->{'classAbility'.$_.'Dfclty'}   = noiseText(1,2);
    $pc->{'classAbility'.$_.'Target'}   = noiseText(2,5);
    $pc->{'classAbility'.$_.'Range'}    = noiseText(2,3);
    $pc->{'classAbility'.$_.'Cost'}     = noiseText(1,2);
    $pc->{'classAbility'.$_.'MC'}       = noiseText(1);
    $pc->{'classAbility'.$_.'Note'}     = noiseText(10,20);
  }
  $pc->{worksAbilityNum} = int(rand 2) + 2;
  foreach(1..$pc->{worksAbilityNum}){
    $pc->{'worksAbility'.$_.'Name'}     = noiseText(5,10);
    $pc->{'worksAbility'.$_.'Type'}     = noiseText(2,5);
    $pc->{'worksAbility'.$_.'Lv'}       = noiseText(1);
    $pc->{'worksAbility'.$_.'Timing'}   = noiseText(4,7);
    $pc->{'worksAbility'.$_.'Check'}    = noiseText(2,6);
    $pc->{'worksAbility'.$_.'Dfclty'}   = noiseText(1,2);
    $pc->{'worksAbility'.$_.'Target'}   = noiseText(2,5);
    $pc->{'worksAbility'.$_.'Range'}    = noiseText(2,3);
    $pc->{'worksAbility'.$_.'Cost'}     = noiseText(1,2);
    $pc->{'worksAbility'.$_.'Note'}     = noiseText(10,20);
  }
  $pc->{magicNum} = 0;
  
  foreach ('Main','Sub','Other','Total'){
    $pc->{"weapon${_}Name"}   = noiseText(4,8);
    $pc->{"weapon${_}Type"}   = noiseText(1);
    $pc->{"weapon${_}Weight"} = noiseText(1);
    $pc->{"weapon${_}Skill"}  = noiseText(1);
    $pc->{"weapon${_}Acc"}    = noiseText(1);
    $pc->{"weapon${_}Atk"}    = noiseText(1);
    $pc->{"weapon${_}Init"}   = noiseText(1);
    $pc->{"weapon${_}Move"}   = noiseText(1);
    $pc->{"weapon${_}Range"}  = noiseText(1);
    $pc->{"weapon${_}Guard"}  = noiseText(1);
    $pc->{"weapon${_}Note"}   = noiseText(6,12);
    
    $pc->{"armor${_}Name"}   = noiseText(4,8);
    $pc->{"armor${_}Type"}   = noiseText(1);
    $pc->{"armor${_}Weight"} = noiseText(1);
    $pc->{"armor${_}Eva"}    = noiseText(1);
    $pc->{"armor${_}Def"}    = noiseText(8);
    $pc->{"armor${_}Init"}   = noiseText(1);
    $pc->{"armor${_}Move"}   = noiseText(1);
    $pc->{"armor${_}Range"}  = noiseText(1);
    $pc->{"armor${_}Guard"}  = noiseText(1);
    $pc->{"armor${_}Note"}   = noiseText(6,12);
  }
  $pc->{itemNum} = 0;
  delete $pc->{$_} foreach (grep { /^vehicle/ } keys %pc);


  $pc->{historyNum} = 0;
  $pc->{history0Result}   = noiseText(1,3);
}

### 所属国 --------------------------------------------------
if($pc{countryURL}){
  $SHEET->param(country => "<a href=\"$pc{countryURL}\">$pc{country}</a>");
}
### 因縁 --------------------------------------------------
{
  my @row;
  foreach (1..5){
    push(@row, {
      NAME     => $pc{"bond${_}Name"},
      RELATION => $pc{"bond${_}Relation"},
      EMOMAIN  => $pc{"bond${_}EmotionMain"},
      EMOSUB   => $pc{"bond${_}EmotionSub"},
    });
  }
  $SHEET->param(Bonds => \@row);
}
### 能力値 --------------------------------------------------
foreach ('Hp','Mp','Fate','Init','Move'){
  $SHEET->param("stt${_}Mod" => '<span class="small">+'.$pc{"stt${_}Mod"}.'=</span>') if $pc{"stt${_}Mod"};
}
### 技能 --------------------------------------------------
my %skillLv;
{
  my @columns;
  foreach my $stt ('Str','Ref','Per','Int','Mnd','Emp'){
    my @rows;
    my $i = 1;
    foreach my $label (@{$set::skill{$stt}}){
      $skillLv{$label.$pc{"skill${stt}${i}LabelBranch"}} = $pc{"skill${stt}${i}Lv"};
      push(@rows, {
        LABEL => $label.$pc{"skill${stt}${i}LabelBranch"},
        LV => ('●' x $pc{"skill${stt}${i}Lv"}).'<s>'.('○' x (5-$pc{"skill${stt}${i}Lv"})).'</s>',
      });
      $i++;
    }
    push(@columns, {Rows => \@rows});
  }
  $SHEET->param(Skills => \@columns);
}
### 特技・魔法 --------------------------------------------------
sub renderType {
  my $text = shift;
  $text =~ s{[(（)](.+?)[）)]}{<span class="small">（$1）</small>}g;
  return $text;
}
sub renderTiming {
  my $text = shift;
  $text =~ s#([^<])[／\/]#$1<hr class="dotted">#g;
  $text =~ s#(ムーブ|メジャー|マイナー)(アクション)?#<span class="thin">$1<wbr>アクション</span>#g;
  $text =~ s#リアク?(ション)?#<span class="thin">リアクション</span>#g;
  $text =~ s#(セットアップ|クリンナップ)(プロセス)?#<span class="thiner">$1<wbr>プロセス</span>#g;
  $text =~ s#(?:DR|ダメージロール)の?(直[前後])#<span class="thin">ダメージロール<wbr>の$1</span>#g;
  $text =~ s#(?:ダイスロール)の?(直[前後])#<span class="thin">ダイスロール<wbr>の$1</span>#g;
  $text =~ s#(魔法使用)の?(直[前後])#<span class="thin">$1<wbr>の$2</span>#g;
  $text =~ s#(判定|攻撃)の?(直[前後])#$1の$2#g;
  return $text;
}
sub renderCheck {
  my $text = shift;
  $text =~ s{〈.+?〉}{<span>$&</span>}g;
  return $text;
}
sub renderTarget {
  my $text = shift;
  if(length($text) >= 5){ $text = "<span class='thin'>$text</span>" }
  return $text;
}
sub renderRange {
  my $text = shift;
  if($text eq "効果参照"){ $text =~ s{効果参照}{<span class='thinest'>$&</span>}g; }
  elsif(length($text) >= 5){ $text = "<span class='thinest'>$text</span>" }
  return $text;
}
sub renderDfclty {
  my $text = shift;
  $text =~ s{効果参照}{<span class='thin'>$&</span>}g;
  $text =~ s{[0-9]+／対決}{<span class='thinest'>$&</span>}g;
  return $text;
}
sub renderCost {
  my $text = shift;
  $text =~ s{効果参照}{<span class='thinest small'>$&</span>}g;
  return $text;
}
### クラス特技 --------------------------------------------------
{
  my @row;
  foreach (1..$pc{classAbilityNum}){
    next if (!existsRow "classAbility${_}",'Name','Lv');
    push(@row, {
      'NAME'     => $pc{"classAbility${_}Name"},
      'TYPE'     => renderType($pc{"classAbility${_}Type"}),
      'LV'       => $pc{"classAbility${_}Lv"},
      'TIMING'   => renderTiming($pc{"classAbility${_}Timing"}),
      'CHECK'    => renderCheck($pc{"classAbility${_}Check"}),
      'TARGET'   => renderTarget($pc{"classAbility${_}Target"}),
      'RANGE'    => renderRange($pc{"classAbility${_}Range"}),
      'DFCLTY'   => renderDfclty($pc{"classAbility${_}Dfclty"}),
      'COST'     => renderCost($pc{"classAbility${_}Cost"}),
      'MC'       => $pc{"classAbility${_}MC"},
      'NOTE'     => $pc{"classAbility${_}Note"},
    });
  }
  $SHEET->param(ClassAbilities => \@row);
}
### ワークス特技 --------------------------------------------------
{
  my @row;
  foreach (1..$pc{classAbilityNum}){
    next if (!existsRow "worksAbility${_}",'Name','Lv');
    push(@row, {
      'NAME'     => $pc{"worksAbility${_}Name"},
      'TYPE'     => renderType($pc{"worksAbility${_}Type"}),
      'LV'       => $pc{"worksAbility${_}Lv"},
      'TIMING'   => renderTiming($pc{"worksAbility${_}Timing"}),
      'CHECK'    => renderCheck($pc{"worksAbility${_}Check"}),
      'TARGET'   => renderTarget($pc{"worksAbility${_}Target"}),
      'RANGE'    => renderRange($pc{"worksAbility${_}Range"}),
      'DFCLTY'   => renderDfclty($pc{"worksAbility${_}Dfclty"}),
      'COST'     => renderCost($pc{"worksAbility${_}Cost"}),
      'NOTE'     => $pc{"worksAbility${_}Note"},
    });
  }
  $SHEET->param(WorksAbilities => \@row);
}
### 魔法 --------------------------------------------------
{
  my @row;
  foreach (1..$pc{magicNum}){
    next if (!existsRow "magic${_}",'Name','Lv');
    push(@row, {
      'NAME'     => $pc{"magic${_}Name"},
      'TYPE'     => renderType($pc{"magic${_}Type"}),
      'LV'       => $pc{"magic${_}Lv"},
      'DURATION' => renderDuration($pc{"magic${_}Duration"}),
      'TIMING'   => renderTiming($pc{"magic${_}Timing"}),
      'CHECK'    => renderCheck($pc{"magic${_}Check"}),
      'TARGET'   => renderTarget($pc{"magic${_}Target"}),
      'RANGE'    => renderRange($pc{"magic${_}Range"}),
      'DFCLTY'   => renderDfclty($pc{"magic${_}Dfclty"}),
      'COST'     => renderCost($pc{"magic${_}Cost"}),
      'MC'       => $pc{"magic${_}MC"},
      'NOTE'     => $pc{"magic${_}Note"},
    });
  }
  $SHEET->param(Magics => \@row);
}
sub renderDuration {
  my $text = shift;
  if(length($text) >= 4){ $text = "<span class='thinest'>$text</span>" }
  return $text;
}

### 装備品 --------------------------------------------------
my %equipCategory = ( Main=>'メイン',Sub=>'サブ',Other=>'その他',Total=>'合計' );
### 武器 --------------------------------------------------
{
  my @row;
  foreach ('Main','Sub','Other','Total'){
    next if(!existsRow "weapon${_}",'Name','Type','Weight','Skill','Acc','Atk','Init','Move','Range','Guard','Note');
    push(@row, {
      'ID'       => $_,
      'CATEGORY' => $equipCategory{$_},
      'NAME'     => $pc{"weapon${_}Name"},
      'TYPE'     => $pc{"weapon${_}Type"},
      'WEIGHT'   => $pc{"weapon${_}Weight"},
      'SKILL'    => $pc{"weapon${_}Skill"},
      'ACC'      => $pc{"weapon${_}Acc"},
      'ATK'      => $pc{"weapon${_}Atk"},
      'INIT'     => $pc{"weapon${_}Init"},
      'MOVE'     => $pc{"weapon${_}Move"},
      'RANGE'    => $pc{"weapon${_}Range"},
      'GUARD'    => $pc{"weapon${_}Guard"},
      'NOTE'     => $pc{"weapon${_}Note"},
    });
  }
  $SHEET->param(Weapons => \@row);
}
### 防具 --------------------------------------------------
{
  my @row;
  foreach ('Main','Sub','Other','Total'){
    if(!$pc{forbiddenMode} && existsRow("armor${_}Def",'Weapon','Fire','Shock','Internal')){
      $pc{"armor${_}Def"} =
        '<span>'.$pc{"armor${_}DefWeapon"  }.'</span>/'.
        '<span>'.$pc{"armor${_}DefFire"    }.'</span>/'.
        '<span>'.$pc{"armor${_}DefShock"   }.'</span>/'.
        '<span>'.$pc{"armor${_}DefInternal"}.'</span>';
    }
    next if(!existsRow "armor${_}",'Name','Type','Weight','Eva','Def','Init','Move','Note');
    push(@row, {
      'ID'       => $_,
      'CATEGORY' => $equipCategory{$_},
      'NAME'     => $pc{"armor${_}Name"},
      'TYPE'     => $pc{"armor${_}Type"},
      'WEIGHT'   => $pc{"armor${_}Weight"},
      'EVA'      => $pc{"armor${_}Eva"},
      'DEF'      => $pc{"armor${_}Def"},
      'INIT'     => $pc{"armor${_}Init"},
      'MOVE'     => $pc{"armor${_}Move"},
      'NOTE'     => $pc{"armor${_}Note"},
    });
  }
  $SHEET->param(Armors => \@row);
}
### 乗騎 --------------------------------------------------
{
  $pc{vehicleTotalName} = '装備品との合計';
  my @row;
  foreach (1,'Total'){
    if(existsRowStrict("vehicle1Def",'Weapon','Fire','Shock','Internal')){
      $pc{"vehicle${_}Def"} =
        '<span>'.$pc{"vehicle${_}DefWeapon"  }.'</span>/'.
        '<span>'.$pc{"vehicle${_}DefFire"    }.'</span>/'.
        '<span>'.$pc{"vehicle${_}DefShock"   }.'</span>/'.
        '<span>'.$pc{"vehicle${_}DefInternal"}.'</span>';
    }
    push(@row, {
      'ID'       => $_,
      'NAME'     => $pc{"vehicle${_}Name"},
      'TYPE'     => $pc{"vehicle${_}Type"},
      'ATK'      => $pc{"vehicle${_}Atk"},
      'ACC'      => $pc{"vehicle${_}Acc"},
      'EVA'      => $pc{"vehicle${_}Eva"},
      'DEF'      => $pc{"vehicle${_}Def"},
      'INIT'     => $pc{"vehicle${_}Init"},
      'MOVE'     => $pc{"vehicle${_}Move"},
      'NOTE'     => $pc{"vehicle${_}Note"},
    });
  }
  $SHEET->param(Vehicles => \@row);
}
if(existsRow("vehicle1",'Name','Atk','Acc','Eva','Def','Init','Move','Note')){
  $SHEET->param(displayVehicle => 1);
}
### アイテム --------------------------------------------------
{
  my @row;
  foreach (1..$pc{itemNum}){
    next if (!existsRow "item${_}",'Name','Quantity','Weight');
    push(@row, {
      NAME     => $pc{"item${_}Name"},
      WEIGHT   => $pc{"item${_}Weight"} || 0,
      QUANTITY => $pc{"item${_}Quantity"} || 0,
      NOTE     => $pc{"item${_}Note"},
    });
  }
  $SHEET->param(Items => \@row);
}
### 部隊 --------------------------------------------------
{
  my @row;
  foreach (1..$pc{forceNum}){
    next if (!existsRow "force$_",
      'Type',
      'Str','Ref','Per','Int','Mnd','Emp',
      'Hp','Init','Move',
      'Atk',
      'DefWeapon','DefFire','DefShock','DefInternal',
    );
    push(@row, {
      'NUM'         => $_,
      'CHECKED'     => $pc{forceLead} eq $_ ? 'checked' : '',
      'TYPE'        => $pc{"force${_}Type"},
      'LV'          => $pc{"force${_}Lv"},
      'MORALE'      => $pc{"force${_}Morale"},
      'STR'         => $pc{"force${_}Str"},
      'REF'         => $pc{"force${_}Ref"},
      'PER'         => $pc{"force${_}Per"},
      'INT'         => $pc{"force${_}Int"},
      'MND'         => $pc{"force${_}Mnd"},
      'EMP'         => $pc{"force${_}Emp"},
      'HP'          => $pc{"force${_}Hp"},
      'INIT'        => $pc{"force${_}Init"},
      'MOVE'        => $pc{"force${_}Move"},
      'ATK'         => $pc{"force${_}Atk"},
      'DEFWEAPON'   => $pc{"force${_}DefWeapon"},
      'DEFFIRE'     => $pc{"force${_}DefFire"},
      'DEFSHOCK'    => $pc{"force${_}DefShock"},
      'DEFINTERNAL' => $pc{"force${_}DefInternal"},
      'NOTE'        => $pc{"force${_}Note"},
    });
  }
  $SHEET->param(Forces => \@row);
}
### アクションセット --------------------------------------------------
my %skill2Stt;
foreach my $stt (keys %set::skill){
  foreach my $label (@{$set::skill{$stt}}){
    $skill2Stt{$label} = $stt;
  }
}
my %sttJ2E;
while (my ($key, $value) = each %set::sttE2J){
  $sttJ2E{$value} = $key
}
{
  my @row;
  foreach (1..$pc{actionSetNum}){
    next if (!existsRow "actionSet$_",'Name','Minor','Major','Other','Note');
    my $diceBase = $skillLv{$pc{"actionSet${_}Skill"}};
    my $stt = $pc{"actionSet${_}Check"} ? $sttJ2E{$pc{"actionSet${_}Check"}} : $skill2Stt{$pc{"actionSet${_}Skill"}};
    my $checkBase = $pc{"stt${stt}CheckTotal"};

    push(@row, {
      'NAME'   => $pc{"actionSet${_}Name"},
      'MINOR'  => $pc{"actionSet${_}Minor"},
      'MAJOR'  => $pc{"actionSet${_}Major"},
      'OTHER'  => $pc{"actionSet${_}Other"},
      'SKILL'  => $pc{"actionSet${_}Skill"},
      'DICE'   => $diceBase  . addNum($pc{"actionSet${_}Dice"}),
      'CHECK'  => $checkBase . addNum($pc{"actionSet${_}Mod"}),
      'STT'    => $stt,
      'DFCLTY' => $pc{"actionSet${_}Dfclty"},
      'TARGET' => $pc{"actionSet${_}Target"},
      'RANGE'  => $pc{"actionSet${_}Range"},
      'MC'     => $pc{"actionSet${_}MC"},
      'COST'   => $pc{"actionSet${_}Cost"},
      'DMG'    => $pc{"actionSet${_}Dmg"},
      'NOTE'   => $pc{"actionSet${_}Note"},
    });
  }
  $SHEET->param(ActionSets => \@row);
}
# リアクション
{
  my @row;
  foreach (1..$pc{reactionSetNum}){
    next if (!existsRow "reactionSet$_",'Name','Minor','Major','Other','Note');
    my $diceBase = $skillLv{$pc{"reactionSet${_}Skill"}};
    my $stt = $pc{"reactionSet${_}Check"} ? $sttJ2E{$pc{"reactionSet${_}Check"}} : $skill2Stt{$pc{"reactionSet${_}Skill"}};
    my $checkBase = $pc{"stt${stt}CheckTotal"};

    push(@row, {
      'NAME'    => $pc{"reactionSet${_}Name"},
      'REACTION'=> $pc{"reactionSet${_}Reaction"},
      'OTHER'   => $pc{"reactionSet${_}Other"},
      'SKILL'   => $pc{"reactionSet${_}Skill"},
      'DICE'    => $diceBase  . addNum($pc{"reactionSet${_}Dice"}),
      'CHECK'   => $checkBase . addNum($pc{"reactionSet${_}Mod"}),
      'STT'     => $stt,
      'DFCLTY'  => $pc{"reactionSet${_}Dfclty"},
      'MC'      => $pc{"reactionSet${_}MC"},
      'COST'    => $pc{"reactionSet${_}Cost"},
      'NOTE'    => $pc{"reactionSet${_}Note"},
    });
  }
  $SHEET->param(ReactionSets => \@row);
}
### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = "キャラクター作成（$pc{makeLv}レベル）";
$pc{history0Exp} = "―";
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
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、 ]+/$1　/g;
  foreach my $mem (split(/　/,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  $pc{'history'.$_.'Money'} = formatHistoryFigures($pc{'history'.$_.'Money'});
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
$SHEET->param(historyExpTotal   => commify $pc{historyExpTotal}   );
$SHEET->param(payment           => commify $pc{payment}           );
$SHEET->param(historyMoneyTotal => commify $pc{historyMoneyTotal} );

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "レベル:$pc{level}　クラス:$pc{class}　スタイル:$pc{style}　ワークス:$pc{works}　所属国:$pc{country}　性別:$pc{gender}　年齢:$pc{age}　身長:$pc{height}　体重:$pc{weight}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
