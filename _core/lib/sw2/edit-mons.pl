############# フォーム・モンスター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_mons;

### データ読み込み ###################################################################################
my ($data, $mode, $file, $message) = getSheetData($::in{mode});
our %pc = %{ $data };

my $mode_make = ($mode =~ /^(blanksheet|copy|convert)$/) ? 1 : 0;

### 出力準備 #########################################################################################
if($message){
  my $name = unescapeTags($pc{characterName} || $pc{monsterName} || '無題');
  $message =~ s/<!NAME>/$name/;
}
### 製作者名 --------------------------------------------------
if($mode_make){
  $pc{author} = (getplayername($LOGIN_ID))[0];
}
### 初期設定 --------------------------------------------------
if($mode_make){ $pc{protect} = $LOGIN_ID ? 'account' : 'password'; }

if($mode eq 'blanksheet'){
  $pc{paletteUseBuff} = 1;
}

## カラー
setDefaultColors();

## その他
$pc{partsNum}  ||= 1;
$pc{statusNum} ||= 1;
$pc{lootsNum}  ||= 2;

my $status_text_input = $pc{statusTextInput} || $pc{mount} || 0;

### 改行処理 --------------------------------------------------
$pc{skills}      =~ s/&lt;br&gt;/\n/g;
$pc{description} =~ s/&lt;br&gt;/\n/g;
$pc{chatPalette} =~ s/&lt;br&gt;/\n/g;

### フォーム表示 #####################################################################################
my $title;
if ($mode eq 'edit') {
  $title = '編集：';
  if ($pc{characterName}) {
    $title .= $pc{characterName};
    $title .= "（$pc{monsterName}）" if $pc{monsterName};
  }
  else {
    $title .= $pc{monsterName};
  }
}
else {
  $title = '新規作成';
}
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>$title - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/base.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/sheet.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/monster.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/sw2/edit-mons.js?${main::ver}" defer></script>
</head>
<body>
  <script src="${main::core_dir}/skin/_common/js/common.js?${main::ver}"></script>
  <header>
    <h1>$set::title</h1>
  </header>

  <main>
    <article>
      <form id="monster" name="sheet" method="post" action="./" enctype="multipart/form-data" class="@{[ $pc{statusTextInput} ? 'not-calc' : '' ]}">
      <input type="hidden" name="ver" value="${main::ver}">
      <input type="hidden" name="type" value="m">
