############# フォーム・アイテム #############
use strict;
#use warnings;
use utf8;
use open ":utf8";

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_class;
my @magic_classes;
my @craft_classes;
foreach(@data::class_names){
  if($_ eq 'フェアリーテイマー'){
    push(@magic_classes, '基本妖精魔法', '属性妖精魔法(土)', '属性妖精魔法(水・氷)', '属性妖精魔法(炎)', '属性妖精魔法(風)', '属性妖精魔法(光)', '属性妖精魔法(闇)', '特殊妖精魔法');
  }
  elsif($_ eq 'コンジャラー'){
    push(@craft_classes, $data::class{$_}{'magic'}{'jName'}, '深智魔法');
  }
  elsif($_ eq 'バード'){
    push(@craft_classes, $data::class{$_}{'craft'}{'jName'}, '終律');
  }
  elsif($_ eq 'ウォーリーダー'){
    push(@craft_classes, '鼓咆','陣率');
  }
  elsif($data::class{$_}{'magic'}) { push(@magic_classes, $data::class{$_}{'magic'}{'jName'}); }
  elsif($data::class{$_}{'craft'}) { push(@craft_classes, $data::class{$_}{'craft'}{'jName'}); }
}
push(@magic_classes, @craft_classes);
### データ読み込み ###################################################################################
my ($data, $mode, $file, $message) = pcDataGet($::in{'mode'});
our %pc = %{ $data };

my $mode_make = ($mode =~ /^(blanksheet|copy|convert)$/) ? 1 : 0;

### 出力準備 #########################################################################################
if($message){
  my $name = tag_unescape($pc{'category'} eq 'magic' ? $pc{'magicName'} : $pc{'category'} eq 'god' ? $pc{'godAka'}.$pc{'godName'} : '無題');
  $message =~ s/<!NAME>/$name/;
}
### 製作者名 --------------------------------------------------
if($mode_make){
  $pc{'author'} = (getplayername($LOGIN_ID))[0];
}
### 初期設定 --------------------------------------------------
if($mode_make){ $pc{'protect'} = $LOGIN_ID ? 'account' : 'password'; }

if($mode eq 'edit' || ($mode eq 'convert' && $pc{'ver'})){
  %pc = data_update_arts(\%pc);
}
if($mode eq 'blanksheet'){
  $pc{"magicCost"} = 'MP';
  foreach my $lv (2,4,7,10,13){ $pc{"godMagic${lv}Cost"} = 'MP' }
  $pc{'schoolReq'} = '＿名誉点';
}

## カラー
setDefaultColors();

## その他
$pc{"schoolArtsNum"} ||= 3;

### 改行処理 --------------------------------------------------
foreach (
  'magicEffect',
  'magicDescription',
  'godSymbol',
  'godDeity',
  'godNote',
  'godMagic2Effect',
  'godMagic4Effect',
  'godMagic7Effect',
  'godMagic10Effect',
  'godMagic13Effect',
  'schoolNote',
  'schoolItemNote',
){
  $pc{$_} =~ s/&lt;br&gt;/\n/g;
}
foreach my $num (1..$pc{'schoolArtsNum'}){
  $pc{"schoolArts${num}Effect"} =~ s/&lt;br&gt;/\n/g;
}

### 画像 --------------------------------------------------
my $imgurl = shift;
my $image_maxsize = $set::image_maxsize / 4;
  my $image_maxsize_view = $image_maxsize >= 1048576 ? sprintf("%.3g",$image_maxsize/1048576).'MB' : sprintf("%.3g",$image_maxsize/1024).'KB';

### フォーム表示 #####################################################################################
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>@{[$mode eq 'edit'?"編集：$pc{'itemName'}":'新規作成']} - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/base.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/sheet.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/arts.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/sw2/edit-arts.js?${main::ver}" defer></script>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/\@fortawesome/fontawesome-free\@5.15.4/css/all.min.css" integrity="sha256-mUZM63G8m73Mcidfrv5E+Y61y7a12O5mW4ezU3bxqW4=" crossorigin="anonymous">
  <style>
    #image {
      background-image: url("${set::arts_dir}${file}/image.$pc{'image'}?$pc{'imageUpdate'}");
    }
  </style>
