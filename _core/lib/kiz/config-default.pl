################# デフォルト設定 #################
use strict;
use utf8;

package set;

require $::core_dir . '/lib/config-default.pl';

our $game = 'kiz';

# config.cgiのほうが優先されます
# 変更する場合は同様の項目をconfig.cgiに追記してください
# （CGIアップデート時に上書きされるため）
  
## ●タイトル
  our $title = 'ゆとシートⅡ for KIZ';


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
  our $make_endurance  = 0;
  our $make_initiative = 0;


## ●各種ファイルへのパス
  our $data_dir = './data/'; # データ格納ディレクトリ
  our $passfile = $data_dir . 'charpass.cgi'; # パスワード記録ファイル
  our $listfile = $data_dir . 'charlist.cgi'; # キャラクター一覧ファイル
  our $char_dir = $data_dir . 'chara/'; # キャラクターデータ格納ディレクトリ

  our $lib_edit_char   = $::core_dir . '/lib/kiz/edit-chara.pl';  # 編集画面
  our $lib_calc_char   = $::core_dir . '/lib/kiz/calc-chara.pl';  # 保存処理
  our $lib_view_char   = $::core_dir . '/lib/kiz/view-chara.pl';  # シート表示
  our $lib_palette_sub = $::core_dir . '/lib/kiz/palette-sub.pl'; # チャットパレット
  our $lib_list_char   = $::core_dir . '/lib/kiz/list-chara.pl';  # 一覧
  our $lib_json_sub    = $::core_dir . '/lib/kiz/json-sub.pl';    # JSON出力
  our $lib_convert     = $::core_dir . '/lib/kiz/convert.pl';     # コンバート

  # 各種データ

  # HTMLテンプレート
  our $skin_tmpl  = $::core_dir . '/skin/kiz/index.html';      # 一覧／登録フォーム等の大枠
  our $skin_sheet = $::core_dir . '/skin/kiz/sheet-chara.html';   # キャラクターシート

# シート初期値の変更
our %customizedInitialValues = (
    '' => {
        # 例：「キャラクター名」の初期値を「unnamed」にする
        # 'characterName' => 'unnamed',
    },
);

1;