################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_class;
require $set::data_races;
require $set::data_items;
require $set::data_faith;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  loop_context_vars => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);


$SHEET->param("backupMode" => param('backup') ? 1 : 0);

### キャラクターデータ読み込み #######################################################################
my $id = param('id');
my $conv_url = param('url');
my $file = $main::file;

our %pc = ();
if($id){
  my $datafile = "${set::char_dir}${file}/data.cgi";
     $datafile = "${set::char_dir}${file}/backup/".param('backup').'.cgi' if param('backup');
  open my $IN, '<', $datafile or error 'キャラクターシートがありません。';
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
}
elsif($conv_url){
  %pc = %::conv_data;
  if(!$pc{'ver'}){
    require $set::lib_calc_char;
    %pc = data_calc(\%pc);
  }
  $SHEET->param("convertMode" => 1);
  $SHEET->param("convertUrl" => $conv_url);
}

$SHEET->param("id" => $id);

### 置換 --------------------------------------------------
foreach (keys %pc) {
  if($_ =~ /^(?:items|freeNote|freeHistory|cashbook)$/){
    $pc{$_} = tag_unescape_lines($pc{$_});
  }
  $pc{$_} = tag_unescape($pc{$_});
}

### コンバート --------------------------------------------------
if($pc{'colorCustom'} && $pc{'colorHeadBgA'}) {
  ($pc{'colorHeadBgH'}, $pc{'colorHeadBgS'}, $pc{'colorHeadBgL'}) = rgb_to_hsl($pc{'colorHeadBgR'},$pc{'colorHeadBgG'},$pc{'colorHeadBgB'});
  ($pc{'colorBaseBgH'}, $pc{'colorBaseBgS'}, undef) = rgb_to_hsl($pc{'colorBaseBgR'},$pc{'colorBaseBgG'},$pc{'colorBaseBgB'});
  $pc{'colorBaseBgS'} = $pc{'colorBaseBgS'} * $pc{'colorBaseBgA'} * 10;
}
foreach (1..17) {
  $pc{'craftGramarye'.$_} = $pc{'craftGramarye'.$_} || $pc{'magicGramarye'.$_};
}

### アップデート --------------------------------------------------
if($pc{'ver'}){
  %pc = data_update_chara(\%pc);
}

### テンプレ用に変換 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}

### 出力準備 #########################################################################################
### 二つ名 --------------------------------------------------
my($aka, $ruby) = split(/:/,$pc{'aka'});
$SHEET->param("aka" => "<ruby>$aka<rt>$ruby</rt></ruby>") if $ruby;

### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $id))[0];
  $SHEET->param("playerName" => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{'playerName'}.'</a>');
}
### グループ --------------------------------------------------
if($conv_url){
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
$pc{'words'} =~ s/^「/<span class="brackets">「<\/span>/g;
$pc{'words'} =~ s/(.+?(?:[，、。？」]|$))/<span>$1<\/span>/g;
$SHEET->param("words" => $pc{'words'});
$SHEET->param("wordsX" => ($pc{'wordsX'} eq '左' ? 'left:0;' : 'right:0;'));
$SHEET->param("wordsY" => ($pc{'wordsY'} eq '下' ? 'bottom:0;' : 'top:0;'));

### 種族名 --------------------------------------------------
$pc{'race'} =~ s/［.*］//g;
$SHEET->param("race" => $pc{'race'});

### 種族特徴 --------------------------------------------------
$pc{'raceAbility'} =~ s/［(.*?)］/<span>［$1］<\/span>/g;
$SHEET->param("raceAbility" => $pc{'raceAbility'});

### 穢れ --------------------------------------------------
$SHEET->param("sin" => '―') if !$pc{'sin'} && $pc{'race'} =~ /^(?:ルーンフォーク|フィー)$/;

### 信仰 --------------------------------------------------
if($pc{'faith'} eq 'その他の信仰') { $SHEET->param("faith" => $pc{'faithOther'}); }
$pc{'faith'} =~ s/“(.*)”//;

### 経験点 --------------------------------------------------
$SHEET->param("expUsed" => $pc{'expTotal'} - $pc{'expRest'}) ;

### 技能 --------------------------------------------------
my @classes; my %classes;
foreach my $class (@data::class_names){
  my $id   = $data::class{$class}{'id'};
  next if !$pc{'lv'.$id};
  my $name = $class;
  if($name eq 'プリースト' && $pc{'faith'}){
    $name .= '<span class="priest-faith'.(length($pc{'faith'}) > 12 ? ' narrow' : "").'">（'.$pc{'faith'}.$pc{'faithType'}.'）</span>';
  }
  push(@classes, { "NAME" => $name, "LV" => $pc{'lv'.$id} } );
  $classes{$class} = $pc{'lv'.$id};
}
@classes = sort{$b->{'LV'} <=> $a->{'LV'}} @classes;
$SHEET->param(Classes => \@classes);
my $class_text;
foreach my $key (sort {$classes{$b} <=> $classes{$a}} keys %classes){ $class_text .= ($class_text ? ',' : '').$key.$classes{$key}; }

### 一般技能 --------------------------------------------------
my @common_classes;
foreach (1..10){
  next if !$pc{'commonClass'.$_};
  $pc{'commonClass'.$_} =~ s#([（\(].+?[\)）])#<span class="small">$1</span>#g;
  push(@common_classes, { "NAME" => $pc{'commonClass'.$_}, "LV" => $pc{'lvCommon'.$_} } );
}
$SHEET->param(CommonClasses => \@common_classes);

### 戦闘特技 --------------------------------------------------
my @feats_lv;
foreach (@set::feats_lv){
  next if !$pc{'combatFeatsLv'.$_};
  next if $pc{'level'} < $_;
  push(@feats_lv, { "NAME" => $pc{'combatFeatsLv'.$_}, "LV" => $_ } );
}
$SHEET->param(CombatFeatsLv => \@feats_lv);

## 自動習得
my @feats_auto;
foreach (split /,/, $pc{'combatFeatsAuto'}) {
  push(@feats_auto, { "NAME" => $_ } );
}
$SHEET->param(CombatFeatsAuto => \@feats_auto);

### 秘伝 --------------------------------------------------
my @mystic_arts; my $mysticarts_honor = 0;
foreach (1..$pc{'mysticArtsNum'}){
  $mysticarts_honor += $pc{'mysticArts'.$_.'Pt'};
  next if !$pc{'mysticArts'.$_};
  push(@mystic_arts, { "NAME" => $pc{'mysticArts'.$_} });
}
$SHEET->param(MysticArts => \@mystic_arts);
$SHEET->param(MysticArtsHonor => $mysticarts_honor);

### 秘奥魔法 --------------------------------------------------
my %gramarye_ruby;
foreach (@{$data::class{'グリモワール'}{'magic'}{'data'}}){
  $gramarye_ruby{@$_[1]} = @$_[2];
}
### 魔法 --------------------------------------------------
my $craft_none = 1;
my @magic_lists;
foreach my $class (@data::class_names){
  next if !$data::class{$class}{'magic'}{'data'};
  my $lv = $pc{'lv'.$data::class{$class}{'id'}};
  next if !$lv;
  
  my @magics;
  foreach (1 .. $lv + $pc{$data::class{$class}{'magic'}{'eName'}.'Addition'}){
    my $magic = $pc{'magic'.ucfirst($data::class{$class}{'magic'}{'eName'}).$_};
    
    if($class eq 'グリモワール'){
      push(@magics, { "ITEM" => "－${magic}－", "RUBY" => "data-ruby=\"$gramarye_ruby{$magic}\"" } );
    }
    else { push(@magics, { "ITEM" => $magic } ); }
  }
  
  push(@magic_lists, { "jNAME" => $data::class{$class}{'magic'}{'jName'}, "eNAME" => $data::class{$class}{'magic'}{'eName'}, "MAGICS" => \@magics } );
  $craft_none = 0;
}
$SHEET->param(MagicLists => \@magic_lists);

### 技芸 --------------------------------------------------
my @craft_lists;
my $enhance_attack_on;
my $rider_obs_on;
foreach my $class (@data::class_names){
  next if !$data::class{$class}{'craft'}{'data'};
  my $lv = $pc{'lv'.$data::class{$class}{'id'}};
  next if !$lv;
  
  my @crafts;
  foreach (1 .. $lv + $pc{$data::class{$class}{'craft'}{'eName'}.'Addition'}){
    my $craft = $pc{'craft'.ucfirst($data::class{$class}{'craft'}{'eName'}).$_};
    
    if($class eq 'エンハンサー'){
      $enhance_attack_on = 1 if $craft =~ /フェンリルバイト|バルーンシードショット/;
    }
    elsif($class eq 'ライダー'){
      $SHEET->param(riderObsOn => 1)  if $craft eq '探索指令';
    }
    push(@crafts, { "ITEM" => $craft } );
  }
  
  push(@craft_lists, { "jNAME" => $data::class{$class}{'craft'}{'jName'}, "eNAME" => $data::class{$class}{'craft'}{'eName'}, "CRAFTS" => \@crafts } );
  $craft_none = 0;
}
$SHEET->param(CraftLists => \@craft_lists);

$SHEET->param(craftNone => $craft_none);

### 言語 --------------------------------------------------
my @language;
foreach (@{$data::race_language{ $pc{'race'} }}){
  last if $pc{'languageAutoOff'};
  push(@language, {
    "NAME" => @$_[0],
    "TALK" => @$_[1],
    "READ" => @$_[2],
    "TALK/READ" => (@$_[1]?'会話':'').(@$_[1] && @$_[2] ? '／' : '').(@$_[2]?'読文':'')
  } );
}
foreach (1 .. $pc{'languageNum'}) {
  next if !$pc{'language'.$_};
  push(@language, {
    "NAME" => $pc{'language'.$_},
    "TALK" => $pc{'language'.$_.'Talk'},
    "READ" => $pc{'language'.$_.'Read'},
    "TALK/READ" => ($pc{'language'.$_.'Talk'}?'会話':'').
                   ($pc{'language'.$_.'Talk'} && $pc{'language'.$_.'Read'} ? '／' : '').
                   ($pc{'language'.$_.'Read'}?'読文':'')
  } );
}
$SHEET->param(Language => \@language);


### パッケージ --------------------------------------------------
$SHEET->param("PackageLv" => max($pc{'lvSco'},$pc{'lvRan'},$pc{'lvSag'},$pc{'lvBar'},$pc{'lvRid'},$pc{'lvAlc'}));

### 妖精契約 --------------------------------------------------
my $fairy_contact;
{
  $fairy_contact .= '<span class="ft-earth">土</span>' if $pc{'fairyContractEarth'};
  $fairy_contact .= '<span class="ft-water">水</span>' if $pc{'fairyContractWater'};
  $fairy_contact .= '<span class="ft-fire" >炎</span>' if $pc{'fairyContractFire' };
  $fairy_contact .= '<span class="ft-wind" >風</span>' if $pc{'fairyContractWind' };
  $fairy_contact .= '<span class="ft-light">光</span>' if $pc{'fairyContractLight'};
  $fairy_contact .= '<span class="ft-dark" >闇</span>' if $pc{'fairyContractDark' };
}
### 魔力 --------------------------------------------------
my @magic;
foreach my $class (@data::class_names){
  my $id   = $data::class{$class}{'id'};
  my $name = $data::class{$class}{'magic'}{'jName'};
  next if !$name;
  next if !$pc{'lv'.$id};
  
  my $power  = $pc{'magicPowerAdd' .$id} + $pc{'magicPowerAdd'} +$pc{'magicPowerEnhance'};
  my $cast   = $pc{'magicCastAdd'  .$id} + $pc{'magicCastAdd'};
  my $damage = $pc{'magicDamageAdd'.$id} + $pc{'magicDamageAdd'};
  
  push(@magic, {
    "NAME" => $class."<span class=\"small\">技能レベル</span>".$pc{'lv'.$id},
    "OWN"  => ($pc{'magicPowerOwn'.$id} ? '✔<span class="small">知力+2</span>' : ''),
    "MAGIC"  => $name.($id eq 'Fai' && $fairy_contact ? "<div id=\"fairycontact\">$fairy_contact</div>" : ''),
    "POWER"  => ($power ? '<span class="small">+'.$power.'=</span>' : '').$pc{'magicPower'.$id},
    "CAST"   => ($cast ? '<span class="small">+'.$cast.'=</span>' : '').($pc{'magicPower'.$id}+$cast),
    "DAMAGE" => "+$damage",
  } );
}

foreach my $class (@data::class_names){
  my $id    = $data::class{$class}{'id'};
  my $name  = $data::class{$class}{'craft'}{'jName'};
  my $stt   = $data::class{$class}{'craft'}{'stt'};
  my $pname = $data::class{$class}{'craft'}{'power'};
  next if !$stt;
  next if !$pc{'lv'.$id};
  
  my $power  = $pc{'magicPowerAdd' .$id};
  my $cast   = $pc{'magicCastAdd'  .$id};
  my $damage = $pc{'magicDamageAdd'.$id};
  
  push(@magic, {
    "NAME" => $class."<span class=\"small\">技能レベル</span>".$pc{'lv'.$id},
    "OWN"  => ($pc{'magicPowerOwn'.$id} ? '✔<span class="small">'.$stt.'+2</span>' : ''),
    "MAGIC"  => $name,
    "POWER"  => ($pname) ? ($power ? '<span class="small">+'.$power.'=</span>' : '').$pc{'magicPower'.$id} : '―',
    "CAST"   => ($cast ? '<span class="small">+'.$cast.'=</span>' : '').($pc{'magicPower'.$id}+$cast),
    "DAMAGE" => ($pname) ? "+$damage" : '―',
  } );
}
$SHEET->param(MagicPowers => \@magic);
{
  my @head; my @pow; my @act;
  if($pc{'lvCaster'}) { push(@head, '魔法'); push(@pow, '魔力'); push(@act, '行使'); }
  foreach my $class (@data::class_names){
    my $id    = $data::class{$class}{'id'};
    next if !$data::class{$class}{'craft'}{'stt'};
    next if !$pc{'lv'.$id};
    
    push(@head, $data::class{$class}{'craft'}{'jName'});
    push(@pow,  $data::class{$class}{'craft'}{'power'}) if $data::class{$class}{'craft'}{'power'};
    if($class eq 'バード'){ push(@act, '演奏'); }
    else                  { push(@act, $data::class{$class}{'craft'}{'jName'}); }
  }
  
  $SHEET->param(MagicPowerHeader => join('／',@head));
  $SHEET->param(MagicPowerThPow => scalar(@pow) >= 2 ? '<span class="small">'.join('/',@pow).'</span>' : join('/',@pow));
  $SHEET->param(MagicPowerThAct => scalar(@act) >= 3 ? "$act[0]など" : join('/',@act));
}

### 攻撃技能／特技 --------------------------------------------------
my @atacck;
foreach (
  ['ファイター',      'Fig'],
  ['グラップラー',    'Gra'],
  ['フェンサー',      'Fen'],
  ['シューター',      'Sho'],
  ['エンハンサー',    'Enh'],
  ['デーモンルーラー','Dem'],
){
  next if !$pc{'lv'.@$_[1]};
  next if @$_[0] eq 'エンハンサー' && !$enhance_attack_on;
  push(@atacck, {
    "NAME" => @$_[0]."<span class=\"small\">技能レベル</span>".$pc{'lv'.@$_[1]},
    "STR"  => (@$_[1] eq 'Fen' ? $pc{'reqdStrF'} : $pc{'reqdStr'}),
    "ACC"  => $pc{'lv'.@$_[1]}+$pc{'bonusDex'},
    (@$_[1] eq 'Fen' ? ("CRIT" => '-1') : ('' => '')),
    "DMG"  => $pc{'lv'.@$_[1]}+$pc{'bonusStr'},
  } );
}
foreach (@data::weapons) {
  next if !$pc{'mastery'.ucfirst(@$_[1])};
  push(@atacck, {
    "NAME" => "《武器習熟".($pc{'mastery'.ucfirst(@$_[1])} >= 2 ? 'Ｓ' : 'Ａ')."／".@$_[0]."》",
    "DMG"  => $pc{'mastery'.ucfirst(@$_[1])},
  } );
}
if($pc{'masteryArtisan'}) {
  push(@atacck, {
    "NAME" => "《".($pc{'masteryArtisan'} >= 3 ? '魔器の達人' : $pc{'masteryArtisan'} >= 2 ? '魔器習熟Ｓ' : '魔器習熟Ａ')."》",
    "DMG"  => $pc{'masteryArtisan'},
  } );
}
if($pc{'accuracyEnhance'}) {
  push(@atacck, {
    "NAME" => "《命中強化".($pc{'accuracyEnhance'}  >= 2  ? 'Ⅱ' : 'Ⅰ')."》",
    "ACC"  => $pc{'accuracyEnhance'},
  } );
}
if($pc{'throwing'}) {
  push(@atacck, {
    "NAME" => "《スローイング".($pc{'throwing'}  >= 2  ? 'Ⅱ' : 'Ⅰ')."》",
    "ACC"  => 1,
  } );
}
$SHEET->param(AttackClasses => \@atacck);

### 武器 --------------------------------------------------
{
my @weapons; my $first = 1;
foreach (1 .. $pc{'weaponNum'}){
  next if $pc{'weapon'.$_.'Name'}.$pc{'weapon'.$_.'Usage'}.$pc{'weapon'.$_.'Reqd'}.
          $pc{'weapon'.$_.'Acc'}.$pc{'weapon'.$_.'Rate'}.$pc{'weapon'.$_.'Crit'}.
          $pc{'weapon'.$_.'Dmg'}.$pc{'weapon'.$_.'Own'}.$pc{'weapon'.$_.'Note'}
          eq '';
  my $rowspan = 1;
  for(my $num = $_+1; $num <= $pc{'weaponNum'}; $num++){
    last if $pc{'weapon'.$num.'NameOff'};
    last if $pc{'weapon'.$num.'Name'};
    last if $pc{'weapon'.$num.'Name'}.$pc{'weapon'.$num.'Usage'}.$pc{'weapon'.$num.'Reqd'}.
          $pc{'weapon'.$num.'Acc'}.$pc{'weapon'.$num.'Rate'}.$pc{'weapon'.$num.'Crit'}.
          $pc{'weapon'.$num.'Dmg'}.$pc{'weapon'.$num.'Own'}.$pc{'weapon'.$num.'Note'} eq '';
    $rowspan++;
    $pc{'weapon'.$num.'NameOff'} = 1;
  }
  if($pc{'weapon'.$_.'Class'} eq "自動計算しない"){
    $pc{'weapon'.$_.'Acc'} = 0;
    $pc{'weapon'.$_.'Dmg'} = 0;
  }
  push(@weapons, {
    "NAME"     => $pc{'weapon'.$_.'Name'},
    "ROWSPAN"  => $rowspan,
    "NAMEOFF"  => $pc{'weapon'.$_.'NameOff'},
    "USAGE"    => $pc{'weapon'.$_.'Usage'},
    "REQD"     => $pc{'weapon'.$_.'Reqd'},
    "ACC"      => $pc{'weapon'.$_.'Acc'},
    "ACCTOTAL" => $pc{'weapon'.$_.'AccTotal'},
    "RATE"     => $pc{'weapon'.$_.'Rate'},
    "CRIT"     => $pc{'weapon'.$_.'Crit'},
    "DMG"      => $pc{'weapon'.$_.'Dmg'},
    "DMGTOTAL" => $pc{'weapon'.$_.'DmgTotal'},
    "OWN"      => $pc{'weapon'.$_.'Own'},
    "NOTE"     => $pc{'weapon'.$_.'Note'},
    "CLOSE"    => ($pc{'weapon'.$_.'NameOff'} || $first ? 0 : 1),
  } );
  $first = 0;
}
$SHEET->param(Weapons => \@weapons);
}
### 回避技能／特技 --------------------------------------------------
my @evasion;
foreach (
  ['ファイター',      'Fig'],
  ['グラップラー',    'Gra'],
  ['フェンサー',      'Fen'],
  ['シューター',      'Sho'],
  ['デーモンルーラー','Dem'],
){
  next if @$_[0] ne $pc{'evasionClass'};
  push(@evasion, {
    "NAME" => @$_[0]."<span class=\"small\">技能レベル</span>".$pc{'lv'.@$_[1]},
    "STR"  => (@$_[1] eq 'Fen' ? $pc{'reqdStrF'} : $pc{'reqdStr'}),
    "EVA"  => $pc{'lv'.@$_[1]}+$pc{'bonusAgi'},
  } );
}
if(!$pc{'evasionClass'}){
  push(@evasion, {
    "NAME" => '技能なし',
    "STR"  => $pc{'reqdStr'},
    "EVA"  => 0,
  } );
}
if($pc{'race'} eq 'リルドラケン') {
  push(@evasion, {
    "NAME" => "［鱗の皮膚］",
    "DEF"  => $pc{'raceAbilityDef'},
  } );
}
elsif($pc{'race'} eq 'フロウライト') {
  push(@evasion, {
    "NAME" => "［晶石の身体］",
    "DEF"  => $pc{'raceAbilityDef'},
  } );
}
elsif($pc{'race'} eq 'ダークトロール') {
  push(@evasion, {
    "NAME" => "［トロールの体躯］",
    "DEF"  => $pc{'raceAbilityDef'},
  } );
}
foreach (['金属鎧','MetalArmour'],['非金属鎧','NonMetalArmour'],['盾','Shield']) {
  next if !$pc{'mastery'.ucfirst(@$_[1])};
  push(@evasion, {
    "NAME" => "《防具習熟".($pc{'mastery'.ucfirst(@$_[1])} >= 2 ? 'Ｓ' : 'Ａ')."／".@$_[0]."》",
    "DEF"  => $pc{'mastery'.ucfirst(@$_[1])},
  } );
}
if($pc{'masteryArtisan'}) {
  push(@evasion, {
    "NAME" => "《".($pc{'masteryArtisan'} >= 3 ? '魔器の達人' : $pc{'masteryArtisan'} >= 2 ? '魔器習熟Ｓ' : '魔器習熟Ａ')."》",
    "DEF"  => $pc{'masteryArtisan'},
  } );
}
if($pc{'evasiveManeuver'}) {
  push(@evasion, {
    "NAME" => "《回避行動".($pc{'evasiveManeuver'}  >= 2  ? 'Ⅱ' : 'Ⅰ').@$_[0]."》",
    "EVA"  => $pc{'evasiveManeuver'},
  } );
}
$SHEET->param(EvasionClasses => \@evasion);

### 装飾品 --------------------------------------------------
my @accessories;
foreach (
  ["頭","Head"],    ["┗","Head_"],   ["┗","Head__"],
  ["顔","Face"],    ["┗","Face_"],   ["┗","Face__"],
  ["耳","Ear"],     ["┗","Ear_"],    ["┗","Ear__"],
  ["首","Neck"],    ["┗","Neck_"],   ["┗","Neck__"],
  ["背中","Back"],  ["┗","Back_"],   ["┗","Back__"],
  ["右手","HandR"], ["┗","HandR_"],  ["┗","HandR__"],
  ["左手","HandL"], ["┗","HandL_"],  ["┗","HandL__"],
  ["腰","Waist"],   ["┗","Waist_"],  ["┗","Waist__"],
  ["足","Leg"],     ["┗","Leg_"],    ["┗","Leg__"],
  ["他","Other"],   ["┗","Other_"],  ["┗","Other__"],
  ["他2","Other2"], ["┗","Other2_"], ["┗","Other2__"],
  ["他3","Other3"], ["┗","Other3_"], ["┗","Other3__"],
  ["他4","Other4"], ["┗","Other4_"], ["┗","Other4__"],
){
  next if !$pc{'accessory'.@$_[1].'Name'} && !$pc{'accessory'.@$_[1].'Note'};
  push(@accessories, {
    "TYPE" => @$_[0],
    "NAME" => $pc{'accessory'.@$_[1].'Name'},
    "OWN"  => $pc{'accessory'.@$_[1].'Own'},
    "NOTE" => $pc{'accessory'.@$_[1].'Note'},
  } );
}
$SHEET->param(Accessories => \@accessories);

### 履歴 --------------------------------------------------

$pc{"history0Grow"} .= '器用'.$pc{'sttPreGrowA'} if $pc{'sttPreGrowA'};
$pc{"history0Grow"} .= '敏捷'.$pc{'sttPreGrowB'} if $pc{'sttPreGrowB'};
$pc{"history0Grow"} .= '筋力'.$pc{'sttPreGrowC'} if $pc{'sttPreGrowC'};
$pc{"history0Grow"} .= '生命'.$pc{'sttPreGrowD'} if $pc{'sttPreGrowD'};
$pc{"history0Grow"} .= '知力'.$pc{'sttPreGrowE'} if $pc{'sttPreGrowE'};
$pc{"history0Grow"} .= '精神'.$pc{'sttPreGrowF'} if $pc{'sttPreGrowF'};

my @history;
my $h_num = 0;
$pc{'history0Title'} = 'キャラクター作成';
foreach (0 .. $pc{'historyNum'}){
  $pc{'history'.$_.'Grow'} =~ s/[^器敏筋生知精0-9]//g;
  $pc{'history'.$_.'Grow'} =~ s/器([0-9]{0,3})/器用×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/敏([0-9]{0,3})/敏捷×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/筋([0-9]{0,3})/筋力×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/生([0-9]{0,3})/生命×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/知([0-9]{0,3})/知力×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/精([0-9]{0,3})/精神×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/×([^0-9])/$1/g;
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
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、 ]+/$1　/g;
  foreach my $mem (split(/　/,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  push(@history, {
    "NUM"    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    "DATE"   => $pc{'history'.$_.'Date'},
    "TITLE"  => $pc{'history'.$_.'Title'},
    "EXP"    => $pc{'history'.$_.'Exp'},
    "HONOR"  => $pc{'history'.$_.'Honor'},
    "MONEY"  => $pc{'history'.$_.'Money'},
    "GROW"   => $pc{'history'.$_.'Grow'},
    "GM"     => $pc{'history'.$_.'Gm'},
    "MEMBER" => $members,
    "NOTE"   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);


### 名誉アイテム --------------------------------------------------
my @honoritems;
foreach (1 .. $pc{'honorItemsNum'}) {
  next if !$pc{'honorItem'.$_} && !$pc{'honorItem'.$_.'Pt'};
  push(@honoritems, {
    "NAME" => $pc{'honorItem'.$_},
    "PT"   => $pc{'honorItem'.$_.'Pt'},
  } );
}
$SHEET->param(HonorItems => \@honoritems);

my @dishonoritems;
foreach (1 .. $pc{'dishonorItemsNum'}) {
  next if !$pc{'dishonorItem'.$_} && !$pc{'dishonorItem'.$_.'Pt'};
  push(@dishonoritems, {
    "NAME" => $pc{'dishonorItem'.$_},
    "PT"   => $pc{'dishonorItem'.$_.'Pt'},
  } );
}
$SHEET->param(DishonorItems => \@dishonoritems);

foreach (@set::adventurer_rank){
  my ($name, $num, undef) = @$_;
  $SHEET->param(rankHonorValue => $num) if ($pc{'rank'} eq $name);
}
foreach (@set::notoriety_rank){
  my ($name, $num) = @$_;
  $SHEET->param(notoriety => $name) if $pc{'dishonor'} >= $num;
}

### ガメル --------------------------------------------------
if($pc{"money"} =~ /^(?:自動|auto)$/i){
  $SHEET->param(money => $pc{'moneyTotal'});
}
if($pc{"deposit"} =~ /^(?:自動|auto)$/i){
  $SHEET->param(deposit => $pc{'depositTotal'}.' G ／ '.$pc{'debtTotal'});
}
$pc{"cashbook"} =~ s/(:(?:\:|&lt;|&gt;))((?:[\+\-\*\/]?[0-9]+)+)/$1.cashCheck($2)/eg;
  $SHEET->param(cashbook => $pc{'cashbook'});
sub cashCheck(){
  my $text = shift;
  my $num = s_eval($text);
  if   ($num > 0) { return '<b class="cash plus">'.$text.'</b>'; }
  elsif($num < 0) { return '<b class="cash minus">'.$text.'</b>'; }
  else { return '<b class="cash">'.$text.'</b>'; }
}
### マテリアルカード --------------------------------------------------
foreach my $color ('Red','Gre','Bla','Whi','Gol'){
  $SHEET->param("card${color}View" => $pc{'card'.$color.'B'}+$pc{'card'.$color.'A'}+$pc{'card'.$color.'S'}+$pc{'card'.$color.'SS'});
}

### 戦闘用アイテム --------------------------------------------------
my $smax = max("$pc{'lvSco'}","$pc{'lvRan'}","$pc{'lvSag'}");
my @battleitems;
foreach (1 .. (8 + ceil($smax / 2))) {
  last if !$set::battleitem;
  push(@battleitems, {
    "ITEM" => $pc{'battleItem'.$_},
  } );
}
$SHEET->param(BattleItems => \@battleitems);


### カラーカスタム --------------------------------------------------
$SHEET->param(colorBaseBgS => $pc{colorBaseBgS} * 0.7);
$SHEET->param(colorBaseBgL => 100 - $pc{colorBaseBgS} / 6);
$SHEET->param(colorBaseBgD => 15);

### バックアップ --------------------------------------------------
if($id){
  opendir(my $DIR,"${set::char_dir}${file}/backup");
  my @backlist = readdir($DIR);
  closedir($DIR);
  my @backup;
  foreach (reverse sort @backlist) {
    if ($_ =~ s/\.cgi//) {
      my $url = $_;
      $_ =~ s/^([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})-([0-9]{2})$/$1 $2\:$3/;
      push(@backup, {
        "NOW"  => ($url eq param('backup') ? 1 : 0),
        "URL"  => $url,
        "DATE" => $_,
      });
    }
  }
  $SHEET->param(Backup => \@backup);
}

### パスワード要求 --------------------------------------------------
$SHEET->param(ReqdPassword => (!$pc{'protect'} || $pc{'protect'} eq 'password' ? 1 : 0) );

### フェロー --------------------------------------------------
$SHEET->param(FellowMode => param('f'));

### タイトル --------------------------------------------------
$SHEET->param(characterNameTitle => tag_delete name_plain $pc{'characterName'});
$SHEET->param(title => $set::title);

### 画像 --------------------------------------------------
my $imgsrc = (
  $pc{'imageURL'} ? tag_delete($pc{'imageURL'})
  : $main::base_url ? "${main::base_url}data/chara/$pc{'birthTime'}/image.$pc{'image'}"
  : "${set::char_dir}${file}/image.$pc{'image'}?$pc{'imageUpdate'}"
);
$SHEET->param("imageSrc" => $imgsrc);

if($pc{'imageFit'} eq 'percentY'){
  $SHEET->param("imageFit" => 'auto '.$pc{'imagePercent'}.'%');
}
elsif($pc{'imageFit'} =~ /^percentX?$/){
  $SHEET->param("imageFit" => $pc{'imagePercent'}.'%');
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($conv_url ? "?url=${conv_url}" : "?id=${id}"));
if($pc{'image'}) { $SHEET->param(ogImg => url()."/".$imgsrc); }
$SHEET->param(ogDescript => "種族:$pc{'race'}　性別:$pc{'gender'}　年齢:$pc{'age'}　技能:${class_text}");

### バージョン等 --------------------------------------------------
$SHEET->param("ver" => $::ver);
$SHEET->param("coreDir" => $::core_dir);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $SHEET->output;

1;