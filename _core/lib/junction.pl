################## 各処理へ移動 ##################
use strict;
#use warnings;
use utf8;
use Encode;

our $ver = "1.26.100";

our %in;
for (param()){ $in{$_} = param($_); }

my $mode = $in{mode};

if($mode eq 'register'){
  if($in{id})    { require $set::lib_register; }    #登録処理
  else           { require $set::lib_form; }        #新規登録フォーム
}
elsif($mode eq 'option'){
  if($in{name})  { require $set::lib_register; }    #オプション変更処理
  else           { require $set::lib_form; }        #オプションフォーム
}
elsif($mode eq 'passchange'){
  require $set::lib_register;    #パスワード変更処理
}
elsif($mode eq 'login')   {
  if($in{id}) { &log_in($in{id},$in{password}); }  #ログイン
  else        { require $set::lib_form; }          #ログインフォーム
}
elsif($mode eq 'reminder')   {
  if($in{mail}) { require $set::lib_reminder; }  #IDリマインダ
  elsif($in{id}){ require $set::lib_reminder; }  #メール送信
  else          { require $set::lib_form; }      #リマインダフォーム
}
elsif($mode eq 'reset')   {
  if($in{password}) { require $set::lib_reminder; }  #パスリセット処理
  else              { require $set::lib_form; }  #パスリセットフォーム
}
elsif($mode eq 'making')   {
  if($in{make})     { require $set::lib_making; }  #キャラクター作成
  else              { require $set::lib_list_make; }  #キャラクター作成フォーム
}
elsif($mode eq 'logout')     { &log_out; }   #ログアウト
elsif($mode eq 'option')     { require $set::lib_form; }   #オプション
elsif($mode eq 'blanksheet') { require $set::lib_edit; }   #ブランクシート
elsif($mode eq 'edit')       { require $set::lib_edit; }   #編集
elsif($mode eq 'copy')       { require $set::lib_edit; }   #コピー
elsif($mode eq 'convert')    { require $set::lib_edit; }   #コンバート編集
elsif($mode eq 'convertform'){ require $set::lib_form; }   #コンバートフォーム
elsif($mode eq 'make')       { require $set::lib_save; }   #新規作成
elsif($mode eq 'save')       { require $set::lib_save; }   #更新
elsif($mode eq 'bu-naming')  { require $set::lib_others; } #過去ログ命名
elsif($mode eq 'delete')     { require $set::lib_delete; } #削除
elsif($mode eq 'img-delete') { require $set::lib_delete; } #画像削除
elsif($mode eq 'palette')    { require $set::lib_palette; }#チャットパレット表示
elsif($mode eq 'js-consts')  { &printJS('consts') }        #JS用定数
elsif($mode eq 'image')      { &redirectToImage($in{id}); }#画像表示
elsif(($in{id}||$in{url}) && $mode eq 'json') { require $set::lib_json; }#外部アプリ連携
elsif($in{id})  { require $set::lib_view; }   #シート表示
elsif($in{url}) { require $set::lib_view; }   #シート表示（コンバート）
else {
  changeFileByType($in{type});
  require $set::lib_list_char;
}   #一覧表示

1;