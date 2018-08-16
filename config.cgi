#################### 基本設定 ####################
use strict;
use utf8;

package set;

## ●管理パスワード (必ず変更してください)
  our $masterkey = '';
  
## ●管理人ユーザーID (指定したIDは非表示のシートの閲覧や全シートの編集ができます)
  our $masterid = '';

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
  
## ●グループ設定
 # ["ID", "ソート順(空欄で非表示)", "分類名", "分類の説明文"],
 # 選択時はここで書いた順番、キャラ一覧(グループ別)ではソート順で数字が小さい方から表示されます
 # 増減OK
   our @groups = (
    ["pc",  "01", "自由登録", ""],
    ["sample", "00", "サンプル", ""],

   # ["A", "01", "キャンペーン「A」", "GM：○○"],
   # ["B", "02", "キャンペーン「B」", "GM：××"],
   # ["", "", "", ""],
   );
   our $group_default = 'pc'; # デフォルトのグループ


## ●キャラクターシートの各種初期値
   our $make_exp   = 3000;  # 初期経験点
   our $make_money = 1200;  # 初期所持金
   our $make_honor = 0;  # 初期名誉点
   our $make_fix   = 0;  # 初期値を固定にする(PLが変更出来ないようにする)=1 しない=0

1;