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

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{guildName} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{playerName} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode =~ /^(?:convert|copy)$/ && $pc{ver})){
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

  $pc{makeLv} = 1;
  
  $pc{moneyAuto} = 1;

  %pc = applyCustomizedInitialValues(\%pc, 'g');
}

## カラー
setDefaultColors(\%pc);

## その他
$pc{memberNum}       ||= 3;
$pc{guildSupportNum} ||= 2;
$pc{historyNum}      ||= 3;

### 折り畳み判断 --------------------------------------------------
my %open;
foreach (1..$pc{memberNum}){ if($pc{"member${_}Name"}){ $open{members} = 'open'; last; } }
foreach (1..$pc{academySupportNum}){ if($pc{"academySupport${_}Name"} || $pc{"academySupport${_}Cost"}){ $open{academySupports} = 'open'; last; } }
foreach (1..$pc{artifactNum}){ if($pc{"artifact${_}Name"} || $pc{"artifact${_}Cost"}){ $open{artifacts} = 'open'; last; } }
foreach (1..$pc{characteristicNum}){ if($pc{"characteristic${_}Name"}){ $open{characteristics} = 'open'; last; } }
foreach (1..$pc{forceNum}){ if($pc{"force${_}Type"}){ $open{forces} = 'open'; last; } }

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/items cashbook freeNote freeHistory chatPalette/,
);

### 画像 --------------------------------------------------
my $imageMaxSize = $set::image_maxsize / 2;
my $imageMaxSizeView = $imageMaxSize >= 1048576 ? sprintf("%.3g",$imageMaxSize/1048576).'MB' : sprintf("%.3g",$imageMaxSize/1024).'KB';

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ( $pc{guildName} )),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>ギルド</span></span><span>データ</span>
  HTML
);
print qq|<aside class="message">$message</aside>| if $message;

