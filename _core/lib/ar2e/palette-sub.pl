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
  if   (!$tool)           { $bot{YTC} = 1; }
  elsif($tool eq 'tekey' ){ $bot{TKY} = $bot{BCD} = 1; }
  elsif($tool eq 'bcdice'){ $bot{BCD} = 1; }
  ## ＰＣ
  if(!$type){
    # 基本判定
    $text .= "### ■判定\n";
    $text .= "{筋力判定}+{筋力判定ダイス}D 【筋力】判定\n";
    $text .= "{器用判定}+{器用判定ダイス}D 【器用】判定\n";
    $text .= "{敏捷判定}+{敏捷判定ダイス}D 【敏捷】判定\n";
    $text .= "{知力判定}+{知力判定ダイス}D 【知力】判定\n";
    $text .= "{感知判定}+{感知判定ダイス}D 【感知】判定\n";
    $text .= "{精神判定}+{精神判定ダイス}D 【精神】判定\n";
    $text .= "{幸運判定}+{幸運判定ダイス}D 【幸運】判定\n";
    $text .= "{命中}+{命中ダイス}D 命中判定\n";
    $text .= "{攻撃力}+{攻撃ダイス}D 攻撃力\n";
    $text .= "{回避}+{回避ダイス}D 回避判定\n";
    $text .= "{トラップ探知}+{トラップ探知ダイス}D トラップ探知判定\n";
    $text .= "{トラップ解除}+{トラップ解除ダイス}D トラップ解除判定\n";
    $text .= "{危険感知}+{危険感知ダイス}D 危険感知判定\n";
    $text .= "{エネミー識別}+{エネミー識別ダイス}D エネミー識別判定\n";
    $text .= "{アイテム鑑定}+{アイテム鑑定ダイス}D アイテム鑑定判定\n";
    $text .= "{魔術判定}+{魔術判定ダイス}D 魔術判定\n";
    $text .= "{呪歌判定}+{呪歌判定ダイス}D 呪歌判定\n";
    $text .= "{錬金術判定}+{錬金術判定ダイス}D 錬金術判定\n";
    
    $text .= "###\n" if $bot{YTC} || $bot{TKY};
  }
  
  return $text;
}

### プリセット（シンプル） ###########################################################################
sub palettePresetSimple {
  my $tool = shift;
  my $type = shift;
  
  my $text = palettePreset($tool,$type);
  my %propaty;
  foreach (paletteProperties($tool,$type)){
    if($_ =~ /^\/\/(.+?)=(.*)$/){
      $propaty{$1} = $2;
    }
  }
  my $hit = 1;
  while ($hit){
    $hit = 0;
    foreach(keys %propaty){
      if($text =~ s/\{$_\}/$propaty{$_}/i){ $hit = 1 }
    }
  }
  1 while $text =~ s/\([+\-*0-9]+\)/s_eval($&)/egi;
  
  return $text;
}

### デフォルト変数 ###################################################################################
sub paletteProperties {
  my $tool = shift;
  my $type = shift;
  my @propaties;
  ## PC
  if  (!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//CL=$::pc{level}";
    push @propaties, "//筋力=$::pc{sttStrTotal}";
    push @propaties, "//器用=$::pc{sttDexTotal}";
    push @propaties, "//敏捷=$::pc{sttAgiTotal}";
    push @propaties, "//知力=$::pc{sttIntTotal}";
    push @propaties, "//感知=$::pc{sttSenTotal}";
    push @propaties, "//精神=$::pc{sttMndTotal}";
    push @propaties, "//幸運=$::pc{sttLukTotal}";
    push @propaties, "//筋力判定={筋力}".addNum($::pc{rollStrAdd});
    push @propaties, "//筋力判定ダイス=".$::pc{rollStrDice};
    push @propaties, "//器用判定={器用}".addNum($::pc{rollDexAdd});
    push @propaties, "//器用判定ダイス=".$::pc{rollDexDice};
    push @propaties, "//敏捷判定={敏捷}".addNum($::pc{rollAgiAdd});
    push @propaties, "//敏捷判定ダイス=".$::pc{rollAgiDice};
    push @propaties, "//知力判定={知力}".addNum($::pc{rollIntAdd});
    push @propaties, "//知力判定ダイス=".$::pc{rollIntDice};
    push @propaties, "//感知判定={感知}".addNum($::pc{rollSenAdd});
    push @propaties, "//感知判定ダイス=".$::pc{rollSenDice};
    push @propaties, "//精神判定={精神}".addNum($::pc{rollMndAdd});
    push @propaties, "//精神判定ダイス=".$::pc{rollMndDice};
    push @propaties, "//幸運判定={幸運}".addNum($::pc{rollLukAdd});
    push @propaties, "//幸運判定ダイス=".$::pc{rollLukDice};
    push @propaties, "### ■代入パラメータ";
    push @propaties, "//命中={器用判定}".addNum($::pc{battleAddAcc});
    push @propaties, "//命中ダイス=".$::pc{battleDiceAcc};
    push @propaties, "//攻撃力=".($::pc{battleTotalAtk});
    push @propaties, "//攻撃ダイス=".$::pc{battleDiceAtk};
    push @propaties, "//回避={敏捷判定}".addNum($::pc{battleAddEva});
    push @propaties, "//回避ダイス=".$::pc{battleDiceEva};
    push @propaties, "//物理防御力=".$::pc{battleTotalDef};
    push @propaties, "//魔法防御力={精神}".addNum($::pc{battleAddMDef});
    push @propaties, "//行動値=".$::pc{battleTotalIni};
    push @propaties, "//移動力=".$::pc{battleTotalMove};
    push @propaties, "//トラップ探知={感知判定}".addNum($::pc{rollTrapDetectAdd});
    push @propaties, "//トラップ探知ダイス="    .$::pc{rollTrapDetectDice};
    push @propaties, "//トラップ解除={器用判定}".addNum($::pc{rollTrapReleaseAdd});
    push @propaties, "//トラップ解除ダイス="    .$::pc{rollTrapReleaseDice};
    push @propaties, "//危険感知={感知判定}"    .addNum($::pc{rollDangerDetectAdd});
    push @propaties, "//危険感知ダイス="        .$::pc{rollDangerDetectDice};
    push @propaties, "//エネミー識別={知力判定}".addNum($::pc{rollEnemyLoreAdd});
    push @propaties, "//エネミー識別ダイス="    .$::pc{rollEnemyLoreDice};
    push @propaties, "//アイテム鑑定={知力判定}".addNum($::pc{rollAppraisalAdd});
    push @propaties, "//アイテム鑑定ダイス="    .$::pc{rollAppraisalDice};
    push @propaties, "//魔術判定={知力判定}"    .addNum($::pc{rollMagicAdd});
    push @propaties, "//魔術判定ダイス="        .$::pc{rollMagicDice};
    push @propaties, "//呪歌判定={精神判定}"    .addNum($::pc{rollSongAdd});
    push @propaties, "//呪歌判定ダイス="        .$::pc{rollSongDice};
    push @propaties, "//錬金術判定={器用判定}"  .addNum($::pc{rollAlchemyAdd});
    push @propaties, "//錬金術判定ダイス="      .$::pc{rollAlchemyDice};
  }
  
  return @propaties;
}

1;