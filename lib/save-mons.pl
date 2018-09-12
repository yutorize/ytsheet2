################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";

my $mode = $main::mode;
my $LOGIN_ID = check;

my %pc; 
for (param()){ $pc{$_} = param($_); }
my %st;

if($main::new_id){ $pc{'id'} = $main::new_id; }

### データ読み込み ###################################################################################
require $set::data_mons;

### 保存前処理 #######################################################################################
## 現在時刻
my $now = time;
## 最終更新
$pc{'updateTime'} = time_convert($now);

## ファイル名取得
my $file;
if($mode eq 'make'){
  $pc{'birthTime'} = $file = $now;
}
elsif($mode eq 'save'){
  (undef, undef, $file, undef) = getfile($pc{'id'},$pc{'pass'},$LOGIN_ID);
  if(!$file){ die; }
}


#### 改行を<br>に変換 --------------------------------------------------
$pc{'skills'}      =~ s/\r\n?|\n/<br>/g;
$pc{'description'} =~ s/\r\n?|\n/<br>/g;

### 画像アップロード --------------------------------------------------
if($pc{'imageDelete'}){
  unlink "${set::mons_dir}${file}/image.$pc{'image'}"; # ファイルを削除
  $pc{'image'} = '';
}
if(param('imageFile')){
  my $imagefile = param('imageFile'); # ファイル名の取得
  my $type = uploadInfo($imagefile)->{'Content-Type'}; # MIMEタイプの取得
  
  # ファイルの受け取り
  my $data; my $buffer;
  while(my $bytesread = read($imagefile, $buffer, 2048)) {
    $data .= $buffer;
  }
  # サイズチェック
  my $flag; 
  my $max_size = ( $set::image_maxsize ? $set::image_maxsize : 1024 * 1024 );
  if (length($data) <= $max_size){ $flag = 1; }
  # 形式チェック
  my $ext;
  if    ($type eq "image/gif")   { $ext ="gif"; } #GIF
  elsif ($type eq "image/jpeg")  { $ext ="jpg"; } #JPG
  elsif ($type eq "image/pjpeg") { $ext ="jpg"; } #JPG
  elsif ($type eq "image/png")   { $ext ="png"; } #PNG
  elsif ($type eq "image/x-png") { $ext ="png"; } #PNG
  
  if($flag && $ext){
    unlink "${set::mons_dir}${file}/image.$pc{'image'}"; # 前のファイルを削除
    
    if (!-d "${set::mons_dir}${file}"){ mkdir "${set::mons_dir}${file}"; }
    open(my $IMG, ">", "${set::mons_dir}${file}/image.${ext}");
    binmode($IMG);
    print $IMG $data;
    close($IMG);
    
    $pc{'image'} = $ext;
  }
}

### エスケープ --------------------------------------------------
foreach (keys %pc) {
  $pc{$_} =~ s/&/&amp;/g;
  $pc{$_} =~ s/"/&quot;/g;
  $pc{$_} =~ s/</&lt;/g;
  $pc{$_} =~ s/>/&gt;/g;
  $pc{$_} =~ s/\r//g;
  $pc{$_} =~ s/\n//g;
}

## タグ：全角スペース・英数を半角に変換 --------------------------------------------------
$pc{'tags'} =~ tr/　/ /;
$pc{'tags'} =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
$pc{'tags'} =~ tr/＋－＊／．，＿/\+\-\*\/\.,_/;
$pc{'tags'} =~ tr/ / /s;

### 保存 #############################################################################################
my $mask = umask 0;
### passfile --------------------------------------------------
## 新規
if($mode eq 'make'){
  passfile_write_make($pc{'id'},$pc{'pass'},$LOGIN_ID,$pc{'protect'},$now)
}
## 更新
elsif($mode eq 'save'){
  if($pc{'protect'} ne $pc{'protectOld'}){
    passfile_write_save($pc{'id'},$pc{'pass'},$LOGIN_ID,$pc{'protect'})
  }
}

### 個別データ保存 --------------------------------------------------
delete $pc{'pass'};
delete $pc{'_token'};
delete $pc{'registerkey'};
if($mode eq 'save'){
  use File::Copy qw/copy/;
  if (!-d "${set::mons_dir}${file}/backup/"){ mkdir "${set::mons_dir}${file}/backup/"; }
  
  my $modtime = (stat("${set::mons_dir}${file}/data.cgi"))[9];
  my ($min, $hour, $day, $mon, $year) = (localtime($modtime))[1..5];
  $year += 1900; $mon++;
  my $update_date = sprintf("%04d-%02d-%02d-%02d-%02d",$year,$mon,$day,$hour,$min);
  copy("${set::mons_dir}${file}/data.cgi", "${set::mons_dir}${file}/backup/${update_date}.cgi");
}

if (!-d "${set::mons_dir}"){ mkdir "${set::mons_dir}"; }
if (!-d "${set::mons_dir}${file}"){ mkdir "${set::mons_dir}${file}"; }
sysopen (my $FH, "${set::mons_dir}${file}/data.cgi", O_WRONLY | O_TRUNC | O_CREAT, 0666);
  print $FH "ver<>".$main::ver."\n";
  foreach (sort keys %pc){
    if($pc{$_} ne "") { print $FH "$_<>".$pc{$_}."\n"; }
  }
close($FH);

### 一覧データ更新 --------------------------------------------------
{
  my $name = $pc{'characterName'} ? $pc{'characterName'} : $pc{'monsterName'};
  sysopen (my $FH, $set::monslist, O_RDWR | O_CREAT, 0666);
  my @list = sort { (split(/<>/,$b))[3] cmp (split(/<>/,$a))[3] } <$FH>;
  flock($FH, 2);
  seek($FH, 0, 0);
  my $newline = "$pc{'id'}<>$file<>".
                "$pc{'birthTime'}<>$now<>$name<>$pc{'author'}<>$pc{'taxa'}<>$pc{'lv'}<>".
                "$pc{'intellect'}<>$pc{'perception'}<>$pc{'disposition'}<>$pc{'sin'}<>$pc{'initiative'}<>$pc{'weakness'}<>".
                "$pc{'image'}<> $pc{'tags'} <>$pc{'hide'}<>";
  my $listhit;
  foreach (@list){
    my( $id, undef ) = split /<>/;
    if ($id eq $pc{'id'}){
      print $FH "$newline\n";
      $listhit = 1;
    }else{
      print $FH $_;
    }
  }
  if(!$listhit){
    print $FH "$newline\n";
  }
  truncate($FH, tell($FH));
  close($FH);
}

1;