print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box" id="group">
      <dl>
        ${\ do {
          if(@set::groups_guild) {
            <<~"HTML";
              <dt>グループ
              <dd><select name="group">@{[ renderGroupOptions(@set::groups_guild) ]}</select>
            HTML
          }
          else { "" }
        } }
        <dt>タグ
        <dd @{[ @set::groups_guild ? '' : 'style="grid-column:span 3;"' ]}>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="国名・ロード名・プレイヤー名">
      <div>
        <dl id="character-name">
          <dt>ギルド名
          <dd>@{[ input 'guildName','text',"setName",'id="main-name" required' ]}
          <dt>ギルドマスター名
          <dd>@{[ input 'masterName']}
        </dl>
      </div>
      <dl id="player-name">
        <dt>プレイヤー名
        <dd>@{[ input 'playerName' ]}
      </dl>
    </div>

    <details class="box" id="regulation" @{[$::mode eq 'edit' ? '':'open']}>
      <summary class="in-toc">作成レギュレーション</summary>
      <dl>
        <dt>作成時ギルドレベル
        <dd>@{[ input 'makeLv','number','calcExp' ]}
        <dt>備考
        <dd>@{[ input "history0Note" ]}
      </dl>
    </details>

    <details class="box" id="members" open>
      <summary class="in-toc">ギルドメンバー</summary>
      <table class="edit-table no-border-cells">
        <colgroup>
          <col class="handle">
          <col class="name  ">
          <col class="url   ">
          <col class="cl    ">
          <col class="race  ">
          <col class="mclass">
          <col class="sclass">
          <col class="player">
          <col class="note  ">
        </colgroup>
        <thead>
          <tr>
            <th>
            <th class="name  ">キャラクター名
            <th class="url   "><span class="small">シートURL</span>
            <th class="cl    ">CL
            <th class="race  ">種族
            <th class="mclass"><span class="small">メインクラス</span>
            <th class="sclass"><span class="small">サポートクラス</span>
            <th class="player"><span class="small">プレイヤー名</span>
            <th class="note left">備考
        <tbody>
          @{[ renderTemplateLoop(
            'member',
            sub ($num) {
              return <<~"ROW";
              <tr id="member-row${num}">
                <td class="handle">
                <td class="name  ">@{[ input "member${num}Name" ]}
                <td class="url   ">@{[ input "member${num}URL",'url','setMemberData(this)' ]}<span class="refresh" onclick="setMemberData(this.previousElementSibling)"></span>
                <td class="cl    ">@{[ input "member${num}CL",'number' ]}
                <td class="race  ">@{[ input "member${num}Race" ]}
                <td class="mclass">@{[ input "member${num}MClass" ]}
                <td class="sclass">@{[ input "member${num}SClass" ]}
                <td class="player">@{[ input "member${num}Player" ]}
                <td class="note  ">@{[ input "member${num}Note" ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('member') ]}
      <ul class="annotate">
        <li>キャラクターシートURLを入力すると、自動的にURL先のデータを取得して各項目を入力します。
        <li><span class="material-symbols-outlined">refresh</span>ボタンを押すと、URLからデータを再取得します。
      </ul>
    </details>

    <details class="box" id="guild-supports" open>
      <summary class="in-toc">レベルアップ／取得ギルドサポート</summary>
      <table class="edit-table no-border-cells">
        <colgroup>
          <col class="gl    ">
          <col class="name  ">
          <col class="timing">
          <col class="lv    ">
          <col class="stack ">
          <col class="note  ">
          <col class="used  ">
          <col class="select">
        </colgroup>
        <thead>
          <tr>
            <th class="gl    "><span class="small">ギルド<br>レベル</small>
            <th class="name  ">名称
            <th class="timing">タイミング
            <th class="lv    "><span class="small">レベル</small>
            <th class="stack ">重複
            <th class="note left">効果
            <th class="used  "><span class="small">使用<br>チェック</small>
            <th class="select">選択
        <tbody>
          @{[ renderTemplateLoop(
            'guild-support',
            sub ($num) {
              return <<~"ROW";
              <tr id="guild-support-row${num}">
                <th class="gl handle">
                <td class="name  ">@{[ input "guildSupport${num}Name" ]}
                <td class="timing">@{[ input "guildSupport${num}Timing",'','','list="list-timing"' ]}
                <td class="lv    ">@{[ input "guildSupport${num}Lv",'number' ]}
                <td class="stack ">@{[ selectBox "guildSupport${num}Stackable",'','○','×' ]}
                <td class="note  ">@{[ input "guildSupport${num}Note" ]}
                <td class="used  ">@{[ checkbox "guildSupport${num}Used",'' ]}
                <td class="select">@{[ checkbox "guildSupport${num}Selected",'' ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('guild-support') ]}
      <p>
        現在成長点：<b id="exp-rest">0</b>　消費成長点：<b id="exp-used">0</b>
      </p>
      <ul class="annotate">
        <li>行を追加すると、自動的に成長点を消費してレベルアップします。
      </ul>
    </details>

    <div id="items-and-money">
      <dl class="box" id="money">
        <dt class="in-toc">ギルド管理金
        <dd>@{[ checkbox 'moneyAuto', '自動計算', 'calcCash' ]}
        <dd>@{[ input 'money' ]} G
      </dl>
      <div class="box" id="items">
        <h2 class="in-toc">ギルド管理アイテム</h2>
        <textarea name="items">$pc{items}</textarea>
      </div>
      <details class="box" id="cashbook" @{[ $pc{cashbook} || $pc{money} =~ /^(?:自動|auto)$/i ? 'open' : '' ]}>
        <summary class="in-toc">収支履歴</summary>
        <textarea name="cashbook" oninput="calcCash();" placeholder="例）冒険者セット::-10&#13;&#10;　　HPポーション売却::+15">$pc{cashbook}</textarea>
        <p>
          所持金：<span id="cashbook-total-value">$pc{moneyTotal}</span> G
        </p>
        <ul class="annotate">
          <li><code>::+n</code> <code>::-n</code>の書式で入力すると加算・減算されます。（<code>n</code>には金額を入れてください）
        </ul>
      </details>
    </div>

    <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
      <summary class="in-toc">ギルドの経歴・メモ</summary>
      <textarea name="freeNote">$pc{freeNote}</textarea>
      @{[ ($::in{log} || $::in{overwrite}) ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeNote\')">最新のメモを適用する</button>' : '' ]}
    </details>

    <details class="box" id="free-history" @{[$pc{freeHistory}?'open':'']}>
      <summary class="in-toc">履歴（自由記入）</summary>
      <textarea name="freeHistory">$pc{freeHistory}</textarea>
      @{[ ($::in{log} || $::in{overwrite}) ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeHistory\')">最新の履歴（自由記入）を適用する</button>' : '' ]}
    </details>

    <div class="box" id="history">
      <h2 class="in-toc">セッション履歴</h2>
      <table class="edit-table line-tbody no-border-cells" id="history-table">
        <colgroup id="history-col">
          <col>
          <col class="date  ">
          <col class="title ">
          <col class="exp   ">
          <col class="gm    ">
          <col class="member">
        </colgroup>
        <thead id="history-head">
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="exp   ">成長点
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
                <td class="exp   ">@{[ input "history${num}Exp",'','calcExp' ]}
                <td class="gm    ">@{[ input "history${num}Gm" ]}
                <td class="member">@{[ input "history${num}Member" ]}
              <tr>
                <td colspan="3" class="left">@{[ input "history${num}Note",'','','placeholder="備考"' ]}
            ROW
          }
        ) ]}
        <tfoot id="history-foot">
          <tr>
            <td>
            <td>
            <td>取得総計
            <td id="history-exp-total">
            <td colspan="2">
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="exp   ">成長点
            <th class="gm    ">GM
            <th class="member">参加者
          </tr>
        </tfoot>
      </table>
      @{[ renderAddDelButtons('history') ]}
      <h2>記入例</h2>
      <table class="example edit-table line-tbody no-border-cells">
        <colgroup id="history-col">
          <col>
          <col class="date  ">
          <col class="title ">
          <col class="exp">
          <col class="gm    ">
          <col class="member">
        </colgroup>
        <thead>
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="exp"   >成長点
            <th class="gm    ">GM
            <th class="member">参加者
        <tbody>
          <tr>
            <td>-
            <td><input type="text" value="2013/08/20" disabled>
            <td><input type="text" value="第一話「記入例」" disabled>
            <td><input type="text" value="5" disabled>
            <td><input type="text" value="サンプルさん" disabled>
            <td><input type="text" value="アルバート　ラミット　ブランデン　レンダ・レイ　ナイルベルト" disabled class="left">
          </tr>
        </tbody>
      </table>
      <ul class="annotate">
        <li>成長点欄は<code>1+2*2</code>など四則演算が有効です。<br>
      </ul>
      @{[ ($::in{log} || $::in{overwrite}) ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
    </div>
  </section>
HTML
print renderEditPageEnd(
  notes => '©FarEast Amusement Research Co.,Ltd.「アリアンロッドRPG 2E」',
  extraHtml => renderDataList() . renderFooterScript(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-timing">
    <option value="パッシブ">
    <option value="ムーブ">
    <option value="マイナー">
    <option value="メジャー">
    <option value="リアクション">
    <option value="フリー">
    <option value="レガシー">
    <option value="セットアップ">
    <option value="イニシアチブ">
    <option value="クリンナップ">
    <option value="判定の直前">
    <option value="判定の直後">
    <option value="DRの直前">
    <option value="DRの直後">
    <option value="《》">
    <option value="戦闘不能">
    <option value="アイテム">
    <option value="戦闘前">
    <option value="効果参照">
  </datalist>
  HTML
}

sub renderFooterScript {
  my %settings = (
    gameSystem => $set::game,
    styleNames => \@data::styleNames,
    worksNames => \@data::worksNames,
    styleData => \%data::styleData,
    worksData => \%data::worksData,
    peerageRank => \%set::peerageRank,
  );
  my $html;
  $html .= '<script>';
  $html .= 'const SET = '. JSON::PP->new->encode(\%settings) .';';
  $html .= '</script>';
  return $html;
}

1;
