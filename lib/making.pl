################## メイキング ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $LOGIN_ID = check;

require $set::data_races;

error('名前が未入力です') if !param('name');
error('種族が未選択です') if !param('race');

my %in;

foreach(param()){
  $in{$_} = Encode::decode('utf8', param($_));
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
    $in{'name'} eq $name &&
    $in{'race'} eq $race
  ){
    error($set::making_interval.'秒以内の連続投稿は禁止されています。');
  }
}

## 能力値作成処理
my $adventurer = ($in{'race'} =~ s/（冒険者）//) ? 1 : 0;

my $stt_data;
my $average_max = 0;
my $i = 1;
while ($i <= $in{"repeat"} || ($average_max <= $set::average_over)){
  if($adventurer){
    $in{'tec'} = dice(2);
    $in{'phy'} = dice(2);
    $in{'spi'} = dice(2);
  }
  
  my $stt_A = dice($data::race_dices{$in{'race'}}{'A'});
  my $stt_B = dice($data::race_dices{$in{'race'}}{'B'});
  my $stt_C = dice($data::race_dices{$in{'race'}}{'C'});
  my $stt_D = dice($data::race_dices{$in{'race'}}{'D'});
  my $stt_E = dice($data::race_dices{$in{'race'}}{'E'});
  my $stt_F = dice($data::race_dices{$in{'race'}}{'F'});

  my $dicetotal  = $data::race_dices{$in{'race'}}{'A'}
                 + $data::race_dices{$in{'race'}}{'B'}
                 + $data::race_dices{$in{'race'}}{'C'}
                 + $data::race_dices{$in{'race'}}{'D'}
                 + $data::race_dices{$in{'race'}}{'E'}
                 + $data::race_dices{$in{'race'}}{'F'};
                 
  $stt_data .= "$in{'tec'},$in{'phy'},$in{'spi'},$stt_A,$stt_B,$stt_C,$stt_D,$stt_E,$stt_F,/";

  my $average = ($stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F) / $dicetotal;
     $average = ($stt_A + $stt_B + $stt_C + $stt_D + $stt_E + $stt_F + $in{'tec'} + $in{'phy'} + $in{'spi'}) / 18 if $adventurer;
  $average_max = $average if $average > $average_max;
  
  last if $set::adventurer_onlyonce && $adventurer;
  $i++;
}

$in{'race'} .= '（冒険者）' if $adventurer;

# 書き込み
sysopen (my $FH, $set::makelist, O_RDWR | O_CREAT, 0666);
  my @lines = <$FH>;
  flock($FH, 2);
  seek($FH, 0, 0);
  my $num = (split(/<>/, $lines[0]))[0] + 1;
  if ($set::making_max) { while ($set::making_max <= @lines) { pop(@lines); } }
  unshift(@lines,"$num<>$now<>$LOGIN_ID<>$in{'name'}<>$in{'comment'}<>$in{'race'}<>$stt_data<><>\n");
  print $FH @lines;
  truncate($FH, tell($FH));
close($FH);

print "Location:./?mode=making\n\n";

sub dice {
  my $loop = shift;
  my $num = 0;
  foreach (1..$loop){
    $num += int(rand(6)) + 1;
  }
  return $num;
}