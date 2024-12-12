################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_class;
require $set::data_races;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  path => ['./', $::core_dir."/skin/gs", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  loop_context_vars => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### キャラクターデータ読み込み #######################################################################
our %pc = getSheetData();

### タグ置換前処理 ###################################################################################
### 閲覧禁止データ --------------------------------------------------
if($pc{forbidden} && !$pc{yourAuthor}){
  my $ver = $pc{ver};
  my $author = $pc{playerName};
  my $protect   = $pc{protect};
  my $forbidden = $pc{forbidden};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{characterName} = noiseText(6,14);
    $pc{group} = $pc{tags} = '';
      
    $pc{age}    = noiseText(1,2);
    $pc{gender} = noiseText(1,2);
    $pc{traits}     = noiseText(5,12);
    $pc{traitsHair} = noiseText(1,2);
    $pc{traitsEyes} = noiseText(1,2);
    
    $pc{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc{freeNote} .= '　'.noiseText(18,40)."\n";
    }
    $pc{freeHistory} = '';
  }
  
  $pc{race}     = noiseText(2,8);
  $pc{raceFree}     = '';
  $pc{faith}  = noiseText(2,4);

  $pc{rank} = noiseTextTag(noiseText(3,4)).'<div class="small">（第'.noiseTextTag(noiseText(1)).'位）</div>';

  $pc{careerOrigin} = noiseText(2,3);
  $pc{careerGenesis} = noiseText(2,3);
  $pc{careerEncounter} = noiseText(2,3);
  
  $pc{level}  = noiseText(1);
  
  $pc{expUsed}  = noiseText(3,5);
  $pc{expRest}  = noiseText(3,5);
  $pc{expTotal} = noiseText(3,5);
  $pc{adpUsed}  = noiseText(2,3);
  $pc{adpRest}  = noiseText(2,3);
  $pc{adpTotal} = noiseText(2,3);

  $pc{adventures} = noiseText(1);
  $pc{completed}  = noiseText(1);
  
  $pc{dodgeClass} = noiseText(2,4);
  $pc{blockClass} = noiseText(2,4);
  $pc{dodgeClassLv} = noiseText(1);
  $pc{blockClassLv} = noiseText(1);
  
  $pc{moneyAllCoins} = 0;
  $pc{money}   = noiseText(3,6);
  $pc{deposit} = noiseText(3,6);
  $pc{items} = '';
  foreach(1..int(rand 3)+6){
    $pc{items} .= noiseText(6,24)."\n";
  }
  $pc{cashbook} = '';
  
  $pc{historyNum} = 0;
  $pc{history0Exp}   = noiseText(1,3);
  $pc{history0Adp}   = noiseText(1,2);
  $pc{history0Money} = noiseText(1,3);
  
  $pc{ver} = $ver;
  $pc{playerName} = $author;
  $pc{protect} = $protect;
  $pc{forbidden} = $forbidden;
  $pc{forbiddenMode} = 1;
}

### その他 --------------------------------------------------
$SHEET->param(rawName => $pc{characterName} || ($pc{aka} ? "“$pc{aka}”" : ''));

### タグ置換 #########################################################################################
if($pc{ver}){
  foreach (keys %pc) {
    next if($_ =~ /^image/);
    if($_ =~ /^(?:items|freeNote|freeHistory|cashbook)$/){
      $pc{$_} = unescapeTagsLines($pc{$_});
    }
    $pc{$_} = unescapeTags $pc{$_};

    $pc{$_} = noiseTextTag $pc{$_} if $pc{forbiddenMode};
  }
}
else {
  $pc{freeNote} = $pc{freeNoteView} if $pc{freeNoteView};
}

### アップデート --------------------------------------------------
if($pc{ver}){
  %pc = data_update_chara(\%pc);
}

### カラー設定 --------------------------------------------------
setColors();

### 置換後出力 #######################################################################################
### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param(id => $::in{id});

if($::in{url}){
  $SHEET->param(convertMode => 1);
  $SHEET->param(convertUrl => $::in{url});
}

### キャラクター名 --------------------------------------------------
$SHEET->param(characterName => stylizeCharacterName $pc{characterName});

### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $::in{id}))[0];
  $SHEET->param(playerName => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{playerName}.'</a>');
}
### グループ --------------------------------------------------
if($::in{url}){
  $SHEET->param(group => '');
}
else {
  if(!$pc{group}) {
    $pc{group} = $set::group_default;
    $SHEET->param(group => $set::group_default);
  }
  foreach (@set::groups){
    if($pc{group} eq @$_[0]){
      $SHEET->param(groupName => @$_[2]);
      last;
    }
  }
}

### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{tags})){
  push(@tags, {
    "URL"  => uri_escape_utf8($_),
    "TEXT" => $_,
  });
}
$SHEET->param(Tags => \@tags);

### セリフ --------------------------------------------------
{
  my ($words, $x, $y) = stylizeWords($pc{words},$pc{wordsX},$pc{wordsY});
  $SHEET->param(words => $words);
  $SHEET->param(wordsX => $x);
  $SHEET->param(wordsY => $y);
}
### 種族名 --------------------------------------------------
{
  my %kana = (%data::padfoots, %data::beastbind);
  foreach('race','raceBase'){
    my @name = (split ':', $pc{$_});
    if($data::races{$name[0]}{kana}){
      $name[0] = "<ruby>$name[0]<rp>(<rt>$data::races{$name[0]}{kana}<rp>)</ruby>";
    }
    if($pc{$_.'Free'}){
      foreach my $kanji (keys %kana){
        $pc{$_.'Free'} =~ s|$kanji|<ruby>$kanji<rp>(<rt>$kana{$kanji}{kana}<rp>)</ruby>|;
      }
      if($pc{$_}){ $SHEET->param($_ => $pc{$_.'Free'}.'<span class="small">（'.join(':',@name).'）</span>') }
      else       { $SHEET->param($_ => $pc{$_.'Free'}) }
    }
    else {
      $SHEET->param($_ => join(':',@name));
    }
  }
}

### 等級 --------------------------------------------------
foreach my $data (@set::adventurer_rank){
  if($pc{rank} eq $data->[0]){
    $SHEET->param(rank => "$pc{rank}<span class=\"small\">($data->[1])</span>");
    last;
  }
}

### 経験点 --------------------------------------------------
foreach('expUsed','expTotal','expRest'){
  $pc{$_} = commify $pc{$_};
  $SHEET->param($_ => $pc{$_});
}
### 能力値 --------------------------------------------------
if($pc{forbiddenMode}) {
  foreach my $p ('Str','Psy','Tec','Int'){
    $SHEET->param("ability1${p}" => noiseTextTag noiseText(1) );
  }
  foreach my $s ('Foc','Edu','Ref'){
    $SHEET->param("ability2${s}" => noiseTextTag noiseText(1) );
    foreach my $p ('Str','Psy','Tec','Int'){
      $SHEET->param("ability${p}${s}" =>  noiseTextTag noiseText(1) );
    }
  }
}
else {
  foreach  ('1Str','1Psy','1Tec','1Int','2Foc','2Edu','2Ref'){
    my $mod = $pc{'ability'.$_.'Mod'} + ($_ =~ /$pc{ability1Bonus}$/ ? 1 : 0);
    $SHEET->param('ability'.$_.'Mod' => $mod ? addNum($mod)."=" : '');
  }
}

### 状態 --------------------------------------------------
if($pc{forbiddenMode}) {
  foreach(
    'Life','LifeX2','Move','Spell','Resist',
    'LifeDice','MoveDice','SpellDice',
    'MoveRace','SpellBase',
  ){
    $SHEET->param("status$_" => noiseTextTag noiseText(1) );
  }
}
else {
  foreach('Life','Move','Spell','Resist'){
    $SHEET->param('status'.$_.'Mod' => addNum($pc{'status'.$_.'Mod'}));
  }
}

### 職業 --------------------------------------------------
my @classes; my %classes; my $class_text;

if($pc{forbiddenMode}) {
  foreach (1..int(rand 3)+1){
    push(@classes, {
      NAME => noiseTextTag(noiseText(2,4)),
      LV   => noiseTextTag(noiseText(1)),
      EXP  => noiseTextTag(noiseText(3,4)),
    });
  }
  $class_text = noiseText(3,10);
}
else {
  foreach my $class (@data::class_names){
    my $id = $data::class{$class}{id};
    next if !$pc{'lv'.$id};
    my $kana = $data::class{$class}{kana};
    my $name = "<ruby>$class<rt>$kana</ruby>";
    if($class eq '神官' && $pc{faith}){
      $name .= '<span class="priest-faith'.(length($pc{faith}) > 12 ? ' narrow' : "").'">('.$pc{faith}.')</span>';
    }
    push(@classes, { "NAME" => $name, "LV" => $pc{'lv'.$id}, "EXP" => commify $pc{'expUsed'.$id} } );
    $classes{$class} = $pc{'lv'.$id};
  }
  @classes = sort{$b->{LV} <=> $a->{LV}} @classes;
  foreach my $key (sort {$classes{$b} <=> $classes{$a}} keys %classes){ $class_text .= ($class_text ? ',' : '').$key.$classes{$key}; }
}
$SHEET->param(Classes => \@classes);

