############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';
use JSON::PP;

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_races;
require $set::data_class;
my @main_class; my @adv_class; my @fate_class; my @legacy_class;
my @support_class; my @area_names; my %area_class;
foreach (sort{$data::class{$a}{sort} cmp $data::class{$b}{sort}} keys %data::class){
  if($data::class{$_}{type} eq 'main'){ push(@main_class, $_); push(@support_class, $_); }
  elsif($data::class{$_}{type} eq 'adv'   ){ push(@adv_class , $_); }
  elsif($data::class{$_}{type} eq 'fate'  ){ push(@fate_class, $_); }
  elsif($data::class{$_}{type} eq 'legacy'){ push(@legacy_class, $_); }
  else {
    if($data::class{$_}{area}){
      push(@area_names, $data::class{$_}{area}) if !$area_class{$data::class{$_}{area}};
      push(@{ $area_class{$data::class{$_}{area}} }, $_);
    }
    else {
      push(@support_class, $_);
    }
  }
  
}
@main_class = (
  'label=基本クラス',@main_class,
  #'label=その他', 'free|<その他（自由記入）>',
);
foreach my $area (@area_names){
  push(@support_class, 'label='.$area, @{$area_class{$area}});
}
unshift(@support_class, 'label=基本クラス');
push(@support_class, 'label=レガシークラス', @legacy_class);
push(@support_class, 'label=その他', 'free|<その他（自由記入）>');

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
  
  $pc{history0Exp}   = $set::make_exp;
  $pc{history0Money} = $set::make_money;
  $pc{expTotal} = $pc{history0Exp};
  
  $pc{level} = 1;

  $pc{moneyAuto} = 1;
  
  $pc{rollStrDice} = $pc{rollDexDice} = $pc{rollAgiDice} =
  $pc{rollIntDice} = $pc{rollSenDice} = $pc{rollMndDice} = $pc{rollLukDice} =
  $pc{battleDiceAcc} = $pc{battleDiceAtk} = $pc{battleDiceEva} =
  $pc{rollTrapDetectDice} = $pc{rollTrapReleaseDice} = $pc{rollDangerDetectDice} = $pc{rollEnemyLoreDice} = 
  $pc{rollAppraisalDice} = $pc{rollMagicDice} = $pc{rollSongDice} = $pc{rollAlchemyDice} = 2;
  $pc{fate} = 5;

  $pc{skill1Type} = 'race';
  $pc{skill3Type} = 'general';
  $pc{skill4Type} = 'general';
  
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
$pc{skillsNum}      ||=  3;
$pc{connectionsNum} ||=  1;
$pc{geisesNum}      ||=  1;
$pc{historyNum}     ||=  3;

### 折り畳み判断 --------------------------------------------------
my %open;
$open{skills} = 'open';
#foreach (3..$pc{skillsNum}){ if($pc{"skill${_}Name"} || $pc{"skill${_}Lv"}){ $open{skills} = 'open'; last; } }

