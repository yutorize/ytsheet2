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

$::in{'log'} ||= $::in{'backup'};

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
  ## データ読み込み
  if($::in{'id'}){
    my $datadir = ($type eq 'm') ? $set::mons_dir : ($type eq 'i') ? $set::item_dir : $set::char_dir;

    my $datatype = ($::in{'log'}) ? 'logs' : 'data';
    my $hit = 0;
    open my $IN, '<', "${datadir}${file}/${datatype}.cgi" or viewNotFound($datadir);
    while (<$IN>){
      if($datatype eq 'logs'){
        if (index($_, "=") == 0){
          if (index($_, "=$::in{'log'}=") == 0){ $hit = 1; next; }
          if ($hit){ last; }
        }
        if (!$hit) { next; }
      }
      chomp $_;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }
    close($IN);
    if($datatype eq 'logs' && !$hit){ error("過去ログ（$::in{'log'}）が見つかりません。"); }

    if($::in{'log'}){
      ($pc{'protect'}, $pc{'forbidden'}) = protectTypeGet("${datadir}${file}/data.cgi");
      $pc{'logId'} = $::in{'log'};
    }
  }
  ## データ読み込み：コンバート
  elsif($::in{'url'}){
    %pc = %conv_data;
    if(!$conv_data{'ver'}){
      require (($type eq 'm') ? $set::lib_calc_mons : ($type eq 'i') ? $set::lib_calc_item : $set::lib_calc_char);
      %pc = data_calc(\%pc);
    }
  }
  ##
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
  if(!$::in{'log'} && $file =~ /^(.+)\/(.+?)$/){
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
sub getLogList {
  my $dir  = shift;
  my $file = shift;
  open(my $FH,"${dir}${file}/log-list.cgi") || logFileCheck("${dir}${file}",'view');
  my @lines = reverse <$FH>;
  close($FH);
  my @logs; my $selectedname;
  foreach (@lines){
    chomp;
    my ($date, $epoc, $name) = split('<>', $_, 3);
    
    my ($selected, $query, $text);
    if($date eq 'latest'){
      $selected = (!$::in{'log'} ? 1 : 0);
      $text     = ($name ? "<b>$name</b>":'') . '最新: ' .epocToDate($epoc);
    }
    else {
      (my $dateview = $date) =~ s/(\d{4}-\d{2}-\d{2})-(\d{2})-(\d{2})/$1 $2:$3/g;
      $selected = ($date eq $::in{'log'} ? 1 : 0);
      $query    = "&log=$date";
      $text     = ($name ? "<b>$name</b>":'') .epocToDate($epoc);
    }
    push(@logs, { "SELECTED"  => ($selected ? 'selected' : ''), "URL"  => $query, "DATE" => $text });
    if($selected){ $selectedname = $name }
  }
  return $selectedname, \@logs;
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