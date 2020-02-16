################## チャットパレット ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';

require './lib/palette-sub.pl';

### バックアップ情報読み込み #########################################################################
my $backup = param('backup');

### キャラクターデータ読み込み #######################################################################
my $id = param('id');
my ($file, $type) = getfile_open($id);

my $data_dir;
   if($type eq 'm'){ $data_dir = $set::mons_dir; }
elsif($type eq 'i'){ $data_dir = $set::item_dir; }
else               { $data_dir = $set::char_dir; }

our %pc = ();

my $IN;
if($backup eq "") {
  open $IN, '<', "${data_dir}${file}/data.cgi" or "";
} else {
  open $IN, '<', "${data_dir}${file}/backup/${backup}.cgi" or "";
}

$_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = tag_unescape($2);/egi while <$IN>;
$pc{'chatPalette'} =~ s/<br>/\n/g;
$pc{'skills'} =~ s/<br>/\n/gi;
$pc{$_} = tag_delete($pc{$_}) foreach keys %pc;
close($IN);

my $preset = $pc{'paletteUseVar'} ? palettePreset($type) : palettePresetRaw($type);
if ($pc{'paletteInsertType'} eq 'begin'){ $pc{'chatPalette'} = $pc{'chatPalette'}."\n".$preset; }
elsif($pc{'paletteInsertType'} eq 'end'){ $pc{'chatPalette'} = $preset."\n".$pc{'chatPalette'}; }
else {
  $pc{'chatPalette'} = $preset if !$pc{'chatPalette'};
}

sub usedCheck{
  my $var = shift;
  return 1 if !$pc{'chatPaletteUnusedHidden'};
  return 1 if $pc{'chatPalette'} =~ /\{$var\}/i;
  return 0;
}

### 出力 #############################################################################################
my $un = $pc{'chatPaletteUnusedHidden'};
print "Content-type: text/plain; charset=UTF-8\n\n";
  say $pc{'chatPalette'},"\n";
