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
require $set::data_syndrome;

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{enemyName} || $pc{aka} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{author} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode =~ /^(?:convert|copy)$/ && $pc{ver})){
  %pc = upgradeEnemyData(\%pc);
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

  $pc{history0Exp}   = 0;

  $pc{comboNum} = 1;

  $pc{paletteUseBuff} = 1;

  %pc = applyCustomizedInitialValues(\%pc);
}

## 画像・セリフ位置
setDefaultImageStyle(\%pc);
setDefaultWordsPosition(\%pc);

## カラー
setDefaultColors(\%pc);

## その他
$pc{skillRideNum} ||= 2;
$pc{skillArtNum}  ||= 2;
$pc{skillKnowNum} ||= 2;
$pc{skillInfoNum} ||= 2;
$pc{effectNum}  ||= 5;
$pc{attackNum}  ||= 1;
$pc{weaponNum}  ||= 1;
$pc{armorNum}   ||= 0;
$pc{vehicleNum} ||= 0;
$pc{itemNum}    ||= 0;

### 折り畳み判断 --------------------------------------------------
my %open;
foreach (
  'skillMelee','skillRanged','skillRC','skillNegotiate',
  'skillDodge','skillPercept','skillWill','skillProcure',
){
  if ($pc{$_}){ $open{skill} = 'open'; last; }
}
foreach (
    'skillRide','skillArt','skillKnow','skillInfo',
){
  foreach my $num (1..$pc{$_.'Num'}){
    if ($pc{$_.$num}){ $open{skill} = 'open'; last; }
  }
}
if(existsRowStrict "lifepath",'Origin','Experience','Encounter','Awaken','Impulse'){ $open{lifepath} = 'open'; }
foreach (3..$pc{effectNum}){ if(existsRow "effect$_",'Name'){ $open{effect} = 'open'; last; } }
foreach (1..$pc{comboNum}) { if(existsRowStrict "combo$_" ,'Name','Combo'){ $open{combo } = 'open'; last; } }
foreach (1..$pc{attackNum }){ if(existsRow "attack$_" ,'Name'){ $open{attack} = 'open'; last; } }
foreach (1..$pc{weaponNum }){ if(existsRow "weapon$_" ,'Name'){ $open{item} = 'open'; last; } }
foreach (1..$pc{armorNum  }){ if(existsRow "armor$_"  ,'Name'){ $open{item} = 'open'; last; } }
foreach (1..$pc{vehicleNum}){ if(existsRow "vehicle$_",'Name'){ $open{item} = 'open'; last; } }
foreach (1..$pc{itemNum   }){ if(existsRow "item$_"   ,'Name'){ $open{item} = 'open'; last; } }

if(exists $data::syndrome_status{$pc{syndrome1}}){
  $pc{sttSyn1Body} = $pc{sttSyn1Sense}  = $pc{sttSyn1Mind} = $pc{sttSyn1Social} = '';
}
if(exists $data::syndrome_status{$pc{syndrome2}}){
  $pc{sttSyn2Body} = $pc{sttSyn2Sense}  = $pc{sttSyn2Mind} = $pc{sttSyn2Social} = '';
}

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/freeNote chatPalette/,
  ( map { 'words'.$_ } '', 2 .. ($set::image_maxcount || 1) ),
  ( map { "combo${_}Note"   } 1..$pc{comboNum} ),
  ( map { "weapon${_}Note"  } 1..$pc{weaponNum} ),
  ( map { "armor${_}Note"   } 1..$pc{armorNum} ),
  ( map { "vehicle${_}Note" } 1..$pc{vehicleNum} ),
  ( map { "item${_}Note"    } 1..$pc{itemNum} ),
);

### コンボ欄用選択肢 --------------------------------------------------
my @setComboSkills = qw/― 白兵 射撃 RC 交渉 回避 知覚 意志 調達/;
foreach my $id ('Ride','Art','Know','Info'){
  foreach my $num (1 .. $pc{'skill'.$id.'Num'}){
    push(@setComboSkills, $pc{'skill'.$id.$num.'Name'}) if $pc{'skill'.$id.$num.'Name'};
  }
}
push(@setComboSkills, '解説参照');

