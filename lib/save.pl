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
  ## 二重投稿チェック
  if(!token_check(param('_token'))){
    $make_error .= 'エラー：セッションの有効期限が切れたか、二重投稿です。（⇒<a href="./'
                   .(param('protect') eq 'account'? '?mode=mylist' : '')
                   .'">投稿されているか確認する</a>';
  }
  
  ## 登録キーチェック
  if($set::registerkey && $set::registerkey ne param('registerkey')){
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
  $new_id = random_id(6);
  # 重複チェック
  while (overlap_check($new_id)) {
    $new_id = random_id(6);
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


1;