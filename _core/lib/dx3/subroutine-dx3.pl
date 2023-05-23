use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-DX ##################################################################################

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  my $ver = $pc{'ver'};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($ver && $ver < 1.10003){
    $pc{'comboCalcOff'} = 1;
    foreach my $num (1 .. $pc{'comboNum'}){
      $pc{"combo${num}Skill"} =~ s/[〈〉<>]//g;
      foreach (1..5) {
        $pc{"combo${num}DiceAdd".$_}  = $pc{"combo${num}Dice".$_};
        $pc{"combo${num}FixedAdd".$_} = $pc{"combo${num}Fixed".$_};
      }
    }
  }
  if($ver < 1.11001){
    $pc{'paletteUseBuff'} = 1;
  }
  if($ver < 1.12012){
    foreach my $num (1 .. $pc{'historyNum'}){
      $pc{"history${num}ExpApply".$_} = 1 if $pc{"history${num}Exp".$_};
    }
  }
  if($ver < 1.12015){
    $pc{'skillRideNum'} = $pc{'skillNum'};
    $pc{'skillArtNum'}  = $pc{'skillNum'};
    $pc{'skillKnowNum'} = $pc{'skillNum'};
    $pc{'skillInfoNum'} = $pc{'skillNum'};
  }
  if($ver < 1.13002){
    ($pc{'characterName'},$pc{'characterNameRuby'}) = split(':', $pc{'characterName'});
    ($pc{'aka'},$pc{'akaRuby'}) = split(':', $pc{'aka'});
  }
  $pc{'ver'} = $main::ver;
  $pc{'lasttimever'} = $ver;
  return %pc;
}

1;