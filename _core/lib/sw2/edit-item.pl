############# フォーム・アイテム #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'signatures';
no warnings 'experimental::signatures';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
### 各種データライブラリ読み込み --------------------------------------------------
#require $set::data_item;

### データ読み込み ###################################################################################
my $records = itemRecordList();
my ($data, undef, $message, $latest) = loadSheetData(
  $::mode eq 'edit' ? ($records->lastNumberKey(), $records->countKey()) : (),
);
our %pc = %{ $data };
if(my $formError = $records->normalizeForm(\%pc)){ error($formError); }

our $isNewSheet = isNewSheet();

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{author} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode =~ /^(?:convert|copy)$/ && $pc{ver})){
  %pc = upgradeItemData(\%pc);
}

%pc = applyCustomizedInitialValues(\%pc, 'i') if $::mode eq 'blanksheet';

my $multipleItems = $records->count(\%pc) > 1;
my $sheetName = itemSheetName(\%pc);
$message = applyMessageName($message, $sheetName);

## カラー
setDefaultColors(\%pc);

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc, 'description', map { $_.'effects' } $records->prefixes(\%pc));
my @itemOrder = $records->prepareForm(\%pc, $latest);

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags $sheetName),
  extraJsTop => qq|<script src="$::core_dir/lib/edit-record-list.js?$::ver" defer></script>|,
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>アイテム</span><span>データ</span>
  HTML
);
print qq|<aside class="message">$message</aside>| if $message;

