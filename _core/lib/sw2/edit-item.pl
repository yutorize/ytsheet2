############# フォーム・アイテム #############
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
### 各種データライブラリ読み込み --------------------------------------------------
#require $set::data_item;

### データ読み込み ###################################################################################
my ($data, $mode, $file, $message) = loadSheetData($::in{mode});
our %pc = %{ $data };

my $isNewSheet = isNewSheet($mode);

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{itemName} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{author} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($mode eq 'edit' || ($mode eq 'convert' && $pc{ver})){
  %pc = data_update_item(\%pc);
}

%pc = applyCustomizedInitialValues(\%pc, 'i') if $mode eq 'blanksheet';

$pc{weaponNum} ||= 1;
$pc{armourNum} ||= 1;

## カラー
setDefaultColors();

### 改行処理 --------------------------------------------------
$pc{effects}     =~ s/&lt;br&gt;/\n/g;
$pc{description} =~ s/&lt;br&gt;/\n/g;


### フォーム表示 #####################################################################################
print <<"HTML";
Content-Type: text/html; charset=utf-8\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>@{[$mode eq 'edit'?"編集：$pc{itemName}":'新規作成']} - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/base.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/sheet.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/item.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/sw2/edit-item.js?${main::ver}" defer></script>
</head>
<body>
  <script src="${main::core_dir}/skin/_common/js/common.js?${main::ver}"></script>
  <header>
    <h1>$set::title</h1>
  </header>

  <main>
    <article>
      <form id="item" name="sheet" method="post" action="./" enctype="multipart/form-data">
      <input type="hidden" name="ver" value="${main::ver}">
      <input type="hidden" name="type" value="i">
HTML
if($isNewSheet){
  print '<input type="hidden" name="_token" value="'.tokenMake().'">'."\n";
}
print qq|<input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">\n|;

print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
        <li onclick="sectionSelect('common');" class="sheet-main"><span>アイテム</span><span>データ</span>
  HTML
);
print qq|<aside class="message">$message</aside>\n|;
print qq|<section id="section-common">\n|;

print renderProtectBlock(
  isNewSheet => $isNewSheet,
  protect    => $pc{protect},
  pass       => $::in{pass},
);
print renderVisibilityBlock(
  forbidden => $pc{forbidden},
  hide      => $pc{hide},
);
print <<"HTML";
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
HTML
foreach my $num ('TMPL', 1 .. $pc{weaponNum}){
  print <<~"HTML";
          @{[ $num eq 'TMPL' ? '<template id="weapon-template">' : '' ]}<tr id="weapon-row$num">
            <td class="handle">
            <td>@{[ input "weapon${num}Usage",'text','','list="list-weapon-usage"' ]}
            <td>@{[ input "weapon${num}Reqd" ]}
            <td>@{[ input "weapon${num}Acc" ]}
            <td>@{[ input "weapon${num}Rate" ]}
            <td>@{[ input "weapon${num}Crit" ]}
            <td>@{[ input "weapon${num}Dmg" ]}
            <td class="range">@{[ input "weapon${num}Range",'','','list="list-weapon-range"' ]}
            <td>@{[ input "weapon${num}Note" ]}
          @{[ $num eq 'TMPL' ? "</template>" : '' ]}
  HTML
}
print <<"HTML";
      </table>
      <div class="add-del-button"><a onclick="addWeapon()">▼</a><a onclick="delWeapon()">▲</a></div>
      @{[ input 'weaponNum','hidden' ]}
      <p>
      <code>[刃]</code> <code>[打]</code> でそれぞれ<img class="i-icon" src="${set::icon_dir}item_edge.png"><img class="i-icon" src="${set::icon_dir}item_blow.png">に置き換え
      <p>
      <h4 class="in-toc">防具データ</h4>
      <table class="input-arms-data" id="armours-table">
        <thead>
          <tr><th><th>用法<th>必筋<th>回避<th>防護<th>備考
        <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{armourNum}){
  print <<~"HTML";
          @{[ $num eq 'TMPL' ? '<template id="armour-template">' : '' ]}<tr id="armour-row$num">
            <td class="handle">
            <td>@{[ input "armour${num}Usage",'text','','list="list-armour-usage"' ]}
            <td>@{[ input "armour${num}Reqd" ]}
            <td>@{[ input "armour${num}Eva" ]}
            <td>@{[ input "armour${num}Def" ]}
            <td>@{[ input "armour${num}Note" ]}
          @{[ $num eq 'TMPL' ? "</template>" : '' ]}
  HTML
}
print <<"HTML";
      </table>
      <div class="add-del-button"><a onclick="addArmour()">▼</a><a onclick="delArmour()">▲</a></div>
      @{[ input 'armourNum','hidden' ]}
    </div>
    <div class="box">
      <h2 class="in-toc">由来・逸話</h2>
      <textarea name="description">$pc{description}</textarea>
    </div>
    </section>
      
      @{[ colorCostomForm ]}
    
      @{[ input 'birthTime','hidden' ]}
      <input type="hidden" name="id" value="$::in{id}">
    </form>
    @{[ deleteForm($mode) ]}
    </article>
HTML
# ヘルプ
my $text_rule = <<"HTML";
        アイコン<br>
        　魔法のアイテム：<code>[魔]</code>：<img class="i-icon" src="${set::icon_dir}item_magic.png"><br>
        　刃武器　　　　：<code>[刃]</code>：<img class="i-icon" src="${set::icon_dir}item_edge.png"><br>
        　打撃武器　　　：<code>[打]</code>：<img class="i-icon" src="${set::icon_dir}item_blow.png"><br>
        　地方特産品　　：<code>[特]</code>：<img class="i-icon" src="${set::icon_dir}item_local.png"><br>
HTML
if ($::SW2_0) {
  $text_rule .= <<~"HTML";
        　流派装備　　　：<code>[流]</code>：<img class="i-icon" src="${set::icon_dir}item_school.png"><br>
  HTML
}
else {
  $text_rule .= <<~"HTML";
        　流派アイテム　：<code>[流]</code>：<img class="i-icon" src="${set::icon_dir}item_school.png"><br>
        　アルフレイム大陸由来の流派アイテム：<code>[ア]</code>：<img class="i-icon" src="${set::icon_dir}item_school_a.png"><br>
        　テラスティア大陸由来の流派アイテム：<code>[テ]</code>：<img class="i-icon" src="${set::icon_dir}item_school_t.png"><br>
        　高揚の楽素：<code>[⤴]</code><code>[↑]</code>：<i class="s-icon uplift">⤴</i><br>
        　鎮静の楽素：<code>[⤵]</code><code>[↓]</code>：<i class="s-icon calm">⤵</i><br>
        　魅惑の楽素：<code>[♡]</code>：<i class="s-icon heart">♡</i><br>
  HTML
}
print textRuleArea( $text_rule,'「効果」「解説」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">(C)Group SNE「ソード・ワールド2.0／2.5」</p>
    <p class="copyright">©<a href="https://yutorize.work">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
  </footer>
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
  <script>
@{[ &commonJSVariable ]}
  </script>
</body>
</html>
HTML

1;