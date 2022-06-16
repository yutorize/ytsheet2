############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
my @negai = ('究明','守護','正裁','破壊','復讐','奉仕','享楽','功名','善行','無垢');
my %negai = (
  '究明' => {'out' => {'endurance' => 5,'operation' => 5}, 'in' => {'endurance' => 4,'operation' => 2}},
  '守護' => {'out' => {'endurance' =>13,'operation' => 1}, 'in' => {'endurance' => 6,'operation' => 1}},
  '正裁' => {'out' => {'endurance' => 7,'operation' => 4}, 'in' => {'endurance' => 4,'operation' => 2}},
  '破壊' => {'out' => {'endurance' => 9,'operation' => 3}, 'in' => {'endurance' => 6,'operation' => 1}},
  '復讐' => {'out' => {'endurance' =>11,'operation' => 2}, 'in' => {'endurance' => 6,'operation' => 1}},
  '奉仕' => {'out' => {'endurance' => 9,'operation' => 3}, 'in' => {'endurance' => 4,'operation' => 2}},
  '享楽' => {'out' => {'endurance' =>11,'operation' => 2}, 'in' => {'endurance' => 6,'operation' => 1}},
  '功名' => {'out' => {'endurance' => 7,'operation' => 4}, 'in' => {'endurance' => 4,'operation' => 2}},
  '善行' => {'out' => {'endurance' => 5,'operation' => 5}, 'in' => {'endurance' => 4,'operation' => 2}},
  '無垢' => {'out' => {'endurance' => 9,'operation' => 3}, 'in' => {'endurance' => 2,'operation' => 3}},
);

### データ読み込み ###################################################################################
my ($data, $mode, $file, $message) = pcDataGet($::in{'mode'});
our %pc = %{ $data };

my $mode_make = ($mode =~ /^(blanksheet|copy|convert)$/) ? 1 : 0;

### 出力準備 #########################################################################################
if($message){
  my $name = tag_unescape($pc{'characterName'} || $pc{'aka'} || '無題');
  $message =~ s/<!NAME>/$name/;
}
### プレイヤー名 --------------------------------------------------
if($mode_make && !$::make_error){
  $pc{'playerName'} = (getplayername($LOGIN_ID))[0];
}
### 初期設定 --------------------------------------------------
if($mode_make){ $pc{'protect'} ||= $LOGIN_ID ? 'account' : 'password'; }

if($mode eq 'edit' || ($mode eq 'convert' && $pc{'ver'})){
  %pc = data_update_chara(\%pc);
  if($pc{'updateMessage'}){
    $message .= "<hr>" if $message;
    $message .= "<h2>アップデート通知</h2><dl>";
    foreach (sort keys %{$pc{'updateMessage'}}){
      $message .= '<dt>'.$_.'</dt><dd>'.$pc{'updateMessage'}{$_}.'</dd>';
    }
    (my $lasttimever = $pc{'lasttimever'}) =~ s/([0-9]{3})$/\.$1/;
    $message .= "</dl><small>前回保存時のバージョン:$lasttimever</small>";
  }
}
elsif($mode eq 'blanksheet' && !$::make_error){
  $pc{'group'} = $set::group_default;
  
  $pc{'endurancePreGrow'} = $set::make_endurance || 0;
  $pc{'operationPreGrow'} = $set::make_operation || 0;
  
  $pc{'partner1Auto'} = 1;
  $pc{'partner2Auto'} = 1;
  
  $pc{'paletteUseBuff'} = 1;
}

$pc{'imageFit'} = $pc{'imageFit'} eq 'percent' ? 'percentX' : $pc{'imageFit'};
$pc{'imagePercent'} = $pc{'imagePercent'} eq '' ? '200' : $pc{'imagePercent'};
$pc{'imagePositionX'} = $pc{'imagePositionX'} eq '' ? '50' : $pc{'imagePositionX'};
$pc{'imagePositionY'} = $pc{'imagePositionY'} eq '' ? '50' : $pc{'imagePositionY'};
$pc{'wordsX'} ||= '右';
$pc{'wordsY'} ||= '上';

