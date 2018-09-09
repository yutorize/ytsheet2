############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";
use Encode;

my $mode = $main::mode;
my $message = $main::message;
our %pc;

my $LOGIN_ID = check;

### 読込前処理 #######################################################################################
### エラーメッセージ --------------------------------------------------
if($main::make_error) {
  $mode = 'blanksheet';
  for (param()){ $pc{$_} = param($_); }
  $message = $main::make_error;
}
## 新規作成＆コピー時 --------------------------------------------------
my $token;
if($mode eq 'blanksheet' || $mode eq 'copy'){
  $token = token_make();
  
  if(!$pc{'playerName'}){
    $pc{'playerName'} = (getplayername($LOGIN_ID))[0];
  }
}
## 更新後処理 --------------------------------------------------
if($mode eq 'save'){
  $message .= 'データを更新しました。<a href="./?id='.param('id').'">⇒シートを確認する</a>';
  $mode = 'edit';
}
### データ読み込み ###################################################################################
my $id;
my $pass;
my $file;
### 編集時 --------------------------------------------------
if($mode eq 'edit'){
  $id = param('id');
  $pass = param('pass');
  (undef, undef, $file, undef) = getfile($id,$pass,$LOGIN_ID);
  open my $IN, '<', "${set::char_dir}${file}/data.cgi" or &login_error;
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
}
if($mode eq 'copy'){
  $id = param('id');
  $file = (getfile_open($id))[0];
  open my $IN, '<', "${set::char_dir}${file}/data.cgi" or error 'キャラクターシートがありません。';
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
  
  delete $pc{'image'};  
  
  $message = '「<a href="./?id='.$id.'" target="_blank">'.$pc{"characterName"}.'</a>」コピーして新規作成します。<br>（まだ保存はされていません）';
}

### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_feats;
require $set::data_races;
require $set::data_items;
require $set::data_faith;

### 出力準備 #########################################################################################
### 初期設定 --------------------------------------------------
$pc{'protect'} = $pc{'protect'} ? $pc{'protect'} : 'password';
$pc{'group'} = $pc{'group'} ? $pc{'group'} : $set::group_default;

$pc{'history0Exp'}   = $pc{'history0Exp'}   ne '' ? $pc{'history0Exp'}   : $set::make_exp;
$pc{'history0Honor'} = $pc{'history0Honor'} ne '' ? $pc{'history0Honor'} : $set::make_honor;
$pc{'history0Money'} = $pc{'history0Money'} ne '' ? $pc{'history0Money'} : $set::make_money;
$pc{'expTotal'} = $pc{'expTotal'} ? $pc{'expTotal'} : $pc{'history0Exp'};

$pc{'accuracyEnhance'} = $pc{'accuracyEnhance'} ? $pc{'accuracyEnhance'} : 0;
$pc{'evasiveManeuver'} = $pc{'evasiveManeuver'} ? $pc{'evasiveManeuver'} : 0;
$pc{'tenacity'} = $pc{'tenacity'} ? $pc{'tenacity'} : 0;
$pc{'capacity'} = $pc{'capacity'} ? $pc{'capacity'} : 0;

$pc{'weaponNum'}   = $pc{'weaponNum'}   ? $pc{'weaponNum'}   : 3;
$pc{'languageNum'} = $pc{'languageNum'} ? $pc{'languageNum'} : 5;
$pc{'historyNum'}  = $pc{'historyNum'}  ? $pc{'historyNum'}  : 5;

### 改行処理 --------------------------------------------------
$pc{'items'}         =~ s/&lt;br&gt;/\n/g;
$pc{'freeNote'}      =~ s/&lt;br&gt;/\n/g;
$pc{'cashbook'}      =~ s/&lt;br&gt;/\n/g;
$pc{'fellowProfile'} =~ s/&lt;br&gt;/\n/g;
$pc{'fellowNote'}    =~ s/&lt;br&gt;/\n/g;


### フォーム表示 #####################################################################################
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>@{[$mode eq 'edit'?"編集：$pc{'characterName'}":'新規作成']} - $set::title</title>
  <link rel="stylesheet" media="all" href="./skin/css/base.css?201809010000">
  <link rel="stylesheet" media="all" href="./skin/css/sheet.css?201808272000">
  <link rel="stylesheet" media="all" href="./skin/css/chara.css?201808272000">
  <link rel="stylesheet" media="all" href="./skin/css/sheet-sp.css?201808211430">
  <link rel="stylesheet" media="all" href="./skin/css/edit.css?201808211430">
  <link rel="stylesheet" id="nightmode">
  <script src="./skin/js/common.js?201808211430" ></script>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    #image {
      background-image: url("${set::char_dir}${file}/image.$pc{'image'}");
    }
    #image > * {
      background: rgba(255,255,255,0.8);
    }
  </style>
</head>
<body>
  <header>
    <h1>$set::title</h1>
  </header>

  <main>
    <article>
      <aside class="message">$message</aside>
      <form name="sheet" method="post" action="./" enctype="multipart/form-data">
