################# デフォルト設定 #################
use strict;
use utf8;

package set;

our $game = 'gc';

# config.cgiのほうが優先されます
# 変更する場合は同様の項目をconfig.cgiに追記してください
# （CGIアップデート時に上書きされるため）
  
## ●タイトル
  our $title = 'ゆとシートⅡ for VC';

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


## ●キャラクターシートの各種初期値

## ●能力値・技能
  our %skill = (
    "Str" => [ "格闘","力技","重武器","水泳","頑健" ],
    "Ref" => [ "軽武器","運動","隠密","回避","騎乗" ],
    "Per" => [ "射撃","手業","知覚","霊感" ],
    "Int" => [ "治療","混沌知識","聖印知識","軍略知識","専門知識:","専門知識:" ],
    "Mnd" => [ "意志","聖印" ],
    "Emp" => [ "話術","感性","情報収集","芸術:","芸術:" ],
  ); 
  our %sttE2J = (
    "Str" => '筋力',
    "Ref" => '反射',
    "Per" => '感覚',
    "Int" => '知力',
    "Mnd" => '精神',
    "Emp" => '共感',
  );
  our %peerageRank = (
    '騎士'  => { lv=>  1, counts=>  1000 },
    '男爵'  => { lv=>  5, counts=>  5000 },
    '子爵'  => { lv=> 10, counts=> 10000 },
    '伯爵'  => { lv=> 30, counts=> 30000 },
    '辺境伯'=> { lv=> 50, counts=> 50000 },
    '侯爵'  => { lv=>100, counts=>100000 },
    '公爵'  => { lv=>200, counts=>200000 },
    '大公'  => { lv=>300, counts=>300000 },
  );

## ●保存時の送信モード
 # Base64にして送信するかどうか
 #（ロリポップなどでファイアウォールに引っ掛かる場合、「1」（=ON）にする）
  our $base64mode = 0;

## ●Cookie
 # Cookieの名前
  our $cookie = 'ytsheet2';

## ●各種ファイルへのパス
  our $sendmail = '/usr/sbin/sendmail'; # sendmailのパス
  our $admimail = 'noreply@yutorize.2-d.jp'; # 管理者メールアドレス
  
  our $data_dir = './data/'; # データ格納ディレクトリ
  our $passfile = $data_dir . 'charpass.cgi'; # パスワード記録ファイル
  our $listfile = $data_dir . 'charlist.cgi'; # キャラクター一覧ファイル
  our $char_dir = $data_dir . 'chara/'; # キャラクターデータ格納ディレクトリ
  
  our $userfile    = $::core_dir . '/data/users.cgi';           # ユーザー一覧ファイル
  our $login_users = $::core_dir . '/data/login_users.cgi'; # ログイン情報保存ファイル
  our $tokenfile   = $::core_dir . '/data/token.cgi';       # 一時トークン保存ファイル
  
  our $lib_form     = $::core_dir . '/lib/form.pl';
  our $lib_info     = $::core_dir . '/lib/info.pl';
  our $lib_register = $::core_dir . '/lib/register.pl';
  our $lib_reminder = $::core_dir . '/lib/reminder.pl';
  our $lib_delete   = $::core_dir . '/lib/delete.pl';
  
  our $lib_others   = $::core_dir . '/lib/others.pl';

  # 編集画面
  our $lib_edit = $::core_dir . '/lib/edit.pl';
  our $lib_edit_char = $::core_dir . '/lib/gc/edit-chara.pl';
  # 保存処理
  our $lib_save   = $::core_dir . '/lib/save.pl';
  our $lib_calc_char = $::core_dir . '/lib/gc/calc-chara.pl';
  # シート表示
  our $lib_view   = $::core_dir . '/lib/view.pl';
  our $lib_view_char = $::core_dir . '/lib/gc/view-chara.pl';
  # チャットパレット
  our $lib_palette     = $::core_dir . '/lib/palette.pl';
  our $lib_palette_sub = $::core_dir . '/lib/gc/palette-sub.pl';
  # 一覧
  our $lib_list_char = $::core_dir . '/lib/gc/list-chara.pl';
  # JSON出力
  our $lib_json     = $::core_dir . '/lib/json.pl';
  our $lib_json_sub = $::core_dir . '/lib/gc/json-sub.pl';
  # コンバート
  our $lib_convert = $::core_dir . '/lib/gc/convert.pl';

  # 各種データ
  our $data_class = $::core_dir . '/lib/gc/data-class.pl';  # クラス

  # HTMLテンプレート
  our $icon_dir   = $::core_dir . '/skin/gc/img/'; # 武器アイコンのあるディレクトリ
  our $skin_tmpl  = $::core_dir . '/skin/gc/index.html';         # 一覧／登録フォーム等の大枠
  our $skin_sheet = $::core_dir . '/skin/gc/sheet-chara.html';   # キャラクターシート
  
  # 国管理シートの設定
  our %lib_type = (
    'c' => {
      listFile => $data_dir . 'countrylist.cgi',
      dataDir => $data_dir . 'country/',
      edit => $::core_dir . '/lib/gc/edit-country.pl',
      calc => $::core_dir . '/lib/gc/calc-country.pl',
      view => $::core_dir . '/lib/gc/view-country.pl',
      list => $::core_dir . '/lib/gc/list-country.pl',
      skin => $::core_dir . '/skin/gc/sheet-country.html',
      sheetType => 'country',
    },
  );

# シート初期値の変更
our %customizedInitialValues = (
    # キャラクターデータ
    '' => {
        # 例：「キャラクター名」の初期値を「unnamed」にする
        # 'characterName' => 'unnamed',
    },

    # 国データ
    c => {
        # 例：「作成時爵位」の初期値を「子爵」にする
        # 'makePeerage' => '子爵',
    },
);

1;