$pc{'colorHeadBgH'} = $pc{'colorHeadBgH'} eq '' ? 225 : $pc{'colorHeadBgH'};
$pc{'colorHeadBgS'} = $pc{'colorHeadBgS'} eq '' ?   9 : $pc{'colorHeadBgS'};
$pc{'colorHeadBgL'} = $pc{'colorHeadBgL'} eq '' ?  65 : $pc{'colorHeadBgL'};
$pc{'colorBaseBgH'} = $pc{'colorBaseBgH'} eq '' ? 210 : $pc{'colorBaseBgH'};
$pc{'colorBaseBgS'} = $pc{'colorBaseBgS'} eq '' ?   0 : $pc{'colorBaseBgS'};
$pc{'colorBaseBgL'} = $pc{'colorBaseBgL'} eq '' ? 100 : $pc{'colorBaseBgL'};

$pc{'historyNum'} ||= 3;
$pc{'kizunaNum'}  ||= 3;
$pc{'kizuatoNum'} ||= 2;

### 改行処理 --------------------------------------------------
foreach (
  'words',
  'freeNote',
  'freeHistory',
  'chatPalette',
  'partner1Memory',
  'partner2Memory',
){
  $pc{$_} =~ s/&lt;br&gt;/\n/g;
}

### フォーム表示 #####################################################################################
my $titlebarname = tag_delete name_plain tag_unescape ($pc{'characterName'}||"“$pc{'aka'}”");
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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/kiz/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/kiz/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/kiz/edit-chara.js?${main::ver}" defer></script>
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.15.4/css/all.css" integrity="sha384-DyZ88mC6Up2uqS4h/KRgHuoeGwBcD4Ng9SiP4dIRy0EXTlnuz47vAwmeGwVChigm" crossorigin="anonymous">
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
      <form name="sheet" method="post" action="./" enctype="multipart/form-data">
      <input type="hidden" name="ver" value="${main::ver}">