print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box" id="group">
      <dl>
        <dt>タグ<dd>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="ページ情報">
      <div id="item-page-title" @{[ $multipleItems ? '' : 'hidden' ]}>
        <dl>
          <dt>ページタイトル
          <dd>@{[ input 'pageTitle','text','setItemName',($multipleItems ? '' : 'disabled') ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>製作者
        <dd>@{[ input 'author' ]}
      </dl>
    </div>

    @{[ renderRecordList($records, \@itemOrder, \&renderItemFields) ]}
    <div class="box">
      <h2 class="in-toc">由来・逸話</h2>
      <textarea name="description">$pc{description}</textarea>
    </div>
  </section>
HTML

print renderEditPageEnd(
  notes => '(C)Group SNE「ソード・ワールド'.($::SW2_0 ? '2.0' : '2.5').'」',
  extraHtml => renderDataList(),
);

sub renderItemFields ($prefix) {
  my $weapon = "${prefix}weapon";
  my $armour = "${prefix}armour";
  $pc{"${weapon}Num"} ||= 1;
  $pc{"${armour}Num"} ||= 1;
  my $nameAttr = 'list="list-item-name"';

  return <<~"HTML";
      <dl class="item-form-name">
        <dt>名称
        <dd>@{[ input "${prefix}itemName",'text','',$nameAttr ]}
      </dl>
      <dl class="icon-checkboxes"><dt>アイコン<dd>
        @{[ checkbox "${prefix}iconMagic"  , "<img class='i-icon' src=\"${set::icon_dir}item_magic.png\">魔法のアイテム" ]}
        @{[ checkbox "${prefix}iconLocal"  , "<img class='i-icon' src=\"${set::icon_dir}item_local.png\">地方特産品" ]}<br>
        @{[ checkbox "${prefix}iconSchool" , "<img class='i-icon' src=\"${set::icon_dir}item_school.png\">流派アイテム" ]}
        @{[ checkbox "${prefix}iconSchoolA", "<img class='i-icon' src=\"${set::icon_dir}item_school_a.png\">流派アイテム（アルフレイム）" ]}
        @{[ checkbox "${prefix}iconSchoolT", "<img class='i-icon' src=\"${set::icon_dir}item_school_t.png\">流派アイテム（テラスティア）" ]}
      </dl>
      <hr>
      <dl><dt>基本取引価格<dd>@{[ input "${prefix}price",'','','list="list-item-price"' ]}G</dl>
      <dl><dt>知名度  <dd>@{[ input "${prefix}reputation",'text','','pattern="^[0-9\/／]+$"' ]} 数字と／のみ入力可</dl>
      <dl><dt>形状    <dd>@{[ input "${prefix}shape" ]}</dl>
      <dl><dt>カテゴリ<dd>@{[ input "${prefix}category",'text','checkCategory(this)','list="list-category"' ]}
        複数カテゴリの場合、スペースで区切ってください。</dl>
      <dl><dt>製作時期<dd>@{[ input "${prefix}age",'text','','list="list-age"' ]}</dl>
      <dl><dt>概要    <dd>@{[ input "${prefix}summary" ]}</dl>
      <h3>効果</h3>
      @{[ textarea "${prefix}effects" ]}
      <h4>武器データ</h4>
      <table class="input-arms-data" id="$weapon-table" data-arms="$weapon">
        <thead>
          <tr><th><th>用法<th>必筋<th>命中<th>威力<th>C値<th>追加D<th class="range">射程<th>備考
        <tbody>
          @{[ renderTemplateLoop(
            { id => $weapon, numKey => "${weapon}Num" },
            sub ($row) {
              my $field = "$weapon$row";
              return <<~"ROW";
              <tr id="$weapon-row$row">
                <td class="handle">
                <td>@{[ input "${field}Usage",'text','','list="list-weapon-usage"' ]}
                <td>@{[ input "${field}Reqd" ]}
                <td>@{[ input "${field}Acc" ]}
                <td>@{[ input "${field}Rate" ]}
                <td>@{[ input "${field}Crit" ]}
                <td>@{[ input "${field}Dmg" ]}
                <td class="range">@{[ input "${field}Range",'','','list="list-weapon-range"' ]}
                <td>@{[ input "${field}Note" ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('arms', "'$weapon'", "${weapon}Num") ]}
      <p>
      <code>[刃]</code> <code>[打]</code> でそれぞれ<img class="i-icon" src="${set::icon_dir}item_edge.png"><img class="i-icon" src="${set::icon_dir}item_blow.png">に置き換え
      </p>
      <h4>防具データ</h4>
      <table class="input-arms-data" id="$armour-table" data-arms="$armour">
        <thead>
          <tr><th><th>用法<th>必筋<th>回避<th>防護<th>備考
        <tbody>
          @{[ renderTemplateLoop(
            { id => $armour, numKey => "${armour}Num" },
            sub ($row) {
              my $field = "$armour$row";
              return <<~"ROW";
              <tr id="$armour-row$row">
                <td class="handle">
                <td>@{[ input "${field}Usage",'text','','list="list-armour-usage"' ]}
                <td>@{[ input "${field}Reqd" ]}
                <td>@{[ input "${field}Eva" ]}
                <td>@{[ input "${field}Def" ]}
                <td>@{[ input "${field}Note" ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('arms', "'$armour'", "${armour}Num") ]}
  HTML
}

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-item-name">
    <option value="〈〉">
  </datalist>
  <datalist id="list-item-price">
    <option value="（非売品）">
    <option value="取引不能">
  </datalist>
  <datalist id="list-weapon-usage">
    <option value="1H">
    <option value="1H#">
    <option value="1H投">
    <option value="1H拳">
    <option value="1H両">
    <option value="1H騎">
    <option value="2H">
    <option value="2H#">
    <option value="2H投">
    <option value="振2H">
    <option value="突2H">
  </datalist>
  <datalist id="list-weapon-range">
    <option value="1(10m)">
    <option value="2(20m)">
    <option value="2(30m)">
    <option value="2(40m)">
    <option value="2(50m)">
    <option value="2(60m)">
  </datalist>
  <datalist id="list-armour-usage">
    <option value="1H">
    <option value="2H">
  </datalist>
  <datalist id="list-age">
    <option value="現在">
    <option value="魔動機文明">
    <option value="古代魔法文明">
    <option value="神紀文明">
    <option value="不明">
  </datalist>
  <datalist id="list-category">
    <option value="〈ソード〉">
    <option value="〈アックス〉">
    <option value="〈スピア〉">
    <option value="〈メイス〉">
    <option value="〈スタッフ〉">
    <option value="〈フレイル〉">
    <option value="〈ウォーハンマー〉">
    <option value="〈絡み〉">
    <option value="〈格闘〉">
    <option value="〈投擲〉">
    <option value="〈ボウ〉">
    <option value="〈クロスボウ〉">
    <option value="〈ガン〉">
    <option value="〈矢弾〉">
    <option value="〈非金属鎧〉">
    <option value="〈金属鎧〉">
    <option value="〈盾〉">
    <option value="〈魔導書〉">
    <option value="〈龍骸〉">
    <option value="装飾品：頭">
    <option value="装飾品：顔">
    <option value="装飾品：耳">
    <option value="装飾品：首">
    <option value="装飾品：背中">
    <option value="装飾品：手">
    <option value="装飾品：腰">
    <option value="装飾品：足">
    <option value="装飾品：その他">
    <option value="装飾品：任意">
    <option value="薬草類">
    <option value="ポーション類">
    <option value="冒険者技能用アイテム">
    <option value="楽器">
    <option value="特殊楽器">
    <option value="冒険道具類">
    <option value="冒険道具類（消耗品）">
    <option value="武器強化">
    <option value="防具強化">
    <option value="楽器加工">
    <option value="騎獣用防具">
    <option value="騎獣用武装">
    <option value="衣類">
    <option value="道具類">
    <option value="照明器具">
    <option value="照明器具（消耗品）">
    <option value="キャンプ用品">
    <option value="食事">
    <option value="移動費用">
    <option value="その他">
  </datalist>
  HTML
}

1;
