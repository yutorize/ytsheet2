################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";


my $mode = param('mode');
my %pc; my %st;
for (param()){ $pc{$_} = param($_); }

my $LOGIN_ID = check;

our $make_error;

## 新規作成時処理
if ($mode eq 'make'){  
  ## 二重投稿チェック
  if(!token_check(param('_token'))){
    $make_error .= 'セッションの有効期限が切れたか、二重投稿です。（⇒<a href="./'
                   .($pc{'protect'} eq 'account'? '?mode=mylist' : '')
                   .'">投稿されているか確認する</a>';
  }
  delete $pc{'_token'};

  ## パスワードチェック
  if($pc{'protect'} eq 'password'){
    if ($pc{'pass'} eq ''){ $make_error .= '記入エラー：パスワードが入力されていません。<br>'; }
    else {
      if ($pc{'pass'} =~ /[^0-9A-Za-z\.\-\/]/) { $make_error .= '記入エラー：パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです。'; }
    }
  }
  
  ## ID生成＆重複チェック
  $pc{'id'} = random_id(6);
  open (my $FH, '<', $set::passfile) ;
  while (<$FH>){ 
    if ($_ =~ /^$pc{'id'}<>/){ $pc{'id'} = random_id(6); }
  }
  close ($FH);
}
if ($make_error) { require $set::lib_edit; exit; }


### データ読み込み ##################################################
require $set::data_races;
require $set::data_items;

## 現在時刻
my $now = time;
## 最終更新
{
  my ($min,$hour,$day,$mon,$year) = (localtime($now))[1..5];
  $year += 1900; $mon++;
  $pc{'updateTime'} = sprintf("%04d-%02d-%02d %02d:%02d",$year,$mon,$day,$hour,$min);
}

## ファイル名取得
my $file;
if($mode eq 'make'){
  $pc{'birthTime'} = $file = $now;
}
elsif($mode eq 'save'){
  (undef, undef, $file, undef) = getfile($pc{'id'},$pc{'pass'},$LOGIN_ID);
  if(!$file){ die; }
}

### 種族特徴 ##################################################
$pc{'raceAbility'} = $data::race_ability{$pc{'race'}};

### 冒険者レベル算出 ##################################################
$pc{'level'} = max(
  $pc{'lvFig'},
  $pc{'lvGra'},
  $pc{'lvFen'},
  $pc{'lvSho'},
  $pc{'lvSor'},
  $pc{'lvCon'},
  $pc{'lvPri'},
  $pc{'lvFai'},
  $pc{'lvMag'},
  $pc{'lvSco'},
  $pc{'lvRan'},
  $pc{'lvSag'},
  $pc{'lvEnh'},
  $pc{'lvBar'},
  $pc{'lvRid'},
  $pc{'lvAlc'},
  $pc{'lvWar'},
  $pc{'lvMys'},
  $pc{'lvDem'},
  $pc{'lvPhy'},
  $pc{'lvGri'},
  $pc{'lvArt'},
  $pc{'lvAri'}
);

### スカレンセジ最大レベル算出 ##################################################
my $smax = max("$pc{'lvSco'}","$pc{'lvRan'}","$pc{'lvSag'}");

### ウィザードレベル算出 ##################################################
$pc{'lvWiz'} = max($pc{'lvSor'},$pc{'lvCon'});
### 魔法使い最大レベル算出 ##################################################
$pc{'lvCaster'} = max($pc{'lvSor'},$pc{'lvCon'},$pc{'lvPri'},$pc{'lvFai'},$pc{'lvMag'},$pc{'lvDem'},$pc{'lvGri'});

