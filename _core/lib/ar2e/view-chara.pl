################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_class;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  path => ['./', $::core_dir."/skin/ar2e", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  loop_context_vars => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### キャラクターデータ読み込み #######################################################################
our %pc = getSheetData();

### タグ置換前処理 ###################################################################################
### 閲覧禁止データ --------------------------------------------------
if($pc{forbidden} && !$pc{yourAuthor}){
  my $author = $pc{playerName};
  my $protect   = $pc{protect};
  my $forbidden = $pc{forbidden};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{aka} = '';
    $pc{characterName} = noiseText(6,14);
    $pc{group} = $pc{areaTags} = $pc{tags} = '';
    
    $pc{age}    = noiseText(1,2);
    $pc{gender} = noiseText(1,2);

    $pc{guildName} = noiseText(4,12);
    $pc{guildMaster} = noiseText(3,12);

    $pc{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc{freeHistory} = '';
  }

  $pc{level}        = noiseText(1);
  
  $pc{race}         = noiseText(3,8);
  $pc{classMain}    = noiseText(3,8);
  $pc{classSupport} = noiseText(3,8);
  $pc{classMainLv1}    = noiseText(3,8);
  $pc{classSupportLv1} = noiseText(3,8);
  $pc{classTitle}   = noiseText(3,8);

  $pc{homeArea} = noiseText(5,10);
  foreach my $name ('Origin','Experience','Motive'){
    $pc{'lifepath'.$name} = noiseText(2,4);
    $pc{'lifepath'.$name.'Note'} = noiseText(8,30);
  }

  foreach my $name ('Str','Dex','Agi','Int','Sen','Mnd','Luk'){
    $pc{'stt'.$name.'Base'}    = noiseText(1);
    $pc{'stt'.$name.'Bonus'}   = noiseText(1);
    $pc{'stt'.$name.'Main'}    = noiseText(1);
    $pc{'stt'.$name.'Support'} = noiseText(1);
    $pc{'stt'.$name.'Add'}     = noiseText(1);
    $pc{'stt'.$name.'Total'}   = noiseText(1);
    $pc{'roll'.$name.'Add'}    = noiseText(1);
    $pc{'roll'.$name}          = noiseText(1);
    $pc{'roll'.$name.'Dice'}   = noiseText(1);
  }
  foreach my $stt ('hp','mp','fate'){
    $pc{$stt.'Total'}  = noiseText(1);
    $pc{$stt.'Add'}  = '';
  }
  $pc{fateLimit} = noiseText(1);
  $pc{weightLimitWeapon} = noiseText(1);
  $pc{weightLimitArmour} = noiseText(1);
  $pc{weightLimitItems}  = noiseText(1);

  foreach my $part ('HandR','HandL','Head','Body','Sub','Other','Total'){
    $pc{"armament${part}Name"} = noiseText(3,12);
    foreach my $stt ('Weight','Acc','Atk','Eva','Def','MDef','Ini','Move'){
      $pc{"armament${part}${stt}"} = noiseText(1);
    }
    $pc{"armament${part}Range"} = noiseText(2);
    $pc{"armament${part}Note"} = noiseText(4,14);
  }
  $pc{armamentTotalWeightWeapon} = noiseText(1);
  $pc{armamentTotalWeightArmour} = noiseText(1);
  $pc{armamentTotalAccR} = noiseText(1);
  $pc{armamentTotalAccL} = noiseText(1);
  $pc{armamentTotalAtkR} = noiseText(1);
  $pc{armamentTotalAtkL} = noiseText(1);
  foreach my $part ('Skill','Other','Total','Dice'){
    $pc{"battle${part}Name"} = noiseText(3,12);
    foreach my $stt ('Weight','Acc','Atk','Eva','Def','MDef','Ini','Move'){
      $pc{"battle${part}${stt}"} = noiseText(1);
      $pc{"battle${part}${stt}"} = noiseText(1);
    }
    $pc{"battle${part}Range"} = noiseText(2);
    $pc{"battle${part}Note"} = noiseText(4,14);
  }
  foreach my $roll ('TrapDetect','TrapRelease','DangerDetect','EnemyLore','Appraisal','Magic','Song','Alchemy'){
      $pc{"roll${roll}"} = noiseText(1);
      $pc{"roll${roll}Skill"} = noiseText(1);
      $pc{"roll${roll}Other"} = noiseText(1);
      $pc{"roll${roll}Dice"} = noiseText(1);
  }
  $pc{geisesNum} = int(rand 2);
  foreach(1..$pc{geisesNum}){
    $pc{'geis'.$_.'Name'}      = noiseText(5,10);
    $pc{'geis'.$_.'Num'}       = noiseText(1,2);
    $pc{'geis'.$_.'Note'}      = noiseText(10,20);
  }
  $pc{connectionsNum} = int(rand 3) + 1;
  foreach(1..$pc{connectionsNum}){
    $pc{'connection'.$_.'Name'}      = noiseText(5,10);
    $pc{'connection'.$_.'Relation'}  = noiseText(2,4);
    $pc{'connection'.$_.'Note'}      = noiseText(10,20);
  }
  
  $pc{lvUp1SttStr} = 0;
  $pc{lvUp1SttDex} = 0;
  $pc{lvUp1SttAgi} = 0;
  $pc{lvUp1SttInt} = 0;
  $pc{lvUp1SttSen} = 0;
  $pc{lvUp1SttMnd} = 0;
  $pc{lvUp1SttLuk} = 0;
  $pc{lvUp1Class} = noiseText(5,10);
  foreach(1..6){ $pc{"lvUp1Skill".$_} = noiseText(5,10); }

  $pc{skillsNum} = int(rand 3) + 8;
  foreach(1..$pc{skillsNum}){
    $pc{'skill'.$_.'Type'}    = noiseText(2,5);
    $pc{'skill'.$_.'Category'}= noiseText(2);
    $pc{'skill'.$_.'Name'}    = noiseText(5,10);
    $pc{'skill'.$_.'Lv'}      = noiseText(1);
    $pc{'skill'.$_.'Timing'}  = noiseText(4,6);
    $pc{'skill'.$_.'Roll'}    = noiseText(2,5);
    $pc{'skill'.$_.'Target'}  = noiseText(2,5);
    $pc{'skill'.$_.'Range'}   = noiseText(2,3);
    $pc{'skill'.$_.'Cost'}    = noiseText(1);
    $pc{'skill'.$_.'Reqd'}    = noiseText(0,8);
    $pc{'skill'.$_.'Note'}    = noiseText(10,20);
  }
  $pc{skillLvTotal} = noiseText(1);
  $pc{skillLvLimit} = noiseText(1);
  $pc{skillLvLimitAdd} = '';
  $pc{skillLvGeneral} = noiseText(1);

  $pc{items} = '';
  foreach(1..int(rand 10)+6){
    $pc{items} .= noiseText(6,24)."<br>";
  }
  $pc{weightItems}   = noiseText(1);
  
  $pc{money}   = noiseText(3,6);
  $pc{deposit} = noiseText(3,6);
  $pc{cashbook} = '';
  
  $pc{expUsed}  = noiseText(1,3);
  $pc{expRest}  = noiseText(1,3);
  $pc{expTotal} = noiseText(1,3);

  $pc{historyNum} = 0;
  $pc{history0Exp}   = noiseText(1,3);
  $pc{history0Honor} = noiseText(1,2);
  $pc{history0Money} = noiseText(2,4);
  
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
    $pc{$_} = unescapeTags($pc{$_});

    $pc{$_} = noiseTextTag $pc{$_} if $pc{forbiddenMode};
  }
}
else {
  $pc{items} = $pc{itemsView} if $pc{itemsView};
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
$SHEET->param(characterName => stylizeCharacterName $pc{characterName},$pc{characterNameRuby});
$SHEET->param(aka => stylizeCharacterName $pc{aka},$pc{akaRuby});

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
    URL  => uri_escape_utf8($_),
    TEXT => $_,
  });
}
$SHEET->param(Tags => \@tags);