### ルビチェック --------------------------------------------------
sub itemNameRubyCheck {
  my $name = shift;
  $name =~ s/^(魔法の)?(.+?)[（(]([ぁ-ゟァ-ヿ\-‐―－～=＝]+?)[)）](\[+＋][0-9]+)?$/$1<ruby>$2<rp>(<rt>$3<rp>)<\/ruby>$4/;
  return $name;
}
sub spellNameRubyCheck {
  my $name = shift;
  $name =~ s/^(.+?)[（(]([ぁ-ゟァ-ヿ\-‐―－～=＝]+?)[)）]$/<ruby>$1<rp>(<rt>$2<rp>)<\/ruby>$3/;
  return $name;
}

### 呪文 --------------------------------------------------
if(!$pc{forbiddenMode}){
  my @data;
  foreach my $name (grep { $data::class{$_}{type} =~ /spell/ } @data::class_names){
    my $id = $data::class{$name}{id};
    next if !$pc{'lv'.$id};
    push(@data, {
      BASE  => abilityToName($data::class{$name}{cast}),
      VALUE => $pc{'ability'.$data::class{$name}{cast}},
      CLASS => $name,
      LEVEL => $pc{'lv'.$id},
      TOTAL => $pc{'spellCast'.$id},
    } );
  }
  $SHEET->param(SpellCasters => \@data);
}

### 命中 --------------------------------------------------
if(!$pc{forbiddenMode}){
  my @attack;
  foreach my $name (grep { $data::class{$_}{type} =~ /warrior/ } @data::class_names){
    my $id    = $data::class{$name}{id};
    next if !$pc{'lv'.$id};
    push(@attack, {
      NAME   => $name,
      LV     => $pc{'lv'.$id},
      MELEE  => $pc{'hitScore'.$id.'Melee'},
      THROW  => $pc{'hitScore'.$id.'Throwing'},
      PROJ   => $pc{'hitScore'.$id.'Projectile'},
    } );
  }
  $SHEET->param(AttackClasses => \@attack);

  if($pc{hitScoreModName} || $pc{hitScoreModMelee} || $pc{hitScoreModThrowing} || $pc{hitScoreModProjectile}){
    $SHEET->param(existsHitScoreMod => 1);
  }
}

### 武器 --------------------------------------------------
my @weapons;
if($pc{forbiddenMode}){
  push(@weapons,{
    NAME     => noiseTextTag(noiseText(4,8)),
    REQD     => noiseTextTag(noiseText(1)),
    USAGE    => noiseTextTag(noiseText(2)),
    HITSCORE => noiseTextTag(noiseText(1)),
    POWER    => noiseTextTag(noiseText(3)),
    RANGE    => noiseTextTag(noiseText(2)),
    NOTE     => noiseTextTag(noiseText(4,8)),
  });
}
else {
  my $first = 1;
  foreach (1 .. $pc{weaponNum}){
    next if !existsRow "weapon$_",'Name','Type','Weight','Usage','Attr','HitMod','Power','PowerMod','Range','Note';
    my $rowspan = 1;
    for(my $num = $_+1; $num <= $pc{weaponNum}; $num++){
      last if $pc{'weapon'.$num.'NameOff'};
      last if $pc{'weapon'.$num.'Name'};
      last if !existsRow "weapon$_",'Name','Type','Weight','Usage','Attr','HitMod','Power','PowerMod','Range','Note';
      $rowspan++;
      $pc{'weapon'.$num.'NameOff'} = 1;
    }
    my $power = $pc{'weapon'.$_.'Power'}
      . addNum($pc{'lv'.$data::class{$pc{'weapon'.$_.'Class'}}{id}})
      . addNum($pc{'weapon'.$_.'PowerMod'});
    push(@weapons, {
      NAME     => itemNameRubyCheck($pc{'weapon'.$_.'Name'}),
      ROWSPAN  => $rowspan,
      NAMEOFF  => $pc{'weapon'.$_.'NameOff'},
      TYPE     => $pc{'weapon'.$_.'Type'},
      WEIGHT   => $pc{'weapon'.$_.'Weight'},
      USAGE    => $pc{'weapon'.$_.'Usage'}.'／'.$pc{'weapon'.$_.'Attr'},
      HITMOD   => addNum($pc{'weapon'.$_.'HitMod'}),
      HITTOTAL => $pc{'weapon'.$_.'HitTotal'},
      POWER    => $power,
      RANGE    => $pc{'weapon'.$_.'Range'},
      NOTE     => $pc{'weapon'.$_.'Note'},
      CLOSE    => ($pc{'weapon'.$_.'NameOff'} || $first ? 0 : 1),
    } );
    $first = 0;
  }
}
$SHEET->param(Weapons => \@weapons);


