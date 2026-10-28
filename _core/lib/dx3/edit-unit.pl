############# フォーム・ユニット #############
use strict;
use utf8;
use open ":utf8";
use feature 'signatures';
no warnings 'experimental::signatures';

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{unitName} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{playerName} = (getPlayerName($::LOGIN_ID))[0];
  $pc{protect} ||= $::LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode =~ /^(?:convert|copy)$/ && $pc{ver})){
  %pc = upgradeUnitData(\%pc);
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
  %pc = applyCustomizedInitialValues(\%pc, 'u');
}
$pc{memberNum}   //= 6;
$pc{orderNum}    //= 6;
$pc{facilityNum} //= 6;

## カラー
setDefaultColors(\%pc);

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  'freeNote',
);

### フォーム表示 #####################################################################################
print renderEditPageStart(title => removeTags removeRuby unescapeTags $pc{unitName});
print renderEditHeaderMenu(
  tabsHtml => '<li onclick="sectionSelect(\'common\');" class="sheet-main"><span>ユニット</span><span>データ</span>',
);
print qq|<aside class="message">$message</aside>| if $message;
print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box" id="group">
      <dl>
        <dt>グループ<dd><select name="group">@{[ renderGroupOptions() ]}</select>
        <dt>タグ<dd>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box" id="sheet-type">
      @{[ radios "sheetSubType", 'checkSheetType', 'unit=>ユニットシート','company=>カンパニーシート' ]}
    </div>

    <div class="box in-toc" id="name-form" data-content-title="名称・プレイヤー名">
      <div>
        <dl id="character-name">
          <dt><span class="company-only">カンパニー</span><span class="unit-only">ユニット</span>名称<dd>@{[ input 'unitName','text','setName','id="main-name" required' ]}
          <dt class="ruby">ふりがな<dd>@{[ input 'unitNameRuby','text','setName' ]}
        </dl>
      </div>
      <dl id="player-name"><dt>プレイヤー名<dd>@{[ input 'playerName' ]}</dl>
    </div>

    <div class="box" id="members">
      <h2 class="in-toc" data-content-title="メンバー"><span class="unit-only">ユニット</span><span class="company-only">チーム</span>メンバー</h2>
      <table class="edit-table no-border-cells" id="member-table">
        <thead id="member-head">
          <tr>
          <th class="row-handle">
          <th class="name">名前
          <th class="url">URL
          <th class="belong unit-only">所属
          <th class="note left">備考
          <th class="leader"><span class="thin">リーダー</span>
          <th class="m-left"><span class="thin">離脱</span>
        <tbody>
          @{[ renderTemplateLoop('member', sub ($num) {
            return <<~"ROW";
            <tr id="member-row$num">
              <th class="handle">
              <td class="name  ">@{[ input "member${num}Name" ]}
              <td class="url   ">@{[ input "member${num}URL",'url','','placeholder="https://..."' ]}
              <td class="belong unit-only">@{[ input "member${num}Belong",'','','list="list-unit-organization"' ]}
              <td class="note  ">@{[ input "member${num}Note" ]}
              <td class="leader">@{[ input "member${num}Leader",'checkbox' ]}
              <td class="m-left">@{[ input "member${num}Left",'checkbox' ]}
            ROW
          }) ]}
      </table>
      @{[ renderAddDelButtons('member') ]}
    </div>

    <div class="box unit-only" id="unit-orders">
      <h2 class="in-toc">ユニットオーダー</h2>
      <table class="edit-table no-border-cells">
        <thead>
          <tr>
            <th class="row-handle">
            <th class="name">名称
            <th class="organization">組織
            <th class="timing">タイミング
            <th class="note">備考
        <tbody id="order-tbody">
          @{[ renderTemplateLoop('order', sub ($num) {
            return <<~"ROW";
            <tr id="order-row$num">
              <th class="handle">
              <td>@{[ input "order${num}Name" ]}
              <td>@{[ input "order${num}Organization",'','','list="list-unit-organization"' ]}
              <td>@{[ input "order${num}Timing",'','','list="list-timing"' ]}
              <td>@{[ input "order${num}Note" ]}
            ROW
          }) ]}
      </table>
      @{[ renderAddDelButtons('order') ]}
    </div>

    <div class="box company-only" id="company-profile">
      <table class="edit-table no-border-cells">
        <thead>
          <tr>
            <th class="row-handle">
            <th class="form">組織形態
            <th class="size">規模
            <th class="slot">スロット
            <th class="exp "><span class="small">消費<br>経験点</span>
        <tbody>
          <tr>
            <th class="handle">
            <td class="form">@{[ input "companyForm" ]}
            <td class="size">@{[ selectInput "companySize", "calcCompany",
                '1=>パーソナル',
                '2=>ごく小規模',
                '3=>小規模',
                '4=>中規模',
                '5=>大規模',
                '6=>超大規模',
              ]}
            <td class="slot">@{[ input "companySlot","number","calcCompany" ]}
            <td class="exp ">@{[ input "companyExp","number","calcCompany" ]}
      </table>
    </div>

    <div class="box company-only" id="company-exterior">
      <h2 class="in-toc">カンパニー外装</h2>
      <table class="edit-table no-border-cells">
        <thead>
          <tr>
            <th class="row-handle">
            <th class="name">名称
            <th class="save"><span class="small">取得財産<br>ポイント</span>
            <th class="exp "><span class="small">消費<br>経験点</span>
            <th class="note left">効果
        <tbody>
          <tr>
            <th class="handle">
            <td class="name">@{[ input "exteriorName" ]}
            <td class="save">@{[ input "exteriorSaving","number","calcCompany" ]}
            <td class="exp ">@{[ input "exteriorExp","number","calcCompany" ]}
            <td class="note">@{[ input "exteriorNote" ]}
      </table>
    </div>

    <div class="box company-only" id="company-facility">
      <h2 class="in-toc">カンパニー追加施設</h2>
      <table class="edit-table no-border-cells">
        <thead>
          <tr>
            <th class="row-handle">
            <th class="name">名称
            <th class="exp "><span class="small">消費<br>経験点</span>
            <th class="slot"><span class="small">消費<br>スロット</span>
            <th class="note left">効果
        <tbody id="facility-tbody">
          @{[ renderTemplateLoop('facility', sub ($num) {
            return <<~"ROW";
            <tr id="facility-row$num">
              <th class="handle">
              <td class="name">@{[ input "facility${num}Name" ]}
              <td class="exp ">@{[ input "facility${num}Exp","number","calcCompany" ]}
              <td class="slot">@{[ input "facility${num}Slot","number","calcCompany" ]}
              <td class="note">@{[ input "facility${num}Note" ]}
            ROW
          }) ]}
        <tfoot>
          <tr>
            <th>
            <th>合計
            <td class="exp ">
            <td class="slot">
            <th>
      </table>
      @{[ renderAddDelButtons('facility') ]}
    </div>

    <div class="box" id="free-note">
      <h2 class="in-toc">設定・メモ</h2>
      @{[ textarea 'freeNote' ]}
    </div>
  </section>
HTML
print renderEditPageEnd(
  notes => '©FarEast Amusement Research Co.,Ltd.「ダブルクロスThe 3rd Edition」',
  extraHtml => renderDataList(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-unit-organization">
    <option value="UGN">
    <option value="FH">
    <option value="ゼノス">
    <option value="その他">
  </datalist>
  <datalist id="list-timing">
    <option value="オート">
    <option value="マイナー">
    <option value="メジャー">
    <option value="リアクション">
    <option value="セットアップ">
    <option value="イニシアチブ">
    <option value="クリンナップ">
    <option value="常時">
    <option value="効果参照">
  </datalist>
  HTML
}

1;
