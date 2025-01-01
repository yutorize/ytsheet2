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
my ($data, $mode, $file, $message) = getSheetData($::in{mode});
our %pc = %{ $data };

my $mode_make = ($mode =~ /^(blanksheet|copy|convert)$/) ? 1 : 0;

### 出力準備 #########################################################################################
if($message){
  my $name = unescapeTags($pc{itemName} || '無題');
  $message =~ s/<!NAME>/$name/;
}
### 製作者名 --------------------------------------------------
if($mode_make){
  $pc{author} = (getplayername($LOGIN_ID))[0];
}
### 初期設定 --------------------------------------------------
if($mode_make){ $pc{protect} = $LOGIN_ID ? 'account' : 'password'; }

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
Content-type: text/html\n
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
if($mode_make){
  print '<input type="hidden" name="_token" value="'.tokenMake().'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
            
      <div id="header-menu">
        <h2><span></span></h2>
        <ul>
          <li onclick="sectionSelect('common');"><span>アイテム</span><span>データ</span>
          <li onclick="sectionSelect('color');" class="color-icon" title="カラーカスタム">
          <li onclick="view('text-rule')" class="help-icon" title="テキスト整形ルール">
          <li onclick="nightModeChange()" class="nightmode-icon" title="ナイトモード切替">
          <li onclick="exportAsJson()" class="download-icon" title="JSON出力">
          <li class="buttons">
            <ul>
              <li @{[ display ($mode eq 'edit') ]} class="view-icon" title="閲覧画面"><a href="./?id=$::in{id}"></a>
              <li @{[ display ($mode eq 'edit') ]} class="copy" onclick="window.open('./?mode=copy&id=$::in{id}@{[  $::in{log}?"&log=$::in{log}":'' ]}');">複製
              <li class="submit" onclick="formSubmit()" title="Ctrl+S">保存
            </ul>
          </li>
        </ul>
        <div id="save-state"></div>
      </div>

      <aside class="message">$message</aside>
      
      <section id="section-common">
HTML
if($set::user_reqd){
  print <<"HTML";
    <input type="hidden" name="protect" value="account">
    <input type="hidden" name="protectOld" value="$pc{protect}">
    <input type="hidden" name="pass" value="$::in{pass}">
HTML
}
else {
  if($set::registerkey && $mode_make){
    print '登録キー：<input type="text" name="registerkey" required>'."\n";
  }
  print <<"HTML";
      <details class="box" id="edit-protect" @{[$mode eq 'edit' ? '':'open']}>
      <summary>編集保護設定</summary>
      <fieldset id="edit-protect-view"><input type="hidden" name="protectOld" value="$pc{protect}">
HTML
  if($LOGIN_ID){
    print '<input type="radio" name="protect" value="account"'.($pc{protect} eq 'account'?' checked':'').'> アカウントに紐付ける（ログイン中のみ編集可能になります）<br>';
  }
    print '<input type="radio" name="protect" value="password"'.($pc{protect} eq 'password'?' checked':'').'> パスワードで保護 ';
  if ($mode eq 'edit' && $pc{protect} eq 'password') {
    print '<input type="hidden" name="pass" value="'.$::in{pass}.'"><br>';
  } else {
    print '<input type="password" name="pass"><br>';
  }
  print <<"HTML";
<input type="radio" name="protect" value="none"@{[ $pc{protect} eq 'none'?' checked':'' ]}> 保護しない（誰でも編集できるようになります）
      </fieldset>
      </details>
HTML
}
  print <<"HTML";
      <dl class="box" id="hide-options">
        <dt>閲覧可否設定
        <dd id="forbidden-checkbox">
          <select name="forbidden">
            <option value="">内容を全て開示
            <option value="battle" @{[ $pc{forbidden} eq 'battle' ? 'selected' : '' ]}>データ・数値のみ秘匿
            <option value="all"    @{[ $pc{forbidden} eq 'all'    ? 'selected' : '' ]}>内容を全て秘匿
          </select>
        <dd id="hide-checkbox">
          <select name="hide">
            <option value="">一覧に表示
            <option value="1" @{[ $pc{hide} ? 'selected' : '' ]}>一覧には非表示
          </select>
        <dd>※「一覧に非表示」でもタグ検索結果・マイリストには表示されます
      </dl>
      <div class="box" id="group">
        <dl>
          <dt>タグ<dd>@{[ input 'tags' ]}
        </dl>
      </div>

      <div class="box in-toc" id="name-form" data-content-title="名称・製作者">
        <div>
          <dl id="character-name">
            <dt>名称
            <dd>@{[ input('itemName','text',"setName('itemName')",'list="list-item-name"') ]}
          </dl>
        </div>
        <dl id="player-name">
          <dt>製作者
          <dd>@{[input('author')]}
        </dl>
      </div>
      
      <div class="box input-data in-toc" data-content-title="基本データ">
      <label>@{[ input 'magic', 'checkbox' ]}<span>魔法のアイテム</span></label>
      <!-- <label>@{[ input 'school', 'checkbox' ]}　流派装備</label> -->
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
  print <<"HTML";
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
      <code>[刃]</code> <code>[打]</code> でそれぞれ<img class="i-icon" src="${set::icon_dir}wp_edge.png"><img class="i-icon" src="${set::icon_dir}wp_blow.png">に置き換え
      <p>
      <h4 class="in-toc">防具データ</h4>
      <table class="input-arms-data" id="armours-table">
        <thead>
          <tr><th><th>用法<th>必筋<th>回避<th>防護<th>備考
        <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{armourNum}){
  print <<"HTML";
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
        　魔法のアイテム：<code>[魔]</code>：<img class="i-icon" src="${set::icon_dir}wp_magic.png"><br>
        　刃武器　　　　：<code>[刃]</code>：<img class="i-icon" src="${set::icon_dir}wp_edge.png"><br>
        　打撃武器　　　：<code>[打]</code>：<img class="i-icon" src="${set::icon_dir}wp_blow.png"><br>
HTML
print textRuleArea( $text_rule,'「効果」「解説」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">(C)Group SNE「ソード・ワールド2.0／2.5」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
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
    <option value="魔法文明">
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
    <option value="武器や防具の強化">
  </datalist>
  <script>
@{[ &commonJSVariable ]}
  </script>
</body>
</html>
HTML

1;