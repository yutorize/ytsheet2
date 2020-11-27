################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

sub getValueWithDefault {
  my $column = $_[0];
  return $::pc{$column} ? $::pc{$column} : '0';
}

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
    $text .= "//侵蝕率ダイスボーナス=0\n";
    $text .= "### ■バフ・デバフ\n";
    $text .= "//ダイス修正=0\n";
    $text .= "//C値修正=0\n";
    $text .= "//達成値修正=0\n";
    $text .= "//攻撃力修正=0\n";
    $text .= "### ■判定\n";
    $text .= "{肉体}+{DB}dx+{AB}\@10+{CB} 【肉体】判定\n";
    $text .= "{感覚}+{DB}dx+{AB}\@10+{CB} 【感覚】判定\n";
    $text .= "{精神}+{DB}dx+{AB}\@10+{CB} 【精神】判定\n";
    $text .= "{社会}+{DB}dx+{AB}\@10+{CB} 【社会】判定\n";
    $text .= "{肉体}+{DB}dx+{白兵}+{AB}\@10+{CB} 〈白兵〉判定\n";
    $text .= "{肉体}+{DB}dx+{回避}+{AB}\@10+{CB} 〈回避〉判定\n";
    $text .= "{感覚}+{DB}dx+{射撃}+{AB}\@10+{CB} 〈射撃〉判定\n";
    $text .= "{感覚}+{DB}dx+{知覚}+{AB}\@10+{CB} 〈知覚〉判定\n";
    $text .= "{精神}+{DB}dx+{RC}+{AB}\@10+{CB} 〈ＲＣ〉判定\n";
    $text .= "{精神}+{DB}dx+{意志}+{AB}\@10+{CB} 〈意志〉判定\n";
    $text .= "{社会}+{DB}dx+{交渉}+{AB}\@10+{CB} 〈交渉〉判定\n";
    $text .= "{社会}+{DB}dx+{調達}+{AB}\@10+{CB} 〈調達〉判定\n";
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "{肉体}+{DB}dx+{$::pc{'skillRide'.$num.'Name'}}+{AB}\@10+{CB} 〈$::pc{'skillRide'.$num.'Name'}〉判定\n" if $::pc{'skillRide'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "{感覚}+{DB}dx+{$::pc{'skillArt'.$num.'Name'}}+{AB}\@10+{CB} 〈$::pc{'skillArt'.$num.'Name'}〉判定\n"  if $::pc{'skillArt'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "{精神}+{DB}dx+{$::pc{'skillKnow'.$num.'Name'}}+{AB}\@10+{CB} 〈$::pc{'skillKnow'.$num.'Name'}〉判定\n" if $::pc{'skillKnow'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "{社会}+{DB}dx+{$::pc{'skillInfo'.$num.'Name'}}+{AB}\@10+{CB} 〈$::pc{'skillInfo'.$num.'Name'}〉判定\n" if $::pc{'skillInfo'.$num.'Name'};
    }
    $text .= "\n";
    foreach my $num (1 .. $::pc{'comboNum'}){
      next if !$::pc{'combo'.$num.'Name'};
      $text .= "### ■コンボ: $::pc{'combo'.$num.'Name'}\n";
      $text .= "【$::pc{'combo'.$num.'Name'}】：$::pc{'combo'.$num.'Combo'}\n";
      foreach my $i (1..4) {
        next if !$::pc{'combo'.$num.'Condition'.$i};
        $text .= "▼$::pc{'combo'.$num.'Condition'.$i} ----------\n" if $bot{'YTC'};
        if(!$::pc{'comboCalcOff'}){
          if($::pc{"combo${num}Stt"}){
            if   ($::pc{"combo${num}Stt"} eq '肉体'){ $text .= '{肉体}+'; }
            elsif($::pc{"combo${num}Stt"} eq '感覚'){ $text .= '{感覚}+'; }
            elsif($::pc{"combo${num}Stt"} eq '精神'){ $text .= '{精神}+'; }
            elsif($::pc{"combo${num}Stt"} eq '社会'){ $text .= '{社会}+'; }
          }
          else {
            if   ($::pc{"combo${num}Skill"} =~ /^(白兵|回避|運転)/){ $text .= '{肉体}+';  }
            elsif($::pc{"combo${num}Skill"} =~ /^(射撃|知覚|芸術)/){ $text .= '{感覚}+';  }
            elsif($::pc{"combo${num}Skill"} =~ /^(RC|意思|知識)/)  { $text .= '{精神}+';  }
            elsif($::pc{"combo${num}Skill"} =~ /^(交渉|調達|情報)/){ $text .= '{社会}+';  }
          }
        }
        $text .= "$::pc{'combo'.$num.'DiceAdd'.$i}+{DB}dx+$::pc{'combo'.$num.'Fixed'.$i}+{AB}\@$::pc{'combo'.$num.'Crit'.$i}+{CB}";
        $text .= " 判定／$::pc{'combo'.$num.'Condition'.$i}／$::pc{'combo'.$num.'Name'}" if $bot{'BCD'};
        $text .= "\n";
        if($::pc{'combo'.$num.'Atk'.$i}){
          $text .= "d10+$::pc{'combo'.$num.'Atk'.$i}+{AtkB} ダメージ";
          $text .= "／$::pc{'combo'.$num.'Condition'.$i}／$::pc{'combo'.$num.'Name'}" if $bot{'BCD'};
          $text .= "\n";
        }
      }
      $text .= "\n";
    }
  }
  $text .= "### ■代入式\n";
  $text .= "//DB={侵蝕率ダイスボーナス}+{ダイス修正}\n";
  $text .= "//CB={C値修正}\n";
  $text .= "//AB={達成値修正}\n";
  $text .= "//AtkB={攻撃力修正}\n";
  $text .= "\n";
  $text .= "###\n";
  
  if($tool eq 'bcdice') {
    $text =~ s/^(.+?)dx(.+?)@(.+?)(\s|$)/\($1\)dx$2\@($3)$4/mg;
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
    $text .= "//侵蝕率ダイスボーナス=0\n";
    $text .= "### ■バフ・デバフ\n";
    $text .= "//ダイス修正=0\n";
    $text .= "//C値修正=0\n";
    $text .= "//達成値修正=0\n";
    $text .= "//攻撃力修正=0\n";
    $text .= "### ■判定\n";
    $text .= "$::pc{'sttTotalBody'  }+{DB}dx+{AB}\@10+{CB} 【肉体】判定\n";
    $text .= "$::pc{'sttTotalSense' }+{DB}dx+{AB}\@10+{CB} 【感覚】判定\n";
    $text .= "$::pc{'sttTotalMind'  }+{DB}dx+{AB}\@10+{CB} 【精神】判定\n";
    $text .= "$::pc{'sttTotalSocial'}+{DB}dx+{AB}\@10+{CB} 【社会】判定\n";
    $text .= "$::pc{'sttTotalBody'  }+{DB}dx+" . getValueWithDefault('skillMelee'    ) . "+{AB}\@10+{CB} 〈白兵〉判定\n";
    $text .= "$::pc{'sttTotalBody'  }+{DB}dx+" . getValueWithDefault('skillDodge'    ) . "+{AB}\@10+{CB} 〈回避〉判定\n";
    $text .= "$::pc{'sttTotalSense' }+{DB}dx+" . getValueWithDefault('skillRanged'   ) . "+{AB}\@10+{CB} 〈射撃〉判定\n";
    $text .= "$::pc{'sttTotalSense' }+{DB}dx+" . getValueWithDefault('skillPercept'  ) . "+{AB}\@10+{CB} 〈知覚〉判定\n";
    $text .= "$::pc{'sttTotalMind'  }+{DB}dx+" . getValueWithDefault('skillRC'       ) . "+{AB}\@10+{CB} 〈ＲＣ〉判定\n";
    $text .= "$::pc{'sttTotalMind'  }+{DB}dx+" . getValueWithDefault('skillWill'     ) . "+{AB}\@10+{CB} 〈意志〉判定\n";
    $text .= "$::pc{'sttTotalSocial'}+{DB}dx+" . getValueWithDefault('skillNegotiate') . "+{AB}\@10+{CB} 〈交渉〉判定\n";
    $text .= "$::pc{'sttTotalSocial'}+{DB}dx+" . getValueWithDefault('skillProcure'  ) . "+{AB}\@10+{CB} 〈調達〉判定\n";
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "$::pc{'sttTotalBody'}+{DB}dx+" . getValueWithDefault('skillRide'.$num) . "+{AB}\@10+{CB} 〈$::pc{'skillRide'.$num.'Name'}〉判定\n" if $::pc{'skillRide'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "$::pc{'sttTotalSense'}+{DB}dx+" . getValueWithDefault('skillArt'.$num) . "+{AB}\@10+{CB} 〈$::pc{'skillArt'.$num.'Name'}〉判定\n"  if $::pc{'skillArt'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "$::pc{'sttTotalMind'}+{DB}dx+" . getValueWithDefault('skillKnow'.$num) . "+{AB}\@10+{CB} 〈$::pc{'skillKnow'.$num.'Name'}〉判定\n" if $::pc{'skillKnow'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "$::pc{'sttTotalSocial'}+{DB}dx+" . getValueWithDefault('skillInfo'.$num) . "+{AB}\@10+{CB} 〈$::pc{'skillInfo'.$num.'Name'}〉判定\n" if $::pc{'skillInfo'.$num.'Name'};
    }
    $text .= "\n";
    foreach my $num (1 .. $::pc{'comboNum'}){
      next if !$::pc{'combo'.$num.'Name'};
      $text .= "### ■コンボ: $::pc{'combo'.$num.'Name'}\n";
      $text .= "【$::pc{'combo'.$num.'Name'}】：$::pc{'combo'.$num.'Combo'}\n";
      foreach my $i (1..4) {
        next if !$::pc{'combo'.$num.'Condition'.$i};
        $text .= "▼$::pc{'combo'.$num.'Condition'.$i} ----------\n" if $bot{'YTC'};
        if(!$::pc{'comboCalcOff'}){
          if($::pc{"combo${num}Stt"}){
            if   ($::pc{"combo${num}Stt"} eq '肉体'){ $text .= $::pc{'sttTotalBody'  }.'+'; }
            elsif($::pc{"combo${num}Stt"} eq '感覚'){ $text .= $::pc{'sttTotalSense' }.'+'; }
            elsif($::pc{"combo${num}Stt"} eq '精神'){ $text .= $::pc{'sttTotalMind'  }.'+'; }
            elsif($::pc{"combo${num}Stt"} eq '社会'){ $text .= $::pc{'sttTotalSocial'}.'+'; }
          }
          else {
            if   ($::pc{"combo${num}Skill"} =~ /^(白兵|回避|運転)/){ $text .= $::pc{'sttTotalBody'  }.'+';  }
            elsif($::pc{"combo${num}Skill"} =~ /^(射撃|知覚|芸術)/){ $text .= $::pc{'sttTotalSense' }.'+';  }
            elsif($::pc{"combo${num}Skill"} =~ /^(RC|意思|知識)/)  { $text .= $::pc{'sttTotalMind'  }.'+';  }
            elsif($::pc{"combo${num}Skill"} =~ /^(交渉|調達|情報)/){ $text .= $::pc{'sttTotalSocial'}.'+';  }
          }
        }
        $text .= "$::pc{'combo'.$num.'DiceAdd'.$i}+{DB}dx+" . getValueWithDefault('combo'.$num.'Fixed'.$i) . "+{AB}\@$::pc{'combo'.$num.'Crit'.$i}+{CB} ";
        $text .= "判定／$::pc{'combo'.$num.'Condition'.$i}／$::pc{'combo'.$num.'Name'}" if $bot{'BCD'};
        $text .= "\n";
        if($::pc{'combo'.$num.'Atk'.$i}){
          $text .= "d10+$::pc{'combo'.$num.'Atk'.$i}+{AtkB} ダメージ";
          $text .= "／$::pc{'combo'.$num.'Condition'.$i}／$::pc{'combo'.$num.'Name'}" if $bot{'BCD'};
          $text .= "\n";
        }
      }
      $text .= "\n";
    }
  }
  $text .= "### ■代入式\n";
  $text .= "//DB={侵蝕率ダイスボーナス}+{ダイス修正}\n";
  $text .= "//CB={C値修正}\n";
  $text .= "//AB={達成値修正}\n";
  $text .= "//AtkB={攻撃力修正}\n";
  $text .= "\n";
  $text .= "###\n";
  
  if($bot{'BCD'}) {
    $text =~ s/^(.+?)dx(.+?)@(.+?)(\s|$)/\($1\)dx$2\@($3)$4/mg;
  }
  
  return $text;
}

### デフォルト変数 ###################################################################################
sub paletteProperties {
  my $type = shift;
  my @propaties;
  push @propaties, "//肉体=$::pc{'sttTotalBody'}"  ;
  push @propaties, "//感覚=$::pc{'sttTotalSense'}" ;
  push @propaties, "//精神=$::pc{'sttTotalMind'}"  ;
  push @propaties, "//社会=$::pc{'sttTotalSocial'}";
  push @propaties, "//白兵=".($::pc{'skillMelee'}    ||0);
  push @propaties, "//回避=".($::pc{'skillDodge'}    ||0);
  push @propaties, "//射撃=".($::pc{'skillRanged'}   ||0);
  push @propaties, "//知覚=".($::pc{'skillPercept'}  ||0);
  push @propaties, "//RC=".($::pc{'skillRC'}         ||0);
  push @propaties, "//意志=".($::pc{'skillWill'}     ||0);
  push @propaties, "//交渉=".($::pc{'skillNegotiate'}||0);
  push @propaties, "//調達=".($::pc{'skillProcure'}  ||0);
  foreach my $name ('Ride','Art','Know','Info'){
    foreach my $num (1 .. $::pc{'skillNum'}){
      next if !$::pc{'skill'.$name.$num.'Name'};
      push @propaties, "//$::pc{'skill'.$name.$num.'Name'}=".($::pc{'skill'.$name.$num}||0);
    }
  }
  return @propaties;
}

1;