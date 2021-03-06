################# デフォルト設定 #################
use strict;
use utf8;

package set;

# config.cgiのほうが優先されます
# 変更する場合は同様の項目をconfig.cgiに追記してください
# （CGIアップデート時に上書きされるため）
  
## ●タイトル
  our $title = 'ゆとシートⅡ for SW2.5';

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

## ●OAuth2 でのログイン関係
 # OAuth2 を提供するサービスの名称。現在 Discord と Google のみ対応
  our $oauth_service = '';
 # OAuth2 で利用するサービスにユーザがログインするための URL
  our $oauth_login_url = '';
 # OAuth2 で利用するサービスから払い出される client_id
  our $oauth_client_id = '';
 # OAuth2 で利用するサービスから払い出される client_secret
  our $oauth_secret_id = '';
 # ゆとシート2 の URL のうち index.cgi を oauth.cgi に置換したもの
  our $oauth_redirect_url = '';
 # OAuth2 のスコープ
  our $oauth_scope = '';

 # OAuth で Discord を利用する場合のみ利用可能 ログインを許可する Discord のサーバ一覧。空リストの場合は制限しない
  our @oauth_discord_login_servers = (); 

## ●画像関係
 # キャラクター画像のファイルサイズ上限(単位byte)
  our $image_maxsize = 1024 * 1024 * 1;


## ●削除関係
 # データを削除するとき、バックアップも削除 する=1 しない=0
  our $del_back = 0;

## ●一覧表示関係
 # キャラクター一覧を簡易表示にする
  our $simplelist = 0; 

## ●グループ設定
 # ["ID", "ソート順(空欄で非表示)", "分類名", "分類の説明文"],
 # 選択時はここで書いた順番、キャラ一覧(グループ別)ではソート順で数字が小さい方から表示されます
 # 増減OK
  our @groups = (
    ["pc",  "01", "ＰＣ", "プレイヤーキャラクター"],
    ["npc", "99", "ＮＰＣ", "ノンプレイヤーキャラクター"],
  );

 # デフォルトのグループID
  our $group_default = 'pc';

 # トップページのキャラクター最大表示数（1グループあたり／無制限=0）
  our $list_maxline = 0;

 # グループ個別表示時や検索結果表示時の1ページあたりの最大表示数（0で全部表示）
  our $pagemax = 0;

 # グループ自動移動（レベルと経験点で自動で分ける設定）
 # ['自動にしたいグループのID', 上限Lv, 上限経験点],
  our @grades = ( 
   #['s-',  3,   4999],
   #['s0',  4,  10000],
   #['s1',  6,  19000],
   #['s2',  8,  33000],
   #['s3', 10,  55000],
   #['s4', 12,  88000],
   #['s5', 14, 133000],
   #['s6', 15, 160000],
  );


## ●キャラクターシートの各種初期値
  our $make_exp   = 3000;
  our $make_money = 1200;
  our $make_honor = 0;
  our $make_fix   = 0;


## ●2.5未実装要素の表示設定 (ON=1)
 # 全ての技能を表示
  our $all_class_on = 1;
 # 秘伝
  our $mystic_arts_on = 1;


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

## ●メイキング
  our $making_max = 0; # 作成板の最大保存数（0で無制限）
  our $average_over = 0;
  our $adventurer_onlyonce = 0;
  our $making_interval = 0;

## ●Cookie
 # Cookieの名前
  our $cookie = 'ytsheet2';

## ●特殊ハウスルール向け
 # 戦闘用アイテム欄
 # our $battleitem = 1;

 # 成長タイプ O=1000毎 ／ A=1000＋(10*成長回数)
 # our $growtype = '';

 # レンジャー先制
 # our @ini_class_add = ('RanB');

