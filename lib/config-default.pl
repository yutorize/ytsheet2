################# デフォルト設定 #################
use strict;
use utf8;

package set;

## ●管理パスワード
  our $masterkey = '';
  
## ●管理人ユーザーID (指定したIDは非表示のシートの閲覧や全シートの編集ができます)
  our $masterid = '';

## ●登録キー
  our $registerkey = '';
  
## ●タイトル
  our $title = 'ゆとシート for SW2.5';

## ●画像関係
 # キャラクター画像のファイルサイズ上限(単位byte)
  our $image_maxsize = 1024 * 1024 * 1;
  
## ●削除関係
 # データを削除するとき、バックアップも削除 する=1 しない=0
  our $del_back = 0;

## ●グループ設定
  our @groups = (
    ["pc",  "01", "ＰＣ", "プレイヤーキャラクター"],
    ["npc", "99", "ＮＰＣ", "ノンプレイヤーキャラクター"],
  );
 # デフォルトのグループID
  our $group_default = 'pc';
 # トップページのキャラクター最大表示数（1グループあたり／無制限=0）
  our $list_maxline = 0; 

## ●キャラクターシートの各種初期値
  our $make_exp   = 3000;
  our $make_money = 1200;
  our $make_honor = 0;
  our $make_fix   = 0;

## ●各種ファイルへのパス
  our $sendmail = '/usr/sbin/sendmail'; # sendmailのパス
  
  our $data_dir = 'data/'; # データ格納ディレクトリ
  our $userfile = $data_dir . 'users.cgi';    # ユーザー一覧ファイル
  our $passfile = $data_dir . 'charpass.cgi'; # パスワード記録ファイル
  our $listfile = $data_dir . 'charlist.cgi'; # キャラクター一覧ファイル
  our $monslist = $data_dir . 'monslist.cgi'; # 魔物一覧ファイル
  our $itemlist = $data_dir . 'itemlist.cgi'; # アイテム一覧ファイル
  our $char_dir = $data_dir . 'chara/'; # キャラクターデータ格納ディレクトリ
  our $mons_dir = $data_dir . 'mons/';  # 魔物データ格納ディレクトリ
  our $item_dir = $data_dir . 'item/';  # アイテムデータ格納ディレクトリ
  
  our $lib_edit      = 'lib/edit.pl';
  our $lib_edit_char = 'lib/edit-chara.pl';
  our $lib_edit_mons = 'lib/edit-mons.pl';
  our $lib_save      = 'lib/save.pl';
  our $lib_save_char = 'lib/save-chara.pl';
  our $lib_save_mons = 'lib/save-mons.pl';
  our $lib_view      = 'lib/view.pl';
  our $lib_view_char = 'lib/view-chara.pl';
  our $lib_view_mons = 'lib/view-mons.pl';
  our $lib_json      = 'lib/json.pl';
  our $lib_list      = 'lib/list.pl';
  our $lib_list_mons = 'lib/list-mons.pl';
  
  our $lib_delete = 'lib/delete.pl';
  
  our $lib_form    = 'lib/form.pl';
  our $lib_info    = 'lib/info.pl';
  our $lib_register= 'lib/register.pl';
  our $lib_reminder= 'lib/reminder.pl';
  our $login_users = 'tmp/login_users.cgi';
  
  our $tokenfile  = 'tmp/token.cgi'; 

  our $data_feats = 'lib/data-feats.pl';  # 戦闘特技のデータ
  our $data_races = 'lib/data-races.pl';  # 種族のデータ
  our $data_items = 'lib/data-items.pl';  # アイテムカテゴリのデータ
  our $data_faith = 'lib/data-faith.pl';  # 信仰のデータ
  our $data_mons  = 'lib/data-mons.pl';   # 魔物分類のデータ

  our $skin_tmpl  = 'skin/template.html'; # 一覧など
  our $skin_sheet = 'skin/sheet.html';    # キャラクターシート
  our $skin_mons  = 'skin/monster.html';    # キャラクターシート
  
 # config.cgiのほうが優先されます
 # 変更する場合は同様の項目をconfig.cgiに追記してください
 #（CGIアップデート時に上書きされるため）

1;