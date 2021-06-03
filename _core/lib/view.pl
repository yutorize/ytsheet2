################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

our $LOGIN_ID = check;

our $file;
my $type;
our %conv_data = ();

if($::in{'id'}){
  ($file, $type) = getfile_open($::in{'id'});
}
elsif($::in{'url'}){
  require $set::lib_convert;
  %conv_data = data_convert($::in{'url'});
  $type = $conv_data{'type'};
}

### 各システム別処理 --------------------------------------------------
if   ($type eq 'm'){ require $set::lib_view_mons; }
elsif($type eq 'i'){ require $set::lib_view_item; }
else               { require $set::lib_view_char; }


### データ取得 --------------------------------------------------
sub pcDataGet {
  my %pc;
  if($::in{'id'}){
    my $datadir = ($type eq 'm') ? $set::mons_dir : ($type eq 'i') ? $set::item_dir : $set::char_dir;
    my $datafile = $::in{'backup'} ? "${datadir}${file}/backup/$::in{'backup'}.cgi" : "${datadir}${file}/data.cgi";
    open my $IN, '<', $datafile or error 'データがありません。';
    $_ =~ s/^(.+?)<>(.*)\n$/$pc{$1} = $2;/egi while <$IN>;
    close($IN);
    if($::in{'backup'}){
      ($pc{'protect'}, $pc{'forbidden'}) = protectTypeGet("${datadir}${file}/data.cgi");
      $pc{'backupId'} = $::in{'backup'};
    }
  }
  elsif($::in{'url'}){
    %pc = %conv_data;
    if(!$conv_data{'ver'}){
      require (($type eq 'm') ? $set::lib_calc_mons : ($type eq 'i') ? $set::lib_calc_item : $set::lib_calc_char);
      %pc = data_calc(\%pc);
    }
  }
  return %pc;
}


### 伏せ文字 --------------------------------------------------
sub noiseText {
  my $min = shift;
  my $max = shift || $min;
  my $length = $min + (int rand($max - $min + 1));
  my @seed = split(//, '██████████▇▆▅▄▃▂▚▞▙▛▜▟');
  my $text;
  foreach (1 .. $length) {
    $text .= @seed[int rand(scalar @seed)];
  }
  return $text;
}
sub noiseTextTag {
  my $text = shift;
  $text =~ s/<br>/\n/g;
  $text =~ s/^[██████████▇▆▅▄▃▂▚▞▙▛▜▟\n\s]+$/<span class="censored">$&<\/span>/s;
  $text =~ s/\n/<br>/g;
  return $text;
}

1;