############# フォーム・アイテム #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'signatures';
no warnings 'experimental::signatures';

my $LOGIN_ID = $::LOGIN_ID;

require $set::lib_convert;

### 読込前処理 #######################################################################################
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_class;
my @magic_classes;
my @craft_classes;
foreach(@data::class_names){
  if($_ eq 'フェアリーテイマー'){
    push(
      @magic_classes,
      'label=妖精魔法',
      '基本妖精魔法', '属性妖精魔法(土)', '属性妖精魔法(水・氷)', '属性妖精魔法(炎)', '属性妖精魔法(風)', '属性妖精魔法(光)', '属性妖精魔法(闇)', '特殊妖精魔法',
      'close_group'
    );
  }
  elsif($_ eq 'コンジャラー'){
    push(@magic_classes, $data::class{$_}{magic}{jName}, '深智魔法');
  }
  elsif($_ eq 'バード'){
    push(@craft_classes, $data::class{$_}{craft}{jName}, '終律');
  }
  elsif($_ eq 'ウォーリーダー'){
    push(@craft_classes, '鼓咆','陣率');
  }
  elsif($data::class{$_}{magic}) { push(@magic_classes, $data::class{$_}{magic}{jName}); }
  elsif($data::class{$_}{craft}) { push(@craft_classes, $data::class{$_}{craft}{jName}); }
}
push(@magic_classes, @craft_classes);
@magic_classes = deduplicate(@magic_classes); #重複削除
### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, unescapeTags(
    $pc{category} eq 'magic'  ? $pc{magicName}
  : $pc{category} eq 'god'    ? $pc{godAka}.$pc{godName}
  : $pc{category} eq 'school' ? $pc{schoolName}
  : $pc{category} eq 'skill'  ? $pc{skillName}
  : '無題'
));

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{author} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}
if($::mode eq 'edit' || ($::mode eq 'convert' && $pc{ver})){
  %pc = data_update_arts(\%pc);
}
if($::mode eq 'blanksheet'){
  $pc{magicCost} = 'MP';
  foreach my $lv (2,4,7,10,13){ $pc{"godMagic${lv}Cost"} = 'MP' }
  $pc{schoolReq} = '＿名誉点';

  %pc = applyCustomizedInitialValues(\%pc, 'a');
}

## カラー
setDefaultColors(\%pc);

## その他
$pc{schoolArtsNum} ||= 3;
$pc{schoolMagicNum} ||= 1;

### 折り畳み判断 --------------------------------------------------
my %open;
foreach (1..$pc{schoolArtsNum} ){ if($pc{"schoolArts${_}Name"} ){ $open{schoolArts}  = 'open'; last; } }
foreach (1..$pc{schoolMagicNum}){ if($pc{"schoolMagic${_}Name"}){ $open{schoolMagic} = 'open'; last; } }
if($pc{schoolArtsNote} ){ $open{schoolArts}  = 'open'; }
if($pc{schoolMagicNote}){ $open{schoolMagic} = 'open'; }
if($pc{schoolQnA}      ){ $open{schoolQnA}   = 'open'; }
if($pc{godQnA}         ){ $open{godQnA}      = 'open'; }

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/magicEffect magicDescription
  godSymbol godDeity godNote godQnA
  schoolNote schoolItemNote schoolArtsNote schoolMagicNote schoolQnA
  skillRankB_effect skillRankA_effect skillRankS_effect skillRankSS_effect
  /,
  ( map { "godMagic${_}Effect"    } 2,4,7,10,13 ),
  ( map { "schoolArts${_}Effect"  } 1..$pc{schoolArtsNum} ),
  ( map { "schoolMagic${_}Effect" } 1..$pc{schoolMagicNum} ),
  ( map { "skillRank${_}_effect"  } qw/B A S SS/ ),
);