</head>
<body>
  <script src="${main::core_dir}/skin/_common/js/common.js?${main::ver}"></script>
  <header>
    <h1>$set::title</h1>
  </header>

  <main>
    <article>
      <form id="arts" name="sheet" method="post" action="./" enctype="multipart/form-data">
      <input type="hidden" name="ver" value="${main::ver}">
      <input type="hidden" name="type" value="a">
HTML
if($mode_make){
  print '<input type="hidden" name="_token" value="'.token_make().'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
            
      <div id="header-menu">
        <h2><span></span></h2>
        <ul>
          <li onclick="sectionSelect('common');"><span>魔法</span><span>データ</span></li>
          <li onclick="sectionSelect('color');" class="color-icon" title="カラーカスタム"></span></li>
          <li onclick="view('text-rule')" class="help-icon" title="テキスト整形ルール"></li>
          <li onclick="nightModeChange()" class="nightmode-icon" title="ナイトモード切替"></li>
          <li class="buttons">
            <ul>
              <li @{[ display ($mode eq 'edit') ]} class="view-icon" title="閲覧画面"><a href="./?id=$::in{'id'}"></a></li>
              <li @{[ display ($mode eq 'edit') ]} class="copy" onclick="window.open('./?mode=copy&id=$::in{'id'}@{[  $::in{'log'}?"&log=$::in{'log'}":'' ]}');">複製</li>
              <li class="submit" onclick="formSubmit()" title="Ctrl+S">保存</li>
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
    <input type="hidden" name="protectOld" value="$pc{'protect'}">
    <input type="hidden" name="pass" value="$::in{'pass'}">
HTML
}
else {
  if($set::registerkey && $mode_make){
    print '登録キー：<input type="text" name="registerkey" required>'."\n";
  }
  print <<"HTML";
      <details class="box" id="edit-protect" @{[$mode eq 'edit' ? '':'open']}>
      <summary>編集保護設定</summary>
      <p id="edit-protect-view"><input type="hidden" name="protectOld" value="$pc{'protect'}">
HTML
  if($LOGIN_ID){
    print '<input type="radio" name="protect" value="account"'.($pc{'protect'} eq 'account'?' checked':'').'> アカウントに紐付ける（ログイン中のみ編集可能になります）<br>';
  }
    print '<input type="radio" name="protect" value="password"'.($pc{'protect'} eq 'password'?' checked':'').'> パスワードで保護 ';
  if ($mode eq 'edit' && $pc{'protect'} eq 'password') {
    print '<input type="hidden" name="pass" value="'.$::in{'pass'}.'"><br>';
  } else {
    print '<input type="password" name="pass"><br>';
  }
  print <<"HTML";
<input type="radio" name="protect" value="none"@{[ $pc{'protect'} eq 'none'?' checked':'' ]}> 保護しない（誰でも編集できるようになります）
      </p>
      </details>
HTML
}
  print <<"HTML";
      <dl class="box" id="hide-options">
        <dt>閲覧可否設定</dt>
        <dd id="forbidden-checkbox">
          <select name="forbidden">
            <option value="">内容を全て開示
            <option value="battle" @{[ $pc{'forbidden'} eq 'battle' ? 'selected' : '' ]}>データ・数値のみ秘匿
            <option value="all"    @{[ $pc{'forbidden'} eq 'all'    ? 'selected' : '' ]}>内容を全て秘匿
          </select>
        </dd>
        <dd id="hide-checkbox">
          <select name="hide">
            <option value="">一覧に表示
            <option value="1" @{[ $pc{'hide'} ? 'selected' : '' ]}>一覧には非表示
          </select>
        </dd>
        <dd>
          ※一覧に非表示でもタグ検索結果・マイリストには表示されます
        </dd>
      </dl>
      <div class="box" id="group">
        <dl>
          <dt>タグ</dt><dd>@{[ input 'tags' ]}</dd>
        </dl>
      </div>

      <div class="box" id="name-form">
        <div>
          <dl id="category">
            <dt>カテゴリ</dt>
            <dd><select name="category" oninput="checkCategory();">@{[ option 'category','magic|<魔法／練技・呪歌など>','god|<神格＋特殊神聖魔法>','school|<流派＋秘伝>' ]}</select></dd>
          </dl>
        </div>
        <dl id="player-name">
          <dt>製作者</dt>
          <dd>@{[input('author')]}</dd>
        </dl>
      </div>
      <div class="data-area box" id="data-none">
        <p>カテゴリを選択してください。</p>
      </div>
      <!-- 魔法 -->
      <div class="data-area" id="data-magic">
        <div class="box input-data">
          <dl class="name     "><dt>名称        </dt><dd>【@{[ input 'magicName','',"nameSet" ]}】<br>
                                                          @{[ checkbox 'magicActionTypePassive','常時' ]}@{[ checkbox 'magicActionTypeMajor','主動作' ]}@{[ checkbox 'magicActionTypeMinor','補助動作' ]}@{[ checkbox 'magicActionTypeSetup','戦闘準備' ]}</dd></dl>
          <dl class="class    "><dt>系統        </dt><dd>@{[ selectInput "magicClass","checkMagicClass",@magic_classes ]} @{[ checkbox 'magicMinor','小魔法' ]}</dd></dl>
          <dl class="sphere   "><dt>マギスフィア</dt><dd>@{[ input 'magicMagisphere','','','list="list-sphere"' ]}</dd></dl>
          <dl class="level    "><dt>習得レベル  </dt><dd>@{[ input 'magicLevel' ]}</dd></dl>
          <dl class="type     "><dt>対応        </dt><dd>@{[ input 'magicType','','','list="list-type"' ]}</dd></dl>
          <dl class="premise  "><dt>前提        </dt><dd>@{[ input 'magicPremise' ]}</dd></dl>
          <dl class="cost     "><dt>消費        </dt><dd>@{[ input 'magicCost','','','list="list-cost"' ]}</dd></dl>
          <dl class="target   "><dt>対象        </dt><dd>@{[ input 'magicTarget','','','list="list-target"' ]}</dd></dl>
          <dl class="range    "><dt>射程／形状  </dt><dd>@{[ input 'magicRange','','','list="list-range"' ]}／@{[ input 'magicForm','','','list="list-form"' ]}</dd></dl>
          <dl class="duration "><dt>時間        </dt><dd>@{[ input 'magicDuration','','','list="list-duration"' ]}</dd></dl>
          <dl class="song     "><dt>歌唱        </dt><dd>@{[ checkbox 'magicSongSing','必要' ]}</dd></dl>
          <dl class="song     "><dt>ペット      </dt><dd>@{[ checkbox 'magicSongPetBird','小鳥' ]}@{[ checkbox 'magicSongPetFrog','蛙' ]}@{[ checkbox 'magicSongPetBug','虫' ]}</dd></dl>
          <dl class="condition"><dt>条件        </dt><dd>@{[ input 'magicCondition','','','list="list-songpoint"' ]}</dd></dl>
          <dl class="song     "><dt>楽素        </dt><dd>基礎@{[ input 'magicSongBasePoint','','','list="list-songpoint"' ]} 巧奏値@{[ input 'magicSongSetPoint' ]} 追加@{[ input 'magicSongAddPoint','','','list="list-songpoint"' ]}</dd></dl>
          <dl class="rider    "><dt>対応        </dt><dd>@{[ checkbox 'magicMountTypeAnimal','動物' ]}@{[ checkbox 'magicMountTypeCryptid','幻獣' ]}@{[ checkbox 'magicMountTypeMachine','魔動機' ]}</dd></dl>
          <dl class="part     "><dt>適用部位    </dt><dd>@{[ input 'magicApplyPart','','','list="list-part"' ]}</dd></dl>
          <dl class="rank     "><dt>ランク      </dt><dd>@{[ input 'magicRank' ]}</dd></dl>
          <dl class="commcost "><dt>陣気コスト  </dt><dd>@{[ input 'magicCommandCost','number' ]}消費</dd></dl>
          <dl class="command  "><dt>陣気蓄積    </dt><dd>＋@{[ input 'magicCommandCharge','number' ]}</dd></dl>
          <dl class="resist   "><dt>抵抗        </dt><dd>@{[ input 'magicResist','','','list="list-resist"' ]}</dd></dl>
          <dl class="element  "><dt>属性        </dt><dd>@{[ input 'magicElement','','','list="list-element"' ]}</dd></dl>
          <dl class="summary  "><dt>概要        </dt><dd>@{[ input 'magicSummary' ]}</dd></dl>
          <dl class="effect   "><dt>効果        </dt><dd><textarea name="magicEffect">$pc{'magicEffect'}</textarea></dd></dl>
          
        </div>
        <div class="box">
          <h2>由来・逸話など</h2>
          <textarea name="magicDescription">$pc{'magicDescription'}</textarea>
        </div>
      </div>
      <!-- 神格 -->
      <div class="data-area" id="data-god">
        <div class="box input-data">
          <div id="image" style="">
            <h2>聖印の画像</h2>
            <p>
              プレビューエリアに画像ファイルをドロップ、または
              <input type="file" accept="image/*" name="imageFile" onchange="imagePreView(this.files[0], $image_maxsize || 0)"><br>
              ※ ファイルサイズ @{[ $image_maxsize_view ]} までの JPG/PNG/GIF/WebP
              <small>（サイズを超過する場合、自動的にWebP形式に変換し、その上でまだ超過している場合は縮小処理が行われます）</small>
              <input type="hidden" name="imageCompressed">
              <input type="hidden" name="imageCompressedType">
            </p>
            <p>
              <input type="checkbox" name="imageDelete" value="1"> 画像を削除する
              @{[input('image','hidden')]}
            </p>
          <script>
            const imageType = 'symbol';
            let imgURL = "${imgurl}";
          </script>
          </div>
          <dl class="name  "><dt>名称      </dt><dd>@{[ input 'godName','',"nameSet" ]}</dd></dl>
          <dl class="aka   "><dt>異名      </dt><dd>“@{[ input 'godAka','',"nameSet" ]}”</dd></dl>
          <dl class="class "><dt>系統      </dt><dd><select name="godClass">@{[ option 'godClass','第一の剣','第二の剣','第三の剣','不明' ]}</select>／<select name="godRank">@{[ option 'godRank','古代神','大神','小神' ]}</select></dd></dl>
          <dl class="area  "><dt>地域      </dt><dd>@{[ input 'godArea','','','placeholder="大陸・地方など"' ]}<small>※主に小神向けの項目です</small></dd></dl>
          <dl class="symbol"><dt>聖印と神像</dt><dd><textarea name="godSymbol">$pc{'godSymbol'}</textarea></dd></dl>
          <dl class="deity "><dt>神格と教義</dt><dd><textarea name="godDeity">$pc{'godDeity'}</textarea></dd></dl>
          <dl class="maxim "><dt>格言      </dt><dd>「@{[ input "godMaxim1" ]}」<br>「@{[ input "godMaxim2" ]}」<br>「@{[ input "godMaxim3" ]}」</dd></dl>
          <dl class="deity "><dt>備考      </dt><dd><textarea name="godNote" placeholder="他神との関係やその他逸話、データの諸注意などなんでも">$pc{'godNote'}</textarea></dd></dl>
        </div>
        <div class="box input-data">