### 改行処理 --------------------------------------------------
foreach (
  'words',
  'items',
  'freeNote',
  'freeHistory',
  'cashbook',
  'chatPalette',
  'armamentHandRNote',
  'armamentHandLNote',
  'armamentHeadNote',
  'armamentBodyNote',
  'armamentSubNote',
  'armamentOtherNote',
  'armamentTotalNote',
  'battleSkillNote',
  'battleOtherNote',
){
  $pc{$_} =~ s/&lt;br&gt;/\n/g;
}
foreach my $i (1 .. $pc{geisesNum}){
  $pc{"geis${i}Note"} =~ s/&lt;br&gt;/\n/g;
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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/ar2e/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/ar2e/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/\@yaireo/tagify"></script>
  <script src="https://cdn.jsdelivr.net/npm/\@yaireo/tagify/dist/tagify.polyfills.min.js"></script>
  <link href="https://cdn.jsdelivr.net/npm/\@yaireo/tagify/dist/tagify.css" rel="stylesheet" type="text/css">
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/ar2e/edit-chara.js?${main::ver}" defer></script>
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
            <dd>@{[input('characterName','text',"setName")]}
            <dt class="ruby">ふりがな（アーシアン向け）
            <dd>@{[input('characterNameRuby','text',"setName")]}
          </dl>
          <dl id="aka">
            <dt>二つ名・異名など
            <dd>@{[input('aka','text',"setName")]}
            <dt class="ruby">フリガナ
            <dd>@{[input('akaRuby','text',"setName")]}
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
          <dt>成長点
          <dd>@{[input("history0Exp",'number','changeRegu','step="1"'.($set::make_fix?' readonly':''))]}
          <dt>所持金
          <dd>@{[input("history0Money",'number','changeRegu', ($set::make_fix?' readonly':''))]}
          <dt>エリア／ローカル
          <dd class="area-tags">
            <input name="areaTags" class="tagify-custom" value="$pc{areaTags}">
            <script defer>
            var areaTags = document.querySelector('input[name="areaTags"]');
            let areaTagify = new Tagify(areaTags, {
              whitelist: [
                "エリア：すべて",
                "ローカル：すべて",
                "エリンディル大陸西方",
                "エリンディル大陸東方",
                "アルディオン大陸東方",
                "アースラン",
                "マジェラニカ大陸",
                "エルクレスト・カレッジ",
                "ネオ・ダイナストカバル",
                "黒波衆",
                "十三神将",
                "霊獣の里",
                "シェルドニアン学園",
              ],
              maxTags: 12,
              delimiters: ' ',
              dropdown: {
                maxItems: 20,
                classname: "tags-look",
                enabled: 0,
                closeOnSelect: false
              },
              originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(' ')
            });
            //var dragsort = new DragSort(areaTagify.DOM.scope, {
            //    selector:'.'+areaTagify.settings.classNames.tag,
            //    callbacks: {
            //        dragEnd: onDragEnd
            //    }
            //})
            //function onDragEnd(elm){
            //    areaTagify.updateValueByDOMTags()
            //}
            </script>
          </dd>
        </dl>
        <dl class="regulation-note"><dt>備考<dd>@{[ input "history0Note" ]}</dl>
      </details>
      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}

        <div id="personal" class="in-toc" data-content-title="種族・年齢・性別">
          <dl class="box select-or-input" id="race">
            <dt>種族
            <dd><select name="race" onchange="changeRace()">@{[ option 'race',(sort{$data::races{$a}{sort} cmp $data::races{$b}{sort} } keys %data::races),'free|<その他（自由記入）>' ]}</select>@{[ input 'raceFree' ]}
          </dl>
          <div class="box-union">
            <dl class="box" id="age">
              <dt>年齢
              <dd>@{[ input 'age' ]}
            </dl>
            <dl class="box" id="gender">
              <dt>性別
              <dd>@{[ input 'gender','','','list="list-gender"' ]}
            </dl>
          </div>
        </div>

        <div class="box" id="lifepath">
          <h2 class="in-toc">ライフパス</h2>
          <dl id="home"><dt>出身地</dt><dd>@{[ input "homeArea",'','','list="list-area"' ]}</dd></dl>
          <table class="edit-table line-tbody no-border-cells">
            </thead>
            <tbody id="lifepath-origin">
              <tr>
                <th>出自
                <td>@{[ input 'lifepathOrigin' ]}
                <td>@{[ input 'lifepathOriginNote','','','placeholder="備考"' ]}
              </tr>
            <tbody id="lifepath-experience">
              <tr>
                <th>境遇
                <td>@{[ input 'lifepathExperience' ]}
                <td>@{[ input 'lifepathExperienceNote','','','placeholder="備考"' ]}
              </tr>
            <tbody id="lifepath-motive">
              <tr>
                <th>目的
                <td>@{[ input 'lifepathMotive' ]}
                <td>@{[ input 'lifepathMotiveNote','','','placeholder="備考"' ]}
              </tr>
            </tbody>
          </table>
          <div id="lifepath-earthian">@{[ input 'lifepathEarthian','checkbox','checkRace' ]}アーシアン専用ライフパスを使う</div>
        </div>

        <div class="box-union in-toc" id="classes" data-content-title="クラス">
          <dl class="box" id="class-main">
            <dt>メインクラス
            <dd id="class-main-value">$pc{classMain}
          </dl>
          <dl class="box" id="class-support">
            <dt>サポートクラス
            <dd id="class-support-value">$pc{classSupport}
          </dl>
          <dl class="box" id="class-main-lv1">
            <dt><small>レベル1の時</small>
            <dd><select name="classMainLv1" onchange="changeClass('MainLv1')">@{[ option 'classMainLv1',@main_class ]}</select>
          </dl>
          <dl class="box select-or-input" id="class-support-lv1">
            <dt><small>レベル1の時</small>
            <dd><select name="classSupportLv1" onchange="changeClass('SupportLv1')">@{[ option 'classSupportLv1',@support_class ]}</select>@{[ input 'classSupportLv1Free','','changeClass' ]}
          </dl>
          <dl class="box" id="class-title">
            <dt>称号クラス
            <dd id="class-title-value">$pc{classTitle}
          </dl>
        </div>
        
        <div class="box in-toc" id="status" data-content-title="能力値">
          <table class="edit-table" id="status-main">
            <colgroup>
              <col class="name">
              <col class="text">
              <col class="input">
              <col class="input">
              <col class="text">
              <col class="total">
              <col class="total">
              <col class="input">
              <col class="input">
              <col class="input">
              <col class="total">
              <col class="input">
              <col class="total">
              <col class="dice">
            </colgroup>
            <thead>
              <tr>
                <th>
                <th class="small">種族<br>基本値
                <th class="small">作成時<br>[<i id="make-bonus-total">0</i>/5]pt
                <th class="small"><span>スキル</span><br>他
                <th class="small">成長
                <th class="small">能力<br>基本値
                <th class="small">能力<br><span>ボーナス</span>
                <th colspan="2" class="small">クラス修正<br><span>メイン/サポート</span>
                <th class="small"><span>スキル</span><br>他
                <th>能力値
                <th class="small"><span>スキル</span><br>他
                <th>判定
                <th>+ダイス数
              </tr>
            <tbody>
