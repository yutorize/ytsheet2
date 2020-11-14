############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';
use Encode;

require $set::lib_palette_sub;

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
if($mode eq 'blanksheet' || $mode eq 'copy' || $mode eq 'convert'){
  $token = token_make();
}
## 更新後処理 --------------------------------------------------
if($mode eq 'save'){
  $message .= 'データを更新しました。<a href="./?id='.param('id').'">⇒シートを確認する</a>';
  $mode = 'edit';
}

### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_class;
require $set::data_feats;
require $set::data_races;
require $set::data_items;
require $set::data_faith;

### データ読み込み ###################################################################################
my $id;
my $pass;
my $file;
### 編集時 --------------------------------------------------
if($mode eq 'blanksheet' && param('stt')){
  ($pc{'sttBaseTec'}, $pc{'sttBasePhy'}, $pc{'sttBaseSpi'}, $pc{'sttBaseA'}, $pc{'sttBaseB'}, $pc{'sttBaseC'}, $pc{'sttBaseD'}, $pc{'sttBaseE'}, $pc{'sttBaseF'}) = split(/_/, param('stt'));
  $pc{'race'} = Encode::decode('utf8', param('race'));
  $pc{'race'} = 'ナイトメア（人間）' if $pc{'race'} eq 'ナイトメア';
  $pc{'race'} = 'ウィークリング（ガルーダ）' if $pc{'race'} eq 'ウィークリング';
}
if($mode eq 'edit'){
  $id = param('id');
  $pass = param('pass');
  (undef, undef, $file, undef) = getfile($id,$pass,$LOGIN_ID);
  open my $IN, '<', "${set::char_dir}${file}/data.cgi" or &login_error;
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
}
elsif($mode eq 'copy'){
  $id = param('id');
  $file = (getfile_open($id))[0];
  open my $IN, '<', "${set::char_dir}${file}/data.cgi" or error 'キャラクターシートがありません。';
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
  
  delete $pc{'image'};  
  
  $message = '「<a href="./?id='.$id.'" target="_blank">'.$pc{"characterName"}.'</a>」をコピーして新規作成します。<br>（まだ保存はされていません）';
}
elsif($mode eq 'convert'){
  require $set::lib_convert;
  %pc = data_convert(param('url'));
  $message = '「<a href="'.param('url').'" target="_blank">'.($pc{"characterName"}||$pc{"aka"}||'無題').'</a>」をコンバートして新規作成します。<br>（まだ保存はされていません）';
}

### プレイヤー名 --------------------------------------------------
if($mode eq 'blanksheet' || $mode eq 'copy' || $mode eq 'convert'){
  $pc{'playerName'} = (getplayername($LOGIN_ID))[0] if !$main::make_error;
}

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

$pc{'weaponNum'}     = $pc{'weaponNum'}     || 1;
$pc{'languageNum'}   = $pc{'languageNum'}   || 3;
$pc{'honorItemsNum'} = $pc{'honorItemsNum'} || 3;
$pc{'historyNum'}    = $pc{'historyNum'}    || 3;

$pc{'imageFit'} = $pc{'imageFit'} eq 'percent' ? 'percentX' : $pc{'imageFit'};
$pc{'imagePercent'} = $pc{'imagePercent'} eq '' ? '200' : $pc{'imagePercent'};
$pc{'imagePositionX'} = $pc{'imagePositionX'} eq '' ? '50' : $pc{'imagePositionX'};
$pc{'imagePositionY'} = $pc{'imagePositionY'} eq '' ? '50' : $pc{'imagePositionY'};

$pc{'colorHeadBgH'} = $pc{'colorHeadBgH'} eq '' ? 225 : $pc{'colorHeadBgH'};
$pc{'colorHeadBgS'} = $pc{'colorHeadBgS'} eq '' ?   9 : $pc{'colorHeadBgS'};
$pc{'colorHeadBgL'} = $pc{'colorHeadBgL'} eq '' ?  65 : $pc{'colorHeadBgL'};
$pc{'colorBaseBgH'} = $pc{'colorBaseBgH'} eq '' ? 210 : $pc{'colorBaseBgH'};
$pc{'colorBaseBgS'} = $pc{'colorBaseBgS'} eq '' ?   0 : $pc{'colorBaseBgS'};
$pc{'colorBaseBgL'} = $pc{'colorBaseBgL'} eq '' ? 100 : $pc{'colorBaseBgL'};

if($pc{'colorCustom'} && $pc{'colorHeadBgA'}) {
  ($pc{'colorHeadBgH'}, $pc{'colorHeadBgS'}, $pc{'colorHeadBgL'}) = rgb_to_hsl($pc{'colorHeadBgR'},$pc{'colorHeadBgG'},$pc{'colorHeadBgB'});
  ($pc{'colorBaseBgH'}, $pc{'colorBaseBgS'}, undef) = rgb_to_hsl($pc{'colorBaseBgR'},$pc{'colorBaseBgG'},$pc{'colorBaseBgB'});
  $pc{'colorBaseBgS'} = $pc{'colorBaseBgS'} * $pc{'colorBaseBgA'} * 10;
}

### アップデート --------------------------------------------------
if($pc{'ver'} < 1.10){
  $pc{'fairyContractEarth'} = 1 if $pc{'ftElemental'} =~ /土|地/;
  $pc{'fairyContractWater'} = 1 if $pc{'ftElemental'} =~ /水|氷/;
  $pc{'fairyContractFire' } = 1 if $pc{'ftElemental'} =~ /火|炎/;
  $pc{'fairyContractWind' } = 1 if $pc{'ftElemental'} =~ /風|空/;
  $pc{'fairyContractLight'} = 1 if $pc{'ftElemental'} =~ /光/;
  $pc{'fairyContractDark' } = 1 if $pc{'ftElemental'} =~ /闇/;
}

### 改行処理 --------------------------------------------------
$pc{'items'}         =~ s/&lt;br&gt;/\n/g;
$pc{'freeNote'}      =~ s/&lt;br&gt;/\n/g;
$pc{'freeHistory'}   =~ s/&lt;br&gt;/\n/g;
$pc{'cashbook'}      =~ s/&lt;br&gt;/\n/g;
$pc{'fellowProfile'} =~ s/&lt;br&gt;/\n/g;
$pc{'fellowNote'}    =~ s/&lt;br&gt;/\n/g;
$pc{'chatPalette'}   =~ s/&lt;br&gt;/\n/g;

