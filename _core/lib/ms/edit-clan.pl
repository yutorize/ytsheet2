############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'signatures';
no warnings 'experimental::signatures';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::data_magi;
require $set::lib_palette_sub;

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{clanName} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{playerName} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode eq 'convert' && $pc{ver})){
  %pc = data_update_clan(\%pc);
  if($pc{updateMessage}){
    $message .= "<hr>" if $message;
    $message .= "<h2>アップデート通知</h2><dl>";
    foreach (sort keys %{$pc{updateMessage}}){
      $message .= '<dt>'.$_.'</dt><dd>'.$pc{updateMessage}{$_}.'</dd>';
    }
    (my $lasttimever = $pc{lasttimever}) =~ s/([0-9]{3})$/\.$1/;
    $message .= "</dl><small>前回保存時のバージョン:$lasttimever</small>";
  }
}
elsif($::mode eq 'blanksheet'){
  $pc{group} = $set::group_default;

  $pc{level} = 0;
  $pc{endurance} = 20;

  $pc{magi1}   = 'スクランブル！';

  %pc = applyCustomizedInitialValues(\%pc, 'c');
}

## 画像・セリフ位置
setDefaultImageStyle(\%pc);
setDefaultWordsPosition(\%pc);

## カラー
setDefaultColors(\%pc);

## その他
$pc{historyNum} ||= 3;
$pc{memberNum}  ||= 4;

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/freeNote freeHistory chatPalette/,
);

