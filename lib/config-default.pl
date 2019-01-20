################# デフォルト設定 #################
use strict;
use utf8;

package set;
  
## ●タイトル
  our $title = 'ゆとシート for SW2.5';

## ●管理パスワード
  our $masterkey = '';
  
## ●管理人ユーザーID (指定したIDは非表示のシートの閲覧や全シートの編集ができます)
  our $masterid = '';

## ●登録関係
 # 登録キー
  our $registerkey = '';
 # データ作成・編集にユーザー登録（ログイン状態）を必須にする
  our $user_reqd = 0;
 # キャラクター・魔物のIDをランダムではなくユーザーID＋番号(001,002..)にする(魔物はm001..)
  our $id_type = 0;


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
  
## ●名誉ランク
  our @adventurer_rank = (
    ['ダガー',          20,  0],
    ['レイピア',        50,  5],
    ['ブロードソード', 100, 10],
    ['グレートソード', 200, 20],
    ['フランベルジュ', 300, 30],
    ['センチネル',     500, 50],
    ['ハイペリオン',   700, 70],
    ['〈始まりの剣〉',1000,100],
  );
  our @adventurer_rank_name;
  push (@adventurer_rank_name, @$_[0]) foreach (@adventurer_rank);
## ●不名誉称号
  our @notoriety_rank = (
    ['ゴブリン級迷惑',       1],
    ['ボルグ級危険',        21],
    ['オーガ級外道',        51],
    ['トロール級極悪',     101],
    ['ドレイク級人族の敵', 201],
    ['蛮王級世界破壊者',   501],
  );

## ●戦闘特技
 # 習得レベル
  our @feats_lv = (1,3,5,7,9,11,13,15,16,17);
  
## ●作成板の最大保存数
  our $making_max = 0;
  
## ●Cookie
 # Cookieの名前
  our $cookie = 'ytsheet2.5';

## ●各種ファイルへのパス
  our $sendmail = '/usr/sbin/sendmail'; # sendmailのパス
  
  our $data_dir = 'data/'; # データ格納ディレクトリ
  our $userfile = $data_dir . 'users.cgi';    # ユーザー一覧ファイル
  our $passfile = $data_dir . 'charpass.cgi'; # パスワード記録ファイル
  our $listfile = $data_dir . 'charlist.cgi'; # キャラクター一覧ファイル
  our $monslist = $data_dir . 'monslist.cgi'; # 魔物一覧ファイル
  our $itemlist = $data_dir . 'itemlist.cgi'; # アイテム一覧ファイル
  our $makelist = $data_dir . 'makelist.cgi'; # 能力値作成データファイル
  our $char_dir = $data_dir . 'chara/'; # キャラクターデータ格納ディレクトリ
  our $mons_dir = $data_dir . 'mons/';  # 魔物データ格納ディレクトリ
  our $item_dir = $data_dir . 'item/';  # アイテムデータ格納ディレクトリ
  
  our $lib_edit      = 'lib/edit.pl';
  our $lib_edit_char = 'lib/edit-chara.pl';
  our $lib_edit_mons = 'lib/edit-mons.pl';
  our $lib_edit_item = 'lib/edit-item.pl';
  our $lib_save      = 'lib/save.pl';
  our $lib_save_char = 'lib/save-chara.pl';
  our $lib_save_mons = 'lib/save-mons.pl';
  our $lib_save_item = 'lib/save-item.pl';
  our $lib_view      = 'lib/view.pl';
  our $lib_view_char = 'lib/view-chara.pl';
  our $lib_view_mons = 'lib/view-mons.pl';
  our $lib_view_item = 'lib/view-item.pl';
  our $lib_json      = 'lib/json.pl';
  our $lib_list      = 'lib/list.pl';
  our $lib_list_mons = 'lib/list-mons.pl';
  our $lib_list_item = 'lib/list-item.pl';
  our $lib_making    = 'lib/making.pl';
  our $lib_list_make = 'lib/list-making.pl';
  
  our $lib_delete = 'lib/delete.pl';
  
  our $lib_form    = 'lib/form.pl';
  our $lib_info    = 'lib/info.pl';
  our $lib_register= 'lib/register.pl';
  our $lib_reminder= 'lib/reminder.pl';
  our $login_users = 'tmp/login_users.cgi';
  
  our $tokenfile  = 'tmp/token.cgi'; 

  our $data_races = 'lib/data-races.pl';  # 種族のデータ
  our $data_items = 'lib/data-items.pl';  # アイテムカテゴリのデータ
  our $data_faith = 'lib/data-faith.pl';  # 信仰のデータ
  our $data_feats = 'lib/data-feats.pl';  # 戦闘特技のデータ
  our $data_craft = 'lib/data-craft.pl';  # 練技・呪歌などのデータ
  our $data_mons  = 'lib/data-mons.pl';   # 魔物分類のデータ

  our $icon_dir  = 'skin/img/'; # 武器アイコンのあるディレクトリ
  
  our $skin_tmpl  = 'skin/template.html'; # 一覧など
  our $skin_sheet = 'skin/sheet.html';    # キャラクターシート
  our $skin_mons  = 'skin/monster.html';    # 魔物シート
  our $skin_item  = 'skin/item.html';    # アイテムシート
  
 # config.cgiのほうが優先されます
 # 変更する場合は同様の項目をconfig.cgiに追記してください
 #（CGIアップデート時に上書きされるため）

1;