## ●各種ファイルへのパス
  our $sendmail = '/usr/sbin/sendmail'; # sendmailのパス
  our $admimail = 'noreply@yutorize.2-d.jp'; # 管理者メールアドレス
  
  our $data_dir = './data/'; # データ格納ディレクトリ
  our $passfile = $data_dir . 'charpass.cgi'; # パスワード記録ファイル
  our $listfile = $data_dir . 'charlist.cgi'; # キャラクター一覧ファイル
  our $monslist = $data_dir . 'monslist.cgi'; # 魔物一覧ファイル
  our $itemlist = $data_dir . 'itemlist.cgi'; # アイテム一覧ファイル
  our $makelist = $data_dir . 'makelist.cgi'; # 能力値作成データファイル
  our $char_dir = $data_dir . 'chara/'; # キャラクターデータ格納ディレクトリ
  our $mons_dir = $data_dir . 'mons/';  # 魔物データ格納ディレクトリ
  our $item_dir = $data_dir . 'item/';  # アイテムデータ格納ディレクトリ
  
  our $userfile    = $::core_dir . '/data/users.cgi';           # ユーザー一覧ファイル
  our $login_users = $::core_dir . '/data/login_users.cgi'; # ログイン情報保存ファイル
  our $tokenfile   = $::core_dir . '/data/token.cgi';       # 一時トークン保存ファイル
  
  our $lib_form     = $::core_dir . '/lib/form.pl';
  our $lib_info     = $::core_dir . '/lib/info.pl';
  our $lib_register = $::core_dir . '/lib/register.pl';
  our $lib_reminder = $::core_dir . '/lib/reminder.pl';
  our $lib_delete   = $::core_dir . '/lib/delete.pl';
  
  # 編集画面
  our $lib_edit = $::core_dir . '/lib/edit.pl';
  our $lib_edit_char = $::core_dir . '/lib/sw2/edit-chara.pl';
  our $lib_edit_mons = $::core_dir . '/lib/sw2/edit-mons.pl';
  our $lib_edit_item = $::core_dir . '/lib/sw2/edit-item.pl';
  # 保存処理
  our $lib_save   = $::core_dir . '/lib/save.pl';
  our $lib_calc_char = $::core_dir . '/lib/sw2/calc-chara.pl';
  our $lib_calc_mons = $::core_dir . '/lib/sw2/calc-mons.pl';
  our $lib_calc_item = $::core_dir . '/lib/sw2/calc-item.pl';
  # シート表示
  our $lib_view   = $::core_dir . '/lib/view.pl';
  our $lib_view_char = $::core_dir . '/lib/sw2/view-chara.pl';
  our $lib_view_mons = $::core_dir . '/lib/sw2/view-mons.pl';
  our $lib_view_item = $::core_dir . '/lib/sw2/view-item.pl';
  # チャットパレット
  our $lib_palette     = $::core_dir . '/lib/palette.pl';
  our $lib_palette_sub = $::core_dir . '/lib/sw2/palette-sub.pl';
  # キャラ作成
  our $lib_making = $::core_dir . '/lib/sw2/making.pl';
  # 一覧
  our $lib_list_char = $::core_dir . '/lib/sw2/list-chara.pl';
  our $lib_list_mons = $::core_dir . '/lib/sw2/list-mons.pl';
  our $lib_list_item = $::core_dir . '/lib/sw2/list-item.pl';
  our $lib_list_make = $::core_dir . '/lib/sw2/list-making.pl';
  # JSON出力
  our $lib_json     = $::core_dir . '/lib/json.pl';
  our $lib_json_sub = $::core_dir . '/lib/sw2/json-sub.pl';
  # コンバート
  our $lib_convert = $::core_dir . '/lib/sw2/convert.pl';
  our $lib_ytsheetMConvert = $::core_dir . '/lib/sw2/client-ytsheet_one_mons.pl';

  # 各種データ
  our $data_races = $::core_dir . '/lib/sw2/data-races.pl';  # 種族
  our $data_items = $::core_dir . '/lib/sw2/data-items.pl';  # アイテムカテゴリ
  our $data_faith = $::core_dir . '/lib/sw2/data-faith.pl';  # 信仰
  our $data_feats = $::core_dir . '/lib/sw2/data-feats.pl';  # 戦闘特技
  our $data_class = $::core_dir . '/lib/sw2/data-class.pl';  # 技能、練技・呪歌など
  our $data_mons  = $::core_dir . '/lib/sw2/data-mons.pl';   # 魔物分類

  # HTMLテンプレート
  our $icon_dir   = $::core_dir . '/skin/sw2/img/'; # 武器アイコンのあるディレクトリ
  our $skin_tmpl  = $::core_dir . '/skin/sw2/index.html';         # 一覧／登録フォーム等の大枠
  our $skin_sheet = $::core_dir . '/skin/sw2/sheet-chara.html';   # キャラクターシート
  our $skin_mons  = $::core_dir . '/skin/sw2/sheet-monster.html'; # 魔物シート
  our $skin_item  = $::core_dir . '/skin/sw2/sheet-item.html';    # アイテムシート

1;