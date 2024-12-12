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
  '究明' => { out => {endurance => 5, operation => 5}, in => {endurance => 4, operation => 2} },
  '守護' => { out => {endurance =>13, operation => 1}, in => {endurance => 6, operation => 1} },
  '正裁' => { out => {endurance => 7, operation => 4}, in => {endurance => 4, operation => 2} },
  '破壊' => { out => {endurance => 9, operation => 3}, in => {endurance => 6, operation => 1} },
  '復讐' => { out => {endurance =>11, operation => 2}, in => {endurance => 6, operation => 1} },
  '奉仕' => { out => {endurance => 9, operation => 3}, in => {endurance => 4, operation => 2} },
  '享楽' => { out => {endurance =>11, operation => 2}, in => {endurance => 6, operation => 1} },
  '功名' => { out => {endurance => 7, operation => 4}, in => {endurance => 4, operation => 2} },
  '善行' => { out => {endurance => 5, operation => 5}, in => {endurance => 4, operation => 2} },
  '無垢' => { out => {endurance => 9, operation => 3}, in => {endurance => 2, operation => 3} },
);

### データ読み込み ###################################################################################
my ($data, $mode, $file, $message) = getSheetData($::in{mode});
our %pc = %{ $data };

my $mode_make = ($mode =~ /^(blanksheet|copy|convert)$/) ? 1 : 0;

### 出力準備 #########################################################################################
if($message){
  my $name = unescapeTags($pc{characterName} || $pc{aka} || '無題');
  $message =~ s/<!NAME>/$name/;
}
### プレイヤー名 --------------------------------------------------
if($mode_make){
  $pc{playerName} = (getplayername($LOGIN_ID))[0];
}
### 初期設定 --------------------------------------------------
if($mode_make){ $pc{protect} ||= $LOGIN_ID ? 'account' : 'password'; }

if($mode eq 'edit' || ($mode eq 'convert' && $pc{ver})){
  %pc = data_update_chara(\%pc);
  if($pc{updateMessage}){
    $message .= "<hr>" if $message;
    $message .= "<h2>アップデート通知</h2><dl>";
    foreach (sort keys %{$pc{updateMessage}}){
      $message .= '<dt>'.$_.'</dt><dd>'.$pc{updateMessage}{$_}.'</dd>';
    }
    (my $lasttimever = $pc{lasttimever}) =~ s/([0-9]{3})$/\.$1/;
    $message .= "</dl><small>前回保存時のバージョン:$lasttimever</small>";
  }
}
elsif($mode eq 'blanksheet'){
  $pc{group} = $set::group_default;
  
  $pc{endurancePreGrow} = $set::make_endurance || 0;
  $pc{operationPreGrow} = $set::make_operation || 0;
  
  $pc{partner1Auto} = 1;
  $pc{partner2Auto} = 1;
  
  $pc{paletteUseBuff} = 1;

  %pc = applyCustomizedInitialValues(\%pc);
}

## 画像
$pc{imageFit} = $pc{imageFit} eq 'percent' ? 'percentX' : $pc{imageFit};
$pc{imagePercent}   //= '200';
$pc{imagePositionX} //= '50';
$pc{imagePositionY} //= '50';
$pc{wordsX} ||= '右';
$pc{wordsY} ||= '上';

## カラー
setDefaultColors();

