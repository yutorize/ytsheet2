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
  
  $pc{endurancePreGrow}  = $set::make_endurance  || 0;
  $pc{initiativePreGrow} = $set::make_initiative || 0;
  
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
$pc{historyNum} ||= 3;
$pc{artsNum} ||= 3;

### 改行処理 --------------------------------------------------
$pc{words}       =~ s/&lt;br&gt;/\n/g;
$pc{scarNote}    =~ s/&lt;br&gt;/\n/g;
$pc{freeNote}    =~ s/&lt;br&gt;/\n/g;
$pc{freeHistory} =~ s/&lt;br&gt;/\n/g;
$pc{chatPalette} =~ s/&lt;br&gt;/\n/g;

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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/blp/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/blp/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/blp/edit-chara.js?${main::ver}" defer></script>
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

      <details class="box" id="regulation" @{[$mode eq 'edit' ? '':'open']}>
        <summary class="in-toc">作成レギュレーション</summary>
        <dl>
          <dt>練度
          <dd id="level-pre-grow">
          <dt>耐久値+
          <dd>@{[input("endurancePreGrow",'number','changeRegu','step="5"'.($set::make_fix?' readonly':''))]}
          <dt>先制値+
          <dd>@{[input("initiativePreGrow",'number','changeRegu','step="2"'.($set::make_fix?' readonly':''))]}
        </dl>
        <ul class="annotate" @{[ $pc{convertSource} eq 'キャラクターシート倉庫' ? '' : 'style="display:none"' ]}>
          <li>コンバート時、副能力値の基本値を超える値は、クローズ時の成長としてこの欄に振り分けられます。<br>
            ただし、（耐久は5、先制は2で）割り切れない「あまり」の値は特技等による補正として、副能力値の補正欄に振り分けています。
        </ul>
        <ul class="annotate"><li>練度は自動的に計算されます。</ul>
        <dl class="regulation-note"><dt>備考<dd>@{[ input "history0Note" ]}</dl>
      </details>
      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}

        <div id="factors" class="box">
          <h2 class="in-toc" data-content-title="能力値">練度:<span id="level-value"></span> ／ 能力値</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th></th>
                <th></th>
                <th>
                  <span class="h-only"><i>♠</i>技</span>
                  <span class="v-only"><i>♥</i>血</span>
                <th>
                  <span class="h-only"><i>♣</i>情</span>
                  <span class="v-only"><i>♦</i>想</span>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th>ファクター
                <td><select name="factor" oninput="changeFactor();">@{[option "factor",'人間','吸血鬼']}</select>
                <td>―
                <td>―
              <tr>
                <th>
                  <span class="h-only">信念</span>
                  <span class="v-only">起源</span>
                </th>
                <td>@{[ selectInput "factorCore","checkSubFactor('Core',this.value);calcStt()",@{$data::factor_list{$pc{factor}}{core}} ]}
                <td>@{[ input 'statusMain1Core','number','calcStt' ]}
                <td>@{[ input 'statusMain2Core','number','calcStt' ]}
              <tr>
                <th>
                  <span class="h-only">職能</span>
                  <span class="v-only">流儀</span>
                </th>
                <td>@{[ selectInput "factorStyle","checkSubFactor('Style',this.value);calcStt()",@{$data::factor_list{$pc{factor}}{style}} ]}
                <td>@{[ input 'statusMain1Style','number','calcStt' ]}
                <td>@{[ input 'statusMain2Style','number','calcStt' ]}
              <tr class="total">
                <th colspan="2">合計
                <td id="main1-total">
                <td id="main2-total">
              </tr>
          </table>
          <h2>副能力値</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th>
                <th>
                <th class="center">耐久値<div class="small" id="endurance-base"></div>
                <th class="center">先制値<div class="small" id="initiative-base"></div>
            </thead>
            <tbody>
              <tr>
                <th colspan="2">成長
                <td id="endurance-grow">
                <td id="initiative-grow">
              <tr>
                <th colspan="2">その他修正
                <td>@{[ input 'enduranceAdd','number','calcStt' ]}
                <td>@{[ input 'initiativeAdd','number','calcStt' ]}
              <tr class="total">
                <th colspan="2">合計
                <td id="endurance-total">
                <td id="initiative-total">
              </tr>
            </tbody>
          </table>
        </div>

        <div id="personal" class="box-union in-toc" data-content-title="プロファイル">
          <dl class="box"><dt><span class="v-only">外見年齢／実</span>年齢<dd><span class="v-only">@{[input "ageApp"]}／</span>@{[input "age"]}</dl>
          <dl class="box"><dt>性別      <dd>@{[input "gender",'','','list="list-gender"']}</dl>
          <dl class="box"><dt>所属      <dd>@{[input "belong",'','','list="list-belong"']}<dd>@{[input "belongNote",'','','placeholder="備考"']}</dl>
          <dl class="box"><dt>過去      <dd>@{[input "past"]}      <dd>@{[input "pastNote",'','','placeholder="備考"']}</dl>
          <dl class="box"><dt>経緯      <dd>@{[input "background"]}<dd>@{[input "backgroundNote",'','','placeholder="備考"']}</dl>
          <dl class="box"><dt>喪失      <dd>@{[input "missing"]}   <dd>@{[input "missingNote",'','','placeholder="備考"']}</dl>
          <dl class="box"><dt>外見的特徴<dd>@{[input "appearance"]}<dd>@{[input "appearanceNote",'','','placeholder="備考"']}</dl>
          <dl class="box"><dt>住まい    <dd>@{[input "dwelling"]}  <dd>@{[input "dwellingNote",'','','placeholder="備考"']}</dl>
          <dl class="box"><dt>使用武器  <dd>@{[input "weapon"]}    <dd>@{[input "weaponNote",'','','placeholder="備考"']}</dl>
        </div>
        
        <dl id="scar" class="box">
          <dt class="in-toc">傷号
          <dd>@{[input "scarName",'','scarCheck']}
          <dd><textarea name="scarNote" placeholder="設定" rows="3">$pc{scarNote}</textarea>
        </dl>
      </div>
      
      <div class="box partner-edit">
        <h2 id="head-servant" class="in-toc">@{[ input 'servantOn','checkbox','toggleServant' ]}血僕／隷印</h2>
        <div class="partner-table" id="servant">
          <dl class="servant-data">
            <dt>
            <dd>
              <dl>
                <dt id="servant-master-term">主
                <dd>@{[ input 'servantMaster' ]}
                
                <dt id="servant-class-term">区分
                <dd>@{[ input 'servantClass','','','list="list-servant-class"' ]}
                
                <dt id="servant-background-term">従属経緯
                <dd>@{[ input 'servantBackground' ]}
              </dl>
            </dd>
          </dl>
          <dl class="partner-from">
            <dt>隷印
            <dd>
              <dl>
                <dt>位置
                <dd>@{[ input 'servantSealPosition','','','list="list-servant-seal-position"' ]}
                <dt>形状
                <dd>@{[ input 'servantSealShape','','','list="list-servant-seal-shape"' ]}
                <dt>主からの感情1<dd>@{[ input 'servantEmotion1','','','list="list-servant-emotion1"' ]}
                <dt>主からの感情2<dd>@{[ input 'servantEmotion2','','','list="list-servant-emotion2"' ]}
              </dl>
            </dd>
          </dl>
        </div>
      </div>
      
      <div class="box partner-edit">
        <h2 class="in-toc">血契</h2>
        <div class="partner-table" id="partner1area">
          <dl class="partner-data">
            <dt>相手
            <dd>
              <dl>
                <dt>名前
                <dd>@{[ input 'partner1Name' ]}
                <dt>URL<small>（@{[ input 'partner1Auto','checkbox','autoInputPartner(1)' ]}相手のデータを自動入力）</small>
                <dd>@{[ input 'partner1Url','url','autoInputPartner(1)' ]}
                <dt id="partner1-factor-term">起源／流儀
                <dd>@{[ input 'partner1Factor' ]}
                <dt id="partner1-age-term">年齢
                <dd>@{[ input 'partner1Age' ]}
                <dt>性別
                <dd>@{[ input 'partner1Gender' ]}
                <dt id="partner1-missing-term">欠落
                <dd>@{[ input 'partner1Missing' ]}
              </dl>
          </dl>
          <dl class="partner-from">
            <dt>自分の<br>痕印
            <dd>
              <select name="partnerOrder" oninput="autoInputPartner(1)" style="width:auto;">
                <option value="1" @{[ $pc{partnerOrder} eq 1 ? 'selected' :'' ]}>血契１
                <option value="2" @{[ $pc{partnerOrder} eq 2 ? 'selected' :'' ]}>血契２
              </select>※相手から見て
            </dd>
            <dd>
              <dl>
                <dt>位置<dd>@{[ input 'fromPartner1SealPosition','','','list="list-seal-position"' ]}
                <dt>形状<dd>@{[ input 'fromPartner1SealShape','','','list="list-seal-shape"' ]}
                <dt>相手からの感情1<dd>@{[ input 'fromPartner1Emotion1','','','list="list-emotion1"' ]}
                <dt>相手からの感情2<dd>@{[ input 'fromPartner1Emotion2','','','list="list-emotion2"' ]}
              </dl>
          </dl>
          <dl class="partner-to">
            <dt>相手の<br>痕印
            <dd>※相手のシートへ表示される内容
            <dd>
              <dl>
                <dt>位置<dd>@{[ input 'toPartner1SealPosition','','','list="list-seal-position"' ]}
                <dt>形状<dd>@{[ input 'toPartner1SealShape','','','list="list-seal-shape"' ]}
                <dt>相手への感情1<dd>@{[ input 'toPartner1Emotion1','','','list="list-emotion1"' ]}
                <dt>相手への感情2<dd>@{[ input 'toPartner1Emotion2','','','list="list-emotion2"' ]}
              </dl>
          </dl>
          <dl class="partner-promise">
            <dt>約束
            <dd>@{[ input 'partner1Promise' ]}
          </dl>
        </div>
      </div>
      
      <div class="box partner-edit">
        <h2 id="head-partner2" class="in-toc" data-content-title="血契２または連血鬼">@{[ input 'partner2On','checkbox','togglePartner2' ]}<span class="h-only">血契２</span><span class="v-only">連血鬼</span></h2>
        <div class="partner-table" id="partner2area">
          <dl class="partner-data">
            <dt>相手
            <dd>
              <dl>
                <dt>名前
                <dd>@{[ input 'partner2Name' ]}
                <dt>URL<small>（@{[ input 'partner2Auto','checkbox','autoInputPartner(2)' ]}相手のデータを自動入力）</small>
                <dd>@{[ input 'partner2Url','url','autoInputPartner(2)' ]}
                <dt id="partner1-factor-term">起源／流儀
                <dd>@{[ input 'partner2Factor' ]}
                <dt id="partner1-age-term">年齢
                <dd>@{[ input 'partner2Age' ]}
                <dt>性別
                <dd>@{[ input 'partner2Gender' ]}
                <dt id="partner1-missing-term">欠落
                <dd>@{[ input 'partner2Missing' ]}
              </dl>
          </dl>
          <dl class="partner-from">
            <dt>自分の<br>痕印
            <dd>
            <dd>
              <dl>
                <dt class="h-only">位置
                <dd class="h-only">@{[ input 'fromPartner2SealPosition','','','list="list-seal-position"' ]}
                <dt class="h-only">形状
                <dd class="h-only">@{[ input 'fromPartner2SealShape','','','list="list-seal-shape"' ]}
                <dt>相手からの感情1<dd>@{[ input 'fromPartner2Emotion1','','','list="list-emotion1"' ]}
                <dt>相手からの感情2<dd>@{[ input 'fromPartner2Emotion2','','','list="list-emotion2"' ]}
              </dl>
          </dl>
          <dl class="partner-to">
            <dt>相手の<br>痕印
            <dd>※相手のシートへ表示される内容
            <dd>
              <dl>
                <dt class="h-only">位置
                <dd class="h-only">@{[ input 'toPartner2SealPosition','','','list="list-seal-position"' ]}
                <dt class="h-only">形状
                <dd class="h-only">@{[ input 'toPartner2SealShape','','','list="list-seal-shape"' ]}
                <dt>相手への感情1<dd>@{[ input 'toPartner2Emotion1','','','list="list-emotion1"' ]}
                <dt>相手への感情2<dd>@{[ input 'toPartner2Emotion2','','','list="list-emotion2"' ]}
              </dl>
          </dl>
          <dl class="partner-promise">
            <dt><span class="h-only">約束</span><span class="v-only">協定</span>
            <dd>@{[ input 'partner2Promise' ]}
          </dl>
        </div>
      </div>
      
      <div class="box" id="bloodarts">
        <h2 class="in-toc">血威</h2>
        <table class="edit-table no-border-cells">
          <thead>
            <tr><th><th>名称<th>タイミング<th>対象<th class="left">解説
          <tbody id="bloodarts-list">