### 鎧 --------------------------------------------------
if($pc{forbiddenMode}){
  my @armours;
  foreach(1){
    push(@armours, {
      NAME    => noiseTextTag(noiseText(4,8)),
      TYPE    => noiseTextTag(noiseText(1)),
      DODGE   => noiseTextTag(noiseText(1)),
      ARMOR   => noiseTextTag(noiseText(1)),
      STEALTH => noiseTextTag(noiseText(2)),
      MOVE    => noiseTextTag(noiseText(1)),
      NOTE    => noiseTextTag(noiseText(4,8)),
    });
  }
  $SHEET->param(Armours => \@armours);
}
else {
  if($pc{dodgeModName} || $pc{dodgeModValue} || $pc{MoveModValue}){
    $SHEET->param(existsDodgeMod => 1);
  }

  my @armours;
  foreach (1){
    next if !existsRow "armor$_",'Name','Dodge','Armor';
    my $type = $pc{'armor'.$_.'Type'};
       $type .= "($pc{'armor'.$_.'Material'})" if $pc{'armor'.$_.'Material'};
       $type .= "／$pc{'armor'.$_.'Weight'}"   if $pc{'armor'.$_.'Weight'};
    push(@armours, {
      NAME       => itemNameRubyCheck($pc{'armor'.$_.'Name'}),
      TYPE       => $pc{'armor'.$_.'Type'}.($pc{'armor'.$_.'Material'}?"($pc{'armor'.$_.'Material'})":''),
      WEIGHT     => $pc{'armor'.$_.'Weight'},
      DODGEMOD   => addNum($pc{'armor'.$_.'DodgeMod'}) || '+0',
      DODGETOTAL => $pc{'armor'.$_.'DodgeTotal'},
      ARMOR      => $pc{'armor'.$_.'Armor'},
      STEALTH    => $pc{'armor'.$_.'Stealth'},
      MOVEMOD    => addNum($pc{'armor'.$_.'MoveMod'}) || '+0',
      MOVETOTAL  => $pc{'armor'.$_.'MoveTotal'},
      NOTE       => $pc{'armor'.$_.'Note'},
    } );
  }
  $SHEET->param(Armours => \@armours);
}


### 盾 --------------------------------------------------
if($pc{forbiddenMode}){
  my @shields;
  foreach(1){
    push(@shields, {
      NAME       => noiseTextTag(noiseText(4,8)),
      TYPE       => noiseTextTag(noiseText(1)),
      BLOCKMOD   => noiseTextTag(noiseText(1)),
      BLOCKTOTAL => noiseTextTag(noiseText(1)),
      ARMOR      => noiseTextTag(noiseText(1)),
      STEALTH    => noiseTextTag(noiseText(2)),
      NOTE       => noiseTextTag(noiseText(4,8)),
    });
  }
  $SHEET->param(Shields => \@shields);
}
else {
  if($pc{blockModName} || $pc{blockModValue}){
    $SHEET->param(existsBlockMod => 1);
  }

  my @shields;
  foreach (1){
    next if !existsRow "shield$_",'Name','Block','Armor';
    push(@shields, {
      NAME       => itemNameRubyCheck($pc{'shield'.$_.'Name'}),
      TYPE       => $pc{'shield'.$_.'Type'}.($pc{'shield'.$_.'Material'}?"($pc{'shield'.$_.'Material'})":''),
      WEIGHT     => $pc{'shield'.$_.'Weight'},
      BLOCKMOD   => addNum($pc{'shield'.$_.'BlockMod'}) || '+0',
      BLOCKTOTAL => $pc{'shield'.$_.'BlockTotal'},
      ARMOR      => addNum($pc{'shield'.$_.'Armor'}) || '+0',
      ARMORTOTAL => $pc{'shield'.$_.'ArmorTotal'},
      STEALTH    => $pc{'shield'.$_.'Stealth'},
      NOTE       => $pc{'shield'.$_.'Note'},
    } );
  }
  $SHEET->param(Shields => \@shields);
}