HTML
if($mode_make){
  print '<input type="hidden" name="_token" value="'.token_make().'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      
      <div id="header-menu">
        <h2><span></span></h2>
        <ul>
          <li onclick="sectionSelect('common');"><span>キャラクター</span><span>データ</span></li>
          <li onclick="sectionSelect('palette');"><span>チャット</span><span>パレット</span></li>
          <li onclick="sectionSelect('color');"><span>カラー</span><span>カスタム</span></li>
          <li class="button">
HTML
if($mode eq 'edit'){
print <<"HTML";
            <input type="button" value="複製" onclick="window.open('./?mode=copy&id=$::in{'id'}@{[  $::in{'log'}?"&log=$::in{'log'}":'' ]}');">
HTML
}
print <<"HTML";
            <input type="submit" value="保存">
          </li>
        </ul>
      </div>

      <aside class="message">$message</aside>
      
      <section id="section-common">
      <div class="box" id="name-form">
        <div>
          <dl id="character-name">
            <dt>キャラクター名</dt>
            <dd>@{[input('characterName','text',"nameSet",'required')]}</dd>
            <dt class="ruby">ふりがな</dt>
            <dd>@{[input('characterNameRuby','text',"nameSet")]}</dd>
          </dl>
        </div>
        <dl id="player-name">
          <dt>プレイヤー名</dt>
          <dd>@{[input('playerName')]}</dd>
        </dl>
      </div>
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
  if ($mode eq 'edit' && $pc{'protect'} eq 'password' && $::in{'pass'}) {
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
            <option value="">内容を全て開示する
            <option value="battle" @{[ $pc{'forbidden'} eq 'battle' ? 'selected' : '' ]}>データ・数値のみ秘匿する
            <option value="all"    @{[ $pc{'forbidden'} eq 'all'    ? 'selected' : '' ]}>内容を全て秘匿する
          </select>
        </dd>
        <dd id="hide-checkbox">
          <select name="hide">
            <option value="">一覧に表示
            <option value="1" @{[ $pc{'hide'} ? 'selected' : '' ]}>一覧には非表示
          </select>
          ※タグ検索結果・マイリストには表示されます
        </dd>
      </dl>
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
      <details class="box" id="regulation" @{[$mode eq 'edit' ? '':'open']} style="display:none">
        <summary>作成レギュレーション</summary>
        <dl>
          <dt>初期成長</dt>
          <dd id="level-pre-grow"></dd>
          <dt>耐久値+</dt>
          <dd>@{[input("endurancePreGrow",'number','changeRegu','step="2"'.($set::make_fix?' readonly':''))]}</dd>
          <dt>作戦力+</dt>
          <dd>@{[input("operationPreGrow",'number','changeRegu','step="1"'.($set::make_fix?' readonly':''))]}</dd>
        </dl>
      </details>
      <div id="area-status">
        @{[ image_form("${set::char_dir}${file}/image.$pc{'image'}?$pc{'imageUpdate'}") ]}

        <div id="classes" class="box">
        <h2>種別／ネガイ／能力値</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th></th>
                <th></th>
                <th>耐久値</th>
                <th>作戦力</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th>種別</th>
                <td><select name="class" oninput="changeType();">@{[option "class",'ハウンド','オーナー']}</select></td>
                <td>@{[ input 'enduranceType','number','calcStt', "readonly tabindex='-1'" ]}</td>
                <td>@{[ input 'operationType','number','calcStt', "readonly tabindex='-1'" ]}</td>
              </tr>
              <tr>
                <th>ネガイ(表)</th>
                <td>@{[ selectInput "negaiOutside","changeNegai('Out',this.value)",@negai ]}</td>
                <td>@{[ input 'enduranceOutside','number','calcStt' ]}</td>
                <td>@{[ input 'operationOutside','number','calcStt' ]}</td>
              </tr>
              <tr>
                <th>ネガイ(裏)</th>
                <td>@{[ selectInput "negaiInside","changeNegai('In',this.value)",@negai ]}</td>
                <td>@{[ input 'enduranceInside','number','calcStt' ]}</td>
                <td>@{[ input 'operationInside','number','calcStt' ]}</td>
              </tr>
              <tr>
                <th colspan="2">成長</th>
                <td id="endurance-grow"></td>
                <td id="operation-grow"></td>
              </tr>
              <tr>
                <th colspan="2">その他修正</th>
                <td>@{[ input 'enduranceAdd','number','calcStt' ]}</td>
                <td>@{[ input 'operationAdd','number','calcStt' ]}</td>
              </tr>
              <tr class="total">
                <th colspan="2">合計</th>
                <td id="endurance-total"></td>
                <td id="operation-total"></td>
              </tr>
            </tbody>
          </table>
        </div>

        <div id="hitogara" class="box">
          <h2>ヒトガラ</h2>
          <table class="edit-table">
            <tr>
              <th>年齢</th><td>@{[input "age"]}</td>
              <th>性別</th><td>@{[input "gender",'','','list="list-gender"']}</td>
            </tr>
            <tr>
              <th>過去</th>
              <td colspan="3">@{[input "past"]}</td>
            </tr>
            <tr>
              <th>
                <span class="h-only">遭遇</span>
                <span class="o-only">経緯</span>
              </th>
              <td colspan="3">@{[input "background"]}</td>
            </tr>
            <tr>
              <th>外見の特徴</th>
              <td colspan="3">@{[input "appearance"]}</td>
            </tr>
            <tr>
              <th>
                <span class="h-only">ケージ</span>
                <span class="o-only">住居</span>
              </th>
              <td colspan="3">@{[input "dwelling"]}</td>
            </tr>
            <tr>
              <th>好きなもの</th>
              <td colspan="3">@{[input "like"]}</td>
            </tr>
            <tr>
              <th>嫌いなもの</th>
              <td colspan="3">@{[input "dislike"]}</td>
            </tr>
            <tr>
              <th>得意なこと</th>
              <td colspan="3">@{[input "good"]}</td>
            </tr>
            <tr>
              <th>苦手なこと</th>
              <td colspan="3">@{[input "notgood"]}</td>
            </tr>
            <tr>
              <th>喪失</th>
              <td colspan="3">@{[input "missing"]}</td>
            </tr>
            <tr>
              <th>
                <span class="h-only thin">リミッターの影響</span>
                <span class="o-only thin">ペアリングの副作用</span>
              </th>
              <td colspan="3">@{[input "sideeffect"]}</td>
            </tr>
            <tr>
              <th>
                <span class="h-only">決意</span>
                <span class="o-only">使命</span>
              </th>
              <td colspan="3">@{[input "resolution"]}</td>
            </tr>
            <tr>
              <th>所属</th>
              <td colspan="3">@{[input "belong",'','','list="list-belong"']}</td>
            </tr>
            <tr>
              <th>おもな武器</th>
              <td colspan="3">@{[input "weapon"]}</td>
            </tr>
          </table>
        </div>
      </div>
      
      <div class="box partner-edit">
        <h2>パートナー</h2>
        <div class="partner-table" id="partner1area">
          <dl class="partner-data">
            <dt>相手</dt>
            <dd>
              <dl>
                <dt>名前</dt>
                <dd>@{[ input 'partner1Name' ]}</dd>
                
                <dt>URL<small>（@{[ input 'partner1Auto','checkbox','autoInputPartner(1)' ]}相手のデータを自動入力）</small></dt>
                <dd>@{[ input 'partner1Url','url','autoInputPartner(1)' ]}</dd>
                
                <dt>年齢</dt>
                <dd>@{[ input 'partner1Age' ]}</dd>
                
                <dt>性別</dt>
                <dd>@{[ input 'partner1Gender' ]}</dd>
                
                <dt>ネガイ（表）</dt>
                <dd>@{[ input 'partner1NegaiOutside' ]}</dd>
                
                <dt>ネガイ（裏）</dt>
                <dd>@{[ input 'partner1NegaiInside' ]}</dd>
                
                <dt>リリースの方法</dt>
                <dd>@{[ input 'partner1Release' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-from">
            <dt>自分の<br>マーカー</dt>
            <dd>
              <select name="partnerOrder" oninput="autoInputPartner(1)" style="width:auto;">
                <option value="1">パートナー１
                <option value="2">パートナー２
              </select>※相手から見て
            </dd>
            <dd>
              <dl>
                <dt>位置</dt><dd>@{[ input 'fromPartner1MarkerPosition','','','list="list-marker-position"' ]}</dd>
                <dt>色</dt><dd>@{[ input 'fromPartner1MarkerColor','','','list="list-marker-color"' ]}</dd>
                <dt>相手からの感情1</dt><dd>@{[ input 'fromPartner1Emotion1','','','list="list-emotion1"' ]}</dd>
                <dt>相手からの感情2</dt><dd>@{[ input 'fromPartner1Emotion2','','','list="list-emotion2"' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-to">
            <dt>相手の<br>マーカー</dt>
            <dd>※相手のシートへ表示される内容</dd>
            <dd>
              <dl>
                <dt>位置</dt><dd>@{[ input 'toPartner1MarkerPosition','','','list="list-marker-position"' ]}</dd>
                <dt>色</dt><dd>@{[ input 'toPartner1MarkerColor','','','list="list-marker-color"' ]}</dd>
                <dt>相手への感情1</dt><dd>@{[ input 'toPartner1Emotion1','','','list="list-emotion1"' ]}</dd>
                <dt>相手への感情2</dt><dd>@{[ input 'toPartner1Emotion2','','','list="list-emotion2"' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-promise">
            <dt>最初の<br>思い出</dt>
            <dd><textarea name="partner1Memory">$pc{'partner1Memory'}</textarea></dd>
          </dl>
        </div>
      </div>
      
      <div class="box partner-edit">
        <h2 id="head-partner2">@{[ input 'partner2On','checkbox','togglePartner2' ]}<span class="h-only">アナザー</span><span class="o-only">パートナー２</span></h2>
        <div class="partner-table" id="partner2area">
          <dl class="partner-data">
            <dt>相手</dt>
            <dd>
              <dl>
                <dt>名前</dt>
                <dd>@{[ input 'partner2Name' ]}</dd>
                
                <dt>URL<small>（@{[ input 'partner2Auto','checkbox','autoInputPartner(2)' ]}相手のデータを自動入力）</small></dt>
                <dd>@{[ input 'partner2Url','url','autoInputPartner(2)' ]}</dd>
                
                <dt>年齢</dt>
                <dd>@{[ input 'partner2Age' ]}</dd>
                
                <dt>性別</dt>
                <dd>@{[ input 'partner2Gender' ]}</dd>
                
                <dt>ネガイ（表）</dt>
                <dd>@{[ input 'partner2NegaiOutside' ]}</dd>
                
                <dt>ネガイ（裏）</dt>
                <dd>@{[ input 'partner2NegaiInside' ]}</dd>

                <dt>リリースの方法</dt>
                <dd>@{[ input 'partner2Release' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-from">
            <dt>自分の<br>マーカー</dt>
            <dd></dd>
            <dd>
              <dl>
                <dt class="o-only">位置</dt>
                <dd class="o-only">@{[ input 'fromPartner2MarkerPosition','','','list="list-marker-position"' ]}</dd>
                <dt class="o-only">色</dt>
                <dd class="o-only">@{[ input 'fromPartner2MarkerColor','','','list="list-marker-color"' ]}</dd>
                <dt>相手からの感情1</dt><dd>@{[ input 'fromPartner2Emotion1','','','list="list-emotion1"' ]}</dd>
                <dt>相手からの感情2</dt><dd>@{[ input 'fromPartner2Emotion2','','','list="list-emotion2"' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-to">
            <dt>相手の<br>マーカー</dt>
            <dd>※相手のシートへ表示される内容</dd>
            <dd>
              <dl>
                <dt class="o-only">位置</dt>
                <dd class="o-only">@{[ input 'toPartner2MarkerPosition','','','list="list-marker-position"' ]}</dd>
                <dt class="o-only">色</dt>
                <dd class="o-only">@{[ input 'toPartner2MarkerColor','','','list="list-marker-color"' ]}</dd>
                <dt>相手への感情1</dt><dd>@{[ input 'toPartner2Emotion1','','','list="list-emotion1"' ]}</dd>
                <dt>相手への感情2</dt><dd>@{[ input 'toPartner2Emotion2','','','list="list-emotion2"' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-promise">
            <dt><span class="h-only">協定</span><span class="o-only">最初の<br>思い出</span></dt>
            <dd><textarea name="partner2Memory">$pc{'partner2Memory'}</textarea></dd>
          </dl>
        </div>
      </div>
      
      <div class="box" id="kizuna">
        <h2>キズナ</h2>
        @{[input 'kizunaNum','hidden']}
        <table class="edit-table no-border-cells" id="kizuna-table">
          <thead>
            <tr>
              <th></th>
              <th>物・人・場所など</th>
              <th>感情・思い出など</th>
              <th>ヒビ</th>
              <th>ワレ</th>
            </tr>
          </thead>
          <tbody>
HTML
foreach my $num (1 .. $pc{'kizunaNum'}) {
print <<"HTML";
            <tr id="kizuna${num}" class="@{[ $pc{"kizuna${num}Hibi"} ? 'hibi':'' ]}@{[ $pc{"kizuna${num}Ware"} ? 'ware':'' ]}">
              <td class="handle"></td>
              <td>@{[ input "kizuna${num}Name" ]}</td>
              <td>@{[ input "kizuna${num}Note" ]}</td>
              <td>@{[ input "kizuna${num}Hibi", 'checkbox', "checkHibi(${num})" ]}</td>
              <td>@{[ input "kizuna${num}Ware", 'checkbox', "checkWare(${num})" ]}</td>
            </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addKizuna()">▼</a><a onclick="delKizuna()">▲</a></div>
      </div>

      <div class="box" id="shougou">
        <h2>傷号</h2>
        <dl>
          <dt>1</dt><dd>@{[ input "shougou1" ]}</dd>
          <dt>2</dt><dd>@{[ input "shougou2" ]}</dd>
          <dt>3</dt><dd>@{[ input "shougou3" ]}</dd>
        </dl>
      </div>

      <div class="box" id="kizuato">
        <h2>キズアト</h2>
        @{[input 'kizuatoNum','hidden']}
          <table class="edit-table line-tbody no-border-cells" id="kizuato-table">
            <colgroup>
              <col>
              <col>
              <col>
              <col>
              <col>
              <col>
            </colgroup>
HTML
foreach my $num (1 .. $pc{'kizuatoNum'}) {
print <<"HTML";
            <tbody id="kizuato${num}">
              <tr>
                <td class="name" colspan="6">名称:《@{[input "kizuato${num}Name"]}》</td>
              </tr>
              <tr>
                <th rowspan="2">ドラマ</th>
                <th>ヒトガラ</th>
                <th>タイミング</th>
                <th>対象</th>
                <th>制限</th>
                <th class="left">解説</th>
              </tr>
              <tr>
                <td>@{[input "kizuato${num}DramaHitogara"]}</td>
                <td>@{[input "kizuato${num}DramaTiming" ,'','','list="list-dtiming"']}</td>
                <td>@{[input "kizuato${num}DramaTarget" ,'','','list="list-dtarget"']}</td>
                <td>@{[input "kizuato${num}DramaLimited",'','','list="list-dlimited"']}</td>
                <td class="left">@{[input "kizuato${num}DramaNote"]}</td>
             </tr>
             <tr>
               <th rowspan="2">決戦</th>
               <th>タイミング</th>
               <th>対象</th>
               <th>代償</th>
               <th>制限</th>
               <th class="left">解説</th>
             </tr>
             <tr>
                <td>@{[input "kizuato${num}BattleTiming" ,'','','list="list-btiming"']}</td>
                <td>@{[input "kizuato${num}BattleTarget" ,'','','list="list-btarget"']}</td>
                <td>@{[input "kizuato${num}BattleCost"   ,'','','list="list-bcost"']}</td>
                <td>@{[input "kizuato${num}BattleLimited",'','','list="list-blimited"']}</td>
                <td class="left">@{[input "kizuato${num}BattleNote"]}</td>
            </tr>
          </tbody>
HTML
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addKizuato()">▼</a><a onclick="delKizuato()">▲</a></div>
      </div>
      
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
        <hr>
        ※以下は一部の複数行の欄でのみ有効です。<br>
        （有効な欄：「容姿・経歴・その他メモ」「履歴（自由記入）」）<br>
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
        折り畳み：行頭に<code>[>]項目名</code>：以降のテキストがすべて折り畳みになります。<br>
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
        <table class="edit-table line-tbody no-border-cells" id="history-table">
          <thead>
          <tr>
            <th></th>
            <th>日付</th>
            <th>タイトル</th>
            <th>成長</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
          <tr>
            <td>-</td>
            <td></td>
            <td>キャラクター作成</td>
            <td id="history0-exp">$pc{'history0Exp'}</td>
          </tr>
          </thead>
HTML
foreach my $num (1 .. $pc{'historyNum'}) {
print <<"HTML";
          <tbody id="history${num}">
          <tr>
            <td rowspan="2" class="handle"></td>
            <td rowspan="2">@{[ input"history${num}Date" ]}</td>
            <td rowspan="2">@{[ input"history${num}Title" ]}</td>
            <td><select name="history${num}Grow" oninput="calcGrow()">@{[ option "history${num}Grow",'endurance|<耐久値+2>','operation|<作戦力+1>' ]}</select></td>
            <td>@{[ input "history${num}Gm" ]}</td>
            <td>@{[ input "history${num}Member" ]}</td>
          </tr>
          <tr><td colspan="5" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}</td></tr>
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
        <table class="example edit-table line-tbody no-border-cells">
          <thead>
          <tr>
            <th></th>
            <th>日付</th>
            <th>タイトル</th>
            <th>成長</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
          </thead>
          <tbody>
          <tr>
            <td>-</td>
            <td><input type="text" value="2017-04-07" disabled></td>
            <td><input type="text" value="第一話「記入例」" disabled></td>
            <td><select disabled><option><option>耐久値+2<option selected>作戦力+1</select></td>
            <td class="gm"><input type="text" value="サンプルGM" disabled></td>
            <td class="member"><input type="text" value="イユ　黒崎武" disabled></td>
          </tr>
          </tbody>
        </table>
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
        <textarea name="chatPalette" style="height:20em" placeholder="例）&#13;&#10;2d6+{冒険者}+{器用}&#13;&#10;&#13;&#10;※入力がない場合、プリセットが自動的に反映されます。">$pc{'chatPalette'}</textarea>
        
        <div class="palette-column">
        <h2>デフォルト変数 （自動的に末尾に出力されます）</h2>
        <textarea id="paletteDefaultProperties" readonly style="height:20em">
HTML
  say $_ foreach(paletteProperties());
print <<"HTML";
</textarea>
        <p>
          <label>@{[ input 'chatPalettePropertiesAll', 'checkbox']} 全ての変数を出力する</label><br>
          （デフォルトだと、未使用の変数は出力されません）
        </p>
        </div>
        <div class="palette-column">
        <h2>プリセット （コピーペースト用）</h2>
        <textarea id="palettePreset" readonly style="height:20em"></textarea>
        <p>
          <label>@{[ input 'paletteUseVar', 'checkbox','palettePresetChange']}デフォルト変数を使う</label>
          ／
          <label>@{[ input 'paletteUseBuff', 'checkbox','palettePresetChange']}バフデバフ用変数を使う</label>
          <br>
          使用ダイスbot: <select name="paletteTool" onchange="palettePresetChange();" style="width:auto;">
          <option value="">ゆとチャadv.
          <option value="bcdice" @{[ $pc{'paletteTool'} eq 'bcdice' ? 'selected' : '']}>BCDice
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
      <input type="hidden" name="id" value="$::in{'id'}">
    </form>
HTML
if($mode eq 'edit'){
print <<"HTML";
    <form name="del" method="post" action="./" class="deleteform">
      <p style="font-size: 80%;">
      <input type="hidden" name="mode" value="delete">
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
  # 怒りの画像削除フォーム
  if($LOGIN_ID eq $set::masterid){
    print <<"HTML";
    <form name="imgdel" method="post" action="./" class="deleteform">
      <p style="font-size: 80%;">
      <input type="hidden" name="mode" value="img-delete">
      <input type="hidden" name="id" value="$::in{'id'}">
      <input type="hidden" name="pass" value="$::in{'pass'}">
      <input type="checkbox" name="check1" value="1" required>
      <input type="checkbox" name="check2" value="1" required>
      <input type="checkbox" name="check3" value="1" required>
      <input type="submit" value="画像削除"><br>
      </p>
    </form>
    <p class="right">@{[ $::in{'log'}?$::in{'log'}:'最終' ]}更新時のIP:$pc{'IP'}</p>
HTML
  }
}
print <<"HTML";
    </article>
  </main>
  <footer>
    <p class="notes"><span>『キズナバレット』は、</span><span>「からすば晴（N.G.P.）」及び「株式会社アークライト出版事業部」の著作物です。</span></p>
    <p class="copyright">ゆとシートⅡ for KIZ ver.${main::ver} - ゆとらいず工房</p>
  </footer>
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="その他">
    <option value="なし">
    <option value="不明">
    <option value="不詳">
  </datalist>
  <datalist id="list-belong">
    <option value="SID">
    <option value="藤宮学園">
    <option value="聖伐騎士団">
    <option value="白獅子組">
    <option value="沌竜会">
    <option value="コープス・コー">
    <option value="フリーランス">
  </datalist>
  <datalist id="list-loss">
  </datalist>
  <datalist id="list-dtiming">
    <option value="調査">
    <option value="常時">
    <option value="解説参照">
  </datalist>
  <datalist id="list-btiming">
    <option value="開始">
    <option value="準備">
    <option value="攻撃">
    <option value="威力の強化">
    <option value="ダメージ軽減">
    <option value="終了">
    <option value="戦闘不能">
    <option value="常時">
    <option value="解説参照">
  </datalist>
  <datalist id="list-dtarget">
    <option value="自身">
    <option value="単体">
  </datalist>
  <datalist id="list-btarget">
    <option value="自身">
    <option value="単体">
    <option value="単体※">
    <option value="単体（バレット）">
    <option value="エネミー">
    <option value="場面（選択）">
  </datalist>
  <datalist id="list-bcost">
    <option value="なし">
    <option value="【励起値】">
    <option value="【耐久値】">
  </datalist>
  <datalist id="list-dlimited">
    <option value="なし">
    <option value="ドラマ1回">
    <option value="シナリオ1回">
  </datalist>
  <datalist id="list-blimited">
    <option value="なし">
    <option value="ラウンド1回">
    <option value="シナリオ1回">
    <option value="シナリオ3回">
  </datalist>
  <datalist id="list-marker-position">
    <option value="手首">
    <option value="手の甲">
    <option value="首">
    <option value="背中">
    <option value="脚">
    <option value="手の平">
  </datalist>
  <datalist id="list-marker-color">
    <option value="赤">
    <option value="青">
    <option value="緑">
    <option value="白">
    <option value="黒">
    <option value="紫">
  </datalist>
  <datalist id="list-emotion1">
    <option value="束縛">
    <option value="尊敬">
    <option value="執着">
    <option value="興味">
    <option value="依存">
    <option value="親愛">
  </datalist>
  <datalist id="list-emotion2">
    <option value="憧憬">
    <option value="信頼">
    <option value="安らぎ">
    <option value="劣等感">
    <option value="憎しみ">
    <option value="不安">
  </datalist>
  <script>
HTML
print 'const negaiData = '.(JSON::PP->new->encode(\%negai)).";\n";
## チャットパレット
print <<"HTML";
  let palettePresetText = {
    'ytc'    : { 'full': `@{[ palettePreset()         ]}`, 'simple': `@{[ palettePresetSimple()         ]}` } ,
    'bcdice' : { 'full': `@{[ palettePreset('bcdice') ]}`, 'simple': `@{[ palettePresetSimple('bcdice') ]}` } ,
  };
  </script>
</body>

</html>
HTML

1;