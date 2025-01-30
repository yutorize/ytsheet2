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
    $pc{group} = $pc{tags} = '';
    
    $pc{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc{freeNote} .= '　'.noiseText(18,40)."\n";
    }
    $pc{freeHistory} = '';
  }
  
  $pc{age}    = noiseText(1,2);
  $pc{gender} = noiseText(1,2);
  $pc{birth}  = noiseText(2,4);
  $pc{race}        = noiseText(3,8);
  $pc{raceAbility} = noiseText(4,16);
  $pc{sin} = noiseText(1);
  $pc{faith}  = noiseText(6,10);
  $pc{rank}   = noiseText(3,5);
  
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
  
  $pc{expRest}  = noiseText(2,3);
  $pc{expTotal} = noiseText(2,3);
  $pc{level} = noiseText(1);
  $pc{lvWiz} = $pc{lvSeeker} = $pc{lvMonster} = 0;
  foreach my $class (@data::class_names){ $pc{ 'lv'.$data::class{$class}{id} } = 0; }
  foreach (1 .. 10){ $pc{'commonClass'.$_} = ''; }
  $pc{monsterLore} = noiseText(1);
  $pc{initiative}  = noiseText(1);
  $pc{mobilityLimited} = noiseText(1);
  $pc{mobilityTotal}   = noiseText(1);
  $pc{mobilityFull}    = noiseText(1,2);
  
  $pc{combatFeatsAuto} = '';
  $pc{mysticArtsNum} = '';
  
  $pc{languageNum} = 1;
  foreach (1 .. $pc{languageNum}){
    $pc{'language'.$_} = '不明';
    $pc{'language'.$_.'Read'} = $pc{'language'.$_.'Talk'} = '';
  }
  
  $pc{honor} = $pc{dishonor} = $pc{honorOffset} = noiseText(1,2);
  $pc{honorItemsNum} = $pc{dishonorItemsNum} = $pc{rankHonorValue} = $pc{MysticArtsHonor} = '';
  
  $pc{money}   = noiseText(3,6);
  $pc{deposit} = noiseText(3,6);
  $pc{items} = '';
  foreach(1..int(rand 3)+6){
    $pc{items} .= noiseText(6,24)."\n";
  }
  $pc{cashbook} = '';
  
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
  $pc{freeNote} = $pc{freeNoteView} if $pc{freeNoteView};
}

