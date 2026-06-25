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
$message = applyMessageName($message, $pc{countryName} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{playerName} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode eq 'convert' && $pc{ver})){
  %pc = data_update_chara(\%pc);
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

  $pc{history0Result} = $set::make_exp || 0;

  $pc{level} = $pc{makeLv} = 1;

  $pc{paletteUseVar} = 1;
  $pc{paletteUseBuff} = 1;

  %pc = applyCustomizedInitialValues(\%pc, 'c');
}

## カラー
setDefaultColors(\%pc);

## その他
$pc{memberNum}         ||= 3;
$pc{academySupportNum} ||= 3;
$pc{artifactNum}       ||= 3;
$pc{characteristicNum} ||= 3;
$pc{forceNum}          ||= 3;
$pc{historyNum}        ||= 3;

### 折り畳み判断 --------------------------------------------------
my %open;
foreach (1..$pc{memberNum}){ if($pc{"member${_}Name"}){ $open{members} = 'open'; last; } }
foreach (1..$pc{academySupportNum}){ if($pc{"academySupport${_}Name"} || $pc{"academySupport${_}Cost"}){ $open{academySupports} = 'open'; last; } }
foreach (1..$pc{artifactNum}){ if($pc{"artifact${_}Name"} || $pc{"artifact${_}Cost"}){ $open{artifacts} = 'open'; last; } }
foreach (1..$pc{characteristicNum}){ if($pc{"characteristic${_}Name"}){ $open{characteristics} = 'open'; last; } }
foreach (1..$pc{forceNum}){ if($pc{"force${_}Type"}){ $open{forces} = 'open'; last; } }

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/words freeNote freeHistory chatPalette/,
);

### 画像 --------------------------------------------------
my $image_maxsize = $set::image_maxsize / 2;
my $image_maxsize_view = $image_maxsize >= 1048576 ? sprintf("%.3g",$image_maxsize/1048576).'MB' : sprintf("%.3g",$image_maxsize/1024).'KB';

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ( $pc{countryName} )),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>国</span></span><span>データ</span>
  HTML
);
print qq|<aside class="message">$message</aside>| if $message;