HTML
if($mode_make){
  print '<input type="hidden" name="_token" value="'.tokenMake().'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      
      <div id="header-menu">
        <h2><span></span></h2>
        <ul>
          <li onclick="sectionSelect('common');"><span>魔物</span><span>データ</span>
          <li onclick="sectionSelect('palette');"><span><span class="shorten">ユニット(</span>コマ<span class="shorten">)</span></span><span>設定</span>
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
      <div class="box in-toc" id="group" data-content-title="分類・タグ">
        <dl>
          <dt>分類</dt>
          <dd>
            <div class="select-input">
              <select name="taxa" oninput="selectInputCheck(this,'その他')">
HTML
foreach (@data::taxa){
  print '<option '.($pc{taxa} eq @$_[0] ? ' selected': '').'>'.@$_[0].'</option>';
}
if($pc{taxa} && !grep { @$_[0] eq $pc{taxa} } @data::taxa){
  print '<option selected>'.$pc{taxa}.'</option>'."\n";
}
print <<"HTML";
              </select>
              <input type="text" name="taxaFree">
            </div>
          <dd>@{[ checkbox 'mount','騎獣','checkMount' ]}
          <dt>タグ
          <dd>@{[ input 'tags' ]}
        </dl>
      </div>

      <div class="box in-toc" id="name-form" data-content-title="名称・製作者">
        <div>
          <dl id="character-name">
            <dt>名称
            <dd>@{[ input('monsterName','text',"setName") ]}
          </dl>
          <dl id="aka">
            <dt>名前
            <dd>@{[ input 'characterName','text','setName','placeholder="※名前を持つ魔物のみ"' ]}
          </dl>
        </div>
        <dl id="player-name">
          <dt>製作者
          <dd>@{[input('author')]}
        </dl>
      </div>

      <div class="box status in-toc" data-content-title="基本データ">
        <dl class="mount-only price">
          <dt>価格
          <dd>購入@{[ input 'price' ]}G
          <dd>レンタル@{[ input 'priceRental' ]}G
          <dd>部位再生@{[ input 'priceRegenerate' ]}G
        </dl>
        <dl class="mount-only">
          <dt>適正レベル
          <dd>@{[ input 'lvMin','number','checkMountLevel','min="0"' ]} ～ @{[ input 'lvMax','number','checkMountLevel','min="0"' ]}
        </dl>
        <dl>
          <dt><span class="mount-only">騎獣</span>レベル
          <dd>@{[ input 'lv','number','checkLevel','min="0"' ]}
          <dd class="mount-only small">※入力すると、閲覧画面では現在の騎獣レベルのステータスのみ表示されます
        </dl>
        <dl>
          <dt>知能
          <dd>@{[ input 'intellect','','','list="data-intellect"' ]}
        </dl>
        <dl>
          <dt>知覚
          <dd>@{[ input 'perception','','','list="data-perception"' ]}
        </dl>
        <dl class="monster-only">
          <dt>反応
          <dd>@{[ input 'disposition','','','list="data-disposition"' ]}
        </dl>
        <dl>
          <dt>穢れ
          <dd>@{[ input 'sin','number','','min="0"' ]}
        </dl>
        <dl>
          <dt>言語
          <dd>@{[ input 'language' ]}
        </dl>
        <dl class="monster-only">
          <dt>生息地
          <dd>@{[ input 'habitat' ]}
        </dl>
        <dl class="monster-only">
          <dt>知名度／弱点値
          <dd>@{[ input 'reputation' ]}／@{[ input 'reputation+','','','list="list-of-reputation-plus"' ]}
        </dl>
        <dl>
          <dt>弱点
          <dd>@{[ input 'weakness','','','list="data-weakness"' ]}
        </dl>
        <dl class="monster-only">
          <dt>先制値
          <dd>@{[ input 'initiative' ]}
        </dl>
        <dl>
          <dt>移動速度<dd>@{[ input 'mobility' ]}
        </dl>
        <dl class="monster-only">
          <dt>生命抵抗力
          <dd>@{[ input 'vitResist',($status_text_input ? 'text':'number'),'calcVit' ]} <span class=" calc-only">(@{[ input 'vitResistFix','number','calcVitF' ]})</span>
        </dl>
        <dl class="monster-only">
          <dt>精神抵抗力
          <dd>@{[ input 'mndResist',($status_text_input ? 'text':'number'),'calcMnd' ]} <span class=" calc-only">(@{[ input 'mndResistFix','number','calcMndF' ]})</span>
        </dl>
      </div>
      <p class="monster-only">@{[ input "statusTextInput",'checkbox','statusTextInputToggle']}命中・回避・抵抗に数値以外を入力</p>
      <div class="box in-toc" data-content-title="攻撃方法・命中・打撃・回避・防護・ＨＰ・ＭＰ">
      <table id="status-table" class="status">
        <thead>
          <tr>
            <th class="lv mount-only">Lv
            <th class="handle">
            <th class="name">攻撃方法<span class="text-part">（部位）</span>
            <th class="acc">命中力
            <th class="atk">打撃点
            <th class="eva">回避力
            <th class="def">防護点
            <th class="hp">ＨＰ
            <th class="mp">ＭＰ
            <th class="vit mount-only">生命抵抗
            <th class="mnd mount-only">精神抵抗
            <th>
          </tr>
        <tbody id="status-tbody">
HTML
foreach my $num (1 .. $pc{statusNum}){
  $pc{"status${num}Damage"} = '2d+' if $pc{"status${num}Damage"} eq '' && $mode eq 'blanksheet';
  print <<"HTML";
        <tr id="status-row${num}">
          <th class="mount-only">
          <td class="handle">
          <td>@{[ input "status${num}Style",'text',"checkStyle(${num})" ]}
          <td>@{[ input "status${num}Accuracy",($status_text_input ? 'text':'number'),"calcAcc($num)" ]}<span class="monster-only calc-only"><br>(@{[ input "status${num}AccuracyFix",'number',"calcAccF($num)" ]})</span>
          <td>@{[ input "status${num}Damage" ]}
          <td>@{[ input "status${num}Evasion",($status_text_input ? 'text':'number'),"calcEva($num)" ]}<span class="monster-only calc-only"><br>(@{[ input "status${num}EvasionFix",'number',"calcEvaF($num)" ]})</span>
          <td>@{[ input "status${num}Defense" ]}
          <td>@{[ input "status${num}Hp" ]}
          <td>@{[ input "status${num}Mp" ]}
          <td class="mount-only">@{[ input "status${num}Vit" ]}
          <td class="mount-only">@{[ input "status${num}Mnd" ]}
          <td><span class="button" onclick="addStatus(${num});">複<br>製</span>
HTML
}
print <<"HTML";
        </tbody>
HTML
foreach my $lv (2 .. ($pc{lvMax}-$pc{lvMin}+1)){
  print <<"HTML";
        <tbody class="mount-only" id="status-tbody${lv}" data-lv="${lv}">
HTML
  foreach my $num (1 .. $pc{statusNum}){
    $pc{"status${num}Damage"} = '2d6+' if $pc{"status${num}Damage"} eq '' && $mode eq 'blanksheet';
    print <<"HTML";
        <tr id="status-row${num}-${lv}">
          <th>
          <td>
          <td class="name" data-style="${num}">$pc{"status${num}Style"}
          <td>@{[ input "status${num}-${lv}Accuracy",($status_text_input ? 'text':'number') ]}
          <td>@{[ input "status${num}-${lv}Damage" ]}
          <td>@{[ input "status${num}-${lv}Evasion",($status_text_input ? 'text':'number') ]}
          <td>@{[ input "status${num}-${lv}Defense" ]}
          <td>@{[ input "status${num}-${lv}Hp" ]}
          <td>@{[ input "status${num}-${lv}Mp" ]}
          <td>@{[ input "status${num}-${lv}Vit" ]}
          <td>@{[ input "status${num}-${lv}Mnd" ]}
          <td>
HTML
  }
  print <<"HTML";
        </tbody>
HTML
}
print <<"HTML";
      </table>
      <div class="add-del-button"><a onclick="addStatus()">▼</a><a onclick="delStatus()">▲</a></div>
      @{[input('statusNum','hidden')]}
      </div>
      <div class="box parts in-toc" data-content-title="部位数・コア部位">
        <dl><dt>部位数<dd>@{[ input 'partsNum','number','','min="1"' ]} (@{[ input 'parts' ]}) </dl>
        <dl><dt>コア部位<dd>@{[ input 'coreParts' ]}</dl>
      </div>
      <div class="box">
        <h2 class="in-toc">特殊能力</h2>
        <textarea name="skills">$pc{skills}</textarea>
        <div class="annotate">
          <b>行頭に</b>特殊能力の分類マークなどを記述すると、そこから次の「改行」または「全角スペース」までを自動的に見出し化します。<br>
           2.0での分類マークでも構いません。また、入力簡易化の為に入力しやすい代替文字での入力も可能です。<br>
           以下に見出しとして変換される記号・文字列を一覧にしています。<br>
          部位見出し（●）：<code>●</code><br>
          常時型　　（<i class="s-icon passive"></i>）：<code>[常]</code><code>○</code> <code>◯</code> <code>〇</code><br>
HTML
if($::SW2_0){
print <<"HTML";
          主動作型　（<i class="s-icon major0"   ></i>）：<code>[主]</code><code>＞</code> <code>▶</code> <code>〆</code><br>
          補助動作型（<i class="s-icon minor0"   ></i>）：<code>[補]</code><code>≫</code> <code>&gt;&gt;</code> <code>☆</code><br>
          宣言型　　（<i class="s-icon active0"  ></i>）：<code>[宣]</code><code>🗨</code> <code>□</code> <code>☑</code><br>
          条件型　　（<i class="s-icon condition"></i>）：<code>[条]</code><code>▽</code><br>
          条件選択型（<i class="s-icon selection"></i>）：<code>[選]</code><code>▼</code><br>
HTML
} else {
print <<"HTML";
          戦闘準備型（<i class="s-icon setup"  ></i>）：<code>[準]</code><code>△</code><br>
          主動作型　（<i class="s-icon major"  ></i>）：<code>[主]</code><code>＞</code> <code>▶</code> <code>〆</code><br>
          補助動作型（<i class="s-icon minor"  ></i>）：<code>[補]</code><code>≫</code> <code>&gt;&gt;</code> <code>☆</code><br>
          宣言型　　（<i class="s-icon active" ></i>）：<code>[宣]</code><code>🗨</code> <code>□</code> <code>☑</code><br>
HTML
}
print <<"HTML";
          <code>[]</code>で漢字一文字を囲う記法は、行頭でなくても各マークに変換されます。
        </div>
      </div>
      <div class="box loots monster-only">
        <h2 class="in-toc">戦利品</h2>
        <div id="loots-list">
          <ul id="loots-num">
HTML
foreach my $num (1 .. $pc{lootsNum}){ print "<li id='loots-num${num}'><span class='handle'></span>".input("loots${num}Num"); }
print <<"HTML";
          </ul>
          <ul id="loots-item">
HTML
foreach my $num (1 .. $pc{lootsNum}){ print "<li id='loots-item${num}'><span class='handle'></span>".input("loots${num}Item"); }
print <<"HTML";
        </ul>
      </div>
      <div class="add-del-button"><a onclick="addLoots()">▼</a><a onclick="delLoots()">▲</a></div>
      @{[input('lootsNum','hidden')]}
      </div>
      <div class="box">
        <h2 class="in-toc">解説</h2>
        <textarea name="description">$pc{description}</textarea>
      </div>
      </section>
      
      @{[ chatPaletteForm ]}
      
      @{[ colorCostomForm ]}
    
      @{[ input 'birthTime','hidden' ]}
      @{[ input 'id','hidden' ]}
    </form>
    @{[ deleteForm($mode) ]}
    </article>
HTML
# ヘルプ
print textRuleArea( '','「特殊能力」「解説」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">(C)Group SNE「ソード・ワールド2.0／2.5」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
  </footer>
  <datalist id="data-intellect">
  <option value="なし">
  <option value="動物並み">
  <option value="低い">
  <option value="人間並み">
  <option value="高い">
  <option value="命令を聞く">
  </datalist>
  <datalist id="data-perception">
  <option value="五感">
  <option value="五感（暗視）">
  <option value="五感（）">
  <option value="魔法">
  <option value="機械">
  </datalist>
  <datalist id="data-disposition">
  <option value="友好的">
  <option value="中立">
  <option value="敵対的">
  <option value="腹具合による">
  <option value="命令による">
  </datalist>
  <datalist id="list-of-reputation-plus">
    <option>―</option>
  </datalist>
  <datalist id="data-weakness">
  <option value="命中力+1">
  <option value="物理ダメージ+2点">
  <option value="魔法ダメージ+2点">
  <option value="属性ダメージ+3点">
  <option value="回復効果ダメージ+3点">
  <option value="なし">
  </datalist>
  <script>
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;
