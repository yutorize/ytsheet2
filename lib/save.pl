################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";


our $mode = param('mode');
our $pass = param('pass');
our $new_id;

our $make_error;

## 新規作成時処理
if ($mode eq 'make'){
  ##ログインチェック
  if($set::user_reqd && !check) {
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
  my $LOGIN_ID = check;
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

### 個別処理 --------------------------------------------------
   if(param('type') eq 'm'){ require $set::lib_save_mons; }
elsif(param('type') eq 'i'){ require $set::lib_save_item; }
else                       { require $set::lib_save_char; }



### キャラシートへ移動／編集画面に戻る --------------------------------------------------
if($mode eq 'make'){
  print "Location: ./?id=${new_id}\n\n"
}
else {
  require $set::lib_edit;
}

### サブルーチン --------------------------------------------------
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


1;