### 冒険者技能 --------------------------------------------------
if($pc{forbiddenMode}){
  my @skills;
  foreach(1..int(rand 4) + 3){
    push(@skills, {
      ADP   => noiseTextTag(noiseText(1)),
      NAME  => noiseTextTag(noiseText(2,6)),
      GRADE => noiseTextTag(noiseText(1)),
      NOTE  => noiseTextTag(noiseText(8,12)),
      PAGE  => noiseTextTag(noiseText(2)),
    });
  }
  $SHEET->param(Skills => \@skills);
}
else {
  my @skills;
  foreach (1..$pc{skillNum}){
    next if !existsRow "skill$_",'Adp','Name','Note';
    push(@skills, {
      ADP   => $pc{'skill'.$_.'Adp'},
      NAME  => $pc{'skill'.$_.'Name'},
      GRADE => $pc{'skill'.$_.'Grade'},
      NOTE  => $pc{'skill'.$_.'Note'},
      PAGE  => $pc{'skill'.$_.'Page'},
    } );
  }
  $SHEET->param(Skills => \@skills);
}

### 一般技能 --------------------------------------------------
if($pc{forbiddenMode}){
  my @skills;
  foreach(1..int(rand 4) + 3){
    push(@skills, {
      ADP   => noiseTextTag(noiseText(1)),
      NAME  => noiseTextTag(noiseText(2,6)),
      GRADE => noiseTextTag(noiseText(1)),
      NOTE  => noiseTextTag(noiseText(8,12)),
      PAGE  => noiseTextTag(noiseText(2)),
    });
  }
  $SHEET->param(GeneralSkills => \@skills);
}
else {
  my @skills;
  foreach (1..$pc{generalSkillNum}){
    next if !existsRow "generalSkill$_",'Adp','Name','Note';
    push(@skills, {
      ADP   => $pc{'generalSkill'.$_.'Adp'},
      NAME  => $pc{'generalSkill'.$_.'Name'},
      GRADE => $pc{'generalSkill'.$_.'Grade'},
      NOTE  => $pc{'generalSkill'.$_.'Note'},
      PAGE  => $pc{'generalSkill'.$_.'Page'},
    } );
  }
  $SHEET->param(GeneralSkills => \@skills);
}

### 呪文 --------------------------------------------------
if($pc{forbiddenMode}){
}
else {
  my @spells;
  foreach (1..$pc{spellNum}){
    next if !existsRow "spell$_",'Name','Note';
    push(@spells, {
      NAME   => spellNameRubyCheck($pc{'spell'.$_.'Name'}),
      SYSTEM => $pc{'spell'.$_.'System'},
      TYPE   => "$pc{'spell'.$_.'Type'}($pc{'spell'.$_.'Attr'})",
      DFCLT  => $pc{'spell'.$_.'Dfclt'},
      NOTE   => $pc{'spell'.$_.'Note'},
      PAGE   => $pc{'spell'.$_.'Page'},
    } );
  }
  $SHEET->param(Spells => \@spells);
}

