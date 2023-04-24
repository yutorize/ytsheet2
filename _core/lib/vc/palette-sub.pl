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
  elsif($tool eq 'tekey' ){ $bot{'TKY'} = $bot{'BCD'} = 1; }
  elsif($tool eq 'bcdice'){ $bot{'BCD'} = 1; }
  
  if(!$type){
    # 基本判定
    $text .= "### ■判定\n";
    $text .= "2d6+{バイタリティ} 【バイタリティ】判定\n";
    $text .= "2d6+{テクニック} 【テクニック】判定\n";
    $text .= "2d6+{クレバー} 【クレバー】判定\n";
    $text .= "2d6+{カリスマ} 【カリスマ】判定\n";
    $text .= "2d6+{命中値} 【命中値】判定\n";
    $text .= "2d6+{詠唱値} 【詠唱値】判定\n";
    $text .= "2d6+{回避値} 【回避値】判定\n";
    $text .= "2d6+{攻撃値} 【攻撃値】判定\n";
    $text .= "2d6+{意志値} 【意志値】判定\n";
    $text .= "2d6+{物防値} 【物防値】判定\n";
    $text .= "2d6+{魔防値} 【魔防値】判定\n";
    $text .= "2d6+{行動値} 【行動値】判定\n";
    $text .= "2d6+{耐久値} 【耐久値】判定\n";
    
    $text .= "###\n" if $bot{'YTC'} || $bot{'TKY'};
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
  
  if  (!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//レベル=$::pc{'level'}";
    push @propaties, "//バイタリティ=$::pc{'vitality'}";
    push @propaties, "//テクニック=$::pc{'technic'}";
    push @propaties, "//クレバー=$::pc{'clever'}";
    push @propaties, "//カリスマ=$::pc{'carisma'}";
    push @propaties, "//命中値=$::pc{'battleTotalAcc'}";
    push @propaties, "//詠唱値=$::pc{'battleTotalSpl'}";
    push @propaties, "//回避値=$::pc{'battleTotalEva'}";
    push @propaties, "//攻撃値=$::pc{'battleTotalAtk'}";
    push @propaties, "//意志値=$::pc{'battleTotalDet'}";
    push @propaties, "//物防値=$::pc{'battleTotalDef'}";
    push @propaties, "//魔防値=$::pc{'battleTotalMdf'}";
    push @propaties, "//行動値=$::pc{'battleTotalIni'}";
    push @propaties, "//耐久値=$::pc{'battleTotalStr'}";
    #push @propaties, "### ■代入パラメータ";
  }
  
  return @propaties;
}

1;