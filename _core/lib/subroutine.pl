use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン #####################################################################################

### ファイル名取得／パスorアカウント必要時 --------------------------------------------------
sub getfile {
  open (my $FH, '<', $set::passfile) or die;
  while (my $line = <$FH>) {
    if(index($line, "$_[0]<") == 0){ #まずID照会
      close($FH);
      my ($id, $pass, $file, $type) = (split /<>/, $line)[0..3];
      if ( (!$pass) # パス不要
        || (&c_crypt($_[1], $pass)) # パス一致
        || ($pass eq "[$_[2]]") # 編集権アカウント一致
        || ($set::masterkey && $_[1] eq $set::masterkey) # 管理者パス一致
        || ($set::masterid && $_[2] eq $set::masterid) # 管理者アカウント一致
      ) {
        my $user;
        if($pass =~ /^\[(.+?)\]$/){ $user =$1; }
        return ($id, $pass, $file, $type, $user);
      }
      return 0; #ID一致かつパス不一致
    }
  }
  close($FH);
  return 0;
}
### ファイル名取得／パスorアカウント不要時 --------------------------------------------------
sub getfile_open {
  open (my $FH, '<', $set::passfile) or die;
  while (my $line  = <$FH>) {
    if(index($line, "$_[0]<") == 0){
      close($FH);
      my ($id, $pass, $file, $type) = (split /<>/, $line)[0,1,2,3];
      my $user;
      if($pass =~ /^\[(.+?)\]$/){ $file = '_'.$1.'/'.$file; $user = $1; }
      return ($file,$type,$user);
    }
  }
  close($FH);
  return 0;
}


### プレイヤー名取得 --------------------------------------------------
sub getplayername {
  my $in_id = shift;
  open (my $FH, '<', $set::userfile);
  while (my $line = <$FH>) {
    if(index($line, "$in_id<") == 0){
      my ($id, $name, $mail) = (split /<>/, $line)[0,2,3];
      close($FH);
      return ($name,$mail);
    }
  }
  close($FH);
  return '';
}


### 編集保護設定取得 --------------------------------------------------
sub protectTypeGet {
  my $file = shift;
  my $protect   = '';
  my $forbidden = '';
  open (my $IN, '<', $file) or error('キャラクターシートがありません。');
  while (my $line = <$IN>){
    if   ($line =~ /^protect<>(.*)\n/)  { $protect = $1; }
    elsif($line =~ /^forbidden<>(.*)\n/){ $forbidden = $1; }
    
    if($protect && $forbidden){ close($IN); last; }
  }
  close($IN);
  return ($protect, $forbidden);
}

### 暗号化 --------------------------------------------------
sub e_crypt {
  my $plain = shift;
  my $s;
  my @salt = ('0'..'9','A'..'Z','a'..'z','.','/');
  1 while (length($s .= $salt[rand(@salt)]) < 8);
  return crypt($plain,index(crypt('a','$1$a$'),'$1$a$') == 0 ? '$1$'.$s.'$' : $s);
}

sub c_crypt {
  my($plain,$crypt) = @_;
  return ($plain ne '' && $crypt ne '' && crypt($plain,$crypt) eq $crypt);
}

### ログイン --------------------------------------------------
sub log_in {
  if($set::oauth_service){ error("$set::oauth_serviceでのログインのみ有効です"); }
  my $key = key_get($_[0],$_[1]);
  if($key){
    my $flag = 0;
    my $mask = umask 0;
    sysopen (my $FH, $set::login_users, O_RDWR | O_CREAT, 0666);
      flock($FH, 2);
      my @list = <$FH>;
      seek($FH, 0, 0);
      foreach (@list){
        my @line = (split/<>/, $_);
        if (time - $line[2] < 60*60*24*365){
          print $FH $_;
        }
      }
      print $FH "$_[0]<>$key<>".time."<>\n";
      truncate($FH, tell($FH));
    close ($FH);
    print &cookie_set($set::cookie,$_[0],$key,'+365d');
  }
  else { error('ログインできませんでした'); }
  
  if($set::url_home){ print "Location: $set::url_home\n\n"; }
  else { print "Location: ./\n\n"; }
}

