#################### 基本設定 ####################
use strict;
use utf8;

package set;

## ●管理パスワード (必ず変更してください)
  our $masterkey = '';

## ●登録キー
 # 新規登録をする際に必要な文字列。空欄なら誰でも登録可能。荒らし対策。
  our $registkey = '';

## ●メール関係
 # sendmailのパス
  our $sendmail = '/usr/sbin/sendmail';
 # 管理人メールアドレス
  our $admimail = '';
 # データが登録されたら管理人に通知  0=しない 1=する
  our $notice = 0;
 # メールアドレスを必須にする
  our $mailreqd = 0;

## ●各種ファイル
 # パスワード記録ファイル
  our $passfile = 'data/charpass.cgi';
 # キャラクター一覧ファイル
  our $listfile = 'data/charlist.cgi';
 # ユーザー一覧ファイル
  our $userfile = 'data/users.cgi';

## ●画像関係
 # キャラクター画像の設定 URL入力式=1 アップロード式=0
   our $image_type = 0;
 # キャラクター画像のファイルサイズ上限(単位byte)
   our $image_maxsize = 2024 * 1024;

## ●その他の設定
 # タイトル
  our $title = 'ゆとシート for SW2.5 β'; # ページ左上のタイトル

1;