### コンバート --------------------------------------------------
foreach (1..17) {
  $pc{'craftGramarye'.$_} = $pc{'craftGramarye'.$_} || $pc{'magicGramarye'.$_};
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

### セリフ --------------------------------------------------
{
  my ($words, $x, $y) = stylizeWords($pc{words},$pc{wordsX},$pc{wordsY});
  $SHEET->param(words => $words);
  $SHEET->param(wordsX => $x);
  $SHEET->param(wordsY => $y);
}
### 種族名 --------------------------------------------------
$pc{race} =~ s/［.*］//g;
{
  my $race = $pc{race};
  if($race =~ /^(.+?)[（(](.+?)[)）]/){
    my $base    = $1;
    my $variant = $2;
    if($variant =~ /$base/){ $race = $variant }
    else { $race =~ s|[（(].+?[)）]|<span class="variant">$&</span>|g; }
  }
  $SHEET->param(race => $race);
}
### 種族特徴 --------------------------------------------------
$pc{raceAbility} =~ s/［(.*?)］/<span>［$1］<\/span>/g;
$SHEET->param(raceAbility => $pc{raceAbility});

### 穢れ --------------------------------------------------
if (!$pc{sin}){ 
  $SHEET->param(sin => ($pc{race} =~ /^(?:ルーンフォーク|フィー)$/) ? '―' : 0);
}
### 信仰 --------------------------------------------------
if($pc{faith} eq 'その他の信仰') { $SHEET->param(faith => $pc{faithOther}); }
$pc{faith} =~ s/“(.*)”//;

### 経験点 --------------------------------------------------
$pc{expUsed} = $pc{expTotal} - $pc{expRest};
foreach('expUsed','expTotal','expRest'){
  $SHEET->param($_ => commify $pc{$_});
}
### 能力値 --------------------------------------------------
foreach ('A'..'F'){
  my $value = $pc{'sttAdd'.$_} + $pc{'sttEquip'.$_};
  $SHEET->param('sttAdd'.$_ => $value) if $value;
}

### HPなど --------------------------------------------------
foreach('vitResistAddTotal','mndResistAddTotal','hpAddTotal','mpAddTotal','mobilityAddTotal','monsterLoreAdd','initiativeAdd'){
  $SHEET->param($_ => addNum $pc{$_});
}

### 技能 --------------------------------------------------
my @classes; my %classes; my $class_text;
foreach my $class (@data::class_names){
  my $id   = $data::class{$class}{id};
  next if !$pc{'lv'.$id};
  my $name = $class;
  if($name eq 'プリースト' && $pc{faith}){
    my $faith = $pc{faith};
    if ($faith eq 'その他の信仰') {
      $faith = $pc{faithOther};
      $faith =~ s#<a [^>]*>([^<]+?)</a>#$1#s; # 未定義の神格の場合、ゆとシの神格シートなどへのハイパーリンクが想定されるので、それを除去する
      $faith =~ s/^[“”"].*[“”"](.+$)/$1/;
    }
    $name .= '<span class="priest-faith'.(length($faith) > 12 ? ' narrow' : "").'">（'.$faith.$pc{faithType}.'）</span>';
  }
  push(@classes, { NAME => $name, LV => $pc{'lv'.$id} } );
  $classes{$class} = $pc{'lv'.$id};
}
@classes = sort{$b->{LV} <=> $a->{LV}} @classes;
foreach my $key (sort {$classes{$b} <=> $classes{$a}} keys %classes){ $class_text .= ($class_text ? ',' : '').$key.$classes{$key}; }
$SHEET->param(Classes => \@classes);

### 求道者 --------------------------------------------------
if($pc{lvSeeker}){
  my @seeker;
  my $lv = $pc{lvSeeker};
  push(@seeker, { NAME => '全能力値上昇', LV => ($lv >= 17 ? 'Ⅴ' : $lv >= 13 ? 'Ⅳ' : $lv >=  9 ? 'Ⅲ' : $lv >=  5 ? 'Ⅱ' : 'Ⅰ') } ) if $lv >= 1;
  push(@seeker, { NAME => '防護点上昇'  , LV => ($lv >= 18 ? 'Ⅴ' : $lv >= 14 ? 'Ⅳ' : $lv >= 10 ? 'Ⅲ' : $lv >=  6 ? 'Ⅱ' : 'Ⅰ') } ) if $lv >= 1;
  push(@seeker, { NAME => '成長枠獲得'  , LV => ($lv >= 19 ? 'Ⅴ' : $lv >= 15 ? 'Ⅳ' : $lv >= 11 ? 'Ⅲ' : $lv >=  7 ? 'Ⅱ' : 'Ⅰ') } ) if $lv >= 1;
  push(@seeker, { NAME => '特殊能力獲得', LV => ($lv >= 20 ? 'Ⅴ' : $lv >= 16 ? 'Ⅳ' : $lv >= 12 ? 'Ⅲ' : $lv >=  8 ? 'Ⅱ' : 'Ⅰ') } ) if $lv >= 1;
  $SHEET->param(Seeker => \@seeker);
}

### 一般技能 --------------------------------------------------
my @common_classes;
my $commonClassTotalLevel = 0;
foreach (1..10){
  next if !$pc{'commonClass'.$_};
  $pc{'commonClass'.$_} =~ s#([（\(].+?[\)）])#<span class="small">$1</span>#g;
  push(@common_classes, { "NAME" => $pc{'commonClass'.$_}, "LV" => $pc{'lvCommon'.$_} } );
  $commonClassTotalLevel += $pc{'lvCommon'.$_};
}
$SHEET->param(CommonClasses => \@common_classes);
$SHEET->param(CommonClassTotalLevel => $commonClassTotalLevel);

### 戦闘特技 --------------------------------------------------
my %acquired;
my @feats_lv;
foreach ('1bat',@set::feats_lv){
  (my $lv = $_) =~ s/^([0-9]+)[^0-9].*?$/$1/;
  if($_ =~ /bat/ && !$pc{lvBat}){ next; }
  next if $pc{level} < $lv;
  push(@feats_lv, { NAME => $pc{'combatFeatsLv'.$_}, "LV" => $lv.($_ =~ /bat/ ? '+' : '') } );
  $acquired{$pc{'combatFeatsLv'.$_}} = 1;
}
if($pc{buildupAddFeats}){
  foreach ($pc{level}+1 .. $pc{level}+$pc{buildupAddFeats}){
    push(@feats_lv, { NAME => $pc{'combatFeatsLv'.$_}, "LV" => '+' } );
    $acquired{$pc{'combatFeatsLv'.$_}} = 1;
  }
}
$SHEET->param(CombatFeatsLv => \@feats_lv);

## 自動習得
my @feats_auto;
foreach (split /,/, $pc{combatFeatsAuto}) {
  push(@feats_auto, { NAME => $_ } );
}
$SHEET->param(CombatFeatsAuto => \@feats_auto);

### 特殊能力 --------------------------------------------------
my @seeker_abilities;
foreach (1..5){
  last if ($_ == 1 && $pc{lvSeeker} < 4);
  last if ($_ == 2 && $pc{lvSeeker} < 8);
  last if ($_ == 3 && $pc{lvSeeker} < 12);
  last if ($_ == 4 && $pc{lvSeeker} < 16);
  last if ($_ == 5 && $pc{lvSeeker} < 20);
  push(@seeker_abilities, { "NAME" => $pc{'seekerAbility'.$_} });
}
$SHEET->param(SeekerAbilities => \@seeker_abilities);

### 秘伝 --------------------------------------------------
my @mystic_arts; my %mysticarts_honor;
foreach (1..$pc{mysticArtsNum}){
  my $type = $pc{'mysticArts'.$_.'PtType'} || 'human';
  $mysticarts_honor{$type} += $pc{'mysticArts'.$_.'Pt'};
  next if !$pc{'mysticArts'.$_};
  my ($name, $mark) = checkArtsName $pc{'mysticArts'.$_};
  push(@mystic_arts, { "NAME" => "$mark《$name》" });
}
foreach (1..$pc{mysticMagicNum}){
  my $type = $pc{'mysticMagic'.$_.'PtType'} || 'human';
  $mysticarts_honor{$type} += $pc{'mysticMagic'.$_.'Pt'};
  next if !$pc{'mysticMagic'.$_};
  my ($name, $mark) = checkArtsName $pc{'mysticMagic'.$_};
  push(@mystic_arts, { "NAME" => "$mark【$name】" });
}
my $mysticarts_honor = $mysticarts_honor{human}
                     .($mysticarts_honor{barbaros}?"<br><small>蛮</small>$mysticarts_honor{barbaros}":'')
                     .($mysticarts_honor{dragon}  ?"<br><small>竜</small>$mysticarts_honor{dragon}"  :'');
$SHEET->param(MysticArts => \@mystic_arts);
$SHEET->param(MysticArtsHonor => $mysticarts_honor);

### 秘奥魔法 --------------------------------------------------
my %gramarye_ruby;
foreach (@{$data::class{'グリモワール'}{magic}{data}}){
  $gramarye_ruby{@$_[1]} = @$_[2];
}
### 魔法 --------------------------------------------------
my $craft_none = 1;
my @magic_lists;
foreach my $class (@data::class_caster){
  next if !$data::class{$class}{magic}{data};
  my $lv = $pc{'lv'.$data::class{$class}{id}};
  my $add = $pc{ 'buildupAdd'.ucfirst($data::class{$class}{magic}{eName}) };
  if($class eq 'ウィザード'){ $lv = min($pc{lvSor},$pc{lvCon}); }
  next if !$lv;
  next if $data::class{$class}{magic}{trancendOnly} && $lv+$add <= 15;
  
  my @magics;
  foreach (1 .. $lv + $pc{$data::class{$class}{magic}{eName}.'Addition'}){
    next if $data::class{$class}{magic}{trancendOnly} && $_ <= 15;
    my $magic = $pc{'magic'.ucfirst($data::class{$class}{magic}{eName}).$_};
    
    if($class eq 'グリモワール'){
      push(@magics, { NAME => "－${magic}－", "RUBY" => "data-ruby=\"$gramarye_ruby{$magic}\"" } );
    }
    else { push(@magics, { NAME => $magic } ); }
  }
  
  push(@magic_lists, { "jNAME" => $data::class{$class}{magic}{jName}, "eNAME" => $data::class{$class}{magic}{eName}, "MAGICS" => \@magics } );
  $craft_none = 0;
}
$SHEET->param(MagicLists => \@magic_lists);

### 技芸 --------------------------------------------------
my @craft_lists;
my $enhance_attack_on;
my $rider_obs_on;
foreach my $class (@data::class_names){
  next if !$data::class{$class}{craft}{data};
  my $lv = $pc{'lv'.$data::class{$class}{id}};
  my $add = $pc{ $data::class{$class}{craft}{eName}.'Addition' }
          + $pc{ 'buildupAdd'.ucfirst($data::class{$class}{craft}{eName}) };
  next if !$lv;
  
  if($class eq 'アーティザン'){ $add += $pc{lvArt} >= 17 ? 2 : $pc{lvArt} >= 16 ? 1 : 0; }

  my %craftType;
  foreach (@{$data::class{$class}{craft}{data}}){
    my $craft = $_->[1];
    my $notes = $_->[2];
    if($class eq 'アルケミスト'){
      while($notes =~ s/\[([赤緑黒白金])\]//){ $craftType{$craft} .= '<i class="s-icon m-card" data-color="'.$1.'"></i>' }
    }
    if($notes =~ /(\[[常主補準宣]\])+/){ $craftType{$craft} .= textToIcon $&; }
  }

  my @crafts;
  foreach (1 .. $lv + $add){
    my $craft = $pc{'craft'.ucfirst($data::class{$class}{craft}{eName}).$_};
    
    $acquired{$craft} = 1;
    
    if($::SW2_0){
      push(@crafts, { NAME => $craft, } );
    }
    else {
      my ($name, $mark) = checkArtsName "$craftType{$craft}$craft";
      push(@crafts, { NAME => $name, MARK => $mark } );
    }
  }
  
  push(@craft_lists, { "jNAME" => $data::class{$class}{craft}{jName}, "eNAME" => $data::class{$class}{craft}{eName}, "CRAFTS" => \@crafts } );
  $craft_none = 0;
}
$SHEET->param(CraftLists => \@craft_lists);
$SHEET->param(craftNone => $craft_none);

### 言語 --------------------------------------------------
my @language;
if($pc{forbiddenMode}){
  foreach(1..rand(3)+1){
    push(@language, { "NAME" => noiseTextTag noiseText(4,8) });
  }
}
else {
  my $exist_listen;
  foreach (@{$data::races{ $pc{race} }{language}}){
    last if $pc{languageAutoOff};
    push(@language, {
      NAME => @$_[0],
      TALK => langConvert(@$_[1]),
      READ => langConvert(@$_[2]),
      TALKnREAD => (@$_[1]?'会話':'').(@$_[1] && @$_[2] ? '／' : '').(@$_[2]?'読文':'')
    });
  }
  foreach (1 .. $pc{languageNum}) {
    next if !$pc{'language'.$_};
    push(@language, {
      NAME => $pc{'language'.$_},
      TALK => langConvert($pc{'language'.$_.'Talk'}),
      READ => langConvert($pc{'language'.$_.'Read'}),
      TALKnREAD => ($pc{'language'.$_.'Talk'} eq 'listen' ? '聞取' : $pc{'language'.$_.'Talk'} ? '会話' : '').
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
## 共通処理
my @packages;
foreach my $class (@data::class_names){
  my $c_id = $data::class{$class}{id};
  next if !$data::class{$class}{package} || !$pc{'lv'.$c_id};

  my $c_en = $data::class{$class}{eName};
  my %data = %{$data::class{$class}{package}};
  my @pack;
  foreach my $p_id (sort{$data{$a}{stt} cmp $data{$b}{stt} || $data{$a} cmp $data{$b}} keys %data){
    next if(exists $data{$p_id}{unlockCraft} && !$acquired{$data{$p_id}{unlockCraft}});
    (my $p_name = $data{$p_id}{name}) =~ s/(\(.+?\))/<small>$1<\/small>/;
    push(@pack, {
      name  => $p_name,
      add   => addNum($pc{'pack'.$c_id.$p_id.'Add'}+$pc{'pack'.$c_id.$p_id.'Auto'}),
      total => $pc{'pack'.$c_id.$p_id},
    });
  }
  push(@packages, {
    class   => $class,
    lv      => $pc{'lv'.$c_id},
    colspan => scalar(@pack),
    Packs   => \@pack,
  });
}
$SHEET->param(Packages => \@packages);

### 妖精契約 --------------------------------------------------
my $fairy_contact;
my $fairy_sim_url;
if($::SW2_0){
  $fairy_sim_url = 'https://yutorize.2-d.jp/ft_sim/?ft='
    . convert10to36($pc{lvFai})
    . convert10to36($pc{fairyContractEarth})
    . convert10to36($pc{fairyContractWater})
    . convert10to36($pc{fairyContractFire})
    . convert10to36($pc{fairyContractWind})
    . convert10to36($pc{fairyContractLight})
    . convert10to36($pc{fairyContractDark})
  ;
  $fairy_contact .= '<span class="ft-earth">土<br>'.($pc{fairyContractEarth}||0).'</span>';
  $fairy_contact .= '<span class="ft-water">水<br>'.($pc{fairyContractWater}||0).'</span>';
  $fairy_contact .= '<span class="ft-fire" >炎<br>'.($pc{fairyContractFire }||0).'</span>';
  $fairy_contact .= '<span class="ft-wind" >風<br>'.($pc{fairyContractWind }||0).'</span>';
  $fairy_contact .= '<span class="ft-light">光<br>'.($pc{fairyContractLight}||0).'</span>';
  $fairy_contact .= '<span class="ft-dark" >闇<br>'.($pc{fairyContractDark }||0).'</span>';
}
else {
  $fairy_contact .= '<span class="ft-earth">土</span>' if $pc{fairyContractEarth};
  $fairy_contact .= '<span class="ft-water">水</span>' if $pc{fairyContractWater};
  $fairy_contact .= '<span class="ft-fire" >炎</span>' if $pc{fairyContractFire };
  $fairy_contact .= '<span class="ft-wind" >風</span>' if $pc{fairyContractWind };
  $fairy_contact .= '<span class="ft-light">光</span>' if $pc{fairyContractLight};
  $fairy_contact .= '<span class="ft-dark" >闇</span>' if $pc{fairyContractDark };
}
### 魔力 --------------------------------------------------
my @magic;
foreach my $class (@data::class_caster){
  my $id   = $data::class{$class}{id};
  my $name = $data::class{$class}{magic}{jName};
  next if !$name;
  next if !$pc{'lv'.$id};
  
  my $power  = $pc{'magicPowerAdd' .$id} + $pc{magicPowerAdd } + $pc{magicPowerEquip } +$pc{magicPowerEnhance};
  my $cast   = $pc{'magicCastAdd'  .$id} + $pc{magicCastAdd  } + $pc{magicCastEquip  };
  my $damage = $pc{'magicDamageAdd'.$id} + $pc{magicDamageAdd} + $pc{magicDamageEquip};
  
  my $title = $class.'<wbr><span class="small">技能レベル</span>'.$pc{'lv'.$id};
  if($class eq 'ウィザード'){ $title = 'ウィザード<span class="small">最大魔法レベル</span>'.min($pc{lvSor},$pc{lvCon}); }
  
  my $magicname = $name;
  if($id eq 'Fai'){
    $magicname = ($fairy_sim_url ? "<a href=\"$fairy_sim_url\" target=\"_blank\">$name</a>" : $name)
               . ($fairy_contact ? "<div id=\"fairycontact\">$fairy_contact</div>" : '');
    if(!$::SW2_0){
      $title .= '<div><span class="small">使用可能ランク</span>'.fairyRank($pc{lvFai},$pc{fairyContractEarth},$pc{fairyContractWater},$pc{fairyContractFire },$pc{fairyContractWind },$pc{fairyContractLight},$pc{fairyContractDark }).'</div>';
    }
  }
  push(@magic, {
    NAME => $title,
    OWN  => ($pc{'magicPowerOwn'.$id} ? '✔<span class="small">知力+2</span>' : ''),
    MAGIC  => $magicname,
    POWER  => ($power ? '<span class="small">'.addNum($power).'=</span>' : '').$pc{'magicPower'.$id},
    CAST   => ($cast ? '<span class="small">'.addNum($cast).'=</span>' : '').($pc{'magicPower'.$id}+$cast),
    DAMAGE => addNum($damage)||'+0',
  } );
}

foreach my $class (@data::class_names){
  my $id    = $data::class{$class}{id};
  my $name  = $data::class{$class}{craft}{jName};
  my $stt   = $data::class{$class}{craft}{stt};
  my $pname = $data::class{$class}{craft}{power};
  next if !$stt;
  next if !$pc{'lv'.$id};
  
  my $power  = $pc{'magicPowerAdd' .$id} || 0;
  my $cast   = $pc{'magicCastAdd'  .$id} || 0;
  my $damage = $pc{'magicDamageAdd'.$id} || 0;
  
  push(@magic, {
    NAME => $class."<wbr><span class=\"small\">技能レベル</span>".$pc{'lv'.$id},
    OWN  => ($pc{'magicPowerOwn'.$id} ? '✔<span class="small">'.$stt.'+2</span>' : ''),
    MAGIC  => $name,
    POWER  => ($pname) ? ($power ? '<span class="small">'.addNum($power).'=</span>' : '').$pc{'magicPower'.$id} : '―',
    CAST   => ($cast ? '<span class="small">'.addNum($cast).'=</span>' : '').($pc{'magicPower'.$id}+$cast),
    DAMAGE => ($pname) ? addNum($damage)||'+0' : '―',
  } );
}
$SHEET->param(MagicPowers => \@magic);
{
  my @head; my @pow; my @act;
  if($pc{lvCaster}) { push(@head, '魔法'); push(@pow, '魔力'); push(@act, '行使'); }
  foreach my $class (@data::class_names){
    my $id    = $data::class{$class}{id};
    next if !$data::class{$class}{craft}{stt};
    next if !$pc{'lv'.$id};
    
    push(@head, $data::class{$class}{craft}{jName});
    push(@pow,  $data::class{$class}{craft}{power}) if $data::class{$class}{craft}{power};
    if($class eq 'バード'){ push(@act, '演奏'); }
    else                  { push(@act, $data::class{$class}{craft}{jName}); }
  }
  
  $SHEET->param(MagicPowerHeader => join('／',@head));
  $SHEET->param(MagicPowerThPow => scalar(@pow) >= 2 ? '<span class="small">'.join('/',@pow).'</span>' : join('/',@pow));
  $SHEET->param(MagicPowerThAct => scalar(@act) >= 3 ? "$act[0]など" : join('/',@act));
}

### 攻撃技能／特技 --------------------------------------------------
my $strTotal = $pc{sttStr}+$pc{sttAddC}+$pc{sttEquipC};
my @atacck;
if(!$pc{forbiddenMode}){
  foreach my $name (@data::class_names){
    my $id = $data::class{$name}{id};
    next if !$pc{'lv'.$id};
    next if !($data::class{$name}{type} eq 'weapon-user' || exists $data::class{$name}{accUnlock});
    if(exists $data::class{$name}{accUnlock}){
      next if $pc{'lv'.$id} < $data::class{$name}{accUnlock}{lv};
    }
    if($data::class{$name}{accUnlock}{feat}){
      my $isUnlock = 0;
      foreach my $feat (split '|',$data::class{$name}{accUnlock}{feat}){
        if($acquired{$feat}){ $isUnlock = 1; last; }
      }
      next if !$isUnlock;
    }
    if($data::class{$name}{accUnlock}{craft}){
      my $isUnlock = 0;
      foreach my $craft (split '|',$data::class{$name}{accUnlock}{feat}){
        if($acquired{$craft}){ $isUnlock = 1; last; }
      }
      next if !$isUnlock;
    }
    my $reqdStr = ($id eq 'Fen' ? ceil($strTotal / 2) : $strTotal)
                . ($pc{reqdStrWeaponMod} ? "+$pc{reqdStrWeaponMod}" : '');
    push(@atacck, {
      NAME => $name."<wbr><span class=\"small\">技能レベル</span>".$pc{'lv'.$id},
      STR  => $reqdStr,
      ACC  => $pc{'lv'.$id}+$pc{bonusDex},
      ($id eq 'Fen' ? (CRIT => '-1') : ('' => '')),
      DMG  => $id eq 'Dem' ? '―' : $pc{'lv'.$id}+$pc{bonusStr},
    } );
  }
  foreach (@data::weapons) {
    next if !$pc{'mastery'.ucfirst(@$_[1])};
    push(@atacck, {
      NAME => "《武器習熟".($pc{'mastery'.ucfirst(@$_[1])} >= 2 ? 'Ｓ' : 'Ａ')."／".@$_[0]."》",
      DMG  => $pc{'mastery'.ucfirst(@$_[1])},
    } );
  }
  if($pc{masteryArtisan}) {
    push(@atacck, {
      NAME => "《".($pc{masteryArtisan} >= 3 ? '魔器の達人' : $pc{masteryArtisan} >= 2 ? '魔器習熟Ｓ' : '魔器習熟Ａ')."》",
      DMG  => $pc{masteryArtisan},
    } );
  }
  if($pc{accuracyEnhance}) {
    push(@atacck, {
      NAME => "《命中強化".($pc{accuracyEnhance}  >= 2  ? 'Ⅱ' : 'Ⅰ')."》",
      ACC  => $pc{accuracyEnhance},
    } );
  }
  if($pc{throwing}) {
    push(@atacck, {
      NAME => "《スローイング".($pc{throwing}  >= 2  ? 'Ⅱ' : 'Ⅰ')."》",
      ACC  => 1,
    } );
  }
}
$SHEET->param(AttackClasses => \@atacck);

### 武器 --------------------------------------------------
sub replaceModificationNotation {
  my $sourceText = shift // '';

  $sourceText =~ s#
      [\@＠]
      (
        器(?:用度?)?(?:増強)?  |
        敏(?:捷度?)?(?:増強)?  |
        筋(?:力)?(?:増強)?     |
        生(?:命力)?(?:増強)?   |
        知力?(?:増強)?         |
        精(?:神力?)?(?:増強)?  |
        生命抵抗力?   |
        精神抵抗力?   |
        回避力?       |
        防(?:護点?)?  |
        移動力        |
        魔力          |
        (?:魔法)?行使(?:判定)?|
        魔法のダメージ|
        武器(?:必要筋力|必筋)上限
      )
      ([＋+－-][0-9]+)
    #<i class="term-em">$1$2</i>#gx;

  return $sourceText;
}

my @weapons;
if($pc{forbiddenMode}){
  push(@weapons,{
    NAME     => noiseTextTag(noiseText(4,8)),
    USAGE    => noiseTextTag(noiseText(1)),
    REQD     => noiseTextTag(noiseText(1)),
    ACCTOTAL => noiseTextTag(noiseText(1)),
    RATE     => noiseTextTag(noiseText(1)),
    CRIT     => noiseTextTag(noiseText(1)),
    DMGTOTAL => noiseTextTag(noiseText(1)),
    NOTE     => noiseTextTag(noiseText(4,8)),
  });
}
else {
  my $first = 1;
  foreach (1 .. $pc{weaponNum}){
    next if !existsRow "weapon$_",'Name','Part','Usage','Reqd','Acc','Rate','Crit','Dmg','Own','Note';
    my $rowspan = 1; my $notespan = 1;
    for(my $num = $_+1; $num <= $pc{weaponNum}; $num++){
      last if $pc{'weapon'.$num.'NameOff'};
      last if $pc{'weapon'.$num.'Name'};
      last if !existsRow "weapon$_",'Name','Part','Usage','Reqd','Acc','Rate','Crit','Dmg','Own','Note';
      if($pc{'weapon'.$num.'Part'} ne $pc{'weapon'.$_.'Part'}){
        $pc{'weapon'.$num.'Name'} = $pc{'weapon'.$_.'Name'};
        next;
      }
      $rowspan++;
      $pc{'weapon'.$num.'NameOff'} = 1;
      if($pc{'weapon'.$num.'Note'}){
      $pc{'weapon'.($num-$notespan).'NoteSpan'} = $notespan;
        $notespan = 1
      }
      else {
      $pc{'weapon'.($num-$notespan).'NoteSpan'} = $notespan+1;
        $pc{'weapon'.$num.'NoteOff'} = 1;
        $notespan++;
      }
    }
    if($pc{'weapon'.$_.'Class'} eq "自動計算しない"){
      $pc{'weapon'.$_.'Acc'} = 0;
      $pc{'weapon'.$_.'Dmg'} = 0;
    }
    push(@weapons, {
      NAME     => $pc{'weapon'.$_.'Name'},
      PART     => $pc{'part'.$pc{'weapon'.$_.'Part'}.'Name'},
      ROWSPAN  => $rowspan,
      NAMEOFF  => $pc{'weapon'.$_.'NameOff'},
      USAGE    => $pc{'weapon'.$_.'Usage'},
      REQD     => $pc{'weapon'.$_.'Reqd'},
      ACC      => addNum($pc{'weapon'.$_.'Acc'}),
      ACCTOTAL => $pc{'weapon'.$_.'AccTotal'},
      RATE     => $pc{'weapon'.$_.'Rate'},
      CRIT     => $pc{'weapon'.$_.'Crit'},
      DMG      => addNum($pc{'weapon'.$_.'Dmg'}),
      DMGTOTAL => $pc{'weapon'.$_.'DmgTotal'},
      OWN      => $pc{'weapon'.$_.'Own'},
      NOTE     => replaceModificationNotation($pc{'weapon'.$_.'Note'}),
      NOTESPAN => $pc{'weapon'.$_.'NoteSpan'},
      NOTEOFF  => $pc{'weapon'.$_.'NoteOff'},
      CLOSE    => ($pc{'weapon'.$_.'NameOff'} || $first ? 0 : 1),
    } );
    $first = 0;
  }
}
$SHEET->param(Weapons => \@weapons);

### 回避技能／特技 --------------------------------------------------
if(!$pc{forbiddenMode}){
  my @evasion;
  foreach my $name (@data::class_names){
    my $id = $data::class{$name}{id};
    next if !$pc{'lv'.$id};
    next if !($data::class{$name}{type} eq 'weapon-user' || exists $data::class{$name}{evaUnlock});
    if(exists $data::class{$name}{evaUnlock}){
      next if $pc{'lv'.$id} < $data::class{$name}{evaUnlock}{lv};
      if($data::class{$name}{evaUnlock}{feat}){
        my $isUnlock = 0;
        foreach my $feat (split('\|',$data::class{$name}{evaUnlock}{feat})){
          if($acquired{$feat}){ $isUnlock = 1; last; }
        }
        next if !$isUnlock;
      }
      if($data::class{$name}{evaUnlock}{craft}){
        my $isUnlock = 0;
        foreach my $craft (split('\|',$data::class{$name}{evaUnlock}{craft})){
          if($acquired{$craft}){ $isUnlock = 1; last; }
        }
        next if !$isUnlock;
      }
    }
    push(@evasion, {
      NAME => $name."<wbr><span class=\"small\">技能レベル</span>".$pc{'lv'.$id},
      STR  => ($id eq 'Fen' ? ceil($strTotal / 2) : $strTotal),
      EVA  => $pc{'lv'.$id}+$pc{bonusAgi},
    } );
  }
  if(!@evasion){
    push(@evasion, {
      NAME => '技能なし',
      STR  => $pc{reqdStr},
      EVA  => 0,
    } );
  }
  if($pc{raceAbility} =~ /［(鱗の皮膚|晶石の身体|奈落の身体／アビストランク|トロールの体躯)］/) {
    push(@evasion, {
      NAME => $&,
      DEF  => $pc{raceAbilityDef},
    } );
  }
  if($pc{lvSeeker}) {
    push(@evasion, {
      NAME => "求道者：防護点上昇",
      DEF  => $pc{defenseSeeker},
    } );
  }
  foreach (['金属鎧','MetalArmour'],['非金属鎧','NonMetalArmour'],['盾','Shield']) {
    next if !$pc{'mastery'.ucfirst(@$_[1])};
    push(@evasion, {
      NAME => "《防具習熟".($pc{'mastery'.ucfirst(@$_[1])} >= 2 ? 'Ｓ' : 'Ａ')."／".@$_[0]."》",
      DEF  => $pc{'mastery'.ucfirst(@$_[1])},
    } );
  }
  if($pc{masteryArtisan}) {
    push(@evasion, {
      NAME => "《".($pc{masteryArtisan} >= 3 ? '魔器の達人' : $pc{masteryArtisan} >= 2 ? '魔器習熟Ｓ' : '魔器習熟Ａ')."》",
      DEF  => $pc{masteryArtisan},
    } );
  }
  if($pc{evasiveManeuver}) {
    push(@evasion, {
      NAME => "《回避行動".($pc{evasiveManeuver} >= 2 ? 'Ⅱ' : 'Ⅰ')."》",
      EVA  => $pc{evasiveManeuver},
    } );
  }
  if($pc{mindsEye}) {
    push(@evasion, {
      NAME => "《心眼》",
      EVA  => $pc{mindsEye},
    } );
  }
  if($pc{partEnhance}) {
    push(@evasion, {
      NAME => '【部位'.($pc{partEnhance} >= 3 ? '極' : $pc{partEnhance} >= 2 ? '超' : '即応＆').'強化】',
      EVA  => $pc{partEnhance},
    } );
  }

  foreach (@{extractModifications(\%pc)}) {
    my %mod = %{$_;};

    if ($mod{eva} || $mod{def}) {
      my %item = (NAME => $mod{name});
      $item{EVA} = $mod{eva} if $mod{eva};
      $item{DEF} = $mod{def} if $mod{def};

      push(@evasion, \%item);
    }
  }

  $SHEET->param(EvasionClasses => \@evasion);
}
### 防具 --------------------------------------------------
if($pc{forbiddenMode}){
  my @armours;
  foreach(1..3){
    push(@armours, {
      TH   => noiseTextTag(noiseText(1)),
      NAME => noiseTextTag(noiseText(4,8)),
      REQD => noiseTextTag(noiseText(1)),
      EVA  => noiseTextTag(noiseText(1)),
      DEF  => noiseTextTag(noiseText(1)),
      NOTE => noiseTextTag(noiseText(4,8)),
    });
  }
  $SHEET->param(Armours => \@armours);
}
else {
  my @armours;
  my %count;
  foreach (1 .. $pc{armourNum}){
    my $cate = $pc{'armour'.$_.'Category'};
    if($_ == 1 && !$cate){ $cate = '鎧' }
    if   ($cate =~ /鎧/){ $count{'鎧'}++; $pc{'armour'.$_.'Type'} = "鎧$count{'鎧'}" }
    elsif($cate =~ /盾/){ $count{'盾'}++; $pc{'armour'.$_.'Type'} = "盾$count{'盾'}" }
    elsif($cate =~ /他/){ $count{'他'}++; $pc{'armour'.$_.'Type'} = "他$count{'他'}" }
  }
  foreach (1 .. $pc{armourNum}){
    next if $pc{'armour'.$_.'Name'} eq '' && !$pc{'armour'.$_.'Eva'} && !$pc{'armour'.$_.'Def'} && !$pc{'armour'.$_.'Own'};

    if($pc{'armour'.$_.'Type'} =~ /^(鎧|盾|他)[0-9]+/ && $count{$1} <= 1){ $pc{'armour'.$_.'Type'} = $1 }

    push(@armours, {
      TYPE => $pc{'armour'.$_.'Type'},
      NAME => $pc{'armour'.$_.'Name'},
      REQD => $pc{'armour'.$_.'Reqd'},
      EVA  => $pc{'armour'.$_.'Eva'} ? addNum($pc{'armour'.$_.'Eva'}) : ($pc{'armour'.$_.'Category'} =~ /[鎧盾]/ ? '―' : ''),
      DEF  => $pc{'armour'.$_.'Def'} // ($pc{'armour'.$_.'Category'} =~ /[鎧盾]/ ? '0' : ''),
      OWN  => $pc{'armour'.$_.'Own'},
      NOTE => replaceModificationNotation($pc{'armour'.$_.'Note'}),
    } );
  }
  $SHEET->param(Armours => \@armours);
  
  my @total;
  foreach my $i (1..$pc{defenseNum}){
    my @ths;
    my $class = $pc{"evasionClass$i"};
    my $part  = $pc{'part'.$pc{"evasionPart$i"}.'Name'};
    foreach (1 .. $pc{armourNum}){
      my $cate = $pc{'armour'.$_.'Category'};
      if ($pc{"defTotal${i}CheckArmour$_"} && (
           $pc{'armour'.$_.'Name'}
        || $pc{'armour'.$_.'Eva'}
        || $pc{'armour'.$_.'Def'}
        || $pc{'armour'.$_.'Own'}
      )){
        push(@ths, $pc{'armour'.$_.'Type'});
      }
    }
    next if !$class && !@ths && !$pc{"defenseTotal${i}Note"};
    my $th = 
      ($part ? "${part}/" : '')
      .($class ? "${class}/" : '')
      .(@ths == @armours ? 'すべての防具・効果' : join('＋', @ths) || '');
    $th =~ s|/$||;
    push(@total, {
      TH   => $th,
      EVA  => $pc{"defenseTotal${i}Eva"},
      DEF  => $pc{"defenseTotal${i}Def"},
      NOTE => $pc{"defenseTotal${i}Note"},
    } );
  }
  $SHEET->param(ArmourTotals => \@total);
}
### 装飾品 --------------------------------------------------
  my @accessories;
if($pc{forbiddenMode}){
  foreach(1..rand(3)+3){
    push(@accessories, {
      TYPE => noiseTextTag(noiseText(1)),
      NAME => noiseTextTag(noiseText(4,8)),
      NOTE => noiseTextTag(noiseText(6,13)),
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
    next if !existsRow "accessory@$_[1]",'Name','Own','Note','Add';
    next if (@$_[1] =~ /Other2/ &&  $pc{raceAbility} !~ /［見えざる手］/);
    next if (@$_[1] =~ /Other3/ && ($pc{raceAbility} !~ '［見えざる手］' || $pc{level} <  6));
    next if (@$_[1] =~ /Other4/ && ($pc{raceAbility} !~ '［見えざる手］' || $pc{level} < 16));
    if (@$_[1] =~ /_$/) {
      next unless $pc{'accessory'.substr(@$_[1],0,-1).'Add'};
    }
    push(@accessories, {
      TYPE => @$_[0],
      NAME => $pc{'accessory'.@$_[1].'Name'},
      OWN  => $pc{'accessory'.@$_[1].'Own'},
      NOTE => replaceModificationNotation($pc{'accessory'.@$_[1].'Note'}),
    } );
  }
  $SHEET->param(Accessories => \@accessories);
}

### 部位 --------------------------------------------------
if(exists $data::races{$pc{race}}{parts}){
  my @row;
  foreach (1 .. $pc{partNum}) {
    my $type = ($pc{partCore} eq $_) ? 'core' : 'part';
    push(@row, {
      NAME   => $pc{"part${_}Name"}.($pc{partCore} eq $_ ? "<small>（コア部位）</small>" : ""),
      DEF    => $pc{"part${_}DefTotal"},
      HP     => $pc{"part${_}HpTotal"},
      MP     => $pc{"part${_}MpTotal"},
      DEFMOD => ($pc{"part${_}Def"} != $pc{"part${_}DefTotal"} ? $pc{"part${_}Def"}+$pc{$type.'DefAuto'} : 0),
      HPMOD  => ($pc{"part${_}Hp" } != $pc{"part${_}HpTotal" } ? $pc{"part${_}Hp" }+$pc{$type.'HpAuto'}  : 0),
      MPMOD  => ($pc{"part${_}Mp" } != $pc{"part${_}MpTotal" } ? $pc{"part${_}Mp" }+$pc{$type.'MpAuto'}  : 0),
      NOTE   => $pc{"part${_}Note"},
    } );
  }
  $SHEET->param(Parts => \@row);
}

### 魔晶石 --------------------------------------------------
my @manaGems = ();
{
  my $lastColumn = 0;
  my $row;

  foreach my $point (1 .. 20) {
    my $key = $point < 10 ? ('0' . $point) : $point;

    my $quantity = $pc{"manaGem${key}Quantity"} // 0;
    my $offset = $pc{"manaGem${key}Offset"} // 0;

    my $total = $quantity + $offset;
    next if $total == 0;

    my $startColumn = $point < 10 ? 1 : 4;

    if ($startColumn > $lastColumn) {
      $row = 1;
      $lastColumn = $startColumn;
    }
    else {
      $row++;
    }

    push(
        @manaGems,
        {
            POINT        => $point,
            TOTAL        => commify($total),
            ROW          => $row,
            POINT_COLUMN => $startColumn,
            TOTAL_COLUMN => $startColumn + 1,
        }
    );
  }
}
$SHEET->param(ManaGems => \@manaGems);

### 履歴 --------------------------------------------------

$pc{history0Grow} .= '器用'.$pc{sttPreGrowA} if $pc{sttPreGrowA};
$pc{history0Grow} .= '敏捷'.$pc{sttPreGrowB} if $pc{sttPreGrowB};
$pc{history0Grow} .= '筋力'.$pc{sttPreGrowC} if $pc{sttPreGrowC};
$pc{history0Grow} .= '生命'.$pc{sttPreGrowD} if $pc{sttPreGrowD};
$pc{history0Grow} .= '知力'.$pc{sttPreGrowE} if $pc{sttPreGrowE};
$pc{history0Grow} .= '精神'.$pc{sttPreGrowF} if $pc{sttPreGrowF};

my @history;
my $h_num = 0;
$pc{history0Title} = 'キャラクター作成';
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Exp','Honor','Money','Grow','Gm','Member','Note');
  $pc{'history'.$_.'Grow'} =~ s/[^器敏筋生知精0-9]//g;
  $pc{'history'.$_.'Grow'} =~ s/器([0-9]{0,3})/器用×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/敏([0-9]{0,3})/敏捷×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/筋([0-9]{0,3})/筋力×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/生([0-9]{0,3})/生命×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/知([0-9]{0,3})/知力×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/精([0-9]{0,3})/精神×$1<br>/g;
  $pc{'history'.$_.'Grow'} =~ s/×([^0-9])/$1/g;
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
  $pc{'history'.$_.'Exp'}   = formatHistoryFigures($pc{'history'.$_.'Exp'});
  $pc{'history'.$_.'Money'} = formatHistoryFigures($pc{'history'.$_.'Money'});
  push(@history, {
    NUM    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE   => $pc{'history'.$_.'Date'},
    TITLE  => $pc{'history'.$_.'Title'},
    EXP    => $pc{'history'.$_.'Exp'},
    HONOR  => $pc{'history'.$_.'Honor'},
    MONEY  => $pc{'history'.$_.'Money'},
    GROW   => $pc{'history'.$_.'Grow'},
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);
$SHEET->param(historyExpTotal   => commify $pc{historyExpTotal}   );
$SHEET->param(historyHonorTotal => commify $pc{historyHonorTotal} );
$SHEET->param(historyMoneyTotal => commify $pc{historyMoneyTotal} );


### 名誉アイテム --------------------------------------------------
my @honoritems;
foreach (1 .. $pc{honorItemsNum}) {
  next if !$pc{'honorItem'.$_} && !$pc{'honorItem'.$_.'Pt'};
  my $type;
  if   ($pc{"honorItem${_}PtType"} eq 'barbaros'){ $type = '<small>蛮</small>'; }
  elsif($pc{"honorItem${_}PtType"} eq 'dragon'  ){ $type = '<small>竜</small>'; }
  push(@honoritems, {
    NAME => $pc{'honorItem'.$_},
    PT   => $type.$pc{'honorItem'.$_.'Pt'},
  } );
}
$SHEET->param(HonorItems => \@honoritems);

my @dishonoritems;
foreach (1 .. $pc{dishonorItemsNum}) {
  next if !$pc{'dishonorItem'.$_} && !$pc{'dishonorItem'.$_.'Pt'};
  my $type;
  if   ($pc{"dishonorItem${_}PtType"} eq 'barbaros'){ $type = '<small>蛮</small>'; }
  elsif($pc{"dishonorItem${_}PtType"} eq 'both'    ){ $type = '<small>両</small>'; }
  elsif($pc{"dishonorItem${_}PtType"} eq 'dragon'  ){ $type = '<small>竜</small>'; }
  push(@dishonoritems, {
    NAME => $pc{'dishonorItem'.$_},
    PT   => $type.$pc{'dishonorItem'.$_.'Pt'},
  } );
}
$SHEET->param(DishonorItems => \@dishonoritems);

if($::SW2_0){
  foreach (@set::adventurer_rank){
    my ($name, $num) = @$_;
    last if ($pc{honor} < $num);
    $SHEET->param(rank => $name || '―');
  }
  foreach (@set::notoriety_rank){
    my ($name, $num) = @$_;
    $SHEET->param(notoriety => $name || '―') if $pc{dishonor} >= $num;
  }
}
else {
  $SHEET->param(rankAll => 
    ($pc{rank} && $pc{rankBarbaros}) ? "<div class=\"small\">$pc{rank}$pc{rankStar}</div><div class=\"small\">$pc{rankBarbaros}$pc{rankStarBarbaros}</div>"
    : $pc{rank}.$pc{rankStar} || $pc{rankBarbaros}.$pc{rankStarBarbaros} || "―"
  );
  foreach (@set::adventurer_rank){
    my ($name, $num, undef) = @$_;
    if($pc{rank}=~/★$/ && $pc{rankStar} >= 2){ $num += ($pc{rankStar}-1)*500 }
    $SHEET->param(rankHonorValue => $num) if ($pc{rank} eq $name);
  }
  foreach (@set::barbaros_rank){
    my ($name, $num, undef) = @$_;
    if($pc{rankBarbaros}=~/★$/ && $pc{rankStarBarbaros} >= 2){ $num += ($pc{rankStarBarbaros}-1)*500 }
    $SHEET->param(rankBarbarosValue => $num) if ($pc{rankBarbaros} eq $name);
  }
  my $notoriety;
  foreach (@set::notoriety_rank){
    my ($name, $num) = @$_;
    $notoriety = "<span>“${name}”</span>" if $pc{dishonor} >= $num;
  }
  my $notorietyB;
  foreach (@set::notoriety_barbaros_rank){
    my ($name, $num) = @$_;
    $notorietyB = "<span>“${name}”</span>" if $pc{dishonorBarbaros} >= $num;
  }
  $SHEET->param(notoriety => $notoriety.$notorietyB || '―');
}

### ガメル --------------------------------------------------
if($pc{moneyAuto}){
  $SHEET->param(money => commify($pc{moneyTotal}));
}
if($pc{depositAuto}){
  $SHEET->param(deposit => $pc{depositTotal} || $pc{debtTotal} ? commify($pc{depositTotal}).' G ／ '.commify($pc{debtTotal}) : '');
}
$pc{cashbook} =~ s/(:(?:\:|&lt;|&gt;))((?:[\+\-\*\/]?[0-9,]+)+)/$1.cashCheck($2)/eg;
  $SHEET->param(cashbook => $pc{cashbook});
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
### 各種影響表（穢れ、侵蝕など） --------------------------------------------------
{
  my %effects = map { $_->{name} => $_ } @set::effects;
  my @boxes;
  foreach my $box (1 .. $pc{effectBoxNum}){
    my @rows;
    my $name = $pc{"effect${box}Name"};
    my $freeMode = ($name =~ /^自由記入/) ? 1 : 0;
    foreach my $num (1 .. $pc{"effect${box}Num"}){
      next if ($num == 1 && $freeMode);
      next if(!existsRow "effect${box}-${num}",'','Pt1','Pt2');
      my %point = ();
      foreach my $i (1 .. 2){
        $point{$i} = $pc{"effect${box}-${num}Pt$i"};
        if($effects{$name}{type}[$i] =~ /^(checkbox|radio)$/){
          $point{$i} = $point{$i} ? '✔' : '';
        }
      }
      push(@rows, {
        TEXT => $pc{"effect${box}-${num}"},
        POINT1 => $point{1},
        POINT2 => $point{2},
      });
    }
    my $effectName = $name;
    my $pointName = $effects{$name}{pointName};
    if($freeMode) {
      ($effectName,$pointName) = split(/\s?[@＠]\s?/, $pc{"effect${box}NameFree"});
    }
    next if !@rows && !$effectName && !$pointName;
    my $sort = 1000+$box;
    if(!$freeMode){
      foreach my $i (0 .. $#set::effects){
        if($set::effects[$i]{name} eq $name){
          $sort = $i;
          last;
        }
      }
    }
    push(@boxes, {
      SORT => $sort,
      NAME => $effectName,
      PTNAME => $pointName,
      TOTAL => $pc{"effect${box}PtTotal"},
      HEAD0 => $freeMode ? $pc{"effect${box}-1"   } : $effects{$name}{header}[0],
      HEAD1 => $freeMode ? $pc{"effect${box}-1Pt1"} : $effects{$name}{header}[1],
      HEAD2 => $freeMode ? $pc{"effect${box}-1Pt2"} : $effects{$name}{header}[2],
      COLUMN1 => $effects{$name}{header}[1] || $effects{$name}{type}[1],
      COLUMN2 => $effects{$name}{header}[2] || $effects{$name}{type}[2],
      Rows => \@rows,
    });
  }
  @boxes = sort { $a->{SORT} <=> $b->{SORT} } @boxes;
  $SHEET->param(Effects => \@boxes);
}

### 戦闘用アイテム --------------------------------------------------
my $smax = max($pc{lvSco},$pc{lvRan},$pc{lvSag});
my @battleitems;
foreach (1 .. (8 + ceil($smax / 2))) {
  last if !$set::battleitem;
  push(@battleitems, {
    ITEM => $pc{'battleItem'.$_},
  } );
}
$SHEET->param(BattleItems => \@battleitems);

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
if($::in{f}){
  $SHEET->param(FellowMode => 1);
  $SHEET->param($_ => $pc{$_} =~ s{[0-9]+|[^0-9]+}{$&<wbr>}gr) foreach (grep {/^fellow[-0-9]+Num$/} keys %pc);
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
$SHEET->param(ogDescript => removeTags "種族:$pc{race}　性別:$pc{gender}　年齢:$pc{age}　技能:${class_text}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'sw2');
$SHEET->param(sheetType => 'chara');
$SHEET->param(generateType => 'SwordWorld2PC');
$SHEET->param(defaultImage => $::core_dir.'/skin/sw2/img/default_pc.png');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{modeDownload}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './', });
  if($::in{url}){
    push(@menu, { TEXT => 'コンバート', TYPE => "href", VALUE => "./?mode=convert&url=$::in{url}" });
  }
  else {
    if($pc{logId}){
      if   ($::in{f}         ){ push(@menu, { TEXT => 'ＰＣ',     TYPE => "href", VALUE => "./?id=$::in{id}&log=$pc{logId}",     CLASSES => 'character-format', }); }
      elsif($pc{fellowPublic}){ push(@menu, { TEXT => 'フェロー', TYPE => "href", VALUE => "./?id=$::in{id}&log=$pc{logId}&f=1", CLASSES => 'character-format', }); }
      push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => 'loglistOn()', });
      if($pc{reqdPassword}){ push(@menu, { TEXT => '復元', TYPE => "onclick", VALUE => "editOn()", }); }
      else                 { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}&log=$pc{logId}", }); }
    }
    else {
      if   ($::in{f}         ){ push(@menu, { TEXT => 'ＰＣ',     TYPE => "href", VALUE => "./?id=$::in{id}",     CLASSES => 'character-format', }); }
      elsif($pc{fellowPublic}){ push(@menu, { TEXT => 'フェロー', TYPE => "href", VALUE => "./?id=$::in{id}&f=1", CLASSES => 'character-format', }); }
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