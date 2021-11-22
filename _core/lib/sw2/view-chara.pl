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
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  loop_context_vars => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### キャラクターデータ読み込み #######################################################################
our %pc = pcDataGet();

### 閲覧禁止データ ###################################################################################
if($::in{'checkView'}){ $::LOGIN_ID = ''; }

if($pc{'forbidden'} && (getfile($::in{'id'},'',$::LOGIN_ID))[0]){
  $pc{'forbiddenAuthor'} = 1;
}
elsif($pc{'forbidden'}){
  my $author = $pc{'playerName'};
  my $protect   = $pc{'protect'};
  my $forbidden = $pc{'forbidden'};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{'aka'} = '';
    $pc{'characterName'} = noiseText(6,14);
    $pc{'group'} = $pc{'tags'} = '';
    
    $pc{'freeNote'} = '';
    foreach(1..int(rand 5)+4){
      $pc{'freeNote'} .= '　'.noiseText(18,40)."\n";
    }
    $pc{'freeHistory'} = '';
  }
  
  $pc{'age'}    = noiseText(1,2);
  $pc{'gender'} = noiseText(1,2);
  $pc{'birth'}  = noiseText(2,4);
  $pc{'race'}        = noiseText(3,8);
  $pc{'raceAbility'} = noiseText(4,16);
  $pc{'sin'} = noiseText(1);
  $pc{'faith'}  = noiseText(6,10);
  $pc{'rank'}   = noiseText(3,5);
  
  foreach('Tec','Phy','Spi'){ $pc{'sttBase'.$_} = noiseText(1,2); }
  foreach('A'..'F'){
    $pc{'sttBase'.$_} = noiseText(1);
    $pc{'sttGrow'.$_} = noiseText(1);
    $pc{'sttAdd'.$_} = noiseText(1);
    $pc{'sttPreGrow'.$_} = 0;
  }
  foreach('Dex','Agi','Str','Vit','Int','Mnd'){
    $pc{'stt'.$_} = noiseText(1);
    $pc{'bonus'.$_} = noiseText(1);
  }
  foreach('vitResist','mndResist','hp','mp'){
    $pc{$_.'AddTotal'} = '';
    $pc{$_.'Total'} = noiseText(1,2);
  }
  
  $pc{'expRest'}  = noiseText(2,3);
  $pc{'expTotal'} = noiseText(2,3);
  $pc{'level'} = noiseText(1);
  $pc{'lvWiz'} = $pc{'lvSeeker'} = $pc{'lvMonster'} = 0;
  foreach my $class (@data::class_names){ $pc{ 'lv'.$data::class{$class}{'id'} } = 0; }
  foreach (1 .. 10){ $pc{'commonClass'.$_} = ''; }
  $pc{'monsterLore'} = noiseText(1);
  $pc{'initiative'}  = noiseText(1);
  $pc{'mobilityLimited'} = noiseText(1);
  $pc{'mobilityTotal'}   = noiseText(1);
  $pc{'mobilityFull'}    = noiseText(1,2);
  
  $pc{'combatFeatsAuto'} = '';
  $pc{'mysticArtsNum'} = '';
  
  $pc{'languageNum'} = 1;
  foreach (1 .. $pc{'languageNum'}){
    $pc{'language'.$_} = '不明';
    $pc{'language'.$_.'Read'} = $pc{'language'.$_.'Talk'} = '';
  }
  
  $pc{'honor'} = $pc{'dishonor'} = $pc{'honorOffset'} = noiseText(1,2);
  $pc{'honorItemsNum'} = $pc{'dishonorItemsNum'} = $pc{'rankHonorValue'} = $pc{'MysticArtsHonor'} = '';
  
  $pc{'money'}   = noiseText(3,6);
  $pc{'deposit'} = noiseText(3,6);
  $pc{'items'} = '';
  foreach(1..int(rand 3)+6){
    $pc{'items'} .= noiseText(6,24)."\n";
  }
  $pc{'cashbook'} = '';
  
  $pc{'historyNum'} = 0;
  $pc{'history0Exp'}   = noiseText(1,3);
  $pc{'history0Honor'} = noiseText(1,2);
  $pc{'history0Money'} = noiseText(2,4);
  
  $pc{'playerName'} = $author;
  $pc{'protect'} = $protect;
  $pc{'forbidden'} = $forbidden;
  $pc{'forbiddenMode'} = 1;
}

