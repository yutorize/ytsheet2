################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";
use HTML::Template;

### データ読み込み ##################################################
require $set::data_races;
require $set::data_items;

### テンプレート読み込み ##################################################
#my $template = HTML::Template->new(filename => "template.html", utf8 => 1,);
my $SHEET;
open (my $FH, "<:utf8", $set::skin_sheet ) or die "Couldn't open template file: $!\n";
$SHEET = HTML::Template->new( filehandle => *$FH , die_on_bad_params => 0, case_sensitive => 1, global_vars => 1);
close($FH);

$SHEET->param("BackupMode" => param('backup') ? 1 : 0);

### キャラクターデータ読み込み ##################################################
my $id = param('id');
my $file;

open (my $FH, '<', $set::listfile) or die;
while (<$FH>) {
  my @data = (split /<>/, $_)[0..1];
  if ($data[0] eq $id) {
    $file = $data[1];
    last;
  }
}
close($FH);

my %pc = ();
my $datafile = "${set::data_dir}${file}/data.cgi";
   $datafile = "${set::data_dir}${file}/backup/".param('backup').'.cgi' if param('backup');
open my $IN, '<', $datafile or error 'キャラクターシートがありません。';
$_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
close($IN);

$SHEET->param("id" => $id);

### 置換
foreach (keys %pc) {
  $pc{$_} = tag_unescape($pc{$_});
  if($_ =~ /^(?:items|freeNote|freeHistory)$/){
  }
}

### テンプレ用に変換
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}

### 出力準備 ##################################################
## セリフ
$pc{'words'} =~ s/^「/<span class="brackets">「<\/span>/g;
$pc{'words'} =~ s/(.+?[，、。？」])/<span>$1<\/span>/g;
$SHEET->param("words" => $pc{'words'});
$SHEET->param("wordsX" => ($pc{'wordsX'} eq '左' ? 'left:0;' : 'right:0;'));
$SHEET->param("wordsY" => ($pc{'wordsY'} eq '下' ? 'bottom:0;' : 'top:0;'));

## 信仰
if($pc{'faith'} eq 'その他の信仰') { $SHEET->param("faith" => $pc{'faithOther'}); }
$pc{'faith'} =~ s/“(.*)”//;
## 技能
my @classes;
foreach (
  ['Fig','ファイター'],
  ['Gra','グラップラー'],
  ['Fen','フェンサー'],
  ['Sho','シューター'],
  ['Sor','ソーサラー'],
  ['Con','コンジャラー'],
  ['Pri','プリースト'],
  ['Fai','フェアリーテイマー'],
  ['Mag','マギテック'],
  ['Sco','スカウト'],
  ['Ran','レンジャー'],
  ['Sag','セージ'],
  ['Enh','エンハンサー'],
  ['Bar','バード'],
  ['Rid','ライダー'],
  ['Alc','アルケミスト'],
  ['War','ウォーリーダー'],
  ['Mys','ミスティック'],
  ['Dem','デーモンルーラー'],
  ['Phy','フィジカルマスター'],
  ['Gri','グリモワール'],
  ['Art','アリストクラシー'],
  ['Ari','アーティザン'],
){
  next if !$pc{'lv'.@$_[0]};
  if(@$_[1] eq 'プリースト' && $pc{'faith'}){
    @$_[1] .= '<span class="priest-faith'.(length($pc{'faith'}) > 12 ? ' narrow' : "").'">（'.$pc{'faith'}.'）</span>';
  }
  push(@classes, { "NAME" => @$_[1], "LV" => $pc{'lv'.@$_[0]} } );
}
@classes = sort{$b->{'LV'} <=> $a->{'LV'}} @classes;
$SHEET->param(Classes => \@classes);

## 戦闘特技
my @feats_lv;
foreach (1..$pc{'level'}){
  next if !$pc{'combatFeatsLv'.$_};
  push(@feats_lv, { "NAME" => $pc{'combatFeatsLv'.$_}, "LV" => $_ } );
}
$SHEET->param(CombatFeatsLv => \@feats_lv);
## 戦闘特技（自動習得）
my @feats_auto;
foreach (split /,/, $pc{'combatFeatsAuto'}) {
  push(@feats_auto, { "NAME" => $_ } );
}
$SHEET->param(CombatFeatsAuto => \@feats_auto);

