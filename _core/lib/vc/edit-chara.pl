############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'signatures';
no warnings 'experimental::signatures';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_races;
require $set::data_class;

my @races   = data::raceNameList();
my @classes = data::classNameList();
my @styles  = data::styleNameList();

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{characterName} || $pc{aka} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{playerName} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode eq 'convert' && $pc{ver})){
  %pc = upgradeCharaData(\%pc);
  if($pc{updateMessage}){
    $message .= "<hr>" if $message;
    $message .= "<h2>アップデート通知</h2><dl>";
    foreach (sort keys %{$pc{updateMessage}}){
      $message .= '<dt>'.$_.'</dt><dd>'.$pc{updateMessage}{$_}.'</dd>';
    }
    $message .= "</dl><small>前回保存時のバージョン:$pc{lasttimever}</small>";
  }
}
elsif($::mode eq 'blanksheet'){
  $pc{group} = $set::group_default;

  $pc{history0Result} = $set::make_exp || 0;

  $pc{level} = 1;

  $pc{paletteUseVar} = 1;
  $pc{paletteUseBuff} = 1;

  %pc = applyCustomizedInitialValues(\%pc, '');
}

## 画像・セリフ位置
setDefaultImageStyle(\%pc);
setDefaultWordsPosition(\%pc);

## カラー
setDefaultColors(\%pc);

## その他
$pc{goodsNum}   ||= 2;
$pc{itemNum}    ||= 2;
$pc{historyNum} ||= 3;

### 折り畳み判断 --------------------------------------------------
my %open;
$open{skills} = 'open';

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/freeNote freeHistory chatPalette/,
  ( map { 'words'.$_ } '', 2 .. ($set::image_maxcount || 1) ),
);

### パラメータ定義 --------------------------------------------------
my @battleParams = qw(Acc Spl Eva Atk Det Def Mdf Ini Str);

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ($pc{characterName} || qq|“$pc{aka}”|)),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>キャラ<span class="shorten">クター</span></span><span>データ</span>
    <li onclick="sectionSelect('palette');" class="unit-setting"><span><span class="shorten">ユニット(</span>コマ<span class="shorten">)</span></span><span>設定</span>
  HTML
);
print qq|<aside class="message">$message</aside>| if $message;