### 置換 #############################################################################################
if($pc{'ver'}){
  foreach (keys %pc) {
    next if($_ =~ /^(?:imageURL|imageCopyrightURL)$/);
    if($_ =~ /^(?:items|freeNote|freeHistory|cashbook)$/){
      $pc{$_} = tag_unescape_lines($pc{$_});
    }
    $pc{$_} = tag_unescape($pc{$_});

    $pc{$_} = noiseTextTag $pc{$_} if $pc{'forbiddenMode'};
  }
}
else {
  $pc{'freeNote'} = $pc{'freeNoteView'} if $pc{'freeNoteView'};
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

### 置換後出力 #######################################################################################
### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param("id" => $::in{'id'});

if($::in{'url'}){
  $SHEET->param("convertMode" => 1);
  $SHEET->param("convertUrl" => $::in{'url'});
}

### 二つ名 --------------------------------------------------
$SHEET->param("aka" => "<ruby>$pc{'aka'}<rt>$pc{'akaRuby'}</rt></ruby>") if $pc{'akaRuby'};

### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $::in{'id'}))[0];
  $SHEET->param("playerName" => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{'playerName'}.'</a>');
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
$pc{'expUsed'} = $pc{'expTotal'} - $pc{'expRest'};
foreach('expUsed','expTotal','expRest'){
  $pc{$_} = commify $pc{$_};
  $SHEET->param($_ => $pc{$_});
}

### 技能 --------------------------------------------------
my @classes; my %classes; my $class_text;
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
foreach my $key (sort {$classes{$b} <=> $classes{$a}} keys %classes){ $class_text .= ($class_text ? ',' : '').$key.$classes{$key}; }
$SHEET->param(Classes => \@classes);

### 求道者 --------------------------------------------------
if($pc{'lvSeeker'}){
  my @seeker;
  my $lv = $pc{'lvSeeker'};
  push(@seeker, { "NAME" => '全能力値上昇', 'LV' => ($lv >= 17 ? 'Ⅴ' : $lv >= 13 ? 'Ⅳ' : $lv >=  9 ? 'Ⅲ' : $lv >=  5 ? 'Ⅱ' : 'Ⅰ') } ) if $lv >= 1;
  push(@seeker, { "NAME" => '防護点上昇'  , 'LV' => ($lv >= 18 ? 'Ⅴ' : $lv >= 14 ? 'Ⅳ' : $lv >= 10 ? 'Ⅲ' : $lv >=  6 ? 'Ⅱ' : 'Ⅰ') } ) if $lv >= 1;
  push(@seeker, { "NAME" => '成長枠獲得'  , 'LV' => ($lv >= 19 ? 'Ⅴ' : $lv >= 15 ? 'Ⅳ' : $lv >= 11 ? 'Ⅲ' : $lv >=  7 ? 'Ⅱ' : 'Ⅰ') } ) if $lv >= 1;
  push(@seeker, { "NAME" => '特殊能力獲得', 'LV' => ($lv >= 20 ? 'Ⅴ' : $lv >= 16 ? 'Ⅳ' : $lv >= 12 ? 'Ⅲ' : $lv >=  8 ? 'Ⅱ' : 'Ⅰ') } ) if $lv >= 1;
  $SHEET->param(Seeker => \@seeker);
}

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
  next if $pc{'level'} < $_;
  push(@feats_lv, { "NAME" => $pc{'combatFeatsLv'.$_}, "LV" => $_ } );
}
if($pc{'buildupAddFeats'}){
  foreach ($pc{'level'}+1 .. $pc{'level'}+$pc{'buildupAddFeats'}){
    push(@feats_lv, { "NAME" => $pc{'combatFeatsLv'.$_}, "LV" => '+' } );
  }
}
$SHEET->param(CombatFeatsLv => \@feats_lv);

