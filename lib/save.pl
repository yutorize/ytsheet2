################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";


our $mode = param('mode');
our $pass = param('pass');
our $new_id;

our $make_error;

our $LOGIN_ID = check;

## 新規作成時処理
if ($mode eq 'make'){
  ##ログインチェック
  if($set::user_reqd && !$LOGIN_ID) {
    $make_error .= 'エラー：ログインしていません。<br>';
  }

  ## 二重投稿チェック
  if(!token_check(param('_token'))){
    $make_error .= 'エラー：セッションの有効期限が切れたか、二重投稿です。（⇒<a href="./'
                   .(param('protect') eq 'account'? '?mode=mylist' : '')
                   .'">投稿されているか確認する</a>';
  }
  
  ## 登録キーチェック
  if(!$set::user_reqd && $set::registerkey && $set::registerkey ne param('registerkey')){
    $make_error .= '記入エラー：登録キーが一致しません。<br>';
  }
  
  ## パスワードチェック
  if(param('protect') eq 'password'){
    if ($pass eq ''){ $make_error .= '記入エラー：パスワードが入力されていません。<br>'; }
    else {
      if ($pass =~ /[^0-9A-Za-z\.\-\/]/) { $make_error .= '記入エラー：パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです。'; }
    }
  }
  ## ID生成
  if($set::id_type && $LOGIN_ID){
    my $type = (param('type') eq 'm') ? 'm' : (param('type') eq 'i') ? 'i' : '';
    my $i = 1;
    $new_id = $LOGIN_ID.'-'.$type.sprintf("%03d",$i);
    # 重複チェック
    while (overlap_check($new_id)) {
      $i++;
      $new_id = $LOGIN_ID.'-'.$type.sprintf("%03d",$i);
    }
  }
  else {
    $new_id = random_id(6);
    # 重複チェック
    while (overlap_check($new_id)) {
      $new_id = random_id(6);
    }
  }
}

## 重複チェックサブルーチン
sub overlap_check {
  my $id = shift;
  my $flag;
  open (my $FH, '<', $set::passfile) ;
  while (<$FH>){ 
    if ($_ =~ /^$id<>/){ $flag = 1; }
  }
  close ($FH);
  return $flag;
}

if ($make_error) { require $set::lib_edit; exit; } # エラーなら編集画面に戻す

### データ処理 #################################################################################
my %pc;
for (param()){ $pc{$_} = param($_); }
if($main::new_id){ $pc{'id'} = $main::new_id; }
delete $pc{'imageFile'};
## 現在時刻
our $now = time;
## 最終更新
$pc{'updateTime'} = time_convert($now);

## ファイル名取得
our $file;
if($mode eq 'make'){
  $pc{'birthTime'} = $file = $now;
}
elsif($mode eq 'save'){
  (undef, undef, $file, undef) = getfile($pc{'id'},$pc{'pass'},$LOGIN_ID);
  if(!$file){ error('編集権限がありません。'); }
}

my $data_dir; my $listfile; our $newline;
if   (param('type') eq 'm'){ require $set::lib_save_mons; $data_dir = $set::mons_dir; $listfile = $set::monslist; }
elsif(param('type') eq 'i'){ require $set::lib_save_item; $data_dir = $set::item_dir; $listfile = $set::itemlist; }
else                       { require $set::lib_save_char; $data_dir = $set::char_dir; $listfile = $set::listfile; }

%pc = data_calc(\%pc);

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

### 画像アップロード --------------------------------------------------
if($pc{'imageDelete'}){
  unlink "${data_dir}${file}/image.$pc{'image'}"; # ファイルを削除
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
    unlink "${data_dir}${file}/image.$pc{'image'}"; # 前のファイルを削除
    
    if (!-d "${data_dir}${file}"){ mkdir "${data_dir}${file}"; }
    open(my $IMG, ">", "${data_dir}${file}/image.${ext}");
    binmode($IMG);
    print $IMG $data;
    close($IMG);
    
    $pc{'image'} = $ext;
  }
}


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
data_save($mode, $data_dir, $file);
### 一覧データ更新 --------------------------------------------------
list_save($listfile, $newline);




### 保存後処理 ######################################################################################
### キャラシートへ移動／編集画面に戻る --------------------------------------------------
if($mode eq 'make'){
  print "Location: ./?id=${new_id}\n\n"
}
else {
  require $set::lib_edit;
}




### サブルーチン ###################################################################################
sub time_convert {
  my ($min,$hour,$day,$mon,$year) = (localtime($_[0]))[1..5];
  $year += 1900; $mon++;
  return sprintf("%04d-%02d-%02d %02d:%02d",$year,$mon,$day,$hour,$min);
}

sub passfile_write_make {
  my ($id, $pass ,$LOGIN_ID, $protect, $now) = @_;
  sysopen (my $FH, $set::passfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
    my $passwrite;
    if   ($protect eq 'account'&& $LOGIN_ID) { $passwrite = '['.$LOGIN_ID.']'; }
    elsif($protect eq 'password')            { $passwrite = e_crypt($pass); }
    print $FH "$id<>$passwrite<>$now<>".param('type')."<>\n";
  close ($FH);
}

sub passfile_write_save {
  my ($id, $pass ,$LOGIN_ID, $protect) = @_;
  sysopen (my $FH, $set::passfile, O_RDWR);
  my @list = <$FH>;
  flock($FH, 2);
  seek($FH, 0, 0);
  foreach (@list){
    my @data = split /<>/;
    if ($data[0] eq $id){
      my $passwrite = $data[1];
      if   ($protect eq 'account')  {
        if($passwrite !~ /\[.+?\]/) { $passwrite = '['.$LOGIN_ID.']'; }
      }
      elsif($protect eq 'password') {
        if(!$passwrite || $passwrite =~ /\[.+?\]/) { $passwrite = e_crypt($pass); }
      }
      elsif($protect eq 'none') {
        $passwrite = '';
      }
      print $FH "$data[0]<>$passwrite<>$data[2]<>$data[3]<>\n";
    }else{
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
}

sub data_save {
  my $mode = shift;
  my $dir  = shift;
  my $file = shift;
  if($mode eq 'save'){
    use File::Copy qw/copy/;
    if (!-d "${dir}${file}/backup/"){ mkdir "${dir}${file}/backup/"; }

    my $modtime = (stat("${dir}${file}/data.cgi"))[9];
    my ($min, $hour, $day, $mon, $year) = (localtime($modtime))[1..5];
    $year += 1900; $mon++;
    my $update_date = sprintf("%04d-%02d-%02d-%02d-%02d",$year,$mon,$day,$hour,$min);
    copy("${dir}${file}/data.cgi", "${dir}${file}/backup/${update_date}.cgi");
  }

  if (!-d "${dir}"){ mkdir "${dir}"; }
  if (!-d "${dir}${file}"){ mkdir "${dir}${file}"; }
  sysopen (my $FH, "${dir}${file}/data.cgi", O_WRONLY | O_TRUNC | O_CREAT, 0666);
    print $FH "ver<>".$main::ver."\n";
    foreach (sort keys %pc){
      if($pc{$_} ne "") { print $FH "$_<>".$pc{$_}."\n"; }
    }
  close($FH);
}

sub list_save {
  my $listfile = shift;
  my $newline  = shift;
  sysopen (my $FH, $listfile, O_RDWR | O_CREAT, 0666);
  my @list = sort { (split(/<>/,$b))[3] cmp (split(/<>/,$a))[3] } <$FH>;
  flock($FH, 2);
  seek($FH, 0, 0);
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