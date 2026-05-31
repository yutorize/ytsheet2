############# フォーム・モンスター #############
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
require $set::data_mons;

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{characterName} || $pc{monsterName} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{author} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}
if($::mode eq 'edit' || ($::mode eq 'convert' && $pc{ver})){
  %pc = data_update_mons(\%pc);
}
elsif($::mode eq 'blanksheet'){
  $pc{paletteUseBuff} = 1;
  $pc{partsManualInput} = 0;

  %pc = applyCustomizedInitialValues(\%pc, 'm');
}

## カラー
setDefaultColors(\%pc);

## その他
$pc{partsNum}  ||= 1;
$pc{statusNum} ||= 1;
$pc{lootsNum}  ||= 2;

my $status_text_input = $pc{statusTextInput} || $pc{mount} || 0;

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/skills description chatPalette/,
);

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ( $pc{characterName} || $pc{monsterName} )),
  systemId => ($::SW2_0 ? 'sw2.0' : 'sw2.5'),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>魔物</span><span>データ</span>
    <li onclick="sectionSelect('palette');" class="unit-setting"><span><span class="shorten">ユニット(</span>コマ<span class="shorten">)</span></span><span>設定</span>
  HTML
);
print qq|<aside class="message">$message</aside>| if $message;

print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box in-toc" id="group" data-content-title="分類・タグ">
      <dl>
        <dt>分類</dt>
        <dd>
          <div class="select-input">
            <select name="taxa" oninput="selectInputCheck(this,'その他')">
            @{[
              map { '<option '. ($pc{taxa} eq @$_[0] ? ' selected': '') .">@$_[0]</option>" } @data::taxa
            ]}
            @{[
              ($pc{taxa} && !grep { @$_[0] eq $pc{taxa} } @data::taxa) ? "<option selected>$pc{taxa}</option>" : ''
            ]}
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
          <dd>@{[ input 'monsterName','text',"setName",'id="sub-name"' ]}
        </dl>
        <dl id="aka">
          <dt>名前
          <dd>@{[ input 'characterName','text','setName','id="main-name" placeholder="※名前を持つ魔物のみ"' ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>製作者
        <dd>@{[ input 'author' ]}
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
        <dd>@{[ input 'language','','','list="data-language"' ]}
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
        @{[ map {
          my $num = $_;
          $pc{"status${num}Damage"} = '2d+' if $pc{"status${num}Damage"} eq '' && $::mode eq 'blanksheet';
          <<~"ROW";
          <tr id="status-row${num}">
            <th class="mount-only">
            <td class="handle">
            <td>@{[ input "status${num}Style",'text',"checkStyle(${num}); updatePartsAutomatically()" ]}
            <td>@{[ input "status${num}Accuracy",($status_text_input ? 'text':'number'),"calcAcc($num)" ]}<span class="monster-only calc-only"><br>(@{[ input "status${num}AccuracyFix",'number',"calcAccF($num)" ]})</span>
            <td>@{[ input "status${num}Damage" ]}
            <td>@{[ input "status${num}Evasion",($status_text_input ? 'text':'number'),"calcEva($num)" ]}<span class="monster-only calc-only"><br>(@{[ input "status${num}EvasionFix",'number',"calcEvaF($num)" ]})</span>
            <td>@{[ input "status${num}Defense" ]}
            <td>@{[ input "status${num}Hp" ]}
            <td>@{[ input "status${num}Mp" ]}
            <td class="mount-only">@{[ input "status${num}Vit" ]}
            <td class="mount-only">@{[ input "status${num}Mnd" ]}
            <td><span class="button" onclick="addStatus(${num});">複<br>製</span>
          ROW
        } 1 .. $pc{statusNum} ]}
        @{[ map {
          my $lv = $_;
          <<~"TBODY";
          <tbody class="mount-only" id="status-tbody${lv}" data-lv="${lv}">
          @{[
            map {
              my $num = $_;
              $pc{"status${num}Damage"} = '2d+' if $pc{"status${num}Damage"} eq '' && $::mode eq 'blanksheet';
              <<~"ROW";
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
              ROW
            } 1 .. $pc{statusNum}
          ]}
          TBODY
        } 2 .. ($pc{lvMax}-$pc{lvMin}+1) ]}
    </table>
    @{[ renderAddDelButtons('status') ]}
    </div>
    <div class="box parts in-toc" data-content-title="部位数・コア部位">
      @{[ checkbox 'partsManualInput', '部位数と内訳を手動入力する', 'updatePartsAutomatically' ]}
      <dl><dt>部位数<dd>@{[ input 'partsNum','number','','min="1"' ]} (@{[ input 'parts','','updatePartList' ]}) </dl>
      <dl><dt>コア部位<dd>@{[ input 'coreParts','','','list="list-of-core-part"' ]}</dl>
      <datalist id="list-of-core-part"></datalist>
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
        ${\ do {
          if($::SW2_0){
            <<~"HTML";
            主動作型　（<i class="s-icon major0"   ></i>）：<code>[主]</code><code>＞</code> <code>▶</code> <code>〆</code><br>
            補助動作型（<i class="s-icon minor0"   ></i>）：<code>[補]</code><code>≫</code> <code>&gt;&gt;</code> <code>☆</code><br>
            宣言型　　（<i class="s-icon active0"  ></i>）：<code>[宣]</code><code>🗨</code> <code>□</code> <code>☑</code><br>
            条件型　　（<i class="s-icon condition"></i>）：<code>[条]</code><code>▽</code><br>
            条件選択型（<i class="s-icon selection"></i>）：<code>[選]</code><code>▼</code><br>
            HTML
          } else {
            <<~"HTML";
            戦闘準備型（<i class="s-icon setup"  ></i>）：<code>[準]</code><code>△</code><br>
            主動作型　（<i class="s-icon major"  ></i>）：<code>[主]</code><code>＞</code> <code>▶</code> <code>〆</code><br>
            補助動作型（<i class="s-icon minor"  ></i>）：<code>[補]</code><code>≫</code> <code>&gt;&gt;</code> <code>☆</code><br>
            宣言型　　（<i class="s-icon active" ></i>）：<code>[宣]</code><code>🗨</code> <code>□</code> <code>☑</code><br>
            HTML
          }
        } }
        <code>[]</code>で漢字一文字を囲う記法は、行頭でなくても各マークに変換されます。
      </div>
    </div>
    <div class="box loots monster-only">
      <h2 class="in-toc">戦利品</h2>
      <div id="loots-list">
        <ul id="loots-num">
          @{[ map {
            "<li id='loots-num${_}'><span class='handle'></span>".input("loots${_}Num",'','','list="data-roots-num"')
          } 1 .. $pc{lootsNum} ]}
        </ul>
        <ul id="loots-item">
          @{[ map {
            "<li id='loots-item${_}'><span class='handle'></span>".input("loots${_}Item")
          } 1 .. $pc{lootsNum} ]}
        </ul>
      </div>
      @{[ renderAddDelButtons('loots') ]}
    </div>
    <div class="box">
      <h2 class="in-toc">解説</h2>
      <textarea name="description">$pc{description}</textarea>
    </div>
  </section>
HTML
print renderChatPaletteForm();

print renderEditPageEnd(
  notes => '(C)Group SNE「ソード・ワールド'.($::SW2_0 ? '2.0' : '2.5').'」',
  multilineTargets => '「特殊能力」「解説」',
  addTextRule => renderAddTextRule(),
  extraHtml => renderDataList(),
);

sub renderDataList {
  return <<~"HTML";
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
  <datalist id="data-language">
    <option value="なし">
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
  <datalist id="data-roots-num">
    <option value="自動">
  </datalist>
  HTML
}

1;