## 自動習得
my @feats_auto;
foreach (split /,/, $pc{'combatFeatsAuto'}) {
  push(@feats_auto, { "NAME" => $_ } );
}
$SHEET->param(CombatFeatsAuto => \@feats_auto);

### 特殊能力 --------------------------------------------------
my @seeker_abilities;
foreach (1..5){
  last if ($_ == 1 && $pc{'lvSeeker'} < 4);
  last if ($_ == 2 && $pc{'lvSeeker'} < 8);
  last if ($_ == 3 && $pc{'lvSeeker'} < 12);
  last if ($_ == 4 && $pc{'lvSeeker'} < 16);
  last if ($_ == 5 && $pc{'lvSeeker'} < 20);
  push(@seeker_abilities, { "NAME" => $pc{'seekerAbility'.$_} });
}
$SHEET->param(SeekerAbilities => \@seeker_abilities);

### 秘伝 --------------------------------------------------
my @mystic_arts; my %mysticarts_honor;
foreach (1..$pc{'mysticArtsNum'}){
  my $type = $pc{'mysticArts'.$_.'PtType'} || 'human';
  $mysticarts_honor{$type} += $pc{'mysticArts'.$_.'Pt'};
  next if !$pc{'mysticArts'.$_};
  push(@mystic_arts, { "NAME" => $pc{'mysticArts'.$_} });
}
my $mysticarts_honor = $mysticarts_honor{'human'}
                     .($mysticarts_honor{'barbaros'}?"<br><small>蛮</small>$mysticarts_honor{'barbaros'}":'')
                     .($mysticarts_honor{'dragon'}  ?"<br><small>竜</small>$mysticarts_honor{'dragon'}"  :'');
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
foreach my $class (@data::class_caster){
  next if !$data::class{$class}{'magic'}{'data'};
  my $lv = $pc{'lv'.$data::class{$class}{'id'}};
  my $add = $pc{ 'buildupAdd'.ucfirst($data::class{$class}{'magic'}{'eName'}) };
  if($class eq 'ウィザード'){ $lv = min($pc{'lvSor'},$pc{'lvCon'}); }
  next if !$lv;
  next if $data::class{$class}{'magic'}{'trancendOnly'} && $lv+$add <= 15;
  
  my @magics;
  foreach (1 .. $lv + $pc{$data::class{$class}{'magic'}{'eName'}.'Addition'}){
    next if $data::class{$class}{'magic'}{'trancendOnly'} && $_ <= 15;
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
  my $add = $pc{ $data::class{$class}{'craft'}{'eName'}.'Addition' }
          + $pc{ 'buildupAdd'.ucfirst($data::class{$class}{'craft'}{'eName'}) };
  next if !$lv;
  
  if($class eq 'アーティザン'){ $add += $pc{'lvArt'} >= 17 ? 2 : $pc{'lvArt'} >= 16 ? 1 : 0; }

  my @crafts;
  foreach (1 .. $lv + $add){
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
if($pc{'forbiddenMode'}){
  foreach(1..rand(3)+1){
    push(@language, { "NAME" => noiseTextTag noiseText(4,8) });
  }
}
else {
  my $exist_listen;
  foreach (@{$data::race_language{ $pc{'race'} }}){
    last if $pc{'languageAutoOff'};
    push(@language, {
      "NAME" => @$_[0],
      "TALK" => langConvert(@$_[1]),
      "READ" => langConvert(@$_[2]),
      "TALK/READ" => (@$_[1]?'会話':'').(@$_[1] && @$_[2] ? '／' : '').(@$_[2]?'読文':'')
    });
  }
  foreach (1 .. $pc{'languageNum'}) {
    next if !$pc{'language'.$_};
    push(@language, {
      "NAME" => $pc{'language'.$_},
      "TALK" => langConvert($pc{'language'.$_.'Talk'}),
      "READ" => langConvert($pc{'language'.$_.'Read'}),
      "TALK/READ" => ($pc{'language'.$_.'Talk'} eq 'listen' ? '聞取' : $pc{'language'.$_.'Talk'} ? '会話' : '').
                     ($pc{'language'.$_.'Talk'} && $pc{'language'.$_.'Read'} ? '／' : '').
                     ($pc{'language'.$_.'Read'}?'読文':'')
    } );
  }
  if($exist_listen){ $SHEET->param(languageListenOnlyExist => 1); }
  sub langConvert {
    my $v = shift;
    if($v eq 'listen'){ $exist_listen = 1; return '△'; }
    elsif($v){ return '○' }
    else{ return '' }
  }
}
$SHEET->param(Language => \@language);

### パッケージ --------------------------------------------------
## ウォーリーダー：軍師の知略
my $war_int_initiative;
foreach(1 .. $pc{'lvWar'}+$pc{'commandAddition'}){
  if($pc{'craftCommand'.$_} =~ /軍師の知略$/){ $war_int_initiative = 1; last; }
}
if(!$war_int_initiative){ delete $data::class{'ウォーリーダー'}{'package'}{'Int'} }
## 共通処理
my @packages;
foreach my $class (@data::class_names){
  my $c_id = $data::class{$class}{'id'};
  next if !$data::class{$class}{'package'} || !$pc{'lv'.$c_id};

  my $c_en = $data::class{$class}{'eName'};
  my %data = %{$data::class{$class}{'package'}};
  my @pack;
  foreach my $p_id (sort{$data{$a}{'stt'} cmp $data{$b}{'stt'} || $data{$a} cmp $data{$b}} keys %data){
    (my $p_name = $data{$p_id}{'name'}) =~ s/(\(.+?\))/<small>$1<\/small>/;
    push(@pack, {
      'name'  => $p_name,
      'add'   => $pc{'pack'.$c_id.$p_id.'Add'},
      'total' => $pc{'pack'.$c_id.$p_id},
    });
  }
  push(@packages, {
    'class'   => $class,
    'lv'      => $pc{'lv'.$c_id},
    'colspan' => scalar(@pack),
    'Packs'   => \@pack,
  });
}
$SHEET->param("Packages" => \@packages);

### 妖精契約 --------------------------------------------------
my $fairy_contact;
my $fairy_sim_url;
if($::SW2_0){
  $fairy_sim_url = 'https://yutorize.2-d.jp/ft_sim/?ft='
    . convert10to36($pc{"lvFai"})
    . convert10to36($pc{"fairyContractEarth"})
    . convert10to36($pc{"fairyContractWater"})
    . convert10to36($pc{"fairyContractFire"})
    . convert10to36($pc{"fairyContractWind"})
    . convert10to36($pc{"fairyContractLight"})
    . convert10to36($pc{"fairyContractDark"})
  ;
  $fairy_contact .= '<span class="ft-earth">土<br>'.($pc{'fairyContractEarth'}||0).'</span>';
  $fairy_contact .= '<span class="ft-water">水<br>'.($pc{'fairyContractWater'}||0).'</span>';
  $fairy_contact .= '<span class="ft-fire" >炎<br>'.($pc{'fairyContractFire' }||0).'</span>';
  $fairy_contact .= '<span class="ft-wind" >風<br>'.($pc{'fairyContractWind' }||0).'</span>';
  $fairy_contact .= '<span class="ft-light">光<br>'.($pc{'fairyContractLight'}||0).'</span>';
  $fairy_contact .= '<span class="ft-dark" >闇<br>'.($pc{'fairyContractDark' }||0).'</span>';
}
else {
  $fairy_contact .= '<span class="ft-earth">土</span>' if $pc{'fairyContractEarth'};
  $fairy_contact .= '<span class="ft-water">水</span>' if $pc{'fairyContractWater'};
  $fairy_contact .= '<span class="ft-fire" >炎</span>' if $pc{'fairyContractFire' };
  $fairy_contact .= '<span class="ft-wind" >風</span>' if $pc{'fairyContractWind' };
  $fairy_contact .= '<span class="ft-light">光</span>' if $pc{'fairyContractLight'};
  $fairy_contact .= '<span class="ft-dark" >闇</span>' if $pc{'fairyContractDark' };
}
### 魔力 --------------------------------------------------
my @magic;
foreach my $class (@data::class_caster){
  my $id   = $data::class{$class}{'id'};
  my $name = $data::class{$class}{'magic'}{'jName'};
  next if !$name;
  next if !$pc{'lv'.$id};
  
  my $power  = $pc{'magicPowerAdd' .$id} + $pc{'magicPowerAdd'} +$pc{'magicPowerEnhance'};
  my $cast   = $pc{'magicCastAdd'  .$id} + $pc{'magicCastAdd'};
  my $damage = $pc{'magicDamageAdd'.$id} + $pc{'magicDamageAdd'};
  
  my $title = $class.'<span class="small">技能レベル</span>'.$pc{'lv'.$id};
  if($class eq 'ウィザード'){ $title = 'ウィザード<span class="small">最大魔法レベル</span>'.min($pc{'lvSor'},$pc{'lvCon'}); }
  
  my $magicname = $name;
  if($id eq 'Fai'){
    $magicname = ($fairy_sim_url ? "<a href=\"$fairy_sim_url\" target=\"_blank\">$name</a>" : $name)
               . ($fairy_contact ? "<div id=\"fairycontact\">$fairy_contact</div>" : '')
  }
  push(@magic, {
    "NAME" => $title,
    "OWN"  => ($pc{'magicPowerOwn'.$id} ? '✔<span class="small">知力+2</span>' : ''),
    "MAGIC"  => $magicname,
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
  
  my $power  = $pc{'magicPowerAdd' .$id} || 0;
  my $cast   = $pc{'magicCastAdd'  .$id} || 0;
  my $damage = $pc{'magicDamageAdd'.$id} || 0;
  
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
if(!$pc{'forbiddenMode'}){
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
      "DMG"  => @$_[1] eq 'Dem' ? '―' : $pc{'lv'.@$_[1]}+$pc{'bonusStr'},
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
}
$SHEET->param(AttackClasses => \@atacck);

### 武器 --------------------------------------------------
my @weapons;
if($pc{'forbiddenMode'}){
  push(@weapons,{
    "NAME"     => noiseTextTag(noiseText(4,8)),
    "USAGE"    => noiseTextTag(noiseText(1)),
    "REQD"     => noiseTextTag(noiseText(1)),
    "ACCTOTAL" => noiseTextTag(noiseText(1)),
    "RATE"     => noiseTextTag(noiseText(1)),
    "CRIT"     => noiseTextTag(noiseText(1)),
    "DMGTOTAL" => noiseTextTag(noiseText(1)),
    "NOTE"     => noiseTextTag(noiseText(4,8)),
  });
}
else {
  my $first = 1;
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
}
$SHEET->param(Weapons => \@weapons);
### 回避技能／特技 --------------------------------------------------
if(!$pc{'forbiddenMode'}){
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
  if($pc{'lvSeeker'}) {
    push(@evasion, {
      "NAME" => "求道者：防護点上昇",
      "DEF"  => $pc{'defenseSeeker'},
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
      "NAME" => "《回避行動".($pc{'evasiveManeuver'} >= 2 ? 'Ⅱ' : 'Ⅰ')."》",
      "EVA"  => $pc{'evasiveManeuver'},
    } );
  }
  if($pc{'mindsEye'}) {
    push(@evasion, {
      "NAME" => "《心眼》",
      "EVA"  => $pc{'mindsEye'},
    } );
  }
  $SHEET->param(EvasionClasses => \@evasion);
}
### 防具 --------------------------------------------------
if($pc{'forbiddenMode'}){
  my @armours;
  foreach(1..3){
    push(@armours, {
      "TH"   => noiseTextTag(noiseText(1)),
      "NAME" => noiseTextTag(noiseText(4,8)),
      "REQD" => noiseTextTag(noiseText(1)),
      "EVA"  => noiseTextTag(noiseText(1)),
      "DEF"  => noiseTextTag(noiseText(1)),
      "NOTE" => noiseTextTag(noiseText(4,8)),
    });
  }
  $SHEET->param(Armours => \@armours);
}
else {
  my @armours;
  my @list = (
    ['鎧','armour1'],
    ['盾','shield1'],
    ['他1','defOther1'],
    ['他2','defOther2'],
    ['他3','defOther3'],
  );
  foreach (@list){
    next if $pc{@$_[1].'Name'} eq '' && !$pc{@$_[1].'Eva'} && !$pc{@$_[1].'Def'};
    push(@armours, {
      "TH"   => @$_[0],
      "NAME" => $pc{@$_[1].'Name'},
      "REQD" => $pc{@$_[1].'Reqd'},
      "EVA"  => $pc{@$_[1].'Eva'},
      "DEF"  => $pc{@$_[1].'Def'},
      "OWN"  => $pc{@$_[1].'Own'},
      "NOTE" => $pc{@$_[1].'Note'},
    } );
  }
  $SHEET->param(Armours => \@armours);
  
  my @total;
  foreach my $i (1..3){
    my @ths;
    foreach (@list){
      if($pc{"defTotal${i}Check".ucfirst(@$_[1])} && ($pc{@$_[1].'Name'} || $pc{@$_[1].'Eva'} || $pc{@$_[1].'Def'})){
        push(@ths, @$_[0]);
      }
    }
    next if !@ths;
    push(@total, {
      "TH"   => (@ths == @armours ? 'すべて' : join('＋', @ths)),
      "EVA"  => $pc{"defenseTotal${i}Eva"},
      "DEF"  => $pc{"defenseTotal${i}Def"},
      "NOTE" => $pc{"defenseTotal${i}Note"},
    } );
  }
  $SHEET->param(ArmourTotals => \@total);
}
### 装飾品 --------------------------------------------------
  my @accessories;
if($pc{'forbiddenMode'}){
  foreach(1..rand(3)+3){
    push(@accessories, {
      "TYPE" => noiseTextTag(noiseText(1)),
      "NAME" => noiseTextTag(noiseText(4,8)),
      "NOTE" => noiseTextTag(noiseText(6,13)),
    });
  }
  $SHEET->param(Accessories => \@accessories);
}
else {
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
}
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
  if   ($pc{"history${_}HonorType"} eq 'barbaros'){ $pc{"history${_}Honor"} = '蛮'.$pc{"history${_}Honor"}; }
  elsif($pc{"history${_}HonorType"} eq 'dragon'  ){ $pc{"history${_}Honor"} = '竜'.$pc{"history${_}Honor"}; }
  $pc{'history'.$_.'Money'} =~ s/([0-9]+)/$1<wbr>/g;
  $pc{'history'.$_.'Money'} =~ s/([0-9]+)/commify($1);/ge;
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
$SHEET->param(historyExpTotal   => commify $pc{'historyExpTotal'}   );
$SHEET->param(hisotryHonorTotal => commify $pc{'hisotryHonorTotal'} );
$SHEET->param(hisotryMoneyTotal => commify $pc{'hisotryMoneyTotal'} );


### 名誉アイテム --------------------------------------------------
my @honoritems;
foreach (1 .. $pc{'honorItemsNum'}) {
  next if !$pc{'honorItem'.$_} && !$pc{'honorItem'.$_.'Pt'};
  my $type;
  if   ($pc{"honorItem${_}PtType"} eq 'barbaros'){ $type = '<small>蛮</small>'; }
  elsif($pc{"honorItem${_}PtType"} eq 'dragon'  ){ $type = '<small>竜</small>'; }
  push(@honoritems, {
    "NAME" => $pc{'honorItem'.$_},
    "PT"   => $type.$pc{'honorItem'.$_.'Pt'},
  } );
}
$SHEET->param(HonorItems => \@honoritems);

my @dishonoritems;
foreach (1 .. $pc{'dishonorItemsNum'}) {
  next if !$pc{'dishonorItem'.$_} && !$pc{'dishonorItem'.$_.'Pt'};
  my $type;
  if   ($pc{"dishonorItem${_}PtType"} eq 'barbaros'){ $type = '<small>蛮</small>'; }
  elsif($pc{"dishonorItem${_}PtType"} eq 'dragon'  ){ $type = '<small>竜</small>'; }
  push(@dishonoritems, {
    "NAME" => $pc{'dishonorItem'.$_},
    "PT"   => $type.$pc{'dishonorItem'.$_.'Pt'},
  } );
}
$SHEET->param(DishonorItems => \@dishonoritems);

if($::SW2_0){
  foreach (@set::adventurer_rank){
    my ($name, $num) = @$_;
    last if ($pc{'honor'} < $num);
    $SHEET->param(rank => $name);
  }
  foreach (@set::notoriety_rank){
    my ($name, $num) = @$_;
    $SHEET->param(notoriety => $name) if $pc{'dishonor'} >= $num;
  }
}
else {
  foreach (@set::adventurer_rank){
    my ($name, $num, undef) = @$_;
    $SHEET->param(rankHonorValue => $num) if ($pc{'rank'} eq $name);
  }
  foreach (@set::notoriety_rank){
    my ($name, $num) = @$_;
    $SHEET->param(notoriety => $name) if $pc{'dishonor'} >= $num;
  }
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
if($::in{'id'}){
  opendir(my $DIR,"${set::char_dir}${main::file}/backup");
  my @backlist = readdir($DIR);
  closedir($DIR);
  my @backup;
  foreach (reverse sort @backlist) {
    if ($_ =~ s/\.cgi//) {
      my $url = $_;
      $_ =~ s/^([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})-([0-9]{2})$/$1 $2\:$3/;
      push(@backup, {
        "NOW"  => ($url eq $::in{'backup'} ? 1 : 0),
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
$SHEET->param(FellowMode => $::in{'f'});

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{'forbidden'} eq 'all' && $pc{'forbiddenMode'}){
  $SHEET->param(characterNameTitle => '非公開データ');
}
else {
  $SHEET->param(characterNameTitle => tag_delete name_plain($pc{'characterName'}||"“$pc{'aka'}”"));
}

### 画像 --------------------------------------------------
my $imgsrc;
if($pc{'convertSource'} eq '別のゆとシートⅡ') {
  $imgsrc = $pc{'imageURL'}."?$pc{'imageUpdate'}";
}
else {
  $imgsrc = "${set::char_dir}${main::file}/image.$pc{'image'}?$pc{'imageUpdate'}";
}
$SHEET->param("imageSrc" => $imgsrc);

if($pc{'imageFit'} eq 'percentY'){
  $SHEET->param("imageFit" => 'auto '.$pc{'imagePercent'}.'%');
}
elsif($pc{'imageFit'} =~ /^percentX?$/){
  $SHEET->param("imageFit" => $pc{'imagePercent'}.'%');
}

## 権利表記
if($pc{'imageCopyrightURL'}){
  $pc{'imageCopyright'} = $pc{'imageCopyrightURL'} if !$pc{'imageCopyright'};
  $SHEET->param(imageCopyright => "<a href=\"$pc{'imageCopyrightURL'}\" target=\"_blank\">$pc{'imageCopyright'}</a>");
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{'url'} ? "?url=$::in{'url'}" : "?id=$::in{'id'}"));
if($pc{'image'}) { $SHEET->param(ogImg => url()."/".$imgsrc); }
$SHEET->param(ogDescript => tag_delete "種族:$pc{'race'}　性別:$pc{'gender'}　年齢:$pc{'age'}　技能:${class_text}");

### バージョン等 --------------------------------------------------
$SHEET->param("ver" => $::ver);
$SHEET->param("coreDir" => $::core_dir);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $SHEET->output;

1;