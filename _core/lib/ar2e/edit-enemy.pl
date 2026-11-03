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
$message = applyMessageName($message, $pc{enemyName} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{author} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode =~ /^(?:convert|copy)$/ && $pc{ver})){
  %pc = upgradeCharaData(\%pc);
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

  $pc{makeLv} = 1;
  
  $pc{moneyAuto} = 1;

  %pc = applyCustomizedInitialValues(\%pc, 'e');
}

## カラー
setDefaultColors(\%pc);

## その他
$pc{attackNum} ||= 1;
$pc{lootNum}  ||= 3;

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
    qw/skills description chatPalette/,
);

### 画像 --------------------------------------------------
my $imageMaxSize = $set::image_maxsize / 2;
my $imageMaxSizeView = $imageMaxSize >= 1048576 ? sprintf("%.3g",$imageMaxSize/1048576).'MB' : sprintf("%.3g",$imageMaxSize/1024).'KB';

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ( $pc{enemyName} )),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>エネミー</span></span><span>データ</span>
    <li onclick="sectionSelect('palette');" class="unit-setting"><span><span class="shorten">ユニット(</span>コマ<span class="shorten">)</span></span><span>設定</span>
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
          if(@set::groups_enemy) {
            <<~"HTML";
              <dt>グループ
              <dd><select name="group">@{[ renderGroupOptions(@set::groups_enemy) ]}</select>
            HTML
          }
          else { "" }
        } }
        <dt>タグ
        <dd @{[ @set::groups_enemy ? '' : 'style="grid-column:span 3;"' ]}>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="エネミー名">
      <div>
        <dl id="character-name">
          <dt>エネミー名
          <dd>@{[ input 'enemyName','text',"setName",'id="main-name" required' ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>データ製作者
        <dd>@{[ input 'author' ]}
      </dl>
    </div>

    <div class="box" id="area-status">
      <div id="base-data">
        <dl><dt>分類<dd>@{[ selectInput "taxon",'', qw/植物 動物 人間 妖精 妖魔 アンデッド 精霊 人造生物 機械 魔獣 霊獣 巨人 竜 魔族/ ]} (@{[ input "race",'','','placeholder="種族名"' ]})</dl>
        <dl><dt>属性<dd>@{[ selectBox "element",'', qw/― 地 水 火 風 光 闇/ ]}</dl>
        <dl><dt>レベル<dd>@{[ input "level",'number','','min="0" max="9999"' ]} @{[ checkbox "isMob", "モブ", 'checkEnemyType' ]}</dl>
        <dl><dt>識別値<dd>@{[ input "identifyTarget",'number' ]}</dl>
      </div>
      <div id="status-mob">
        <dl><dt>判定<dd>@{[ input "action",'number' ]}／@{[ input "reaction",'number' ]}</dl>
      </div>
      <div id="status-solo">
        <dl><dt>筋力<dd>@{[ input "sttStrBase",'number','calcStatus' ]}／@{[ input "sttStr",'number','','readonly' ]}</dl>
        <dl><dt>器用<dd>@{[ input "sttDexBase",'number','calcStatus' ]}／@{[ input "sttDex",'number','','readonly' ]}</dl>
        <dl><dt>敏捷<dd>@{[ input "sttAgiBase",'number','calcStatus' ]}／@{[ input "sttAgi",'number','','readonly' ]}</dl>
        <dl><dt>知力<dd>@{[ input "sttIntBase",'number','calcStatus' ]}／@{[ input "sttInt",'number','','readonly' ]}</dl>
        <dl><dt>感知<dd>@{[ input "sttSenBase",'number','calcStatus' ]}／@{[ input "sttSen",'number','','readonly' ]}</dl>
        <dl><dt>精神<dd>@{[ input "sttMndBase",'number','calcStatus' ]}／@{[ input "sttMnd",'number','','readonly' ]}</dl>
        <dl><dt>幸運<dd>@{[ input "sttLukBase",'number','calcStatus' ]}／@{[ input "sttLuk",'number','','readonly' ]}</dl>
      </div>
      <div id="status-battle">
        <dl><dt>回避<dd>@{[ input "dodge",'number' ]}</dl>
        <dl><dt>防御<dd>@{[ input "armorP",'number' ]}／@{[ input "armorM",'number' ]}</dl>
        <dl><dt>ＨＰ<dd>@{[ input "hp",'number' ]}</dl>
        <dl><dt>ＭＰ<dd>@{[ input "mp",'number' ]}</dl>
        <dl><dt>行動<dd>@{[ input "initiative",'number' ]}</dl>
        <dl><dt>移動<dd>@{[ input "mobility",'number' ]}</dl>
      </div>
    </div>

    <div class="box" id="attack">
      <h2 class="in-toc">攻撃</h2>
      <table class="edit-table no-border-cells">
        <thead>
          <tr>
            <th>
            <th class="name "><span class="small">使用する武器（武器種別／装備部位）<br>または 使用するスキル名とレベル</span>
            <th class="acc  ">命中判定
            <th class="dmg  ">ダメージ
            <th class="type "><span class="small">攻撃方法と<br>ダメージ種別</span>
            <th class="range">射程
        <tbody>
          @{[ renderTemplateLoop(
            'attack',
            sub ($num) {
              return <<~"ROW";
              <tr id="attack-row${num}">
                <td class="handle">
                <td class="name ">@{[ input "attack${num}Name",'','','list="list-attack-name"' ]}
                <td class="acc  ">@{[ input "attack${num}Acc",'number' ]}(@{[ input "attack${num}AccDice",'number' ]}D)
                <td class="dmg  ">@{[ input "attack${num}Dmg",'number' ]}(@{[ input "attack${num}DmgDice",'number' ]}D)
                <td class="type ">@{[ input "attack${num}Type",'','','list="list-attack-type"' ]}（@{[ input "attack${num}DmgType",'','','list="list-damage-type"' ]}）
                <td class="range">@{[ input "attack${num}Range",'','','list="list-range"' ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('attack') ]}
    </div>

    <div class="box" id="skills">
      <h2 class="in-toc">エネミースキル</h2>
      @{[ textarea "skills" ]}
    </div>
    <div class="box" id="description">
      <h2 class="in-toc">解説</h2>
      @{[ textarea "description" ]}
    </div>
    <div class="box" id="loot">
      <h2 class="in-toc">ドロップ品</h2>
      <div id="loot-list">
        <ul id="loot-num">
          @{[ map {
            "<li id='loot-num${_}'><span class='handle'></span>".input("loot${_}Num")
          } 1 .. $pc{lootNum} ]}
        </ul>
        <ul id="loot-item">
          @{[ map {
            "<li id='loot-item${_}'><span class='handle'></span>".input("loot${_}Item")
          } 1 .. $pc{lootNum} ]}
        </ul>
      </div>
      @{[ renderAddDelButtons('loot') ]}
    </div>
  </section>
HTML
print renderChatPaletteForm();

print renderEditPageEnd(
  notes => '©FarEast Amusement Research Co.,Ltd.「アリアンロッドRPG 2E」',
  extraHtml => renderDataList(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-taxa">
    <option value="植物">
    <option value="動物">
    <option value="人間">
    <option value="妖精">
    <option value="妖魔">
    <option value="アンデッド">
    <option value="精霊">
    <option value="人造生物">
    <option value="機械">
    <option value="魔獣">
    <option value="霊獣">
    <option value="巨人">
    <option value="竜">
    <option value="魔族">
  </datalist>
  <datalist id="list-attack-name">
    <option value="（／）">
    <option value="《》">
  </datalist>
  <datalist id="list-attack-type">
    <option value="白兵">
    <option value="射撃">
    <option value="投射">
    <option value="魔法">
    <option value="特殊">
  </datalist>
  <datalist id="list-damage-type">
    <option value="物理">
    <option value="貫通">
    <option value="魔法〈無〉">
    <option value="魔法〈地〉">
    <option value="魔法〈水〉">
    <option value="魔法〈火〉">
    <option value="魔法〈風〉">
    <option value="魔法〈光〉">
    <option value="魔法〈闇〉">
  </datalist>
  <datalist id="list-range">
    <option value="―">
    <option value="10m">
    <option value="20m">
    <option value="30m">
    <option value="至近">
    <option value="視界">
    <option value="シーン">
  </datalist>
  HTML
}

1;