HTML
foreach my $num (1 .. 3) {
print <<"HTML";
            <tr id="bloodarts${num}">
              <td class="handle">
              <td>@{[input "bloodarts${num}Name"]}
              <td>@{[input "bloodarts${num}Timing",'','','list="list-timing"']}
              <td>@{[input "bloodarts${num}Target",'','','list="list-target"']}
              <td>@{[input "bloodarts${num}Note"]}
HTML
}
print <<"HTML";
          </tbody>
        </table>
      </div>
      
      <div class="box" id="arts">
        <h2 class="in-toc">特技</h2>
        @{[input 'artsNum','hidden']}
        <table class="edit-table no-border-cells" id="arts-table">
          <thead id="arts-head">
            <tr><th><th>名称<th>タイミング<th>対象<th>代償<th>条件<th class="left">解説
          <tbody id="arts-list">
HTML
foreach my $num ('TMPL',1 .. $pc{artsNum}) {
  if($num eq 'TMPL'){ print '<template id="arts-template">' }
print <<"HTML";
            <tr id="arts-row${num}">
              <td class="handle">
              <td>@{[input "arts${num}Name"]}
              <td>@{[input "arts${num}Timing" ,'','','list="list-timing"']}
              <td>@{[input "arts${num}Target" ,'','','list="list-target"']}
              <td>@{[input "arts${num}Cost"   ,'','','list="list-cost"']}
              <td>@{[input "arts${num}Limited",'','','list="list-limited"']}
              <td>@{[input "arts${num}Note"]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addArts()">▼</a><a onclick="delArts()">▲</a></div>
        <h2 id="arts-scar-head">傷号特技</h2>
        <table id="arts-scar" class="edit-table no-border-cells">
          <thead>
            <tr><th><th>名称<th>タイミング<th>対象<th>代償<th>条件<th class="left">解説
          </thead>
          <tbody>
            <tr>
              <td colspan="2" id="arts-scar-name">
              <td>@{[input "artsSTiming" ,'','','list="list-timing"']}
              <td>@{[input "artsSTarget" ,'','','list="list-target"']}
              <td>@{[input "artsSCost"   ,'','','list="list-cost"']}
              <td>@{[input "artsSLimited",'','','list="list-limited"']}
              <td>@{[input "artsSNote"]}
            </tr>
          </tbody>
        </table>
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
            <th class="grow  ">力の向上
            <th class="gm    ">GM
            <th class="member">参加者
          <tr>
            <td>-
            <td>
            <td>キャラクター作成
            <td id="history0-exp">$pc{history0Exp}
HTML
foreach my $num ('TMPL',1 .. $pc{historyNum}) {
  if($num eq 'TMPL'){ print '<template id="history-template">' }
print <<"HTML";
          <tbody id="history-row${num}">
          <tr>
            <td class="handle" rowspan="2">
            <td class="date  " rowspan="2">@{[ input"history${num}Date" ]}
            <td class="title " rowspan="2">@{[ input"history${num}Title" ]}
            <td class="grow  "><select name="history${num}Grow" oninput="calcGrow()">@{[ option "history${num}Grow",'endurance|<耐久値+5>','initiative|<先制値+2>' ]}</select>
            <td class="gm    ">@{[ input "history${num}Gm" ]}
            <td class="member">@{[ input "history${num}Member" ]}
          <tr>
            <td colspan="5" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          <tfoot id="history-foot">
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="grow  ">力の向上
            <th class="gm    ">GM
            <th class="member">参加者
        </table>
        <div class="add-del-button"><a onclick="addHistory()">▼</a><a onclick="delHistory()">▲</a></div>
        <h2>記入例</h2>
        <table class="example edit-table line-tbody no-border-cells">
          <thead>
            <tr>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="grow  ">力の向上
              <th class="gm    ">GM
              <th class="member">参加者
            </tr>
          <tbody>
            <tr>
              <td>-
              <td><input type="text" value="2021-08-26" disabled>
              <td><input type="text" value="第一話「記入例」" disabled>
              <td><select disabled><option><option>耐久値+5<option selected>先制値+2</select>
              <td class="gm"><input type="text" value="サンプルGM" disabled>
              <td class="member"><input type="text" value="遠野志貴　アルクェイド" disabled>
            </tr>
          </tbody>
        </table>
        <ul class="annotate">
          <li>「力の向上」の選択を行うと、自動的に練度が+1されます。
        </ul>
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
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;