## その他
$pc{makeType}   ||= 'normal';
$pc{historyNum} ||= 3;
$pc{kizunaNum}  ||= 3;
$pc{kizuatoNum} ||= 2;

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
my $titlebarname = removeTags removeRuby unescapeTags ($pc{characterName}||"“$pc{aka}”");
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
  <style>
    #image,
    .image-custom-view {
      background-image: url("$pc{imageURL}");
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
  print '<input type="hidden" name="_token" value="'.tokenMake().'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      
      <div id="header-menu">
        <h2><span></span></h2>
        <ul>
          <li onclick="sectionSelect('common');"><span>キャラ<span class="shorten">クター</span></span><span>データ</span>
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
  if ($mode eq 'edit' && $pc{protect} eq 'password' && $::in{pass}) {
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
      <div class="box" id="group">
        <dl>
          <dt>グループ
          <dd><select name="group">
HTML
foreach (@set::groups){
  my $id   = @$_[0];
  my $name = @$_[2];
  my $exclusive = @$_[4];
  next if($exclusive && (!$LOGIN_ID || $LOGIN_ID !~ /^($exclusive)$/));
  print '<option value="'.$id.'"'.($pc{group} eq $id ? ' selected': '').'>'.$name.'</option>';
}
print <<"HTML";
          </select>
          <dt>タグ
          <dd>@{[ input 'tags','','','' ]}
        </dl>
      </div>

      <div class="box in-toc" id="name-form" data-content-title="キャラクター名・プレイヤー名">
        <div>
          <dl id="character-name">
            <dt>キャラクター名
            <dd>@{[input('characterName','text',"setName",'required')]}
            <dt class="ruby">ふりがな
            <dd>@{[input('characterNameRuby','text',"setName")]}
          </dl>
        </div>
        <dl id="player-name">
          <dt>プレイヤー名
          <dd>@{[input('playerName')]}
        </dl>
      </div>

      <details class="box" id="regulation" @{[$mode eq 'edit' ? '':'open']} style="display:none">
        <summary class="in-toc">作成レギュレーション</summary>
        <dl>
          <dt>初期成長
          <dd id="level-pre-grow">
          <dt>耐久値+
          <dd>@{[input("endurancePreGrow",'number','changeRegu','step="2"'.($set::make_fix?' readonly':''))]}
          <dt>作戦力+
          <dd>@{[input("operationPreGrow",'number','changeRegu','step="1"'.($set::make_fix?' readonly':''))]}
        </dl>
      </details>
      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}

        <div id="make-type" class="box">
          @{[ radios 'makeType','changeMakeType','normal=>通常作成','gospel=>ゴスペルバレット作成' ]}
        </div>

        <div id="classes" class="box">
        <h2 class="in-toc">種別／ネガイ／能力値</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th>
                <th>
                <th>耐久値
                <th>作戦力
              </tr>
            <tbody>
              <tr>
                <th>種別
                <td><select name="class" oninput="changeType();">@{[option "class",'ハウンド','オーナー']}</select>
                <td>@{[ input 'enduranceType','number','calcStt', "readonly tabindex='-1'" ]}
                <td>@{[ input 'operationType','number','calcStt', "readonly tabindex='-1'" ]}
              <tr>
                <th>ネガイ(表)
                <td>@{[ selectInput "negaiOutside","changeNegai('Out',this.value)",@negai ]}
                <td>@{[ input 'enduranceOutside','number','calcStt' ]}
                <td>@{[ input 'operationOutside','number','calcStt' ]}
              <tr>
                <th>ネガイ(裏)
                <td>@{[ selectInput "negaiInside","changeNegai('In',this.value)",@negai ]}
                <td>@{[ input 'enduranceInside','number','calcStt' ]}
                <td>@{[ input 'operationInside','number','calcStt' ]}
              <tr>
                <th colspan="2">成長
                <td id="endurance-grow">
                <td id="operation-grow">
              <tr>
                <th colspan="2">その他修正
                <td>@{[ input 'enduranceAdd','number','calcStt' ]}
                <td>@{[ input 'operationAdd','number','calcStt' ]}
              <tr class="total">
                <th colspan="2">合計
                <td id="endurance-total">
                <td id="operation-total">
              </tr>
            </tbody>
          </table>
        </div>

        <div id="hitogara" class="box">
          <h2 class="in-toc">ヒトガラ</h2>
          <table class="edit-table">
            <tr>
              <th>年齢<td>@{[input "age"]}
              <th>性別<td>@{[input "gender",'','','list="list-gender"']}
            <tr>
              <th>過去
              <td colspan="3">@{[input "past"]}
            <tr>
              <th>
                <span class="h-only">遭遇</span>
                <span class="o-only">経緯</span>
              
              <td colspan="3">@{[input "background"]}
            <tr>
              <th>外見の特徴
              <td colspan="3">@{[input "appearance"]}
            <tr>
              <th>
                <span class="h-only">ケージ</span>
                <span class="o-only">住居</span>
              
              <td colspan="3">@{[input "dwelling"]}
            <tr>
              <th>好きなもの
              <td colspan="3">@{[input "like"]}
            <tr>
              <th>嫌いなもの
              <td colspan="3">@{[input "dislike"]}
            <tr>
              <th>得意なこと
              <td colspan="3">@{[input "good"]}
            <tr>
              <th>苦手なこと
              <td colspan="3">@{[input "notgood"]}
            <tr>
              <th>喪失
              <td colspan="3">@{[input "missing"]}
            <tr>
              <th>
                <span class="h-only thin">リミッターの影響</span>
                <span class="o-only thin">ペアリングの副作用</span>
              <td colspan="3">@{[input "sideeffect"]}
            <tr>
              <th>
                <span class="h-only">決意</span>
                <span class="o-only">使命</span>
              <td colspan="3">@{[input "resolution"]}
            <tr class="normal-only">
              <th>所属
              <td colspan="3">@{[input "belong",'','','list="list-belong"']}
            <tr>
              <th>おもな武器
              <td colspan="3">@{[input "weapon"]}
            <tr class="gospel-only">
              <th>主人(テンシ)
              <td colspan="3">@{[input "master"]}
            <tr class="gospel-only">
              <th>テンシの恩恵
              <td colspan="3">@{[input "benefit"]}
            <tr class="gospel-only">
              <th>経緯 <span class="small thin">(ゴスペルバレット)</span>
              <td colspan="3">@{[input "backgroundGB",'','','placeholder="転化時のみ記入"']}
            <tr class="gospel-only">
              <th><span class="thin">イルマーカー:位置</span>
              <td>@{[input "illMarkerPosition",'','','list="list-illmarker-position"']}
              <th>主人の感情１
              <td>@{[input "masterEmotion1",'','','list="list-master-emotion1"']}
            <tr class="gospel-only">
              <th><span class="thin">イルマーカー:形状</span>
              <td>@{[input "illMarkerShape",'','','list="list-illmarker-shape"']}
              <th>主人の感情２
              <td>@{[input "masterEmotion2",'','','list="list-master-emotion2"']}
            </tr>
          </table>
        </div>
      </div>
      
      <div class="box partner-edit">
        <h2 class="in-toc">パートナー</h2>
        <div class="partner-table" id="partner1area">
          <dl class="partner-data">
            <dt>相手
            <dd>
              <dl>
                <dt>名前
                <dd>@{[ input 'partner1Name' ]}
                <dt>URL<small>（@{[ input 'partner1Auto','checkbox','autoInputPartner(1)' ]}相手のデータを自動入力）</small>
                <dd>@{[ input 'partner1Url','url','autoInputPartner(1)' ]}
                <dt>年齢
                <dd>@{[ input 'partner1Age' ]}
                <dt>性別
                <dd>@{[ input 'partner1Gender' ]}
                <dt>ネガイ（表）
                <dd>@{[ input 'partner1NegaiOutside' ]}
                <dt>ネガイ（裏）
                <dd>@{[ input 'partner1NegaiInside' ]}
                <dt>リリースの方法
                <dd>@{[ input 'partner1Release' ]}
              </dl>
            </dd>
          </dl>
          <dl class="partner-from">
            <dt>自分の<br>マーカー
            <dd>
              <select name="partnerOrder" oninput="autoInputPartner(1)" style="width:auto;">
                <option value="1">パートナー１
                <option value="2">パートナー２
              </select>※相手から見て
            <dd>
              <dl>
                <dt>位置<dd>@{[ input 'fromPartner1MarkerPosition','','','list="list-marker-position"' ]}
                <dt>色<dd>@{[ input 'fromPartner1MarkerColor','','','list="list-marker-color"' ]}
                <dt>相手からの感情1<dd>@{[ input 'fromPartner1Emotion1','','','list="list-emotion1"' ]}
                <dt>相手からの感情2<dd>@{[ input 'fromPartner1Emotion2','','','list="list-emotion2"' ]}
              </dl>
          </dl>
          <dl class="partner-to">
            <dt>相手の<br>マーカー
            <dd>※相手のシートへ表示される内容
            <dd>
              <dl>
                <dt>位置<dd>@{[ input 'toPartner1MarkerPosition','','','list="list-marker-position"' ]}
                <dt>色<dd>@{[ input 'toPartner1MarkerColor','','','list="list-marker-color"' ]}
                <dt>相手への感情1<dd>@{[ input 'toPartner1Emotion1','','','list="list-emotion1"' ]}
                <dt>相手への感情2<dd>@{[ input 'toPartner1Emotion2','','','list="list-emotion2"' ]}
              </dl>
          </dl>
          <dl class="partner-promise">
            <dt>最初の<br>思い出
            <dd><textarea name="partner1Memory">$pc{partner1Memory}</textarea>
          </dl>
        </div>
      </div>
      
      <div class="box partner-edit">
        <h2 id="head-partner2" class="in-toc" data-content-title="アナザーまたはパートナー２">@{[ input 'partner2On','checkbox','togglePartner2' ]}<span class="h-only">アナザー</span><span class="o-only">パートナー２</span></h2>
        <div class="partner-table" id="partner2area">
          <dl class="partner-data">
            <dt>相手
            <dd>
              <dl>
                <dt>名前
                <dd>@{[ input 'partner2Name' ]}
                <dt>URL<small>（@{[ input 'partner2Auto','checkbox','autoInputPartner(2)' ]}相手のデータを自動入力）</small>
                <dd>@{[ input 'partner2Url','url','autoInputPartner(2)' ]}
                <dt>年齢
                <dd>@{[ input 'partner2Age' ]}
                <dt>性別
                <dd>@{[ input 'partner2Gender' ]}
                <dt>ネガイ（表）
                <dd>@{[ input 'partner2NegaiOutside' ]}
                <dt>ネガイ（裏）
                <dd>@{[ input 'partner2NegaiInside' ]}
                <dt>リリースの方法
                <dd>@{[ input 'partner2Release' ]}
              </dl>
          </dl>
          <dl class="partner-from">
            <dt>自分の<br>マーカー
            <dd>
            <dd>
              <dl>
                <dt class="o-only">位置
                <dd class="o-only">@{[ input 'fromPartner2MarkerPosition','','','list="list-marker-position"' ]}
                <dt class="o-only">色
                <dd class="o-only">@{[ input 'fromPartner2MarkerColor','','','list="list-marker-color"' ]}
                <dt>相手からの感情1<dd>@{[ input 'fromPartner2Emotion1','','','list="list-emotion1"' ]}
                <dt>相手からの感情2<dd>@{[ input 'fromPartner2Emotion2','','','list="list-emotion2"' ]}
              </dl>
          </dl>
          <dl class="partner-to">
            <dt>相手の<br>マーカー
            <dd>※相手のシートへ表示される内容
            <dd>
              <dl>
                <dt class="o-only">位置
                <dd class="o-only">@{[ input 'toPartner2MarkerPosition','','','list="list-marker-position"' ]}
                <dt class="o-only">色
                <dd class="o-only">@{[ input 'toPartner2MarkerColor','','','list="list-marker-color"' ]}
                <dt>相手への感情1<dd>@{[ input 'toPartner2Emotion1','','','list="list-emotion1"' ]}
                <dt>相手への感情2<dd>@{[ input 'toPartner2Emotion2','','','list="list-emotion2"' ]}
              </dl>
          </dl>
          <dl class="partner-promise">
            <dt><span class="h-only">協定</span><span class="o-only">最初の<br>思い出</span>
            <dd><textarea name="partner2Memory">$pc{partner2Memory}</textarea>
          </dl>
        </div>
      </div>
      
      <div class="box" id="kizuna">
        <h2 class="in-toc">キズナ</h2>
        @{[input 'kizunaNum','hidden']}
        <table class="edit-table no-border-cells" id="kizuna-table">
          <thead>
            <tr>
              <th>
              <th>物・人・場所など
              <th>感情・思い出など
              <th>ヒビ
              <th>ワレ
            </tr>
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{kizunaNum}) {
  if($num eq 'TMPL'){ print '<template id="kizuna-template">' }
print <<"HTML";
            <tr id="kizuna-row${num}" class="@{[ $pc{"kizuna${num}Hibi"} ? 'hibi':'' ]}@{[ $pc{"kizuna${num}Ware"} ? 'ware':'' ]}">
              <td class="handle">
              <td>@{[ input "kizuna${num}Name" ]}
              <td>@{[ input "kizuna${num}Note" ]}
              <td>@{[ input "kizuna${num}Hibi", 'checkbox', "checkHibi(${num})" ]}
              <td>@{[ input "kizuna${num}Ware", 'checkbox', "checkWare(${num})" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addKizuna()">▼</a><a onclick="delKizuna()">▲</a></div>
      </div>

      <div class="box" id="shougou">
        <h2 class="in-toc">傷号</h2>
        <dl>
          <dt>1<dd>@{[ input "shougou1" ]}
          <dt>2<dd>@{[ input "shougou2" ]}
          <dt>3<dd>@{[ input "shougou3" ]}
        </dl>
      </div>

      <div class="box" id="kizuato">
        <h2 class="in-toc">キズアト</h2>
        @{[input 'kizuatoNum','hidden']}
          <table class="edit-table line-tbody no-border-cells" id="kizuato-table">
            <colgroup id="kizuato-col">
              <col>
              <col>
              <col>
              <col>
              <col>
              <col>
            </colgroup>
HTML
foreach my $num ('TMPL',1 .. $pc{kizuatoNum}) {
  if($num eq 'TMPL'){ print '<template id="kizuato-template">' }
print <<"HTML";
            <tbody id="kizuato-row${num}">
              <tr>
                <td class="name" colspan="6">
                <span class="handle"></span>
                名称:《@{[input "kizuato${num}Name"]}》
              <tr>
                <th rowspan="2">ドラマ
                <th>ヒトガラ
                <th>タイミング
                <th>対象
                <th>制限
                <th class="left">解説
              <tr>
                <td>@{[input "kizuato${num}DramaHitogara"]}
                <td>@{[input "kizuato${num}DramaTiming" ,'','','list="list-dtiming"']}
                <td>@{[input "kizuato${num}DramaTarget" ,'','','list="list-dtarget"']}
                <td>@{[input "kizuato${num}DramaLimited",'','','list="list-dlimited"']}
                <td class="left">@{[input "kizuato${num}DramaNote"]}
             <tr>
               <th rowspan="2">決戦
               <th>タイミング
               <th>対象
               <th>代償
               <th>制限
               <th class="left">解説
             <tr>
                <td>@{[input "kizuato${num}BattleTiming" ,'','','list="list-btiming"']}
                <td>@{[input "kizuato${num}BattleTarget" ,'','','list="list-btarget"']}
                <td>@{[input "kizuato${num}BattleCost"   ,'','','list="list-bcost"']}
                <td>@{[input "kizuato${num}BattleLimited",'','','list="list-blimited"']}
                <td class="left">@{[input "kizuato${num}BattleNote"]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addKizuato()">▼</a><a onclick="delKizuato()">▲</a></div>
      </div>
      
      <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
        <summary class="in-toc">容姿・経歴・その他メモ</summary>
        <textarea name="freeNote">$pc{freeNote}</textarea>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeNote\')">最新のメモを適用する</button>' : '' ]}
      </details>
      
      <details class="box" id="free-history" @{[$pc{freeHistory}?'open':'']}>
        <summary class="in-toc">履歴（自由記入）</summary>
        <textarea name="freeHistory">$pc{freeHistory}</textarea>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeHistory\')">最新の履歴（自由記入）を適用する</button>' : '' ]}
      </details>
      
      <div class="box" id="history">
        <h2 class="in-toc">セッション履歴</h2>
        @{[input 'historyNum','hidden']}
        <table class="edit-table line-tbody no-border-cells" id="history-table">
          <thead id="history-head">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="grow  ">成長
              <th class="gm    ">GM
              <th class="member">参加者
            <!--
            <tr>
              <td>-
              <td>
              <td>キャラクター作成
              <td id="history0-exp">$pc{history0Exp}
            -->
HTML
foreach my $num ('TMPL',1 .. $pc{historyNum}) {
  if($num eq 'TMPL'){ print '<template id="history-template">' }
print <<"HTML";
          <tbody id="history-row${num}">
          <tr>
            <td class="handle" rowspan="2">
            <td class="date  " rowspan="2">@{[ input"history${num}Date" ]}
            <td class="title " rowspan="2">@{[ input"history${num}Title" ]}
            <td class="grow  "><select name="history${num}Grow" oninput="calcGrow()">@{[ option "history${num}Grow",'endurance|<耐久値+2>','operation|<作戦力+1>' ]}</select>
            <td class="gm    ">@{[ input "history${num}Gm" ]}
            <td class="member">@{[ input "history${num}Member" ]}
          <tr>
            <td colspan="5" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          <tfoot id="history-foot">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="grow  ">成長
              <th class="gm    ">GM
              <th class="member">参加者
            </tr>
          </tfoot>
        </table>
        <div class="add-del-button"><a onclick="addHistory()">▼</a><a onclick="delHistory()">▲</a></div>
        <h2>記入例</h2>
        <table class="example edit-table line-tbody no-border-cells">
          <thead>
            <tr>
              <th>
              <th>日付
              <th>タイトル
              <th>成長
              <th>GM
              <th>参加者
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>-
              <td><input type="text" value="2017-04-07" disabled>
              <td><input type="text" value="第一話「記入例」" disabled>
              <td><select disabled><option><option>耐久値+2<option selected>作戦力+1</select>
              <td class="gm"><input type="text" value="サンプルGM" disabled>
              <td class="member"><input type="text" value="イユ　黒崎武" disabled>
            </tr>
          </tbody>
        </table>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
      </div>
      </section>
      
      @{[ chatPaletteForm ]}
      
      @{[ colorCostomForm ]}
      
      @{[ input 'birthTime','hidden' ]}
      <input type="hidden" name="id" value="$::in{id}">
    </form>
    @{[ deleteForm($mode) ]}
    </article>
HTML
# ヘルプ
print textRuleArea( '','「容姿・経歴・その他メモ」「履歴（自由記入）」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">©からすば晴／N.G.P.／アークライト／新紀元社「キズナバレット」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
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
  <datalist id="list-illmarker-position">
    <option value="手首">
    <option value="胸">
    <option value="首">
    <option value="足首">
    <option value="腹">
    <option value="舌">
  </datalist>
  <datalist id="list-illmarker-shape">
    <option value="鎖">
    <option value="縄">
    <option value="剣">
    <option value="茨">
    <option value="蔓">
    <option value="文字">
    <option value="目">
    <option value="咬み痕">
  </datalist>
  <datalist id="list-master-emotion1">
    <option value="独占欲">
    <option value="役に立つ">
    <option value="優越感">
    <option value="愉悦">
    <option value="偏愛">
    <option value="嗜虐心">
  </datalist>
  <datalist id="list-master-emotion2">
    <option value="家畜">
    <option value="消耗品">
    <option value="美術品">
    <option value="部下">
    <option value="観察対象">
    <option value="愛玩物">
  </datalist>
  <script>
HTML
print 'const negaiData = '.(JSON::PP->new->encode(\%negai)).";\n";
print <<"HTML";
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;