### 画像 --------------------------------------------------
my $image_maxsize = $set::image_maxsize / 2;
my $image_maxsize_view = $image_maxsize >= 1048576 ? sprintf("%.3g",$image_maxsize/1048576).'MB' : sprintf("%.3g",$image_maxsize/1024).'KB';

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ($pc{clanName})),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>クラン</span><span>データ</span>
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
          if(@set::groups_clan) {
            <<~"HTML";
                    <dt>グループ
                    <dd><select name="group">@{[ renderGroupOptions ]}</select>
            HTML
          }
        } }
        <dt>タグ
        <dd @{[ @set::groups_clan ? '' : 'style="grid-column:span 3;"' ]}>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box" id="support-hub">
      <div class="annotate"><a href="https://karasuba-sei.biz/officialsite/?p=88" target="_blank">⇒キャラクター作成の手順（サポートハブ）</a></div>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="クラン名・管理プレイヤー名">
      <div>
        <dl id="character-name">
          <dt>クラン名
          <dd>@{[ input 'clanName','text',"setName",'id="main-name" required' ]}
          <dt class="ruby">ふりがな
          <dd>@{[ input 'clanNameRuby','text',"setName" ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>管理プレイヤー名
        <dd>@{[ input 'playerName' ]}
      </dl>
    </div>

    <!--
    <details class="box" id="regulation" @{[$::mode eq 'edit' ? '':'open']} style="display:none">
      <summary>作成レギュレーション</summary>
      <dl>
        <dt>初期成長
        <dd id="level-pre-grow">
        <dt>強度
        <dd>
      </dl>
    </details>
    -->

    <div id="area-status">
      <div id="image" class="box">
        <h2>エンブレムなどの画像</h2>
        <p>
          プレビューエリアに画像ファイルをドロップ、<br>または
          <input type="file" accept="image/*" name="imageFile" onchange="imagePreView(this.files[0], $image_maxsize || 0)"><br>
          ※ ファイルサイズ @{[ $image_maxsize_view ]} までの JPG/PNG/GIF/WebP<br>
          <small>（サイズを超過する場合、自動的にWebP形式に変換し、その上でまだ超過している場合は縮小処理が行われます）</small>
          <input type="hidden" name="imageCompressed">
          <input type="hidden" name="imageCompressedType">
        </p>
        <p>
          <input type="checkbox" name="imageDelete" value="1"> 画像を削除する
          @{[ input 'image','hidden' ]}
        </p>
      <script>
        const imageType = 'symbol';
        let imgURL = "$pc{imageURL}";
      </script>
      </div>

      <dl id="level" class="box"><dt>強度<dd><b id="level-value">$pc{level}</b></dl>

      <div id="profile" class="box-union">
        <dl class="box" id="rule"        ><dt>ルール  <dd>@{[ input 'rule','','','list="list-clan-rule"' ]}</dl>
        <dl class="box" id="base"        ><dt>拠点    <dd>@{[ input 'base','','','list="list-clan-base"' ]}</dl>
        <dl class="box" id="belong"      ><dt>所属    <dd>@{[ input 'belong','','','list="list-clan-belong"' ]}</dl>
      </div>

      <div class="box" id="member">
        <h2>リーダー</h2>
        <table class="edit-table no-border-cells">
          <thead>
            <tr>
              <th>
              <th class="left small">リーダーのシートURL
          <tbody>
            <tr>
              <td class="name">@{[ input 'leaderName','','','placeholder="名前"' ]}
              <td class="url ">@{[ input 'leaderURL','','','placeholder="シートURL"' ]}
        </table>
        <h2>メンバー</h2>
        <table class="edit-table no-border-cells">
          <thead>
            <tr>
              <th>
              <th>
              <th class="left small">メンバーのシートURL
          <tbody id="member-tbody">
            @{[ renderTemplateLoop(
              'member',
              sub ($num) {
                return <<~"ROW";
                <tr id="member-row$num">
                  <th class="handle">
                  <td class="name">@{[ input "member${num}Name",'','','placeholder="名前"' ]}
                  <td class="url">@{[ input "member${num}URL",'','','placeholder="シートURL"' ]}
                ROW
              }
            ) ]}
        </table>
        @{[ renderAddDelButtons('member') ]}
      </div>

      <div class="box" id="attribute">
        <h2>特性</h2>
        <ul>
          @{[ map {
            qq|<li id="attribute$_">《|.(input 'attribute'.$_,'','checkAttribute').'》'
          } 1 .. 6 ]}
        </ul>
        <!-- @{[ renderAddDelButtons('attribute') ]} -->
        <div class="annotate caution"></div>
        <div class="annotate"><a href="https://karasuba-sei.biz/officialsite/?p=142" target="_blank">⇒特性の例（サポートハブ）</a></div>
      </div>

    </div>

    <div class="box" id="magi">
      <h2>マギ</h2>
      <table class="edit-table line-tbody no-border-cells" id="magi-table">
        <colgroup id="magi-col">
          <col class="name  ">
          <col class="check ">
          <col class="timing">
          <col class="target">
          <col class="cond  ">
          <col class="note  ">
        </colgroup>
        <thead id="magi-thead">
          <tr>
            <th class="name  ">名称
            <th class="check small nowrap">名前<br>変更
            <th class="timing">タイミング
            <th class="target">対象
            <th class="cond  ">条件
            <th class="note  ">効果
        @{[ map {
          my $num = $_;
          <<~"ROW"
          <tbody id="magi${num}">
            <tr>
              <td class="name  ">
                《@{[ selectBox "magi${num}",'checkMagi',@data::clanMagiNames,'その他' ]}》
                <div class="changed-name hidden">《@{[ input "magi${num}Name",'','','placeholder="任意の名前"' ]}》</div>
              <td class="check ">@{[ checkbox "magi${num}NC",'','checkMagi' ]}
              <td class="timing">@{[ input "magi${num}Timing" ,'','','list="list-timing"' ]}<div class="text-timing"></div>
              <td class="target">@{[ input "magi${num}Target" ,'','','list="list-target"' ]}<div class="text-target"></div>
              <td class="cond  ">@{[ input "magi${num}Cond"   ,'','','list="list-cond"'   ]}<div class="text-cond"></div>
              <td class="left">@{[ input "magi${num}Note" ]}<div class="text-note"></div>
          ROW
        } 1 .. 5 ]}
      </table>
      <div class="annotate caution"></div>
      <div class="annotate"><a href="https://karasuba-sei.biz/officialsite/?p=149#index_id2" target="_blank">⇒クラン用マギの一覧（サポートハブ）</a></div>
    </div>

    <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
      <summary>その他メモ</summary>
      <textarea name="freeNote">$pc{freeNote}</textarea>
      @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeNote\')">最新のメモを適用する</button>' : '' ]}
    </details>

    <details class="box" id="free-history" @{[$pc{freeHistory}?'open':'']}>
      <summary>履歴（自由記入）</summary>
      <textarea name="freeHistory">$pc{freeHistory}</textarea>
      @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeHistory\')">最新の履歴（自由記入）を適用する</button>' : '' ]}
    </details>

    <div class="box" id="history">
      <h2>セッション履歴</h2>
      <table class="edit-table line-tbody no-border-cells" id="history-table">
        <thead id="history-head">
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="level ">強度
            <th class="gm    ">GM
            <th class="member">参加者
          <!--
          <tr>
            <td>-
            <td>
            <td>キャラクター作成
            <td id="history0-exp">$pc{history0Exp}
          -->
        @{[ renderTemplateLoop(
          'history',
          sub ($num) {
            return <<~"ROW";
            <tbody id="history-row${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td class="date  " rowspan="2">@{[ input"history${num}Date" ]}
              <td class="title " rowspan="2">@{[ input"history${num}Title" ]}
              <td class="level " rowspan="2">@{[ input"history${num}Level",'','calcLevel' ]}
              <td class="gm    ">@{[ input "history${num}Gm" ]}
              <td class="member">@{[ input "history${num}Member" ]}
            <tr>
              <td colspan="5" class="left">@{[ input "history${num}Note",'','','placeholder="備考"' ]}
            ROW
          }
        ) ]}
        <tfoot id="history-foot">
          <tr>
            <td>
            <td>
            <td>取得総計
            <td id="history-level-total">
            <td colspan="2">
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="level ">強度
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
            <th class="level ">強度
            <th class="gm    ">GM
            <th class="member">参加者
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>-
            <td><input type="text" value="2017-04-07" disabled>
            <td><input type="text" value="第一話「記入例」" disabled>
            <td>10
            <td class="gm"><input type="text" value="サンプルGM" disabled>
            <td class="member"><input type="text" value="" disabled>
          </tr>
        </tbody>
      </table>
      @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
    </div>
  </section>
