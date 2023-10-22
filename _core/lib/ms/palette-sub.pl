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
  elsif($tool eq 'bcdice'){ $bot{BCD} = 1; }

  $text .= "1MS<={身体} 【身体】判定（ダイス1個）\n";
  $text .= "2MS<={身体} 【身体】判定（ダイス2個）\n";
  $text .= "3MS<={身体} 【身体】判定（ダイス3個）\n";
  $text .= "\n";
  $text .= "1MS<={異質} 【異質】判定（ダイス1個）\n";
  $text .= "2MS<={異質} 【異質】判定（ダイス2個）\n";
  $text .= "3MS<={異質} 【異質】判定（ダイス3個）\n";
  $text .= "\n";
  $text .= "1MS<={社会} 【社会】判定（ダイス1個）\n";
  $text .= "2MS<={社会} 【社会】判定（ダイス2個）\n";
  $text .= "3MS<={社会} 【社会】判定（ダイス3個）\n";


  
  return $text;
}

### プリセット（シンプル） ###########################################################################
sub palettePresetSimple {
  my $tool = shift;
  my $type = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{YTC} = 1; }
  elsif($tool eq 'bcdice'){ $bot{BCD} = 1; }

  $text .= "1MS<=$::pc{statusPhysical} 【身体】判定（ダイス1個）\n";
  $text .= "2MS<=$::pc{statusPhysical} 【身体】判定（ダイス2個）\n";
  $text .= "3MS<=$::pc{statusPhysical} 【身体】判定（ダイス3個）\n";
  $text .= "\n";
  $text .= "1MS<=$::pc{statusSpecial} 【異質】判定（ダイス1個）\n";
  $text .= "2MS<=$::pc{statusSpecial} 【異質】判定（ダイス2個）\n";
  $text .= "3MS<=$::pc{statusSpecial} 【異質】判定（ダイス3個）\n";
  $text .= "\n";
  $text .= "1MS<=$::pc{statusSocial} 【社会】判定（ダイス1個）\n";
  $text .= "2MS<=$::pc{statusSocial} 【社会】判定（ダイス2個）\n";
  $text .= "3MS<=$::pc{statusSocial} 【社会】判定（ダイス3個）\n";
  
  return $text;
}

### デフォルト変数 ###################################################################################
sub paletteProperties {
  my $tool = shift;
  my $type = shift;
  my @propaties;
  if(!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//身体=$::pc{statusPhysical}";
    push @propaties, "//異質=$::pc{statusSpecial}";
    push @propaties, "//社会=$::pc{statusSocial}";
  }
  return @propaties;
}

1;