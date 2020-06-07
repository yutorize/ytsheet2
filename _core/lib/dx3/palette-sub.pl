################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

sub palettePreset {
  my $type = shift;
  my $tool = shift;
  my $text;
  ## ＰＣ
  if(!$type){
    $text .= "//EDB=0\n";
    $text .= "  ※侵蝕率によるダイスボーナス\n";
    $text .= "{肉体}+{EDB}dx+{白兵}\@10 〈白兵〉判定\n";
    $text .= "{肉体}+{EDB}dx+{回避}\@10 〈回避〉判定\n";
    $text .= "{感覚}+{EDB}dx+{射撃}\@10 〈射撃〉判定\n";
    $text .= "{感覚}+{EDB}dx+{知覚}\@10 〈感覚〉判定\n";
    $text .= "{精神}+{EDB}dx+{ＲＣ}\@10 〈ＲＣ〉判定\n";
    $text .= "{精神}+{EDB}dx+{意思}\@10 〈意思〉判定\n";
    $text .= "{社会}+{EDB}dx+{交渉}\@10 〈交渉〉判定\n";
    $text .= "{社会}+{EDB}dx+{調達}\@10 〈調達〉判定\n";
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "{肉体}+{EDB}dx+{$::pc{'skillRide'.$num.'Name'}}\@10 〈$::pc{'skillRide'.$num.'Name'}〉判定\n" if $::pc{'skillRide'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "{感覚}+{EDB}dx+{$::pc{'skillArt'.$num.'Name'}}\@10 〈$::pc{'skillArt'.$num.'Name'}〉判定\n"  if $::pc{'skillArt'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "{精神}+{EDB}dx+{$::pc{'skillKnow'.$num.'Name'}}\@10 〈$::pc{'skillKnow'.$num.'Name'}〉判定\n" if $::pc{'skillKnow'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{'skillNum'}){
      $text .= "{社会}+{EDB}dx+{$::pc{'skillInfo'.$num.'Name'}}\@10 〈$::pc{'skillInfo'.$num.'Name'}〉判定\n" if $::pc{'skillInfo'.$num.'Name'};
    }
    $text .= "\n";
    foreach my $num (1 .. $::pc{'comboNum'}){
      next if !$::pc{'combo'.$num.'Name'};
      $text .= "$::pc{'combo'.$num.'Name'}\n";
      foreach my $i (1..4) {
        next if !$::pc{'combo'.$num.'Condition'.$i};
        $text .= "$::pc{'combo'.$num.'Condition'.$i}\n";
        $text .= "$::pc{'combo'.$num.'Dice'.$i}+{EDB}dx+$::pc{'combo'.$num.'Fixed'.$i}\@$::pc{'combo'.$num.'Crit'.$i}\n";
      }
    }
  }
  
  if($tool eq 'bcdice') {
    $text =~ s/^(.+?)dx/\($1\)dx/mg;
  }
  
  return $text;
}

sub palettePresetRaw {
  my $type = shift;
  my $tool = shift;
  my $text = palettePreset($type,$tool);
  my %property;
  $_ =~ s|^//(.*?)=(.*?)$|$property{$1} = $2;|egi foreach paletteProperties($type);
  $text =~ s|\{$_\}|$property{$_}|g foreach keys %property;
  
  return $text;
}

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
  push @propaties, "//ＲＣ=".($::pc{'skillRC'}       ||0);
  push @propaties, "//意思=".($::pc{'skillWill'}     ||0);
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

sub palettePropertiesUsedOnly {
  my $type = shift;
  my $palette = shift;
  my %used;
  my @propaties;
  foreach (paletteProperties($type)){
    if($_ =~ "^//(.+?)="){
      if($palette =~ /\{($1)\}/){ push @propaties, $_ }
    }
    elsif(!$_){
      push @propaties, '';
    }
  }
  return @propaties;
}


1;