### 武技 --------------------------------------------------
if($pc{forbiddenMode}){
}
else {
  my @arts;
  foreach (1..$pc{artsNum}){
    next if !existsRow "arts$_",'Name','Note';
    push(@arts, {
      NAME   => $pc{'arts'.$_.'Name'},
      WEAPON => $pc{'arts'.$_.'Weapon'},
      SKILL  => $pc{'arts'.$_.'Skill'},
      COST   => $pc{'arts'.$_.'Cost'},
      TERMS  => $pc{'arts'.$_.'Terms'},
      NOTE   => $pc{'arts'.$_.'Note'},
      PAGE   => $pc{'arts'.$_.'Page'},
    } );
  }
  $SHEET->param(Arts => \@arts);
}

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = 'キャラクター作成';
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Completed','Exp','Adp','Money','Gm','Member','Note');
  $h_num++ if $pc{'history'.$_.'Gm'} || $pc{'history'.$_.'Completed'};
  if ($set::log_dir && $pc{'history'.$_.'Date'} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
    my $room = $1;
    (my $date = $pc{'history'.$_.'Date'}) =~ s/[\-\/]//g;
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
  $pc{'history'.$_.'Exp'}   = formatHistoryFigures($pc{'history'.$_.'Exp'});
  $pc{'history'.$_.'Money'} = formatHistoryFigures($pc{'history'.$_.'Money'});
  
  my $completed = ($pc{'history'.$_.'Completed'} > 0) ? '<span class="completed">達成<span>'
                : ($pc{'history'.$_.'Completed'} < 0) ? '<span class="failed">失敗<span>'
                : '';
  if(!$_){
    if($pc{history0Adventures} || $pc{history0Completed}){
      $completed = ($pc{history0Adventures} || 0).' / '.($pc{history0Completed} || 0)
    }
    else { $completed = '―'; }
  }
  push(@history, {
    NUM    => ($completed || $pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE   => $pc{'history'.$_.'Date'},
    TITLE  => $pc{'history'.$_.'Title'},
    COMP   => $completed,
    EXP    => $pc{'history'.$_.'Exp'},
    ADP    => $pc{'history'.$_.'Adp'},
    MONEY  => $pc{'history'.$_.'Money'},
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);
$SHEET->param(historyExpTotal   => commify $pc{historyExpTotal}   );
$SHEET->param(historyMoneyTotal => commify $pc{historyMoneyTotal} );


### 銀貨 --------------------------------------------------
$pc{cashbook} =~ s/(:(?:\:|&lt;|&gt;))((?:[\+\-\*\/]?[0-9,]+)+)/$1.cashCheck($2)/eg;
  $SHEET->param(cashbook => $pc{cashbook});
sub cashCheck(){
  my $text = shift;
  my $num = s_eval($text);
  if   ($num > 0) { return '<b class="cash plus">'.$text.'</b>'; }
  elsif($num < 0) { return '<b class="cash minus">'.$text.'</b>'; }
  else { return '<b class="cash">'.$text.'</b>'; }
}

### バックアップ --------------------------------------------------
if($::in{id}){
  my($selected, $list) = getLogList($set::char_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{yourAuthor} || $pc{protect} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{forbidden} eq 'all' && $pc{forbiddenMode}){
  $SHEET->param(titleName => '非公開データ');
}
else {
  $SHEET->param(titleName => removeTags removeRuby($pc{characterName}||"“$pc{aka}”"));
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
if($pc{image}) { $SHEET->param(ogImg => $pc{imageURL}); }
$SHEET->param(ogDescript => removeTags "種族:$pc{race}　性別:$pc{gender}　年齢:$pc{age}　職業:${class_text}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'gs');
$SHEET->param(sheetType => 'chara');
$SHEET->param(generateType => 'GoblinSlayerPC');
$SHEET->param(defaultImage => $::core_dir.'/skin/gs/img/default_pc.png');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{modeDownload}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './', });
  if($::in{url}){
    push(@menu, { TEXT => 'コンバート', TYPE => "href", VALUE => "./?mode=convert&url=$::in{url}" });
  }
  else {
    if($pc{logId}){
      push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => 'loglistOn()', });
      if($pc{reqdPassword}){ push(@menu, { TEXT => '復元', TYPE => "onclick", VALUE => "editOn()", }); }
      else                   { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}&log=$pc{logId}", }); }
    }
    else {
      if(!$pc{forbiddenMode}){
        push(@menu, { TEXT => 'パレット', TYPE => "onclick", VALUE => "chatPaletteOn()",   });
        push(@menu, { TEXT => '出力'    , TYPE => "onclick", VALUE => "downloadListOn()",  });
        push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => "loglistOn()",      });
      }
      if($pc{reqdPassword}){ push(@menu, { TEXT => '編集', TYPE => "onclick", VALUE => "editOn()", }); }
      else                   { push(@menu, { TEXT => '編集', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}", }); }
    }
  }
}
$SHEET->param(Menu => sheetMenuCreate @menu);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
if($pc{modeDownload}){
  if($pc{forbidden} && $pc{yourAuthor}){ $SHEET->param(forbidden => ''); }
  print downloadModeSheetConvert $SHEET->output;
}
else {
  print $SHEET->output;
}

1;