### 経験点／名誉点計算 ##################################################
my @expA = ( 0, 1000, 2000, 3500, 5000, 7000, 9500, 12500, 16500, 21500, 27500, 35000, 44000, 54500, 66500, 80000, 95000, 125000 );
my @expB = ( 0,  500, 1500, 2500, 4000, 5500, 7500, 10000, 13000, 17000, 22000, 28000, 35500, 44500, 55000, 67000, 80500, 105500 );
my @expS = ( 0, 3000, 6000, 9000, 12000, 16000, 20000, 24000, 28000, 33000, 38000, 43000, 48000, 54000, 60000, 66000, 72000, 79000, 86000, 93000, 100000 );
## 履歴から 
foreach (split /[|｜]/, $pc{'make_honor'}) {
     if($_ =~ s/^b//){ $pc{'bhonor_total'} += s_eval($_); } #蛮族名誉点
  elsif($_ =~ s/^r//){ $pc{'rhonor_total'} += s_eval($_); } #盟竜点
  else { $pc{'honor_total'} += s_eval($_); }
}
for (my $i = 0; $i <= $pc{'historyNum'}; $i++){
  $pc{'expTotal'} += s_eval($pc{"history${i}Exp"});
  foreach (split /[|｜]/, $pc{"history${i}Honor"}) {
       if($_ =~ s/^b//){ $pc{'bhonorTotal'} += s_eval($_); } #蛮族名誉点
    elsif($_ =~ s/^r//){ $pc{'rhonorTotal'} += s_eval($_); } #盟竜点
    else { $pc{'honorTotal'} += s_eval($_); }
  }
}
## 経験点消費
$pc{'expRest'} = $pc{'expTotal'};
foreach ("Fig", "Gra", "Sor", "Con", "Pri", "Fai", "Mag", "Dem","Gri") {
  $pc{'expRest'} -= $expA[$pc{'lv'.$_}];
}
foreach ("Fen", "Sho", "Sco", "Ran", "Sag", "Enh", "Bar", "Rid", "Alc", "War", "Mys","Phy","Art","Ari") {
  $pc{'expRest'} -= $expB[$pc{'lv'.$_}];
}
$pc{'expRest'} += $expS[$pc{'lvSeeker'}];  # 求道者

### 能力値計算  ##################################################
## 成長
$pc{'sttGrowA'} = $pc{'sttPreGrowA'};
$pc{'sttGrowB'} = $pc{'sttPreGrowB'};
$pc{'sttGrowC'} = $pc{'sttPreGrowC'};
$pc{'sttGrowD'} = $pc{'sttPreGrowD'};
$pc{'sttGrowE'} = $pc{'sttPreGrowE'};
$pc{'sttGrowF'} = $pc{'sttPreGrowF'};
for (my $i = 1; $i <= $pc{'historyNum'}; $i++) {
  my $grow = $pc{"history${i}Grow"};
  $grow =~ s/器(?:用度?)?(?:×|\*)?([0-9]{1,3})/$pc{'sttGrowA'} += $1; ''/ge;
  $grow =~ s/敏(?:捷度?)?(?:×|\*)?([0-9]{1,3})/$pc{'sttGrowB'} += $1; ''/ge;
  $grow =~ s/筋(?:力)?(?:×|\*)?([0-9]{1,3})/$pc{'sttGrowC'} += $1; ''/ge;
  $grow =~ s/生(?:命力?)?(?:×|\*)?([0-9]{1,3})/$pc{'sttGrowD'} += $1; ''/ge;
  $grow =~ s/知(?:力)?(?:×|\*)?([0-9]{1,3})/$pc{'sttGrowE'} += $1; ''/ge;
  $grow =~ s/精(?:神力?)?(?:×|\*)?([0-9]{1,3})/$pc{'sttGrowF'} += $1; ''/ge;
  $pc{'sttGrowA'} += ($grow =~ s/器/器/g);
  $pc{'sttGrowB'} += ($grow =~ s/敏/敏/g);
  $pc{'sttGrowC'} += ($grow =~ s/筋/筋/g);
  $pc{'sttGrowD'} += ($grow =~ s/生/生/g);
  $pc{'sttGrowE'} += ($grow =~ s/知/知/g);
  $pc{'sttGrowF'} += ($grow =~ s/精/精/g);
}

## 能力値算出
$pc{'sttDex'} = $pc{'sttBaseTec'} + $pc{'sttBaseA'} + $pc{'sttGrowA'};
$pc{'sttAgi'} = $pc{'sttBaseTec'} + $pc{'sttBaseB'} + $pc{'sttGrowB'};
$pc{'sttStr'} = $pc{'sttBasePhy'} + $pc{'sttBaseC'} + $pc{'sttGrowC'};
$pc{'sttVit'} = $pc{'sttBasePhy'} + $pc{'sttBaseD'} + $pc{'sttGrowD'};
$pc{'sttInt'} = $pc{'sttBaseSpi'} + $pc{'sttBaseE'} + $pc{'sttGrowE'};
$pc{'sttMnd'} = $pc{'sttBaseSpi'} + $pc{'sttBaseF'} + $pc{'sttGrowF'};
  # ウィークリング補正
  $pc{'sttAgi'} += 3 if $pc{'race'} eq 'ウィークリング（ガルーダ）';
  $pc{'sttStr'} += 3 if $pc{'race'} eq 'ウィークリング（ミノタウロス）';
  $pc{'sttInt'} += 3 if $pc{'race'} eq 'ウィークリング（バジリスク）';
  $pc{'sttMnd'} += 3 if $pc{'race'} eq 'ウィークリング（マーマン）';

## ボーナス算出
$pc{'bonusDex'} = int(($pc{'sttDex'} + $pc{'sttAddA'}) / 6);
$pc{'bonusAgi'} = int(($pc{'sttAgi'} + $pc{'sttAddB'}) / 6);
$pc{'bonusStr'} = int(($pc{'sttStr'} + $pc{'sttAddC'}) / 6);
$pc{'bonusVit'} = int(($pc{'sttVit'} + $pc{'sttAddD'}) / 6);
$pc{'bonusInt'} = int(($pc{'sttInt'} + $pc{'sttAddE'}) / 6);
$pc{'bonusMnd'} = int(($pc{'sttMnd'} + $pc{'sttAddF'}) / 6);
## 冒険者レベル＋各ボーナス算出
$st{'LvA'} = $pc{'level'}+$pc{'bonusDex'};
$st{'LvB'} = $pc{'level'}+$pc{'bonusAgi'};
$st{'LvC'} = $pc{'level'}+$pc{'bonusStr'};
$st{'LvD'} = $pc{'level'}+$pc{'bonusVit'};
$st{'LvE'} = $pc{'level'}+$pc{'bonusInt'};
$st{'LvF'} = $pc{'level'}+$pc{'bonusMnd'};
## 各技能レベル＋各ボーナス算出
foreach (
  'Fig',
  'Gra',
  'Fen',
  'Sho',
  'Sor',
  'Con',
  'Pri',
  'Fai',
  'Mag',
  'Sco',
  'Ran',
  'Sag',
  'Enh',
  'Bar',
  'Rid',
  'Alc',
  'War',
  'Mys',
  'Dem',
  'Phy',
  'Gri',
  'Art',
  'Ari',
){
  if($pc{'lv'.$_} > 0) {
    $st{$_.'A'} = $pc{'lv'.$_}+$pc{'bonusDex'};
    $st{$_.'B'} = $pc{'lv'.$_}+$pc{'bonusAgi'};
    $st{$_.'C'} = $pc{'lv'.$_}+$pc{'bonusStr'};
    $st{$_.'D'} = $pc{'lv'.$_}+$pc{'bonusVit'};
    $st{$_.'E'} = $pc{'lv'.$_}+$pc{'bonusInt'};
    $st{$_.'F'} = $pc{'lv'.$_}+$pc{'bonusMnd'};
  }
  else {
    $st{$_.'A'} = 0;
    $st{$_.'B'} = 0;
    $st{$_.'C'} = 0;
    $st{$_.'D'} = 0;
    $st{$_.'E'} = 0;
    $st{$_.'F'} = 0;
  }
}

### 戦闘特技 ##################################################
## 自動習得
my @abilities;
if($pc{'lvGra'} >= 1) { push(@abilities, "追加攻撃"); }
if($pc{'lvSco'} >= 5) { push(@abilities, "トレジャーハント"); }
if($pc{'lvRan'} >= 5) { push(@abilities, "サバイバビリティ"); }
if($pc{'lvSag'} >= 5) { push(@abilities, "鋭い目"); }
$" = ',';
$pc{'combatFeatsAuto'} = "@abilities";
## 選択特技による補正
{
  my $i = 1; #カウンターセット
  foreach (
    $pc{'combatFeatsLv1'},
    $pc{'combatFeatsLv3'},
    $pc{'combatFeatsLv5'},
    $pc{'combatFeatsLv7'},
    $pc{'combatFeatsLv9'},
    $pc{'combatFeatsLv11'},
    $pc{'combatFeatsLv13'},
    $pc{'combatFeatsLv15'},
    $pc{'combatFeatsLv16'},
    $pc{'combatFeatsLv17'},
  ) {
    if   ($_ eq '命中強化Ⅰ')  { $pc{'accuracyEnhance'} = 1; }
    elsif($_ eq '命中強化Ⅱ')  { $pc{'accuracyEnhance'} = 2; }
    elsif($_ eq '回避行動Ⅰ')  { $pc{'evasiveManeuver'} = 1; }
    elsif($_ eq '回避行動Ⅱ')  { $pc{'evasiveManeuver'} = 2; }
    elsif($_ eq '魔力強化Ⅰ')  { $pc{'magicPowerEnhance'} = 1; }
    elsif($_ eq '魔力強化Ⅱ')  { $pc{'magicPowerEnhance'} = 2; }
    elsif($_ eq '頑強')        { $pc{'tenacity'} += 15; }
    elsif($_ eq '超頑強')      { $pc{'tenacity'} += 15; }
    elsif($_ eq 'キャパシティ'){ $pc{'capacity'} += 15; }
    elsif($_ eq '防具習熟Ａ／金属鎧')  { $pc{'masteryMetalArmour'}   += 1; }
    elsif($_ eq '防具習熟Ａ／非金属鎧'){ $pc{'masteryNonMetalArmour'}+= 1; }
    elsif($_ eq '防具習熟Ａ／盾')      { $pc{'masteryShield'}        += 1; }
    elsif($_ eq '防具習熟Ｓ／金属鎧')  { $pc{'masteryMetalArmour'}   += 2; }
    elsif($_ eq '防具習熟Ｓ／非金属鎧'){ $pc{'masteryNonMetalArmour'}+= 2; }
    elsif($_ eq '防具習熟Ｓ／盾')      { $pc{'masteryShield'}        += 2; }
    elsif($_ =~ /^武器習熟Ａ／(.*)$/) { $pc{'mastery'.ucfirst($data::weapon_id{$1})} += 1; }
    elsif($_ =~ /^武器習熟Ｓ／(.*)$/) { $pc{'mastery'.ucfirst($data::weapon_id{$1})} += 2; }
  #  elsif($_ =~ /^魔器習熟Ａ/) { $master{'魔器'} += 1; }
  #  elsif($_ =~ /^魔器習熟Ｓ/) { $master{'魔器'} += 1; }
  #  elsif($_ =~ /^魔器の達人/) { $master{'魔器'} += 1; }
  #  elsif($_ eq 'スローイングⅠ'){ $pc{'throwing'} = 1; }
  #  elsif($_ eq 'スローイングⅡ'){ $pc{'throwing'} = 2; }
    $i += $i < 15 ? 2 : 1;      #カウンターに+2(15Lv～は+1)
    if($i > $pc{'level'}){ last; } #カウンターがLvを超えたら中断
  }
}

### サブステータス ##################################################
## 生命抵抗力
$pc{'vitResistBase'} = $st{'LvD'};
$pc{'vitResistAddTotal'} = s_eval($pc{'vitResistAdd'});
$pc{'vitResistTotal'}  = $pc{'vitResistBase'} + $pc{'vitResistAddTotal'};
## 精神抵抗力
$pc{'mndResistBase'} = $st{'LvF'};
$pc{'mndResistAddTotal'} = s_eval($pc{'mndResistAdd'});
$pc{'mndResistTotal'}  = $pc{'mndResistBase'} + $pc{'mndResistAddTotal'};
## ＨＰＭＰ：装飾品
foreach (
  'Head',
  'Ear',
  'Face',
  'Neck',
  'Back',
  'HandR',
  'HandL',
  'Waist',
  'Leg',
  'Other',
  'Other2',
  'Other3',
  'Other4',) {
  $pc{'hpAccessory'} = 2 if $pc{"accessory$_".'Own'} eq 'HP';
  $pc{'mpAccessory'} = 2 if $pc{"accessory$_".'Own'} eq 'MP';
}
## ＨＰ
$pc{'hpBase'} = $pc{'level'} * 3 + $pc{'sttVit'} + $pc{'sttAddD'};
$pc{'hpAddTotal'} = s_eval($pc{'hpAdd'}) + $pc{'tenacity'};
$pc{'hpTotal'}  = $pc{'hpBase'} + $pc{'hpAddTotal'};
## ＭＰ
$pc{'mpBase'} = ($pc{'lvSor'} + $pc{'lvCon'} + $pc{'lvPri'} + $pc{'lvFai'} + 
                 $pc{'lvMag'} + $pc{'lvDem'} + $pc{'lvGri'}) * 3 + $pc{'sttMnd'} + $pc{'sttAddF'};
$pc{'mpAddTotal'} = s_eval($pc{'mpAdd'});
$pc{'mpTotal'}  = $pc{'mpBase'} + $pc{'mpAddTotal'};

## 移動力
$pc{'mobilityBase'} = $pc{'sttAgi'} + $pc{'sttAddB'};
$pc{'mobilityTotal'} = $pc{'mobilityBase'} + s_eval($pc{'mobilityAdd'});
$pc{'mobilityFull'} = $pc{'mobilityTotal'} * 3;
$pc{'mobilityLimited'} = $pc{'footwork'} ? 9 : 3;

## 判定パッケージ
$pc{'packScoutTec'}  = $st{'ScoA'};
$pc{'packScoutAgi'}  = $st{'ScoB'};
$pc{'packScoutInt'}  = $st{'ScoE'};
$pc{'packRangerTec'} = $st{'RanA'};
$pc{'packRangerAgi'} = $st{'RanB'};
$pc{'packRangerInt'} = $st{'RanE'};
$pc{'packSageInt'}   = $st{'SagE'};

## 魔物知識／先制力
$pc{'monsterLore'} = max($st{'SagE'},$st{'RidE'});
$pc{'initiative'}  = max($st{'ScoB'},$st{'WarB'});

### 装備 ##################################################
## 武器
foreach(1 .. $pc{'weaponNum'}){
  my $class;
  if   ($pc{'weapon'.$_.'Class'} eq "ファイター"       && $pc{'lvFig'}){ $class = 'Fig'; }
  elsif($pc{'weapon'.$_.'Class'} eq "グラップラー"     && $pc{'lvGra'}){ $class = 'Gra'; }
  elsif($pc{'weapon'.$_.'Class'} eq "フェンサー"       && $pc{'lvFen'}){ $class = 'Fen'; }
  elsif($pc{'weapon'.$_.'Class'} eq "シューター"       && $pc{'lvSho'}){ $class = 'Sho'; }
  elsif($pc{'weapon'.$_.'Class'} eq "エンハンサー"     && $pc{'lvEnh'}){ $class = 'Enh'; }
  elsif($pc{'weapon'.$_.'Class'} eq "デーモンルーラー" && $pc{'lvDem'}){ $class = 'Dem'; }
  # 命中
  my $base_acc = 0;
     $base_acc = $pc{'lv'.$class} + int(($pc{'sttDex'} + $pc{'sttAddA'}) / 6) if $pc{'lv'.$class};
  $pc{'weapon'.$_.'AccTotal'} = $pc{'weapon'.$_.'Acc'} + $base_acc;
  # ダメージ
  if($pc{'weapon'.$_.'Category'} eq 'クロスボウ'){ $pc{'weapon'.$_.'DmgTotal'} = $pc{'weapon'.$_.'Dmg'} + $pc{'lvSho'}; }
  elsif   ($pc{'weapon'.$_.'Category'} eq 'ガン'){ $pc{'weapon'.$_.'DmgTotal'} = $pc{'weapon'.$_.'Dmg'} + $st{'MagE'}; }
  else                                           { $pc{'weapon'.$_.'DmgTotal'} = $pc{'weapon'.$_.'Dmg'} + $st{$class.'C'}; }
  $pc{'weapon'.$_.'DmgTotal'} += $pc{'mastery' . ucfirst($data::weapon_id{ $pc{'weapon'.$_.'Category'} }) };
}

## 回避力
  use POSIX 'ceil';
  $pc{'reqdStr'}  = $pc{'sttStr'} + $pc{'sttAddC'};
  $pc{'reqdStrF'} = ceil($pc{'reqdStr'} / 2);
  if   ($pc{'evasionClass'} eq "ファイター"       && $pc{'lvFig'}){ $pc{'evasionEva'} = $st{'FigB'}; $pc{'evasionStr'} = $pc{'reqdStr'}; }
  elsif($pc{'evasionClass'} eq "グラップラー"     && $pc{'lvGra'}){ $pc{'evasionEva'} = $st{'GraB'}; $pc{'evasionStr'} = $pc{'reqdStr'}; }
  elsif($pc{'evasionClass'} eq "フェンサー"       && $pc{'lvFen'}){ $pc{'evasionEva'} = $st{'FenB'}; $pc{'evasionStr'} = $pc{'reqdStrF'}; }
  elsif($pc{'evasionClass'} eq "シューター"       && $pc{'lvSho'}){ $pc{'evasionEva'} = $st{'ShoB'}; $pc{'evasionStr'} = $pc{'reqdStr'}; }
  elsif($pc{'evasionClass'} eq "デーモンルーラー" && $pc{'lvDem'}){ $pc{'evasionEva'} = $st{'DemB'}; $pc{'evasionStr'} = $pc{'reqdStr'}; }
  else{ $pc{'evasionEva'} = 0; $pc{'reqdStr'} = $pc{'reqdStr'}; }

## 防具
  $pc{'DefenseTotalAllEva'} = $pc{'evasionEva'} + $pc{'evasiveManeuver'} + $pc{'armourEva'} + $pc{'shieldEva'} + $pc{'defOtherEva'};
  $pc{'DefenseTotalAllDef'} =
    $pc{'armourDef'} + max($pc{'masteryMetalArmour'},$pc{'masteryNonMetalArmour'}) +
    $pc{'shieldDef'} + $pc{'masteryShield'} +
    $pc{'defOtherDef'};

#### 改行を<br>に変換 ##################################################
$pc{'items'}         =~ s/\r\n?|\n/<br>/g;
$pc{'freeNote'}      =~ s/\r\n?|\n/<br>/g;
$pc{'freeHistory'}   =~ s/\r\n?|\n/<br>/g;
$pc{'fellowProfile'} =~ s/\r\n?|\n/<br>/g;
$pc{'fellowNote'}    =~ s/\r\n?|\n/<br>/g;

### 画像アップロード ##################################################
if($pc{'imageDelete'}){
  unlink "${set::data_dir}${file}/image.$pc{'image'}"; # ファイルを削除
  $pc{'image'} = '';
}
if(param('imageFile')){
  my $imagefile = param('imageFile'); # ファイル名の取得
  my $type = uploadInfo($imagefile)->{'Content-Type'}; # MIMEタイプの取得
  
  # ファイルの受け取り
  my $data; my $buffer;
  while(my $bytesread = read($imagefile, $buffer, 2048)) {
    $data .= $buffer;
  }
  # サイズチェック
  my $flag; 
  my $max_size = ( $set::image_maxsize ? $set::image_maxsize : 1024 * 512 );
  if (length($data) <= $max_size){ $flag = 1; }
  # 形式チェック
  my $ext;
  if    ($type eq "image/gif")   { $ext ="gif"; } #GIF
  elsif ($type eq "image/jpeg")  { $ext ="jpg"; } #JPG
  elsif ($type eq "image/pjpeg") { $ext ="jpg"; } #JPG
  elsif ($type eq "image/png")   { $ext ="png"; } #PNG
  elsif ($type eq "image/x-png") { $ext ="png"; } #PNG
  
  if($flag && $ext){
    unlink "${set::data_dir}${file}/image.$pc{'image'}"; # 前のファイルを削除
    
    if (!-d "${set::data_dir}${file}"){ mkdir "${set::data_dir}${file}"; }
    open(my $IMG, ">", "${set::data_dir}${file}/image.${ext}");
    binmode($IMG);
    print $IMG $data;
    close($IMG);
    
    $pc{'image'} = $ext;
  }
}

### 保存 ##################################################
my $mask = umask 0;
### エスケープ
foreach (keys %pc) {
  $pc{$_} =~ s/&/&amp;/g;
  $pc{$_} =~ s/"/&quot;/g;
  $pc{$_} =~ s/</&lt;/g;
  $pc{$_} =~ s/>/&gt;/g;
  $pc{$_} =~ s/\r//g;
  $pc{$_} =~ s/\n//g;
}

## タグ：全角スペース・英数を半角に変換
$pc{'tags'} =~ tr/　/ /;
$pc{'tags'} =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
$pc{'tags'} =~ tr/＋－＊／．，＿/\+\-\*\/\.,_/;
$pc{'tags'} =~ tr/ / /s;

## 新規
if($mode eq 'make'){
  sysopen (my $FH, $set::passfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
    my $pass;
    if   ($pc{'protect'} eq 'account'&& $LOGIN_ID) { $pass = '['.$LOGIN_ID.']'; }
    elsif($pc{'protect'} eq 'password')            { $pass = &e_crypt($pc{'pass'}); }
    print $FH "$pc{'id'}<>$pass<>$now<>$pc{'mail'}<>\n";
  close ($FH);
}
## 更新
elsif($mode eq 'save'){
  if($pc{'protect'} ne $pc{'protectOld'}){
  sysopen (my $FH, $set::passfile, O_RDWR);
  my @list = <$FH>;
  flock($FH, 2);
  seek($FH, 0, 0);
  foreach (@list){
    my @data= split /<>/;
    if ($data[0] eq $pc{'id'}){
      my $pass;
      if   ($pc{'protect'} eq 'account'&& $LOGIN_ID) { $pass = '['.$LOGIN_ID.']'; }
      elsif($pc{'protect'} eq 'password')            { $pass = &e_crypt($pc{'pass'}); }
      print $FH "$data[0]<>$pass<>$data[2]<>$data[3]<>\n";
    }else{
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
  }
}

### 保存
if($mode eq 'save'){
  use File::Copy qw/copy/;
  if (!-d "${set::data_dir}${file}/backup/"){ mkdir "${set::data_dir}${file}/backup/"; }
  
  my $modtime = (stat("${set::data_dir}${file}/data.cgi"))[9];
  my ($min, $hour, $day, $mon, $year) = (localtime($modtime))[1..5];
  $year += 1900; $mon++;
  my $update_date = sprintf("%04d-%02d-%02d-%02d-%02d",$year,$mon,$day,$hour,$min);
  copy("${set::data_dir}${file}/data.cgi", "${set::data_dir}${file}/backup/${update_date}.cgi");
}
delete $pc{'pass'};
if (!-d "${set::data_dir}${file}"){ mkdir "${set::data_dir}${file}"; }
sysopen (my $FH, "${set::data_dir}${file}/data.cgi", O_WRONLY | O_TRUNC | O_CREAT, 0666);
print $FH "ver<>".$main::ver."\n";
foreach (sort keys %pc){
  if($pc{$_} ne "") { print $FH "$_<>".$pc{$_}."\n"; }
}
close($FH);

## 一覧更新
{
  my($aka, $ruby) = split(/:/,$pc{'aka'});

  sysopen (my $FH, $set::listfile, O_RDWR | O_CREAT, 0666);
  my @list = sort { (split(/<>/,$b))[3] cmp (split(/<>/,$a))[3] } <$FH>;
  flock($FH, 2);
  seek($FH, 0, 0);
  my $newline = "$pc{'id'}<>$file<>".
                "$pc{'birthTime'}<>$now<>$pc{'characterName'}<>$pc{'playerName'}<>$pc{'group'}<>".
                "$pc{'expTotal'}<>$pc{'honorTotal'}<>$pc{'race'}<>$pc{'gender'}<>$pc{'age'}<>$pc{'faith'}<>".
                
                "$pc{'lvFig'}/$pc{'lvGra'}/$pc{'lvFen'}/".
                "$pc{'lvSho'}/$pc{'lvSor'}/$pc{'lvCon'}/$pc{'lvPri'}/$pc{'lvFai'}/$pc{'lvMag'}/".
                "$pc{'lvSco'}/$pc{'lvRan'}/$pc{'lvSag'}/".
                "$pc{'lvEnh'}/$pc{'lvBar'}/$pc{'lvRid'}/$pc{'lvAlc'}/$pc{'lvWar'}/$pc{'lvMys'}/".
                "$pc{'lvDem'}/$pc{'lvPhy'}/$pc{'lvGri'}/$pc{'lvArt'}/$pc{'lvAri'}<>".
                
                "$pc{'sessionTotal'}<>$pc{'image'}<> $pc{'tags'} <>$pc{'hide'}<>$pc{'fellowPublic'}<>";
  my $listhit;
  foreach (@list){
    my( $id, undef ) = split /<>/;
    if ($id eq $pc{'id'}){
      print $FH "$newline\n";
      $listhit = 1;
    }else{
      print $FH $_;
    }
  }
  if(!$listhit){
    print $FH "$newline\n";
  }
  truncate($FH, tell($FH));
  close($FH);
}

if($mode eq 'make'){
  print "Location: ./?id=$pc{'id'}\n\n"
}

require $set::lib_edit;

1;