HTML
foreach my $lv (2,4,7,10,13){
print <<"HTML";
          <h2>特殊神聖魔法 ${lv}レベル</h2>
          <dl class="name    "><dt>名称      </dt><dd>【@{[ input "godMagic${lv}Name",'' ]}】<br>@{[ checkbox "godMagic${lv}ActionTypeMinor",'補助動作' ]}@{[ checkbox "godMagic${lv}ActionTypeSetup",'戦闘準備' ]}</dd></dl>
          <dl class="cost    "><dt>消費      </dt><dd>@{[ input "godMagic${lv}Cost" ]}</dd></dl>
          <dl class="target  "><dt>対象      </dt><dd>@{[ input "godMagic${lv}Target",'','','list="list-target"' ]}</dd></dl>
          <dl class="range   "><dt>射程／形状</dt><dd>@{[ input "godMagic${lv}Range",'','','list="list-range"' ]}／@{[ input "godMagic${lv}Form",'','','list="list-form"' ]}</dd></dl>
          <dl class="duration"><dt>時間      </dt><dd>@{[ input "godMagic${lv}Duration",'','','list="list-duration"' ]}</dd></dl>
          <dl class="resist  "><dt>抵抗      </dt><dd>@{[ input "godMagic${lv}Resist",'','','list="list-resist"' ]}</dd></dl>
          <dl class="element "><dt>属性      </dt><dd>@{[ input "godMagic${lv}Element",'','','list="list-element"' ]}</dd></dl>
          <dl class="summary "><dt>概要      </dt><dd>@{[ input "godMagic${lv}Summary" ]}</dd></dl>
          <dl class="effect  "><dt>効果      </dt><dd><textarea name="godMagic${lv}Effect">$pc{"godMagic${lv}Effect"}</textarea></dd></dl>
HTML
}
print <<"HTML";
        </div>
      </div>
      <!-- 流派 -->
      <div class="data-area" id="data-school">
        <div class="box input-data">
          <dl class="name  "><dt>名称      </dt><dd>【@{[ input 'schoolName','',"nameSet" ]}】</dd></dl>
          <dl class="area  "><dt>地域      </dt><dd>@{[ input 'schoolArea','','','placeholder="大陸・地方など"' ]}</dd></dl>
          <dl class="req   "><dt>入門条件  </dt><dd>@{[ input 'schoolReq','','','list="list-school-req"' ]}</dd></dl>
          <dl class="note  "><dt>詳細      </dt><dd><textarea name="schoolNote">$pc{'schoolNote'}</textarea></dd></dl>
          <dl class="arms  "><dt>流派装備  </dt><dd><textarea name="schoolItemNote" placeholder="流派装備の概要">$pc{'schoolItemNote'}</textarea></dd></dl>
          <dl class="arms  "><dt>流派装備一覧</dt>
            <dd>
              <input type="text" id="schoolItemUrl" placeholder="アイテムシートのURL"><span class="button" onclick="addSchoolItem()">追加</span>
              @{[ input 'schoolItemList','hidden' ]}
              <table id="school-item-list" class="data-table">
              <thead>
                <th>名前</th>
                <th>カテゴリ</th>
                <th>概要</th>
                <th></th>
              </thead>
              <tbody></tbody>
              </table>
            </dd></dl>
        </div>
        @{[ input 'schoolArtsNum','hidden' ]}
        <div class="box">
          <h2>流派秘伝</h2>
          <div id="arts-list">
