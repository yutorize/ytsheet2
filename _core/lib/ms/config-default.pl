################# デフォルト設定 #################
use strict;
use utf8;

package set;

require $::core_dir . '/lib/config-default.pl';

our $game = 'ms';

# config.cgiのほうが優先されます
# 変更する場合は同様の項目をconfig.cgiに追記してください
# （CGIアップデート時に上書きされるため）
  
## ●タイトル
  our $title = 'ゆとシートⅡ for マモノスクランブル';


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
  
  our @groups_clan = ();
  our $group_clan_default = '';


## ●キャラクターシートの各種初期値
  our $make_endurance  = 0;
  our $make_initiative = 0;


## ●各種ファイルへのパス
  our $data_dir = './data/'; # データ格納ディレクトリ
  our $passfile = $data_dir . 'charpass.cgi'; # パスワード記録ファイル
  our $listfile = $data_dir . 'charlist.cgi'; # キャラクター一覧ファイル
  our $char_dir = $data_dir . 'chara/'; # キャラクターデータ格納ディレクトリ

  our $lib_edit_char   = $::core_dir . '/lib/ms/edit-chara.pl';  # 編集画面
  our $lib_calc_char   = $::core_dir . '/lib/ms/calc-chara.pl';  # 保存処理
  our $lib_view_char   = $::core_dir . '/lib/ms/view-chara.pl';  # シート表示
  our $lib_palette_sub = $::core_dir . '/lib/ms/palette-sub.pl'; # チャットパレット
  our $lib_list_char   = $::core_dir . '/lib/ms/list-chara.pl';  # 一覧
  our $lib_js_consts   = $::core_dir . '/lib/ms/js-consts.pl';   # JS固定値
  our $lib_json_sub    = $::core_dir . '/lib/ms/json-sub.pl';    # JSON出力

  # 各種データ
  our $data_magi = $::core_dir . '/lib/ms/data-magi.pl';

  # HTMLテンプレート
  our $skin_tmpl  = $::core_dir . '/skin/ms/index.html';      # 一覧／登録フォーム等の大枠
  our $skin_sheet = $::core_dir . '/skin/ms/sheet-chara.html';   # キャラクターシート
  
  # クランシートの設定
  our %lib_type = (
    'c' => {
      listFile => $data_dir . 'clanlist.cgi',
      dataDir => $data_dir . 'clan/',
      edit => $::core_dir . '/lib/ms/edit-clan.pl',
      calc => $::core_dir . '/lib/ms/calc-clan.pl',
      view => $::core_dir . '/lib/ms/view-clan.pl',
      list => $::core_dir . '/lib/ms/list-clan.pl',
      skin => $::core_dir . '/skin/ms/sheet-clan.html',
      sheetType => 'clan',
    },
  );

# シート初期値の変更
our %customizedInitialValues = (
    # キャラクターデータ
    '' => {
        # 例：「キャラクター名」の初期値を「unnamed」にする
        # 'characterName' => 'unnamed',
    },

    # クランデータ
    c => {
        # 例：「クラン名」の初期値を「unnamed」にする
        # 'clanName' => 'unnamed',
    },
);

1;