### キー取得 --------------------------------------------------
sub key_get {
  my $in_id  = $_[0];
  my $in_pass= $_[1];
  open (my $FH, '<', $set::userfile);
  while (my $line = <$FH>) {
    my ($id, $pass) = (split /<>/, $line)[0,1];
    if ($in_id eq $id && (&c_crypt($in_pass, $pass))) {
      close($FH);
      my $s;
      my @salt = ('0'..'9','A'..'Z','a'..'z','.','/');
      1 while (length($s .= $salt[rand(@salt)] ) < 12);
      return $s;
    }
  }
  close($FH);
  return 0;
}

### ログアウト --------------------------------------------------
sub log_out {
  my ($id, $key) = &cookie_get;
  my $key  = $::in{'key'};
  open (my $FH, '+<', $set::login_users);
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    my @line = (split/<>/, $_);
    if($id eq $line[0] && $key eq $line[1]){
    }
    else {
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
  print &cookie_set($set::cookie,$id,$key,'Thu, 1-Jan-1970 00:00:00 GMT');
  
  if($set::url_home){ print "Location: $set::url_home\n\n"; }
  else { print "Location: ./\n\n"; }
}
### ログインチェック --------------------------------------------------
sub check {
  my ($in_id, $in_key) = &cookie_get;
  return 0 if !$in_id || !$in_key;
  open (my $FH, $set::login_users) or 0;
  while (my $line = <$FH>){
    if(index($line, "$in_id<") == 0){
      my @data = (split/<>/, $line);
      if ($in_key eq $data[1] && time - $data[2] < 86400*365) {
        close($FH);
        return ($in_id);
      }
    }
  }
  close($FH);
  return 0;
}

### Cookieセット --------------------------------------------------
sub cookie_set {
  my $value   = "$_[1]<>$_[2]";
  my $cookie = new CGI::Cookie(
    -name    => $_[0] ,
    -value   => $value ,
    -expires => $_[3] ,
  );
  return ("Set-Cookie: $cookie\n");
}

### Cookieゲット --------------------------------------------------
sub cookie_get {
  my %cookies = fetch CGI::Cookie;
  my $value   = $cookies{$set::cookie}->value if(exists $cookies{$set::cookie});
  my @return = split(/<>/, $value);
  return @return;
}

### ランダムID生成 --------------------------------------------------
sub random_id {
  my @char = (0..9,'a'..'z','A'..'Z');
  my $s;
  1 while (length($s .= $char[rand(@char)]) < $_[0]);
  return $s;
}

### トークンチェック --------------------------------------------------
sub token_check {
  my $in_token = shift;
  my $flag = 0;
  open (my $FH, '+<', $set::tokenfile);
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    my ($token, $time) = (split/<>/, $_);
    if   ($token eq $in_token && $time >= time){ $flag = 1; }
    elsif($time < time) {  }
    else { print $FH $_; }
  }
  truncate($FH, tell($FH));
  close($FH);
  
  return $flag;
}

### メール送信 --------------------------------------------------
sub sendmail {
  my $from    = encode('MIME-Header', "ゆとシートⅡ")." <$set::admimail>";
  my $to      = shift;
  my $subject = encode('MIME-Header', shift);
  my $message = shift;

  $from    =~ s/\r|\n//g;
  $to      =~ s/\r|\n//g;
  $subject =~ s/\r|\n//g;

  open (my $MA, "|$set::sendmail -t") or &error("sendmailの起動に失敗しました。");
  print $MA "To: $to\n";
  print $MA "From: $from\n";
  print $MA "Subject: $subject\n";
  print $MA "Content-Transfer-Encoding: 8bit\n";
  print $MA "Content-Type: text/plain; charset=utf-8\n\n";
  print $MA $message;
  close($MA);
}

### URIエスケープ --------------------------------------------------
sub uri_escape_utf8 {
  my($tmp) = @_;
  $tmp = encode('utf8',$tmp);
  $tmp =~ s/([^\w])/'%'.unpack("H2", $1)/ego;
  $tmp =~ tr/ /+/;
  $tmp = decode('utf8',$tmp);
  return($tmp);
}

