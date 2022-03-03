################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

our $LOGIN_ID = check;

our $file;
my $type;
my $author;
our %conv_data = ();

if($::in{'id'}){
  ($file, $type, $author) = getfile_open($::in{'id'});
}
elsif($::in{'url'}){
  require $set::lib_convert;
  %conv_data = dataConvert($::in{'url'});
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
    open my $IN, '<', $datafile or viewNotFound($datadir);
    while (<$IN>){
      chomp;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }
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
  if(!$::in{'checkView'} && (
    ($pc{'protect'} eq 'none') || 
    ($author && ($author eq $LOGIN_ID || $set::masterid eq $LOGIN_ID))
  )){
    $pc{'yourAuthor'} = 1;
  }
  if(!$pc{'protect'} || $pc{'protect'} eq 'password'){
    $pc{'reqdPassword'} = 1;
  }
  return %pc;
}

sub viewNotFound { #v1.14のコンバート処理
  my $dir = shift;
  if(!$::in{'backup'} && $file =~ /^(.+)\/(.+?)$/){
    my $user = $1;
    my $file = $2;
    if(-d "${dir}${file}"){
      if(!-d "${dir}${user}"){ mkdir "${dir}${user}" or error("データディレクトリの作成に失敗しました。"); }
      rename("${dir}${file}", "${dir}${user}/${file}");
      print "Location:./?id=$::in{'id'}\n\n";
      exit;
    }
  }
  
  error('データがありません');
}

### バックアップ一覧 --------------------------------------------------
sub getBackupList {
  my $dir  = shift;
  my $file = shift;
  opendir(my $DIR,"${dir}${file}/backup");
  my @backlist = readdir($DIR);
  closedir($DIR);
  my %backname;
  open(my $FH,"${dir}${file}/buname.cgi");
  foreach(<$FH>){
    chomp;
    my @data = split('<>', $_, 2);
    $backname{$data[0]} = $data[1];
  }
  close($FH);
  my @backup; my $selectedname;
  foreach my $date (reverse sort @backlist) {
    if ($date =~ s/\.cgi//) {
      my $url = $date;
      my $selected = ($url eq $::in{'backup'} ? 1 : 0);
      $date =~ s/^([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})-([0-9]{2})$/$1 $2\:$3/;
      push(@backup, {
        "NOW"  => $selected,
        "URL"  => $url,
        "DATE" => ($backname{$url} ? "<b>$backname{$url}</b>":'') . $date,
      });
      if($selected){ $selectedname = $backname{$url}; }
    }
  }
  return $selectedname, \@backup;
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
  $text =~ s/^[█▇▆▅▄▃▂▚▞▙▛▜▟\n\s]+$/<span class="censored">$&<\/span>/s;
  $text =~ s/\n/<br>/g;
  return $text;
}

1;