### 画像 --------------------------------------------------
my $image_maxsize = $set::image_maxsize / 4;
my $image_maxsize_view = $image_maxsize >= 1048576 ? sprintf("%.3g",$image_maxsize/1048576).'MB' : sprintf("%.3g",$image_maxsize/1024).'KB';

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ( $pc{artsName} )),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span class="sheet-kind"></span><span>データ</span>
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

    <div class="box in-toc" id="name-form" data-content-title="カテゴリ・製作者名">
      <div>
        <dl id="category">
          <dt>カテゴリ
          <dd><select name="category" oninput="checkCategory();">@{[ option 'category','magic|<魔法／練技・呪歌など>','god|<神格＋特殊神聖魔法>','school|<流派＋秘伝>','skill|<特殊能力（蛮族向け）>' ]}</select>
        </dl>
      </div>
      <dl id="player-name">
        <dt>製作者
        <dd>@{[ input 'author' ]}
      </dl>
    </div>
    <div class="data-area box" id="data-none">
      <p>カテゴリを選択してください。</p>
    </div>
    <!-- 魔法 -->
    <div class="data-area in-toc" id="data-magic" data-content-title="データ">
      <div class="box input-data">
        <dl class="name     "><dt>名称        <dd>【@{[ input 'magicName','',"setName" ]}】<br>
                                                  @{[ checkbox 'magicActionTypePassive','常時' ]}@{[ checkbox 'magicActionTypeMajor','主動作' ]}@{[ checkbox 'magicActionTypeMinor','補助動作' ]}@{[ checkbox 'magicActionTypeSetup','戦闘準備' ]}</dl>
        <dl class="class    "><dt>系統        <dd>@{[ selectInput "magicClass","checkMagicClass",@magic_classes ]} @{[ checkbox 'magicMinor','小魔法' ]}</dl>
        <dl class="sphere   "><dt>マギスフィア<dd>@{[ input 'magicMagisphere','','','list="list-sphere"' ]}</dl>
        <dl class="level    "><dt>習得レベル  <dd>@{[ input 'magicLevel' ]}</dl>
        <dl class="type     "><dt>対応        <dd>@{[ input 'magicType','','','list="list-type"' ]}</dl>
        <dl class="premise  "><dt>前提        <dd>@{[ input 'magicPremise','','','list="list-premise"' ]}</dl>
        <dl class="cost     "><dt>消費        <dd>@{[ input 'magicCost','','','list="list-cost"' ]}</dl>
        <dl class="target   "><dt>対象        <dd>@{[ input 'magicTarget','','','list="list-target"' ]}</dl>
        <dl class="range    "><dt>射程／形状  <dd>@{[ input 'magicRange','','','list="list-range"' ]}／@{[ input 'magicForm','','','list="list-form"' ]}</dl>
        <dl class="duration "><dt>時間        <dd>@{[ input 'magicDuration','','','list="list-duration"' ]}</dl>
        <dl class="song     "><dt>歌唱        <dd>@{[ checkbox 'magicSongSing','必要' ]}</dl>
        <dl class="song     "><dt>ペット      <dd>@{[ checkbox 'magicSongPetBird','小鳥' ]}@{[ checkbox 'magicSongPetFrog','蛙' ]}@{[ checkbox 'magicSongPetBug','虫' ]}</dl>
        <dl class="condition"><dt>条件        <dd>@{[ input 'magicCondition','','','list="list-song-condition"' ]}</dl>
        <dl class="song     "><dt>楽素        <dd>基礎@{[ input 'magicSongBasePoint','','','list="list-songpoint"' ]} 巧奏値@{[ input 'magicSongSetPoint','','','list="list-song-set-point"' ]} 追加@{[ input 'magicSongAddPoint','','','list="list-songpoint"' ]}</dl>
        <dl class="rider    "><dt>対応        <dd>@{[ checkbox 'magicMountTypeAnimal','動物' ]}@{[ checkbox 'magicMountTypeCryptid','幻獣' ]}@{[ checkbox 'magicMountTypeMachine','魔動機' ]}</dl>
        <dl class="part     "><dt>適用部位    <dd>@{[ input 'magicApplyPart','','','list="list-part"' ]}</dl>
        <dl class="human-form"><dt>人間形態時 <dd>@{[ radios 'magicApplyHumanForm','','available=>有効','unavailable=>無効','=>指定なし（変身しない種族用）' ]}</dl>
        <dl class="rank     "><dt>ランク      <dd>@{[ input 'magicRank' ]}</dl>
        <dl class="commcost "><dt>陣気コスト  <dd>@{[ input 'magicCommandCost','number' ]}消費</dl>
        <dl class="command  "><dt>陣気蓄積    <dd>＋@{[ input 'magicCommandCharge','number' ]}</dl>
        <dl class="resist   "><dt>抵抗        <dd>@{[ input 'magicResist','','','list="list-resist"' ]}</dl>
        <dl class="element  "><dt>属性        <dd>@{[ input 'magicElement','','','list="list-element"' ]}</dl>
        <dl class="summary  "><dt>概要        <dd>@{[ input 'magicSummary' ]}</dl>
        <dl class="effect   "><dt>効果        <dd><textarea name="magicEffect">$pc{magicEffect}</textarea></dl>
      </div>
      <div class="box">
        <h2 class="in-toc">由来・逸話など</h2>
        <textarea name="magicDescription">$pc{magicDescription}</textarea>
      </div>
    </div>
    <!-- 神格 -->
    <div class="data-area in-toc" id="data-god" data-content-title="神格の詳細">
      <div class="box input-data">
        <div id="image" style="">
          <h2>聖印の画像</h2>
          <p>
            プレビューエリアに画像ファイルをドロップ、または
            <input type="file" accept="image/*" name="imageFile" onchange="imagePreView(this.files[0], $image_maxsize || 0)"><br>
            ※ ファイルサイズ @{[ $image_maxsize_view ]} までの JPG/PNG/GIF/WebP
            <small>（サイズを超過する場合、自動的にWebP形式に変換し、その上でまだ超過している場合は縮小処理が行われます）</small>
          </p>
          <p>
            <input type="checkbox" name="imageDelete" value="1"> 画像を削除する
            @{[ input 'image','hidden' ]}
          </p>
        <script>
          const imageType = 'symbol';
          let imgURL = "$pc{imageURL}";
        </script>
        </div>
        <dl class="name  "><dt>名称      <dd>@{[ input 'godName','',"setName" ]}</dl>
        <dl class="aka   "><dt>異名      <dd>“@{[ input 'godAka','',"setName" ]}”</dl>
        <dl class="class "><dt>系統      <dd><select name="godClass">@{[ option 'godClass','第一の剣','第二の剣','第三の剣','不明' ]}</select>／<select name="godRank">@{[ option 'godRank','古代神','大神','小神' ]}</select></dl>
        <dl class="area  "><dt>地域      <dd>@{[ input 'godArea','','','placeholder="大陸・地方など"' ]}<small>※主に小神向けの項目です</small></dl>
        <dl class="symbol"><dt>聖印と神像<dd><textarea name="godSymbol">$pc{godSymbol}</textarea></dl>
        <dl class="deity "><dt>神格と教義<dd><textarea name="godDeity">$pc{godDeity}</textarea></dl>
        <dl class="maxim "><dt>格言      <dd>「@{[ input "godMaxim1" ]}」<br>「@{[ input "godMaxim2" ]}」<br>「@{[ input "godMaxim3" ]}」</dl>
        <dl class="deity "><dt>備考      <dd><textarea name="godNote" placeholder="他神との関係やその他逸話、データの諸注意などなんでも">$pc{godNote}</textarea></dl>
      </div>
      <div class="box input-data">
        @{[ map {
          my $lv = $_;
          <<~"HTML";
            <h2 class="in-toc">特殊神聖魔法 ${lv}レベル</h2>
            <dl class="name    "><dt>名称      <dd>【@{[ input "godMagic${lv}Name",'' ]}】<br>@{[ checkbox "godMagic${lv}ActionTypeMinor",'補助動作' ]}@{[ checkbox "godMagic${lv}ActionTypeSetup",'戦闘準備' ]}</dl>
            <dl class="cost    "><dt>消費      <dd>@{[ input "godMagic${lv}Cost",'','','list="list-cost"' ]}</dl>
            <dl class="target  "><dt>対象      <dd>@{[ input "godMagic${lv}Target",'','','list="list-target"' ]}</dl>
            <dl class="range   "><dt>射程／形状<dd>@{[ input "godMagic${lv}Range",'','','list="list-range"' ]}／@{[ input "godMagic${lv}Form",'','','list="list-form"' ]}</dl>
            <dl class="duration"><dt>時間      <dd>@{[ input "godMagic${lv}Duration",'','','list="list-duration"' ]}</dl>
            <dl class="resist  "><dt>抵抗      <dd>@{[ input "godMagic${lv}Resist",'','','list="list-resist"' ]}</dl>
            <dl class="element "><dt>属性      <dd>@{[ input "godMagic${lv}Element",'','','list="list-element"' ]}</dl>
            <dl class="summary "><dt>概要      <dd>@{[ input "godMagic${lv}Summary" ]}</dl>
            <dl class="effect  "><dt>効果      <dd><textarea name="godMagic${lv}Effect">$pc{"godMagic${lv}Effect"}</textarea></dl>
          HTML
        } (2,4,7,10,13) ]}
      </div>
      <details class="box" $open{godQnA}>
        <summary class="in-toc">Ｑ＆Ａ</summary>
        <textarea name="godQnA">$pc{godQnA}</textarea>
      </details>
    </div>
    <!-- 流派 -->
    <div class="data-area in-toc" id="data-school" data-content-title="流派の詳細">
      <div class="box input-data">
        <dl class="name  "><dt>名称      <dd>【@{[ input 'schoolName','',"setName" ]}】</dl>
        <dl class="area  "><dt>地域      <dd>@{[ input 'schoolArea','','','placeholder="大陸・地方など"' ]}</dl>
        <dl class="req   "><dt>入門条件  <dd>@{[ input 'schoolReq','','','list="list-school-req"' ]}</dl>
        <dl class="note  "><dt>詳細      <dd><textarea name="schoolNote">$pc{schoolNote}</textarea></dl>
        <dl class="arms  "><dt>流派アイテム<dd><textarea name="schoolItemNote" placeholder="流派アイテムの概要">$pc{schoolItemNote}</textarea></dl>
        <dl class="arms  "><dt>アイテム一覧
          <dd>
            <input type="text" id="schoolItemUrl" placeholder="アイテムシートのURL"><span class="button" onclick="addSchoolItem()">追加</span>
            @{[ input 'schoolItemList','hidden' ]}
            <table id="school-item-list" class="data-table">
              <thead>
                <th>名前
                <th>カテゴリ
                <th>概要
                <th>
              <tbody>
                @{[ map {
                  my %item = loadItemData($_);
                  $item{category} =~ s/\s/<hr>/g;
                  <<~"HTML";
                  <tr>
                  ${\ do {
                    if(exists $item{itemName}) {
                      qq|<td><a href="$_" target="_blank">|.unescapeTags($item{itemName})."</a>";
                    }
                    else {
                      qq|<td><a href="$_" target="_blank" class="failed">データ取得失敗</a>|;
                    }
                  }}
                  <td>@{[ unescapeTags $item{category} ]}
                  <td>@{[ unescapeTags $item{summary} ]}
                  <td class='button' onclick="delSchoolItem(this,'$_')">×
                  HTML
                } split ',',$pc{schoolItemList} ]}
          </table>
        </dl>
      </div>
      <details class="box" $open{schoolArts}>
        <summary class="in-toc">流派秘伝</summary>
        <textarea name="schoolArtsNote" placeholder="流派秘伝全体の注釈（あれば）">$pc{schoolArtsNote}</textarea>
        <hr style="margin:0">
        <ul class="annotate"><li>下位秘伝と上位秘伝をまとめて記述する場合、<code> / </code>のように、「空白・スラッシュ・空白」で区切って入力してください。</ul>
        <div id="arts-list">
          @{[ renderTemplateLoop(
            'school-arts',
            sub ($num) {
              return <<~"ROW";
              <div class="input-data" id="school-arts-row${num}">
                <div class="handle"></div>
                <dl class="name    "><dt>名称      <dd>《@{[ input "schoolArts${num}Name",'' ]}》<br>@{[ checkbox "schoolArts${num}ActionTypeSetup",'戦闘準備' ]}</dl>
                <dl class="cost    "><dt>必要名誉点<dd>@{[ input "schoolArts${num}Cost" ]}</dl>
                <dl class="type    "><dt>タイプ    <dd>@{[ input "schoolArts${num}Type",'','','list="list-arts-type"' ]}</dl>
                <dl class="premise "><dt>前提      <dd>@{[ input "schoolArts${num}Premise",'','','list="list-arts-premise"' ]}</dl>
                <dl class="equip   "><dt>限定条件  <dd>@{[ input "schoolArts${num}Equip" ]}</dl>
                <dl class="use     "><dt>使用      <dd>@{[ input "schoolArts${num}Use",'','','list="list-arts-use"' ]}</dl>
                <dl class="apply   "><dt>適用      <dd>@{[ input "schoolArts${num}Apply",'','','list="list-arts-apply"' ]}</dl>
                <dl class="risk    "><dt>リスク    <dd>@{[ input "schoolArts${num}Risk",'','','list="list-arts-risk"' ]}</dl>
                <dl class="summary "><dt>概要      <dd>@{[ input "schoolArts${num}Summary" ]}</dl>
                <dl class="effect  "><dt>効果      <dd><textarea name="schoolArts${num}Effect">$pc{"schoolArts${num}Effect"}</textarea></dl>
              </div>
              ROW
            }
          ) ]}
        </div>
      @{[ renderAddDelButtons('school-arts') ]}
      </details>
      <details class="box" $open{schoolMagic}>
        <summary class="in-toc">流派秘伝魔法</summary>
        <textarea name="schoolMagicNote" placeholder="流派秘伝魔法全体の注釈（あれば）">$pc{schoolMagicNote}</textarea>
        <div id="school-magic-list">
          @{[ renderTemplateLoop(
            'school-magic',
            sub ($num) {
              return <<~"ROW";
              <div class="input-data" id="school-magic-row${num}">
                <div class="handle"></div>
                <dl class="name    "><dt>名称      <dd>【@{[ input "schoolMagic${num}Name",'' ]}】<br>@{[ checkbox "schoolMagic${num}ActionTypeMinor",'補助動作' ]}@{[ checkbox "schoolMagic${num}ActionTypeSetup",'戦闘準備' ]}</dl>
                <dl class="cost    "><dt>必要名誉点<dd>@{[ input "schoolMagic${num}AcquireCost" ]}</dl>
                <dl class="level   "><dt>習得レベル<dd>@{[ input "schoolMagic${num}Lv" ]}</dl>
                <dl class="cost    "><dt>消費      <dd>@{[ input "schoolMagic${num}Cost",'','','list="list-cost"' ]}</dl>
                <dl class="target  "><dt>対象      <dd>@{[ input "schoolMagic${num}Target",'','','list="list-target"' ]}</dl>
                <dl class="range   "><dt>射程／形状<dd>@{[ input "schoolMagic${num}Range",'','','list="list-range"' ]}／@{[ input "schoolMagic${num}Form",'','','list="list-form"' ]}</dl>
                <dl class="duration"><dt>時間      <dd>@{[ input "schoolMagic${num}Duration",'','','list="list-duration"' ]}</dl>
                <dl class="resist  "><dt>抵抗      <dd>@{[ input "schoolMagic${num}Resist",'','','list="list-resist"' ]}</dl>
                <dl class="element "><dt>属性      <dd>@{[ input "schoolMagic${num}Element",'','','list="list-element"' ]}</dl>
                <dl class="summary "><dt>概要      <dd>@{[ input "schoolMagic${num}Summary" ]}</dl>
                <dl class="effect  "><dt>効果      <dd><textarea name="schoolMagic${num}Effect">$pc{"schoolMagic${num}Effect"}</textarea></dl>
              </div>
              ROW
            }
          ) ]}
        </div>
        @{[ renderAddDelButtons('school-magic') ]}
      </details>
      <details class="box" $open{schoolQnA}>
        <summary class="in-toc">Ｑ＆Ａ</summary>
        <textarea name="schoolQnA">$pc{schoolQnA}</textarea>
      </details>
    </div>
    <!-- 特殊能力 -->
    <div class="data-area in-toc" id="data-skill" data-content-title="基本データ">
      <div class="box input-data base">
        <dl class="name">
          <dt>名称
          <dd>「@{[ input 'skillName','','setName' ]}」
        </dl>
        <dl class="action">
          <dt>動作種別
          <dd>
            @{[ checkbox 'skillActionPassive','常時' ]}
            @{[ checkbox 'skillActionMinor','補助動作' ]}
            @{[ checkbox 'skillActionSetup','戦闘準備' ]}
            @{[ checkbox 'skillActionMajor','主動作' ]}
        </dl>
        <dl class="resist">
          <dt>抵抗
          <dd>
            @{[ input 'skillResist','','','list="list-resist"' ]}
        </dl>
        <dl class="action-base-value">
          <dt>基準値
          <dd>
            @{[ input 'skillActionBaseValue','','','list="list-skill-action-base-value"' ]}
        </dl>
        <dl class="resist-base-value">
          <dt>抵抗基準値
          <dd>
            @{[ input 'skillResistBaseValue','','','list="list-skill-resist-base-value"' ]}
        </dl>
        <dl class="rank">
          <dt>ランク
          <dd>
            @{[ radios 'skillRankMode','checkRankMode','0=>ランク分けなし','1=>ランク分けあり' ]}
        </dl>
      </div>
      <div class="details box">
        <h2 class="in-toc" data-content-title="詳細"><span class="for-ranks">ランクごとの</span>詳細</h2>
        <dl class="ranks">
        @{[ map {
          my $rank = $_;
          <<~"HTML";
          <dt class="rank" data-rank="${rank}">${rank}</dt>
          <dd class="rank" data-rank="${rank}">
            <dl class="details">
              <dt class="summary">概要</dt>
              <dd class="summary">@{[ input "skillRank${rank}_summary" ]}</dd>
              <dt class="effect">効果</dt>
              <dd class="effect">@{[ textarea "skillRank${rank}_effect" ]}</dd>
            </dl>
          </dd>
          HTML
        } qw/B A S SS/ ]}
        </dl>
      </div>
    </div>
  </section>