HTML
if($mode eq 'blanksheet' || $mode eq 'copy'){
  print '<input type="hidden" name="_token" value="'.$token.'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      <div id="area-name">
        <div id="character-name">
        <!-- 称号：<input type="text" id="aka"> -->
        キャラクター名@{[input('characterName','text','','required')]}
        </div>
        <div>
        <p id="update-time"></p>
        <p id="player-name">プレイヤー名@{[input('playerName')]}</p>
        </div>
HTML
if($mode eq 'edit'){
print <<"HTML";
        <input type="button" value="複製" onclick="window.open('./?mode=copy&id=${id}');">
HTML
}
print <<"HTML";
        <input type="submit" value="保存">
      </div>
HTML
if($set::registerkey && ($mode eq 'blanksheet' || $mode eq 'copy')){
  print '登録キー：<input type="text" name="registerkey" required>'."\n";
}
print <<"HTML";
      <div class="box" id="edit-protect">
      <h2 onclick="view('edit-protect-view')">編集保護設定 ▼</h2>
      <p id="edit-protect-view" @{[$mode eq 'edit' ? 'style="display:none"':'']}><input type="hidden" name="protectOld" value="$pc{'protect'}">
HTML
if($LOGIN_ID){
  print '<input type="radio" name="protect" value="account"'.($pc{'protect'} eq 'account'?' checked':'').'> アカウントに紐付ける（ログイン中のみ編集可能になります）<br>';
}
  print '<input type="radio" name="protect" value="password"'.($pc{'protect'} eq 'password'?' checked':'').'> パスワードで保護 ';
if ($mode eq 'edit' && $pass) {
  print '<input type="hidden" name="pass" value="'.$pass.'"><br>';
} else {
  print '<input type="password" name="pass"><br>';
}
print <<"HTML";
<input type="radio" name="protect" value="none"@{[ $pc{'protect'} eq 'none'?' checked':'' ]}> 保護しない（誰でも編集できるようになります）
      </p>
      </div>
      <p id="hide-checkbox">
      @{[ input 'hide','checkbox' ]} 一覧に表示しない<br>
      ※タグ検索結果に合致した場合は表示されます
      </p>
      <div class="box" id="group">
        <dl>
          <dt>グループ</dt><dd><select name="group">
HTML
foreach (@set::groups){
  my $id   = @$_[0];
  my $name = @$_[2];
  print '<option value="'.$id.'"'.($pc{'group'} eq $id ? ' selected': '').'>'.$name.'</option>';
}
print <<"HTML";
          </select></dd>
          <dt>タグ</dt><dd>@{[ input 'tags','','','' ]}</dd>
        </dl>
      </div>
      <div class="box" id="regulation">
        <h2>作成レギュレーション</h2>
        <dl>
          <dt>経験点</dt>
          <dd>@{[input("history0Exp",'number','changeRegu','step="500"'.($set::make_fix?' readonly':''))]}</dd>
          <dt>名誉点</dt>
          <dd>@{[input("history0Honor",'number','changeRegu', ($set::make_fix?' readonly':''))]}</dd>
          <dt>所持金</dt>
          <dd>@{[input("history0Money",'number','changeRegu', ($set::make_fix?' readonly':''))]}</dd>
          <dt>初期成長</dt>
          <dd>器用度:@{[ input "sttPreGrowA",'number','calcStt' ]}</dd>
          <dd>敏捷度:@{[ input "sttPreGrowB",'number','calcStt' ]}</dd>
          <dd>　筋力:@{[ input "sttPreGrowC",'number','calcStt' ]}</dd>
          <dd>生命力:@{[ input "sttPreGrowD",'number','calcStt' ]}</dd>
          <dd>　知力:@{[ input "sttPreGrowE",'number','calcStt' ]}</dd>
          <dd>精神力:@{[ input "sttPreGrowF",'number','calcStt' ]}</dd>
        </dl>
      </div>
      <div id="area-status">
        <div class="box" id="image">
          <h2>キャラクター画像</h2>
          <div><p>
            <input type="file" accept="image/*" name="imageFile"><br>
            ※ @{[ int($set::image_maxsize / 1024) ]}KBまでのJPG/PNG/GIF<br>
            表示方式：<select name="imageFit">
            <option value="cover"   @{[$pc{'imageFit'} eq 'cover'  ?'selected':'']}>枠いっぱいに表示
            <option value="contain" @{[$pc{'imageFit'} eq 'contain'?'selected':'']}>画像全体を表示
            <option value="unset"   @{[$pc{'imageFit'} eq 'unset'  ?'selected':'']}>拡大せず表示
            </select><br>
            <br>
            <input type="checkbox" name="imageDelete" value="1">画像を削除する
            @{[input('image','hidden')]}
          </p>
          </div>
          <p>
          画像の注釈（作者や権利表記など）
          @{[ input 'imageCopyright' ]}
          </p>
          <h2>セリフ</h2>
          <p class="words-input">
          @{[ input 'words' ]}<br>
          セリフの配置：
          <select name="wordsX">@{[ option 'wordsX','右','左' ]}</select>
          <select name="wordsY">@{[ option 'wordsY','上','下' ]}</select>
          </p>
        </div>

        <div id="personal">
          <dl class="box" id="race">
            <dt>種族</dt><dd><select name="race" oninput="changeRace()">@{[ option 'race', @data::race_names ]}</select></dd>
          </dl>
          <dl class="box" id="gender">
            <dt>性別</dt><dd>@{[input('gender')]}</dd>
          </dl>
          <dl class="box" id="age">
            <dt>年齢</dt><dd>@{[input('age')]}</dd>
          </dl>
          <dl class="box" id="race-ability">
            <dt>種族特徴</dt><dd id="race-ability-value">$data::race_ability{$pc{'race'}}</dd>
          </dl>
          <dl class="box" id="sin">
            <dt>穢れ</dt><dd>@{[input('sin','number','','min="0"')]}</dd>
          </dl>
          <dl class="box" id="birth">
            <dt>生まれ</dt><dd>@{[input('birth')]}</dd>
          </dl>
          <dl class="box" id="faith">
HTML
print '<dt>信仰</dt><dd><select name="faith" oninput="changeFaith(this)">';
print '<option>';
print '<option'.($pc{"faith"} eq 'なし' ? ' selected' : '').'>なし';
foreach my $type (1,3,2,0) {
  print '<optgroup label="'.($type eq 1 ? '第一の剣' : $type eq 3 ? '第三の剣' : $type eq 2 ? '第二の剣' : 'その他').'">';
  foreach my $gods (@data::gods){
    next if $type ne @$gods[0];
    my $name = @$gods[2] ? "“@$gods[2]”@$gods[3]" : @$gods[3];
    print '<option'.(($pc{"faith"} eq $name)?' selected':'').">$name";
  }
  print '</optgroup>';
}
print "</select>".input('faithOther','text','', ' placeholder="自由記入欄"'.($pc{"faith"} eq 'その他の信仰'?'':'style="display:none"'))."</dl>\n";
print <<"HTML";
        </div>

        <div id="status">
          <dl id="stt-base-tec">
            <dt>技</dt>
            <dd>@{[input('sttBaseTec','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-base-phy">
            <dt>体</dt>
            <dd>@{[input('sttBasePhy','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-base-spi">
            <dt>心</dt>
            <dd>@{[input('sttBaseSpi','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-base-A">
            <dt>Ａ</dt>
            <dd>@{[input('sttBaseA','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-base-B">
            <dt>Ｂ</dt>
            <dd>@{[input('sttBaseB','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-base-C">
            <dt>Ｃ</dt>
            <dd>@{[input('sttBaseC','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-base-D">
            <dt>Ｄ</dt>
            <dd>@{[input('sttBaseD','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-base-E">
            <dt>Ｅ</dt>
            <dd>@{[input('sttBaseE','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-base-F">
            <dt>Ｆ</dt>
            <dd>@{[input('sttBaseF','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-grow-A">
            <dt>成長</dt>
            <dd id="stt-grow-A-value">$pc{'sttGrowA'}</dd>
          </dl>
          <dl id="stt-grow-B">
            <dt>成長</dt>
            <dd id="stt-grow-B-value">$pc{'sttGrowB'}</dd>
          </dl>
          <dl id="stt-grow-C">
            <dt>成長</dt>
            <dd id="stt-grow-C-value">$pc{'sttGrowC'}</dd>
          </dl>
          <dl id="stt-grow-D">
            <dt>成長</dt>
            <dd id="stt-grow-D-value">$pc{'sttGrowD'}</dd>
          </dl>
          <dl id="stt-grow-E">
            <dt>成長</dt>
            <dd id="stt-grow-E-value">$pc{'sttGrowE'}</dd>
          </dl>
          <dl id="stt-grow-F">
            <dt>成長</dt>
            <dd id="stt-grow-F-value">$pc{'sttGrowF'}</dd>
          </dl>
          <dl id="stt-dex">
            <dt>器用度</dt>
            <dd id="stt-dex-value">$pc{'sttDex'}</dd>
          </dl>
          <dl id="stt-agi">
            <dt>敏捷度</dt>
            <dd id="stt-agi-value">$pc{'sttAgi'}</dd>
          </dl>
          <dl id="stt-str">
            <dt>筋力</dt>
            <dd id="stt-str-value">$pc{'sttStr'}</dd>
          </dl>
          <dl id="stt-vit">
            <dt>生命力</dt>
            <dd id="stt-vit-value">$pc{'sttVit'}</dd>
          </dl>
          <dl id="stt-int">
            <dt>知力</dt>
            <dd id="stt-int-value">$pc{'sttInt'}</dd>
          </dl>
          <dl id="stt-mnd">
            <dt>精神力</dt>
            <dd id="stt-mnd-value">$pc{'sttMnd'}</dd>
          </dl>
          <dl id="stt-add-A">
            <dt>増強</dt>
            <dd>@{[input('sttAddA','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-add-B">
            <dt>増強</dt>
            <dd>@{[input('sttAddB','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-add-C">
            <dt>増強</dt>
            <dd>@{[input('sttAddC','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-add-D">
            <dt>増強</dt>
            <dd>@{[input('sttAddD','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-add-E">
            <dt>増強</dt>
            <dd>@{[input('sttAddE','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-add-F">
            <dt>増強</dt>
            <dd>@{[input('sttAddF','number','calcStt')]}</dd>
          </dl>
          <dl id="stt-bonus-dex">
            <dt>＋</dt>
            <dd id="stt-bonus-dex-value">$pc{'bonusDex'}</dd>
          </dl>
          <dl id="stt-bonus-agi">
            <dt>＋</dt>
            <dd id="stt-bonus-agi-value">$pc{'bonusAgi'}</dd>
          </dl>
          <dl id="stt-bonus-str">
            <dt>＋</dt>
            <dd id="stt-bonus-str-value">$pc{'bonusStr'}</dd>
          </dl>
          <dl id="stt-bonus-vit">
            <dt>＋</dt>
            <dd id="stt-bonus-vit-value">$pc{'bonusVit'}</dd>
          </dl>
          <dl id="stt-bonus-int">
            <dt>＋</dt>
            <dd id="stt-bonus-int-value">$pc{'bonusInt'}</dd>
          </dl>
          <dl id="stt-bonus-mnd">
            <dt>＋</dt>
            <dd id="stt-bonus-mnd-value">$pc{'bonusMnd'}</dd>
          </dl>
        </div>

        <dl class="box" id="sub-status">
          <dt id="vit-resist">生命抵抗力</dt><dd><span id="vit-resist-base">$pc{'vitResistBase'}</span>+<span id="vit-resist-auto-add">$pc{'vitResistAutoAdd'}</span>+@{[input('vitResistAdd','number','calcSubStt')]}=<b id="vit-resist-total">$pc{'vitResistTotal'}</b></dd>
          <dt id="mnd-resist">精神抵抗力</dt><dd><span id="mnd-resist-base">$pc{'mndResistBase'}</span>+<span id="mnd-resist-auto-add">$pc{'mndResistAutoAdd'}</span>+@{[input('mndResistAdd','number','calcSubStt')]}=<b id="mnd-resist-total">$pc{'mndResistTotal'}</b></dd>
          <dt id="hp">ＨＰ</dt><dd><span id="hp-base">$pc{'hpBase'}</span>+<span id="hp-auto-add">$pc{'hpAutoAdd'}</span>+@{[input('hpAdd','number','calcSubStt')]}=<b id="hp-total">$pc{'hpTotal'}</b></dd>
          <dt id="mp">ＭＰ</dt><dd><span id="mp-base">$pc{'mpBase'}</span>+<span id="mp-auto-add">$pc{'mpAutoAdd'}</span>+@{[input('mpAdd','number','calcSubStt')]}=<b id="mp-total">$pc{'mpTotal'}</b></dd>
        </dl>
        
        <dl class="box" id="level">
          <dt>冒険者レベル</dt><dd id="level-value">$pc{'level'}</dd>
        </dl>
        <dl class="box" id="exp">
          <dt>経験点</dt><dd><div><span id="exp-rest">$pc{'expRest'}</span><br>／<br><span id="exp-total">$pc{'expTotal'}</span></div></dd>
        </dl>
      </div>

      <div id="area-ability">
        <div id="area-classes">
          <div class="box" id="classes">
            <h2>技能</h2>
            <dl>
              <dt>ファイター  </dt><dd>@{[input('lvFig', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>グラップラー</dt><dd>@{[input('lvGra', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>フェンサー  </dt><dd>@{[input('lvFen', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>シューター  </dt><dd>@{[input('lvSho', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>ソーサラー  </dt><dd>@{[input('lvSor', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>コンジャラー</dt><dd>@{[input('lvCon', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>プリースト  </dt><dd>@{[input('lvPri', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>マギテック  </dt><dd>@{[input('lvMag', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>スカウト    </dt><dd>@{[input('lvSco', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>レンジャー  </dt><dd>@{[input('lvRan', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt>セージ      </dt><dd>@{[input('lvSag', 'number','changeLv','min="0" max="17"')]}</dd>
            </dl>
          </div>
          <div class="box" id="common-classes">
            <h2>一般技能</h2>
            <dl>
              <dt>未実装</dt><dd></dd>
            </dl>
          </div>
        </div>

        <div>
          <div class="box" id="combat-feats">
            <h2>戦闘特技</h2>
            <ul>
HTML
foreach my $i (1,3,5,7,9,11,13,15,16,17) {
  print '<li id="combat-feats-lv'.$i.'"><select name="combatFeatsLv'.$i.'" oninput="checkFeats()">';
  print '<option></option>';
  foreach my $type ('常','宣','主') {
    print '<optgroup label="'.($type eq '常' ? '常時' : $type eq '宣' ? '宣言' : '主動作').'特技">';
    foreach my $feats (@data::combat_feats){
      next if $i < @$feats[1];
      next if $type ne @$feats[0];
      print '<option'.(($pc{"combatFeatsLv$i"} eq @$feats[2])?' selected':'').'>'.@$feats[2];
    }
    print '</optgroup>';
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
<!--
          <div class="box" id="mystic-arts">
            <h2>秘伝</h2>
            <ul>
              <li>《》</li>
            </ul>
          </div>
-->
        </div>
        <div>
          <div class="box" id="">
            <h2>練技／呪歌／騎芸／賦術</h2>
            <ul>
              <li>ルールブックⅡ以降で実装</li>
            </ul>
          </div>
        </div>
      </div>

      <div id="area-actions">
        <div id="area-package">
          <div class="box" id="package">
            <h2>判定パッケージ</h2>
            <table id="package-scout"@{[ display $pc{'lvSco'} ]}>
              <tr>
                <th rowspan="3">スカウト技能</th>
                <th>技巧</th>
                <td id="package-scout-tec">$pc{'packScoutTec'}</td>
              </tr>
              <tr>
                <th>運動</th>
                <td id="package-scout-agi">$pc{'packScoutAgi'}</td>
              </tr>
              <tr>
                <th>観察</th>
                <td id="package-scout-int">$pc{'packScoutInt'}</td>
              </tr>
            </table>
            <table id="package-ranger"@{[ display $pc{'lvRan'} ]}>
              <tr>
                <th rowspan="3">レンジャー技能</th>
                <th>技巧</th>
                <td id="package-ranger-tec">$pc{'packRangerTec'}</td>
              </tr>
              <tr>
                <th>運動</th>
                <td id="package-ranger-agi">$pc{'packRangerAgi'}</td>
              </tr>
              <tr>
                <th>観察</th>
                <td id="package-ranger-int">$pc{'packRangerInt'}</td>
              </tr>
            </table>
            <table id="package-sage"@{[ display $pc{'lvSag'} ]}>
              <tr>
                <th>セージ技能レベル</th>
                <th>知識</th>
                <td id="package-sage-int">$pc{'packSageInt'}</td>
              </tr>
            </table>
          </div>
        </div>
        <div id="area-other-actions">
          <dl class="box" id="monster-lore">
            <dt>魔物知識</dt>
            <dd id="monster-lore-value">$pc{'monsterLore'}</dd>
          </dl>
          <dl class="box" id="initiative">
            <dt>先制力</dt>
            <dd id="initiative-value">$pc{'initiative'}</dd>
          </dl>
          <dl class="box" id="mobility">
            <dt>制限移動</dt><dd><b id="mobility-limited">$pc{'mobilityLimited'}</b> m</dd>
            <dt>移動力</dt><dd><span id="mobility-base">$pc{'mobilityBase'}</span>+@{[input('mobilityAdd','number','calcMobility')]}=<b id="mobility-total">0</b> m</dd>
            <dt>全力移動</dt><dd><b id="mobility-full">$pc{'mobilityFull'}</b> m</dd>
          </dl>
          <div class="box" id="magic-power">
            <h2>魔力</h2>
            <p>+@{[input('magicPowerAdd','number','calcMagic')]}</p>
            <table>
              <tr@{[ display $pc{'lvSor'} ]} id="magic-power-sorcerer"><th>ソーサラー  </th><th>真語魔法</th><td id="magic-power-sorcerer-value">0</td></tr>
              <tr@{[ display $pc{'lvCon'} ]} id="magic-power-conjurer"><th>コンジャラー</th><th>操霊魔法</th><td id="magic-power-conjurer-value">0</td></tr>
              <tr@{[ display $pc{'lvPri'} ]} id="magic-power-priest"  ><th>プリースト  </th><th>神聖魔法</th><td id="magic-power-priest-value"  >0</td></tr>
              <tr@{[ display $pc{'lvMag'} ]} id="magic-power-magitech"><th>マギテック  </th><th>魔動機術</th><td id="magic-power-magitech-value">0</td></tr>
            </table>
          </div>
        </div>
        <div class="box" id="language">
          <h2>言語</h2>
          <table>
            <tr><th></th><th>会話</th><th>読文</th></tr>
          </table>
          <dl id="language-default">
HTML
foreach (@{$data::race_language{ $pc{'race'} }}){
  print '<dt>'.@$_[0].'</dt><dd>'.(@$_[1] ? '○' : '－').'</dd><dd>'.(@$_[2] ? '○' : '－').'</dd>';
}
print <<"HTML";
          </dl>
          <table id="language-table">
HTML
foreach my $i (1 .. $pc{'languageNum'}){
  print '<tr><td>'.input('language'.$i).'</td>'.
  '<td><input type="checkbox" name="language'.$i.'Talk" value="1"'.($pc{"language${i}Talk"} ? 'checked' :'').'></td>'.
  '<td><input type="checkbox" name="language'.$i.'Read" value="1"'.($pc{"language${i}Read"} ? 'checked' :'').'></td>'.
  '</tr>'."\n";
}
print <<"HTML";
          </table>
          <div class="add-del-button"><a onclick="addLanguage()">▼</a><a onclick="delLanguage()">▲</a></div>
          @{[input('languageNum','hidden')]}
        </div>
      </div>
      
      <div id="area-equipment">
        <div class="box" id="attack-classes">
          <table>
            <tr>
              <th>技能・特技</th>
              <th>必筋<br>上限</th>
              <th>命中力</th>
              <th></th>
              <th>Ｃ値</th>
              <th>追加Ｄ</th>
            </tr>
            <tr id="attack-fighter"@{[ display $pc{'lvFig'} ]}>
              <td>ファイター技能</td>
              <td id="attack-fighter-str">0</td>
              <td id="attack-fighter-acc">0</td>
              <td>―</td>
              <td>―</td>
              <td id="attack-fighter-dmg">―</td>
            </tr>
            <tr id="attack-grappler"@{[ display $pc{'lvGra'} ]}>
              <td>グラップラー技能</td>
              <td id="attack-grappler-str">0</td>
              <td id="attack-grappler-acc">0</td>
              <td>―</td>
              <td>―</td>
              <td id="attack-grappler-dmg">0</td>
            </tr>
            <tr id="attack-fencer"@{[ display $pc{'lvFen'} ]}>
              <td>フェンサー技能</td>
              <td id="attack-fencer-str">0</td>
              <td id="attack-fencer-acc">0</td>
              <td>―</td>
              <td>-1</td>
              <td id="attack-fencer-dmg">0</td>
            </tr>
            <tr id="attack-shooter"@{[ display $pc{'lvSho'} ]}>
              <td>シューター技能</td>
              <td id="attack-shooter-str">0</td>
              <td id="attack-shooter-acc">0</td>
              <td>―</td>
              <td>―</td>
              <td id="attack-shooter-dmg">0</td>
            </tr>
HTML
foreach my $weapon (@data::weapons){
print <<"HTML";
            <tr id="attack-@$weapon[1]-mastery"@{[ display $pc{'mastery'.ucfirst(@$weapon[1])} ]}>
              <td>《武器習熟／@$weapon[0]》</td>
              <td>―</td>
              <td>―</td>
              <td>―</td>
              <td>―</td>
              <td id="attack-@$weapon[1]-mastery-damage">$pc{'mastery'.ucfirst(@$weapon[1])}</td>
            </tr>
HTML
}
if(0){
print <<"HTML";
            <tr id="accuracy-enhance"@{[ display $pc{'accuracyEnhance'} ]}>
              <td>《命中強化》</td>
              <td>―</td>
              <td>―</td>
              <td>―</td>
              <td>―</td>
              <td id="accuracyEnhance">$pc{'accuracyEnhance'}</td>
            </tr>
HTML
}
print <<"HTML";
          </table>
        </div>
        <div class="box" id="weapons">
          <table id="weapons-table">
            <tr>
              <th>武器</th>
              <th>用法</th>
              <th>必筋</th>
              <th>命中力</th>
              <th>威力</th>
              <th>Ｃ値</th>
              <th>追加Ｄ</th>
              <th>専用</th>
              <th>カテゴリ</th>
              <th>使用技能</th>
            </tr>
HTML

foreach my $i (1 .. $pc{'weaponNum'}) {
print <<"HTML";
            <tr>
              <td>@{[input("weapon${i}Name")]}</td>
              <td>@{[input("weapon${i}Usage","text",'','list="list-usage"')]}</td>
              <td>@{[input("weapon${i}Reqd")]}</td>
              <td>+@{[input("weapon${i}Acc",'number','calcWeapon')]}=<b id="weapon${i}-acc-total">0</b></td>
              <td>@{[input("weapon${i}Rate")]}</td>
              <td>@{[input("weapon${i}Crit")]}</td>
              <td>+@{[input("weapon${i}Dmg",'number','calcWeapon')]}=<b id="weapon${i}-dmg-total">0</b></td>
              <td>@{[input("weapon${i}Own",'checkbox','calcWeapon', 'disabled')]}</td>
              <td><select name="weapon${i}Category" oninput="calcWeapon()">@{[option("weapon${i}Category",@data::weapon_names)]}</select></td>
              <td><select name="weapon${i}Class" oninput="calcWeapon()">@{[option("weapon${i}Class",'ファイター','グラップラー','フェンサー','シューター')]}</select></td>
              <td>@{[input("weapon${i}Note",'','','placeholder="備考"')]}</td>
            </tr>
HTML
}
print <<"HTML";
          </table>
          <div class="annotate">
            ※Ｃ値は自動計算されません。
          </div>
          <div class="add-del-button"><a onclick="addWeapons()">▼</a><a onclick="delWeapons()">▲</a></div>
          @{[input('weaponNum','hidden')]}
        </div>
        <div class="box" id="evasion-classes">
          <table>
            <tr>
              <th>技能・特技</th>
              <th>必筋<br>上限</th>
              <th>回避力</th>
              <th>防護点</th>
            </tr>
            <tr>
              <td><select id="evasion-class" name="evasionClass" oninput="calcDefense()">@{[option('evasionClass','ファイター','グラップラー','フェンサー','シューター')]}</select></td>
              <td id="evasion-str">$pc{'EvasionStr'}</td>
              <td id="evasion-eva">$pc{'EvasionEva'}</td>
              <td>―</td>
            </tr>
            <tr id="race-ability-def"@{[ display $pc{'raceAbilityDef'} ]}>
              <td id="race-ability-def-name">［@{[ $pc{'race'} eq 'リルドラケン' ? '鱗の皮膚':$pc{'race'} eq 'フロウライト'?'晶石の身体':$pc{'race'} eq 'ダークトロール'?'トロールの体躯':'']}］</td>
              <td>―</td>
              <td>―</td>
              <td id="race-ability-def-value">$pc{'raceAbilityDef'}</td>
            </tr>
            <tr id="mastery-metalarmour"@{[ display $pc{'masteryMetalArmour'} ]}>
              <td>《防具習熟／金属鎧》</td>
              <td>―</td>
              <td>―</td>
              <td id="mastery-metalarmour-value">$pc{'masteryMetalArmour'}</td>
            </tr>
            <tr id="mastery-nonmetalarmour"@{[ display $pc{'masteryNonMetalArmour'} ]}>
              <td>《防具習熟／非金属鎧》</td>
              <td>―</td>
              <td>―</td>
              <td id="mastery-nonmetalarmour-value">$pc{'masteryNonMetalArmour'}</td>
            </tr>
            <tr id="mastery-shield"@{[ display $pc{'masteryShield'} ]}>
              <td>《防具習熟／盾》</td>
              <td>―</td>
              <td>―</td>
              <td id="mastery-shield-value">$pc{'masteryShield'}</td>
            </tr>
            <tr id="evasive-maneuver"@{[ display $pc{'evasiveManeuver'} ]}>
              <td>《回避行動》</td>
              <td>―</td>
              <td id="evasive-maneuver-value">$pc{'evasiveManeuver'}</td>
              <td>―</td>
            </tr>
          </table>
        </div>
        <div class="box" id="armours">
          <table>
            <tr>
              <th></th>
              <th>防具</th>
              <th>必筋</th>
              <th>回避力</th>
              <th>防護点</th>
              <th>専用</th>
              <th>備考</th>
            </tr>
            <tr>
              <th>鎧</th>
              <td>@{[input('armourName')]}</td>
              <td>@{[input('armourReqd')]}</td>
              <td>@{[input('armourEva','number','calcDefense')]}</td>
              <td>@{[input('armourDef','number','calcDefense')]}</td>
              <td><input type="checkbox" name="armourOwn" disabled></td>
              <td>@{[input('armourNote')]}</td>
            </tr>
            <tr>
              <th>盾</th>
              <td>@{[input('shieldName')]}</td>
              <td>@{[input('shieldReqd')]}</td>
              <td>@{[input('shieldEva','number','calcDefense')]}</td>
              <td>@{[input('shieldDef','number','calcDefense')]}</td>
              <td><input type="checkbox" name="shieldOwn" disabled></td>
              <td>@{[input('shieldNote')]}</td>
            </tr>
            <tr>
              <th>他</th>
              <td>@{[input('defOtherName')]}</td>
              <td>@{[input('defOtherReqd')]}</td>
              <td>@{[input('defOtherEva','number','calcDefense')]}</td>
              <td>@{[input('defOtherDef','number','calcDefense')]}</td>
              <td><input type="checkbox" name="defOtherOwn" disabled></td>
              <td>@{[input('defOtherNote')]}</td>
            </tr>
            <tr class="defense-total">
              <th colspan="3">合計：すべて</th>
              <td id="defense-total-all-eva">0</td>
              <td id="defense-total-all-def">0</td>
            </tr>
          </table>
        </div>
        <div class="box" id="accessories">
          <table>
            <tr>
              <th></th>
              <th></th>
              <th>装飾品</th>
              <th>専用</th>
              <th>効果</th>
            </tr>
HTML
foreach (
  ["頭","Head"],    ["┗","Head_"],
  ["耳","Ear"],     ["┗","Ear_"],
  ["顔","Face"],    ["┗","Face_"],
  ["首","Neck"],    ["┗","Neck_"],
  ["背中","Back"],  ["┗","Back_"],
  ["右手","HandR"], ["┗","HandR_"],
  ["左手","HandL"], ["┗","HandL_"],
  ["腰","Waist"],   ["┗","Waist_"],
  ["足","Leg"],     ["┗","Leg_"],
  ["他","Other"],   ["┗","Other_"],
  ["他2","Other2"], ["┗","Other2_"],
  ["他3","Other3"], ["┗","Other3_"],
  ["他4","Other4"], ["┗","Other4_"]
) {
  my $flag;
  my $addbase = @$_[1];
     $addbase =~ s/@$_[1]//;
  if   (@$_[0] eq '他2' &&  $pc{'race'} ne 'レプラカーン')                     { $flag = 0; }
  elsif(@$_[0] eq '他3' && ($pc{'race'} ne 'レプラカーン' || $pc{'level'} < 6)){ $flag = 0; }
  elsif(@$_[0] eq '他4' && ($pc{'race'} ne 'レプラカーン' || $pc{'level'} <16)){ $flag = 0; }
  elsif(@$_[0] =~ /┗/  && !$pc{'accessory'.$addbase.'Add'}){ $flag = 0; }
  else { $flag = 1; }
  print '  <tr id="accessory-' . @$_[1] . '"' . display($flag) . ">\n";
  print '  <td>';
  if (@$_[0] !~ /┗/) {
    print "  <input type=\"checkbox\" id=\"accessory-@$_[1]-add-check\"" .
          " name=\"accessory@$_[1]Add\" value=\"1\"" .
          ($pc{"accessory@$_[1]Add"}?' checked' : '') .
          " onChange=\"addAccessory(this,'@$_[1]')\" disabled>";
  }
  print "</td>\n";
  print <<"HTML";
  <th>@$_[0]</th>
  <td>@{[input('accessory'.@$_[1].'Name')]}</td>
  <td>
    <select id="accessory-@$_[1]" name="accessory@$_[1]Own" oninput="" disabled>
      <option></option>
      <option value="HP" @{[ $pc{"accessory@$_[1]Own"} eq 'HP' ? 'selected':'']}>HP</option>
      <option value="MP" @{[ $pc{"accessory@$_[1]Own"} eq 'MP' ? 'selected':'' ]}>MP</option>
    </select>
  </td>
  <td>@{[input('accessory'.@$_[1].'Note')]}</td>
  </tr>
HTML
}
print <<"HTML";
          </table>
        </div>
      </div>
      <div id="area-items">
        <div id="area-items-L">
          <dl class="box" id="money">
            <dt>所持金</dt><dd>@{[ input 'money' ]} G</dd>
            <dt>預金／借金</dt><dd>@{[ input 'deposit' ]} G</dd>
          </dl>
          <div class="box" id="items">
            <h2>所持品</h2>
            <textarea name="items">$pc{'items'}</textarea>
          </div>
        </div>
        <div id="area-items-R">
          <div class="box">
            <h2>名誉点</h2>
            <p>　ルールブックⅡで実装</p>
          </div>
          <div class="box" id="honor-items">
            <table id="honorItems">
              <h2>名誉アイテム</h2>
              <tr><th></th><th>　</th></tr>
              <tr><td>　ルールブックⅡで実装</td><td></td></tr>
            </table>
          </div>
        </div>
      </div>
      <div class="box" id="cashbook">
        <h2>収支履歴</h2>
        <textarea name="cashbook" oninput="calcCash();" placeholder="例）冒険者セット  ::-100&#13;&#10;　　剣のかけら売却::+200">$pc{'cashbook'}</textarea>
        <p>
          所持金：<span id="cashbook-total-value">$pc{'moneyTotal'}</span> G
          　預金：<span id="cashbook-deposit-value">－</span> G
          　借金：<span id="cashbook-debt-value">－</span> G
        </p>
        <div class="annotate">
          ※<code>::+n</code> <code>::-n</code>の書式で入力すると加算・減算されます。（<code>n</code>には金額を入れてください）<br>
          　預金は<code>:>+n</code>、借金は<code>:<+n</code>で増減できます。（それに応じて所持金も増減します）<br>
          ※<span class="underline">セッション履歴に記入されたガメル報酬は自動的に加算されます。</span><br>
          ※所持金欄、預金／借金欄に<code>自動</code>または<code>auto</code>と記入すると、収支の計算結果を反映します。
        </div>
      </div>
      <div class="box" id="free-note">
        <h2>容姿・経歴・その他メモ</h2>
        <textarea name="freeNote">$pc{'freeNote'}</textarea>
        <h4 onclick="view('text-format')">テキスト装飾・整形ルール▼</h4>
        <div class="annotate" id="text-format" style="display:none;">
        ※メモ欄以外でも有効です。<br>
        太字　：<code>''テキスト''</code>：<b>テキスト</b><br>
        斜体　：<code>'''テキスト'''</code>：<span class="oblique">テキスト</span><br>
        打消線：<code>%%テキスト%%</code>：<span class="strike">テキスト</span><br>
        下線　：<code>__テキスト__</code>：<span class="underline">テキスト</span><br>
        ルビ　：<code>|テキスト《てきすと》</code>：<ruby>テキスト<rt>てきすと</rt></ruby><br>
        傍点　：<code>《《テキスト》》</code>：<span class="text-em">テキスト</span><br>
        <hr>
        ※以下は複数行の欄でのみ有効です。<br>
        大見出し：行頭に<code>*</code><br>
        中見出し：行頭に<code>**</code><br>
        少見出し：行頭に<code>***</code><br>
        左寄せ　：行頭に<code>LEFT:</code>：以降のテキストがすべて左寄せになります。<br>
        中央寄せ：行頭に<code>CENTER:</code>：以降のテキストがすべて中央寄せになります。<br>
        右寄せ　：行頭に<code>RIGHT:</code>：以降のテキストがすべて右寄せになります。<br>
        横罫線（直線）：<code>----</code>（4つ以上のハイフン）<br>
        横罫線（点線）：<code> * * * *</code>（4つ以上の「スペース＋アスタリスク」）<br>
        横罫線（破線）：<code> - - - -</code>（4つ以上の「スペース＋ハイフン」）<br>
        </div>
      </div>
      <div class="box" id="history">
        <h2>セッション履歴</h2>
        <table id="history-table">
          <tr>
            <th>No.</th>
            <th>日付</th>
            <th>タイトル</th>
            <th>経験点</th>
            <th>名誉点</th>
            <th>ガメル</th>
            <th>成長</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
HTML
if(1){
print <<"HTML";
          <tr>
            <td>-</td>
            <td></td>
            <td>キャラクター作成</td>
            <td id="history0-exp">$pc{'history0Exp'}</td>
            <td id="history0-honor">$pc{'history0Honor'}</td>
            <td id="history0-money">$pc{'history0Money'}</td>
            <td id="history0-grow">$pc{'history0Grow'}</td>
          </tr>
HTML
}
foreach my $i (1 .. $pc{'historyNum'}) {
print <<"HTML";
          <tr>
            <td>$i</td>
            <td>@{[input("history${i}Date")]}</td>
            <td>@{[input("history${i}Title")]}</td>
            <td>@{[input("history${i}Exp",'text','calcExp')]}</td>
            <td>@{[input("history${i}Honor")]}</td>
            <td>@{[input("history${i}Money",'text','calcCash')]}</td>
            <td>@{[input("history${i}Grow",'text','','list="list-grow"')]}</td>
            <td>@{[input("history${i}Gm")]}</td>
            <td>@{[input("history${i}Member")]}</td>
          </tr>
HTML
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addHistory()">▼</a><a onclick="delHistory()">▲</a></div>
        <table class="example">
          <tr>
            <th>No.</th>
            <th>日付</th>
            <th>タイトル</th>
            <th>経験点</th>
            <th>名誉点</th>
            <th>ガメル</th>
            <th>成長</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
        <tr>
          <td>-</td>
          <td>2018-08-11</td>
          <td>第一話「記入例」</td>
          <td>1100+50</td>
          <td>17</td>
          <td>1800</td>
          <td>器用</td>
          <td>サンプルさん</td>
          <td>ウィリアム　メネルドール<br>ヴィンダールヴ　レイストフ</td>
        </tr>
        </table>
        <div class="annotate">
        ※経験点欄は<code>1000+50*2</code>など四則演算が有効です（ファンブル経験点などを分けて書けます）。<br>
        ※成長は欄1つの欄に<code>敏捷生命知力</code>など複数書いても自動計算されます。<br>
        　また、<code>敏捷×2</code><code>知力*3</code>など同じ成長が複数ある場合は纏めて記述できます（×や*は省略できます）。<br>
        　<code>器敏2知3</code>と能力値の頭文字1つで記述することもできます。<br>
        ※成長はリアルタイムでの自動計算はされません。反映するには一度保存してください。
        </div>
        @{[input('historyNum','hidden')]}
      </div>
      
      <hr>
      
      <h2>フェロー関連データ</h2>
      <div class="box" id="f-public">
        @{[ input 'fellowPublic', 'checkbox']} フェローを公開する
      </div>
      <div class="box" id="f-checkboxes">
        <dl><dt>経験点</dt>
          <dd><input type="radio" name="fellowExpCheck" value="1" @{[ $pc{'fellowExpCheck'}?'checked':'' ]}>あり</dd>
          <dd><input type="radio" name="fellowExpCheck" value="0" @{[ $pc{'fellowExpCheck'}?'':'checked' ]}>なし</dd>
        </dl>
        <dl><dt>報酬</dt>
          <dd><input type="radio" name="fellowRewardCheck" value="1" @{[ $pc{'fellowRewardCheck'}?'checked':'' ]}>要望</dd>
          <dd><input type="radio" name="fellowRewardCheck" value="0" @{[ $pc{'fellowRewardCheck'}?'':'checked' ]}>不要</dd>
        </dl>
      </div>
      <div class="box" id="f-profile">
        <h2>自己紹介</h2>
        <textarea name="fellowProfile">$pc{'fellowProfile'}</textarea>
      </div>
      <div class="box" id="f-actions">
        <h2>行動表</h2>
      <table>
        <tr>
          <th>1d</th>
          <th>想定<br>出目</th>
          <th>行動</th>
          <th>台詞</th>
          <th>達成値</th>
          <th>効果</th>
        </tr>
        <tr>
          <td>⚀⚁</td>
          <td>7</td>
          <td>@{[ input 'fellow1Action' ]}</td>
          <td>@{[ input 'fellow1Words' ]}</td>
          <td>@{[ input 'fellow1Num' ]}</td>
          <td>@{[ input 'fellow1Note' ]}</td>
        </tr>
        <tr>
          <td>⚂⚃</td>
          <td>8</td>
          <td>@{[ input 'fellow3Action' ]}</td>
          <td>@{[ input 'fellow3Words' ]}</td>
          <td>@{[ input 'fellow3Num' ]}</td>
          <td>@{[ input 'fellow3Note' ]}</td>
        </tr>
        <tr>
          <td>⚄</td>
          <td>9</td>
          <td>@{[ input 'fellow5Action' ]}</td>
          <td>@{[ input 'fellow5Words' ]}</td>
          <td>@{[ input 'fellow5Num' ]}</td>
          <td>@{[ input 'fellow5Note' ]}</td>
        </tr>
        <tr>
          <td>⚅</td>
          <td>10</td>
          <td>@{[ input 'fellow6Action' ]}</td>
          <td>@{[ input 'fellow6Words' ]}</td>
          <td>@{[ input 'fellow6Num' ]}</td>
          <td>@{[ input 'fellow6Note' ]}</td>
        </tr>
      </table>
      </div>
      <div class="box" id="f-note">
        <h2>備考</h2>
        <textarea name="fellowNote">$pc{'fellowNote'}</textarea>
      </div>
      
      @{[ input 'birthTime','hidden' ]}
      @{[ input 'id','hidden' ]}
    </form>
HTML
if($mode eq 'edit'){
print <<"HTML";
    <form name="del" method="post" action="./" id="deleteform">
      <p>
      <input type="hidden" name="mode" value="delete">
      <input type="hidden" name="id" value="$id">
      <input type="hidden" name="pass" value="$pass">
      <input type="checkbox" name="check1" value="1" required>
      <input type="checkbox" name="check2" value="1" required>
      <input type="checkbox" name="check3" value="1" required>
      <input type="submit" value="シート削除">
      </p>
    </form>
HTML
}
print <<"HTML";
    </article>
  </main>
  <footer>
    『ソード・ワールド2.5』は、「グループSNE」及び「KADOKAWA」の著作物です。<br>
    　ゆとシートⅡ for SW2.5 ver.${main::ver} - ゆとらいず工房
  </footer>
  <datalist id="list-usage">
    <option value="1H">
    <option value="1H#">
    <option value="1H投">
    <option value="1H拳">
    <option value="1H両">
    <option value="2H">
    <option value="2H#">
    <option value="振2H">
    <option value="突2H">
  </datalist>
  <datalist id="list-grow">
    <option value="器用">
    <option value="敏捷">
    <option value="筋力">
    <option value="生命">
    <option value="知力">
    <option value="精神">
  </datalist>
  <script>
HTML
foreach (
  'sttHistGrowA',
  'sttHistGrowB',
  'sttHistGrowC',
  'sttHistGrowD',
  'sttHistGrowE',
  'sttHistGrowF',
  'raceAbilityDef',
  'raceAbilityMp',
  'raceAbilityMndResist',
  'accuracyEnhance',
  'evasiveManeuver',
  'shootersMartialArts',
  'tenacity',
  'capacity',
  'masteryMetalArmour',
  'masteryNonMetalArmour',
  'masteryShield'
) {
  print "let $_ = ". ($pc{$_} ? $pc{$_} : 0) . ";\n";
}
foreach (@data::weapons){
  print 'let mastery'.ucfirst(@$_[1]).' = '. 
  ($pc{'mastery'.ucfirst(@$_[1])} ? $pc{'mastery'.ucfirst(@$_[1])} : 0 ). 
  ";\n";
}
print 'let weapons = [';
foreach (@data::weapons){
  print "'".@$_[0]."',";
}
print '];';
print 'let raceAbility = {';
foreach my $key ( keys(%data::race_ability) ){
  print "\"$key\" : \"$data::race_ability{$key}\",";
}
print '};';
print 'let raceLanguage = {';
foreach my $key ( keys(%data::race_language) ){
  print "\"$key\" : \"";
  foreach (@{$data::race_language{$key}}){
    print "<dt>@$_[0]</dt><dd>".(@$_[1]?'○':'－')."</dd><dd>".(@$_[2]?'○':'－')."</dd>";
  }
  print "\",";
}
print '};';
print <<"HTML";
  </script>
  <script src="./lib/edit.js?201808181800" ></script>
</body>

</html>
HTML

1;