################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;
my @class_names;
foreach(@data::class_names){
  push(@class_names, $_);
}

### プリセット #######################################################################################
sub palettePreset {
  my $tool = shift;
  my $type = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{'YTC'} = 1; }
  elsif($tool eq 'tekey' ){ $bot{'TKY'} = $bot{'BCD'} = 1; }
  elsif($tool eq 'bcdice'){ $bot{'BCD'} = 1; }
  ## ＰＣ
  if(!$type){
    # 基本判定
    
    # 魔法
    
    # 攻撃
    
    #
    $text .= "###\n" if $bot{'YTC'} || $bot{'TKY'};
  }
  ## 魔物
  elsif($type eq 'm') {
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
      if($text =~ s/\Q{$_}\E/$propaty{$_}/i){ $hit = 1 }
    }
  }
  1 while $text =~ s/(?<![0-9])\([+\-*0-9]+\)/s_eval($&)/egi;
  $text =~ s/[0-9]+\/6/int s_eval($&)/egi;
  1 while $text =~ s/(?<![0-9])\([+\-*0-9]+\)/s_eval($&)/egi;
  
  return $text;
}

### デフォルト変数 ###################################################################################
sub paletteProperties {
  my $tool = shift;
  my $type = shift;
  my @propaties;
  ## PC
  if  (!$type){
  }
  ## 魔物
  elsif($type eq 'm') {
  }
  
  return @propaties;
}

1;