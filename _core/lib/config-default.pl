################# デフォルト設定：全体 #################
use strict;
use utf8;

package set;

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
 # トップページのキャラクター最大表示数（1グループあたり／無制限=0）
  our $list_maxline = 0;
 # グループ個別表示時や検索結果表示時の1ページあたりの最大表示数（0で全部表示）
  our $pagemax = 0;


## ●保存時の送信モード
 # Base64にして送信するかどうか
 #（ロリポップなどでファイアウォールに引っ掛かる場合、「1」（=ON）にする）
  our $base64mode = 0;


## ●Cookie
 # Cookieの名前
  our $cookie = 'ytsheet2';


## ●sendmail
  our $sendmail = '/usr/sbin/sendmail'; # sendmailのパス
  our $admimail = 'noreply@yutorize.work'; # 管理者（システムメールの送信元）メールアドレス


## ●フォント
  our @googlefonts = (
    ['Kaisei Tokumin',700],
    ['Kaisei HarunoUmi',700],
    ['Kaisei Opti',  700],
    ['Kaisei Decol',  700],
    ['Hina Mincho',   'bold'],
    ['Yuji Syuku',    'bold'],
    ['Yuji Boku',     'bold'],
    ['Yuji Mai',      'bold'],
    ['Klee One',      'bold'],
    ['Zen Kurenaido', 'bold'],
    ['Zen Maru Gothic',700],
    ['Kiwi Maru',     'bold'],
    ['M PLUS Rounded 1c',700],
    ['Noto Sans JP',  700],
    ['Stick',         'normal'],
    ['RocknRoll One', 'normal'],
    ['Reggae One',    'normal'],
    ['Yusei Magic',   'normal'],
    ['Hachi Maru Pop','bold'],
    ['Mochiy Pop One','normal'],
    ['Potta One',     'normal'],
    ['Dela Gothic One','normal'],
    ['Rampart One',   'bold'],
    ['DotGothic16',   'normal'],
    ['WDXL Lubrifont JP N','normal'],
  );

1;