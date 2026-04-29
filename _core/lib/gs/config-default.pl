################# デフォルト設定 #################
use strict;
use utf8;

package set;

require $::core_dir . '/lib/config-default.pl';

our $game = 'gs';

# config.cgiのほうが優先されます
# 変更する場合は同様の項目をconfig.cgiに追記してください
# （CGIアップデート時に上書きされるため）
  
## ●タイトル
  our $title = 'ゆとシートⅡ for GB';


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


## ●キャラクターシートの各種初期値
  our $make_exp   = 3000;
  our $make_adp   = 0;
  our $make_money = 100;
  our $make_fix   = 0;


## ●等級
  our @adventurer_rank = (
    ['白磁等級','第十位'],
    ['黒曜等級','第九位'],
    ['鋼鉄等級','第八位'],
    ['青玉等級','第七位'],
    ['翠玉等級','第六位'],
    ['紅玉等級','第五位'],
    ['銅等級','第四位'],
    ['銀等級','第三位'],
    ['金等級','第二位'],
    ['白金等級','第一位'],
  );
  our @adventurer_rank_name;
  push (@adventurer_rank_name, @$_[0]) foreach (@adventurer_rank);


## ●信仰リスト
  our @faith = (
    [ '戦女神', '秩序の神'],
    [ '地母神', '秩序の神'],
    [ '至高神', '秩序の神'],
    [ '交易神', '秩序の神'],
    [ '知識神', '秩序の神'],
    [ '正道神', '秩序の神'],
    [ '酒造神', '秩序の神'],
    [ '鍛冶神', '秩序の神'],
    [ '太陽神', '秩序の神'],
    [ '奪掠神', '混沌の神'],
    [ '嗜虐神', '混沌の神'],
    [ '覚知神', '外なる神'],
    [ '死灰神', '外なる神'],
    [ '祖竜', 'その他の信仰'],
    [ '祖霊', 'その他の信仰'],
  );
  our @faith_name;
  push (@faith_name, @$_[0]) foreach (@faith);

## ●武器カテゴリリスト
our @weapons = (
  ['片手剣'  , 'Melee'],
  ['両手剣'  , 'Melee'],
  ['斧'      , 'Melee'],
  ['槍'      , 'Melee'],
  ['戦鎚'    , 'Melee'],
  ['棍杖'    , 'Melee'],
  ['格闘武器', 'Melee'],
  ['投擲武器', 'Throwing'],
  ['弩弓'    , 'Projectile'],
);

our @weapon_names;
our %weapon_type;
foreach (@weapons){
  push (@weapon_names, @$_[0]);
  $weapon_type{@$_[0]} = @$_[1];
}

## ●メイキング
  our $making_max = 0; # 作成板の最大保存数（0で無制限）
  our $average_over = 0;
  our $adventurer_onlyonce = 0;
  our $making_interval = 0;

## ●特殊ハウスルール向け
 # 戦闘用アイテム欄
 # our $battleitem = 1;

 # 成長タイプ O=1000毎 ／ A=1000＋(10*成長回数)
 # our $growtype = '';


## ●各種ファイルへのパス
  our $data_dir = './data/'; # データ格納ディレクトリ
  our $passfile = $data_dir . 'charpass.cgi'; # パスワード記録ファイル
  our $listfile = $data_dir . 'charlist.cgi'; # キャラクター一覧ファイル
  our $makelist = $data_dir . 'makelist.cgi'; # 能力値作成データファイル
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
  our $lib_edit_char = $::core_dir . '/lib/gs/edit-chara.pl';
  # 保存処理
  our $lib_save   = $::core_dir . '/lib/save.pl';
  our $lib_calc_char = $::core_dir . '/lib/gs/calc-chara.pl';
  # シート表示
  our $lib_view   = $::core_dir . '/lib/view.pl';
  our $lib_view_char = $::core_dir . '/lib/gs/view-chara.pl';
  # チャットパレット
  our $lib_palette     = $::core_dir . '/lib/palette.pl';
  our $lib_palette_sub = $::core_dir . '/lib/gs/palette-sub.pl';
  # 一覧
  our $lib_list_char = $::core_dir . '/lib/gs/list-chara.pl';
  # JS
  our $lib_js_consts = $::core_dir . '/lib/gs/js-consts.pl';
  # JSON出力
  our $lib_json     = $::core_dir . '/lib/json.pl';
  our $lib_json_sub = $::core_dir . '/lib/gs/json-sub.pl';
  # コンバート
  our $lib_convert = $::core_dir . '/lib/gs/convert.pl';

  # 各種データ
  our $data_races = $::core_dir . '/lib/gs/data-races.pl';  # 種族
  our $data_class = $::core_dir . '/lib/gs/data-class.pl';  # 職業

  # HTMLテンプレート
  our $icon_dir   = $::core_dir . '/skin/gs/img/'; # 武器アイコンのあるディレクトリ
  our $skin_tmpl  = $::core_dir . '/skin/gs/index.html';         # 一覧／登録フォーム等の大枠
  our $skin_sheet = $::core_dir . '/skin/gs/sheet-chara.html';   # キャラクターシート

# シート初期値の変更
our %customizedInitialValues = (
    '' => {
        # 例：「キャラクター名」の初期値を「unnamed」にする
        # 'characterName' => 'unnamed',
    },
);

1;