print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box" id="group">
      <dl>
        <dt>グループ<dd><select name="group">
        @{[ renderGroupOptions ]}
        </select>
        <dt>タグ<dd>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="キャラクター名・プレイヤー名">
      <div>
        <dl id="character-name">
          <dt>キャラクター名
          <dd>@{[ input 'characterName','text',"setName",'id="main-name"' ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>プレイヤー名
        <dd>@{[ input 'playerName' ]}
      </dl>
    </div>

    <div id="area-status">
      @{[ renderImageForm() ]}

      <div id="levels">
        <dl class="box">
          <dt class="in-toc">戦果点</dt>
          <dd>
            @{[ input 'history0Result', 'number','calcResultPoint' ]}
            + <span id="resultpoint-history">0</span>
            - <span id="resultpoint-cost">0</span>
            = <b id="resultpoint-total">0</b>
          </dd>
        </dl>
        <dl class="box">
          <dt class="in-toc">レベル
          <dd>@{[ input 'level', 'number', 'calcBattle' ]}
        </dl>
      </div>

      <div id="personal">
        <div class="box-union" class="in-toc" data-content-title="種族・クラス">
          <dl class="box" id="">
            <dt>種族
            <dd>@{[ selectInput 'race','',@races ]}
          </dl>
          <dl class="box" id="">
            <dt>クラス
            <dd>@{[ selectInput 'class','',@classes ]}
          </dl>
        </div>

        <div class="box-union">
          <dl class="box" id="">
            <dt class="in-toc">スタイル
            <dd>@{[ selectInput 'style1','',@styles ]}
            <dd>@{[ selectInput 'style2','',@styles ]}
          </dl>
        </div>
      </div>

      <div class="box" id="appearance">
        <h2 class="in-toc">キャラクター外見</h2>
        <dl class="">
          <dt>性別
          <dd>@{[ input 'gender','','','list="list-gender"' ]}
          <dt>年齢
          <dd>@{[ input 'age' ]}
          <dt>瞳の色
          <dd>@{[ input 'eye' ]}
          <dt>肌の色
          <dd>@{[ input 'skin' ]}
          <dt>髪の色
          <dd>@{[ input 'hair' ]}
          <dt>身長
          <dd>@{[ input 'height' ]}
        </dl>
      </div>

      <div id="status">
        <div class="box" id="user-status">
          <h2 class="in-toc">能力値</h2>
          <dl class="">
            <dt>バイタリティ
            <dd>@{[ input 'vitality','number','calcStatus' ]}
            <dt>テクニック
            <dd>@{[ input 'technic','number' ]}
            <dt>クレバー
            <dd>@{[ input 'clever','number' ]}
            <dt>カリスマ
            <dd>@{[ input 'carisma','number' ]}
          </dl>
        </div>
        <div class="box-union in-toc" id="hp-and-stamina" data-content-title="ＨＰ・スタミナ">
          <dl class="box" id="hp">
            <dt>ＨＰ
            <dd>
              +@{[ input 'hpAdd','number','calcBattle' ]}=
              <b id="hp-value">0</b>
            </dd>
          </dl>
          <dl class="box" id="stamina">
            <dt>スタミナ
            <dd>
              +@{[ input 'staminaAdd','number','calcStatus' ]}=
              <b id="stamina-value">0</b> <small>(半分:<span id="stamina-half">0</span>)</small>
            </dd>
          </dl>
        </div>
      </div>
    </div>


    <div class="box" id="specialities" $open{specialities}>
      <h2 class="in-toc">特技</h2>
      <table class="edit-table no-border-cells" id="speciality-table">
        <thead>
          <tr><th>名称<th class="left">効果
        </thead>
        <tbody>
          <tr id="skill1">
            <td>@{[ input "speciality1Name" ]}
            <td>@{[ input "speciality1Note" ]}
          <tr id="skill2">
            <td>@{[ input "speciality2Name" ]}
            <td>@{[ input "speciality2Note" ]}
          </tr>
        </tbody>
      </table>
    </div>

    <div class="box" id="goods" $open{goods}>
      <h2 class="in-toc">グッズ</h2>
      <table class="edit-table no-border-cells" id="goods-table">
        <thead>
          <tr><th><th>名称<th>種別<th>戦果点<th>効果
        <tbody>
        @{[ renderTemplateLoop(
          'goods',
          sub ($num) {
            return <<~"ROW";
            <tr id="goods-row${num}">
              <td class="handle">
              <td>@{[ input "goods${num}Name" ]}
              <td>@{[ input "goods${num}Type",'','','list="list-goods-type"' ]}
              <td>@{[ input "goods${num}Cost",'number','calcResultPoint' ]}
              <td>@{[ input "goods${num}Note" ]}
            ROW
          }
        ) ]}
      </table>
      @{[ renderAddDelButtons('goods') ]}
    </div>

    <div class="box" id="battle">
      <h2 class="in-toc">戦闘値表</h2>
      <table class="edit-table no-border-cells">
        <colgroup>
          <col class="head">
          <col class="name">
          @{[ map { qq|<col class="\L$_">| } @battleParams ]}
        </colgroup>
        <thead>
          <tr>
            <th colspan="2">
            <th>命中値
            <th>詠唱値
            <th>回避値
            <th>攻撃値
            <th>意志値
            <th>物防値
            <th>魔防値
            <th>行動値
            <th>耐久値
          </tr>
        <tbody>
          <tr>
            <th colspan="2" class="right">基本戦闘値
            @{[ map { '<td>'. (input "battleBase$_", 'number','calcBattle') } @battleParams ]}
          <tr>
            <th>種族特性
            <td>@{[ input "battleRaceName" ]}
            @{[  map { '<td>'. (input "battleRace$_", 'number','calcBattle') } @battleParams ]}
          <tr class="subtotal">
            <th colspan="2" class="right">小計
            @{[  map { qq|<td id="battle-subtotal-\L$_">| } @battleParams ]}
          @{[
            map {
              my $th = $_->[1];
              my $id = $_->[0];
              '<tr>'
              . '<th>'. (length($th) > 3 ? "<span>$th</span>" : $th)
              . '<td>'. (input "battle${id}Name")
              . join('', map { '<td>'. (input "battle${id}$_", 'number','calcBattle') } @battleParams)
            } (
              ['Weapon', '武器'   ],
              ['Head'  , '頭防具' ],
              ['Body'  , '胴防具' ],
              ['Acc1'  , '装飾品' ],
              ['Acc2'  , '装飾品' ],
            )
          ]}
          <tr>
            <th colspan="2" class="right">その他修正
            @{[ map { '<td>'. (input "battleOther$_", 'number','calcBattle') } @battleParams ]}
          <tr>
            <th colspan="2" class="right">キャラクターレベル
            <td colspan="9" id="battle-level-value">
          <tr class="total">
            <th colspan="2" class="right">合計
            @{[ map { qq|<td id="battle-total-\L$_">0| } @battleParams ]}
          </tr>
        </tbody>
      </table>
    </div>

    <div class="box" id="items" $open{items}>
      <h2 class="in-toc">アイテム</h2>
      <table class="edit-table no-border-cells" id="items-table">
        <thead>
          <tr><th><th>名称<th>種別<th>レベル<th>戦果点<th>効果
        <tbody>
          @{[ renderTemplateLoop(
            'item',
            sub ($num) {
              return <<~"ROW";
              <tr id="item-row${num}">
                <td class="handle">
                <td>@{[ input "item${num}Name" ]}
                <td>@{[ input "item${num}Type",'','','list="list-item-type"' ]}
                <td>@{[ input "item${num}Lv"  ,'number' ]}
                <td>@{[ input "item${num}Cost",'number','calcResultPoint' ]}
                <td>@{[ input "item${num}Note" ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('item') ]}
    </div>

    <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
      <summary class="in-toc">設定・メモ</summary>
      <textarea name="freeNote">$pc{freeNote}</textarea>
      @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeNote\')">最新のメモを適用する</button>' : '' ]}
    </details>

    <details class="box" id="free-history" @{[$pc{freeHistory}?'open':'']}>
      <summary class="in-toc">履歴（自由記入）</summary>
      <textarea name="freeHistory">$pc{freeHistory}</textarea>
      @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeHistory\')">最新の履歴（自由記入）を適用する</button>' : '' ]}
    </details>

    <div class="box" id="history">
      <h2 class="in-toc">セッション履歴</h2>
      <table class="edit-table line-tbody no-border-cells" id="history-table">
        <thead id="history-head">
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="result">戦果点
            <th class="gm    ">GM
            <th class="member">参加者
          <tr>
            <td>-
            <td>
            <td>キャラクター作成
            <td id="history0-exp">$pc{history0Exp}
            <td>
            <td id="history0-money">$pc{history0Money}
          </tr>
        @{[ renderTemplateLoop(
          'history',
          sub ($num) {
            return <<~"ROW";
            <tbody id="history-row${num}">
              <tr>
                <td class="handle" rowspan="2">
                <td class="date  " rowspan="2">@{[ input "history${num}Date" ]}
                <td class="title " rowspan="2">@{[ input "history${num}Title" ]}
                <td class="result">@{[ input "history${num}Result",'text','calcResultPoint' ]}
                <td class="gm    ">@{[ input "history${num}Gm" ]}
                <td class="member">@{[ input "history${num}Member" ]}
              <tr>
                <td colspan="6" class="left">@{[ input "history${num}Note",'','','placeholder="備考"' ]}
            ROW
          }
        ) ]}
        <tfoot id="history-foot">
          <tr>
            <td>
            <td>
            <td>取得総計
            <td id="history-result-total">
            <td colspan="2">
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="result">戦果点
            <th class="gm    ">GM
            <th class="member">参加者
          </tr>
        </tfoot>
      </table>
      @{[ renderAddDelButtons('history') ]}
      <h2>記入例</h2>
      <table class="example edit-table line-tbody no-border-cells">
        <thead>
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="result">戦果点
            <th class="gm    ">GM
            <th class="member">参加者
        <tbody>
          <tr>
            <td>-
            <td><input type="text" value="2019/07/02" disabled>
            <td><input type="text" value="第十四話「記入例」" disabled>
            <td><input type="text" value="5*14" disabled>
            <td><input type="text" value="サンプルさん" disabled>
            <td><input type="text" value="アルバート　ラミミ　ブランヘルツ　ジャ・ルマレ　ナイユベール" disabled>
          </tr>
        </tbody>
      </table>
      <ul class="annotate">
        <li>戦果点欄は<code>5*2</code>など四則演算が有効です。
      </ul>
      @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
    </div>

    <div class="box" id="exp-footer">
      <p>
      戦果点[<b id="result-total"></b>] -
      ( グッズ[<b id="result-used-goods"></b>]
      + アイテム[<b id="result-used-items"></b>]
      ) = 残り[<b id="result-rest"></b>]点
      </p>
    </div>
  </section>
HTML
print renderChatPaletteForm();

print renderEditPageEnd(
  notes => '©FarEast Amusement Research Co.,Ltd.「ヴィジョンコネクト」',
  extraHtml => renderDataList(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="その他">
    <option value="なし">
    <option value="不明">
    <option value="不詳">
  </datalist>
  <datalist id="list-goods-type">
    <option value="一般">
    <option value="デバイス">
    <option value="サポーター">
  </datalist>
  <datalist id="list-item-type">
    <option value="武器">
    <option value="頭防具">
    <option value="胴防具">
    <option value="装飾品">
    <option value="薬品">
    <option value="料理">
  </datalist>
  HTML
}

1;
