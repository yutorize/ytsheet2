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
$pc{memberNum} //= 6;
$pc{orderNum} //= 6;

## カラー
setDefaultColors(\%pc);

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  'freeNote', grep { /^(?:member|order)[0-9]+Note$/ } keys %pc,
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
    <div class="box in-toc" id="name-form" data-content-title="ユニット名・GM名">
      <div>
        <dl id="character-name">
          <dt>ユニット名<dd>@{[ input 'unitName','text','setName','id="main-name" required' ]}
          <dt class="ruby">ふりがな<dd>@{[ input 'unitNameRuby','text','setName' ]}
        </dl>
      </div>
      <dl id="player-name"><dt>GM名<dd>@{[ input 'playerName' ]}</dl>
    </div>
    <div class="box unit-members">
      <h2 class="in-toc">ユニットメンバー</h2>
      <table class="edit-table no-border-cells" id="member-table">
        <thead id="member-head"><tr><th class="row-handle"><th class="name">名称<th class="belong">所属<th class="note">備考<th class="leader">リーダー</thead>
          @{[ renderTemplateLoop('member', sub ($num) {
            return <<~"ROW";
            <tbody id="member-row$num"><tr>
              <th class="handle" rowspan="2">
              <td>@{[ input "member${num}Name" ]}
              <td>@{[ input "member${num}Belong",'','','list="list-unit-organization"' ]}
              <td rowspan="2">@{[ textarea "member${num}Note" ]}
              <td rowspan="2">@{[ input "member${num}Leader",'checkbox','','aria-label="リーダー"' ]}
            <tr class="member-url">
              <td colspan="2"><label>キャラクターシートURL @{[ input "member${num}URL",'url','','placeholder="https://..."' ]}</label>
            </tbody>
            ROW
          }) ]}
      </table>
      @{[ renderAddDelButtons('member') ]}
    </div>
    <div class="box unit-orders">
      <h2 class="in-toc">ユニットオーダー</h2>
      <table class="edit-table no-border-cells">
        <thead><tr><th class="row-handle"><th class="name">名称<th class="organization">組織<th class="timing">タイミング<th class="note">備考<th class="ref">参照
        <tbody id="order-tbody">
          @{[ renderTemplateLoop('order', sub ($num) {
            return <<~"ROW";
            <tr id="order-row$num">
              <th class="handle">
              <td>@{[ input "order${num}Name" ]}
              <td>@{[ input "order${num}Organization",'','','list="list-unit-organization"' ]}
              <td>@{[ input "order${num}Timing" ]}
              <td>@{[ textarea "order${num}Note" ]}
              <td>@{[ input "order${num}Ref" ]}
            ROW
          }) ]}
      </table>
      @{[ renderAddDelButtons('order') ]}
    </div>
    <div class="box" id="free-note">
      <h2 class="in-toc">MEMO</h2>
      @{[ textarea 'freeNote' ]}
    </div>
  </section>
HTML
print renderEditPageEnd(
  notes => '©FarEast Amusement Research Co.,Ltd.「ダブルクロスThe 3rd Edition」',
  extraHtml => '<datalist id="list-unit-organization"><option value="UGN"><option value="FH"><option value="ゼノス"><option value="その他"></datalist>',
);

1;