HTML
foreach (
  ['筋力','Str'],
  ['器用','Dex'],
  ['敏捷','Agi'],
  ['知力','Int'],
  ['感知','Sen'],
  ['精神','Mnd'],
  ['幸運','Luk'],
) {
  my $name = @{$_}[0];
  my $id   = @{$_}[1];
print <<"HTML";
              <tr>
                <th>$name
                <td>@{[ input 'stt'.$id.'Race','number','calcStt','readonly' ]}
                <td data-before="+">@{[ input 'stt'.$id.'Make','number','calcStt','min="0" max="5"' ]}
                <td data-before="+">@{[ input 'stt'.$id.'BaseAdd','number','calcStt' ]}
                <td data-before="+" id="stt-@{[ lc $id  ]}-grow">
                <td data-before="="><b id="stt-@{[ lc $id  ]}-base"></b>
                <td data-before="/3=" id="stt-@{[ lc $id  ]}-bonus">
                <td data-before="+">@{[ input 'stt'.$id.'Main','number','calcStt','readonly' ]}
                <td data-before="+">@{[ input 'stt'.$id.'Support','number','calcStt','readonly' ]}
                <td data-before="+">@{[ input 'stt'.$id.'Add','number','calcStt' ]}
                <td data-before="="><b id="stt-@{[ lc $id  ]}-total"></b>
                <td data-before="+">@{[ input 'roll'.$id.'Add','number','calcStt' ]}
                <td data-before="="><b id="roll-@{[ lc $id  ]}"></b>
                <td class="dice" data-before="+" data-after="D">@{[ input 'roll'.$id.'Dice','number','calcStt' ]}
              </tr>
HTML
}
print <<"HTML";
              <tr><td colspan="13">
            </tbody>
          </table>
          <table class="edit-table" id="status-sub">
            <colgroup>
              <col class="name">
              <col class="name">
              <col class="text">
              <col class="input">
              <col class="input">
              <col class="input">
              <col class="text">
              <col class="text">
              <col class="total">
            </colgroup>
            <thead>
              <tr>
                <th colspan="2">
                <th class="small">基本値
                <th colspan="2" class="small">初期クラス修正<br><span>メイン/サポート</span>
                <th class="small"><span>スキル</span><br>他
                <th class="small"><span>スキル<br>（自動）</span>
                <th class="small">成長
                <th>合計
            </thead>
            <tbody>
              <tr>
                <th colspan="2">HP
                <td id="hp-base">
                <td data-before="+">@{[ input 'hpMain','number','calcStt' ]}
                <td data-before="+">@{[ input 'hpSupport','number','calcStt' ]}
                <td data-before="+">@{[ input 'hpAdd','number','calcStt' ]}
                <td data-before="+" id="hp-auto">
                <td data-before="+" id="hp-grow">
                <td data-before="="><b id="hp-total"></b>
              <tr>
                <th colspan="2">MP
                <td id="mp-base">
                <td data-before="+">@{[ input 'mpMain','number','calcStt' ]}
                <td data-before="+">@{[ input 'mpSupport','number','calcStt' ]}
                <td data-before="+">@{[ input 'mpAdd','number','calcStt' ]}
                <td data-before="+" id="mp-auto">
                <td data-before="+" id="mp-grow">
                <td data-before="="><b id="mp-total"></b>
              <tr>
                <th colspan="2">フェイト
                <td id="fate-base">
                <td>――
                <td>――
                <td data-before="+">@{[ input 'fateAdd','number','calcStt' ]}
                <td>――
                <td data-before="+" id="fate-grow">
                <td data-before="="><b id="fate-total"></b>
              <tr>
                <th colspan="2"><small>使用上限</small>
                <td id="fate-limit-base">
                <td>――
                <td>――
                <td data-before="+">@{[ input 'fateLimitAdd','number','calcStt' ]}
                <td>――
                <td>――
                <td data-before="="><b id="fate-limit-total"></b>
              </tr>
            </tbody>
          </table>
          <table class="edit-table" id="status-weight">
            <colgroup>
              <col class="name">
              <col class="name">
              <col class="text">
              <col class="input">
              <col class="total">
            </colgroup>
            <thead>
              <tr>
                <th colspan="2">重量上限
                <th class="small">基本値
                <th class="small">スキル他
                <th>合計
              </tr>
            <tbody>
              <tr>
                <th colspan="2">武器
                <td id="weight-base-weapon">
                <td data-before="+">@{[ input 'weightLimitAddWeapon','number','calcStt' ]}
                <td data-before="="><b id="weight-limit-weapon"></b>
              <tr>
                <th colspan="2">防具
                <td id="weight-base-armour">
                <td data-before="+">@{[ input 'weightLimitAddArmour','number','calcStt' ]}
                <td data-before="="><b id="weight-limit-armour"></b>
              <tr>
                <th colspan="2">携帯品
                <td id="weight-base-items">
                <td data-before="+">@{[ input 'weightLimitAddItems','number','calcStt' ]}
                <td data-before="="><b id="weight-limit-items"></b>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      
      
      <details class="box" id="levelup" open>
        <summary class="in-toc">レベルアップ</summary>
        <div>
          <dl>
            <dt><ruby>ＣＬ<rp>(</rp><rt>キャラクターレベル</rt><rp>)</rp></ruby>:
            <dd>@{[ input 'level','number','changeLv','min="1"' ]}
          </dl>
          <table class="edit-table no-border-cells">
            <thead>
              <tr>
                <th rowspan="2">CL
                <th colspan="7">能力値上昇
                <th rowspan="2">クラスチェンジ<br>or フェイト増加
                <th rowspan="2" colspan="3">習得スキル　<a class="button" onclick="calcLvUpSkills('copy')">スキル欄に転記する</a>
              </tr>
              <tr>
                <th>筋力
                <th>器用
                <th>敏捷
                <th>知力
                <th>感知
                <th>精神
                <th>幸運
              </tr>
            <tbody id="levelup-lines">
HTML
foreach my $lv (reverse 2 .. $pc{level}){
  my @classes = ('fate|<フェイト増加>',@support_class);
  if($lv >= 10){ push(@classes, 'label=上級クラス',@adv_class); }
  if($lv >= 20){ push(@classes, 'label=運命クラス',@fate_class); }
  if($lv >= 15){ push(@classes, 'label=称号クラス','title|<称号クラス（自由記入）>'); }

print <<"HTML";
              <tr id="lvup${lv}">
                <th>$lv
                <td>@{[ input 'lvUp'.$lv.'SttStr', 'checkbox', "checkGrow(${lv})" ]}
                <td>@{[ input 'lvUp'.$lv.'SttDex', 'checkbox', "checkGrow(${lv})" ]}
                <td>@{[ input 'lvUp'.$lv.'SttAgi', 'checkbox', "checkGrow(${lv})" ]}
                <td>@{[ input 'lvUp'.$lv.'SttInt', 'checkbox', "checkGrow(${lv})" ]}
                <td>@{[ input 'lvUp'.$lv.'SttSen', 'checkbox', "checkGrow(${lv})" ]}
                <td>@{[ input 'lvUp'.$lv.'SttMnd', 'checkbox', "checkGrow(${lv})" ]}
                <td>@{[ input 'lvUp'.$lv.'SttLuk', 'checkbox', "checkGrow(${lv})" ]}
                <td class="select-or-input">
                  <select name="lvUp${lv}Class" onchange="changeClass();calcLvUpSkills();">@{[ option "lvUp${lv}Class",@classes ]}</select>
                  @{[ input 'lvUp'.$lv.'ClassFree','','changeClass' ]}
                </td>
                <td class="skill">@{[ input 'lvUp'.$lv.'Skill1','','calcLvUpSkills' ]}
                <td class="skill">@{[ input 'lvUp'.$lv.'Skill2','','calcLvUpSkills' ]}
                <td class="skill">@{[ input 'lvUp'.$lv.'Skill3','','calcLvUpSkills' ]}
              </tr>
HTML
}
  print <<"HTML";
              <script>
              const lvupClasses1  = `@{[ option '', 'fate|<フェイト増加>',@support_class ]}`;
              const lvupClasses10 = `@{[ option '', 'fate|<フェイト増加>',@support_class,'label=上級クラス',@adv_class ]}`;
              const lvupClasses15 = `@{[ option '', 'fate|<フェイト増加>',@support_class,'label=上級クラス',@adv_class,'label=称号クラス','title|<称号クラス（自由記入）>' ]}`;
              const lvupClasses20 = `@{[ option '', 'fate|<フェイト増加>',@support_class,'label=上級クラス',@adv_class,'label=運命クラス',@fate_class,'label=称号クラス','title|<称号クラス（自由記入）>' ]}`;
              </script>
              <tr id="lvup1">
                <th rowspan="3">1
                <td rowspan="3" id="lvup1-str">+0
                <td rowspan="3" id="lvup1-dex">+0
                <td rowspan="3" id="lvup1-agi">+0
                <td rowspan="3" id="lvup1-int">+0
                <td rowspan="3" id="lvup1-sen">+0
                <td rowspan="3" id="lvup1-mnd">+0
                <td rowspan="3" id="lvup1-luk">+0
                <td rowspan="3" id="lvup1-class">
                <td class="skill" colspan="3">@{[ input 'lvUp1Skill1','','calcLvUpSkills','placeholder="種族スキル／メイキング"' ]}
              <tr>
                <td class="skill">@{[ input 'lvUp1Skill2','','calcLvUpSkills','placeholder="クラススキル／メイン"' ]}
                <td class="skill">@{[ input 'lvUp1Skill3','','calcLvUpSkills','placeholder="クラススキル／メイン"' ]}
                <td class="skill">@{[ input 'lvUp1Skill4','','calcLvUpSkills','placeholder="クラススキル／メイン"' ]}
              <tr>
                <td class="skill">@{[ input 'lvUp1Skill5','','calcLvUpSkills','placeholder="クラススキル／サポート"' ]}
                <td class="skill">@{[ input 'lvUp1Skill6','','calcLvUpSkills','placeholder="クラススキル／サポート"' ]}
                <td>
              </tr>
            </tbody>
          </table>
        </div>
        <ul class="annotate">
          <li>一般スキルは下部のスキル詳細欄にのみ書き込んでください。
          <li>スキル効果で別スキルを追加取得するケースは、<br>
          「ハーフブラッド／ニンブル」のように1つの欄に「／」区切りで入力してください。
        </ul>
      </details>

      <details class="box" id="skills" $open{skills}>
        <summary class="in-toc">
          スキル
        </summary>
        <div>
          <table class="edit-table line-tbody no-border-cells" id="skills-table">
            <thead id="skill-head">
              <tr><th></th><th>名称</th><th>Lv</th><th>タイミング</th><th>判定</th><th>対象</th><th>射程</th><th>コスト</th><th>使用条件</th></tr>
            </thead>
