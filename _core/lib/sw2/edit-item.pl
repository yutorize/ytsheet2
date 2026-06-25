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
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{itemName} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{author} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode eq 'convert' && $pc{ver})){
  %pc = data_update_item(\%pc);
}

%pc = applyCustomizedInitialValues(\%pc, 'i') if $::mode eq 'blanksheet';

$pc{weaponNum} ||= 1;
$pc{armourNum} ||= 1;

## カラー
setDefaultColors(\%pc);

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/effects description/,
);

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ( $pc{itemName} )),
  systemId => ($::SW2_0 ? 'sw2.0' : 'sw2.5'),
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

    <div class="box in-toc" id="name-form" data-content-title="名称・製作者">
      <div>
        <dl id="character-name">
          <dt>名称
          <dd>@{[ input 'itemName','text',"setName",'id="main-name" list="list-item-name"' ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>製作者
        <dd>@{[ input 'author' ]}
      </dl>
    </div>

    <div class="box input-data in-toc" data-content-title="基本データ">
      <dl class="icon-checkboxes"><dt>アイコン<dd>
        @{[ checkbox 'iconMagic'  , "<img class='i-icon' src=\"${set::icon_dir}item_magic.png\">魔法のアイテム" ]}
        @{[ checkbox 'iconLocal'  , "<img class='i-icon' src=\"${set::icon_dir}item_local.png\">地方特産品" ]}<br>
        @{[ checkbox 'iconSchool' , "<img class='i-icon' src=\"${set::icon_dir}item_school.png\">流派アイテム" ]}
        @{[ checkbox 'iconSchoolA', "<img class='i-icon' src=\"${set::icon_dir}item_school_a.png\">流派アイテム（アルフレイム）" ]}
        @{[ checkbox 'iconSchoolT', "<img class='i-icon' src=\"${set::icon_dir}item_school_t.png\">流派アイテム（テラスティア）" ]}
      </dl>
      <hr>
      <dl><dt>基本取引価格<dd>@{[ input 'price','','','list="list-item-price"' ]}G</dl>
      <dl><dt>知名度  <dd>@{[ input 'reputation', 'text','','pattern="^[0-9\/／]+$"' ]} 数字と／のみ入力可</dl>
      <dl><dt>形状    <dd>@{[ input 'shape' ]}</dl>
      <dl><dt>カテゴリ<dd>@{[ input 'category','text','checkCategory','list="list-category"' ]}
        複数カテゴリの場合、スペースで区切ってください。</dl>
      <dl><dt>製作時期<dd>@{[ input 'age','text','','list="list-age"' ]}</dl>
      <dl><dt>概要    <dd>@{[ input 'summary' ]}</dl>
    </div>
    <div class="box">
      <h2 class="in-toc">効果</h2>
      <textarea name="effects">$pc{effects}</textarea>
      <h4 class="in-toc">武器データ</h4>
      <table class="input-arms-data" id="weapons-table">
        <thead>
          <tr><th><th>用法<th>必筋<th>命中<th>威力<th>C値<th>追加D<th class="range">射程<th>備考
        <tbody>
          @{[ renderTemplateLoop(
            'weapon',
            sub ($num) {
              return <<~"ROW";
              <tr id="weapon-row$num">
                <td class="handle">
                <td>@{[ input "weapon${num}Usage",'text','','list="list-weapon-usage"' ]}
                <td>@{[ input "weapon${num}Reqd" ]}
                <td>@{[ input "weapon${num}Acc" ]}
                <td>@{[ input "weapon${num}Rate" ]}
                <td>@{[ input "weapon${num}Crit" ]}
                <td>@{[ input "weapon${num}Dmg" ]}
                <td class="range">@{[ input "weapon${num}Range",'','','list="list-weapon-range"' ]}
                <td>@{[ input "weapon${num}Note" ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('weapon') ]}
      <p>
      <code>[刃]</code> <code>[打]</code> でそれぞれ<img class="i-icon" src="${set::icon_dir}item_edge.png"><img class="i-icon" src="${set::icon_dir}item_blow.png">に置き換え
      <p>
      <h4 class="in-toc">防具データ</h4>
      <table class="input-arms-data" id="armours-table">
        <thead>
          <tr><th><th>用法<th>必筋<th>回避<th>防護<th>備考
        <tbody>
          @{[ renderTemplateLoop(
            'armour',
            sub ($num) {
              return <<~"ROW";
              <tr id="armour-row$num">
                <td class="handle">
                <td>@{[ input "armour${num}Usage",'text','','list="list-armour-usage"' ]}
                <td>@{[ input "armour${num}Reqd" ]}
                <td>@{[ input "armour${num}Eva" ]}
                <td>@{[ input "armour${num}Def" ]}
                <td>@{[ input "armour${num}Note" ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('armour') ]}
    </div>
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
