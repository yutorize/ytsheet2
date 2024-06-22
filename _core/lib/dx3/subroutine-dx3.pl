use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-DX ##################################################################################

### ユニットステータス出力 --------------------------------------------------
sub createUnitStatus {
  my %pc = %{$_[0]};
  my @unitStatus = (
    { 'HP' => $pc{maxHpTotal}.'/'.$pc{maxHpTotal} },
    { '侵蝕' => $pc{baseEncroach} },
    { 'ロイス' => $pc{loisHave}.'/'.$pc{loisMax} },
    { '財産' => $pc{savingTotal} },
    { '行動' => $pc{initiativeTotal} },
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
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($ver && $ver < 1.10003){
    $pc{comboCalcOff} = 1;
    foreach my $num (1 .. $pc{comboNum}){
      $pc{"combo${num}Skill"} =~ s/[〈〉<>]//g;
      foreach (1..5) {
        $pc{"combo${num}DiceAdd".$_}  = $pc{"combo${num}Dice".$_};
        $pc{"combo${num}FixedAdd".$_} = $pc{"combo${num}Fixed".$_};
      }
    }
  }
  if($ver < 1.11001){
    $pc{paletteUseBuff} = 1;
  }
  if($ver < 1.12012){
    foreach my $num (1 .. $pc{historyNum}){
      $pc{"history${num}ExpApply".$_} = 1 if $pc{"history${num}Exp".$_};
    }
  }
  if($ver < 1.12015){
    $pc{skillRideNum} = $pc{skillNum};
    $pc{skillArtNum}  = $pc{skillNum};
    $pc{skillKnowNum} = $pc{skillNum};
    $pc{skillInfoNum} = $pc{skillNum};
  }
  if($ver < 1.13002){
    ($pc{characterName},$pc{characterNameRuby}) = split(':', $pc{characterName});
    ($pc{aka},$pc{akaRuby}) = split(':', $pc{aka});
  }
  if($ver < 1.22014){
    foreach ([0,'Body'], [1,'Sense'], [2,'Mind'], [3,'Social']){
      my $base1 = exists $data::syndrome_status{$pc{syndrome1}} ? $data::syndrome_status{$pc{syndrome1}}[@$_[0]] : 0;
      my $base2 = exists $data::syndrome_status{$pc{syndrome2}} ? $data::syndrome_status{$pc{syndrome2}}[@$_[0]] : 0;
      $pc{'sttBase'.@$_[1]} = 0;
      $pc{'sttBase'.@$_[1]} += $base1;
      $pc{'sttBase'.@$_[1]} += $pc{syndrome2} ? $base2 : $base1;
    }
  }
  if($ver < 1.24004){
    $pc{history0Exp} -= 130;
    $pc{expSpent} = $pc{expTotal} - 130;
    $pc{createTypeName} = 'フルスクラッチ';
  }
  if($ver < 1.24009){
    foreach my $stt ([0,'Body'], [1,'Sense'], [2,'Mind'], [3,'Social']){
      if($data::syndrome_status{$pc{syndrome1}}){ $pc{'sttSyn1'.@$stt[1]} = $data::syndrome_status{$pc{syndrome1}}[@$stt[0]] }
      if($data::syndrome_status{$pc{syndrome2}}){ $pc{'sttSyn2'.@$stt[1]} = $data::syndrome_status{$pc{syndrome2}}[@$stt[0]] }
    }
  }
  if($ver < 1.24026){
    if($pc{comboCalcOff}){
      $pc{"combo${_}Manual"} = 1 foreach (1 .. $pc{comboNum});
    }
  }
  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}

1;