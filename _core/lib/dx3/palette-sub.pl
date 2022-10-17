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
    foreach my $num (1 .. $::pc{'skillRideNum'}){
      $text .= "{肉体}+{DB}dx+{$::pc{'skillRide'.$num.'Name'}}+{AB}\@10+{CB} 〈$::pc{'skillRide'.$num.'Name'}〉判定\n" if $::pc{'skillRide'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillArtNum'}){
      $text .= "{感覚}+{DB}dx+{$::pc{'skillArt'.$num.'Name'}}+{AB}\@10+{CB} 〈$::pc{'skillArt'.$num.'Name'}〉判定\n"  if $::pc{'skillArt'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillKnowNum'}){
      $text .= "{精神}+{DB}dx+{$::pc{'skillKnow'.$num.'Name'}}+{AB}\@10+{CB} 〈$::pc{'skillKnow'.$num.'Name'}〉判定\n" if $::pc{'skillKnow'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillInfoNum'}){
      $text .= "{社会}+{DB}dx+{$::pc{'skillInfo'.$num.'Name'}}+{AB}\@10+{CB} 〈$::pc{'skillInfo'.$num.'Name'}〉判定\n" if $::pc{'skillInfo'.$num.'Name'};
    }
    $text .= "\n";
    foreach my $num (1 .. $::pc{'comboNum'}){
      next if !$::pc{'combo'.$num.'Name'};
      $text .= "### ■コンボ: $::pc{'combo'.$num.'Name'}\n";
      $text .= "【$::pc{'combo'.$num.'Name'}】：$::pc{'combo'.$num.'Combo'}\n";
      $text .= textTiming($::pc{'combo'.$num.'Timing'})." / $::pc{'combo'.$num.'Skill'} / $::pc{'combo'.$num.'Dfclty'} / $::pc{'combo'.$num.'Target'} / $::pc{'combo'.$num.'Range'}\n";
      $text .= ($bot{'YTC'} ? '@侵蝕' : ':侵蝕率')  . "+$::pc{'combo'.$num.'Encroach'}\n";
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
        if($::pc{'combo'.$num.'Atk'.$i} ne ''){
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
  
  my $text = palettePreset($tool,$type);
  my %propaty;
  foreach (paletteProperties($type)){
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
  my $type = shift;
  my @propaties;
  push @propaties, "### ■能力値";
  push @propaties, "//肉体=$::pc{'sttTotalBody'}"  ;
  push @propaties, "//感覚=$::pc{'sttTotalSense'}" ;
  push @propaties, "//精神=$::pc{'sttTotalMind'}"  ;
  push @propaties, "//社会=$::pc{'sttTotalSocial'}";
  push @propaties, "### ■技能";
  push @propaties, "//白兵=".($::pc{'skillTotalMelee'}    ||0);
  push @propaties, "//回避=".($::pc{'skillTotalDodge'}    ||0);
  push @propaties, "//射撃=".($::pc{'skillTotalRanged'}   ||0);
  push @propaties, "//知覚=".($::pc{'skillTotalPercept'}  ||0);
  push @propaties, "//RC="  .($::pc{'skillTotalRC'}       ||0);
  push @propaties, "//意志=".($::pc{'skillTotalWill'}     ||0);
  push @propaties, "//交渉=".($::pc{'skillTotalNegotiate'}||0);
  push @propaties, "//調達=".($::pc{'skillTotalProcure'}  ||0);
  foreach my $name ('Ride','Art','Know','Info'){
    foreach my $num (1 .. $::pc{'skill'.$name.'Num'}){
      next if !$::pc{'skill'.$name.$num.'Name'};
      push @propaties, "//$::pc{'skill'.$name.$num.'Name'}=".($::pc{'skillTotal'.$name.$num}||0);
    }
  }
  return @propaties;
}

sub textTiming {
  my $text = shift;
  $text =~ s/(オート|メジャー|マイナー)(アクション)?/$1アクション/g;
  $text =~ s/リアク?(ション)?/リアクション/g;
  $text =~ s/(セットアップ|クリンナップ)(プロセス)?/$1プロセス/g;
  return $text;
}

1;