HTML
foreach my $num (1..$pc{'schoolArtsNum'}){
print <<"HTML";
          <div class="input-data" id="arts${num}">
            <dl class="name    "><dt>名称      </dt><dd>《@{[ input "schoolArts${num}Name",'' ]}》</dd></dl>
            <dl class="cost    "><dt>必要名誉点</dt><dd>@{[ input "schoolArts${num}Cost" ]}</dd></dl>
            <dl class="type    "><dt>タイプ    </dt><dd>@{[ input "schoolArts${num}Type",'','','list="list-arts-type"' ]}</dd></dl>
            <dl class="premise "><dt>前提      </dt><dd>@{[ input "schoolArts${num}Premise",'','','list="list-arts-base"' ]}</dd></dl>
            <dl class="equip   "><dt>限定条件  </dt><dd>@{[ input "schoolArts${num}Equip" ]}</dd></dl>
            <dl class="use     "><dt>使用      </dt><dd>@{[ input "schoolArts${num}Use" ]}</dd></dl>
            <dl class="apply   "><dt>適用      </dt><dd>@{[ input "schoolArts${num}Apply",'','','list="list-arts-apply"' ]}</dd></dl>
            <dl class="risk    "><dt>リスク    </dt><dd>@{[ input "schoolArts${num}Risk" ]}</dd></dl>
            <dl class="summary "><dt>概要      </dt><dd>@{[ input "schoolArts${num}Summary" ]}</dd></dl>
            <dl class="effect  "><dt>効果      </dt><dd><textarea name="schoolArts${num}Effect">$pc{"schoolArts${num}Effect"}</textarea></dd></dl>
          </div>
HTML
}
print <<"HTML";
          </div>
          <div class="add-del-button"><a onclick="addArts()">▼</a><a onclick="delArts()">▲</a></div>
        </div>
      </div>
    </section>
      
      @{[ colorCostomForm ]}
    
      @{[ input 'birthTime','hidden' ]}
      <input type="hidden" name="id" value="$::in{'id'}">
    </form>
