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
require $set::data_factor;

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
if($mode_make){
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
elsif($mode eq 'blanksheet'){
  $pc{'group'} = $set::group_default;
  
  $pc{'endurancePreGrow'}  = $set::make_endurance  || 0;
  $pc{'initiativePreGrow'} = $set::make_initiative || 0;
  
  $pc{'partner1Auto'} = 1;
  $pc{'partner2Auto'} = 1;
  
  $pc{'paletteUseBuff'} = 1;
}

## 画像
$pc{'imageFit'} = $pc{'imageFit'} eq 'percent' ? 'percentX' : $pc{'imageFit'};
$pc{'imagePercent'} = $pc{'imagePercent'} eq '' ? '200' : $pc{'imagePercent'};
$pc{'imagePositionX'} = $pc{'imagePositionX'} eq '' ? '50' : $pc{'imagePositionX'};
$pc{'imagePositionY'} = $pc{'imagePositionY'} eq '' ? '50' : $pc{'imagePositionY'};
$pc{'wordsX'} ||= '右';
$pc{'wordsY'} ||= '上';

## カラー
setDefaultColors();

## その他
$pc{'historyNum'} ||= 3;
$pc{'artsNum'} ||= 3;

### 改行処理 --------------------------------------------------
$pc{'words'}         =~ s/&lt;br&gt;/\n/g;
$pc{'scarNote'}      =~ s/&lt;br&gt;/\n/g;
$pc{'freeNote'}      =~ s/&lt;br&gt;/\n/g;
$pc{'freeHistory'}   =~ s/&lt;br&gt;/\n/g;
$pc{'chatPalette'}   =~ s/&lt;br&gt;/\n/g;

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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/blp/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/blp/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/blp/edit-chara.js?${main::ver}" defer></script>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/\@fortawesome/fontawesome-free\@5.15.4/css/all.min.css" integrity="sha256-mUZM63G8m73Mcidfrv5E+Y61y7a12O5mW4ezU3bxqW4=" crossorigin="anonymous">
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

      <details class="box" id="regulation" @{[$mode eq 'edit' ? '':'open']}>
        <summary>作成レギュレーション</summary>
        <dl>
          <dt>練度</dt>
          <dd id="level-pre-grow"></dd>
          <dt>耐久値+</dt>
          <dd>@{[input("endurancePreGrow",'number','changeRegu','step="5"'.($set::make_fix?' readonly':''))]}</dd>
          <dt>先制値+</dt>
          <dd>@{[input("initiativePreGrow",'number','changeRegu','step="2"'.($set::make_fix?' readonly':''))]}</dd>
        </dl>
        <div class="annotate" @{[ $pc{'convertSource'} eq 'キャラクターシート倉庫' ? '' : 'style="display:none"' ]}>
          ※コンバート時、副能力値の基本値を超える値は、クローズ時の成長としてこの欄に振り分けられます。<br>
          　ただし、（耐久は5、先制は2で）割り切れない「あまり」の値は特技等による補正として、副能力値の補正欄に振り分けています。<br>
        </div>
        <div class="annotate">※練度は自動的に計算されます。</div>
      </details>
      <div id="area-status">
        @{[ image_form("${set::char_dir}${file}/image.$pc{'image'}?$pc{'imageUpdate'}") ]}

        <div id="factors" class="box">
          <h2>練度:<span id="level-value"></span> ／ 能力値</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th></th>
                <th></th>
                <th>
                  <span class="h-only"><i>♠</i>技</span>
                  <span class="v-only"><i>♥</i>血</span>
                </th>
                <th>
                  <span class="h-only"><i>♣</i>情</span>
                  <span class="v-only"><i>♦</i>想</span>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th>ファクター</th>
                <td><select name="factor" oninput="changeFactor();">@{[option "factor",'人間','吸血鬼']}</select></td>
                <td>―</td>
                <td>―</td>
              </tr>
              <tr>
                <th>
                  <span class="h-only">信念</span>
                  <span class="v-only">起源</span>
                </th>
                <td>@{[ selectInput "factorCore","checkSubFactor('Core',this.value);calcStt()",@{$data::factor_list{$pc{'factor'}}{'core'}} ]}</td>
                <td>@{[ input 'statusMain1Core','number','calcStt' ]}</td>
                <td>@{[ input 'statusMain2Core','number','calcStt' ]}</td>
              </tr>
              <tr>
                <th>
                  <span class="h-only">職能</span>
                  <span class="v-only">流儀</span>
                </th>
                <td>@{[ selectInput "factorStyle","checkSubFactor('Style',this.value);calcStt()",@{$data::factor_list{$pc{'factor'}}{'style'}} ]}</td>
                <td>@{[ input 'statusMain1Style','number','calcStt' ]}</td>
                <td>@{[ input 'statusMain2Style','number','calcStt' ]}</td>
              </tr>
              <tr class="total">
                <th colspan="2">合計</th>
                <td id="main1-total"></td>
                <td id="main2-total"></td>
              </tr>
          </table>
          <h2>副能力値</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th></th>
                <th></th>
                <th class="center">耐久値<div class="small" id="endurance-base"></div></th>
                <th class="center">先制値<div class="small" id="initiative-base"></div></th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th colspan="2">成長</th>
                <td id="endurance-grow"></td>
                <td id="initiative-grow"></td>
              </tr>
              <tr>
                <th colspan="2">その他修正</th>
                <td>@{[ input 'enduranceAdd','number','calcStt' ]}</td>
                <td>@{[ input 'initiativeAdd','number','calcStt' ]}</td>
              </tr>
              <tr class="total">
                <th colspan="2">合計</th>
                <td id="endurance-total"></td>
                <td id="initiative-total"></td>
              </tr>
            </tbody>
          </table>
        </div>

        <div id="personal" class="box-union">
          <dl class="box"><dt><span class="v-only">外見年齢／実</span>年齢</dt><dd><span class="v-only">@{[input "ageApp"]}／</span>@{[input "age"]}</dd></dl>
          <dl class="box"><dt>性別</dt><dd>@{[input "gender",'','','list="list-gender"']}</dd></dl>
          <dl class="box"><dt>所属</dt><dd>@{[input "belong",'','','list="list-belong"']}</dd><dd>@{[input "belongNote",'','','placeholder="備考"']}</dd></dl>
          <dl class="box"><dt>過去</dt><dd>@{[input "past"]}</dd><dd>@{[input "pastNote",'','','placeholder="備考"']}</dd></dl>
          <dl class="box"><dt>経緯</dt><dd>@{[input "background"]}</dd><dd>@{[input "backgroundNote",'','','placeholder="備考"']}</dd></dl>
          <dl class="box"><dt>喪失</dt><dd>@{[input "missing"]}</dd><dd>@{[input "missingNote",'','','placeholder="備考"']}</dd></dl>
          <dl class="box"><dt>外見的特徴</dt><dd>@{[input "appearance"]}</dd><dd>@{[input "appearanceNote",'','','placeholder="備考"']}</dd></dl>
          <dl class="box"><dt>住まい</dt><dd>@{[input "dwelling"]}</dd><dd>@{[input "dwellingNote",'','','placeholder="備考"']}</dd></dl>
          <dl class="box"><dt>使用武器</dt><dd>@{[input "weapon"]}</dd><dd>@{[input "weaponNote",'','','placeholder="備考"']}</dd></dl>
        </div>
        
        <dl id="scar" class="box">
          <dt>傷号</dt>
          <dd>@{[input "scarName",'','scarCheck']}</dd>
          <dd><textarea name="scarNote" placeholder="設定" rows="3">$pc{'scarNote'}</textarea></dd>
        </dl>
      </div>
      
      <div class="box partner-edit">
        <h2 id="head-servant">@{[ input 'servantOn','checkbox','toggleServant' ]}血僕／隷印</h2>
        <div class="partner-table" id="servant">
          <dl class="servant-data">
            <dt></dt>
            <dd>
              <dl>
                <dt id="servant-master-term">主</dt>
                <dd>@{[ input 'servantMaster' ]}</dd>
                
                <dt id="servant-class-term">区分</dt>
                <dd>@{[ input 'servantClass','','','list="list-servant-class"' ]}</dd>
                
                <dt id="servant-background-term">従属経緯</dt>
                <dd>@{[ input 'servantBackground' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-from">
            <dt>隷印</dt>
            <dd>
              <dl>
                <dt>位置</dt>
                <dd>@{[ input 'servantSealPosition','','','list="list-servant-seal-position"' ]}</dd>
                <dt>形状</dt>
                <dd>@{[ input 'servantSealShape','','','list="list-servant-seal-shape"' ]}</dd>
                <dt>主からの感情1</dt><dd>@{[ input 'servantEmotion1','','','list="list-servant-emotion1"' ]}</dd>
                <dt>主からの感情2</dt><dd>@{[ input 'servantEmotion2','','','list="list-servant-emotion2"' ]}</dd>
              </dl>
            </dd>
          </dl>
        </div>
      </div>
      
      <div class="box partner-edit">
        <h2>血契</h2>
        <div class="partner-table" id="partner1area">
          <dl class="partner-data">
            <dt>相手</dt>
            <dd>
              <dl>
                <dt>名前</dt>
                <dd>@{[ input 'partner1Name' ]}</dd>
                
                <dt>URL<small>（@{[ input 'partner1Auto','checkbox','autoInputPartner(1)' ]}相手のデータを自動入力）</small></dt>
                <dd>@{[ input 'partner1Url','url','autoInputPartner(1)' ]}</dd>
                
                <dt id="partner1-factor-term">起源／流儀</dt>
                <dd>@{[ input 'partner1Factor' ]}</dd>
                
                <dt id="partner1-age-term">年齢</dt>
                <dd>@{[ input 'partner1Age' ]}</dd>
                
                <dt>性別</dt>
                <dd>@{[ input 'partner1Gender' ]}</dd>
                
                <dt id="partner1-missing-term">欠落</dt>
                <dd>@{[ input 'partner1Missing' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-from">
            <dt>自分の<br>痕印</dt>
            <dd>
              <select name="partnerOrder" oninput="autoInputPartner(1)" style="width:auto;">
                <option value="1">血契１
                <option value="2">血契２
              </select>※相手から見て
            </dd>
            <dd>
              <dl>
                <dt>位置</dt><dd>@{[ input 'fromPartner1SealPosition','','','list="list-seal-position"' ]}</dd>
                <dt>形状</dt><dd>@{[ input 'fromPartner1SealShape','','','list="list-seal-shape"' ]}</dd>
                <dt>相手からの感情1</dt><dd>@{[ input 'fromPartner1Emotion1','','','list="list-emotion1"' ]}</dd>
                <dt>相手からの感情2</dt><dd>@{[ input 'fromPartner1Emotion2','','','list="list-emotion2"' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-to">
            <dt>相手の<br>痕印</dt>
            <dd>※相手のシートへ表示される内容</dd>
            <dd>
              <dl>
                <dt>位置</dt><dd>@{[ input 'toPartner1SealPosition','','','list="list-seal-position"' ]}</dd>
                <dt>形状</dt><dd>@{[ input 'toPartner1SealShape','','','list="list-seal-shape"' ]}</dd>
                <dt>相手への感情1</dt><dd>@{[ input 'toPartner1Emotion1','','','list="list-emotion1"' ]}</dd>
                <dt>相手への感情2</dt><dd>@{[ input 'toPartner1Emotion2','','','list="list-emotion2"' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-promise">
            <dt>約束</dt>
            <dd>@{[ input 'partner1Promise' ]}</dd>
          </dl>
        </div>
      </div>
      
      <div class="box partner-edit">
        <h2 id="head-partner2">@{[ input 'partner2On','checkbox','togglePartner2' ]}<span class="h-only">血契２</span><span class="v-only">連血鬼</span></h2>
        <div class="partner-table" id="partner2area">
          <dl class="partner-data">
            <dt>相手</dt>
            <dd>
              <dl>
                <dt>名前</dt>
                <dd>@{[ input 'partner2Name' ]}</dd>
                
                <dt>URL<small>（@{[ input 'partner2Auto','checkbox','autoInputPartner(2)' ]}相手のデータを自動入力）</small></dt>
                <dd>@{[ input 'partner2Url','url','autoInputPartner(2)' ]}</dd>
                
                <dt id="partner1-factor-term">起源／流儀</dt>
                <dd>@{[ input 'partner2Factor' ]}</dd>
                
                <dt id="partner1-age-term">年齢</dt>
                <dd>@{[ input 'partner2Age' ]}</dd>
                
                <dt>性別</dt>
                <dd>@{[ input 'partner2Gender' ]}</dd>
                
                <dt id="partner1-missing-term">欠落</dt>
                <dd>@{[ input 'partner2Missing' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-from">
            <dt>自分の<br>痕印</dt>
            <dd></dd>
            <dd>
              <dl>
                <dt class="h-only">位置</dt>
                <dd class="h-only">@{[ input 'fromPartner2SealPosition','','','list="list-seal-position"' ]}</dd>
                <dt class="h-only">形状</dt>
                <dd class="h-only">@{[ input 'fromPartner2SealShape','','','list="list-seal-shape"' ]}</dd>
                <dt>相手からの感情1</dt><dd>@{[ input 'fromPartner2Emotion1','','','list="list-emotion1"' ]}</dd>
                <dt>相手からの感情2</dt><dd>@{[ input 'fromPartner2Emotion2','','','list="list-emotion2"' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-to">
            <dt>相手の<br>痕印</dt>
            <dd>※相手のシートへ表示される内容</dd>
            <dd>
              <dl>
                <dt class="h-only">位置</dt>
                <dd class="h-only">@{[ input 'toPartner2SealPosition','','','list="list-seal-position"' ]}</dd>
                <dt class="h-only">形状</dt>
                <dd class="h-only">@{[ input 'toPartner2SealShape','','','list="list-seal-shape"' ]}</dd>
                <dt>相手への感情1</dt><dd>@{[ input 'toPartner2Emotion1','','','list="list-emotion1"' ]}</dd>
                <dt>相手への感情2</dt><dd>@{[ input 'toPartner2Emotion2','','','list="list-emotion2"' ]}</dd>
              </dl>
            </dd>
          </dl>
          <dl class="partner-promise">
            <dt><span class="h-only">約束</span><span class="v-only">協定</span></dt>
            <dd>@{[ input 'partner2Promise' ]}</dd>
          </dl>
        </div>
      </div>
      
      <div class="box" id="bloodarts">
        <h2>血威</h2>
        <table class="edit-table no-border-cells">
          <thead>
            <tr><th></th><th>名称</th><th>タイミング</th><th>対象</th><th class="left">解説</th></tr>
          </thead>
          <tbody id="bloodarts-list">
HTML
foreach my $num (1 .. 3) {
print <<"HTML";
            <tr id="bloodarts${num}">
              <td class="handle"></td>
              <td>@{[input "bloodarts${num}Name"]}</td>
              <td>@{[input "bloodarts${num}Timing",'','','list="list-timing"']}</td>
              <td>@{[input "bloodarts${num}Target",'','','list="list-target"']}</td>
              <td>@{[input "bloodarts${num}Note"]}</td>
            </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
      </div>
      
      <div class="box" id="arts">
        <h2>特技</h2>
        @{[input 'artsNum','hidden']}
        <table class="edit-table no-border-cells" id="arts-table">
          <thead>
            <tr><th></th><th>名称</th><th>タイミング</th><th>対象</th><th>代償</th><th>条件</th><th class="left">解説</th></tr>
          </thead>
          <tbody id="arts-list">
HTML
foreach my $num (1 .. $pc{'artsNum'}) {
print <<"HTML";
            <tr id="arts${num}">
              <td class="handle"></td>
              <td>@{[input "arts${num}Name"]}</td>
              <td>@{[input "arts${num}Timing" ,'','','list="list-timing"']}</td>
              <td>@{[input "arts${num}Target" ,'','','list="list-target"']}</td>
              <td>@{[input "arts${num}Cost"   ,'','','list="list-cost"']}</td>
              <td>@{[input "arts${num}Limited",'','','list="list-limited"']}</td>
              <td>@{[input "arts${num}Note"]}</td>
            </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addArts()">▼</a><a onclick="delArts()">▲</a></div>
        <h2 id="arts-scar-head">傷号特技</h2>
        <table id="arts-scar" class="edit-table no-border-cells">
          <thead>
            <tr><th></th><th>名称</th><th>タイミング</th><th>対象</th><th>代償</th><th>条件</th><th class="left">解説</th></tr>
          </thead>
          <tbody>
            <tr>
              <td colspan="2" id="arts-scar-name"></td>
              <td>@{[input "artsSTiming" ,'','','list="list-timing"']}</td>
              <td>@{[input "artsSTarget" ,'','','list="list-target"']}</td>
              <td>@{[input "artsSCost"   ,'','','list="list-cost"']}</td>
              <td>@{[input "artsSLimited",'','','list="list-limited"']}</td>
              <td>@{[input "artsSNote"]}</td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <details class="box" id="free-note" @{[$pc{'freeNote'}?'open':'']}>
        <summary>容姿・経歴・その他メモ</summary>
        <textarea name="freeNote">$pc{'freeNote'}</textarea>
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
            <th>力の向上</th>
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
            <td><select name="history${num}Grow" oninput="calcGrow()">@{[ option "history${num}Grow",'endurance|<耐久値+5>','initiative|<先制値+2>' ]}</select></td>
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
            <th>力の向上</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
          </thead>
          <tbody>
          <tr>
            <td>-</td>
            <td><input type="text" value="2021-08-26" disabled></td>
            <td><input type="text" value="第一話「記入例」" disabled></td>
            <td><select disabled><option><option>耐久値+5<option selected>先制値+2</select></td>
            <td class="gm"><input type="text" value="サンプルGM" disabled></td>
            <td class="member"><input type="text" value="遠野志貴　アルクェイド" disabled></td>
          </tr>
          </tbody>
        </table>
        <div class="annotate">
        ※「力の向上」の選択を行うと、自動的に練度が+1されます。
        </div>
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
          <label>@{[ input 'paletteUseVar', 'checkbox','setChatPalette']}デフォルト変数を使う</label>
          ／
          <label>@{[ input 'paletteUseBuff', 'checkbox','setChatPalette']}バフデバフ用変数を使う</label>
          <br>
          使用ダイスbot: <select name="paletteTool" onchange="setChatPalette();" style="width:auto;">
          <option value="">ゆとチャadv.
          <option value="bcdice" @{[ $pc{'paletteTool'} eq 'bcdice' ? 'selected' : '']}>BCDice
          </select>
        </p>
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
HTML
# ヘルプ
print textRuleArea( '','「容姿・経歴・その他メモ」「履歴（自由記入）」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">©からすば晴／N.G.P.／アークライト／新紀元社「人鬼血盟RPG ブラッドパス」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
  </footer>
  <datalist id="list-belief">
    <option value="義士">
    <option value="讐人">
    <option value="傀儡">
    <option value="金愚">
    <option value="研人">
    <option value="求道">
  </datalist>
  <datalist id="list-job">
    <option value="監者">
    <option value="戦衛">
    <option value="狩人">
    <option value="謀智">
    <option value="術士">
    <option value="資道">
  </datalist>
  <datalist id="list-origin">
    <option value="源祖">
    <option value="貴種">
    <option value="夜者">
    <option value="半鬼">
    <option value="屍鬼">
    <option value="綺獣">
  </datalist>
  <datalist id="list-style">
    <option value="舞人">
    <option value="戦鬼">
    <option value="奏者">
    <option value="火華">
    <option value="群団">
    <option value="界律">
  </datalist>
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
    <option value="斬鬼衆">
    <option value="異端改宗室">
    <option value="鮮紅騎士団">
    <option value="鬼灯寮">
    <option value="学館・広魔学科">
    <option value="八刃会">
    <option value="フリーランス">
  </datalist>
  <datalist id="list-loss">
    <option value="視覚（色彩）">
    <option value="声">
    <option value="怒り">
    <option value="記憶（人間）">
    <option value="身体（髪色）">
    <option value="哀れみ">
    <option value="視覚（顔）">
  </datalist>
  <datalist id="list-lack">
    <option value="執着（自身）">
    <option value="喜び">
    <option value="愛">
    <option value="恐怖">
    <option value="悲しみ">
    <option value="執着（他人）">
    <option value="希望">
  </datalist>
  <datalist id="list-timing">
    <option value="調査">
    <option value="開始">
    <option value="準備">
    <option value="攻撃">
    <option value="終了">
    <option value="戦闘不能">
    <option value="いつでも">
    <option value="常時">
    <option value="解説参照">
  </datalist>
  <datalist id="list-target">
    <option value="自身">
    <option value="単体">
    <option value="単体※">
    <option value="単体（血盟）">
    <option value="単体（血盟）※">
    <option value="場面">
    <option value="場面（選択）">
    <option value="解説参照">
  </datalist>
  <datalist id="list-cost">
    <option value="なし">
    <option value="手札1枚">
    <option value="黒1枚">
    <option value="黒絵札1枚">
    <option value="赤1枚">
    <option value="赤絵札1枚">
    <option value="スペード1枚">
    <option value="スペード絵札1枚">
    <option value="クラブ1枚">
    <option value="クラブ絵札1枚">
    <option value="ハート1枚">
    <option value="ハート絵札1枚">
    <option value="ダイヤ1枚">
    <option value="ダイヤ絵札1枚">
    <option value="【耐久値】">
  </datalist>
  <datalist id="list-limited">
    <option value="なし">
    <option value="ドラマ1回">
    <option value="ラウンド1回">
    <option value="血戦1回">
    <option value="シナリオ1回">
  </datalist>
  <datalist id="list-seal-position">
    <option value="手の甲">
    <option value="胸元">
    <option value="掌">
    <option value="首">
    <option value="背中">
    <option value="脚">
    <option value="指先（爪）">
  </datalist>
  <datalist id="list-seal-shape">
    <option value="獣">
    <option value="花">
    <option value="剣">
    <option value="星">
    <option value="太陽">
    <option value="月">
    <option value="羽根">
  </datalist>
  <datalist id="list-emotion1">
    <option value="尊敬">
    <option value="独占欲">
    <option value="親愛">
    <option value="執着心">
    <option value="興味">
    <option value="依存">
    <option value="崇拝">
  </datalist>
  <datalist id="list-emotion2">
    <option value="恐怖">
    <option value="憧憬">
    <option value="憎しみ">
    <option value="隔たり">
    <option value="劣等感">
    <option value="安心感">
    <option value="不安">
  </datalist>
  <datalist id="list-servant-class">
    <option value="戦奴">
    <option value="玩倶">
    <option value="働具">
  </datalist>
  <datalist id="list-servant-seal-position">
    <option value="手首">
    <option value="胸">
    <option value="背中">
    <option value="首">
    <option value="足首">
    <option value="腹">
    <option value="舌">
  </datalist>
  <datalist id="list-servant-seal-shape">
    <option value="鎖">
    <option value="数字">
    <option value="傷跡">
    <option value="花">
    <option value="目">
    <option value="文字">
    <option value="固有紋様">
  </datalist>
  <datalist id="list-servant-emotion1">
    <option value="独占欲">
    <option value="有為">
    <option value="憐憫">
    <option value="優越感">
    <option value="滑稽">
    <option value="偏愛">
    <option value="嗜虐心">
  </datalist>
  <datalist id="list-servant-emotion2">
    <option value="家畜">
    <option value="美品">
    <option value="消耗品">
    <option value="美術品">
    <option value="娯楽">
    <option value="側近">
    <option value="愛用品">
  </datalist>
  <script>
HTML
print 'const factorList = '.(JSON::PP->new->encode(\%data::factor_list)).";\n";
print 'const factorData = '.(JSON::PP->new->encode(\%data::factor_data)).";\n";
print <<"HTML";
  </script>
</body>

</html>
HTML

1;