HTML
my %experienced;
$experienced{ $pc{classMainLv1} }    = 1.1;
if($pc{classSupportLv1} eq 'free'){ $experienced{ $pc{classSupportLv1Free} } = 1.2 }
else                                { $experienced{ $pc{classSupportLv1}     } = 1.2; }
foreach my $lv (2 .. $pc{level}){
  if   ($pc{"lvUp${lv}Class"} eq 'fate' ){  } # フェイト+n
  elsif($pc{"lvUp${lv}Class"} eq 'free' ){ $experienced{ $pc{"lvUp${lv}ClassFree"} } = $lv; }
  elsif($pc{"lvUp${lv}Class"} eq 'title'){ $experienced{ $pc{"lvUp${lv}ClassFree"} } = $lv; }
  elsif($pc{"lvUp${lv}Class"}           ){ $experienced{ $pc{"lvUp${lv}Class"} } = $lv; }
}
my @experienced = sort { $experienced{$a} <=> $experienced{$b} } keys %experienced;
if($data::class{$pc{classMain}} && $data::class{$pc{classMain}}{type} eq 'fate'){
  unshift(@experienced, 'power|<パワー（共通）>', 'another|<異才>')
}
foreach my $num ('TMPL',1 .. $pc{skillsNum}) {
  if($num eq 'TMPL'){ print '<template id="skill-template">' }
print <<"HTML";
            <tbody id="skill-row${num}">
              <tr>
                <td rowspan="2" class="handle"> 
                <td>@{[input "skill${num}Name",'','','onchange="calcSkills()" placeholder="名称"']}
                <td>@{[input "skill${num}Lv",'number','calcSkills','placeholder="Lv"']}
                <td>@{[input "skill${num}Timing",'','','placeholder="タイミング" list="list-timing"']}
                <td>@{[input "skill${num}Roll",'','','placeholder="判定" list="list-roll"']}
                <td>@{[input "skill${num}Target",'','','placeholder="対象" list="list-target"']}
                <td>@{[input "skill${num}Range",'','','placeholder="射程" list="list-range"']}
                <td>@{[input "skill${num}Cost",'number','','min="0" placeholder="ｺｽﾄ"']}
                <td>@{[input "skill${num}Reqd",'','','placeholder="使用条件" list="list-reqd"']}
              </tr>
              <tr><td colspan="8">
                <div>
                  <b>取得元</b><select name="skill${num}Type" onchange="calcSkills();calcLvUpSkills();">@{[ option "skill${num}Type",'general|<一般>','race|<種族>','style|<流派>','faith|<天恵>','geis|<誓約>','add|<他スキル>',@experienced ]}</select>
                  <b>分類</b>@{[input "skill${num}Category",'','','list="list-category"']}
                  <b>効果</b>@{[input "skill${num}Note"]}
                </div>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            <tfoot id="skill-foot">
              <tr><th><th>名称<th>Lv<th>タイミング<th>判定<th>対象<th>射程<th>コスト<th>使用条件
            </tfoot>
          </table>
        </div>
        <div class="add-del-button"><a onclick="addSkill()">▼</a><a onclick="delSkill()">▲</a></div>
        @{[input 'skillsNum','hidden']}
        <ul class="annotate">
          <li>コスト欄は1以上でなければ自動的に「―」になります。
          <li><span class="material-symbols-outlined" style="color:#5ad;font-variation-settings:'FILL' 1;vertical-align:text-bottom;font-size:1.5em;">calculate</span>マークがついているスキルは、ステータス類への修正が自動計算されています。
        </ul>
      </details>
      <div class="box trash-box" id="skills-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除スキル</span></h2>
        <table class="edit-table line-tbody" id="skills-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('skills-trash').style.display = 'none';">close</i>
      </div>

      <div class="box-union in-toc" id="battle" data-content-title="装備品">
        <div class="box" id="armaments">
          <table class="edit-table line-tbody no-border-cells">
            <colgroup>
              <col class="head  ">
              <col class="name  ">
              <col class="weight">
              <col class="acc   ">
              <col class="atk   ">
              <col class="eva   ">
              <col class="def   ">
              <col class="mdef  ">
              <col class="ini   ">
              <col class="move  ">
              <col class="range ">
              <col class="type  ">
              <col class="usage ">
            </colgroup>
            <thead>
              <tr>
                <th colspan="2">装備品
                <th>重量
                <th>命中<br>修正
                <th>攻撃力
                <th>回避<br>修正
                <th>物理<br>防御力
                <th>魔法<br>防御力
                <th>行動<br>修正
                <th>移動<br>修正
                <th>射程
                <th>種別
                <th>装備<br>部位
              </tr>
            </thead>
HTML
foreach (
  ['HandR', '右手'    ,],
  ['HandL', '左手'    ,],
  ['Head' , '頭部'    ,],
  ['Body' , '胴部'    ,],
  ['Sub'  , '補助防具',],
  ['Other', '装身具'  ,],
){
  my $th = @{$_}[1];
  my $id = @{$_}[0];
  print <<"HTML";
            <tbody>
              <tr>
                <th rowspan="2">@{[ length($th) > 3 ? "<span>$th</span>" : $th ]}
                <td rowspan="2">@{[ input "armament${id}Name"   ]}
                <td rowspan="2">@{[ input "armament${id}Weight", 'number','calcBattle' ]}
                <td rowspan="2">@{[ input "armament${id}Acc"   , 'number','calcBattle' ]}
                <td rowspan="2">@{[ input "armament${id}Atk"   , 'number','calcBattle' ]}
                <td rowspan="2">@{[ input "armament${id}Eva"   , 'number','calcBattle' ]}
                <td rowspan="2">@{[ input "armament${id}Def"   , 'number','calcBattle' ]}
                <td rowspan="2">@{[ input "armament${id}MDef"  , 'number','calcBattle' ]}
                <td rowspan="2">@{[ input "armament${id}Ini"   , 'number','calcBattle' ]}
                <td rowspan="2">@{[ input "armament${id}Move"  , 'number','calcBattle' ]}
HTML
  if($id =~ /^Hand/){
    print <<"HTML";
                <td>@{[ input "armament${id}Range" , '','' ,'list="list-weapon-range"' ]}
                <td>@{[ input "armament${id}Type" , '','changeHandedness','list="list-weapon-type"' ]}
                <td>@{[ input "armament${id}Usage", '','',"list='list-weapon-usage'" ]}
HTML
  }
  elsif($id =~ /^(Head|Body|Sub)$/){
    $pc{"armament${id}Type"} ||= '防具';
    print <<"HTML";
                <td>――
                <td>@{[ input "armament${id}Type" , '','', 'list="list-armour-type"' ]}
                <td class="small">@{[ $id eq 'Body' ? (input "armament${id}Usage", '','', "list='list-armour-usage'") : $th ]}
HTML
  }
  else {
    $pc{"armament${id}Type"} ||= $th;
    print <<"HTML";
                <td>――
                <td>@{[ input "armament${id}Type", '', '', '' ]}
                <td class="small">$th
HTML
  }
  print <<"HTML";
              <tr>
                <td colspan="3"><textarea name="armament${id}Note" placeholder="備考">$pc{"armament${id}Note"}</textarea>
              </tr>
            </tbody>
HTML
}
print <<"HTML";
            <tbody class="total">
              <tr>
                <th rowspan="2">合計
                <td class="right small">武器(右)<br>(左)
                <td>
                  <span id="armament-total-weight-weapon"></span>/<span id="armament-weight-limit-weapon"></span>
                <td>
                  <span id="armament-total-acc-right"></span><hr>
                  <span id="armament-total-acc-left"></span>
                <td>
                  <span id="armament-total-atk-right"></span><hr>
                  <span id="armament-total-atk-left"></span>
                <td rowspan="2" id="armament-total-eva">
                <td rowspan="2" id="armament-total-def">
                <td rowspan="2" id="armament-total-mdef">
                <td rowspan="2" id="armament-total-ini">
                <td rowspan="2" id="armament-total-move">
                <td rowspan="2" colspan="3"><textarea name="armamentTotalNote" rows="3" placeholder="備考">$pc{armamentTotalNote}</textarea>
              <tr>
                <td class="right small">防具
                <td>
                  <span id="armament-total-weight-armour"></span>/<span id="armament-weight-limit-armour"></span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="box" id="battle-rolls">
          <table class="edit-table line-tbody no-border-cells">
            <colgroup>
              <col class="head  ">
              <col class="name  ">
              <col class="weight">
              <col class="acc   ">
              <col class="atk   ">
              <col class="eva   ">
              <col class="def   ">
              <col class="mdef  ">
              <col class="ini   ">
              <col class="move  ">
              <col class="note  ">
            </colgroup>
            <thead>
              <tr>
                <th colspan="3">戦闘
                <th>命中<br>判定<div>【器用】</div>
                <th>攻撃力
                <th>回避<br>判定<div>【敏捷】</div>
                <th>物理<br>防御力
                <th>魔法<br>防御力<div>【精神】</div>
                <th>行動値<div>【敏捷】<br>+【感知】</div>
                <th>移動力<div>【筋力】+5</div>
                <th colspan="" class="left">備考
            </thead>
            <tbody>
              <tr>
                <th>スキル
                <td colspan="2">@{[ input "battleSkillName" ]}
                <td>@{[ input "battleSkillAcc" , 'number','calcBattle' ]}
                <td>@{[ input "battleSkillAtk" , 'number','calcBattle' ]}
                <td>@{[ input "battleSkillEva" , 'number','calcBattle' ]}
                <td>@{[ input "battleSkillDef" , 'number','calcBattle' ]}
                <td>@{[ input "battleSkillMDef", 'number','calcBattle' ]}
                <td>@{[ input "battleSkillIni" , 'number','calcBattle' ]}
                <td>@{[ input "battleSkillMove", 'number','calcBattle' ]}
                <td rowspan="2" class="left"><textarea name="battleSkillNote" rows="3" placeholder="備考">$pc{battleSkillNote}</textarea>
              <tr>
                <th></th>
                <td colspan="2" class="right small">ダイス数修正:
                <td>@{[ input "battleSkillAccDice" , 'number','calcBattle' ]}
                <td>@{[ input "battleSkillAtkDice" , 'number','calcBattle' ]}
                <td>@{[ input "battleSkillEvaDice" , 'number','calcBattle' ]}
                <td>
                <td>
                <td>
                <td>
              </tr>
            </tbody>
            <tbody>
              <tr>
                <th>他
                <td colspan="2">@{[ input "battleOtherName" ]}
                <td>@{[ input "battleOtherAcc" , 'number','calcBattle' ]}
                <td>@{[ input "battleOtherAtk" , 'number','calcBattle' ]}
                <td>@{[ input "battleOtherEva" , 'number','calcBattle' ]}
                <td>@{[ input "battleOtherDef" , 'number','calcBattle' ]}
                <td>@{[ input "battleOtherMDef", 'number','calcBattle' ]}
                <td>@{[ input "battleOtherIni" , 'number','calcBattle' ]}
                <td>@{[ input "battleOtherMove", 'number','calcBattle' ]}
                <td rowspan="2" class="left"><textarea name="battleOtherNote" rows="3" placeholder="備考">$pc{battleOtherNote}</textarea>
              <tr>
                <th>
                <td colspan="2" class="right small">ダイス数修正:
                <td>@{[ input "battleOtherAccDice" , 'number','calcBattle' ]}
                <td>@{[ input "battleOtherAtkDice" , 'number','calcBattle' ]}
                <td>@{[ input "battleOtherEvaDice" , 'number','calcBattle' ]}
                <td>
                <td>
                <td>
                <td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="battle-total-value">
                <th colspan="3">
                  合計<br>
                  (右手・左手:<select name="handedness" onchange="changeHandedness()">@{[ option 'handedness', 'def=1|<合計しない>', '2|<両手を合計>', '3|<命中のみ合計>', '4|<全部表示>' ]}</select>)
                <td>
                  <b id="battle-total-acc-right" data-name="右"></b>
                  <b id="battle-total-acc-left" data-name="左"></b>
                  <b id="battle-total-acc" data-name="計"></b>
                <td>
                  <b id="battle-total-atk-right" data-name="右"></b>
                  <b id="battle-total-atk-left" data-name="左"></b>
                  <b id="battle-total-atk" data-name="計"></b>
                <td id="battle-total-eva">
                <td id="battle-total-def">
                <td id="battle-total-mdef">
                <td id="battle-total-ini">
                <td id="battle-total-move">
              <tr class="battle-total-dice">
                <th colspan="3">＋ダイス数
                <td>+<b id="battle-dice-acc"></b>D
                <td>+<b id="battle-dice-atk"></b>D
                <td>+<b id="battle-dice-eva"></b>D
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
      <div class="box" id="other-rolls">
        <h2 class="in-toc">特殊な判定</h2>
        <table class="edit-table no-border-cells">
          <colgroup>
            <col><col><col><col><col>
          </colgroup>
          <thead>
            <th>
            <th>スキル
            <th>その他
            <th class="small">ダイス数
            <th>合計
          </thead>
          <tbody>
            <tr>
              <th>トラップ探知<small>(【感知】)</small>
              <td>@{[ input "rollTrapDetectSkill",'number','calcRolls' ]}
              <td>@{[ input "rollTrapDetectOther",'number','calcRolls' ]}
              <td>@{[ input "rollTrapDetectDiceAdd",'number','calcRolls' ]}
              <td class="roll">
                <b id="roll-trapdetect-total"></b>
                <span>+<b id="roll-trapdetect-total-dice"></b>D</span>
              </td>
            <tr>
              <th>トラップ解除<small>(【器用】)</small>
              <td>@{[ input "rollTrapReleaseSkill",'number','calcRolls' ]}
              <td>@{[ input "rollTrapReleaseOther",'number','calcRolls' ]}
              <td>@{[ input "rollTrapReleaseDiceAdd",'number','calcRolls' ]}
              <td class="roll">
                <b id="roll-traprelease-total"></b>
                <span>+<b id="roll-traprelease-total-dice"></b>D</span>
              </td>
            <tr>
              <th>危険感知<small>(【感知】)</small>
              <td>@{[ input "rollDangerDetectSkill",'number','calcRolls' ]}
              <td>@{[ input "rollDangerDetectOther",'number','calcRolls' ]}
              <td>@{[ input "rollDangerDetectDiceAdd",'number','calcRolls' ]}
              <td class="roll">
                <b id="roll-dengerdetect-total"></b>
                <span>+<b id="roll-dengerdetect-total-dice"></b>D</span>
              </td>
            <tr>
              <th>エネミー識別<small>(【知力】)</small>
              <td>@{[ input "rollEnemyLoreSkill",'number','calcRolls' ]}
              <td>@{[ input "rollEnemyLoreOther",'number','calcRolls' ]}
              <td>@{[ input "rollEnemyLoreDiceAdd",'number','calcRolls' ]}
              <td class="roll">
                <b id="roll-enemylore-total"></b>
                <span>+<b id="roll-enemylore-total-dice"></b>D</span>
              </td>
            </tr>
          </tbody>
        </table>
        <table class="edit-table no-border-cells">
          <colgroup>
            <col><col><col><col><col>
          </colgroup>
          <thead>
            <th>
            <th>スキル
            <th>その他
            <th class="small">ダイス数
            <th>合計
          </thead>
          <tbody>
            <tr>
              <th>アイテム鑑定<small>(【知力】)</small>
              <td>@{[ input "rollAppraisalSkill",'number','calcRolls' ]}
              <td>@{[ input "rollAppraisalOther",'number','calcRolls' ]}
              <td>@{[ input "rollAppraisalDiceAdd",'number','calcRolls' ]}
              <td class="roll">
                <b id="roll-appraisal-total"></b>
                <span>+<b id="roll-appraisal-total-dice"></b>D</span>
              </td>
            <tr>
              <th>魔術判定<small>(【知力】)</small>
              <td>@{[ input "rollMagicSkill",'number','calcRolls' ]}
              <td>@{[ input "rollMagicOther",'number','calcRolls' ]}
              <td>@{[ input "rollMagicDiceAdd",'number','calcRolls' ]}
              <td class="roll">
                <b id="roll-magic-total"></b>
                <span>+<b id="roll-magic-total-dice"></b>D</span>
              </td>
            <tr>
              <th>呪歌判定<small>(【精神】)</small>
              <td>@{[ input "rollSongSkill",'number','calcRolls' ]}
              <td>@{[ input "rollSongOther",'number','calcRolls' ]}
              <td>@{[ input "rollSongDiceAdd",'number','calcRolls' ]}
              <td class="roll">
                <b id="roll-song-total"></b>
                <span>+<b id="roll-song-total-dice"></b>D</span>
              </td>
            <tr>
              <th>錬金術判定<small>(【器用】)</small>
              <td>@{[ input "rollAlchemySkill",'number','calcRolls' ]}
              <td>@{[ input "rollAlchemyOther",'number','calcRolls' ]}
              <td>@{[ input "rollAlchemyDiceAdd",'number','calcRolls' ]}
              <td class="roll">
                <b id="roll-alchemy-total"></b>
                <span>+<b id="roll-alchemy-total-dice"></b>D</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div id="area-items">
        <div id="items-and-money">
          <dl class="box" id="weight">
            <dt>携帯重量／携帯可能重量
            <dd><span id="items-weight-total"></span>／<span id="items-weight-limit"></span>
          </dl>
          <dl class="box" id="money">
            <dt class="in-toc">所持金
            <dd>@{[ checkbox 'moneyAuto', '自動計算', 'calcCash' ]}
            <dd>@{[ input 'money' ]} G
          </dl>
          <div class="box" id="items">
            <h2 class="in-toc">携帯品・所持品</h2>
            <textarea name="items" oninput="calcWeight();" placeholder="例）冒険者セット @[5]&#13;&#10;　　HPポーション @[1]&#13;&#10;　　MPポーションx2 @[2]">$pc{items}</textarea>
            <ul class="annotate">
              <li><code>@[n]</code>の書式を入力すると携帯重量として計算されます。<br>
              （<code>n</code>には数値を入れてください）<br>
            </ul>
          </div>
          <details class="box" id="cashbook" @{[ $pc{cashbook} || $pc{money} =~ /^(?:自動|auto)$/i ? 'open' : '' ]}>
            <summary class="in-toc">収支履歴</summary>
            <textarea name="cashbook" oninput="calcCash();" placeholder="例）冒険者セット::-10&#13;&#10;　　HPポーション売却::+15">$pc{cashbook}</textarea>
            <p>
              所持金：<span id="cashbook-total-value">$pc{moneyTotal}</span> G
            </p>
            <ul class="annotate">
              <li><code>::+n</code> <code>::-n</code>の書式で入力すると加算・減算されます。（<code>n</code>には金額を入れてください）
              <li><span class="underline">セッション履歴に記入されたゴールド報酬は自動的に加算されます。</span>
              <li>所持金欄に<code>自動</code>または<code>auto</code>と記入すると、収支の計算結果を反映します。
            </ul>
          </details>
        </div>

        <div id="relations">
          <div class="box" id="geises">
            <h2 class="in-toc">誓約</h2>
            @{[input 'geisesNum','hidden']}
            <table class="edit-table no-border-cells" id="geises-table">
              <colgroup>
                <col class="handle">
                <col class="name">
                <col class="num">
                <col>
              </colgroup>
              <thead>
                <tr><th><th><th>成長点<th class="left">恩恵・束縛など
              <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{geisesNum}){
  if($num eq 'TMPL'){ print '<template id="geis-template">' }
print <<"HTML";
                <tr id="geis-row${num}">
                  <td class="handle">
                  <td>@{[ input "geis${num}Name" ]}
                  <td>@{[ input "geis${num}Cost", 'number', 'calcGeises' ]}
                  <td><textarea name="geis${num}Note">$pc{"geis${num}Note"}</textarea>
                </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </table>
            <div class="add-del-button"><a onclick="addGeis()">▼</a><a onclick="delGeis()">▲</a></div>
          </div>
          <div class="box-union in-toc" id="guild" data-content-title="所属ギルド">
            <dl class="box">
              <dt>所属ギルド<dd>@{[ input 'guildName' ]}
            </dl>
            <dl class="box">
              <dt>ギルドマスター<dd>@{[ input 'guildMaster' ]}
            </dl>
          </div>

          <div class="box" id="connections">
            <h2 class="in-toc">コネクション</h2>
            @{[input 'connectionsNum','hidden']}
            <table class="edit-table no-border-cells" id="connections-table">
              <colgroup>
                <col class="handle">
                <col class="name">
                <col class="relation">
                <col>
              </colgroup>
              <thead><tr><th><th><th>関係<th class="left">備考
              <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{connectionsNum}){
  if($num eq 'TMPL'){ print '<template id="connection-template">' }
print <<"HTML";
                <tr id="connection-row${num}">
                  <td class="handle">
                  <td>@{[ input "connection${num}Name",'','calcConnections' ]}
                  <td>@{[ input "connection${num}Relation" ]}
                  <td>@{[ input "connection${num}Note" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </table>
            <div class="add-del-button"><a onclick="addConnection()">▼</a><a onclick="delConnection()">▲</a></div>
            <ul class="annotate"><li>名前を入れると成長点が計算されます。</ul>
          </div>
        </div>
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
              <th class="exp   ">成長点
              <th class="pay   ">- 上納
              <th class="money ">ゴールド
              <th class="gm    ">GM
              <th class="member">参加者
            <tr>
              <td>-
              <td>
              <td>キャラクター作成
              <td id="history0-exp">$pc{history0Exp}
              <td>
              <td id="history0-money">$pc{history0Money}
            </tr>
HTML
foreach my $num ('TMPL',1 .. $pc{historyNum}) {
  if($num eq 'TMPL'){ print '<template id="history-template">' }
print <<"HTML";
          <tbody id="history-row${num}">
            <tr>
              <td class="handle" rowspan="2" class="handle">
              <td class="date  " rowspan="2">@{[input("history${num}Date")]}
              <td class="title " rowspan="2">@{[input("history${num}Title")]}
              <td class="exp   ">@{[input("history${num}Exp",'text','calcExp')]}
              <td class="pay   ">@{[input("history${num}Payment",'number','calcExp')]}
              <td class="money ">@{[input("history${num}Money",'text','calcCash')]}
              <td class="gm    ">@{[input("history${num}Gm")]}
              <td class="member">@{[input("history${num}Member")]}
            <tr>
              <td colspan="6" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          <tfoot id="history-foot">
            <tr>
              <td>
              <td>
              <td>取得総計
              <td id="history-exp-total">
              <td id="history-payment-total">
              <td id="history-money-total">
              <td colspan="2">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="exp   ">成長点
              <th class="pay   ">- 上納
              <th class="money ">ゴールド
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
              <th>成長点
              <th>- 上納
              <th>ゴールド
              <th>GM
              <th>参加者
            </tr>
          <tbody>
            <tr>
              <td>-
              <td><input type="text" value="2018-08-11" disabled>
              <td><input type="text" value="第十四話「記入例」" disabled>
              <td><input type="text" value="14+1" disabled>
              <td><input type="text" value="5" disabled>
              <td><input type="text" value="1400" disabled>
              <td><input type="text" value="サンプルさん" disabled>
              <td><input type="text" value="アルバート　ラミット　ブランデン　レンダ・レイ　ナイルベルト" disabled>
            </tr>
          </tbody>
        </table>
        <ul class="annotate">
          <li>「成長点」欄は<code>10+2</code>など四則演算が有効です。
          <li>「上納」欄に入力した数値ぶん、成長点の合計が引かれます。
        </ul>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
      </div>
      
      <div class="box" id="exp-footer">
        <p>
        成長点[<b id="exp-total"></b>] - 
        ( ＣＬ[<b id="exp-used-level"></b>]
        + 一般スキル[<b id="exp-used-skill"></b>]
        + 誓約[<b id="exp-used-geises"></b>]
        + コネ[<b id="exp-used-connections"></b>]
        ) = 残り[<b id="exp-rest"></b>]点
        ｜
        スキルLv[<span id="skills-lv-total">0</span>/<span id="skills-lv-limit">0</span><span id="skills-lv-limit-add">0</span>]
        ｜
        一般スキルLv[<span id="gskills-lv-total">0</span>/<span id="gskills-lv-limit">0</span>]
        </p>
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
print textRuleArea( '','「容姿・経歴・その他メモ」「履歴（自由記入）」「所持品」「収支履歴」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">©FarEast Amusement Research Co.,Ltd.「アリアンロッドRPG 2E」</p>
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
  <datalist id="list-area">
    <option value="エリンディル大陸西方">
    <option value="エリンディル大陸東方">
    <option value="アルディオン大陸東方">
    <option value="アースラン">
    <option value="マジェラニカ大陸">
  </datalist>
  <datalist id="list-category">
    <option value="魔術">
    <option value="魔術〈〉">
    <option value="錬金術">
    <option value="呪歌">
    <option value="ロール">
  </datalist>
  <datalist id="list-timing">
    <option value="パッシブ">
    <option value="ムーブ">
    <option value="マイナー">
    <option value="メジャー">
    <option value="リアクション">
    <option value="フリー">
    <option value="レガシー">
    <option value="セットアップ">
    <option value="イニシアチブ">
    <option value="クリンナップ">
    <option value="判定の直前">
    <option value="判定の直後">
    <option value="DRの直前">
    <option value="DRの直後">
    <option value="《》">
    <option value="戦闘不能">
    <option value="アイテム">
    <option value="戦闘前">
    <option value="効果参照">
    <option value="メイキング">
    <option value="パッシブ／メイキング">
    <option value="効果参照／メイキング">
    <option value="ムーブ／メイキング">
    <option value="セットアップ／メイキング">
    <option value="イニシアチブ／メイキング">
    <option value="判定の直後／メイキング">
  </datalist>
  <datalist id="list-roll">
    <option value="―">
    <option value="自動成功">
    <option value="命中判定">
    <option value="魔術判定">
    <option value="錬金術判定">
    <option value="呪歌判定">
    <option value="回避判定">
    <option value="筋力">
    <option value="器用">
    <option value="敏捷">
    <option value="知力">
    <option value="感知">
    <option value="精神">
    <option value="幸運">
    <option value="効果参照">
  </datalist>
  <datalist id="list-target">
    <option value="―">
    <option value="自身">
    <option value="単体">
    <option value="SL体">
    <option value="[SL+1]体">
    <option value="範囲">
    <option value="範囲（選択）">
    <option value="範囲（[SL×2]体）">
    <option value="場面">
    <option value="場面（選択）">
    <!-- <option value="十字"> -->
    <option value="十字（選択）"">
    <!-- <option value="直線"> -->
    <option value="直線（選択）"">
    <option value="効果参照">
  </datalist>
  <datalist id="list-cost">
    <option value="―">
  </datalist>
  <datalist id="list-range">
    <option value="―">
    <option value="10m">
    <option value="20m">
    <option value="30m">
    <option value="至近">
    <option value="武器">
    <option value="視界">
    <option value="シーン">
    <option value="効果参照">
  </datalist>
  <datalist id="list-weapon-range">
    <option value="―">
    <option value="10m">
    <option value="20m">
    <option value="30m">
    <option value="至近">
    <option value="効果参照">
  </datalist>
  <datalist id="list-weapon-type">
    <option value="格闘">
    <option value="短剣">
    <option value="長剣">
    <option value="両手剣">
    <option value="斧">
    <option value="打撃">
    <option value="槍">
    <option value="鞭">
    <option value="弓">
    <option value="刀">
    <option value="魔導銃">
    <option value="錬金銃">
    <option value="錬金術">
    <option value="盾">
  </datalist>
  <datalist id="list-weapon-usage">
    <option value="片">
    <option value="片（両）">
    <option value="両">
    <option value="双">
  </datalist>
  <datalist id="list-armour-usage">
    <option value="胴部">
    <option value="全身">
  </datalist>
  <datalist id="list-reqd">
    <option value="―">
    <option value="装備">
    <option value="使用">
    <option value="防御中1回">
    <option value="ラウンド1回">
    <option value="シーン1回">
    <option value="シーンSL回">
    <option value="シナリオ1回">
    <option value="シナリオSL回">
    <option value="隠密">
  </datalist>
  <script>
  const races = @{[ JSON::PP->new->encode(\%data::races) ]};
  const classes = @{[ JSON::PP->new->encode(\%data::class) ]};
  let expUse = {
    'level'      : @{[ $pc{expUsedLevel        } || 0 ]},
    'skills'     : @{[ $pc{expUsedGeneralSkills} || 0 ]},
    'connections': @{[ $pc{expUsedConnections  } || 0 ]},
    'geises'     : @{[ $pc{expUsedGeises} || 0 ]},
  };
HTML
print <<"HTML";
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;