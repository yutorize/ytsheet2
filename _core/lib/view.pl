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

$::in{log} ||= $::in{backup};

if($::in{id}){
  ($file, $type, $author) = getfile_open($::in{id});
}
elsif($::in{url}){
  require $set::lib_convert;
  %conv_data = dataConvert($::in{url});
  $type = $conv_data{type};
}

changeFileByType($type);


### 各システム別処理 --------------------------------------------------
require $set::lib_view_char;


### データ取得 --------------------------------------------------
sub getSheetData {
  my %pc;
  my $datadir = $set::char_dir;
  ## データ読み込み
  if($::in{id}){
    my $datatype = ($::in{log}) ? 'logs' : 'data';
    my $hit = 0;
    open my $IN, '<', "${datadir}${file}/${datatype}.cgi" or viewNotFound($datadir);
    while (<$IN>){
      if($datatype eq 'logs'){
        if (index($_, "=") == 0){
          if (index($_, "=$::in{log}=") == 0){ $hit = 1; next; }
          if ($hit){ last; }
        }
        if (!$hit) { next; }
      }
      chomp $_;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value if $value ne '';
    }
    close($IN);
    if($datatype eq 'logs' && !$hit){ error("過去ログ（$::in{log}）が見つかりません。"); }

    if($::in{log}){
      ($pc{protect}, $pc{forbidden}) = getProtectType("${datadir}${file}/data.cgi");
      $pc{logId} = $::in{log};
    }
  }
  ## データ読み込み：コンバート
  elsif($::in{url}){
    %pc = %conv_data;
    if(!$conv_data{ver}){
      require $set::lib_calc_char;
      %pc = data_calc(\%pc);
    }
  }

  ##
  elsif(exists $set::lib_type{$type}){ $pc{sheetType} = $set::lib_type{$type}{sheetType}; }
  else { $pc{sheetType} = 'chara'; }

  if(!$::in{checkView} && (
    ($pc{protect} eq 'none') || 
    ($author && ($author eq $LOGIN_ID || $set::masterid eq $LOGIN_ID))
  )){
    $pc{yourAuthor} = 1;
  }
  if(!$pc{protect} || $pc{protect} eq 'password'){
    $pc{reqdPassword} = 1;
  }

  if($::in{mode} eq 'download'){
    $pc{modeDownload} = 1;
  }
  
  ## キャラクター画像
  if($pc{image}){
    if($pc{convertSource}) {
      $pc{imageSrc} = $pc{imageURL};
    }
    else {
      $pc{imageSrc} =     "./?id=$::in{id}&mode=image&cache=$pc{imageUpdate}";
      $pc{imageURL} = url()."?id=$::in{id}&mode=image&cache=$pc{imageUpdate}";
    }
    $pc{images} = "'1': \"".($pc{modeDownload} ? urlToBase64("${datadir}${file}/image.$pc{image}") : $pc{imageSrc})."\", ";
    
    if($pc{imageFit} eq 'percentY'){
      $pc{imageFit} = 'auto '.$pc{imagePercent}.'%';
    }
    elsif($pc{imageFit} =~ /^percentX?$/){
      $pc{imageFit} = $pc{imagePercent}.'%';
    }
    
    ## 権利表記
    if($pc{imageCopyrightURL}){
      $pc{imageCopyright} = "<a href=\"$pc{imageCopyrightURL}\" target=\"_blank\">".(unescapeTags($pc{imageCopyright})||$pc{imageCopyrightURL})."</a>";
    }
    else { $pc{imageCopyright} = unescapeTags($pc{imageCopyright}) }
  }

  ## 

  return %pc;
}

