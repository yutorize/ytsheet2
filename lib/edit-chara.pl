############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';
use Encode;

require './lib/palette-sub.pl';

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
require $set::data_craft;

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

$pc{'weaponNum'}     = $pc{'weaponNum'}     || 3;
$pc{'languageNum'}   = $pc{'languageNum'}   || 3;
$pc{'honorItemsNum'} = $pc{'honorItemsNum'} || 3;
$pc{'historyNum'}    = $pc{'historyNum'}    || 3;

$pc{'colorHeadBgH'} = $pc{'colorHeadBgH'} eq '' ? 225 : $pc{'colorHeadBgH'};
$pc{'colorHeadBgS'} = $pc{'colorHeadBgS'} eq '' ?   9 : $pc{'colorHeadBgS'};
$pc{'colorHeadBgL'} = $pc{'colorHeadBgL'} eq '' ?  56 : $pc{'colorHeadBgL'};
$pc{'colorBaseBgH'} = $pc{'colorBaseBgH'} eq '' ?   0 : $pc{'colorBaseBgH'};
$pc{'colorBaseBgS'} = $pc{'colorBaseBgS'} eq '' ?   0 : $pc{'colorBaseBgS'};
$pc{'colorBaseBgL'} = $pc{'colorBaseBgL'} eq '' ? 100 : $pc{'colorBaseBgL'};

if($pc{'colorCustom'} && $pc{'colorHeadBgA'}) {
  ($pc{'colorHeadBgH'}, $pc{'colorHeadBgS'}, $pc{'colorHeadBgL'}) = rgb_to_hsl($pc{'colorHeadBgR'},$pc{'colorHeadBgG'},$pc{'colorHeadBgB'});
  ($pc{'colorBaseBgH'}, $pc{'colorBaseBgS'}, undef) = rgb_to_hsl($pc{'colorBaseBgR'},$pc{'colorBaseBgG'},$pc{'colorBaseBgB'});
  $pc{'colorBaseBgS'} = $pc{'colorBaseBgS'} * $pc{'colorBaseBgA'} * 10;
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
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>@{[$mode eq 'edit'?"編集：$pc{'characterName'}":'新規作成']} - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="./skin/css/base.css?1.07.005">
  <link rel="stylesheet" media="all" href="./skin/css/sheet.css?1.07.005">
  <link rel="stylesheet" media="all" href="./skin/css/chara.css?1.07.005">
  <link rel="stylesheet" media="all" href="./skin/css/chara-sp.css?1.07.005">
  <link rel="stylesheet" media="all" href="./skin/css/edit.css?1.07.005">
  <script src="./lib/edit-chara.js?1.07.005" defer></script>
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.3.1/css/all.css" integrity="sha384-mzrmE5qonljUremFsqc01SB46JvROS7bZs3IO2EmfFsd15uHvIt+Y8vEf7N7fWAU" crossorigin="anonymous">
  <style>
    #image {
      background-image: url("${set::char_dir}${file}/image.$pc{'image'}") !important;
    }
  </style>
</head>
<body>
  <script src="./skin/js/common.js?1.06.002"></script>
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
          <div>キャラクター名@{[input('characterName','text','','required')]}</div>
          <div>二つ名　　　　@{[input('aka','text','','placeholder="漢字:ルビ"')]}</div>
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
  if ($mode eq 'edit' && $pc{'protect'} eq 'password') {
    print '<input type="hidden" name="pass" value="'.$pass.'"><br>';
  } else {
    print '<input type="password" name="pass"><br>';
  }
  print <<"HTML";
