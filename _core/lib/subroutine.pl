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
      else { $file = 'anonymous/'.$file; }
      return ($file,$type,$user);
    }
  }
  close($FH);
  return 0;
}
### typeによって各ファイル・ディレクトリを変更 --------------------------------------------------
sub changeFileByType {
  my $type = shift;
  if($type && exists $set::lib_type{$type}){
    return if exists $set::lib_type{chara};
    $set::lib_type{chara}{listFile} = $set::listfile;
    $set::lib_type{chara}{dataDir}  = $set::char_dir;
    $set::lib_type{chara}{edit}     = $set::lib_edit_char;
    $set::lib_type{chara}{calc}     = $set::lib_calc_char;
    $set::lib_type{chara}{view}     = $set::lib_view_char;
    $set::lib_type{chara}{list}     = $set::lib_list_char;
    $set::lib_type{chara}{skin}     = $set::skin_sheet;

    $set::listfile      = $set::lib_type{$type}{listFile};
    $set::char_dir      = $set::lib_type{$type}{dataDir};
    $set::lib_edit_char = $set::lib_type{$type}{edit};
    $set::lib_calc_char = $set::lib_type{$type}{calc};
    $set::lib_view_char = $set::lib_type{$type}{view};
    $set::lib_list_char = $set::lib_type{$type}{list};
    $set::skin_sheet    = $set::lib_type{$type}{skin};
  }
}

