################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

### プリセット #######################################################################################
sub palettePreset {
  my $tool = shift;
  my $type = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{'YTC'} = 1; }
  elsif($tool eq 'bcdice'){ $bot{'BCD'} = 1; }
  ## ＰＣ
  if(!$type){
    # 基本判定
    $text .= "### ■判定\n";
    $text .= "{筋力}+$::pc{'rollStrDice'}D 【筋力】判定\n";
    $text .= "{器用}+$::pc{'rollDexDice'}D 【器用】判定\n";
    $text .= "{敏捷}+$::pc{'rollAgiDice'}D 【敏捷】判定\n";
    $text .= "{知力}+$::pc{'rollIntDice'}D 【知力】判定\n";
    $text .= "{感知}+$::pc{'rollSenDice'}D 【感知】判定\n";
    $text .= "{精神}+$::pc{'rollMndDice'}D 【精神】判定\n";
    $text .= "{幸運}+$::pc{'rollLukDice'}D 【幸運】判定\n";
    $text .= "{命中}+{命中ダイス}D 命中判定\n";
    $text .= "{攻撃力}+{攻撃ダイス}D 攻撃力\n";
    $text .= "{回避}+{回避ダイス}D 回避判定\n";
    $text .= "{トラップ探知}+$::pc{'rollTrapDetectDice'}D トラップ探知判定\n";
    $text .= "{トラップ解除}+$::pc{'rollTrapReleaseDice'}D トラップ解除判定\n";
    $text .= "{危険感知}+$::pc{'rollDangerDetectDice'}D 危険感知判定\n";
    $text .= "{エネミー識別}+$::pc{'rollEnemyLoreDice'}D エネミー識別判定\n";
    $text .= "{アイテム鑑定}+$::pc{'rollAppraisalDice'}D アイテム鑑定判定\n";
    $text .= "{魔術判定}+$::pc{'rollMagicDice'}D 魔術判定\n";
    $text .= "{呪歌判定}+$::pc{'rollSongDice'}D 呪歌判定\n";
    $text .= "{錬金術判定}+$::pc{'rollAlchemyDice'}D 錬金術判定\n";
    $text .= "\n";
  }
  
  return $text;
}

### プリセット（シンプル） ###########################################################################
sub palettePresetSimple {
  my $tool = shift;
  my $type = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{'YTC'} = 1; }
  elsif($tool eq 'bcdice'){ $bot{'BCD'} = 1; }
  ## ＰＣ
  if(!$type){
    # 基本判定
    $text .= "### ■判定\n";
    $text .= "$::pc{'rollStr'}+$::pc{'rollStrDice'}D 【筋力】判定\n";
    $text .= "$::pc{'rollDex'}+$::pc{'rollDexDice'}D 【器用】判定\n";
    $text .= "$::pc{'rollAgi'}+$::pc{'rollAgiDice'}D 【敏捷】判定\n";
    $text .= "$::pc{'rollInt'}+$::pc{'rollIntDice'}D 【知力】判定\n";
    $text .= "$::pc{'rollSen'}+$::pc{'rollSenDice'}D 【感知】判定\n";
    $text .= "$::pc{'rollMnd'}+$::pc{'rollMndDice'}D 【精神】判定\n";
    $text .= "$::pc{'rollLuk'}+$::pc{'rollLukDice'}D 【幸運】判定\n";
    $text .= "\n";
    $text .= "$::pc{'battleTotalAcc'}+$::pc{'battleDiceAcc'}D 命中判定\n";
    $text .= "$::pc{'battleTotalAtk'}+$::pc{'battleDiceAtk'}D 攻撃力\n";
    $text .= "$::pc{'battleTotalEva'}+$::pc{'battleDiceEva'}D 回避判定\n";
    $text .= "\n";
    $text .= "$::pc{'rollTrapDetect'}+$::pc{'rollTrapDetectDice'}D トラップ探知判定\n";
    $text .= "$::pc{'rollTrapRelease'}+$::pc{'rollTrapReleaseDice'}D トラップ解除判定\n";
    $text .= "$::pc{'rollDangerDetect'}+$::pc{'rollDangerDetectDice'}D 危険感知判定\n";
    $text .= "$::pc{'rollEnemyLore'}+$::pc{'rollEnemyLoreDice'}D エネミー識別判定\n";
    $text .= "$::pc{'rollAppraisal'}+$::pc{'rollAppraisalDice'}D アイテム鑑定判定\n";
    $text .= "$::pc{'rollMagic'}+$::pc{'rollMagicDice'}D 魔術判定\n";
    $text .= "$::pc{'rollSong'}+$::pc{'rollSongDice'}D 呪歌判定\n";
    $text .= "$::pc{'rollAlchemy'}+$::pc{'rollAlchemyDice'}D 錬金術判定\n";
    $text .= "\n";
  }
  
  return $text;
}

### デフォルト変数 ###################################################################################
sub paletteProperties {
  my $type = shift;
  my @propaties;
  ## PC
  if  (!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//筋力=$::pc{'rollStr'}";
    push @propaties, "//器用=$::pc{'rollDex'}";
    push @propaties, "//敏捷=$::pc{'rollAgi'}";
    push @propaties, "//知力=$::pc{'rollInt'}";
    push @propaties, "//感知=$::pc{'rollSen'}";
    push @propaties, "//精神=$::pc{'rollMnd'}";
    push @propaties, "//幸運=$::pc{'rollLuk'}";
    push @propaties, "### ■代入パラメータ";
    push @propaties, "//命中={器用}".addNum($::pc{'battleAddAcc'});
    push @propaties, "//命中ダイス=".$::pc{'battleDiceAcc'};
    push @propaties, "//攻撃力=".($::pc{'battleTotalAtk'});
    push @propaties, "//攻撃ダイス=".$::pc{'battleDiceAtk'};
    push @propaties, "//回避={敏捷}".addNum($::pc{'battleAddEva'});
    push @propaties, "//回避ダイス=".$::pc{'battleDiceEva'};
    push @propaties, "//物理防御力=".$::pc{'battleTotalDef'};
    push @propaties, "//魔法防御力={精神}".addNum($::pc{'battleTotalMDef'});
    push @propaties, "//行動値=".$::pc{'battleAddIni'};
    push @propaties, "//移動力=".$::pc{'battleAddMove'};
    push @propaties, "//トラップ探知={感知}".addNum($::pc{'rollTrapDetectAdd'});
    push @propaties, "//トラップ解除={器用}".addNum($::pc{'rollTrapReleaseAdd'});
    push @propaties, "//危険感知={感知}"    .addNum($::pc{'rollDangerDetectAdd'});
    push @propaties, "//エネミー識別={知力}".addNum($::pc{'rollEnemyLoreAdd'});
    push @propaties, "//アイテム鑑定={知力}".addNum($::pc{'rollAppraisalAdd'});
    push @propaties, "//魔術判定={知力}"    .addNum($::pc{'rollMagicAdd'});
    push @propaties, "//呪歌判定={精神}"    .addNum($::pc{'rollSongAdd'});
    push @propaties, "//錬金術判定={器用}"  .addNum($::pc{'rollAlchemyAdd'});
  }
  
  return @propaties;
}

1;