### エリア --------------------------------------------------
my @areatags;
foreach(split(/ /, $pc{areaTags})){
  push(@areatags, { "TEXT" => $_, });
}
$SHEET->param(AreaTags => \@areatags);

### セリフ --------------------------------------------------
{
  my ($words, $x, $y) = stylizeWords($pc{words},$pc{wordsX},$pc{wordsY});
  $SHEET->param(words => $words);
  $SHEET->param(wordsX => $x);
  $SHEET->param(wordsY => $y);
}
### 種族名 --------------------------------------------------
if($pc{race} eq 'free'){ $pc{race} = $pc{raceFree} }
my $race_length = length($pc{race});
$pc{race} =~ s/(（.*）)/<span class="small">$1<\/span>/g;
if($race_length > 10){ $pc{race} = '<span class="thin">'.$pc{race}.'</span>'; }
$SHEET->param(race => $pc{race});

### ステータス --------------------------------------------------
$SHEET->param(hpAdd => addNum($pc{hpAdd} + $pc{hpAuto}));
$SHEET->param(mpAdd => addNum($pc{mpAdd} + $pc{mpAuto}));
$SHEET->param(fateAdd => addNum($pc{fateAdd}));

### ライフパス --------------------------------------------------
if($pc{race} eq 'アーシアン' && $pc{lifepathEarthian}){
  $SHEET->param(head_origin     => '特異');
  $SHEET->param(head_experience => '転移');
}
if($data::class{$pc{classMain}}{type} eq 'fate'){
  $SHEET->param(head_motive     => '運命');
}