print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box" id="group">
      <dl>
        <dt>グループ<dd><select name="group">@{[ renderGroupOptions ]}</select>
        <dt>タグ<dd>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="国名・ロード名・プレイヤー名">
      <div>
        <dl id="character-name">
          <dt>国名
          <dd>@{[ input 'countryName','text',"setName",'id="main-name" required' ]}
          <dt>ロード名
          <dd>@{[ input 'lordName']}
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
        <dt>作成時爵位
        <dd>@{[ selectBox 'makePeerage','changePeerage','def=騎士','男爵','子爵','伯爵','辺境伯','侯爵','公爵','大公' ]}
        <dt>備考
        <dd>@{[ input "history0Note" ]}
      </dl>
    </details>

    <div class="box-union in-toc" id="profile" data-content-title="国レベル・カウント・爵位">
      <dl class="box" id="level">
        <dt>国レベル
        <dd>
      </dl>
      <dl class="box" id="counts">
        <dt>カウント
        <dd>
      </dl>
      <dl class="box" id="peerage">
        <dt>爵位
        <dd>
      </dl>
    </div>

    <details class="box" id="members" $open{members}>
      <summary class="in-toc">メンバー</summary>
      <table class="edit-table no-border-cells">
        <colgroup>
          <col class="handle">
          <col class="name  ">
          <col class="url   ">
          <col class="class ">
          <col class="style ">
          <col class="note  ">
        </colgroup>
        <thead>
          <tr>
            <th>
            <th class="name ">名前
            <th class="url  "><span class="small">キャラクターシートURL</span>
            <th class="class">クラス
            <th class="style">スタイル
            <th class="note left">備考
        <tbody>
          @{[ renderTemplateLoop(
            'member',
            sub ($num) {
              return <<~"ROW";
              <tr id="member-row${num}">
                <td class="handle">
                <td class="name  ">@{[ input "member${num}Name" ]}
                <td class="url   ">@{[ input "member${num}URL",'url','setMemberData(this)' ]}
                <td class="class ">@{[ input "member${num}Class" ]}
                <td class="style ">@{[ input "member${num}Style" ]}
                <td class="note  ">@{[ input "member${num}Note" ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('member') ]}
    </details>

    <details class="box" id="academy-supports" $open{academySupports}>
      <summary class="in-toc">所持アカデミーサポート</summary>
      <table class="edit-table no-border-cells">
        <colgroup>
          <col class="handle">
          <col class="name  ">
          <col class="lv    ">
          <col class="timing">
          <col class="target">
          <col class="cost  ">
          <col class="note  ">
        </colgroup>
        <thead>
          <tr>
            <th>
            <th class="name  ">
            <th class="lv    "><span class="small">レベル</small>
            <th class="timing">タイミング
            <th class="target">対象
            <th class="cost  ">カウント
            <th class="note left">効果
        <tbody>
          @{[ renderTemplateLoop(
            'academy-support',
            sub ($num) {
              return <<~"ROW";
              <tr id="academy-support-row${num}">
                <td class="handle">
                <td class="name  ">@{[ input "academySupport${num}Name" ]}
                <td class="lv    ">@{[ input "academySupport${num}Lv",'number' ]}
                <td class="timing">@{[ input "academySupport${num}Timing",'','','list="list-timing"' ]}
                <td class="target">@{[ input "academySupport${num}Target",'','','list="list-target"' ]}
                <td class="cost  ">@{[ input "academySupport${num}Cost",'number','calcCounts' ]}
                <td class="note  ">@{[ input "academySupport${num}Note" ]}
              ROW
            }
          ) ]}
      </table>
     @{[ renderAddDelButtons('academy-support') ]}
    </details>

    <details class="box" id="artifacts" $open{artifacts}>
      <summary class="in-toc">所持アーティファクト</summary>
      <table class="edit-table no-border-cells">
        <colgroup>
          <col class="handle  ">
          <col class="name    ">
          <col class="type    ">
          <col class="weight  ">
          <col class="lv      ">
          <col class="cost    ">
          <col class="quantity">
          <col class="note    ">
        </colgroup>
        <thead>
          <tr>
            <th>
            <th class="name    ">
            <th class="type    ">種別
            <th class="weight  ">重量
            <th class="lv      "><span class="small">レベル</small>
            <th class="cost    ">カウント
            <th class="quantity">個数
            <th class="note left">効果
        <tbody>
          @{[ renderTemplateLoop(
            'artifact',
            sub ($num) {
              return <<~"ROW";
              <tr id="artifact-row${num}">
                <td class="handle  ">
                <td class="name    ">@{[ input "artifact${num}Name" ]}
                <td class="type    ">@{[ input "artifact${num}Type",'','','list="list-artifact-type"' ]}
                <td class="weight  ">@{[ input "artifact${num}Weight",'number' ]}
                <td class="lv      ">@{[ input "artifact${num}Lv",'number' ]}
                <td class="cost    ">@{[ input "artifact${num}Cost",'number','calcCounts' ]}
                <td class="quantity">@{[ input "artifact${num}Quantity",'number','calcCounts' ]}
                <td class="note    ">@{[ input "artifact${num}Note" ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('artifact') ]}
    </details>

    <details class="box" id="characteristics" $open{characteristics}>
      <summary class="in-toc">国特徴／成長</summary>
      <table class="edit-table no-border-cells">
        <colgroup>
          <col class="handle">
          <col class="name  ">
          <col class="effect">
          <col class="effect">
          <col class="effect">
          <col class="effect">
          <col class="effect">
          <col class="effect">
          <col class="note">
        </colgroup>
        <thead>
          <tr>
            <th rowspan="2">
            <th rowspan="2">
            <th colspan="6"><div class="small">効果</div>
            <th rowspan="2" class="left">解説
          <tr>
            <th class="small">食糧
            <th class="small">技術
            <th class="small">馬
            <th class="small">鉱石
            <th class="small">森林
            <th class="small">資金
        <tbody>
          @{[ renderTemplateLoop(
            'characteristic',
            sub ($num) {
              return <<~"ROW";
              <tr id="characteristic-row${num}">
                <td class="handle">
                <td class="name  ">@{[ input "characteristic${num}Name" ]}
                <td class="effect">@{[ input "characteristic${num}Food" ,'number','calcResources' ]}
                <td class="effect">@{[ input "characteristic${num}Tech" ,'number','calcResources' ]}
                <td class="effect">@{[ input "characteristic${num}Horse",'number','calcResources' ]}
                <td class="effect">@{[ input "characteristic${num}Mineral",'number','calcResources' ]}
                <td class="effect">@{[ input "characteristic${num}Forest",'number','calcResources' ]}
                <td class="effect">@{[ input "characteristic${num}Funds",'number','calcResources' ]}
                <td class="note  ">@{[ input "characteristic${num}Note" ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('characteristic') ]}
      <table class="edit-table no-border-cells" id="grow">
        <colgroup>
          <col class="handle">
          <col class="name  ">
          <col class="effect">
          <col class="effect">
          <col class="effect">
          <col class="effect">
          <col class="effect">
          <col class="effect">
          <col class="note">
        </colgroup>
        <tbody>
          <tr>
            <th class="name" colspan="2">成長[<span id="grow-total">0</span>/<span id="grow-max">0</span>]
            <td class="effect">@{[ input "growFood" ,'number','calcResources' ]}
            <td class="effect">@{[ input "growTech" ,'number','calcResources' ]}
            <td class="effect">@{[ input "growHorse",'number','calcResources' ]}
            <td class="effect">@{[ input "growMineral",'number','calcResources' ]}
            <td class="effect">@{[ input "growForest",'number','calcResources' ]}
            <td class="effect">@{[ input "growFunds",'number','calcResources' ]}
            <td class="note  ">
      </table>
    </details>

    <div class="box in-toc" id="resources" data-content-title="資源">
      <table class="data-table">
        <thead>
          <tr>
            <th colspan="2">食糧
            <th colspan="2">技術
            <th colspan="2">馬
            <th colspan="2">鉱石
            <th colspan="2">森林
            <th colspan="2">資金
          <tr>
            <th class="small">資源量
            <th class="small">使用量
            <th class="small">資源量
            <th class="small">使用量
            <th class="small">資源量
            <th class="small">使用量
            <th class="small">資源量
            <th class="small">使用量
            <th class="small">資源量
            <th class="small">使用量
            <th class="small">資源量
            <th class="small">使用量
        <tbody>
          <tr>
            <td class="Food    total">0
            <td class="Food    used ">0
            <td class="Tech    total">0
            <td class="Tech    used ">0
            <td class="Horse   total">0
            <td class="Horse   used ">0
            <td class="Mineral total">0
            <td class="Mineral used ">0
            <td class="Forest  total">0
            <td class="Forest  used ">0
            <td class="Funds   total">0
            <td class="Funds   used ">0
      </table>
    </div>

    <details class="box" id="forces" $open{forces}>
      <summary class="in-toc">部隊</summary>
      <table class="edit-table no-border-cells">
        <colgroup>
          <col class="handle">
          <col class="type  ">
          <col class="lv    ">
          <col class="cost  ">
          <col class="cost  ">
          <col class="cost  ">
          <col class="cost  ">
          <col class="cost  ">
          <col class="cost  ">
          <col class="note  ">
          <col class="copy  ">
        </colgroup>
        <thead>
          <tr>
            <th rowspan="2">
            <th rowspan="2">部隊種別
            <th rowspan="2" class="small">レベル
            <th colspan="6"><div class="small">必要資源</div>
            <th rowspan="2" class="left">備考
            <th>
          <tr>
            <th class="small">食糧
            <th class="small">技術
            <th class="small">馬
            <th class="small">鉱石
            <th class="small">森林
            <th class="small">資金
        <tbody>
          @{[ renderTemplateLoop(
            'force',
            sub ($num) {
              return <<~"ROW";
              <tr id="force-row${num}">
                <td class="handle">
                <td class="type  ">@{[ input "force${num}Type" ]}
                <td class="cost  ">@{[ input "force${num}Lv" ,'number' ]}
                <td class="cost  ">@{[ input "force${num}CostFood" ,'number','calcResources' ]}
                <td class="cost  ">@{[ input "force${num}CostTech" ,'number','calcResources' ]}
                <td class="cost  ">@{[ input "force${num}CostHorse",'number','calcResources' ]}
                <td class="cost  ">@{[ input "force${num}CostMineral",'number','calcResources' ]}
                <td class="cost  ">@{[ input "force${num}CostForest",'number','calcResources' ]}
                <td class="cost  ">@{[ input "force${num}CostFunds",'number','calcResources' ]}
                <td class="note  ">@{[ input "force${num}Note" ]}
                <td class="copy  "><span class="button" onclick="addForce(${num})">複製</span>
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('force') ]}
    </details>

    <div class="box" id="exp-footer">
      <p>
        <b>カウント</b>[<b class="counts-total">0</b>]
        -
        ( アカデミーサポート[<b class="counts-used-as">0</b>]
        + アーティファクト[<b class="counts-used-artifact">0</b>]
        ) = 残り[<b class="counts-rest">0</b>]
      </p>
    </div>

    <div id="image" class="box">
      <h2 class="in-toc">地図などの画像</h2>
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
            <th class="counts">カウント
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
                <td class="counts">@{[ input "history${num}Counts",'','calcCounts' ]}
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
            <td id="history-counts-total">
            <td colspan="2">
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="counts">カウント
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
          <col class="counts">
          <col class="gm    ">
          <col class="member">
        </colgroup>
        <thead>
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="counts">カウント
            <th class="gm    ">GM
            <th class="member">参加者
        <tbody>
          <tr>
            <td>-
            <td><input type="text" value="2013/08/20" disabled>
            <td><input type="text" value="第一話「記入例」" disabled>
            <td><input type="text" value="" disabled>
            <td><input type="text" value="サンプルさん" disabled>
            <td><input type="text" value="テオ　シルーカ" disabled class="left">
          </tr>
        </tbody>
      </table>
      <ul class="annotate">
        <li>カウント欄は<code>1+2*2</code>など四則演算が有効です。<br>
      </ul>
      @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
    </div>
  </section>
HTML
print renderEditPageEnd(
  notes => '©Shunsaku Yano/Team Barrelroll.「グランクレストRPG」',
  extraHtml => renderDataList() . renderFooterScript(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-timing">
    <option value="常時">
    <option value="いつでも">
    <option value="セットアップ">
    <option value="イニシアチブ">
    <option value="クリンナップ">
    <option value="メジャー">
    <option value="マイナー">
    <option value="リアクション">
    <option value="ガード">
    <option value="判定の直前">
    <option value="判定の直後">
    <option value="効果参照">
  </datalist>
  <datalist id="list-target">
    <option value="―">
    <option value="自国">
    <option value="効果参照">
  </datalist>
  <datalist id="list-artifact-type">
    <option value="その他">
    <option value="その他（使い捨て）">
    <option value="軽武器（）">
    <option value="重武器（）">
    <option value="射撃（）">
    <option value="盾">
    <option value="防具（）">
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