HTML
if($mode eq 'edit'){
print <<"HTML";
    <form name="del" method="post" action="./" id="deleteform">
      <p style="font-size: 80%;">
      <input type="hidden" name="mode" value="delete">
      <input type="hidden" name="type" value="a">
      <input type="hidden" name="id" value="$::in{'id'}">
      <input type="hidden" name="pass" value="$::in{'pass'}">
      <input type="checkbox" name="check1" value="1" required>
      <input type="checkbox" name="check2" value="1" required>
      <input type="checkbox" name="check3" value="1" required>
      <input type="submit" value="シート削除"><br>
      ※チェックを全て入れてください
      </p>
    </form>
HTML
}
print <<"HTML";
    </article>
HTML
# ヘルプ
my $text_rule = <<"HTML";
        アイコン<br>
        　魔法のアイテム：<code>[魔]</code>：<img class="i-icon" src="${set::icon_dir}wp_magic.png"><br>
        　刃武器　　　　：<code>[刃]</code>：<img class="i-icon" src="${set::icon_dir}wp_edge.png"><br>
        　打撃武器　　　：<code>[打]</code>：<img class="i-icon" src="${set::icon_dir}wp_blow.png"><br>
HTML
print textRuleArea( $text_rule,'「効果」「備考」「由来・逸話など」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">(C)Group SNE「ソード・ワールド2.0／2.5」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
  </footer>
  <datalist id="list-cost">
    <option value="MP">
    <option value="MP＋魔晶石＿点">
    <option value="HP">
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
  <datalist id="list-target">
    <option value="術者">
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
    <option value="術者">
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
  <datalist id="list-songpoint">
    <option value="⤴">
    <option value="⤵">
    <option value="♡">
    <option value="⤴⤵">
    <option value="⤴♡">
    <option value="⤵♡">
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
  <datalist id="list-arts-apply">
    <option value="1回の武器攻撃">
    <option value="1回の近接攻撃">
    <option value="1回の遠隔攻撃">
    <option value="1回の射撃攻撃">
    <option value="1回の魔法行使">
    <option value="10秒（1ラウンド）持続">
  </datalist>
<script>
function view(viewId){
  let value = document.getElementById(viewId).style.display;
  document.getElementById(viewId).style.display = (value === 'none') ? '' : 'none';
}
</script>
</body>
</html>
HTML

1;