## 言語
my @language;
foreach (@{$data::race_language{ $pc{'race'} }}){
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


## パッケージ
$SHEET->param("PackageLv" => max($pc{'lvSco'},$pc{'lvRan'},$pc{'lvSag'}));

## 魔力
my @magic;
foreach (
  ['ソーサラー',         'Sor', '真語魔法'],
  ['コンジャラー',       'Con', '操霊魔法'],
  ['プリースト',         'Pri', '神聖魔法'],
  ['マギテック',         'Mag', '魔動機術'],
  ['フェアリーテイマー', 'Fai', '妖精魔法'],
  ['デーモンルーラー'   ,'Dem', '召異魔法'],
  ['グリモワール'       ,'Gri', '秘奥魔法'],
){
  next if !$pc{'lv'.@$_[1]};
  push(@magic, {
    "NAME" => @$_[0]."技能レベル".$pc{'lv'.@$_[1]},
    "MAGIC"  => @$_[2],
    "NUM"  => $pc{'lv'.@$_[1]}+$pc{'bonusInt'}+$pc{'magicPowerAdd'},
  } );
}
$SHEET->param(MagicPowers => \@magic);

## 攻撃技能／特技
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
  push(@atacck, {
    "NAME" => @$_[0]."技能レベル".$pc{'lv'.@$_[1]},
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
if($pc{'accuracyEnhance'}) {
  push(@atacck, {
    "NAME" => "《命中強化".($pc{'accuracyEnhance'}  >= 2  ? 'Ⅱ' : 'Ⅰ').@$_[0]."》",
    "ACC"  => $pc{'accuracyEnhance'},
  } );
}
$SHEET->param(AttackClasses => \@atacck);

## 武器
my @weapons;
foreach (1 .. $pc{'weaponNum'}){
  next if $pc{'weapon'.$_.'Name'}.$pc{'weapon'.$_.'Usage'}.$pc{'weapon'.$_.'Reqd'}.
          $pc{'weapon'.$_.'Acc'}.$pc{'weapon'.$_.'Rate'}.$pc{'weapon'.$_.'Crit'}.
          $pc{'weapon'.$_.'Dmg'}.$pc{'weapon'.$_.'Own'}.$pc{'weapon'.$_.'Note'}
          eq '';
  push(@weapons, {
    "NAME"     => $pc{'weapon'.$_.'Name'},
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
  } );
}
$SHEET->param(Weapons => \@weapons);

## 回避技能／特技
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
    "NAME" => @$_[0]."技能レベル".$pc{'lv'.@$_[1]},
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
foreach (['金属鎧','MetalArmour'],['非金属鎧','NonMetalArmour'],['盾','Shield']) {
  next if !$pc{'mastery'.ucfirst(@$_[1])};
  push(@evasion, {
    "NAME" => "《防具習熟".($pc{'mastery'.ucfirst(@$_[1])} >= 2 ? 'Ｓ' : 'Ａ')."／".@$_[0]."》",
    "DEF"  => $pc{'mastery'.ucfirst(@$_[1])},
  } );
}
if($pc{'evasiveManeuver'}) {
  push(@evasion, {
    "NAME" => "《回避行動".($pc{'evasiveManeuver'}  >= 2  ? 'Ⅱ' : 'Ⅰ').@$_[0]."》",
    "EVA"  => $pc{'evasiveManeuver'},
  } );
}
$SHEET->param(EvasionClasses => \@evasion);

## 装飾品
my @accessories;
foreach (
  ["頭","Head"],    ["┗","Head_"],
  ["耳","Ear"],     ["┗","Ear_"],
  ["顔","Face"],    ["┗","Face_"],
  ["首","Neck"],    ["┗","Neck_"],
  ["背中","Back"],  ["┗","Back_"],
  ["右手","HandR"], ["┗","HandR_"],
  ["左手","HandL"], ["┗","HandL_"],
  ["腰","Waist"],   ["┗","Waist_"],
  ["足","Leg"],     ["┗","Leg_"],
  ["他","Other"],   ["┗","Other_"],
  ["他2","Other2"], ["┗","Other2_"],
  ["他3","Other3"], ["┗","Other3_"],
  ["他4","Other4"], ["┗","Other4_"]
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

## 履歴

$pc{"history0Grow"} .= '器用'.$pc{'sttPreGrowA'} if $pc{'sttPreGrowA'};
$pc{"history0Grow"} .= '敏捷'.$pc{'sttPreGrowB'} if $pc{'sttPreGrowB'};
$pc{"history0Grow"} .= '筋力'.$pc{'sttPreGrowC'} if $pc{'sttPreGrowC'};
$pc{"history0Grow"} .= '生命'.$pc{'sttPreGrowD'} if $pc{'sttPreGrowD'};
$pc{"history0Grow"} .= '知力'.$pc{'sttPreGrowE'} if $pc{'sttPreGrowE'};
$pc{"history0Grow"} .= '精神'.$pc{'sttPreGrowF'} if $pc{'sttPreGrowF'};

my @history;
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
  push(@history, {
    "NUM"    => $_,
    "DATE"   => $pc{'history'.$_.'Date'},
    "TITLE"  => $pc{'history'.$_.'Title'},
    "EXP"    => $pc{'history'.$_.'Exp'},
    "HONOR"  => $pc{'history'.$_.'Honor'},
    "MONEY"  => $pc{'history'.$_.'Money'},
    "GROW"   => $pc{'history'.$_.'Grow'},
    "GM"     => $pc{'history'.$_.'Gm'},
    "MEMBER" => $pc{'history'.$_.'Member'},
  } );
}
$SHEET->param(History => \@history);

### バックアップ
opendir(my $DIR,"${set::data_dir}${file}/backup");
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

### パスワード要求
$SHEET->param(ReqdPassword => (!$pc{'protect'} || $pc{'protect'} eq 'password' ? 1 : 0) );

### フェロー
$SHEET->param(FellowMode => param('f'));

### タイトル
$SHEET->param(title => $set::title);

$SHEET->param("imageSrc" => "${set::data_dir}${file}/image.$pc{'image'}");

### エラー
$SHEET->param(error => $main::login_error);

### 出力 ##################################################
print "Content-Type: text/html\n\n";
print $SHEET->output;

### サブルーチン ##################################################
sub tag_unescape {
  my $text = $_[0];
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  
  $text =~ s/{{([0-9\+\-\*\/\%\(\) ]+?)}}/s_eval($1);/eg;
  
  $text =~ s|(―+)|&ddash($1);|eg;
  
  $text =~ s/[|｜](.+?)《(.*?)》/<ruby>$1<rp>(<\/rp><rt>$2<\/rt><rp>)<\/rp><\/ruby>/gi; # なろう式ルビ
  $text =~ s/&lt;br&gt;/<br>/gi;
  
  return $text;
}

sub ddash {
  my $dash = $_[0];
  $dash =~ s|―|<span>―</span>|g;
  return "<span class=\"d-dash\">$dash</span>";
}

1;