HTML

print renderEditPageEnd(
  notes => '©からすば晴「マモノスクランブル」',
  extraHtml => renderDataList(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-clan-rule">
    <option value="我慢しない">
    <option value="正々堂々">
    <option value="仲間を守る">
    <option value="手段を問わない">
    <option value="エンジョイ主義">
    <option value="いつも優雅に">
    <option value="利益第一">
    <option value="弱者を助ける">
    <option value="マイペース">
    <option value="敵は許さない">
    <option value="エンターテイナー">
    <option value="誰もが捨て駒">
  </datalist>
  <datalist id="list-clan-base">
    <option value="路地裏">
    <option value="事務所">
    <option value="部室">
    <option value="倉庫">
    <option value="行きつけの店">
    <option value="屋上">
    <option value="地下室">
    <option value="メンバーの店">
    <option value="神社">
    <option value="お寺">
    <option value="教会">
    <option value="公園">
    <option value="図書館">
    <option value="書庫">
    <option value="車内">
    <option value="駐車場">
    <option value="メンバーの家">
    <option value="廃墟">
  </datalist>
  <datalist id="list-clan-belong">
    <option value="なし">
  </datalist>
  <datalist id="list-timing">
    <option value="常時">
    <option value="メイン">
    <option value="サブ">
    <option value="ダメージ増加">
    <option value="ダメージ減少">
    <option value="開始">
    <option value="終了">
    <option value="効果参照">
  </datalist>
  <datalist id="list-target">
    <option value="自身">
    <option value="単体">
    <option value="単体">
    <option value="～体">
    <option value="クラン全員">
    <option value="単体（クラン）">
    <option value="効果参照">
  </datalist>
  <datalist id="list-cond">
    <option value="なし">
  </datalist>
  HTML
}

1;
