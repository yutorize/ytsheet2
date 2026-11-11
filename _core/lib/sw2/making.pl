################## メイキング ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $LOGIN_ID = check;

require $set::data_races;
require $::core_dir . '/lib/sw2/making-log.pl';

error('名前が未入力です') if !$::in{name};
error('種族が未選択です') if !$::in{race};

my %in;

foreach(param()){
  $in{$_} = decode('utf8', param($_));
  $in{$_} =~ s/\&/&amp;/g;
  $in{$_} =~ s/</&lt;/g;
  $in{$_} =~ s/>/&gt;/g;
  $in{$_} =~ s/\r\n?|\n/<br>/g;
}

## 能力値作成処理
my $adventurer = ($in{race} =~ s/（冒険者）//) ? 1 : 0;

my $stt_data;
my $average_max = 0;
my $i = 1;
while ($i <= $in{repeat} || ($average_max <= $set::average_over)){
  if($adventurer){
    $in{tec} = rollMakingDice(2);
    $in{phy} = rollMakingDice(2);
    $in{spi} = rollMakingDice(2);
  }
  elsif(exists $data::races{$in{race}}{birth}){
    $in{tec} = $data::races{$in{race}}{birth}{tec};
    $in{phy} = $data::races{$in{race}}{birth}{phy};
    $in{spi} = $data::races{$in{race}}{birth}{spi};
  }
  
  my $stt_A = rollMakingDice($data::races{$in{race}}{dice}{A});
  my $stt_B = rollMakingDice($data::races{$in{race}}{dice}{B});
  my $stt_C = rollMakingDice($data::races{$in{race}}{dice}{C});
  my $stt_D = rollMakingDice($data::races{$in{race}}{dice}{D});
  my $stt_E = rollMakingDice($data::races{$in{race}}{dice}{E});
  my $stt_F = rollMakingDice($data::races{$in{race}}{dice}{F});

  my $dicetotal  = $data::races{$in{race}}{dice}{A}
                 + $data::races{$in{race}}{dice}{B}
                 + $data::races{$in{race}}{dice}{C}
                 + $data::races{$in{race}}{dice}{D}
                 + $data::races{$in{race}}{dice}{E}
                 + $data::races{$in{race}}{dice}{F};
                 
  $stt_data .= "$in{tec},$in{phy},$in{spi},$stt_A,$stt_B,$stt_C,$stt_D,$stt_E,$stt_F,/";

  my $average = ($stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F) / $dicetotal;
     $average = ($stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F + $in{tec} + $in{phy} + $in{spi}) / 18 if $adventurer;
  $average_max = $average if $average > $average_max;
  
  last if $set::adventurer_onlyonce && $adventurer;
  $i++;
}

$in{race} .= '（冒険者）' if $adventurer;

my $curse;
if($in{race} eq 'アビスボーン'){
  my @array = keys %set::curseList;
  my $max = @array;
  $curse .= $array[int(rand $max)].'/' foreach(1..3);
}

## 書き込み
my $num = eval {
  YtSheet::MakingLog->newMakingLog(
    file => $set::makelist,
    keep => $set::making_archive_keep,
    unit => $set::making_archive_unit,
    max  => $set::making_max,
  )->saveMakingPost(
    id => $LOGIN_ID, name => $in{name}, comment => $in{comment},
    race => $in{race}, stt => $stt_data, curse => $curse,
    interval => $set::making_interval,
  );
};
error($@) if $@;

print "Location:./?mode=making&num=${num}\n\n";

sub rollMakingDice {
  my $loop = shift;
  my $num = 0;
  foreach (1..$loop){
    $num += int(rand(6)) + 1;
  }
  return $num;
}