my @setComboStatus = qw/DEF==>自動（技能に合った能力値） LABEL=▼エフェクト等による差し替え 肉体 感覚 精神 社会/;
### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ($pc{enemyName} || qq|“$pc{aka}”|)),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>エネミー</span><span>データ</span>
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
        <dt class="type">種別
        <dd>@{[
          selectInput 'enemyType','', 
          {value => '一般', text => '一般（ゲスト）'},
          {value => 'トループ'},
          {attr => 'class="crc-only"', label => 'Mエネミー'},
          {value => 'Mエネミー／人間', text => '人間'},
          {value => 'Mエネミー／動物', text => '動物'},
          {value => 'Mエネミー／植物', text => '植物'},
          {value => 'Mエネミー／兵器', text => '兵器'},
          {value => 'Mエネミー／オーヴァード', text => 'オーヴァード'},
          {value => 'Mエネミー／ジャーム', text => 'ジャーム'},
          {value => 'Mエネミー／神話生物', text => '神話生物'},
          {value => 'Mエネミー／アンデッド', text => 'アンデッド'},
          {value => 'Mエネミー／神性', text => '神性'},
          {attr => 'class="crc-only"', label => 'Mエネミー（トループ）'},
          {value => 'Mエネミー／人間（T）', text => '人間（T）'},
          {value => 'Mエネミー／動物（T）', text => '動物（T）'},
          {value => 'Mエネミー／植物（T）', text => '植物（T）'},
          {value => 'Mエネミー／兵器（T）', text => '兵器（T）'},
          {value => 'Mエネミー／オーヴァード（T）', text => 'オーヴァード（T）'},
          {value => 'Mエネミー／ジャーム（T）', text => 'ジャーム（T）'},
          {value => 'Mエネミー／神話生物（T）', text => '神話生物（T）'},
          {value => 'Mエネミー／アンデッド（T）', text => 'アンデッド（T）'},
          {value => 'Mエネミー／神性（T）', text => '神性（T）'},
          {close => 1}
        ]}
        <dt class="stage">ステージ
        <dd>@{[ input 'stage','','checkStage','list="list-stage"' ]}
        <dt class="tags">タグ
        <dd>@{[ input 'tags' ]}
      </dl>
      <ul class="annotate">
       <li>ステージの入力値に「クロウリングケイオス」が“含まれる”場合、専用項目／専用選択肢が表示されます。
      </ul>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="エネミー名">
      <div>
        <dl id="character-name">
          <dt>エネミー名
          <dd>@{[ input 'enemyName','text',"setName",'id="main-name"' ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>データ製作者
        <dd>@{[ input 'author' ]}
      </dl>
    </div>

    <div id="area-status">
      <div class="box in-toc" id="syndrome-status" data-content-title="シンドローム">
        <table>
          <thead>
            <tr>
              <th class="breed"><span class="small">ブリード<span>
              <th class="syndrome">シンドローム
          <tbody class="syndrome-rows">
            <tr>
              <th class="breed" rowspan="3"><span id="breed-value"></span><span class="small">ブリード</span>
              <td>@{[ selectInput 'syndrome1','changeSyndrome(1,this.value)',@data::syndromes ]}
            <tr>
              <td>@{[ selectInput 'syndrome2','changeSyndrome(2,this.value)',@data::syndromes ]}
            <tr>
              <td>@{[ selectInput 'syndrome3','changeSyndrome(3,this.value)',@data::syndromes ]}
          </tbody>
        </table>
      </div>
      <div class="box-union" id="sub-status">
        <dl class="box" id="max-hp">
          <dt>HP
          <dd>@{[ input "maxHp",'number','calcMaxHp' ]}
        </dl>
        <dl class="box" id="initiative">
          <dt>行動値
          <dd>@{[ input "initiative",'number','calcInitiative' ]}
        </dl>
        <dl class="box crc-only" id="armor">
          <dt>回避値
          <dd>@{[ input "dodge",'number' ]}
        </dl>
        <dl class="box" id="armor">
          <dt>装甲値
          <dd>@{[ input "armor",'number' ]}
        </dl>
        <dl class="box" id="encroach">
          <dt>侵蝕率
          <dd>@{[ input "encroach",'number','checkEncroachBonus' ]}
        </dl>
      </div>

      <ul class="box annotate">
        <li>HP・行動値および各能力値は、空欄ならシンドロームから自動計算された数値が代入されます。
      </ul>
    </div>

    <details class="box" id="status" $open{skill}>
      <summary class="in-toc">能力値・技能</summary>
      <dl id="status-table">
        <dt>肉体<dd id="skill-body"  >@{[ input "sttBody"  ,'number','calcStt' ]}
        <dt>感覚<dd id="skill-sense" >@{[ input "sttSense" ,'number','calcStt' ]}
        <dt>精神<dd id="skill-mind"  >@{[ input "sttMind"  ,'number','calcStt' ]}
        <dt>社会<dd id="skill-social">@{[ input "sttSocial",'number','calcStt' ]}
      </dl>
      <dl id="skill-table">
        <dt>【肉体】を使用する技能
        <dd>
          <dl id="skill-body-table">
            <dt class="left">白兵<dd>@{[input "skillMelee"  ,'number','calcSkill', 'min="0"']}
            <dt class="left">回避<dd>@{[input "skillDodge"  ,'number','calcSkill', 'min="0"']}
            @{[ map {
              my $num = $_;
              '<dt>'. (input "skillRide${num}Name",'','calcSkill','list="list-ride"')
              . '<dd>'. (input "skillRide${num}",'number','calcSkill', 'min="0"')
            } 1 .. $pc{skillRideNum} ]}
          </dl>
        @{[ renderAddDelButtons('skill', q|'Ride'|, 'skillRideNum') ]}
        </dd>
        <dt>【感覚】を使用する技能
        <dd>
          <dl id="skill-sense-table">
            <dt class="left">射撃<dd>@{[input "skillRanged" ,'number','calcSkill', 'min="0"']}
            <dt class="left">知覚<dd>@{[input "skillPercept",'number','calcSkill', 'min="0"']}
            @{[ map {
              my $num = $_;
              '<dt>'. (input "skillArt${num}Name",'','calcSkill','list="list-art"')
              . '<dd>'. (input "skillArt${num}",'number','calcSkill', 'min="0"')
            } 1 .. $pc{skillArtNum} ]}
          </dl>
        @{[ renderAddDelButtons('skill', q|'Art'|, 'skillArtNum') ]}
        </dd>
        <dt>【精神】を使用する技能
        <dd>
          <dl id="skill-mind-table">
            <dt class="left">ＲＣ<dd>@{[input "skillRC"  ,'number','calcSkill', 'min="0"']}
            <dt class="left">意志<dd>@{[input "skillWill",'number','calcSkill', 'min="0"']}
            @{[ map {
              my $num = $_;
              '<dt>'. (input "skillKnow${num}Name",'','calcSkill','list="list-know"')
              . '<dd>'. (input "skillKnow${num}",'number','calcSkill', 'min="0"')
            } 1 .. $pc{skillKnowNum} ]}
          </dl>
        @{[ renderAddDelButtons('skill', q|'Know'|, 'skillKnowNum') ]}
        </dd>
        <dt>【社会】を使用する技能
        <dd>
          <dl id="skill-social-table">
            <dt class="left">交渉<dd>@{[input "skillNegotiate",'number','calcSkill', 'min="0"']}
            <dt class="left">調達<dd>@{[input "skillProcure"  ,'number','calcSkill', 'min="0"']}
            @{[ map {
              my $num = $_;
              '<dt>'. (input "skillInfo${num}Name",'','calcSkill','list="list-info"')
              . '<dd>'. (input "skillInfo${num}",'number','calcSkill', 'min="0"')
            } 1 .. $pc{skillInfoNum} ]}
          </dl>
          @{[ renderAddDelButtons('skill', q|'Info'|, 'skillInfoNum') ]}
        </dd>
      </dl>
    </details>
    <div id="enc-bonus" style="position: relative;">
      <div class="box">
        <h2 class="in-toc">侵蝕率効果表</h2>
        <p>
          <!-- 現在侵蝕率:@{[ input 'currentEncroach','number','encroachBonusSet(this.value)','style="width: 4em;"' ]} -->
          @{[ checkbox 'encroachEaOn','エフェクトアーカイブ適用','checkEncroachBonus' ]}
          @{[ checkbox 'encroachOrOn','起源種','checkEncroachBonus' ]}
        </p>
        <table class="data-table" id="enc-table">
          <colgroup></colgroup>
          <tr id="enc-table-head">
          <tr id="enc-table-dices">
          <tr id="enc-table-level">
        </table>
      </div>
    </div>

    <details class="box crc-only" id="attack" $open{attack}>
      <summary class="in-toc">攻撃</summary>
      <table class="edit-table no-border-cells" id="attack-table">
        <colgroup>
          <col class="handle">
          <col class="name ">
          <col class="margin">
          <col class="dice ">
          <col class="code ">
          <col class="mod  ">
          <col class="crit ">
          <col class="fixed">
          <col class="margin">
          <col class="atk  ">
          <col class="margin">
          <col class="range">
        </colgroup>
        <thead>
          <tr>
            <th rowspan="2">
            <th rowspan="2">攻撃方法
            <th rowspan="2">
            <th colspan="5">判定値
            <th rowspan="2">
            <th rowspan="2">攻撃力
            <th rowspan="2">
            <th rowspan="2">射程
          <tr class="small"><th>ダイス<th><th>修正<th>C値<th>期待値
        <tbody>
          @{[ renderTemplateLoop(
            'attack',
            sub ($num) {
              return <<~"ROW";
              <tr id="attack-row${num}">
                <td class="handle">
                <td>@{[ input "attack${num}Name" ]}
                <td>
                <td>@{[ input "attack${num}Dice",'number' ]}
                <td>D+
                <td>@{[ input "attack${num}Mod",'number' ]}
                <td>@{[ input "attack${num}Crit",'number' ]}
                <td><div>@{[ input "attack${num}Fixed",'number' ]}</div>
                <td>
                <td>@{[ input "attack${num}Atk",'number' ]}
                <td>
                <td>@{[ input "attack${num}Range",'','','list="list-range-atk"' ]}
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('attack') ]}
      <ul class="annotate">
        <li>MエネミーのC値はパークで変更されますが、ダイスコマンド出力の為にこの欄でも項目を設けています。
      </ul>
    </details>

    <details class="box box-union" id="items" $open{item}>
      <summary class="in-toc">装備</summary>
      <div class="box" id="weapon">
        <table class="edit-table no-border-cells" id="weapon-table">
          <thead>
            <tr><th><th>武器<th>技能<th>命中<th>攻撃力<th><span class="small">ガード値</span><th>解説
          <tbody>
            @{[ renderTemplateLoop(
              'weapon',
              sub ($num) {
                return <<~"ROW";
                <tr id="weapon-row${num}">
                  <td class="handle">
                  <td>@{[ input "weapon${num}Name" ]}
                  <td>@{[ selectBox "weapon${num}Skill",'', @setComboSkills ]}
                  <td>@{[ input "weapon${num}Acc",'number' ]}
                  <td>@{[ input "weapon${num}Atk",'number' ]}
                  <td>@{[ input "weapon${num}Guard" ]}
                  <td><textarea name="weapon${num}Note" rows="2">$pc{"weapon${num}Note"}</textarea>
                ROW
              }
            ) ]}
        </table>
        @{[ renderAddDelButtons('weapon') ]}
      </div>
      <div class="box">
        <table class="edit-table no-border-cells" id="armor-table">
          <thead>
            <tr><th><th>防具<th><th>行動<th>ドッジ<th>装甲値<th>解説
          <tbody>
            @{[ renderTemplateLoop(
              'armor',
              sub ($num) {
                return <<~"ROW";
                <tr id="armor-row${num}">
                  <td class="handle">
                  <td>@{[ input "armor${num}Name" ]}
                  <td>
                  <td>@{[ input "armor${num}Initiative",'number' ]}
                  <td>@{[ input "armor${num}Dodge",'number' ]}
                  <td>@{[ input "armor${num}Armor",'number' ]}
                  <td><textarea name="armor${num}Note" rows="2">$pc{"armor${num}Note"}</textarea>
                ROW
              }
            ) ]}
          </tbody>
        </table>
        @{[ renderAddDelButtons('armor') ]}
      </div>
      <div class="box">
        <table class="edit-table no-border-cells" id="vehicle-table">
          <thead>
            <tr><th><th>ヴィークル<th>技能<th>行動<th>攻撃力<th>装甲値<th><span class="small">全力移動</span><th>解説
          <tbody>
            @{[ renderTemplateLoop(
              'vehicle',
              sub ($num) {
                return <<~"ROW";
                <tr id="vehicle-row${num}">
                  <td class="handle">
                  <td>@{[ input "vehicle${num}Name" ]}
                  <td>@{[ selectBox "vehicle${num}Skill",'', @setComboSkills ]}
                  <td>@{[ input "vehicle${num}Initiative",'number' ]}
                  <td>@{[ input "vehicle${num}Atk",'number' ]}
                  <td>@{[ input "vehicle${num}Armor",'number' ]}
                  <td>@{[ input "vehicle${num}Dash" ]}
                  <td><textarea name="vehicle${num}Note" rows="2">$pc{"vehicle${num}Note"}</textarea>
                ROW
              }
            ) ]}
        </table>
        @{[ renderAddDelButtons('vehicle') ]}
      </div>
      <div class="box">
        <table class="edit-table no-border-cells" id="item-table">
          <thead>
            <tr><th><th>一般アイテム<th>技能<th>解説
          <tbody>
            @{[ renderTemplateLoop(
              'item',
              sub ($num) {
                return <<~"ROW";
                <tr id="item-row${num}">
                  <td class="handle">
                  <td>@{[ input "item${num}Name" ]}
                  <td>@{[ selectBox "item${num}Skill",'', @setComboSkills ]}
                  <td><textarea name="item${num}Note" rows="2">$pc{"item${num}Note"}</textarea>
                ROW
              }
            ) ]}
        </table>
        @{[ renderAddDelButtons('item') ]}
      </div>
    </details>

    <details class="box" id="effect" $open{effect}>
      <summary class="in-toc" data-content-title="取得エフェクト・Eロイスなど">取得エフェクト<span class="crc-only">／パーク</span>／Dロイス／Eロイス</summary>
      <div>
        <table class="edit-table line-tbody no-border-cells" id="effect-table">
          <thead id="effect-head">
            <tr><th><th>名称<th>LV<th>タイミング<th>技能<th>難易度<th>対象<th>射程<th>侵蝕値<th>制限
          @{[ renderTemplateLoop(
            'effect',
            sub ($num) {
              return <<~"ROW";
              <tbody id="effect-row${num}">
                <tr>
                  <td rowspan="2" class="handle">
                  <td>@{[input "effect${num}Name",'','','placeholder="名称"']}
                  <td>@{[input "effect${num}Lv",'number','calcEffect','placeholder="Lv" min="0"']}
                  <td>@{[input "effect${num}Timing",'','','placeholder="タイミング" list="list-timing"']}
                  <td>@{[input "effect${num}Skill",'','','placeholder="技能" list="list-effect-skill"']}
                  <td>@{[input "effect${num}Dfclty",'','','placeholder="難易度" list="list-dfclty"']}
                  <td>@{[input "effect${num}Target",'','','placeholder="対象" list="list-target"']}
                  <td>@{[input "effect${num}Range",'','','placeholder="射程" list="list-range"']}
                  <td>@{[input "effect${num}Encroach",'','','placeholder="侵蝕値" list="list-encroach"']}
                  <td>@{[input "effect${num}Restrict",'','','placeholder="制限" list="list-restrict"']}
                <tr><td colspan="9">
                  <div>
                    <b>種別</b>@{[ selectBox "effect${num}Type","calcEffect()",
                      {value => 'DEF=', text => 'エフェクト'},
                      {value => 'easy', text => 'イージーエフェクト'},
                      {value => 'enemy', text => 'エネミーエフェクト'},
                      {value => 'perk', text => 'パーク', attr => 'crc-only'},
                      {value => 'dlois', text => 'Dロイス'},
                      {value => 'elois', text => 'Eロイス'},
                    ]}
                    <b>効果</b>@{[input "effect${num}Note"]}
                  </div>
              ROW
            }
          ) ]}
          <tfoot id="effect-foot">
            <tr><th><th>名称<th>LV<th>タイミング<th>技能<th>難易度<th>対象<th>射程<th>侵蝕値<th>制限
        </table>
      </div>
      @{[ renderAddDelButtons('effect') ]}
    </details>
    <div class="box trash-box" id="effect-trash">
      <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除エフェクト</span></h2>
      <table class="edit-table line-tbody" id="effect-trash-table"></table>
      <i class="material-symbols-outlined close-button" onclick="document.getElementById('effect-trash').style.display = 'none';">close</i>
    </div>

    <details class="box" id="combo" $open{combo} style="position:relative">
      <summary class="in-toc">コンボ</summary>
      <div id="combo-list">
        @{[ renderTemplateLoop(
          'combo',
          sub ($num) {
            return <<~"ROW";
            <div class="combo-table" id="combo-row${num}">
              <div class="handle"></div>
              <dl class="combo-name"><dt>名称</dt><dd>@{[input "combo${num}Name"]}</dd></dl>
              <dl class="combo-combo"><dt>組み合わせ</dt><dd>@{[input "combo${num}Combo"]}</dl>
              <div class="combo-in">
                <dl><dt>タイミング<dd>@{[input "combo${num}Timing",'','','list="list-combo-timing"']}</dl>
                <dl><dt>技能      <dd>@{[ selectBox "combo${num}Skill", "calcCombo(${num})", @setComboSkills ]}</dl>
                <dl><dt>能力値    <dd>@{[ selectBox "combo${num}Stt", "calcCombo(${num})", @setComboStatus ]}</dl>
                <dl><dt>難易度    <dd>@{[input "combo${num}Dfclty",'','','list="list-dfclty"']}</dl>
                <dl><dt>対象      <dd>@{[input "combo${num}Target",'','','list="list-target"']}</dl>
                <dl><dt>射程      <dd>@{[input "combo${num}Range",'','','list="list-range"']}</dl>
                <dl><dt>侵蝕値    <dd>@{[input "combo${num}Encroach"]}</dl>
              </div>
              <dl class="combo-out">
                <dt class="combo-cond">条件<span class="combo-condition-utility"></span>
                <dt class="combo-dice">ダイス
                <dt class="combo-crit">Ｃ値
                <dt class="combo-fixed">達成値修正<br><span class="very-small">(技能レベル+修正値)</span>
                <dt class="combo-atk">攻撃力
                @{[ map {
                  <<~"DD";
                  <dd>@{[input "combo${num}Condition${_}"]}
                  <dd id="combo${num}Stt${_}"></dd>
                  <dd>@{[input "combo${num}DiceAdd${_}"]}
                  <dd>@{[input "combo${num}Crit${_}"]}
                  <dd id="combo${num}SkillLv${_}"></dd>
                  <dd>@{[input "combo${num}FixedAdd${_}"]}
                  <dd>@{[input "combo${num}Atk${_}"]}
                  DD
                } 1 .. 5 ]}
              </dl>
              <div class="combo-note"><textarea name="combo${num}Note" rows="3" placeholder="解説">$pc{"combo${num}Note"}</textarea></div>
              <div class="combo-other">@{[ checkbox "combo${num}Manual",'技能レベル・能力値を自動挿入しない',"calcCombo(${num})" ]}
              @{[ checkbox "combo${num}DBManual",'侵蝕ダイスボーナスを自動挿入しない',"calcCombo(${num})" ]}
              <span class="button" onclick="addCombo($num)">コンボ複製</span></div>
            </div>
            ROW
          }
        ) ]}
      </div>
      @{[ renderAddDelButtons('combo') ]}
    </details>

    <details class="box" id="free-note" @{[ $pc{freeNote} ? 'open' : '' ]}>
      <summary class="in-toc">解説・戦闘プランなど</summary>
      <textarea name="freeNote">$pc{freeNote}</textarea>
    </details>
  </section>
HTML
print renderChatPaletteForm();

print renderEditPageEnd(
  notes => '©FarEast Amusement Research Co.,Ltd.「ダブルクロスThe 3rd Edition」',
  extraHtml => renderDataList() . renderFooterScript(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-stage">
    <option value="基本ステージ">
    <option value="基本ステージ(UA)">
    <option value="オーヴァードアカデミア">
    <option value="ナイトメアプリズン">
    <option value="デモンズシティ">
    <option value="陽炎の戦場">
    <option value="エンドライン">
    <option value="ホーリーグレイル">
    <option value="平安京物怪録">
    <option value="モダンタイムス">
    <option value="エピックヒーローズ">
    <option value="クロノスガーディアン">
    <option value="レネゲイドウォー">
    <option value="バッドシティ">
    <option value="ウィアードエイジ">
    <option value="カオスガーデン">
    <option value="クロウリングケイオス">
  </datalist>
  <datalist id="list-impulse">
    <option value="―">
    <option value="解放">
    <option value="吸血">
    <option value="飢餓">
    <option value="殺戮">
    <option value="破壊">
    <option value="加虐">
    <option value="嫌悪">
    <option value="闘争">
    <option value="妄想">
    <option value="自傷">
    <option value="恐怖">
    <option value="憎悪">
    <option value="改変">
  </datalist>
  <datalist id="list-ride">
    <option value="運転:">
    <option value="運転:二輪">
    <option value="運転:四輪">
    <option value="運転:船舶">
    <option value="運転:航空機">
    <option value="運転:馬">
    <option value="運転:多脚戦車">
    <option value="運転:宇宙船">
  </datalist>
  <datalist id="list-art" >
    <option value="芸術:">
    <option value="芸術:音楽">
    <option value="芸術:歌唱">
    <option value="芸術:演技">
    <option value="芸術:絵画">
    <option value="芸術:写真">
    <option value="芸術:彫刻">
    <option value="芸術:ゲーム">
  </datalist>
  <datalist id="list-know">
    <option value="知識:">
    <option value="知識:レネゲイド">
    <option value="知識:医療">
    <option value="知識:心理">
    <option value="知識:機械工学">
    <option value="知識:機械操作">
    <option value="知識:オカルト">
    <option value="知識:遺産">
  </datalist>
  <datalist id="list-info">
    <option value="情報:">
    <option value="情報:UGN">
    <option value="情報:FH">
    <option value="情報:ゼノス">
    <option value="情報:噂話">
    <option value="情報:裏社会">
    <option value="情報:警察">
    <option value="情報:軍事">
    <option value="情報:学問">
    <option value="情報:ウェブ">
    <option value="情報:メディア">
    <option value="情報:ビジネス">
  </datalist>
  <datalist id="list-timing">
    <option value="オート">
    <option value="マイナー">
    <option value="メジャー">
    <option value="メジャー／リア">
    <option value="リアクション">
    <option value="セットアップ">
    <option value="イニシアチブ">
    <option value="クリンナップ">
    <option value="常時">
    <option value="効果参照">
  </datalist>
  <datalist id="list-effect-skill">
    <option value="―">
    <option value="シンドローム">
    <option value="〈白兵〉">
    <option value="〈射撃〉">
    <option value="〈RC〉">
    <option value="〈交渉〉">
    <option value="〈白兵〉〈射撃〉">
    <option value="〈白兵〉〈RC〉">
    <option value="〈回避〉">
    <option value="〈知覚〉">
    <option value="〈意志〉">
    <option value="〈調達〉">
    <option value="【肉体】">
    <option value="【感覚】">
    <option value="【精神】">
    <option value="【社会】">
    <option value="〈運転:〉">
    <option value="〈芸術:〉">
    <option value="〈知識:〉">
    <option value="〈情報:〉">
    <option value="効果参照">
  </datalist>
  <datalist id="list-combo-timing">
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
  <datalist id="list-combo-skill">
    <option value="―">
    <option value="〈白兵〉">
    <option value="〈射撃〉">
    <option value="〈RC〉">
    <option value="〈交渉〉">
    <option value="〈白兵〉〈射撃〉">
    <option value="〈白兵〉〈RC〉">
    <option value="〈回避〉">
    <option value="〈知覚〉">
    <option value="〈意志〉">
    <option value="〈調達〉">
    <option value="【肉体】">
    <option value="【感覚】">
    <option value="【精神】">
    <option value="【社会】">
    <option value="〈運転:〉">
    <option value="〈芸術:〉">
    <option value="〈知識:〉">
    <option value="〈情報:〉">
    <option value="効果参照">
  </datalist>
  <datalist id="list-weapon-skill">
    <option value="―">
    <option value="〈白兵〉">
    <option value="〈射撃〉">
    <option value="〈白兵〉〈射撃〉">
    <option value="〈交渉〉">
    <option value="〈知識:機械工学〉">
    <option value="解説参照">
  </datalist>
  <datalist id="list-dfclty">
    <option value="―">
    <option value="自動成功">
    <option value="対決">
    <option value="効果参照">
  </datalist>
  <datalist id="list-target">
    <option value="―">
    <option value="自身">
    <option value="単体">
    <option value="3体">
    <option value="[LV+1]体">
    <option value="範囲">
    <option value="範囲（選択）">
    <option value="シーン">
    <option value="シーン（選択）">
    <option value="効果参照">
  </datalist>
  <datalist id="list-range-atk">
    <option value="m">
    <option value="至近">
    <option value="視界">
    <option value="m※">
    <option value="視界※">
  </datalist>
  <datalist id="list-range">
    <option value="―">
    <option value="至近">
    <option value="武器">
    <option value="視界">
    <option value="効果参照">
  </datalist>
  <datalist id="list-encroach">
    <option value="―">
    <option value="1">
    <option value="2">
    <option value="3">
    <option value="4">
    <option value="5">
    <option value="6">
    <option value="7">
    <option value="8">
    <option value="10">
    <option value="20">
    <option value="1D10">
    <option value="2D10">
    <option value="4D10">
    <option value="効果参照">
  </datalist>
  <datalist id="list-restrict">
    <option value="―">
    <option value="ピュア">
    <option value="80%">
    <option value="100%">
    <option value="120%" class="percent120">
    <option value="Dロイス">
    <option value="リミット">
    <option value="RB">
    <option value="従者専用">
    <option value="改変">
  </datalist>
  <datalist id="list-magic-type">
    <option value="通常">
    <option value="通常／維持">
    <option value="印形">
    <option value="儀式">
    <option value="儀式／維持">
    <option value="儀式／呪詛">
    <option value="儀式／召喚">
    <option value="召喚">
    <option value="喚起">
    <option value="喚起／儀式">
  </datalist>
  HTML
}
sub renderFooterScript {
  my $html;
  $html .= '<script>';
  $html .= "const makeExp = $set::make_exp;";
  $html .= "const synStats = {";
  foreach (keys %data::syndrome_status) {
    next if !$_;
    my @ar = @{$data::syndrome_status{$_}};
    $html .= qq|"$_":{"body":$ar[0],"sense":$ar[1],"mind":$ar[2],"social":$ar[3]},|;
  }
  $html .= "};\n";
  $html .= "const awakens = {";
  foreach (@data::awakens) {
    next if (@$_[0] =~ /^LABEL=/);
    $html .= qq|"@$_[0]":@$_[1],|;
  }
  $html .= "};\n";
  $html .= 'const impulses = {';
  foreach (@data::impulses) {
    $html .= qq|"@$_[0]":@$_[1],|;
  }
  $html .= "};\n";
  $html .= '</script>';

  return $html;
}

1;