### コネクション --------------------------------------------------
my @connections;
foreach (1 .. $pc{connectionsNum}){
  next if !existsRow "connection$_",'Name','Relation','Note';
  push(@connections, {
    NAME     => $pc{'connection'.$_.'Name'},
    RELATION => $pc{'connection'.$_.'Relation'},
    NOTE     => $pc{'connection'.$_.'Note'},
  });
}
$SHEET->param(Connections => \@connections);

### 誓約 --------------------------------------------------
my @geises;
foreach (1 .. $pc{geisesNum}){
  next if !existsRow "geis$_",'Name','Cost','Note';
  push(@geises, {
    NAME => $pc{'geis'.$_.'Name'},
    COST => $pc{'geis'.$_.'Cost'},
    NOTE => $pc{'geis'.$_.'Note'},
  });
}
$SHEET->param(Geises => \@geises);

### 装備品 --------------------------------------------------
my @weapons;
my @armours;
foreach (
  ['HandR', '右手'    ,],
  ['HandL', '左手'    ,],
  ['Head' , '頭部'    ,],
  ['Body' , '胴部'    ,],
  ['Sub'  , '補助防具',],
  ['Other', '装身具'  ,],
){
  my $th = @{$_}[1];
  my $id = @{$_}[0];
  my $note;
  $pc{'armament'.$id.'Type'}  =~ s/^(防具|装身具)$//g;
  $pc{'armament'.$id.'Usage'} =~ s/^$th$//g;
  if($pc{'armament'.$id.'Type'} || $pc{'armament'.$id.'Usage'}){
    $note .= $pc{'armament'.$id.'Type'};
    $note .= '／' if $pc{'armament'.$id.'Type'} && $pc{'armament'.$id.'Usage'};
    $note .= $pc{'armament'.$id.'Usage'};
    $note = '<b class="term-em type">'.$note.'</b>' if $note;
  }
  $note .= $pc{'armament'.$id.'Note'};
  if($id =~ /Hand/){
    push(@weapons, {
      HEAD   => length($th) > 3 ? "<span>$th</span>" : $th,
      NAME   => $pc{'armament'.$id.'Name'},
      WEIGHT => $pc{'armament'.$id.'Weight'},
      ACC    => $pc{'armament'.$id.'Acc'},
      ATK    => $pc{'armament'.$id.'Atk'},
      EVA    => $pc{'armament'.$id.'Eva'},
      DEF    => $pc{'armament'.$id.'Def'},
      MDEF   => $pc{'armament'.$id.'MDef'},
      INI    => $pc{'armament'.$id.'Ini'},
      MOVE   => $pc{'armament'.$id.'Move'},
      RANGE  => $pc{'armament'.$id.'Range'},
      NOTE   => $note,
    });
  }
  else {
    push(@armours, {
      HEAD   => length($th) > 3 ? "<span>$th</span>" : $th,
      NAME   => $pc{'armament'.$id.'Name'},
      WEIGHT => $pc{'armament'.$id.'Weight'},
      ACC    => $pc{'armament'.$id.'Acc'},
      ATK    => $pc{'armament'.$id.'Atk'},
      EVA    => $pc{'armament'.$id.'Eva'},
      DEF    => $pc{'armament'.$id.'Def'},
      MDEF   => $pc{'armament'.$id.'MDef'},
      INI    => $pc{'armament'.$id.'Ini'},
      MOVE   => $pc{'armament'.$id.'Move'},
      NOTE   => $note,
    });
  }
}
$SHEET->param(Weapons => \@weapons);
$SHEET->param(Armours => \@armours);