### 端数切り上げ --------------------------------------------------
sub ceil {
  my $num = shift;
  my $val = 0;
 
  $val = 1 if($num > 0 and $num != int($num));
  return int($num + $val);
}

### 正の数に+追加 --------------------------------------------------
sub addNum {
  my $num = shift;
  return ($num > 0) ? "+$num" : ($num == 0) ? '' : $num;
}

### 数値3桁区切り --------------------------------------------------
sub commify {
  my $num = shift;
  $num=~s/([0-9]{1,3})(?=(?:[0-9]{3})+(?![0-9]))/$1,/g;
  return $num;
}

### 安全にevalする --------------------------------------------------
sub s_eval {
  my $i = shift;
  $i =~ s/[ 　]//g;
  if($i =~ /[^0-9,\+\-\*\/\%\(\) ]/){ $i = 0; }
  $i =~ s/,([0-9]{3}(?![0-9]))/$1/g;
  return eval($i);
}

### 性別記号変換 --------------------------------------------------
sub genderConvert {
  my $gender = shift;
  my $m_flag; my $f_flag;
  $gender =~ s/^(.+?)[\(（].*?[）\)]$/$1/;
  if($gender =~ /男|♂|雄|オス|爺|漢|(?<!fe)male|(?<!wo)man/i) { $m_flag = 1 }
  if($gender =~ /女|♀|雌|メス|婆|娘|female|woman/i)           { $f_flag = 1 }
  if($m_flag && $f_flag){ $gender = '？' }
  elsif($m_flag){ $gender = '♂' }
  elsif($f_flag){ $gender = '♀' }
  elsif($gender){ $gender = '？' }
  else { $gender = '？' }

  return $gender;
}

### エスケープ --------------------------------------------------
sub pcEscape {
  my $text = shift;
  $text =~ s/&/&amp;/g;
  $text =~ s/"/&quot;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  $text =~ tr/\r\n//d;
  return $text;
}
sub pcTagsEscape {
  my $text = shift;
  $text =~ s/\s/ /g; #空白統一
  $text =~ tr/ / /s; #空白詰める
  $text =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
  $text =~ tr/＋－＊／．，＿/\+\-\*\/\.,_/;
  return $text;
}