<input type="radio" name="protect" value="none"@{[ $pc{'protect'} eq 'none'?' checked':'' ]}> 保護しない（誰でも編集できるようになります）
      </p>
      </div>
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
        <div class="box" id="image" style="max-height:550px;">
          <h2>キャラクター画像</h2>
          <p>
            <input type="file" accept="image/*" name="imageFile"><br>
            ※ @{[ int($set::image_maxsize / 1024) ]}KBまでのJPG/PNG/GIF
          </p>
          <p>
            表示方式：<select name="imageFit" oninput="imagePosition()">
            <option value="cover"   @{[$pc{'imageFit'} eq 'cover'  ?'selected':'']}>枠いっぱいに表示
            <option value="contain" @{[$pc{'imageFit'} eq 'contain'?'selected':'']}>画像全体を表示
            <option value="unset"   @{[$pc{'imageFit'} eq 'unset'  ?'selected':'']}>拡大／縮小せず表示
            <option value="percent" @{[$pc{'imageFit'} eq 'percent'?'selected':'']}>拡大率を指定
            </select><br>
            <br>
            拡大率：@{[ input "imagePercent",'number','imagePosition','style="width:4em;"' ]}%<br>
            （「拡大率を指定」時／100で横幅ピッタリ）<br>
            <br>
            枠をはみ出る際の基準位置(50%が中心)<br>
            横@{[ input "imagePositionX",'number','imagePosition','style="width:4em;"' ]}% ／ 
            縦@{[ input "imagePositionY",'number','imagePosition','style="width:4em;"' ]}%
          </p>
          <p>
          画像の注釈（作者や権利表記など）
          @{[ input 'imageCopyright' ]}
          </p>
          <p>
            <input type="checkbox" name="imageDelete" value="1"> 画像を削除する
            @{[input('image','hidden')]}
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

        <dl class="box box-2row" id="sub-status">
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
        <div id="area-classes" @{[ $set::common_class_on ? '' : 'class="common-classes-off"' ]}>
          <div class="box" id="classes">
            <h2>技能</h2>
            <div>使用経験点：<span id="exp-use"></span></div>
            <dl>
              <dt id="classFig">ファイター        </dt><dd>@{[input('lvFig', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classGra">グラップラー      </dt><dd>@{[input('lvGra', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classFen">フェンサー        </dt><dd>@{[input('lvFen', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classSho">シューター        </dt><dd>@{[input('lvSho', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classSor">ソーサラー        </dt><dd>@{[input('lvSor', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classCon">コンジャラー      </dt><dd>@{[input('lvCon', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classPri">プリースト<select name="faithType" style="width:auto;">@{[ option 'faithType','†|<†セイクリッド系>','‡|<‡ヴァイス系>','†‡|<†‡両系統使用可>' ]}</select></dt><dd>@{[input('lvPri', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classFai">フェアリーテイマー</dt><dd>@{[input('lvFai', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classMag">マギテック        </dt><dd>@{[input('lvMag', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classSco">スカウト          </dt><dd>@{[input('lvSco', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classRan">レンジャー        </dt><dd>@{[input('lvRan', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classSag">セージ            </dt><dd>@{[input('lvSag', 'number','changeLv','min="0" max="17"')]}</dd>
            </dl>
            <dl>
              <dt id="classEnh">エンハンサー      </dt><dd>@{[input('lvEnh', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classBar">バード            </dt><dd>@{[input('lvBar', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classRid">ライダー          </dt><dd>@{[input('lvRid', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classAlc">アルケミスト      </dt><dd>@{[input('lvAlc', 'number','changeLv','min="0" max="17"')]}</dd>
HTML
if($set::all_class_on){
print <<"HTML";
              <dt id="classWar" class="zero-data">[2.0] ウォーリーダー    </dt><dd>@{[input('lvWar', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classMys" class="zero-data">[2.0] ミスティック      </dt><dd>@{[input('lvMys', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classDem" class="zero-data">[2.0] デーモンルーラー  </dt><dd>@{[input('lvDem', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classPhy" class="zero-data">[2.0] フィジカルマスター</dt><dd>@{[input('lvPhy', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classGri" class="zero-data">[2.0] グリモワール      </dt><dd>@{[input('lvGri', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classArt" class="zero-data">[2.0] アーティザン      </dt><dd>@{[input('lvArt', 'number','changeLv','min="0" max="17"')]}</dd>
              <dt id="classAri" class="zero-data">[2.0] アリストクラシー  </dt><dd>@{[input('lvAri', 'number','changeLv','min="0" max="17"')]}</dd>
HTML
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
            <dl id="mystic-arts-list">
HTML
$pc{'mysticArtsNum'} = 0 if !$set::mystic_arts_on;
foreach my $i(1 .. $pc{'mysticArtsNum'}){
  print '<dt>'.(input 'mysticArts'.$i).'</dt><dd>'.(input 'mysticArts'.$i.'Pt', 'number', 'calcHonor').'</dd>'
}
print <<"HTML";
            </dl>
            <div class="add-del-button"><a onclick="addMysticArts()">▼</a><a onclick="delMysticArts()">▲</a></div>
            @{[input('mysticArtsNum','hidden')]}
          </div>
        </div>
        <div id="crafts">
          <div class="box" id="magic-gramarye">
            <h2>秘奥魔法</h2>
            <ul>
HTML
foreach my $lv (1..17){
  print '<li id="magic-gramarye'.$lv.'"><select name="magicGramarye'.$lv.'">';
  print '<option></option>';
  foreach my $magic (@data::magic_gramarye){
    next if $lv < @$magic[0];
    print '<option'.(($pc{"magicGramarye$lv"} eq @$magic[1])?' selected':'').' value="'.@$magic[1].'">'.@$magic[1]."（@$magic[2]）";
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
          <div class="box" id="craft-enhance">
            <h2>練技</h2>
            <ul>
HTML
foreach my $lv (1..17){
  print '<li id="craft-enhance'.$lv.'"><select name="craftEnhance'.$lv.'">';
  print '<option></option>';
  foreach my $craft (@data::craft_enhance){
    next if $lv < @$craft[0];
    print '<option'.(($pc{"craftEnhance$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
          <div class="box" id="craft-song">
            <h2>呪歌</h2>
            <ul>
HTML
foreach my $lv (1..19){
  print '<li id="craft-song'.$lv.'"><select name="craftSong'.$lv.'">';
  print '<option></option>';
  foreach my $craft (@data::craft_song){
    next if $lv < @$craft[0];
    print '<option'.(($pc{"craftSong$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
          <div class="box" id="craft-riding">
            <h2>騎芸</h2>
            <ul>
HTML
foreach my $lv (1..17){
  print '<li id="craft-riding'.$lv.'"><select name="craftRiding'.$lv.'">';
  print '<option></option>';
  foreach my $craft (@data::craft_riding){
    next if $lv < @$craft[0];
    print '<option'.(($pc{"craftRiding$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
          <div class="box" id="craft-alchemy">
            <h2>賦術</h2>
            <ul>
HTML
foreach my $lv (1..17){
  print '<li id="craft-alchemy'.$lv.'"><select name="craftAlchemy'.$lv.'">';
  print '<option></option>';
  foreach my $craft (@data::craft_alchemy){
    next if $lv < @$craft[0];
    print '<option'.(($pc{"craftAlchemy$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
          <div class="box" id="craft-command">
            <h2>鼓咆</h2>
            <ul>
HTML
foreach my $lv (1..17){
  print '<li id="craft-command'.$lv.'"><select name="craftCommand'.$lv.'">';
  print '<option></option>';
  foreach my $craft (@data::craft_command){
    next if $lv < @$craft[0];
    print '<option'.(($pc{"craftCommand$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
          <div class="box" id="craft-divination">
            <h2>占瞳</h2>
            <ul>
HTML
foreach my $lv (1..17){
  print '<li id="craft-divination'.$lv.'"><select name="craftDivination'.$lv.'">';
  print '<option></option>';
  foreach my $craft (@data::craft_divination){
    next if $lv < @$craft[0];
    print '<option'.(($pc{"craftDivination$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
          <div class="box" id="craft-potential">
            <h2>魔装</h2>
            <ul>
HTML
foreach my $lv (1..17){
  print '<li id="craft-potential'.$lv.'"><select name="craftPotential'.$lv.'">';
  print '<option></option>';
  my %only;
  foreach my $craft (@data::craft_potential){
    next if $lv < @$craft[0];
    if(@$craft[2] =~ /^(.*?)専用/){
      $only{$1} .= '<option'.(($pc{"craftPotential$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
      next;
    }
    print '<option'.(($pc{"craftPotential$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
  }
  print "<optgroup label=\"ドレイク専用\">$only{'ドレイク'}</optgroup>";
  print "<optgroup label=\"バジリスク専用\">$only{'バジリスク'}</optgroup>";
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
          <div class="box" id="craft-seal">
            <h2>呪印</h2>
            <ul>
HTML
foreach my $lv (1..17){
  print '<li id="craft-seal'.$lv.'"><select name="craftSeal'.$lv.'">';
  print '<option></option>';
  foreach my $craft (@data::craft_seal){
    next if $lv < @$craft[0];
    print '<option'.(($pc{"craftSeal$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
  }
  print "</select></li>\n";
}
print <<"HTML";
            </ul>
          </div>
          <div class="box" id="craft-dignity">
            <h2>貴格</h2>
            <ul>
HTML
foreach my $lv (1..17){
  print '<li id="craft-dignity'.$lv.'"><select name="craftDignity'.$lv.'">';
  print '<option></option>';
  foreach my $craft (@data::craft_dignity){
    next if $lv < @$craft[0];
    print '<option'.(($pc{"craftDignity$lv"} eq @$craft[1])?' selected':'').'>'.@$craft[1];
  }
  print "</select></li>\n";
}
print <<"HTML";
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
            </table>
            <table id="package-ranger"@{[ display $pc{'lvRan'} ]}>
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
            </table>
            <table id="package-sage"@{[ display $pc{'lvSag'} ]}>
              <tr>
                <th>セージ技能</th>
                <th>知識</th>
                <td>+@{[ input 'packSagKnoAdd', 'number','calcPackage' ]}</td>
                <td id="package-sage-kno">$pc{'packSagKno'}</td>
              </tr>
            </table>
            <table id="package-rider"@{[ display $pc{'lvRid'} ]}>
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
            </table>
            <table id="package-alchemist"@{[ display $pc{'lvAlc'} ]}>
              <tr>
                <th>アルケミスト技能</th>
                <th>知識</th>
                <td>+@{[ input 'packAlcKnoAdd', 'number','calcPackage' ]}</td>
                <td id="package-alchemist-kno">$pc{'packAlcKno'}</td>
              </tr>
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
          <p>@{[ input 'languageAutoOff','checkbox','changeRace' ]}初期習得言語を自動記入しない</p>
          <div class="add-del-button"><a onclick="addLanguage()">▼</a><a onclick="delLanguage()">▲</a></div>
          @{[input('languageNum','hidden')]}
        </div>
        <div class="box" id="magic-power">
          <h2>魔力／奏力／他</h2>
          <table>
            <thead>
            <tr>
              <th></th><th>魔法</th><th>専用化</th><th>魔力修正</th><th></th>
            </tr>
            </thead>
            <tr>
              <th></th>
              <th>魔法全般</th>
              <td></td>
              <td>+@{[ input 'magicPowerAdd','number','calcMagic' ]}</td>
              <td></td>
            </tr>
            <tr@{[ display $pc{'lvSor'} ]} id="magic-power-sorcerer">
              <th>ソーサラー</th>
              <th>真語魔法</th>
              <td>@{[ input 'magicPowerOwnSor', 'checkbox','calcMagic' ]}知力+2</td>
              <td>+@{[ input 'magicPowerAddSor', 'number','calcMagic' ]}=</td>
              <td id="magic-power-sorcerer-value">0</td>
            </tr>
            <tr@{[ display $pc{'lvCon'} ]} id="magic-power-conjurer">
              <th>コンジャラー</th>
              <th>操霊魔法</th>
              <td>@{[ input 'magicPowerOwnCon', 'checkbox','calcMagic' ]}知力+2</td>
              <td>+@{[ input 'magicPowerAddCon', 'number','calcMagic' ]}=</td>
              <td id="magic-power-conjurer-value">0</td>
            </tr>
            <tr@{[ display $pc{'lvPri'} ]} id="magic-power-priest">
              <th>プリースト</th>
              <th>神聖魔法</th>
              <td>@{[ input 'magicPowerOwnPri', 'checkbox','calcMagic' ]}知力+2</td>
              <td>+@{[ input 'magicPowerAddPri', 'number','calcMagic' ]}=</td>
              <td id="magic-power-priest-value">0</td>
            </tr>
            <tr@{[ display $pc{'lvFai'} ]} id="magic-power-fairytamer">
              <th>フェアリーテイマー</th>
              <th>
                妖精魔法<br>
                属性: @{[ input 'ftElemental', 'text', '', 'placeholder="例）土／炎／風／光"' ]}
              </th>
              <td>@{[ input 'magicPowerOwnFai', 'checkbox','calcMagic' ]}知力+2</td>
              <td>+@{[ input 'magicPowerAddFai', 'number','calcMagic' ]}=</td>
              <td id="magic-power-fairytamer-value">0</td>
            </tr>
            <tr@{[ display $pc{'lvMag'} ]} id="magic-power-magitech">
              <th>マギテック</th>
              <th>魔動機術</th>
              <td>@{[ input 'magicPowerOwnMag', 'checkbox','calcMagic' ]}知力+2</td>
              <td>+@{[ input 'magicPowerAddMag', 'number','calcMagic' ]}=</td>
              <td id="magic-power-magitech-value">0</td>
            </tr>
            <tr@{[ display $pc{'lvDem'} ]} id="magic-power-demonruler">
              <th>デーモンルーラー</th>
              <th>召異魔法</th>
              <td>@{[ input 'magicPowerOwnDem', 'checkbox','calcMagic' ]}知力+2</td>
              <td>+@{[ input 'magicPowerAddDem', 'number','calcMagic' ]}=</td>
              <td id="magic-power-demonruler-value">0</td>
            </tr>
            <tr@{[ display $pc{'lvGri'} ]} id="magic-power-grimoir">
              <th>グリモワール</th>
              <th>秘奥魔法</th>
              <td>@{[ input 'magicPowerOwnGri', 'checkbox','calcMagic' ]}知力+2</td>
              <td>+@{[ input 'magicPowerAddGri', 'number','calcMagic' ]}=</td>
              <td id="magic-power-grimoir-value">0</td>
            </tr>
            <tr@{[ display $pc{'lvBar'} ]} id="magic-power-bard">
              <th>バード</th>
              <th>呪歌</th>
              <td>@{[ input 'magicPowerOwnBar', 'checkbox','calcMagic' ]}精神力+2</td>
              <td>+@{[ input 'magicPowerAddBar', 'number','calcMagic' ]}=</td>
              <td id="magic-power-bard-value">0</td>
            </tr>
            <tr@{[ display $pc{'lvAlc'} ]} id="magic-power-alchemist">
              <th>アルケミスト</th>
              <th>賦術</th>
              <td>@{[ input 'magicPowerOwnAlc', 'checkbox','calcMagic' ]}知力+2</td>
              <td>+@{[ input 'magicPowerAddAlc', 'number','calcMagic' ]}=</td>
              <td id="magic-power-alchemist-value">0</td>
            </tr>
            <tr@{[ display $pc{'lvMys'} ]} id="magic-power-mystic">
              <th>ミスティック</th>
              <th>占瞳</th>
              <td>@{[ input 'magicPowerOwnMys', 'checkbox','calcMagic' ]}知力+2</td>
              <td>+@{[ input 'magicPowerAddMys', 'number','calcMagic' ]}=</td>
              <td id="magic-power-mystic-value">0</td>
            </tr>
          </table>
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
          </table>
        </div>
        <div class="box" id="weapons">
          <table id="weapons-table">
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

foreach my $i (1 .. $pc{'weaponNum'}) {
print <<"HTML";
            <tr id="weapon-row$i" data-sort="$i">
              <td>@{[input("weapon${i}Name")]}<br><a class="switch-button" onclick="switchWeapon(${i})">⇕</a></td>
              <td>@{[input("weapon${i}Usage","text",'','list="list-usage"')]}</td>
              <td>@{[input("weapon${i}Reqd")]}</td>
              <td>+@{[input("weapon${i}Acc",'number','calcWeapon')]}=<b id="weapon${i}-acc-total">0</b></td>
              <td>@{[input("weapon${i}Rate")]}</td>
              <td>@{[input("weapon${i}Crit")]}</td>
              <td>+@{[input("weapon${i}Dmg",'number','calcWeapon')]}=<b id="weapon${i}-dmg-total">0</b></td>
              <td>@{[input("weapon${i}Own",'checkbox','calcWeapon')]}</td>
              <td><select id="in-weapon${i}Category" name="weapon${i}Category" oninput="calcWeapon()">@{[option("weapon${i}Category",@data::weapon_names,'ガン（物理）','盾')]}</select></td>
              <td><select id="in-weapon${i}Class" name="weapon${i}Class" oninput="calcWeapon()">@{[option("weapon${i}Class",'ファイター','グラップラー','フェンサー','シューター','エンハンサー','デーモンルーラー','自動計算しない')]}</select></td>
              <td>@{[input("weapon${i}Note",'','calcWeapon','placeholder="備考"')]}</td>
            </tr>
HTML
}
print <<"HTML";
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
            <tr>
              <th>技能・特技</th>
              <th>必筋<br>上限</th>
              <th>回避力</th>
              <th>防護点</th>
            </tr>
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
              <td>@{[input('armourOwn','checkbox','calcDefense')]}</td>
              <td>@{[input('armourNote')]}</td>
            </tr>
            <tr>
              <th>盾</th>
              <td>@{[input('shieldName')]}</td>
              <td>@{[input('shieldReqd')]}</td>
              <td>@{[input('shieldEva','number','calcDefense')]}</td>
              <td>@{[input('shieldDef','number','calcDefense')]}</td>
              <td>@{[input('shieldOwn','checkbox','calcDefense')]}</td>
              <td>@{[input('shieldNote')]}</td>
            </tr>
            <tr>
              <th>他</th>
              <td>@{[input('defOtherName')]}</td>
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
     $addbase =~ s/_//;
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
          " onChange=\"addAccessory(this,'@$_[1]')\">";
  }
  print "</td>\n";
  print <<"HTML";
  <th>@$_[0]</th>
  <td>@{[input('accessory'.@$_[1].'Name')]}</td>
  <td>
    <select id="accessory-@$_[1]" name="accessory@$_[1]Own" oninput="calcSubStt()">
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
            <table>
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
          <ul>
HTML
foreach my $i (1 .. 16){
  print '<li id="battle-item'.$i.'"><input type="text" name="battleItem'.$i.'" value="'.$pc{'battleItem'.$i}.'"></li>';
}
print <<"HTML";
          </ul>
          </div>
          <dl class="box" id="honor">
            <dt>名誉点</dt><dd id="honor-value">$pc{'honor'}</dd>
            <dt>ランク</dt>
            <dd><select name="rank" oninput="calcHonor()">@{[ option "rank",@set::adventurer_rank_name ]}</select></dd>
          </dl>
          <div class="box" id="honor-items">
            <table id="honor-items-table">
              <h2>名誉アイテム</h2>
              <tr><th></th><th>点数</th></tr>
              <tr><td class="center">冒険者ランク</td><td id="rank-honor-value">0</td></tr>
              <tr @{[ display $set::mystic_arts_on ]}><td class="center">秘伝</td><td id="mystic-arts-honor-value">0</td></tr>
HTML
foreach my $i (1 .. $pc{'honorItemsNum'}){
  print '<tr><td>'.(input "honorItem${i}", "text").'</td><td>'.(input "honorItem${i}Pt", "number", "calcHonor").'</td></tr>';
}
print <<"HTML";
            </table>
          <div class="add-del-button"><a onclick="addHonorItems()">▼</a><a onclick="delHonorItems()">▲</a></div>
          @{[ input 'honorItemsNum','hidden' ]}
          <p>フリー条件適用可能な（名誉点消費を0点にして良い）場合、<span class="evo">この表示</span>になります。</p>
          </div>
          <dl class="box" id="dishonor">
            <dt>不名誉点</dt><dd id="dishonor-value">0</dd>
            <dt>不名誉称号</dt><dd id="notoriety"></dd>
          </dl>
          <div class="box" id="dishonor-items">
            <table id="dishonor-items-table">
              <h2>不名誉詳細</h2>
              <tr><th></th><th>点数</th></tr>
HTML
foreach my $i (1 .. $pc{'dishonorItemsNum'}){
  print '<tr><td>'.(input "dishonorItem${i}", "text").'</td><td>'.(input "dishonorItem${i}Pt", "number", "calcDishonor").'</td></tr>';
}
print <<"HTML";
            </table>
          <div class="add-del-button"><a onclick="addDishonorItems()">▼</a><a onclick="delDishonorItems()">▲</a></div>
          @{[ input 'dishonorItemsNum','hidden' ]}
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
        <h4 onclick="view('text-format')">テキスト装飾・整形ルール（クリックで展開）▼</h4>
        <div class="annotate" id="text-format" style="display:none;">
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
        　　　　　　<code>:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|説明文2行目</code> 項目名を記入しないか、半角スペースで埋めると上と結合
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
            <td>@{[input("history${i}Date")]}<br><a class="switch-button" onclick="switchHistory(${i})">⇕</a></td>
            <td>@{[input("history${i}Title")]}</td>
            <td>@{[input("history${i}Exp",'text','calcExp')]}</td>
            <td>@{[input("history${i}Honor",'text','calcHonor')]}</td>
            <td>@{[input("history${i}Money",'text','calcCash')]}</td>
            <td>@{[input("history${i}Grow",'text','','list="list-grow"')]}</td>
            <td>@{[input("history${i}Gm")]}</td>
            <td>@{[input("history${i}Member")]}</td>
            <td>@{[input("history${i}Note",'','','placeholder="備考"')]}</td>
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
          <td>アルバート　ラミット　ブランデン<br>レンダ・レイ　ナイルベルト</td>
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
      
      <div class="box" id="free-history">
        <h2>履歴（自由記入）</h2>
        <textarea name="freeHistory">$pc{'freeHistory'}</textarea>
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
  say "//器用=$pc{'bonusDex'}";
  say "//敏捷=$pc{'bonusAgi'}";
  say "//筋力=$pc{'bonusStr'}";
  say "//生命=$pc{'bonusVit'}";
  say "//知力=$pc{'bonusInt'}";
  say "//精神=$pc{'bonusMnd'}";
  say "//DEX=$pc{'bonusDex'}";
  say "//AGI=$pc{'bonusAgi'}";
  say "//STR=$pc{'bonusStr'}";
  say "//VIT=$pc{'bonusVit'}";
  say "//INT=$pc{'bonusInt'}";
  say "//MND=$pc{'bonusMnd'}";
  say '';
  say "//生命抵抗=$pc{'vitResistTotal'}";
  say "//精神抵抗=$pc{'mndResistTotal'}";
  say "//HP=$pc{'hpTotal'}";
  say "//MP=$pc{'mpTotal'}";
  say '';
  say "//冒険者=$pc{'level'}";
  say "//LV=$pc{'level'}";
  foreach (
    ['Fig','ファイター'],
    ['Gra','グラップラー'],
    ['Fen','フェンサー'],
    ['Sho','シューター'],
    ['Sor','ソーサラー'],
    ['Con','コンジャラー'],
    ['Pri','プリースト'],
    ['Fai','フェアリーテイマー'],
    ['Mag','マギテック'],
    ['Sco','スカウト'],
    ['Ran','レンジャー'],
    ['Sag','セージ'],
    ['Enh','エンハンサー'],
    ['Bar','バード'],
    ['Rid','ライダー'],
    ['Alc','アルケミスト'],
    ['War','ウォーリーダー'],
    ['Mys','ミスティック'],
    ['Dem','デーモンルーラー'],
    ['Phy','フィジカルマスター'],
    ['Gri','グリモワール'],
    ['Ari','アリストクラシー'],
    ['Art','アーティザン'],
  ){
    next if !$pc{'lv'.@$_[0]};
    say "//@$_[1]=$pc{'lv'.@$_[0]}";
    say "//".uc(@$_[0])."=$pc{'lv'.@$_[0]}";
  }
  say '';
  say "//魔物知識=$pc{'monsterLore'}" if $pc{'monsterLore'};
  say "//先制力=$pc{'initiative'}" if $pc{'initiative'};
  say "//スカウト技巧=$pc{'packScoTec'}" if $pc{'packScoTec'};
  say "//スカウト運動=$pc{'packScoAgi'}" if $pc{'packScoAgi'};
  say "//スカウト観察=$pc{'packScoObs'}" if $pc{'packScoObs'};
  say "//レンジャー技巧=$pc{'packRanTec'}" if $pc{'packRanTec'};
  say "//レンジャー運動=$pc{'packRanAgi'}" if $pc{'packRanAgi'};
  say "//レンジャー観察=$pc{'packRanObs'}" if $pc{'packRanObs'};
  say "//セージ知識=$pc{'packSagKno'}" if $pc{'packSagKno'};
  say "//バード知識=$pc{'packBarKno'}" if $pc{'packBarKno'};
  say "//ライダー運動=$pc{'packRidAgi'}" if $pc{'packRidAgi'};
  say "//ライダー知識=$pc{'packRidKno'}" if $pc{'packRidKno'};
  say "//ライダー観察=$pc{'packRidObs'}" if $pc{'packRidObs'};
  say "//アルケミスト知識=$pc{'packAlcKno'}" if $pc{'packAlcKno'};
  say '';
  
  foreach (
    ['Sor', '真語魔法'],
    ['Con', '操霊魔法'],
    ['Pri', '神聖魔法'],
    ['Mag', '魔動機術'],
    ['Fai', '妖精魔法'],
    ['Dem', '召異魔法'],
    ['Gri', '秘奥魔法'],
    ['Bar', '呪歌'],
    ['Alc', '賦術'],
    ['Mys', '占瞳'],
  ){
    next if !$pc{'lv'.@$_[0]};
    say "//@$_[1]=$pc{'magicPower'.@$_[0]}";
  }
  say '';
  
  foreach (1 .. $pc{'weaponNum'}){
    next if $pc{'weapon'.$_.'Name'}.$pc{'weapon'.$_.'Usage'}.$pc{'weapon'.$_.'Reqd'}.
            $pc{'weapon'.$_.'Acc'}.$pc{'weapon'.$_.'Rate'}.$pc{'weapon'.$_.'Crit'}.
            $pc{'weapon'.$_.'Dmg'}.$pc{'weapon'.$_.'Own'}.$pc{'weapon'.$_.'Note'}
            eq '';
    say "//武器$_=$pc{'weapon'.$_.'Name'}";
    say "//命中$_=$pc{'weapon'.$_.'AccTotal'}";
    say "//威力$_=$pc{'weapon'.$_.'Rate'}";
    say "//C値$_=$pc{'weapon'.$_.'Crit'}";
    say "//追加D$_=$pc{'weapon'.$_.'DmgTotal'}";
    say '';
  }
  say "//回避=$pc{'DefenseTotalAllEva'}";
  say "//防護=$pc{'DefenseTotalAllDef'}";
print <<"HTML";
</textarea>
        <p><label>@{[ input 'chatPaletteUnusedHidden', 'checkbox']} 未使用の変数は出力しない</label></p>
        </div>
        <div class="palette-column">
        <h2>プリセット （コピーペースト用）</h2>
        <textarea id="palettePreset" readonly style="height:20em">@{[ palettePresetRaw(param('type')) ]}</textarea>
        <p><label><input type="checkbox" name="paletteUseVar" @{[ $pc{'paletteUseVar'}?'checked':'' ]} value="1">変数を使う</label></p>
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
    <form name="del" method="post" action="./" id="deleteform">
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
  </script>
</body>

</html>
HTML

1;