HTML

print renderEditPageEnd(
  notes => '(C)Group SNE「ソード・ワールド'.($::SW2_0 ? '2.0' : '2.5').'」',
  extraHtml => renderDataList(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-craft-required-level">
    <option value="1">
    <option value="5">
    <option value="10">
    <option value="超">
  </datalist>
  <datalist id="list-premise">
    <option value="なし">
    <option value="【】">
  </datalist>
  <datalist id="list-cost">
    <option value="―">
    <option value="MP">
    <option value="MP＋魔晶石＿点">
    <option value="HP">
    <option value="1dHP">
    <option value="2dHP">
  </datalist>
  <datalist id="list-cost-song">
    <option value="⤴">
    <option value="⤵">
    <option value="♡">
    <option value="⤴⤵">
    <option value="⤴♡">
    <option value="⤵♡">
    <option value="⤴⤵♡">
  </datalist>
  <datalist id="list-cost-alchemy">
    <option value="赤">
    <option value="緑">
    <option value="黒">
    <option value="白">
    <option value="金">
  </datalist>
  <datalist id="list-cost-geomancy">
    <option value="天の命脈点">
    <option value="地の命脈点">
    <option value="人の命脈点">
  </datalist>
  <datalist id="list-cost-psychokinesis">
    <option value="1dHP">
    <option value="2dHP">
    <option value="2d(6)HP">
    <option value="2d(9)HP">
  </datalist>
  <datalist id="list-target">
    <option value="術者" class="self">
    <option value="1体">
    <option value="1体全">
    <option value="1体X">
    <option value="物体1つ">
    <option value="任意の地点">
    <option value="接触点">
    <option value="1エリア(半径3m)／5">
    <option value="1エリア(半径4m)／10">
    <option value="1エリア(半径5m)／15">
    <option value="1エリア(半径6m)／20">
    <option value="1エリア(半径6m)／すべて">
    <option value="2～3エリア(半径10m)／すべて">
    <option value="全エリア(半径20m)／すべて">
    <option value="全エリア(半径30m)／すべて">
    <option value="1エリア(半径2m)／空間">
    <option value="1エリア(半径3m)／空間">
    <option value="1エリア(半径4m)／空間">
    <option value="1エリア(半径5m)／空間">
    <option value="1エリア(半径6m)／空間">
    <option value="2～3エリア(半径10m)／空間">
    <option value="全エリア(半径20m)／空間">
    <option value="全エリア(半径30m)／空間">
  </datalist>
  <datalist id="list-range">
    <option value="術者" class="self">
    <option value="接触">
    <option value="1(10m)">
    <option value="2(20m)">
    <option value="2(30m)">
    <option value="2(50m)">
    <option value="2(無限)">
    <option value="2()">
  </datalist>
  <datalist id="list-form">
    <option value="―">
    <option value="射撃">
    <option value="起点指定">
    <option value="貫通">
    <option value="突破">
  </datalist>
  <datalist id="list-duration">
    <option value="一瞬">
    <option value="10秒(1ラウンド)">
    <option value="30秒(3ラウンド)">
    <option value="1分(6ラウンド)">
    <option value="3分(18ラウンド)">
    <option value="10分(60ラウンド)">
    <option value="1時間">
    <option value="3時間">
    <option value="6時間">
    <option value="1日">
    <option value="永続">
    <option value="特殊">
    <option value="さまざま">
    <option value="一瞬／10秒(1ラウンド)">
    <option value="一瞬／30秒(3ラウンド)">
    <option value="一瞬／1分(6ラウンド)">
    <option value="一瞬／3分(18ラウンド)">
    <option value="一瞬／10分(60ラウンド)">
    <option value="一瞬／1時間">
    <option value="一瞬／1日">
    <option value="一瞬／さまざま">
  </datalist>
  <datalist id="list-resist">
    <option value="なし">
    <option value="任意">
    <option value="消滅">
    <option value="半減">
    <option value="短縮">
    <option value="必中">
    <option value="生命／消滅">
    <option value="生命／半減">
  </datalist>
  <datalist id="list-element">
    <option value="土">
    <option value="水・氷">
    <option value="炎">
    <option value="風">
    <option value="雷">
    <option value="純エネルギー">
    <option value="断空">
    <option value="衝撃">
    <option value="毒">
    <option value="病気">
    <option value="精神効果">
    <option value="精神効果（弱）">
    <option value="呪い">
    <option value="呪い＋精神効果">
  </datalist>
  <datalist id="list-sphere">
    <option value="小">
    <option value="中">
    <option value="大">
    <option value="大中小">
    <option value="大（＿個）">
  </datalist>
  <datalist id="list-song-condition">
    <option value="なし">
    <option value="⤴">
    <option value="⤵">
    <option value="♡">
    <option value="⤴⤵">
    <option value="⤴♡">
    <option value="⤵♡">
  </datalist>
  <datalist id="list-songpoint">
    <option value="⤴">
    <option value="⤵">
    <option value="♡">
    <option value="⤴⤵">
    <option value="⤴♡">
    <option value="⤵♡">
  </datalist>
  <datalist id="list-song-set-point">
    <option value="13">
    <option value="18">
    <option value="24">
  </datalist>
  <datalist id="list-part">
    <option value="―">
    <option value="すべて">
    <option value="コア部位">
    <option value="その他部位">
    <option value="その他部位すべて">
    <option value="頭部">
    <option value="胴体">
    <option value="上半身">
    <option value="翼">
    <option value="邪眼">
    <option value="蠍">
    <option value="鋏">
  </datalist>
  <datalist id="list-school-req">
    <option value="50名誉点">
  </datalist>
  <datalist id="list-arts-type">
    <option value="常時型">
    <option value="主動作型">
    <option value="《》変化型">
    <option value="独自宣言型">
  </datalist>
  <datalist id="list-arts-premise">
    <option value="なし">
    <option value="《》">
    <option value="《》《》">
    <option value="《》《》《》">
    <option value="《》《》《》《》">
    <option value="【】">
    <option value="【】【】">
  </datalist>
  <datalist id="list-arts-use">
    <option value="―">
    <option value="ファイター技能">
    <option value="グラップラー技能">
    <option value="フェンサー技能">
    <option value="バトルダンサー技能">
    <option value="ファイター技能 or バトルダンサー技能">
    <option value="ファイター技能 or フェンサー技能 or バトルダンサー技能">
    <option value="フェンサー技能 or バトルダンサー技能">
    <option value="シューター技能">
    <option value="近接攻撃武器">
    <option value="魔法使い系技能">
    <option value="特殊">
  </datalist>
  <datalist id="list-arts-apply">
    <option value="―">
    <option value="1回の武器攻撃">
    <option value="1回の近接攻撃">
    <option value="1回の遠隔攻撃">
    <option value="1回の射撃攻撃">
    <option value="1回の魔法行使">
    <option value="10秒（1ラウンド）持続">
  </datalist>
  <datalist id="list-arts-risk">
    <option value="―">
    <option value="なし">
    <option value="回避力判定-1">
    <option value="回避力判定-2">
    <option value="生命・精神抵抗力判定-2">
    <option value="ほとんどの行為判定-4">
    <option value="〈盾〉の防護点、回避力の有利な修正無効">
  </datalist>
  <datalist id="list-skill-action-base-value">
    <option value="―">
    <option value="フィジカルマスター技能レベル＋器用度ボーナス">
    <option value="フィジカルマスター技能レベル＋敏捷度ボーナス">
    <option value="フィジカルマスター技能レベル＋筋力ボーナス">
    <option value="フィジカルマスター技能レベル＋生命力ボーナス">
    <option value="フィジカルマスター技能レベル＋知力ボーナス">
    <option value="フィジカルマスター技能レベル＋精神力ボーナス">
    <option value="冒険者レベル＋器用度ボーナス">
    <option value="冒険者レベル＋敏捷度ボーナス">
    <option value="冒険者レベル＋筋力ボーナス">
    <option value="冒険者レベル＋生命力ボーナス">
    <option value="冒険者レベル＋知力ボーナス">
    <option value="冒険者レベル＋精神力ボーナス">
  </datalist>
  <datalist id="list-skill-resist-base-value">
    <option value="―">
    <option value="生命抵抗力">
    <option value="精神抵抗力">
  </datalist>
  HTML
}

1;