### 画像リダイレクト --------------------------------------------------
sub redirectToImage {
  my $id   = shift;
  my $type = shift;
  my ($file,$type,$user) = getfile_open($id);
  changeFileByType($type);
  my $datadir = $set::char_dir;
  my $ext;

  if(!$file){ error("ファイルがありません。") }

  open(my $DATA, "./${datadir}/${file}/data.cgi") or die("file open error: $id:$file,$type // $!");
  while(<$DATA>){
    if($_ =~ /^image<>(.*?)\n/){ $ext = $1; last }
  }
  close($DATA);

  if(!$ext){ error("画像がありません。") }

  open(my $IMG, "./${datadir}/${file}/image.${ext}") or die("image open error: $id:$file,$type // $!");
  binmode $IMG;
  binmode STDOUT;
  print "Content-type: image/".($ext eq 'jpg' ? 'jpeg' : $ext)."\n";
  print "Cache-Control: public, max-age=604800\n";
  print "Content-Disposition: inline; filename=\"ytsheet_$::in{id}.$ext\"\n";
  print "\n";
  print while (<$IMG>);
  close($IMG);
  exit;
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
sub getProtectType {
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
  my $key = getKey($_[0],$_[1]);
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
sub getKey {
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
  my $key  = $::in{key};
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

### 正の数に+追加/0なら空 --------------------------------------------------
sub addNum {
  my $num = shift;
  return ($num > 0) ? "+$num" : ($num == 0) ? '' : $num;
}

### 算術演算子の連続を最適化 --------------------------------------------------
sub optimizeOperator {
  my $text = shift;
  $text =~ s/\+\++/\+/g;
  $text =~ s/\+-/-/g;
  $text =~ s/-\+/-/g;
  return $text;
}
sub optimizeOperatorFirst {
  my $text = shift;
  $text =~ s/^\+\++/\+/;
  $text =~ s/^\+-/-/;
  $text =~ s/^-\+/-/;
  return $text;
}
### 数値3桁区切り --------------------------------------------------
sub commify {
  my $num = shift;
  $num=~s/([0-9]{1,3})(?=(?:[0-9]{3})+(?![0-9]))/$1,/g;
  return $num;
}


### エポック秒 => 年-月-日 時:分 --------------------------------------------------
sub epocToDate {
  my ($min, $hour, $day, $mon, $year) = (localtime(shift))[1..5];
  return sprintf("%04d-%02d-%02d %02d:%02d",$year+1900,$mon+1,$day,$hour,$min);
}
sub epocToDateQuery {
  my ($sec, $min, $hour, $day, $mon, $year) = (localtime(shift))[0..5];
  return sprintf("%04d-%02d-%02d-%02d-%02d-%02d",$year+1900,$mon+1,$day,$hour,$min, $sec);
}

### 安全にevalする --------------------------------------------------
sub s_eval {
  my $i = shift;
  $i =~ s/[ 　]//g;
  if($i =~ /[^0-9,\+\-\*\/\%\(\) ]/){ $i = 0; }
  $i =~ s/,([0-9]{3}(?![0-9]))/$1/g;
  return eval($i);
}

### グループ設定の変換 --------------------------------------------------
sub groupArrayToHash {
  my @array = $_[0] ? @{$_[0]} : @set::groups;
  my %hash;
  foreach (@array){
    $hash{@$_[0]} = {
      "sort" => @$_[1],
      "name" => @$_[2],
      "text" => @$_[3],
    };
  }
  return %hash;
}
sub groupArrayToList {
  my $selected = $_[0];
  my @array = $_[1] ? @{$_[1]} : @set::groups;
  my @list;
  foreach (sort { $a->[1] cmp $b->[1] } @array){
    push(@list, {
      "ID" => @$_[0],
      "NAME" => @$_[2],
      "TEXT" => @$_[3],
      "SELECTED" => $selected eq @$_[0] ? 'selected' : '',
    });
  }
  return \@list;
}

### 性別記号変換 --------------------------------------------------
sub stylizeGender {
  my $gender = shift;
  my $m_flag; my $f_flag; my $n_flag;
  $gender =~ s/^(.+?)[\(（].*?[）\)]$/$1/;
  $gender =~ tr/Ａ-Ｚａ-ｚ/A-Za-z/;
  if($gender =~ /男|おとこ|オトコ|♂|雄|オス|爺|漢|(?<!fe)m(ale|$)|(?<!wo)man/i) { $m_flag = 1 }
  if($gender =~ /女|おんな|オンナ|♀|雌|メス|婆|娘|f(em(ale)?|$)|woman/i)       { $f_flag = 1 }
  if($gender =~ /無|なし|^[\-ー‐‑–—―−ｰ]$|non/i)               { $n_flag = 1 }
  if($gender =~ /両|半|トランス|ノンバ|non|Ft[MX]|Mt[FX]|^[XA]/i) { $m_flag = 1; $f_flag = 1 }

  if   ($n_flag){ $gender = '<span data-gender="none">―</span>' }
  elsif($m_flag && $f_flag){ $gender = '<span data-gender="cross">⚧</span>' }
  elsif($m_flag){ $gender = '<span data-gender="male">♂</span>' }
  elsif($f_flag){ $gender = '<span data-gender="female">♀</span>' }
  else { $gender = '<span data-gender="unknown">？</span>' }

  return $gender;
}

### 年齢変換 --------------------------------------------------
sub stylizeAge {
  my $age = shift;
  $age =~ s/^(.+?)[\(（].*?[）\)]$/$1/;
  $age =~ tr/０-９/0-9/;
  if($age =~ /[0-9]$/){ $age .= '歳'; }
  $age =~ s/([^0-9]+)/<span class="small">$1<\/span>/g;
  return $age;
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
sub normalizeHashtags {
  my $text = shift;
  $text =~ s/\s/ /g; #空白統一
  $text =~ tr/ / /s; #空白詰める
  $text =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
  $text =~ tr/＋－＊／．，＿/\+\-\*\/\.,_/;
  return $text;
}
sub escapeThanSign {
  my $text = shift;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  return $text;
}

### タグ変換 --------------------------------------------------
sub unescapeTags {
  my $text = shift;
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  #$text =~ s/\{\{([0-9\+\-\*\/\%\(\) ]+?)\}\}/s_eval($1);/eg;
  
  $text =~ s#(―+)#<span class="d-dash">$1</span>#g;
  
  $text =~ s{©}{<i class="s-icon copyright">©</i>}gi;

  if($set::game eq 'sw2'){
    if($::in{mode} ne 'download'){
      $text =~ s/\[魔\]/<img alt="&#91;魔&#93;" class="i-icon" src="${set::icon_dir}wp_magic.png">/gi;
      $text =~ s/\[刃\]/<img alt="&#91;刃&#93;" class="i-icon" src="${set::icon_dir}wp_edge.png">/gi;
      $text =~ s/\[打\]/<img alt="&#91;打&#93;" class="i-icon" src="${set::icon_dir}wp_blow.png">/gi;
    }
    else {
      $text =~ s|\[魔\]|<img alt="&#91;魔&#93;" class="i-icon" src="data:image/webp;base64,UklGRqwAAABXRUJQVlA4TJ8AAAAvD8ADED9AqIGhhP5FvFQxEa6LmgCEILtJBvnkvBhvESIBCHf8jwZ44QAfzH8IQD8sZ2K6bB8tgeNGktymAZLSmz6E/R5A9z5wI6BJQfzavcsfUBAR/U/AwRmBrkMMOtVnMZxWXvYvc5Vfi8Gc57JPOM2vxTRxVS5767suXovlPnGH7G2uCU+wPO/h+bW57+GIwWvCGbqoHZxfuo7/BAAA">|gi;
      $text =~ s|\[刃\]|<img alt="&#91;刃&#93;" class="i-icon" src="data:image/webp;base64,UklGRmgAAABXRUJQVlA4TFwAAAAvD8ADECcgECD8r1ix5EMgQOhXpkaDgrQNmPq33J35D8B/Cs4KriLZDZv9EAIHgs2gAiCNzR+VyiGi/wGIWX8565unQe15VkDtBrkCr3ZDnhVQt41fgHwX6nojAA==">|gi;
      $text =~ s|\[打\]|<img alt="&#91;打&#93;" class="i-icon" src="data:image/webp;base64,UklGRnAAAABXRUJQVlA4TGMAAAAvD8ADEB+gkG0EODSdId0jEEgC2V9sEQVpG7C49roz/wF8ppPAprb2Ji8JxUO38jthZ84eCzQJHTURgQSmbiOi/4GE4Cs4f8Xxx4x/SfOVNJdDdkez1dghIZdQYvAKLJADIQAA">|gi;
    }
    if($::SW2_0){
      $text =~ s/(\[[常主補宣条選]\])+/&textToIcon($&);/egi;
      $text =~ s/「((?:[○◯〇＞▶〆☆≫»□☐☑🗨▽▼]|&gt;&gt;)+)/"「".&textToIcon($1);/egi;
    } else {
      $text =~ s/(\[[常準主補宣]\])+/&textToIcon($&);/egi;
      $text =~ s/「((?:[○◯〇△＞▶〆☆≫»□☐☑🗨]|&gt;&gt;)+)/"「".&textToIcon($1);/egi;
    }
  }
  
  
  our @linkPlaceholders;
  $text =~ s/((?:making|能力値作成(?:履歴)?)#([0-9]+(?:-[0-9]+)?))/ &generateLinkTag("?&mode=making&num=$2",$1) /egi if($set::game eq 'sw2'); # メイキングリンク
  $text =~ s/\[\[(.+?)&gt;((?:(?!<br>)[^"])+?)\]\]/ &generateLinkTag($2,$1) /egi; # リンク
  $text =~ s/\[(.+?)#([a-zA-Z0-9\-]+?)\]/ &generateLinkTag("?id=$2",$1) /egi; # シート内リンク
  $text =~ s/(https?:\/\/[^\s\<]+)/ &generateLinkTag($1,$1) /egi; # 自動リンク
  
  $text =~ s/'''(.+?)'''/<span class="oblique">$1<\/span>/gi; # 斜体
  $text =~ s/''(.+?)''/<b>$1<\/b>/gi;  # 太字
  $text =~ s/%%(.+?)%%/<span class="strike">$1<\/span>/gi;  # 打ち消し線
  $text =~ s/__(.+?)__/<span class="underline">$1<\/span>/gi;  # 下線
  $text =~ s/\{\{(.+?)\}\}/<span style="color:transparent">$1<\/span>/gi;  # 透明
  $text =~ s/[|｜]([^|｜\n]+?)《(.+?)》/<ruby><rp>｜<\/rp>$1<rp>《<\/rp><rt>$2<\/rt><rp>》<\/rp><\/ruby>/gi; # なろう式ルビ
  $text =~ s/《《(.+?)》》/<span class="text-em">$1<\/span>/gi; # カクヨム式傍点

  $text =~ s/\x{FFFC}(\d+)\x{FFFC}/$linkPlaceholders[$1-1]/g; # リンク後処理
  
  $text =~ s/\n/<br>/gi;

  if($set::game eq 'sw2'){
  }
  
  return $text;
  
  sub generateLinkTag {
    my $url = shift;
    my $txt = shift;
    $txt =~ s{<a .+?>|</a>}{}g; # 内側のリンクは削除（二重リンク防止）
    push @linkPlaceholders, $url;
    my $number = "\x{FFFC}" . scalar(@linkPlaceholders) . "\x{FFFC}";
    if($txt =~ "^https?://"){ $txt = $number; } # $txtがURL形式なら$urlと同じに（二重リンクとURLの偽り防止）
    if($url =~ /^[#\.\/\?]/){ return '<a href="'.$number.'">'.$txt.'</a>'; }
    else { return '<a href="'.$number.'" target="_blank">'.$txt.'</a>'; }
  }
}
sub unescapeTagsLines {
  my $text = shift;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  $text =~ s|^//(.*?)\n?$||gm; # コメントアウト
  
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
  $text =~ s/\A\*(.*?)$/$main::pc{"head_$_"} = $1; ''/egim if $_;
  $text =~ s/^\*(.*?)$/<\/p><h2>$1<\/h2><p>/gim;
  
  $text =~ s/(?:^(?:\|(?:.*?))+\|[hc]?(?:\n|$))+/'<\/p>'.&generateTable($&).'<p>'/egim;

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

sub generateTable {
  my $text = shift;
  my $output = '<table class="note-table">';
  my @data;
  my @classes;
  foreach my $line (split("\n", $text)){
    $line =~ s/^\|//;
    if   (!@data && $line eq 'data-table|'){ $output = '<table class="data-table">'; next; }
    elsif(!@data && $line eq 'max-table|' ){ $output = '<table class="note-table width-max">'; next; }
    elsif($line =~ /c$/){ (my $row, @classes) = generateTableCol($line); $output .= $row; next; }
    elsif($line =~ /h$/){ $output .= generateTableHeader($line); next; }
    my @row = split('\|', $line);
    push(@data, [ @row ]);
  }
  my $row_num = 0;
  foreach my $row (@data){
    $output .= "<tr>";
    my $col_num = 0;
    my $colspan = 1;
    foreach my $col (@{$row}){
      my $rowspan = 1;
      my $td = 'td';
      while($data[$row_num+$rowspan][$col_num] eq '~'){ $rowspan++; }
      $col_num++;
      my @classesCell;
      if($classes[$col_num-1]){ push(@classesCell, @{$classes[$col_num-1]}); }
      if   ($col eq '&gt;'){ $colspan++; next; }
      elsif($col eq '~')   { next; }
      elsif($col =~ s/^~//){ $td = 'th' }
      else {
        while($col =~ s/^(LEFT|CENTER|RIGHT|NOWRAP|SMALL)://){
          push(@classesCell, lc($1));
        }
        foreach my $class (reverse @classesCell){
          if($class =~ /^(left|center|right)$/){
            @classesCell = grep { $_ eq $class || $_ !~ /^(left|center|right)$/ } @classesCell;
            last;
          }
        }
      }
      $output .= "<$td";
      if($colspan > 1){ $output .= ' colspan="'.$colspan.'"'; $colspan = 1; }
      if($rowspan > 1){ $output .= ' rowspan="'.$rowspan.'"'; }
      if(@classesCell){ $output .= ' class="'.join(' ',@classesCell).'"' }
      $output .= ">$col</$td>";
    }
    $output .= "</tr>";
    $row_num++;
  }
  $output .= "</table>";

  return $output;

  sub generateTableCol {
    my @out;
    my @col = (split(/\|/, $_[0]));
    pop @col;
    my @classes;
    foreach(@col){
      if($_ eq '&gt;'){
        push @out, '>';
        push @classes, '>';
      }
      else {
        my ($style, @class) = &generateTableStyle($_);
        push @out, $style;
        push @classes, \@class;
      }
    }
    foreach (0 .. $#out){
      my $n = 1;
      while ($out[$_] eq '>'){
        $out[$_] = $out[$_+$n];
        $n++
      }
      my $n = 1;
      while ($classes[$_] eq '>'){
        $classes[$_] = $classes[$_+$n];
        $n++
      }
    }
    return '<colgroup>'.(join '', @out).'</colgroup>', @classes;
  }
  sub generateTableStyle {
    my $text = shift;
    my $style;
    my @class;
    while($text =~ s/^(LEFT|CENTER|RIGHT|NOWRAP|SMALL)://){
      push @class, lc($1);
    }
    if($_ =~ /^([0-9]+)(px|em|\%)/){
      my $num = $1; my $type = $2;
      if   ($type eq 'px' && $num > 300){ $num = 300 }
      elsif($type eq 'em' && $num >  20){ $num =  20 }
      elsif($type eq  '%' && $num > 100){ $num = 100 }
      $style .= "width:calc(${num}${type} + 1em + 1px);";
    }
    return "<col style=\"$style\">", @class,
  }
  sub generateTableHeader {
    my $line = shift;
    my $output;
    $line =~ s/h$//;
    $output .= "<thead><tr>";
    my $colspan = 1;
    foreach my $col (split('\|', $line)){
      my $td = 'td';
      if   ($col eq '&gt;'){ $colspan++; next; }
      elsif($col =~ s/^~//){ $td = 'th' }
      $output .= "<$td";
      if($colspan > 1){ $output .= ' colspan="'.$colspan.'"'; }
      $output .= ">$col</$td>";
    }
    $output .= "</tr></thead>";
    return $output;
  }
}
### タグ削除 --------------------------------------------------
sub removeTags {
  my $text = $_[0];
  $text =~ s#<rp>[\|｜]</rp>##g;
  $text =~ s#<rp>[《]</rp>#(#g;
  $text =~ s#<rp>[》]</rp>#)#g;
  $text =~ s/<img alt="&#91;(.)&#93;"/[$1]<img /g;
  $text =~ s/<.+?>//g;
  return $text;
}
sub removeRuby {
  my $text = shift;
  $text =~ s#<rt>.*?</rt>|<rp>.*?</rp>##g;
  return $text;
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

### デフォルトカラー --------------------------------------------------
sub setDefaultColors {
  my $type = shift;
  $::pc{$type.'colorHeadBgH'} //= 225;
  $::pc{$type.'colorHeadBgS'} //=   9;
  $::pc{$type.'colorHeadBgL'} //=  65;
  $::pc{$type.'colorBaseBgH'} //= 235;
  $::pc{$type.'colorBaseBgS'} //=   0;
}

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

### 行の有無チェック --------------------------------------------------
## 数値の0も偽とする（NameとNoteは空のみ偽）
sub existsRow {
  my $prefix = shift;
  foreach(@_){
    if($_ eq 'Name' || $_ eq 'Note'){
      if($::pc{$prefix.$_} ne ''){ return 1; }
    }
    else {
      if($::pc{$prefix.$_}){ return 1; }
    }
  }
  return 0;
}
## 厳密に空/未定義のみ偽
sub existsRowStrict {
  my $prefix = shift;
  foreach(@_){
    if($::pc{$prefix.$_} ne ''){ return 1; }
  }
  return 0;
}
## 0も偽としたい場合

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

### JSファイル --------------------------------------------------
sub printJS {
  my $mode = shift;
  print "Content-type: text/javascript; charset=utf-8\n";
  print "Cache-Control: public, max-age=604800\n";
  print "\n";
  print "// ytsheet JS output mode:$mode \n\n";
  if($mode eq 'consts' && $set::lib_js_consts){
    print "const base64Mode = ".($set::base64mode || 0).";\n";
    require $set::lib_js_consts;
  }
  exit;
}

### JSON --------------------------------------------------
sub infoJson {
  our $type = shift;
  our $message = shift;
  $message =~ s/"//g;
  print "Content-type: text/javascript; charset=utf-8\n\n";
  print '{"result":"'.$type.'","message":"'.$message.'"}';
  exit;
}

### アップデート・コンバート --------------------------------------------------
## バックアップ形式変更
sub logFileCheck {
  my $dir = shift;
  my $mode = shift;
  if (-d "${dir}/backup") { logFileUpdate($dir,$mode); }
}
sub logFileUpdate {
  my $dir = shift;
  my $mode = shift;

  my $lately_term    = 60*60*24;
  my $interval_long  = 60 * ($set::log_interval_long  || 60);
  my $interval_short = 60 * ($set::log_interval_short || 15);
  
  require Time::Local;

  my %log_name;
  open (my $IN, "${dir}/buname.cgi");
  while (<$IN>){
    chomp;
    my ($date, $name) = split('<>', $_, 2);
    if($name){ $log_name{$date} = $name; }
  }
  close($IN);

  opendir(my $DIR,"${dir}/backup");
  my @log_list;
  while (my $date = readdir($DIR)){
    if ($date =~ s/.cgi$//){
      my ($year, $month, $day, $hour, $min) = split(/-/, $date);
      my $epoc = Time::Local::timelocal(0, $min, $hour, $day, $month-1, $year-1900);
      push(@log_list, { date => $date, epoc => $epoc });
    }
  }
  closedir($DIR);

  my @tmp = map { $_->{date} } @log_list;
  @log_list = @log_list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp];

  my $latest_epoc = (stat("${dir}/data.cgi"))[9];

  sysopen (my $OUT, "${dir}/logs.cgi", O_WRONLY | O_TRUNC | O_CREAT, 0666);
  flock($OUT, 2);
  sysopen (my $BUL, "${dir}/log-list.cgi", O_WRONLY | O_TRUNC | O_CREAT, 0666);
  flock($BUL, 2);
  my $before_saved = 0;
  foreach my $i (0 .. $#log_list){
    my $date = $log_list[$i]{date};
    my $epoc = $log_list[$i]{epoc};
    my $next = $log_list[$i+1]{epoc} || $latest_epoc;
    if (
      $latest_epoc - $epoc <= $lately_term ||
      $log_name{$date} ne '' ||
      $next - $epoc >= $interval_long ||
      ($next - $epoc >= $interval_short &&
       $epoc - $before_saved >= $interval_long)
    ){
      $before_saved = $epoc;
      print $OUT "=${date}=\n";
      print $BUL "${date}<>$epoc<>$log_name{$date}\n";
      open(my $IN,"${dir}/backup/${date}.cgi") or die;
      while (my $line = <$IN>){ print $OUT $line; };
      close($IN);
    }
    unlink("${dir}/backup/${date}.cgi");
  }
  print $BUL "latest<>$latest_epoc<>\n";
  close($OUT);
  close($BUL);
  rmdir("${dir}/backup");
  unlink("${dir}/buname.cgi");
  if($mode eq 'view'){ print "Location:./?id=$::in{id}\n\n"; }
}


1;