### 戦闘系判定：命中/攻撃 --------------------------------------------------
{
  my $acc; my $atk;
  my $h = $pc{handedness} || 1;
  if($h =~ /1|4/){
    $acc .= '<b data-name="右">'.$pc{battleTotalAccR}.'</b>' unless ($h == 1 && ($pc{armamentHandRType} =~ /^[-―ー盾]?$/));
    $acc .= '<b data-name="左">'.$pc{battleTotalAccL}.'</b>' unless ($h == 1 && ($pc{armamentHandLType} =~ /^[-―ー盾]?$/));
  }
  if($h =~ /1|3|4/){
    $atk .= '<b data-name="右">'.$pc{battleTotalAtkR}.'</b>' unless ($h == 1 && ($pc{armamentHandRType} =~ /^[-―ー盾]?$/));
    $atk .= '<b data-name="左">'.$pc{battleTotalAtkL}.'</b>' unless ($h == 1 && ($pc{armamentHandLType} =~ /^[-―ー盾]?$/));
  }
  if($h =~ /2|3|4/){
    $acc .= '<b data-name="計">'.$pc{battleTotalAcc}.'</b>';
  }
  if($h =~ /2|4/){
    $atk .= '<b data-name="計">'.$pc{battleTotalAtk}.'</b>';
  }
  $SHEET->param(battleTotalAcc => $acc);
  $SHEET->param(battleTotalAtk => $atk);
}
### スキル --------------------------------------------------
my @skills; my $skillCount = 0;
foreach (1 .. $pc{skillsNum}){
  next if !existsRow "skill$_",'Name','Lv','Timing','Skill','Target','Range','Cost','Reqd','Note';
  push(@skills, {
    TYPE     => checkType($pc{'skill'.$_.'Type'}),
    CATEGORY => checkCategory($pc{'skill'.$_.'Category'}),
    NAME     => textShrink(13,15,17,21,$pc{'skill'.$_.'Name'}),
    LV       => $pc{'skill'.$_.'Lv'},
    TIMING   => textTiming($pc{'skill'.$_.'Timing'}),
    ROLL     => $pc{'skill'.$_.'Roll'},
    TARGET   => textShrink(6,7,8,8,$pc{'skill'.$_.'Target'}),
    RANGE    => $pc{'skill'.$_.'Range'},
    COST     => $pc{'skill'.$_.'Cost'} || '―',
    REQD     => $pc{'skill'.$_.'Reqd'},
    NOTE     => $pc{'skill'.$_.'Note'},
  });
  $skillCount++;
}
$SHEET->param(Skills => \@skills);
$SHEET->param(skillFullOpen => 'true') if $skillCount <= 10;
sub checkType {
  my $text = shift;
  return '' if !$text;
  if($text eq 'general'){ return '<i class="sk-general">一般</i>'; }
  if($text eq 'race'   ){ return '<i class="sk-race">種族</i>'; }
  if($text eq 'style'  ){ return '<i class="sk-style">流派</i>'; }
  if($text eq 'faith'  ){ return '<i class="sk-faith">天恵</i>'; }
  if($text eq 'geis'   ){ return '<i class="sk-geis">誓約</i>'; }
  if($text eq 'add'    ){ return '<i class="sk-add">他スキル</i>'; }
  if($text eq 'power'  ){ return '<i class="sk-power">パワー<br>'.($pc{classMainLv1}).'</i>'; }
  if($text eq 'another'){ return '<i class="sk-another">異才</i>'; }
  if($data::class{$text} && $data::class{$text}{type} eq 'fate'){ return '<i class="sk-power">'.$text.'</i>'; }
  return '<i class="sk-class">'.checkTypeClass($text).'</i>';
}
sub checkTypeClass {
  my $text = shift;
  if   ($text eq 'ガンスリンガー'  ){ return 'ガン<br>スリンガー' }
  elsif($text eq 'エクセレント'    ){ return 'エクセ<br>レント' }
  elsif($text eq 'ブラックスミス'  ){ return 'ブラック<br>スミス' }
  elsif($text eq 'ファランクス'    ){ return 'ファラン<br>クス' }
  elsif($text eq 'フォーキャスター'){ return 'フォー<br>キャスター' }
  elsif($text eq 'ウォーロード'    ){ return 'ウォー<br>ロード' }
  elsif($text eq 'エクスプローラー'){ return 'エクス<br>プローラー' }
  return $text;
}
sub checkCategory {
  my $text = shift;
  return '' if !$text;
  if($text eq '魔術'      ){ return '<i class="ct-magic">魔術</i>'; }
  if($text =~ /^魔術[〈＜<](.*)[〉＞>]$/){ return '<i class="ct-magic">魔術<small>〈'.$1.'〉</small></i>'; }
  if($text eq '錬金術'    ){ return '<i class="ct-alchemy">錬金術</i>'; }
  if($text eq '呪歌'      ){ return '<i class="ct-song">呪歌</i>'; }
  if($text eq 'ロール'    ){ return '<i class="ct-role">ロール</i>'; }
  return '<i class="ct-other">'.$text.'</i>';
}
sub textTiming {
  my $text = shift;
  $text =~ s#([^<])[／\/]#$1<hr class="dotted">#g;
  $text =~ s#(ムーブ|メジャー|マイナー)(アクション)?#<span class="thin">$1<span class="shorten">アクション</span></span>#g;
  $text =~ s#リアク?(ション)?#<span class="thin">リア<span class="shorten">クション</span></span>#g;
  $text =~ s#(セットアップ|クリンナップ)(プロセス)?#<span class="thiner">$1<span class="shorten">プロセス</span></span>#g;
  $text =~ s#(?:DR|ダメージロール)の?(直[前後])#<span class="thin">DR<span class="shorten">の</span>$1</span>#g;
  $text =~ s#(?:判定)の?(直[前後])#判定<span class="shorten">の</span>$1#g;
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

### レベルアップ履歴 --------------------------------------------------
my @lvuphistory;
foreach my $lv (2 .. $pc{level}){
  my $class = $pc{'lvUp'.$lv.'Class'};
  $class = $class eq 'fate'  ? 'フェイト+'.(int($lv/10)+1) 
         : $class eq 'free'  ? $pc{'lvUp'.$lv.'ClassFree'}
         : $class eq 'title' ? $pc{'lvUp'.$lv.'ClassFree'}
         : $class;
  push(@lvuphistory, {
    LV     => $lv,
    STR    => $pc{'lvUp'.$lv.'SttStr'},
    DEX    => $pc{'lvUp'.$lv.'SttDex'},
    AGI    => $pc{'lvUp'.$lv.'SttAgi'},
    INT    => $pc{'lvUp'.$lv.'SttInt'},
    SEN    => $pc{'lvUp'.$lv.'SttSen'},
    MND    => $pc{'lvUp'.$lv.'SttMnd'},
    LUK    => $pc{'lvUp'.$lv.'SttLuk'},
    CLASS  => $class,
    SKILL1 => $pc{'lvUp'.$lv.'Skill1'},
    SKILL2 => $pc{'lvUp'.$lv.'Skill2'},
    SKILL3 => $pc{'lvUp'.$lv.'Skill3'},
  });
}
$SHEET->param(LvUpHistory => \@lvuphistory);
$SHEET->param(classSupportLv1 => $pc{classSupportLv1Free}) if $pc{classSupportLv1} eq 'free';


### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = 'キャラクター作成';
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Exp','Payment','Money','Gm','Member','Note');
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
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、 ]+/$1　/g;
  foreach my $mem (split(/　/,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  $pc{'history'.$_.'Money'} = formatHistoryFigures($pc{'history'.$_.'Money'});
  push(@history, {
    NUM     => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE    => $pc{'history'.$_.'Date'},
    TITLE   => $pc{'history'.$_.'Title'},
    EXP     => $pc{'history'.$_.'Exp'},
    PAYMENT => $pc{'history'.$_.'Payment'},
    MONEY   => $pc{'history'.$_.'Money'},
    GM      => $pc{'history'.$_.'Gm'},
    MEMBER  => $members,
    NOTE    => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);
$SHEET->param(historyExpTotal   => commify $pc{historyExpTotal}   );
$SHEET->param(payment           => commify $pc{payment}           );
$SHEET->param(historyMoneyTotal => commify $pc{historyMoneyTotal} );

### 携帯品 --------------------------------------------------
$pc{items} =~ s/[@＠]\[\s*?((?:[\+\-\*\/]?[0-9]+)+)\s*?\]/<i class="weight term-em">$1<\/i>/g;
$SHEET->param(items => $pc{items});

### ゴールド --------------------------------------------------
if($pc{moneyAuto}){
  $SHEET->param(money => commify($pc{moneyTotal}));
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

### バックアップ --------------------------------------------------
if($::in{id}){
  my($selected, $list) = getLogList($set::char_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{yourAuthor} || $pc{protect} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

### フェロー --------------------------------------------------
$SHEET->param(FellowMode => $::in{f});

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
$SHEET->param(ogDescript => removeTags "種族:$pc{race}　性別:$pc{gender}　年齢:$pc{age}　クラス:$pc{classMain}／$pc{classSupport}".($pc{classTitle}?"／$pc{classTitle}":''));

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'ar2e');
$SHEET->param(sheetType => 'chara');
$SHEET->param(generateType => 'Arianrhod2PC');
$SHEET->param(defaultImage => $::core_dir.'/skin/ar2e/img/default_pc.png');

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
      else                 { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}&log=$pc{logId}", }); }
    }
    else {
      if(!$pc{forbiddenMode}){
        push(@menu, { TEXT => 'パレット', TYPE => "onclick", VALUE => "chatPaletteOn()",   });
        push(@menu, { TEXT => '出力'    , TYPE => "onclick", VALUE => "downloadListOn()",  });
        push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => "loglistOn()",      });
      }
      if($pc{reqdPassword}){ push(@menu, { TEXT => '編集', TYPE => "onclick", VALUE => "editOn()", }); }
      else                 { push(@menu, { TEXT => '編集', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}", }); }
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