### タグ変換 --------------------------------------------------
sub tag_link_url {
  my $url = $_[0];
  my $txt = $_[1];
  #foreach my $safe (@set::safeurl){
  #  next if !$safe;
  #  if($url =~ /^$safe/) { return '<a href="'.$url.'" target="_blank">'.$txt.'</a>'; }
  #}
  if($url =~ /^[#\.\/]/){ return '<a href="'.$url.'">'.$txt.'</a>'; }
  return '<a href="'.$url.'" target="_blank">'.$txt.'</a>';
  #return '<a href="../'.$set::cgi.'?jump='.$url.'" target="_blank">'.$txt.'</a>';
}

sub tag_unescape_lines {
  my $text = $_[0];
  $text =~ s/&lt;br&gt;/\n/gi;
  
  $text =~ s|^//(.*?)$||gm; # コメントアウト
  
  $text =~ s/\\\\\n/<br>/gi;
  
  $text =~ s/^LEFT:/<\/p><p class="left">/gim;
  $text =~ s/^CENTER:/<\/p><p class="center">/gim;
  $text =~ s/^RIGHT:/<\/p><p class="right">/gim;
  
  my $d_count = 0;
  $d_count += ($text =~ s/^\[&gt;\]\*\*\*\*(.*?)$/<\/p><details><summary class="header4">$1<\/summary><div class="detail-body"><p>/gim);
  $d_count += ($text =~ s/^\[&gt;\]\*\*\*(.*?)$/<\/p><details><summary class="header3">$1<\/summary><div class="detail-body"><p>/gim);
  $d_count += ($text =~ s/^\[&gt;\]\*\*(.*?)$/<\/p><details><summary class="header2">$1<\/summary><div class="detail-body"><p>/gim);
  $d_count += ($text =~ s/^\[&gt;\]\*(.*?)$/<\/p><details><summary class="header1">$1<\/summary><div class="detail-body"><p>/gim);
  $d_count += ($text =~ s/^\[&gt;\](.+?)$/<\/p><details><summary>$1<\/summary><div class="detail-body"><p>/gim);
  $d_count += ($text =~ s/^\[&gt;\]$/<\/p><details><summary>詳細<\/summary><div class="detail-body"><p>/gim);
  $d_count -= ($text =~ s/^\[-{3,}\]\n?$/<\/p><\/div><\/details><p>/gim);
  
  $text =~ s/^-{4,}$/<\/p><hr><p>/gim;  
  $text =~ s/^( \*){4,}$/<\/p><hr class="dotted"><p>/gim;
  $text =~ s/^( \-){4,}$/<\/p><hr class="dashed"><p>/gim;
  $text =~ s/^\*\*\*\*(.*?)$/<\/p><h5>$1<\/h5><p>/gim;
  $text =~ s/^\*\*\*(.*?)$/<\/p><h4>$1<\/h4><p>/gim;
  $text =~ s/^\*\*(.*?)$/<\/p><h3>$1<\/h3><p>/gim;
  $text =~ s/\A\*(.*?)$/$main::pc{"head_$_"} = $1; ''/egim;
  $text =~ s/^\*(.*?)$/<\/p><h2>$1<\/h2><p>/gim;
  
  $text =~ s/^\|(.*?)\|$/&tablecall($1)/egim;
  $text =~ s/^\|(.*?)\|c$/&colcall($1)/egim;
  $text =~ s/(<\/tr>|<\/colgroup>)\n/$1/gi;
  $text =~ s/(?!<\/tr>|<table>)(<colgroup>.*?<\/colgroup>)?(<tr>.*?<\/tr>)(?!<tr>|<\/table>)/<\/p><table class="note-table">$1$2<\/table><p>/gi;
  
  $text =~ s/^\:(.*?)\|(.*?)$/<dt>$1<\/dt><dd>$2<\/dd>/gim;
  $text =~ s/(<\/dd>)\n/$1/gi;
  $text =~ s/<\/dd><dt>\s*<\/dt><dd>/&lt;br&gt;/gi;
  $text =~ s/(?!<\/dd>)(<dt>.*?<\/dd>)(?!<dt>)/<\/p><dl class="note-description">$1<\/dl><p>/gi;
  $text =~ s/<dt> *?<\/dt>//gim;

  $text =~ s/\n<\/p>/<\/p>/gi;
  $text =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
  $text =~ s/<p><\/p>//gi;
  $text =~ s/\n/&lt;br&gt;/gi;
  
  while($d_count > 0) {
    $text .= "</div></details>";
    $d_count--;
  }
  
  return $text;
}

sub tablecall {
  my $out = '<tr>';
  my @td = split(/\|/, $_[0]);
  my $col_num;
  foreach(@td){
    $col_num++;
    if($_ eq '&gt;'){ $col_num++; next; }
    
    if($_ =~ /^~/){ $_ =~ s/^~//; $out .= '<th'.($col_num > 1 ? " colspan=\"$col_num\"" : '').'>'.$_.'</th>'; }
    else          {               $out .= '<td'.($col_num > 1 ? " colspan=\"$col_num\"" : '').'>'.$_.'</td>'; }
    $col_num = 0;
  }
  $out .= '</tr>';
  return $out;
}
sub colcall {
  my @out;
  my @col = split(/\|/, $_[0]);
  foreach(@col){
    push (@out, &tablestyle($_));
  }
  return '<colgroup>'.(join '', @out).'</colgroup>';
}
sub tablestyle {
  if($_[0] =~ /([0-9]+)(px|em|\%)/){
    my $num = $1; my $type = $2;
    if   ($type eq 'px' && $num > 300){ $num = 300 }
    elsif($type eq 'em' && $num >  20){ $num =  20 }
    elsif($type eq  '%' && $num > 100){ $num = 100 }
    return "<col style=\"width:calc(${num}${type} + 1em)\">";
  }
  else { return '<col>' }
}
### タグ削除 --------------------------------------------------
sub tag_delete {
  my $text = $_[0];
  $text =~ s/<img alt="&#91;(.)&#93;"/[$1]<img /g;
  $text =~ s/<.+?>//g;
  return $text;
}
sub name_plain {
  my($name, undef) = split(/:/,shift);
  $name =~ s#<rt>.*?</rt>|<rp>.*?</rp>##g;
  return $name;
}

### RGB>HSL --------------------------------------------------
sub rgb_to_hsl {
  my $re = shift || 0;
  my $gr = shift || 0;
  my $bl = shift || 0;
  my $RGB_MAX = 255;
  my $HUE_MAX = 360;
  my $SATURATION_MAX = 100;
  my $LIGHTNESS_MAX = 100;

  my $max = max($re,$gr,$bl);
  my $min = min($re,$gr,$bl);
  my ($hu, $sa, $li);

  # Hue
  my $hp = $HUE_MAX / 6;
  if   ($max == $min) { $hu = 0; }
  elsif ($re == $max) { $hu = $hp * (($gr - $bl) / ($max - $min)); }
  elsif ($gr == $max) { $hu = $hp * (($bl - $re) / ($max - $min)) + $HUE_MAX / 3; }
  else                { $hu = $hp * (($re - $gr) / ($max - $min)) + $HUE_MAX * 2 / 3; }
  if ($hu < 0) { $hu += $HUE_MAX; }

  # Saturation
  my $cnt = ($max + $min) / 2;
  if ($max == $min) { $sa = 0; }
  elsif ($cnt < $RGB_MAX / 2) {
    if ($max + $min <= 0) { $sa = 0; }
    else { $sa = ($max - $min) / ($max + $min) * $SATURATION_MAX; }
  }
  else {
    $sa = ($max - $min) / ($RGB_MAX * 2 - $max - $min) * $SATURATION_MAX;
  }

  # Lightness
  my $li = ($max + $min) / $RGB_MAX / 2 * $LIGHTNESS_MAX;

  return ($hu, $sa, $li);
};

### 進数変換 --------------------------------------------------
sub convert10to36 {
  my $number = shift;
  if(!$number){ return 0;}
  my @work;
  while ($number > 0) {
    unshift @work, substr("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", $number % 36, 1);
    $number = int($number / 36);
  }
  return join('', @work);
}

### チャットパレット --------------------------------------------------
sub palettePresetBuffDelete {
  my $text = shift;
  my %property;
  $_ =~ s|^//(.+?)=(.*?)$|$property{$1} = $2;|egi foreach split("\n",$text);
  my $hit;
  foreach(0 .. 100){
    $hit = 0;
    foreach (keys %property){
      if($text =~ s|\{$_\}|$property{$_}|g){ $hit = 1; }
    }
    last if !$hit
  }
  $text =~ s#^//.+?=.*?(\n|$)##gm;
  $text =~ s/\+0//g;
  $text =~ s/\#0\$//g;
  $text =~ s/^### ■バフ・デバフ\n//g;
  
  return $text;
}

sub palettePropertiesUsedOnly {
  my $palette = shift;
  my $type = shift;
  my %used;
  my @propaties_in = paletteProperties($type);
  my @propaties_out;
  my $hit = 1;
  foreach (0 .. 100){
    $hit = 0;
    foreach my $line (@propaties_in){
      if($line =~ "^//(.+?)="){
        if   ($palette =~ /^\/\/$1=/m){ ; }
        elsif($palette =~ /\{($1)\}/){ $palette .= $line."\n"; $hit = 1 }
      }
    }
    last if !$hit;
  }
  foreach (@propaties_in){
    if($_ =~ "^//(.+?)="){
      if($palette =~ /\{($1)\}/){ push @propaties_out, $_; }
    }
    else {
      push @propaties_out, $_;
    }
  }
  return @propaties_out;
}
### 案内画面 --------------------------------------------------
sub info {
  our $header = shift;
  our $message = shift;
  require $set::lib_info;
  exit;
}

### エラー画面 --------------------------------------------------
sub error {
  our $header = 'エラー';
  our $message = shift;
  require $set::lib_info;
  exit;
}

1;