sub viewNotFound { #v1.14/v1.20のコンバート処理
  my $dir = shift;
  if(!$::in{log} && $file =~ /^(.+)\/(.+?)$/){
    my $user = $1;
    my $file = $2;
    if(-d "${dir}${file}"){
      if(!-d "${dir}${user}"){ mkdir "${dir}${user}" or error("データディレクトリの作成に失敗しました。"); }
      rename("${dir}${file}", "${dir}${user}/${file}");
      print "Location:./?id=$::in{id}\n\n";
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
      $selected = (!$::in{log} ? 1 : 0);
      $text     = ($name ? "<b>$name</b>":'') . '最新: ' .epocToDate($epoc);
    }
    else {
      (my $dateview = $date) =~ s/(\d{4}-\d{2}-\d{2})-(\d{2})-(\d{2})/$1 $2:$3/g;
      $selected = ($date eq $::in{log} ? 1 : 0);
      $query    = "&log=$date";
      $text     = ($name ? "<b>$name</b>":'') .epocToDate($epoc);
    }
    push(@logs, { "SELECTED"  => ($selected ? 'selected' : ''), "URL"  => $query, "DATE" => $text });
    if($selected){ $selectedname = $name }
  }
  return $selectedname, \@logs;
}
### カラー出力 --------------------------------------------------
sub setColors {
  my $type = shift;
  setDefaultColors($type);
  $::pc{$type.'colorBaseBgS'} = $::pc{$type.'colorBaseBgS'} * 0.7;
  $::pc{$type.'colorBaseBgL'} = 100 - $::pc{$type.'colorBaseBgS'} / 6;
  $::pc{$type.'colorBaseBgD'} = 15;
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
sub isNoiseText {
  my $text = shift;
  return $text =~ /^[█▇▆▅▄▃▂▚▞▙▛▜▟\n\s]+$/ ? 1 : undef;
}
### キャラクター名 --------------------------------------------------
sub stylizeCharacterName {
  my $name = shift;
  my $ruby = shift;
  $name = insertWbr($name);
  if($ruby) {
    return "<ruby><rp>｜</rp>${name}<rp>《</rp><rt>${ruby}</rt><rp>》</rp></ruby>"
  }
  return $name;
}
### <wbr>挿入 --------------------------------------------------
sub insertWbr { #固有名詞向け
  my $name = shift;
  $name =~ s#[･・＝／”＞]#$&<wbr>#g;
  $name =~ s#[+＋*＊@＠“＜]#<wbr>$&#g;
  return $name;
}
### セリフ --------------------------------------------------
sub stylizeWords {
  my ($words, $x, $y) = @_;
  $words =~ s/<br>/\n/g;
  $words =~ s/“/〝/g;
  $words =~ s/”/〟/g;
  $words =~ s/^([「『（〝])/<span class="brackets">$1<\/span>/gm;
  $words =~ s/(.+?(?:[，、。？」』）〟]|$))/<span>$1<\/span>/g;
  $words =~ s/\n<span>　/\n<span>/g;
  $words =~ s/\n/<br>/g;
  $x = $x eq '左' ? 'left:0;' : 'right:0;';
  $y = $y eq '下' ? 'bottom:0;' : 'top:0;';
  return $words, $x, $y;
}
### セッション履歴 --------------------------------------------------
# 数字列を成形する
sub formatHistoryFigures {
  my $text = shift;
  $text =~ s/[0-9]+/commify($&);/ge;
  $text =~ s#[0-9,]+#<span class="number">$&</span><wbr>#g;
  return $text;
}
### メニュー --------------------------------------------------
sub sheetMenuCreate {
  my @menu = @_;
  foreach my $line (@menu){
    if   (length($line->{TEXT}) >= 4){ $line->{TEXT} = "<span>$line->{TEXT}</span>" }
    elsif(length($line->{TEXT}) >= 5){ $line->{TEXT} = "<span>$line->{TEXT}</span>" }
  }
  return \@menu;
}
### ダウンロード用 --------------------------------------------------
sub downloadModeSheetConvert {
  my $sheet = shift;
  $sheet =~ s#<link rel="stylesheet" data-dl href="(.+?)(\?.+?)?">#"<style>\n".styleToHtml($1)."\n</style>"#gie;
  $sheet =~ s#<script data-dl src="(.+?)(\?.+?)?"></script>#"<script>\n".styleToHtml($1)."\n</script>"#gie;
  return $sheet;
}
sub styleToHtml {
  my $output;
  open(my $FH, '<', $_[0]);
  $output .= $_ foreach <$FH>;
  close($FH);
  
  (my $dir = $_[0]) =~ s#/[^/]+?$##;
  $output =~ s/url\((.+?\.png|jpg|gif|webp)\)/"url(".urlToBase64("$dir\/$1").")"/gie;
  return "$output";
}
use MIME::Base64;
sub urlToBase64 {
  my $url = shift;
  my $ext = shift;
  $url =~ s#\?.*?$##;
  if(!$ext){
    ($ext = $url) =~ s/^.+\.(png|jpg|gif|webp)$/$1/;
    if ($ext eq "jpg") { $ext ="jpeg"; }
  }
  open(my $IMG, '<', "$url");
  binmode $IMG;
  my $binary; my $buffer;
  while(read($IMG, $buffer, 2048)) { $binary .= $buffer }
  close($IMG);
  my $base64 = encode_base64($binary, '');
  return "data:image/$ext;base64,$base64";
}

1;