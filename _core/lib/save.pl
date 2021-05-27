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
    my @query;
    push(@query, 'mode=mylist') if param('protect') eq 'account';
    push(@query, 'type='.param('type')) if param('type');
    $make_error .= 'エラー：セッションの有効期限が切れたか、二重投稿です。（⇒<a href="./'
                   .(@query ? '?'.join('&',@query) : '')
                   .'">投稿されているか確認する</a>';
  }
  
  ## 登録キーチェック
  if(!$set::user_reqd && $set::registerkey && $set::registerkey ne param('registerkey')){
    $make_error .= '記入エラー：登録キーが一致しません。<br>';
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

## パスワードチェック
if(param('protect') eq 'password'){
  if ($pass eq ''){ $make_error .= '記入エラー：パスワードが入力されていません。<br>'; }
  else {
    if ($pass =~ /[^0-9A-Za-z\.\-\/]/) { $make_error .= '記入エラー：パスワードに使える文字は、半角の英数字とピリオド、ハイフン、スラッシュだけです。'; }
  }
}

## 重複チェックサブルーチン
sub overlap_check {
  my $id = shift;
  my $flag;
  open (my $FH, '<', $set::passfile);
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
if   (param('type') eq 'm'){ require $set::lib_calc_mons; $data_dir = $set::mons_dir; $listfile = $set::monslist; }
elsif(param('type') eq 'i'){ require $set::lib_calc_item; $data_dir = $set::item_dir; $listfile = $set::itemlist; }
else                       { require $set::lib_calc_char; $data_dir = $set::char_dir; $listfile = $set::listfile; }

## データ計算
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
my $imagedata; my $imageflag;
if(param('imageFile')){
  my $imagefile = param('imageFile'); # ファイル名の取得
  my $type = uploadInfo($imagefile)->{'Content-Type'}; # MIMEタイプの取得
  
  # ファイルの受け取り
  my $buffer;
  while(my $bytesread = read($imagefile, $buffer, 2048)) {
    $imagedata .= $buffer;
  }
  # サイズチェック
  my $max_size = ( $set::image_maxsize ? $set::image_maxsize : 1024 * 1024 );
  if (length($imagedata) <= $max_size){ $imageflag = 1; }
  # 形式チェック
  my $ext;
  if    ($type eq "image/gif")   { $ext ="gif"; } #GIF
  elsif ($type eq "image/jpeg")  { $ext ="jpg"; } #JPG
  elsif ($type eq "image/pjpeg") { $ext ="jpg"; } #JPG
  elsif ($type eq "image/png")   { $ext ="png"; } #PNG
  elsif ($type eq "image/x-png") { $ext ="png"; } #PNG
  
  if($imageflag && $ext){
    unlink "${data_dir}${file}/image.$pc{'image'}"; # 前のファイルを削除
    
    $pc{'image'} = $ext;
    $pc{'imageUpdate'} = time;
  }
}


### 保存 #############################################################################################
my $mask = umask 0;
### 個別データ保存 --------------------------------------------------
delete $pc{'ver'};
delete $pc{'pass'};
delete $pc{'_token'};
delete $pc{'registerkey'};
$pc{'IP'} = $ENV{'REMOTE_ADDR'};
data_save($mode, $data_dir, $file);
### passfile --------------------------------------------------
## 新規
if($mode eq 'make'){
  passfile_write_make($pc{'id'},$pass,$LOGIN_ID,$pc{'protect'},$now)
}
## 更新
elsif($mode eq 'save'){
  if($pc{'protect'} ne $pc{'protectOld'}){
    passfile_write_save($pc{'id'},$pass,$LOGIN_ID,$pc{'protect'})
  }
}
### 一覧データ更新 --------------------------------------------------
list_save($listfile, $newline);

### 画像アップ更新 --------------------------------------------------
if($imageflag && $pc{'image'}){
  open(my $IMG, ">", "${data_dir}${file}/image.$pc{'image'}");
  binmode($IMG);
  print $IMG $imagedata;
  close($IMG);
}



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
  flock($FH, 2);
  my @list = <$FH>;
  seek($FH, 0, 0);
  foreach (@list){
    my @data = split /<>/;
    if ($data[0] eq $id){
      my $passwrite = $data[1];
      if   ($protect eq 'account')  {
        if($passwrite !~ /^\[.+?\]$/) { $passwrite = '['.$LOGIN_ID.']'; }
      }
      elsif($protect eq 'password') {
        if(!$passwrite || $passwrite =~ /^\[.+?\]$/) { $passwrite = e_crypt($pass); }
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
  if($mode eq 'make'){
    if (-d "${dir}${file}"){
      $make_error = '新規作成が衝突しました。再度保存してください。';
      require $set::lib_edit; exit;
    }
  }
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
  flock($FH, 2);
  my @list = sort { (split(/<>/,$b))[3] cmp (split(/<>/,$a))[3] } <$FH>;
  seek($FH, 0, 0);
  print $FH "$newline\n";
  foreach (@list){
    my( $id, undef ) = split /<>/;
    if ($id ne $pc{'id'}){
      print $FH $_;
    }
  }
  truncate($FH, tell($FH));
  close($FH);
}


1;