if(!$type){
  say "//器用=$pc{'bonusDex'}" if usedCheck('器用');
  say "//敏捷=$pc{'bonusAgi'}" if usedCheck('敏捷');
  say "//筋力=$pc{'bonusStr'}" if usedCheck('筋力');
  say "//生命=$pc{'bonusVit'}" if usedCheck('生命');
  say "//知力=$pc{'bonusInt'}" if usedCheck('知力');
  say "//精神=$pc{'bonusMnd'}" if usedCheck('精神');
  say "//DEX=$pc{'bonusDex'}" if usedCheck('DEX');
  say "//AGI=$pc{'bonusAgi'}" if usedCheck('AGI');
  say "//STR=$pc{'bonusStr'}" if usedCheck('STR');
  say "//VIT=$pc{'bonusVit'}" if usedCheck('VIT');
  say "//INT=$pc{'bonusInt'}" if usedCheck('INT');
  say "//MND=$pc{'bonusMnd'}" if usedCheck('MND');
  say '';
  say "//生命抵抗=$pc{'vitResistTotal'}" if usedCheck('生命抵抗');
  say "//精神抵抗=$pc{'mndResistTotal'}" if usedCheck('精神抵抗');
  say "//HP=$pc{'hpTotal'}" if usedCheck('HP');
  say "//MP=$pc{'mpTotal'}" if usedCheck('MP');
  say '';
  say "//冒険者=$pc{'level'}" if usedCheck('冒険者');
  say "//LV=$pc{'level'}" if usedCheck('LV');
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
    ['Ari','アリストクラシー'],
    ['Art','アーティザン'],
  ){
    next if !$pc{'lv'.@$_[0]};
    say "//@$_[1]=$pc{'lv'.@$_[0]}" if usedCheck(@$_[1]);
    say "//".uc(@$_[0])."=$pc{'lv'.@$_[0]}" if usedCheck(uc(@$_[0]));
  }
  say '';
  say "//魔物知識=$pc{'monsterLore'}" if $pc{'monsterLore'} && usedCheck('魔物知識');
  say "//先制力=$pc{'initiative'}" if $pc{'initiative'} && usedCheck('先制力');
  say "//スカウト技巧=$pc{'packScoTec'}" if $pc{'packScoTec'} && usedCheck('スカウト技巧');
  say "//スカウト運動=$pc{'packScoAgi'}" if $pc{'packScoAgi'} && usedCheck('スカウト運動');
  say "//スカウト観察=$pc{'packScoObs'}" if $pc{'packScoObs'} && usedCheck('スカウト観察');
  say "//レンジャー技巧=$pc{'packRanTec'}" if $pc{'packRanTec'} && usedCheck('レンジャー技巧');
  say "//レンジャー運動=$pc{'packRanAgi'}" if $pc{'packRanAgi'} && usedCheck('レンジャー運動');
  say "//レンジャー観察=$pc{'packRanObs'}" if $pc{'packRanObs'} && usedCheck('レンジャー観察');
  say "//セージ知識=$pc{'packSagKno'}" if $pc{'packSagKno'} && usedCheck('セージ知識');
  say "//バード知識=$pc{'packBarKno'}" if $pc{'packBarKno'} && usedCheck('バード知識');
  say "//ライダー運動=$pc{'packRidAgi'}" if $pc{'packRidAgi'} && usedCheck('ライダー運動');
  say "//ライダー知識=$pc{'packRidKno'}" if $pc{'packRidKno'} && usedCheck('ライダー知識');
  say "//ライダー観察=$pc{'packRidObs'}" if $pc{'packRidObs'} && usedCheck('ライダー観察');
  say "//アルケミスト知識=$pc{'packAlcKno'}" if $pc{'packAlcKno'} && usedCheck('アルケミスト知識');
  say '';
  
  foreach (
    ['Sor', '真語魔法'],
    ['Con', '操霊魔法'],
    ['Pri', '神聖魔法'],
    ['Mag', '魔動機術'],
    ['Fai', '妖精魔法'],
    ['Dem', '召異魔法'],
    ['Gri', '秘奥魔法'],
    ['Bar', '呪歌'],
    ['Alc', '賦術'],
    ['Mys', '占瞳'],
  ){
    next if !$pc{'lv'.@$_[0]};
    say "//@$_[1]=$pc{'magicPower'.@$_[0]}" if usedCheck(@$_[1]);
  }
  say '';
  
  foreach (1 .. $pc{'weaponNum'}){
    next if $pc{'weapon'.$_.'Name'}.$pc{'weapon'.$_.'Usage'}.$pc{'weapon'.$_.'Reqd'}.
            $pc{'weapon'.$_.'Acc'}.$pc{'weapon'.$_.'Rate'}.$pc{'weapon'.$_.'Crit'}.
            $pc{'weapon'.$_.'Dmg'}.$pc{'weapon'.$_.'Own'}.$pc{'weapon'.$_.'Note'}
            eq '';
    say "//武器$_=$pc{'weapon'.$_.'Name'}" if usedCheck("武器$_");
    say "//命中$_=$pc{'weapon'.$_.'AccTotal'}" if usedCheck("命中$_");
    say "//威力$_=$pc{'weapon'.$_.'Rate'}" if usedCheck("威力$_");
    say "//C値$_=$pc{'weapon'.$_.'Crit'}" if usedCheck("C値$_");
    say "//追加D$_=$pc{'weapon'.$_.'DmgTotal'}" if usedCheck("追加D$_");
    say '';
  }
  say "//回避=$pc{'DefenseTotalAllEva'}" if usedCheck('回避');
  say "//防護=$pc{'DefenseTotalAllDef'}" if usedCheck('防護');
}
elsif($type eq 'm') {
  say "//LV=$pc{'lv'}";
  say '';
  say "//生命抵抗=$pc{'vitResist'}";
  say "//精神抵抗=$pc{'mndResist'}";
  
  say '';
  foreach (1 .. $pc{'statusNum'}){
    say "//部位$_=$pc{'status'.$_.'Style'}";
    say "//命中$_=$pc{'status'.$_.'Accuracy'}" if $pc{'status'.$_.'Accuracy'} ne '';
    say "//ダメージ$_=$pc{'status'.$_.'Damage'}" if $pc{'status'.$_.'Damage'} ne '';
    say "//回避$_=$pc{'status'.$_.'Evasion'}" if $pc{'status'.$_.'Evasion'} ne '';
    say '';
  }
  my $skills = $pc{'skills'};
  $skills =~ tr/０-９（）/0-9\(\)/;
  $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+?)(?:[0-9]+(?:レベル|LV)|\(.+\))*[\/／](?:魔力)([0-9]+)[(（][0-9]+[）)]/say "\/\/$1=$2";/megi;
  $skills =~ s/^(?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+(.+)[\/／]([0-9]+)[(（][0-9]+[）)]/say "\/\/$1=$2";/megi;
}

1;
