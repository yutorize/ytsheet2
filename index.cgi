#!/usr/bin/perl
####################################
##     ゆとシートⅡ for SW2.5     ##
##          by ゆとらいず工房     ##
##    https://yutorize.2-d.jp     ##
####################################
use strict;
#use warnings;
use utf8;
use open ":utf8";
binmode STDIN, ":utf8";
binmode STDOUT, ':utf8';
use CGI::Carp qw(fatalsToBrowser);
use CGI qw/:all/;
use CGI::Cookie;
use Encode qw/encode decode/;
use List::Util qw/max min/;
use Fcntl;

### バージョン #######################################################################################
our $ver = "1.07";

### 設定読込 #########################################################################################

require './lib/config-default.pl';
require './config.cgi';
require './lib/subroutine.pl';

### 各処理へ移動 #####################################################################################

my $mode = param('mode');

if($mode eq 'register'){
  if(param('id'))    { require $set::lib_register; }    #登録処理
  else               { require $set::lib_form; }        #新規登録フォーム
}
elsif($mode eq 'option'){
  if(param('name'))  { require $set::lib_register; }    #オプション変更処理
  else               { require $set::lib_form; }        #オプションフォーム
}
elsif($mode eq 'passchange'){
  require $set::lib_register;    #パスワード変更処理
}
elsif($mode eq 'login')   {
  if(param('id')) { &log_in(param('id'),param('password')); }  #ログイン
  else            { require $set::lib_form; }                  #ログインフォーム
}
elsif($mode eq 'reminder')   {
  if(param('id'))   { require $set::lib_reminder; }  #メール送信
  else              { require $set::lib_form; }      #リマインダフォーム
}
elsif($mode eq 'reset')   {
  if(param('password')) { require $set::lib_reminder; }  #パスリセット処理
  else                  { require $set::lib_form; }  #パスリセットフォーム
}
elsif($mode eq 'making')   {
  if(param('make'))     { require $set::lib_making; }  #キャラクター作成
  else                  { require $set::lib_list_make; }  #キャラクター作成フォーム
}
elsif($mode eq 'logout')     { &log_out; }   #ログアウト
elsif($mode eq 'option')     { require $set::lib_form; }   #オプション
elsif($mode eq 'blanksheet') { require $set::lib_edit; }   #ブランクシート
elsif($mode eq 'edit')       { require $set::lib_edit; }   #編集
elsif($mode eq 'copy')       { require $set::lib_edit; }   #コピー
elsif($mode eq 'make')       { require $set::lib_save; }   #新規作成
elsif($mode eq 'save')       { require $set::lib_save; }   #更新
elsif($mode eq 'delete')     { require $set::lib_delete; } #削除
elsif($mode eq 'palette')    { require $set::lib_palette; }#チャットパレット表示
elsif($mode eq 'json')       { require $set::lib_json; }   #外部アプリ連携
elsif(param('id')) { require $set::lib_view; }   #シート表示
else {
  if   (param('type') eq 'm'){ require $set::lib_list_mons; }
  elsif(param('type') eq 'i'){ require $set::lib_list_item; }
  else                       { require $set::lib_list_char; }
}   #一覧表示


