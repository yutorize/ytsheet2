################## メイキング ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $LOGIN_ID = check;

require $set::data_races;

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

my $now = time;

## 重複チェック
if($set::making_interval){
  open (my $FH, '<', $set::makelist);
  my $file = <$FH>;
  close($FH);
  my ($num, $date, $id, $name, $comment, $race, $stt) = split(/<>/, $file);
  if(
    $now - $date <= $set::making_interval &&
    $LOGIN_ID eq $id &&
    $in{name} eq $name &&
    $in{race} eq $race
  ){
    error($set::making_interval.'秒以内の連続投稿は禁止されています。');
  }
}

## 能力値作成処理
my $adventurer = ($in{race} =~ s/（冒険者）//) ? 1 : 0;

my $stt_data;
my $average_max = 0;
my $i = 1;
while ($i <= $in{repeat} || ($average_max <= $set::average_over)){
  if($adventurer){
    $in{tec} = dice(2);
    $in{phy} = dice(2);
    $in{spi} = dice(2);
  }
  elsif(exists $data::races{$in{race}}{birth}){
    $in{tec} = $data::races{$in{race}}{birth}{tec};
    $in{phy} = $data::races{$in{race}}{birth}{phy};
    $in{spi} = $data::races{$in{race}}{birth}{spi};
  }
  
  my $stt_A = dice($data::races{$in{race}}{dice}{A});
  my $stt_B = dice($data::races{$in{race}}{dice}{B});
  my $stt_C = dice($data::races{$in{race}}{dice}{C});
  my $stt_D = dice($data::races{$in{race}}{dice}{D});
  my $stt_E = dice($data::races{$in{race}}{dice}{E});
  my $stt_F = dice($data::races{$in{race}}{dice}{F});

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

# 書き込み
sysopen (my $FH, $set::makelist, O_RDWR | O_CREAT, 0666);
  flock($FH, 2);
  my @lines = <$FH>;
  seek($FH, 0, 0);
  my $num = (split(/<>/, $lines[0]))[0] + 1;
  if ($set::making_max) { while ($set::making_max <= @lines) { pop(@lines); } }
  unshift(@lines,"$num<>$now<>$LOGIN_ID<>$in{name}<>$in{comment}<>$in{race}<>$stt_data<>$curse<>\n");
  print $FH @lines;
  truncate($FH, tell($FH));
close($FH);

print "Location:./?mode=making&num=${num}\n\n";

sub dice {
  my $loop = shift;
  my $num = 0;
  foreach (1..$loop){
    $num += int(rand(6)) + 1;
  }
  return $num;
}