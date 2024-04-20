use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-GS ##################################################################################

my %abilityToName = (
  Str => '体力',
  Psy => '魂魄',
  Tec => '技量',
  Int => '知力',
  Foc => '集中',
  Edu => '持久',
  Ref => '反射',
);
sub abilityToName {
  my $text = shift;
  $text =~ s/$_/$abilityToName{$_}/i foreach (keys %abilityToName);
  return $text;
}

### ユニットステータス出力 --------------------------------------------------
sub createUnitStatus {
  my %pc = %{$_[0]};
  my @unitStatus = (
    { '生命力' => $pc{statusLife} },
    { '負傷' => "0/$pc{statusLifeX2}"},
    { '消耗' => "0/20" },
    { '継戦' => "0/40" },
    { '呪文使用回数' => $pc{statusSpell} },
  );
  
  foreach my $key (split ',', $pc{unitStatusNotOutput}){
    @unitStatus = grep { !exists $_->{$key} } @unitStatus;
  }

  foreach my $num (1..$pc{unitStatusNum}){
    next if !$pc{"unitStatus${num}Label"};
    push(@unitStatus, { $pc{"unitStatus${num}Label"} => $pc{"unitStatus${num}Value"} });
  }

  return \@unitStatus;
}

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  delete $pc{updateMessage};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;

  if($ver < 1.24005){
    $pc{statusResist} = $pc{abilityPsyRef} + $pc{level} + $pc{statusResistMod};
    $pc{armor1MoveTotal} = $pc{statusMove} + $pc{MoveModValue} + $pc{armor1MoveMod};
  }
  if($ver < 1.24013){
    if($pc{race} eq '蜥蜴人' || ($pc{race} =~ /^昼歩く者/ && $pc{raceBase} eq '蜥蜴人')){
      $pc{statusMoveRace} = 2;
      $pc{statusMove} = $pc{statusMoveDice} * $pc{statusMoveRace} + $pc{statusMoveMod};
    }
  }

  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}

1;