### フォーム表示 #####################################################################################
my $titlebarname = tag_delete name_plain tag_unescape $pc{'characterName'} if $pc{'characterName'};
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>@{[$mode eq 'edit'?"編集：$titlebarname" : '新規作成']} - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/base.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/sheet.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/lib/sw2/edit-chara.js?${main::ver}" defer></script>
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.3.1/css/all.css" integrity="sha384-mzrmE5qonljUremFsqc01SB46JvROS7bZs3IO2EmfFsd15uHvIt+Y8vEf7N7fWAU" crossorigin="anonymous">
  <style>
    #image,
    .image-custom-view {
      background-image: url("${set::char_dir}${file}/image.$pc{'image'}?$pc{'imageUpdate'}");
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
      <aside class="message">$message</aside>
      <form name="sheet" method="post" action="./" enctype="multipart/form-data">
HTML
if($mode eq 'blanksheet' || $mode eq 'copy' || $mode eq 'convert'){
  print '<input type="hidden" name="_token" value="'.$token.'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      <div id="area-name">
        <div id="character-name">
          <div>キャラクター名@{[input('characterName','text','','required')]}</div>
          <div>二つ名　　　　@{[input('aka','text','','placeholder="漢字:ルビ　（※「:」は半角）"')]}</div>
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
        <ul id="header-menu">
          <li onclick="sectionSelect('common');">キャラクターデータ</li>
          <li onclick="sectionSelect('fellow');">フェローデータ</li>
          <li onclick="sectionSelect('palette');">チャットパレット</li>
          <li onclick="sectionSelect('color');">カラーカスタム</li>
        </ul>
      </div>
HTML
if($set::user_reqd){
  print <<"HTML";
    <input type="hidden" name="protect" value="account">
    <input type="hidden" name="protectOld" value="$pc{'protect'}">
    <input type="hidden" name="pass" value="$pass">
HTML
}
else {
  if($set::registerkey && ($mode eq 'blanksheet' || $mode eq 'copy' || $mode eq 'convert')){
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
    print '<input type="hidden" name="pass" value="'.$pass.'"><br>';
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
      <section id="section-common">
      <div id="hide-options">
        <p id="hide-checkbox">
        @{[ input 'hide','checkbox' ]} 一覧に表示しない<br>
        ※タグ検索結果に合致した場合は表示されます
        </p>
      </div>
      <div class="box" id="group">
        <dl>
          <dt>グループ</dt><dd><select name="group">
HTML
foreach (@set::groups){
  my $id   = @$_[0];
  my $name = @$_[2];
  my $exclusive = @$_[4];
  next if($exclusive && (!$LOGIN_ID || $LOGIN_ID !~ /^($exclusive)$/));
  print '<option value="'.$id.'"'.($pc{'group'} eq $id ? ' selected': '').'>'.$name.'</option>';
}
print <<"HTML";
          </select></dd>
          <dt>タグ</dt><dd>@{[ input 'tags','','','' ]}</dd>
        </dl>
      </div>
      <details class="box" id="regulation" @{[$mode eq 'edit' ? '':'open']}>
        <summary>作成レギュレーション</summary>
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
      </details>
      <div id="area-status">
        @{[ image_form ]}

        <div id="personal">
          <dl class="box" id="race">
            <dt>種族</dt><dd><select name="race" oninput="changeRace()">@{[ option 'race', @data::race_names ]}</select></dd>
          </dl>
          <dl class="box" id="gender">
            <dt>性別</dt><dd>@{[input('gender','','','list="list-gender"')]}</dd>
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
    my $name = @$gods[2] && @$gods[3] ? "“@$gods[2]”@$gods[3]" : @$gods[2] ? "“@$gods[2]”" : @$gods[3];
    print '<option'.(($pc{"faith"} eq $name)?' selected':'').">$name";
  }
  print '</optgroup>';
}
print "</select>".input('faithOther','text','', ' placeholder="自由記入欄"'.($pc{"faith"} eq 'その他の信仰'?'':'style="display:none"'))."</dl>\n";
print <<"HTML";
        </div>

        <div id="status">
          <dl class="box" id="stt-base-tec"><dt>技</dt><dd>@{[input('sttBaseTec','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-base-phy"><dt>体</dt><dd>@{[input('sttBasePhy','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-base-spi"><dt>心</dt><dd>@{[input('sttBaseSpi','number','calcStt')]}</dd></dl>
          
          <dl class="box" id="stt-base-A"><dt>Ａ</dt><dd>@{[input('sttBaseA','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-base-B"><dt>Ｂ</dt><dd>@{[input('sttBaseB','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-base-C"><dt>Ｃ</dt><dd>@{[input('sttBaseC','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-base-D"><dt>Ｄ</dt><dd>@{[input('sttBaseD','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-base-E"><dt>Ｅ</dt><dd>@{[input('sttBaseE','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-base-F"><dt>Ｆ</dt><dd>@{[input('sttBaseF','number','calcStt')]}</dd></dl>
          
          <dl class="box" id="stt-grow-A"><dt>成長</dt><dd id="stt-grow-A-value">$pc{'sttGrowA'}</dd></dl>
          <dl class="box" id="stt-grow-B"><dt>成長</dt><dd id="stt-grow-B-value">$pc{'sttGrowB'}</dd></dl>
          <dl class="box" id="stt-grow-C"><dt>成長</dt><dd id="stt-grow-C-value">$pc{'sttGrowC'}</dd></dl>
          <dl class="box" id="stt-grow-D"><dt>成長</dt><dd id="stt-grow-D-value">$pc{'sttGrowD'}</dd></dl>
          <dl class="box" id="stt-grow-E"><dt>成長</dt><dd id="stt-grow-E-value">$pc{'sttGrowE'}</dd></dl>
          <dl class="box" id="stt-grow-F"><dt>成長</dt><dd id="stt-grow-F-value">$pc{'sttGrowF'}</dd></dl>
          
          <dl class="box" id="stt-dex"><dt>器用度</dt><dd id="stt-dex-value">$pc{'sttDex'}</dd></dl>
          <dl class="box" id="stt-agi"><dt>敏捷度</dt><dd id="stt-agi-value">$pc{'sttAgi'}</dd></dl>
          <dl class="box" id="stt-str"><dt>筋力  </dt><dd id="stt-str-value">$pc{'sttStr'}</dd></dl>
          <dl class="box" id="stt-vit"><dt>生命力</dt><dd id="stt-vit-value">$pc{'sttVit'}</dd></dl>
          <dl class="box" id="stt-int"><dt>知力  </dt><dd id="stt-int-value">$pc{'sttInt'}</dd></dl>
          <dl class="box" id="stt-mnd"><dt>精神力</dt><dd id="stt-mnd-value">$pc{'sttMnd'}</dd></dl>
          
          <dl class="box" id="stt-add-A"><dt>増強</dt><dd>@{[input('sttAddA','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-add-B"><dt>増強</dt><dd>@{[input('sttAddB','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-add-C"><dt>増強</dt><dd>@{[input('sttAddC','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-add-D"><dt>増強</dt><dd>@{[input('sttAddD','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-add-E"><dt>増強</dt><dd>@{[input('sttAddE','number','calcStt')]}</dd></dl>
          <dl class="box" id="stt-add-F"><dt>増強</dt><dd>@{[input('sttAddF','number','calcStt')]}</dd></dl>
          
          <dl class="box" id="stt-bonus-dex"><dt><span>器用度</span></dt><dd id="stt-bonus-dex-value">$pc{'bonusDex'}</dd></dl>
          <dl class="box" id="stt-bonus-agi"><dt><span>敏捷度</span></dt><dd id="stt-bonus-agi-value">$pc{'bonusAgi'}</dd></dl>
          <dl class="box" id="stt-bonus-str"><dt><span>筋力  </span></dt><dd id="stt-bonus-str-value">$pc{'bonusStr'}</dd></dl>
          <dl class="box" id="stt-bonus-vit"><dt><span>生命力</span></dt><dd id="stt-bonus-vit-value">$pc{'bonusVit'}</dd></dl>
          <dl class="box" id="stt-bonus-int"><dt><span>知力  </span></dt><dd id="stt-bonus-int-value">$pc{'bonusInt'}</dd></dl>
          <dl class="box" id="stt-bonus-mnd"><dt><span>精神力</span></dt><dd id="stt-bonus-mnd-value">$pc{'bonusMnd'}</dd></dl>
          
          <dl class="box" id="stt-pointbuy-TPS">
            <dt>割振りPt.</dt>
            <dd id="stt-pointbuy-TPS-value"></dd>
          </dl>
          <dl class="box" id="stt-pointbuy-AtoF">
            <dt>割振りPt.</dt>
            <dd id="stt-pointbuy-AtoF-value"></dd>
          </dl>
          <dl class="box" id="stt-grow-total">
            <dt>成長合計</dt>
            <dd><span><span id="stt-grow-total-value"></span><span id="stt-grow-max-value"></span></span></dd>
          </dl>
          <dl class="box" id="stt-pointbuy-type">
            <dt>ポイント割り振りの計算式</dt>
            <dd><select name="pointbuyType" onchange="calcStt();">
            <option value="2.5" @{[$pc{'pointbuyType'} eq '2.5' ? 'selected':'']}>2.5式(ET)</option>
            <option value="2.0" @{[$pc{'pointbuyType'} eq '2.0' ? 'selected':'']}>2.0式(AW,EX)</option>
            </select></dd>
          </dl>
        </div>

        <div class="box-union" id="sub-status">
          <dl class="box">
            <dt id="vit-resist">生命抵抗力</dt>
            <dd><span id="vit-resist-base">$pc{'vitResistBase'}</span>+<span id="vit-resist-auto-add">$pc{'vitResistAutoAdd'}</span>+@{[input('vitResistAdd','number','calcSubStt')]}=<b id="vit-resist-total">$pc{'vitResistTotal'}</b></dd>
          </dl>
          <dl class="box">
          <dt id="mnd-resist">精神抵抗力</dt>
          <dd><span id="mnd-resist-base">$pc{'mndResistBase'}</span>+<span id="mnd-resist-auto-add">$pc{'mndResistAutoAdd'}</span>+@{[input('mndResistAdd','number','calcSubStt')]}=<b id="mnd-resist-total">$pc{'mndResistTotal'}</b></dd>
          </dl>
          <dl class="box">
            <dt id="hp">ＨＰ</dt>
            <dd><span id="hp-base">$pc{'hpBase'}</span>+<span id="hp-auto-add">$pc{'hpAutoAdd'}</span>+@{[input('hpAdd','number','calcSubStt')]}=<b id="hp-total">$pc{'hpTotal'}</b></dd>
          </dl>
          <dl class="box">
            <dt id="mp">ＭＰ</dt>
            <dd><span id="mp-base">$pc{'mpBase'}</span>+<span id="mp-auto-add">$pc{'mpAutoAdd'}</span>+@{[input('mpAdd','number','calcSubStt')]}=<b id="mp-total">$pc{'mpTotal'}</b></dd>
          </dl>
        </div>
        
        <dl class="box" id="level">
          <dt>冒険者レベル</dt><dd id="level-value">$pc{'level'}</dd>
        </dl>
        <dl class="box" id="exp">
          <dt>経験点</dt><dd><div><span id="exp-rest">$pc{'expRest'}</span><br>／<br><span id="exp-total">$pc{'expTotal'}</span></div></dd>
        </dl>
      </div>
      
      <div id="area-ability" class="edit-tables side-margin">
        <div id="area-classes" @{[ $set::common_class_on ? '' : 'class="common-classes-off"' ]}>
          <div class="box" id="classes">
            <h2>技能</h2>
            <div>使用経験点：<span id="exp-use"></span></div>
            <dl>
HTML
my $i = 0;
foreach my $name (@data::class_names){
  next if $data::class{$name}{2.0} && !$set::all_class_on;
  $i++;
  my $id = $data::class{$name}{'id'};
  print '<dt id="class'.$id.'"';
  print ' class="zero-data"' if $data::class{$name}{'2.0'};
  print '>';
  print '[2.0] ' if $data::class{$name}{'2.0'};
  print $name;
  print '<select name="faithType" style="width:auto;">'.option('faithType','†|<†セイクリッド系>','‡|<‡ヴァイス系>','†‡|<†‡両系統使用可>').'</select>' if($name eq 'プリースト');
  print '</dt><dd>' . input("lv${id}", 'number','changeLv','min="0" max="17"') . '</dd>';
  print '</dl><dl>' if ($i == int(scalar(@data::class_names) / 2));
}
if($set::common_class_on){
print <<"HTML";
            </dl>
          </div>
          <div class="box" id="common-classes">
            <h2>一般技能</h2>
            <dl>
HTML
  foreach my $i (1..10){
print <<"HTML";
              <dt>@{[input('commonClass'.$i)]}</dt><dd>@{[input('lvCommon'.$i, 'number','','min="0" max="17"')]}</dd>
HTML
  }
}
print <<"HTML";
            </dl>
          </div>
        </div>
        <p class="right">@{[ input "failView", "checkbox", "checkFeats()" ]} 習得レベルの足りない項目（特技／練技・呪歌など）も表示する</p>
        <div>
          <div class="box" id="combat-feats">
            <h2>戦闘特技</h2>
            <ul>
HTML
foreach my $lv (@set::feats_lv) {
  print '<li id="combat-feats-lv'.$lv.'" data-lv="'.$lv.'"><select name="combatFeatsLv'.$lv.'" oninput="checkFeats()">';
  print '<option></option>';
  foreach my $type ('常','宣','主') {
    print '<optgroup label="'.($type eq '常' ? '常時' : $type eq '宣' ? '宣言' : $type eq '宣' ? '宣言' : '主動作').'特技">';
    foreach my $feats (@data::combat_feats){
      next if $lv < @$feats[1];
      next if $type ne @$feats[0];
      next if @$feats[3] =~ /2.0/ && !$set::all_class_on;
      if(@$feats[3] =~ /2.0/){
        print '<option class="zero-data"'.(($pc{"combatFeatsLv$lv"} eq @$feats[2])?' selected':'').' value="'.@$feats[2].'">[2.0]'.@$feats[2];
      }
      else { print '<option'.(($pc{"combatFeatsLv$lv"} eq @$feats[2])?' selected':'').'>'.@$feats[2]; }
    }
    print '</optgroup>';
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
            <p>置き換え可能な場合<span class="evo">この表示</span>になります。</p>
            <p>@{[ input 'featsAutoOn','checkbox','checkFeats' ]}自動置き換え（非推奨）</p>
          </div>
          <div class="box" id="mystic-arts" @{[ display $set::mystic_arts_on ]}>
            <h2>秘伝</h2>
            <div>所持名誉点：<span id="honor-value-MA"></span></div>
            <ul id="mystic-arts-list">
HTML
$pc{'mysticArtsNum'} = 0 if !$set::mystic_arts_on;
foreach my $num (1 .. $pc{'mysticArtsNum'}){
  print '<li id="mystic-arts'.$num.'"><span class="handle"></span>'.(input 'mysticArts'.$num).(input 'mysticArts'.$num.'Pt', 'number', 'calcHonor').'</li>';
}
print <<"HTML";
            </ul>
            <div class="add-del-button"><a onclick="addMysticArts()">▼</a><a onclick="delMysticArts()">▲</a></div>
            @{[input('mysticArtsNum','hidden')]}
          </div>
        </div>
        <div id="crafts">
HTML
foreach my $class (@data::class_names){
  next if !$data::class{$class}{'magic'}{'data'};
  my $name = $data::class{$class}{'magic'}{'eName'};
  my $Name = ucfirst($data::class{$class}{'magic'}{'eName'});
  print <<"HTML";
            <div class="box" id="magic-${name}">
              <h2>$data::class{$class}{'magic'}{'jName'}</h2>
              <ul>
HTML
  foreach my $lv (1..17){
    print '<li id="magic-'.$name.$lv.'"><select name="magic'.$Name.$lv.'">';
    print '<option></option>';
    my %only;
    foreach my $data (@{$data::class{$class}{'magic'}{'data'}}){
      next if $lv < @$data[0];
      my $item = '<option'.(($pc{"magic${Name}${lv}"} eq @$data[1])?' selected':'').' value="'.@$data[1].'">'.@$data[1];
      print $item;
      if ($class eq 'グリモワール'){ print "（@$data[2]）"; }
    }
    foreach my $key (sort keys %only) {
      print "<optgroup label=\"${key}\">$only{$key}</optgroup>";
    }
    print "</select></li>\n";
  }
  print <<"HTML";
            </ul>
          </div>
HTML
}
foreach my $class (@data::class_names){
  next if !$data::class{$class}{'craft'}{'data'};
  my $name = $data::class{$class}{'craft'}{'eName'};
  my $Name = ucfirst($data::class{$class}{'craft'}{'eName'});
  print <<"HTML";
            <div class="box" id="craft-${name}">
              <h2>$data::class{$class}{'craft'}{'jName'}</h2>
              <ul>
HTML
  my $c_max = $class eq 'バード' ? 20 : 17;
  foreach my $lv (1..$c_max){
    print '<li id="craft-'.$name.$lv.'"><select name="craft'.$Name.$lv.'">';
    print '<option></option>';
    my %only;
    foreach my $data (@{$data::class{$class}{'craft'}{'data'}}){
      next if $lv < @$data[0];
      my $item = '<option'.(($pc{"craft${Name}${lv}"} eq @$data[1])?' selected':'').' value="'.@$data[1].'">'.@$data[1];
      
      if(@$data[2] =~ /^(.*?)専用/){ $only{@$data[2]} .= $item; }
      else { print $item; }
    }
    foreach my $key (sort keys %only) {
      print "<optgroup label=\"${key}\">$only{$key}</optgroup>";
    }
    print "</select></li>\n";
  }
  print <<"HTML";
            </ul>
          </div>
HTML
}
print <<"HTML";
        </div>
      </div>

      <div id="area-actions">
        <div id="area-package">
          <div class="box" id="package">
            <h2>判定パッケージ</h2>
            <table class="edit-table side-margin">
              <tbody id="package-scout"@{[ display $pc{'lvSco'} ]}>
                <tr>
                  <th rowspan="3">スカウト技能</th>
                  <th>技巧</th>
                  <td>+@{[ input 'packScoTecAdd', 'number','calcPackage' ]}</td>
                  <td id="package-scout-tec">$pc{'packScoTec'}</td>
                </tr>
                <tr>
                  <th>運動</th>
                  <td>+@{[ input 'packScoAgiAdd', 'number','calcPackage' ]}</td>
                  <td id="package-scout-agi">$pc{'packScoAgi'}</td>
                </tr>
                <tr>
                  <th>観察</th>
                  <td>+@{[ input 'packScoObsAdd', 'number','calcPackage' ]}</td>
                  <td id="package-scout-obs">$pc{'packScoObs'}</td>
                </tr>
              </tbody>
              <tbody id="package-ranger"@{[ display $pc{'lvRan'} ]}>
                <tr>
                  <th rowspan="3">レンジャー技能</th>
                  <th>技巧</th>
                  <td>+@{[ input 'packRanTecAdd', 'number','calcPackage' ]}</td>
                  <td id="package-ranger-tec">$pc{'packRanTec'}</td>
                </tr>
                <tr>
                  <th>運動</th>
                  <td>+@{[ input 'packRanAgiAdd', 'number','calcPackage' ]}</td>
                  <td id="package-ranger-agi">$pc{'packRanAgi'}</td>
                </tr>
                <tr>
                  <th>観察</th>
                  <td>+@{[ input 'packRanObsAdd', 'number','calcPackage' ]}</td>
                  <td id="package-ranger-obs">$pc{'packRanObs'}</td>
                </tr>
              </tbody>
              <tbody id="package-sage"@{[ display $pc{'lvSag'} ]}>
                <tr>
                  <th>セージ技能</th>
                  <th>知識</th>
                  <td>+@{[ input 'packSagKnoAdd', 'number','calcPackage' ]}</td>
                  <td id="package-sage-kno">$pc{'packSagKno'}</td>
                </tr>
              </tbody>
              <tbody id="package-rider"@{[ display $pc{'lvRid'} ]}>
                <tr>
                  <th rowspan="3">ライダー技能</th>
                  <th>運動</th>
                  <td>+@{[ input 'packRidAgiAdd', 'number','calcPackage' ]}</td>
                  <td id="package-rider-agi">$pc{'packRidAgi'}</td>
                </tr>
                <tr>
                  <th>知識</th>
                  <td>+@{[ input 'packRidKnoAdd', 'number','calcPackage' ]}</td>
                  <td id="package-rider-kno">$pc{'packRidKno'}</td>
                </tr>
                <tr>
                  <th>観察</th>
                  <td>+@{[ input 'packRidObsAdd', 'number','calcPackage' ]}</td>
                  <td id="package-rider-obs">$pc{'packRidObs'}</td>
                </tr>
              </tbody>
              <tbody id="package-alchemist"@{[ display $pc{'lvAlc'} ]}>
                <tr>
                  <th>アルケミスト技能</th>
                  <th>知識</th>
                  <td>+@{[ input 'packAlcKnoAdd', 'number','calcPackage' ]}</td>
                  <td id="package-alchemist-kno">$pc{'packAlcKno'}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <div id="area-other-actions">
          <dl class="box" id="monster-lore">
            <dt>魔物知識</dt>
            <dd>+@{[ input 'monsterLoreAdd', 'number','calcPackage' ]}=<span id="monster-lore-value">$pc{'monsterLore'}</span></dd>
          </dl>
          <dl class="box" id="initiative">
            <dt>先制力</dt>
            <dd>+@{[ input 'initiativeAdd', 'number','calcPackage' ]}=<span id="initiative-value">$pc{'initiative'}</span></dd>
          </dl>
          <dl class="box" id="mobility">
            <dt>制限移動</dt><dd><b id="mobility-limited">$pc{'mobilityLimited'}</b> m</dd>
            <dt>移動力</dt><dd><span id="mobility-base">$pc{'mobilityBase'}</span>+@{[input('mobilityAdd','number','calcMobility')]}=<b id="mobility-total">0</b> m</dd>
            <dt>全力移動</dt><dd><b id="mobility-full">$pc{'mobilityFull'}</b> m</dd>
          </dl>
        </div>
        <div class="box" id="language">
          <h2>言語</h2>
          <table class="edit-table side-margin">
            <tr><th></th><th>会話</th><th>読文</th></tr>
          </table>
          <dl class="edit-table side-margin" id="language-default">
HTML
foreach (@{$data::race_language{ $pc{'race'} }}){
  print '<dt>'.@$_[0].'</dt><dd>'.(@$_[1] ? '○' : '－').'</dd><dd>'.(@$_[2] ? '○' : '－').'</dd>';
}
print <<"HTML";
          </dl>
          <table class="edit-table side-margin" id="language-table">
            <tbody>
HTML
foreach my $num (1 .. $pc{'languageNum'}){
  print '<tr id="language-item'.$num.'"><td class="handle"></td><td>'.input('language'.$num, '','','list="list-language"').'</td>'.
  '<td><input type="checkbox" name="language'.$num.'Talk" value="1"'.($pc{"language${num}Talk"} ? 'checked' :'').'></td>'.
  '<td><input type="checkbox" name="language'.$num.'Read" value="1"'.($pc{"language${num}Read"} ? 'checked' :'').'></td>'.
  '</tr>'."\n";
}
print <<"HTML";
            </tbody>
          </table>
          <p>@{[ input 'languageAutoOff','checkbox','changeRace' ]}初期習得言語を自動記入しない</p>
          <div class="add-del-button"><a onclick="addLanguage()">▼</a><a onclick="delLanguage()">▲</a></div>
          @{[input('languageNum','hidden')]}
        </div>
        <div class="box" id="magic-power">
          <h2>魔法／呪歌／賦術など</h2>
          <table class="edit-table line-tbody">
            <thead>
            <tr>
              <th></th><th></th><th>専用化</th><th>魔力／奏力</th><th>行使<small>／演奏など</small></th><th class="small">ダメージ<br>上昇効果</th>
            </tr>
            </thead>
            <tr id="magic-power-magicenhance">
              <td>《魔力強化》</td>
              <td>魔法全般</td>
              <td></td>
              <td class="center">+<span id="magic-power-magicenhance-value">0</span></td>
              <td></td>
              <td></td>
            </tr>
            <tr id="magic-power-common">
              <td>装備補正など</td>
              <td>魔法全般</td>
              <td></td>
              <td>+@{[ input 'magicPowerAdd','number','calcMagic' ]}</td>
              <td>+@{[ input 'magicCastAdd','number','calcMagic' ]}</td>
              <td>+@{[ input 'magicDamageAdd','number','calcMagic' ]}</td>
            </tr>
HTML
my $fairyset = <<"HTML";
<div id="fairycontact">
  <label class="ft-earth">@{[ input 'fairyContractEarth', 'checkbox','calcMagic' ]}<span>土</span></label>
  <label class="ft-water">@{[ input 'fairyContractWater', 'checkbox','calcMagic' ]}<span>水</span></label>
  <label class="ft-fire" >@{[ input 'fairyContractFire' , 'checkbox','calcMagic' ]}<span>炎</span></label>
  <label class="ft-wind" >@{[ input 'fairyContractWind' , 'checkbox','calcMagic' ]}<span>風</span></label>
  <label class="ft-light">@{[ input 'fairyContractLight', 'checkbox','calcMagic' ]}<span>光</span></label>
  <label class="ft-dark" >@{[ input 'fairyContractDark' , 'checkbox','calcMagic' ]}<span>闇</span></label>
</div>
HTML
foreach my $name (@data::class_names){
  next if (!$data::class{$name}{'magic'}{'jName'});
  my $id    = $data::class{$name}{'id'};
  my $ename = $data::class{$name}{'eName'};
  print <<"HTML";
            <tr@{[ display $pc{'lv'.$id} ]} id="magic-power-${ename}">
              <td>${name}</td>
              <td>$data::class{$name}{'magic'}{'jName'} @{[ $name eq 'フェアリーテイマー' ? $fairyset : '' ]}</td>
              <td><label>@{[ input 'magicPowerOwn'.$id, 'checkbox','calcMagic' ]}知力+2</label></td>
              <td>+@{[ input 'magicPowerAdd'.$id,  'number','calcMagic' ]}=<b id="magic-power-${ename}-value">0</b></td>
              <td>+@{[ input 'magicCastAdd'.$id,   'number','calcMagic' ]}=<b id="magic-cast-${ename}-value" >0</b></td>
              <td>+@{[ input 'magicDamageAdd'.$id, 'number','calcMagic' ]}=<b id="magic-damage-${ename}-value" >0</b></td>
            </tr>
HTML
}
print <<"HTML";
            <tr id="magic-power-hr">
              <td colspan="8"></td>
            </tr>
HTML
foreach my $name (@data::class_names){
  next if (!$data::class{$name}{'craft'}{'stt'});
  my $id    = $data::class{$name}{'id'};
  my $ename = $data::class{$name}{'eName'};
  print <<"HTML";
            <tr@{[ display $pc{'lv'.$id} ]} id="magic-power-${ename}">
              <td>${name}</td>
              <td>$data::class{$name}{'craft'}{'jName'}</td>
              <td><label>@{[ input 'magicPowerOwn'.$id, 'checkbox','calcMagic' ]}$data::class{$name}{'craft'}{'stt'}+2</label></td>
              <td>
HTML
  if($data::class{$name}{'craft'}{'power'}){
    print '+'.input('magicPowerAdd'.$id, 'number','calcMagic')."=<b id=\"magic-power-${ename}-value\">0</b>";
  }
  print <<"HTML";
</td>
              <td>+@{[ input 'magicCastAdd'.$id, 'number','calcMagic' ]}=<b id="magic-cast-${ename}-value" >0</b></td>
              <td>
HTML
  if($data::class{$name}{'craft'}{'power'}){
    print '+'.input('magicDamageAdd'.$id, 'number','calcMagic')."=<b id=\"magic-damage-${ename}-value\">0</b>";
  }
  print <<"HTML";
</td>
            </tr>
HTML
}
print <<"HTML";
          </table>
        </div>
      </div>
      
      <div class="edit-tables" id="area-equipment">
        <div class="box" id="attack-classes">
          <table class="line-tbody">
            <thead>
              <tr>
                <th>技能・特技</th>
                <th>必筋<br>上限</th>
                <th>命中力</th>
                <th></th>
                <th>Ｃ値</th>
                <th>追加Ｄ</th>
              </tr>
            </thead>
            <tbody>
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
              <tr id="attack-enhancer"@{[ display ($pc{'lvEnh'} >= 10) ]}>
                <td>エンハンサー技能</td>
                <td id="attack-enhancer-str">0</td>
                <td id="attack-enhancer-acc">0</td>
                <td>―</td>
                <td>―</td>
                <td id="attack-enhancer-dmg">0</td>
              </tr>
              <tr id="attack-demonruler"@{[ display $pc{'lvDem'} ]}>
                <td>デーモンルーラー技能</td>
                <td id="attack-demonruler-str">0</td>
                <td id="attack-demonruler-acc">0</td>
                <td>―</td>
                <td>―</td>
                <td id="attack-demonruler-dmg">0</td>
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
                <td id="attack-@$weapon[1]-mastery-dmg">$pc{'mastery'.ucfirst(@$weapon[1])}</td>
              </tr>
HTML
}
print <<"HTML";
              <tr id="attack-artisan-mastery"@{[ display $pc{'masteryArtisan'} ]}>
                <td>《魔器習熟》</td>
                <td>―</td>
                <td>―</td>
                <td>―</td>
                <td>―</td>
                <td id="attack-artisan-mastery-dmg">$pc{'masteryArtisan'}</td>
              </tr>
              <tr id="accuracy-enhance"@{[ display $pc{'accuracyEnhance'} ]}>
                <td>《命中強化》</td>
                <td>―</td>
                <td id="accuracy-enhance-acc">$pc{'accuracyEnhance'}</td>
                <td>―</td>
                <td>―</td>
                <td>―</td>
              </tr>
              <tr id="throwing"@{[ display $pc{'throwing'} ]}>
                <td>《スローイング》</td>
                <td>―</td>
                <td id="throwing-acc">1</td>
                <td>―</td>
                <td>―</td>
                <td>―</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="box" id="weapons">
          <table class="line-tbody" id="weapons-table">
            <thead>
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
            </thead>
HTML

foreach my $num (1 .. $pc{'weaponNum'}) {
print <<"HTML";
            <tbody id="weapon-row$num">
              <tr>
                <td rowspan="2">@{[input("weapon${num}Name")]}<span class="handle"></span></td>
                <td rowspan="2">@{[input("weapon${num}Usage","text",'','list="list-usage"')]}</td>
                <td rowspan="2">@{[input("weapon${num}Reqd",'text','calcWeapon')]}</td>
                <td rowspan="2">+@{[input("weapon${num}Acc",'number','calcWeapon')]}<b id="weapon${num}-acc-total">0</b></td>
                <td rowspan="2">@{[input("weapon${num}Rate")]}</td>
                <td rowspan="2">@{[input("weapon${num}Crit")]}</td>
                <td rowspan="2">+@{[input("weapon${num}Dmg",'number','calcWeapon')]}<b id="weapon${num}-dmg-total">0</b></td>
                <td>@{[input("weapon${num}Own",'checkbox','calcWeapon')]}</td>
                <td><select name="weapon${num}Category" oninput="calcWeapon()">@{[option("weapon${num}Category",@data::weapon_names,'ガン（物理）','盾')]}</select></td>
                <td><select name="weapon${num}Class" oninput="calcWeapon()">@{[option("weapon${num}Class",'ファイター','グラップラー','フェンサー','シューター','エンハンサー','デーモンルーラー','自動計算しない')]}</select></td>
              </tr>
              <tr><td colspan="3">@{[input("weapon${num}Note",'','calcWeapon','placeholder="備考"')]}</td>
            </tbody>
HTML
}
print <<"HTML";
            </tbody>
          </table>
          <div class="annotate">
            ※Ｃ値は自動計算されません。<br>
            <span id="artisan-annotate" @{[ display $pc{'masteryArtisan'} ]}>※備考欄に<code>〈魔器〉</code>と記入すると魔器習熟が反映されます。</span>
          </div>
          <div class="add-del-button"><a onclick="addWeapons()">▼</a><a onclick="delWeapons()">▲</a></div>
          @{[input('weaponNum','hidden')]}
        </div>
        <div class="box" id="evasion-classes">
          <table>
            <thead>
              <tr>
                <th>技能・特技</th>
                <th>必筋<br>上限</th>
                <th>回避力</th>
                <th>防護点</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><select id="evasion-class" name="evasionClass" oninput="calcDefense()">@{[option('evasionClass','ファイター','グラップラー','フェンサー','シューター','デーモンルーラー')]}</select></td>
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
              <tr id="mastery-artisan-def"@{[ display $pc{'masteryArtisan'} ]}>
                <td>《魔器習熟》</td>
                <td>―</td>
                <td>―</td>
                <td id="mastery-artisan-def-value">$pc{'masteryArtisan'}</td>
              </tr>
              <tr id="evasive-maneuver"@{[ display $pc{'evasiveManeuver'} ]}>
                <td>《回避行動》</td>
                <td>―</td>
                <td id="evasive-maneuver-value">$pc{'evasiveManeuver'}</td>
                <td>―</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="box" id="armours">
          <table>
            <thead>
            <tr>
              <th></th>
              <th>防具</th>
              <th>必筋</th>
              <th>回避力</th>
              <th>防護点</th>
              <th>専用</th>
              <th>備考</th>
            </tr>
            </thead>
            <tbody>
              <tr>
                <th>鎧</th>
                <td>@{[input('armourName')]}</td>
                <td>@{[input('armourReqd','','calcDefense')]}</td>
                <td>@{[input('armourEva','number','calcDefense')]}</td>
                <td>@{[input('armourDef','number','calcDefense')]}</td>
                <td>@{[input('armourOwn','checkbox','calcDefense')]}</td>
                <td>@{[input('armourNote')]}</td>
              </tr>
              <tr>
                <th>盾</th>
                <td>@{[input('shieldName')]}</td>
                <td>@{[input('shieldReqd','','calcDefense')]}</td>
                <td>@{[input('shieldEva','number','calcDefense')]}</td>
                <td>@{[input('shieldDef','number','calcDefense')]}</td>
                <td>@{[input('shieldOwn','checkbox','calcDefense')]}</td>
                <td>@{[input('shieldNote')]}</td>
              </tr>
              <tr>
                <th>他</th>
                <td>@{[input('defOtherName','','calcDefense')]}</td>
                <td>@{[input('defOtherReqd')]}</td>
                <td>@{[input('defOtherEva','number','calcDefense')]}</td>
                <td>@{[input('defOtherDef','number','calcDefense')]}</td>
                <td> </td>
                <td>@{[input('defOtherNote')]}</td>
              </tr>
              <tr class="defense-total">
                <th colspan="3">合計：すべて</th>
                <td id="defense-total-all-eva">0</td>
                <td id="defense-total-all-def">0</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="box" id="accessories">
          <table>
            <thead>
              <tr>
                <th></th>
                <th></th>
                <th>装飾品</th>
                <th>専用</th>
                <th>効果</th>
              </tr>
            </thead>
            <tbody id="accessories-table">
HTML
foreach (
  ["頭","Head"],    ["┗","Head_"],   ["┗","Head__"],
  ["顔","Face"],    ["┗","Face_"],   ["┗","Face__"],
  ["耳","Ear"],     ["┗","Ear_"],    ["┗","Ear__"],
  ["首","Neck"],    ["┗","Neck_"],   ["┗","Neck__"],
  ["背中","Back"],  ["┗","Back_"],   ["┗","Back__"],
  ["右手","HandR"], ["┗","HandR_"],  ["┗","HandR__"],
  ["左手","HandL"], ["┗","HandL_"],  ["┗","HandL__"],
  ["腰","Waist"],   ["┗","Waist_"],  ["┗","Waist__"],
  ["足","Leg"],     ["┗","Leg_"],    ["┗","Leg__"],
  ["他","Other"],   ["┗","Other_"],  ["┗","Other__"],
  ["他2","Other2"], ["┗","Other2_"], ["┗","Other2__"],
  ["他3","Other3"], ["┗","Other3_"], ["┗","Other3__"],
  ["他4","Other4"], ["┗","Other4_"], ["┗","Other4__"],
) {
  my $flag;
  my $addbase = @$_[1];
     $addbase =~ s/_//;
  if   (@$_[0] eq '他2' &&  $pc{'race'} ne 'レプラカーン')                     { $flag = 0; }
  elsif(@$_[0] eq '他3' && ($pc{'race'} ne 'レプラカーン' || $pc{'level'} < 6)){ $flag = 0; }
  elsif(@$_[0] eq '他4' && ($pc{'race'} ne 'レプラカーン' || $pc{'level'} <16)){ $flag = 0; }
  elsif(@$_[0] =~ /┗/  && !$pc{'accessory'.$addbase.'Add'}){ $flag = 0; }
  else { $flag = 1; }
  print '  <tr id="accessory-row'.@$_[1].'" data-type="'.@$_[1].'" '.display($flag).">\n";
  print '  <td>';
  if (@$_[1] !~ /__/) {
    print '  <input type="checkbox"' .
          " name=\"accessory@$_[1]Add\" value=\"1\"" .
          ($pc{"accessory@$_[1]Add"}?' checked' : '') .
          " onChange=\"addAccessory(this,'@$_[1]')\">";
  }
  print "</td>\n";
  print <<"HTML";
  <th>@$_[0]</th>
  <td>@{[input('accessory'.@$_[1].'Name')]}</td>
  <td>
    <select name="accessory@$_[1]Own" oninput="calcSubStt()">
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
          </tbody>
          </table>
        <div class="annotate">
        ※左のボックスにチェックを入れると欄が一つ追加されます
        </div>
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
          <div class="box" id="material-cards"@{[ display $pc{'lvAlc'} ]}>
            <h2>マテリアルカード</h2>
            <table class="edit-table" >
            <tr><th>  </th><th>B</th><th>A</th><th>S</th><th>SS</th></tr>
            <tr class="cards-red"><th>赤</th><td>@{[input 'cardRedB','number']}</td><td>@{[input 'cardRedA','number']}</td><td>@{[input 'cardRedS','number']}</td><td>@{[input 'cardRedSS','number']}</td></tr>
            <tr class="cards-gre"><th>緑</th><td>@{[input 'cardGreB','number']}</td><td>@{[input 'cardGreA','number']}</td><td>@{[input 'cardGreS','number']}</td><td>@{[input 'cardGreSS','number']}</td></tr>
            <tr class="cards-bla"><th>黒</th><td>@{[input 'cardBlaB','number']}</td><td>@{[input 'cardBlaA','number']}</td><td>@{[input 'cardBlaS','number']}</td><td>@{[input 'cardBlaSS','number']}</td></tr>
            <tr class="cards-whi"><th>白</th><td>@{[input 'cardWhiB','number']}</td><td>@{[input 'cardWhiA','number']}</td><td>@{[input 'cardWhiS','number']}</td><td>@{[input 'cardWhiSS','number']}</td></tr>
            <tr class="cards-gol"><th>金</th><td>@{[input 'cardGolB','number']}</td><td>@{[input 'cardGolA','number']}</td><td>@{[input 'cardGolS','number']}</td><td>@{[input 'cardGolSS','number']}</td></tr>
            </table>
          </div>
          <div class="box" id="battle-items"@{[ display $set::battleitem ]}>
          <h2>戦闘用アイテム</h2>
          <ul id="battle-items-list">
HTML
foreach my $num (1 .. 16){
  print '<li id="battle-item'.$num.'"><span class="handle"></span><input type="text" name="battleItem'.$num.'" value="'.$pc{'battleItem'.$num}.'"></li>';
}
print <<"HTML";
          </ul>
          </div>
          <dl class="box" id="honor">
            <dt>名誉点</dt><dd id="honor-value">$pc{'honor'}</dd>
            <dt>ランク</dt>
            <dd><select name="rank" oninput="calcHonor()">@{[ option "rank",@set::adventurer_rank_name ]}</select></dd>
          </dl>
          <div class="box honor-items" id="honor-items">
            <h2>名誉アイテム</h2>
            <table class="edit-table side-margin" id="honor-items-table">
              <thead>
                <tr><th></th><th></th><th>点数</th></tr>
              </thead>
              <tbody>
                <tr><td class="center" colspan="2">冒険者ランク</td><td id="rank-honor-value">0</td></tr>
                <tr @{[ display $set::mystic_arts_on ]}><td class="center" class="center" colspan="2">秘伝</td><td id="mystic-arts-honor-value">0</td></tr>
HTML
foreach my $num (1 .. $pc{'honorItemsNum'}){
  print '<tr id="honor-item'.$num.'"><td class="handle"></td><td>'.(input "honorItem${num}", "text").'</td><td>'.(input "honorItem${num}Pt", "number", "calcHonor").'</td></tr>';
}
print <<"HTML";
              </tbody>
            </table>
          <div class="add-del-button"><a onclick="addHonorItems()">▼</a><a onclick="delHonorItems()">▲</a></div>
          @{[ input 'honorItemsNum','hidden' ]}
          <p>フリー条件適用可能な（名誉点消費を0点にして良い）場合、<span class="evo">この表示</span>になります。</p>
          </div>
          <dl class="box" id="dishonor">
            <dt>不名誉点</dt><dd id="dishonor-value">0</dd>
            <dt>不名誉称号</dt><dd id="notoriety"></dd>
          </dl>
          <div class="box honor-items" id="dishonor-items">
            <h2>不名誉詳細</h2>
            <table class="edit-table side-margin" id="dishonor-items-table">
              <thead><tr><th></th><th></th><th>点数</th></tr></thead>
              <tbody>
HTML
foreach my $num (1 .. $pc{'dishonorItemsNum'}){
  print '<tr id="dishonor-item'.$num.'"><td class="handle"></td><td>'.(input "dishonorItem${num}", "text").'</td><td>'.(input "dishonorItem${num}Pt", "number", "calcDishonor").'</td></tr>';
}
print <<"HTML";
            </tbody>
            </table>
          <div class="add-del-button"><a onclick="addDishonorItems()">▼</a><a onclick="delDishonorItems()">▲</a></div>
          @{[ input 'dishonorItemsNum','hidden' ]}
          </div>
        </div>
      </div>
      <details class="box" id="cashbook" @{[$pc{'cashbook'}?'open':'']}>
        <summary>収支履歴</summary>
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
      </details>
      
      <details class="box" id="free-note" @{[$pc{'freeNote'}?'open':'']}>
        <summary>容姿・経歴・その他メモ</summary>
        <textarea name="freeNote">$pc{'freeNote'}</textarea>
        <details class="annotate">
        <summary>テキスト装飾・整形ルール（クリックで展開）</summary>
        ※メモ欄以外でも有効です。<br>
        太字　：<code>''テキスト''</code>：<b>テキスト</b><br>
        斜体　：<code>'''テキスト'''</code>：<span class="oblique">テキスト</span><br>
        打消線：<code>%%テキスト%%</code>：<span class="strike">テキスト</span><br>
        下線　：<code>__テキスト__</code>：<span class="underline">テキスト</span><br>
        透明　：<code>{{テキスト}}</code>：<span style="color:transparent">テキスト</span><br>
        ルビ　：<code>|テキスト《てきすと》</code>：<ruby>テキスト<rt>てきすと</rt></ruby><br>
        傍点　：<code>《《テキスト》》</code>：<span class="text-em">テキスト</span><br>
        透明　：<code>{{テキスト}}</code>：<span style="color:transparent">テキスト</span>（ドラッグ反転で見える）<br>
        リンク：<code>[[テキスト>URL]]</code><br>
        別シートへのリンク：<code>[テキスト#シートのID]</code><br>
        <br>
        アイコン<br>
        　魔法のアイテム：<code>[魔]</code>：<img class="i-icon" src="${set::icon_dir}wp_magic.png"><br>
        　刃武器　　　　：<code>[刃]</code>：<img class="i-icon" src="${set::icon_dir}wp_edge.png"><br>
        　打撃武器　　　：<code>[打]</code>：<img class="i-icon" src="${set::icon_dir}wp_blow.png"><br>
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
        表組み　　：<code>|テキスト|テキスト|</code><br>
        定義リスト：<code>:項目名|説明文</code><br>
        　　　　　　<code>:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|説明文2行目</code> 項目名を記入しないか、半角スペースで埋めると上と結合<br>
        折り畳み：行頭に<code>[>]項目名</code>：移行のテキストがすべて折り畳みになります。<br>
        　　　　　項目名を省略すると、自動的に「詳細」になります。<br>
        折り畳み終了：行頭に<code>[---]</code>：（ハイフンは3つ以上任意）<br>
        　　　　　　　省略すると、以後のテキストが全て折りたたまれます。<br>
        コメントアウト：行頭に<code>//</code>：記述した行を非表示にします。
        </details>
      </details>
      
      <details class="box" id="free-history" @{[$pc{'freeHistory'}?'open':'']}>
        <summary>履歴（自由記入）</summary>
        <textarea name="freeHistory">$pc{'freeHistory'}</textarea>
      </details>
      
      <div class="box" id="history">
        <h2>セッション履歴</h2>
        @{[input 'historyNum','hidden']}
        <table class="edit-table line-tbody" id="history-table">
          <thead>
            <tr>
              <th></th>
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
              <td></td>
              <td>キャラクター作成</td>
              <td id="history0-exp">$pc{'history0Exp'}</td>
              <td id="history0-honor">$pc{'history0Honor'}</td>
              <td id="history0-money">$pc{'history0Money'}</td>
              <td id="history0-grow">$pc{'history0Grow'}</td>
            </tr>
          </thead>
HTML
foreach my $num (1 .. $pc{'historyNum'}) {
print <<"HTML";
          <tbody id="history${num}">
            <tr>
              <td rowspan="2" class="handle"></td>
              <td rowspan="2">@{[input("history${num}Date")]}</td>
              <td rowspan="2">@{[input("history${num}Title")]}</td>
              <td>@{[input("history${num}Exp",'text','calcExp')]}</td>
              <td>@{[input("history${num}Honor",'text','calcHonor')]}</td>
              <td>@{[input("history${num}Money",'text','calcCash')]}</td>
              <td>@{[input("history${num}Grow",'text','','list="list-grow"')]}</td>
              <td>@{[input("history${num}Gm")]}</td>
              <td>@{[input("history${num}Member")]}</td>
            </tr>
            <tr><td colspan="6" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}</td></tr>
          </tbody>
HTML
}
print <<"HTML";
          <tfoot>
            <tr><th></th><th>日付</th><th>タイトル</th><th>経験点</th><th>GM</th><th>参加者</th></tr>
          </tfoot>
        </table>
        <div class="add-del-button"><a onclick="addHistory()">▼</a><a onclick="delHistory()">▲</a></div>
        <h2>記入例</h2>
        <table class="example edit-table line-tbody">
          <thead>
          <tr>
            <th></th>
            <th>日付</th>
            <th>タイトル</th>
            <th>経験点</th>
            <th>名誉点</th>
            <th>ガメル</th>
            <th>成長</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
          </thead>
          <tbody>
          <tr>
            <td>-</td>
            <td><input type="text" value="2018-08-11" disabled></td>
            <td><input type="text" value="第一話「記入例」" disabled></td>
            <td><input type="text" value="1100+50" disabled></td>
            <td><input type="text" value="17" disabled></td>
            <td><input type="text" value="1800" disabled></td>
            <td><input type="text" value="器用" disabled></td>
            <td><input type="text" value="サンプルさん" disabled></td>
            <td><input type="text" value="アルバート　ラミット　ブランデン　レンダ・レイ　ナイルベルト" disabled></td>
          </tr>
          </tbody>
        </table>
        <div class="annotate">
        ※経験点欄は<code>1000+50*2</code>など四則演算が有効です（ファンブル経験点などを分けて書けます）。<br>
        ※成長は欄1つの欄に<code>敏捷生命知力</code>など複数書いても自動計算されます。<br>
        　また、<code>敏捷×2</code><code>知力*3</code>など同じ成長が複数ある場合は纏めて記述できます（×や*は省略できます）。<br>
        　<code>器敏2知3</code>と能力値の頭文字1つで記述することもできます。<br>
        ※成長はリアルタイムでの自動計算はされません。反映するには一度保存してください。
        </div>
      </div>
      </section>
      
      <section id="section-fellow" style="display:none;">
      <h2 id="fellow">フェロー関連データ</h2>
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
        <tr class="border-top">
          <td rowspan="2">⚀<br>⚁</td>
          <td class="number">7</td>
          <td>@{[ input 'fellow1Action' ]}</td>
          <td>@{[ input 'fellow1Words' ]}</td>
          <td>@{[ input 'fellow1Num' ]}</td>
          <td>@{[ input 'fellow1Note' ]}</td>
        </tr>
        <tr>
          <td class="number">6</td>
          <td>@{[ input 'fellow1-2Action' ]}</td>
          <td>@{[ input 'fellow1-2Words' ]}</td>
          <td>@{[ input 'fellow1-2Num' ]}</td>
          <td>@{[ input 'fellow1-2Note' ]}</td>
        </tr>
        <tr class="border-top">
          <td rowspan="2">⚂<br>⚃</td>
          <td class="number">8</td>
          <td>@{[ input 'fellow3Action' ]}</td>
          <td>@{[ input 'fellow3Words' ]}</td>
          <td>@{[ input 'fellow3Num' ]}</td>
          <td>@{[ input 'fellow3Note' ]}</td>
        </tr>
        <tr>
          <td class="number">5</td>
          <td>@{[ input 'fellow3-2Action' ]}</td>
          <td>@{[ input 'fellow3-2Words' ]}</td>
          <td>@{[ input 'fellow3-2Num' ]}</td>
          <td>@{[ input 'fellow3-2Note' ]}</td>
        </tr>
        <tr class="border-top">
          <td rowspan="2">⚄</td>
          <td class="number">9</td>
          <td>@{[ input 'fellow5Action' ]}</td>
          <td>@{[ input 'fellow5Words' ]}</td>
          <td>@{[ input 'fellow5Num' ]}</td>
          <td>@{[ input 'fellow5Note' ]}</td>
        </tr>
        <tr>
          <td class="number">4</td>
          <td>@{[ input 'fellow5-2Action' ]}</td>
          <td>@{[ input 'fellow5-2Words' ]}</td>
          <td>@{[ input 'fellow5-2Num' ]}</td>
          <td>@{[ input 'fellow5-2Note' ]}</td>
        </tr>
        <tr class="border-top">
          <td rowspan="2">⚅</td>
          <td class="number">10</td>
          <td>@{[ input 'fellow6Action' ]}</td>
          <td>@{[ input 'fellow6Words' ]}</td>
          <td>@{[ input 'fellow6Num' ]}</td>
          <td>@{[ input 'fellow6Note' ]}</td>
        </tr>
        <tr>
          <td class="number">3</td>
          <td>@{[ input 'fellow6-2Action' ]}</td>
          <td>@{[ input 'fellow6-2Words' ]}</td>
          <td>@{[ input 'fellow6-2Num' ]}</td>
          <td>@{[ input 'fellow6-2Note' ]}</td>
        </tr>
      </table>
      </div>
      <div class="box" id="f-note">
        <h2>備考</h2>
        <textarea name="fellowNote">$pc{'fellowNote'}</textarea>
      </div>
      </section>
      
      <section id="section-palette" style="display:none;">
      <div class="box">
        <h2>チャットパレット</h2>
        <p>
          手動パレットの配置:<select name="paletteInsertType" style="width: auto;">
            <option value="exchange" @{[ $pc{'paletteInsertType'} eq 'exchange'?'selected':'' ]}>プリセットと入れ替える</option>
            <option value="begin"    @{[ $pc{'paletteInsertType'} eq 'begin'   ?'selected':'' ]}>プリセットの手前に挿入</option>
            <option value="end"      @{[ $pc{'paletteInsertType'} eq 'end'     ?'selected':'' ]}>プリセットの直後に挿入</option>
          </select>
        </p>
        <textarea name="chatPalette" style="height:20em" placeholder="例）&#13;&#10;2d6+{冒険者}+{器用}&#13;&#10;&#13;&#10;※入力がない場合、プリセットがそのまま反映されます。">$pc{'chatPalette'}</textarea>
        
        <div class="palette-column">
        <h2>デフォルト変数 （自動的に末尾に出力されます）</h2>
        <textarea readonly style="height:20em">
HTML
  say $_ foreach(paletteProperties('','all'));
print <<"HTML";
</textarea>
          <label>@{[ input 'chatPalettePropertiesAll', 'checkbox']} 全ての変数を出力する</label><br>
          （デフォルトだと、未使用の変数は出力されません）
        </div>
        <div class="palette-column">
        <h2>プリセット （コピーペースト用）</h2>
        <textarea id="palettePreset" readonly style="height:20em"></textarea>
        <p>
          <label>@{[ input 'paletteUseVar', 'checkbox','palettePresetChange']}変数を使う</label>
          ／
          使用ダイスbot: <select name="paletteTool" onchange="palettePresetChange();" style="width:auto;">
          <option value="">ゆとチャadv.
          <option value="bcdice" @{[ $pc{'paletteTool'} eq 'bcdice' ? 'checked' : '']}>BCDice
          </select>
        </p>
        </div>
      </div>
      </section>
      <section id="section-color" style="display:none;">
      <h2>キャラクターシートのカラー設定</h2>
      <label class="box color-custom">
        <input type="checkbox" name="colorCustom" value="1" onchange="changeColor();" @{[ $pc{'colorCustom'} ? 'checked':'' ]}><i></i>キャラクターシートの色をカスタムする
      </label>
      <span class="box color-custom night-switch" onclick="nightModeChange()"><i></i>ナイトモード</span>
      <div class="box color-custom">
        <h2>見出し背景</h2>
        <table>
        <tr class="color-range-H"><th>色相</th><td><input type="range" name="colorHeadBgH" min="0" max="360" value="$pc{'colorHeadBgH'}" oninput="changeColor();"></td><td id="colorHeadBgHValue">$pc{'colorHeadBgH'}</td></tr>
        <tr class="color-range-S"><th>彩度</th><td><input type="range" name="colorHeadBgS" min="0" max="100" value="$pc{'colorHeadBgS'}" oninput="changeColor();"></td><td id="colorHeadBgSValue">$pc{'colorHeadBgS'}</td></tr>
        <tr class="color-range-L"><th>輝度</th><td><input type="range" name="colorHeadBgL" min="0" max="100" value="$pc{'colorHeadBgL'}" oninput="changeColor();"></td><td id="colorHeadBgLValue">$pc{'colorHeadBgL'}</td></tr>
        </table>
      </div>
      <div class="box color-custom">
        <h2>ベース背景</h2>
        <table>
        <tr class="color-range-H"><th>色相</th><td><input type="range" name="colorBaseBgH"  min="0" max="360" value="$pc{'colorBaseBgH'}" oninput="changeColor();"></td><td id="colorBaseBgHValue">$pc{'colorBaseBgH'}</td></tr>
        <tr class="color-range-S"><th>色の濃さ</th><td><input type="range" name="colorBaseBgS"  min="0" max="100" value="$pc{'colorBaseBgS'}" oninput="changeColor();"></td><td id="colorBaseBgSValue">$pc{'colorBaseBgS'}</td></tr>
        </table>
      </div>
      </section>
      
      
      @{[ input 'birthTime','hidden' ]}
      @{[ input 'id','hidden' ]}
    </form>
HTML
if($mode eq 'edit'){
print <<"HTML";
    <form name="del" method="post" action="./" class="deleteform">
      <p style="font-size: 80%;">
      <input type="hidden" name="mode" value="delete">
      <input type="hidden" name="id" value="$id">
      <input type="hidden" name="pass" value="$pass">
      <input type="checkbox" name="check1" value="1" required>
      <input type="checkbox" name="check2" value="1" required>
      <input type="checkbox" name="check3" value="1" required>
      <input type="submit" value="シート削除"><br>
      ※チェックを全て入れてください
      </p>
    </form>
HTML
  # 怒りの画像削除フォーム
  if($LOGIN_ID eq $set::masterid){
    print <<"HTML";
    <form name="imgdel" method="post" action="./" class="deleteform">
      <p style="font-size: 80%;">
      <input type="hidden" name="mode" value="img-delete">
      <input type="hidden" name="id" value="$id">
      <input type="hidden" name="pass" value="$pass">
      <input type="checkbox" name="check1" value="1" required>
      <input type="checkbox" name="check2" value="1" required>
      <input type="checkbox" name="check3" value="1" required>
      <input type="submit" value="画像削除"><br>
      </p>
    </form>
HTML
  }
}
print <<"HTML";
    </article>
  </main>
  <footer>
    『ソード・ワールド2.5』は、「グループSNE」及び「KADOKAWA」の著作物です。<br>
    　ゆとシートⅡ for SW2.5 ver.${main::ver} - ゆとらいず工房
  </footer>
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="その他">
    <option value="なし">
    <option value="不明">
    <option value="不詳">
  </datalist>
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
  <datalist id="list-language">
    <option value="交易共通語">
    <option value="地方語（）">
    <option value="神紀文明語">
    <option value="魔法文明語">
    <option value="魔動機文明語">
    <option value="エルフ語">
    <option value="ドワーフ語">
    <option value="グラスランナー語">
    <option value="シャドウ語">
    <option value="ソレイユ語">
    <option value="ミアキス語">
    <option value="リカント語">
    <option value="ドラゴン語">
    <option value="妖精語">
    <option value="海獣語">
    <option value="ヴァルグ語">
    <option value="汎用蛮族語">
    <option value="妖魔語">
    <option value="巨人語">
    <option value="ドレイク語">
    <option value="バジリスク語">
    <option value="ノスフェラトゥ語">
    <option value="マーマン語">
    <option value="ケンタウロス語">
    <option value="ライカンスロープ語">
    <option value="リザードマン語">
    <option value="ハルピュイア語">
    <option value="バルカン語">
    <option value="翼人語">
    <option value="魔神語">
  </datalist>
  <script>
  const AllClassOn = @{[ $set::all_class_on ? 1 : 0 ]};
  const battleItemOn = @{[ $set::battleitem ? 1 : 0 ]};
  const growType = '@{[ $set::growtype ? $set::growtype : 0 ]}';
HTML
print 'const featsLv = ["'. join('","', @set::feats_lv) . '"];';
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
  'footwork',
  'accuracyEnhance',
  'evasiveManeuver',
  'magicPowerEnhance',
  'alchemyEnhance',
  'shootersMartialArts',
  'tenacity',
  'capacity',
  'masteryMetalArmour',
  'masteryNonMetalArmour',
  'masteryShield',
  'masteryArtisan',
  'throwing',
  'songAddition',
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
print '"ガン（物理）","盾"];';
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
print "};\n";
## 技能
print 'const classes = {';
foreach my $key (keys %data::class) {
  print <<"HTML";
  '$data::class{$key}{'id'}' : {
    '2.0'       : '$data::class{$key}{'2.0'}',
    'expTable'  : '$data::class{$key}{'expTable'}',
    'eName'     : '$data::class{$key}{'eName'}',
    'magic'     : '$data::class{$key}{'magic'}{'eName'}',
    'magicData' : @{[ $data::class{$key}{'magic'}{'data'} ? 1 : 0 ]},
    'craft'     : '$data::class{$key}{'craft'}{'eName'}',
    'craftData' : @{[ $data::class{$key}{'craft'}{'data'} ? 1 : 0 ]},
    'craftStt'  : '$data::class{$key}{'craft'}{'stt'}',
    'craftPower': '$data::class{$key}{'craft'}{'power'}',
  },
HTML
}
print "};\n";
## 冒険者ランク
print 'const adventurerRank = {';
print " '' : { 'num':0, 'free':0 },";
foreach(@set::adventurer_rank){
  print "'@$_[0]' : { 'num': @$_[1], 'free':@$_[2] },";
}
print "};\n";
## 不名誉称号
print 'const notorietyRank = {';
foreach(@set::notoriety_rank){
  print "'@$_[0]' : { 'num': @$_[1] },";
}
print "};\n";
## 割り振り計算
print <<"HTML";
function calcPointBuy() {
  const A = Number(form.sttBaseA.value);
  const B = Number(form.sttBaseB.value);
  const C = Number(form.sttBaseC.value);
  const D = Number(form.sttBaseD.value);
  const E = Number(form.sttBaseE.value);
  const F = Number(form.sttBaseF.value);
  
  const _race = race.match(/ナイトメア/) ? 'ナイトメア' : race;
  
  let ptA;
  let ptB;
  let ptC;
  let ptD;
  let ptE;
  let ptF;
  
  if(race == ''){}
HTML
foreach my $key (keys %data::race_dices) {
  print "else if (_race === '$key'){ ";
  foreach ("A".."F"){
    my $x = $data::race_dices{$key}{$_};
    my $add = $data::race_dices{$key}{$_.'+'};
    print "pt$_ = point${x}($_" . ($add ? " - $add" : '') . "); ";
  } 
  print "}\n";
}
print <<"HTML";
  document.getElementById("stt-pointbuy-AtoF-value").innerHTML = ptA + ptB + ptC + ptD + ptE + ptF;
  
  if(form.birth.value === '冒険者'){
    let ptTec = pointx(Number(form.sttBaseTec.value));
    let ptPhy = pointx(Number(form.sttBasePhy.value));
    let ptSpi = pointx(Number(form.sttBaseSpi.value));
    document.getElementById("stt-pointbuy-TPS-value").innerHTML = ptTec + ptPhy + ptSpi;
  } else {
    document.getElementById("stt-pointbuy-TPS-value").innerHTML = '―';
  }
}
HTML
## チャットパレット
print <<"HTML";
  let palettePresetText       = `@{[ palettePreset    ('') ]}`;
  let palettePresetTextRaw    = `@{[ palettePresetRaw ('') ]}`;
  let palettePresetTextBcd    = `@{[ palettePreset    ('', 'bcdice') ]}`;
  let palettePresetTextBcdRaw = `@{[ palettePresetRaw ('', 'bcdice') ]}`;
  </script>
</body>

</html>
HTML

1;