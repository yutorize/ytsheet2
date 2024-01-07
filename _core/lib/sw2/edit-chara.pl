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
require $set::data_class;
require $set::data_feats;
require $set::data_races;
require $set::data_items;
require $set::data_faith;

### データ読み込み ###################################################################################
my ($data, $mode, $file, $message) = pcDataGet($::in{mode});
our %pc = %{ $data };

my $mode_make = ($mode =~ /^(blanksheet|copy|convert)$/) ? 1 : 0;

### 出力準備 #########################################################################################
if($message){
  my $name = tagUnescape($pc{characterName} || $pc{aka} || '無題');
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
  $pc{history0Honor} = $set::make_honor;
  $pc{history0Money} = $set::make_money;
  $pc{expTotal} = $pc{history0Exp};

  $pc{money}   = '自動';
  $pc{deposit} = '自動';
  
  if($::in{stt}){
    ($pc{sttBaseTec}, $pc{sttBasePhy}, $pc{sttBaseSpi}, $pc{sttBaseA}, $pc{sttBaseB}, $pc{sttBaseC}, $pc{sttBaseD}, $pc{sttBaseE}, $pc{sttBaseF}) = split(/_/, $::in{stt});
    $pc{race} = Encode::decode('utf8', $::in{race});
    if($data::races{$pc{race}}{variant} && !$data::races{$pc{race}}{ability}){
      $pc{race} .= "（$data::races{$pc{race}}{variantSort}[0]）";
    }
    if($::in{making_num}){
      $pc{history0Note} = "能力値作成履歴#$::in{making_num}";
    }
  }
  
  $pc{defTotal1CheckArmour1} = $pc{defTotal1CheckArmour2} = $pc{defTotal1CheckArmour3} = 1;
  $pc{armour2Category} = '盾';
  $pc{armour3Category} = 'その他';
  
  $pc{paletteUseBuff} = 1;
}

## 画像
$pc{imageFit} = $pc{imageFit} eq 'percent' ? 'percentX' : $pc{imageFit};
$pc{imagePercent} = $pc{imagePercent} eq '' ? '200' : $pc{imagePercent};
$pc{imagePositionX} = $pc{imagePositionX} eq '' ? '50' : $pc{imagePositionX};
$pc{imagePositionY} = $pc{imagePositionY} eq '' ? '50' : $pc{imagePositionY};
$pc{wordsX} ||= '右';
$pc{wordsY} ||= '上';

## カラー
setDefaultColors();

## その他
$pc{weaponNum}     ||=  1;
$pc{armourNum}     ||=  3;
$pc{languageNum}   ||=  3;
$pc{honorItemsNum} ||=  3;
$pc{historyNum}    ||=  3;

$pc{accuracyEnhance} ||= 0;
$pc{evasiveManeuver} ||= 0;
$pc{tenacity} ||= 0;
$pc{capacity} ||= 0;

### 改行処理 --------------------------------------------------
$pc{words}         =~ s/&lt;br&gt;/\n/g;
$pc{items}         =~ s/&lt;br&gt;/\n/g;
$pc{freeNote}      =~ s/&lt;br&gt;/\n/g;
$pc{freeHistory}   =~ s/&lt;br&gt;/\n/g;
$pc{cashbook}      =~ s/&lt;br&gt;/\n/g;
$pc{fellowProfile} =~ s/&lt;br&gt;/\n/g;
$pc{fellowNote}    =~ s/&lt;br&gt;/\n/g;
$pc{chatPalette}   =~ s/&lt;br&gt;/\n/g;

### フォーム表示 #####################################################################################
my $titlebarname = tagDelete nameToPlain tagUnescape ($pc{characterName}||"“$pc{aka}”");
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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="./?mode=js-consts&ver=${main::ver}"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/sw2/edit-chara.js?${main::ver}" defer></script>
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
          <li onclick="sectionSelect('common');"><span>キャラクター</span><span>データ</span>
          <li onclick="sectionSelect('fellow');"><span>フェロー</span><span>データ</span>
          <li onclick="sectionSelect('palette');"><span>チャット</span><span>パレット</span>
          <li onclick="sectionSelect('color');" class="color-icon" title="カラーカスタム">
          <li onclick="view('text-rule')" class="help-icon" title="テキスト整形ルール">
          <li onclick="nightModeChange()" class="nightmode-icon" title="ナイトモード切替">
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
      <p id="edit-protect-view"><input type="hidden" name="protectOld" value="$pc{protect}">
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
      </p>
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
      
      <div class="box" id="name-form">
        <div>
          <dl id="character-name">
            <dt>キャラクター名
            <dd>@{[input('characterName','text',"nameSet")]}
          </dl>
          <dl id="aka">
            <dt>二つ名
            <dd>@{[input('aka','text',"nameSet")]}
            <dt class="ruby">フリガナ
            <dd>@{[input('akaRuby','text',"nameSet")]}
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
          <dt>経験点
          <dd>@{[input("history0Exp",'number','changeRegu','step="500"'.($set::make_fix?' readonly':''))]}
          <dt>所持金
          <dd>@{[input("history0Money",'number','changeRegu', ($set::make_fix?' readonly':''))]}
          <dt>名誉点
          <dd>@{[input("history0Honor",'number','changeRegu', ($set::make_fix?' readonly':''))]}
          <dt>成長
          <dd>
            <dl class="regulation-grow">
              <dt>器用度<dd>@{[ input "sttPreGrowA",'number','calcStt' ]}
              <dt>敏捷度<dd>@{[ input "sttPreGrowB",'number','calcStt' ]}
              <dt>筋力  <dd>@{[ input "sttPreGrowC",'number','calcStt' ]}
              <dt>生命力<dd>@{[ input "sttPreGrowD",'number','calcStt' ]}
              <dt>知力  <dd>@{[ input "sttPreGrowE",'number','calcStt' ]}
              <dt>精神力<dd>@{[ input "sttPreGrowF",'number','calcStt' ]}
            </dl>
        </dl>
        <div class="annotate">※経験点は、初期所有技能のぶんを含みます。</div>
        <dl class="regulation-note"><dt>備考<dd>@{[ input "history0Note" ]}</dl>
      </details>
      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}

        <div id="personal" class="in-toc" data-content-title="種族・信仰">
          <dl class="box" id="race">
            <dt>種族<dd>@{[ selectInput 'race', 'changeRace(this.value)', @data::race_list,'label=その他' ]}
          </dl>
          <dl class="box" id="age">
            <dt>年齢<dd>@{[input('age')]}
          </dl>
          <dl class="box" id="gender">
            <dt>性別<dd>@{[input('gender','','','list="list-gender"')]}
          </dl>
          <dl class="box" id="race-ability">
            <dt>種族特徴
            <dd>
              <span id="race-ability-value">@{[ !$pc{race} ? '' : exists $data::races{$pc{race}} ? $pc{raceAbility} : input("raceAbilityFree",'','changeRaceAbility') ]}</span>
HTML
{
  print '<span id="race-ability-select">';
  my $i = 1;
  foreach (@{$data::races{$pc{race}}{ability}},@{$data::races{$pc{race}}{abilityLv6}},@{$data::races{$pc{race}}{abilityLv11}},@{$data::races{$pc{race}}{abilityLv16}}){
    if(ref($_) eq 'ARRAY'){
      print '<select name="raceAbilitySelect'.$i.'" oninput="changeRaceAbility()" class="hidden">';
      print option('raceAbilitySelect'.$i, @{$_});
      print '</select>';
      $i++;
    }
  }
  print '</span>';
}
print <<"HTML";
          </dl>
          <dl class="box" id="sin">
            <dt>穢れ<dd>@{[input('sin','number','','min="0"')]}
          </dl>
          <dl class="box" id="birth">
            <dt>生まれ<dd>@{[input('birth')]}
          </dl>
          <dl class="box" id="faith">
HTML
print '<dt>信仰<dd class="select-input '.($pc{faith} eq 'その他の信仰' ? 'free' : '').'"><select name="faith" oninput="changeFaith(this)">';
print '<option>';
print '<option'.($pc{faith} eq 'なし' ? ' selected' : '').'>なし';
foreach my $type (1,3,2,0) {
  print '<optgroup label="'.($type eq 1 ? '第一の剣' : $type eq 3 ? '第三の剣' : $type eq 2 ? '第二の剣' : 'その他').'">';
  foreach my $gods (@data::gods){
    next if $type ne @$gods[0];
    my $name = @$gods[2] && @$gods[3] ? "“@$gods[2]”@$gods[3]" : @$gods[2] ? "“@$gods[2]”" : @$gods[3];
    print '<option'.(($pc{faith} eq $name)?' selected':'').">$name";
  }
  print '</optgroup>';
}
print "</select>".input('faithOther','text','', ' placeholder="自由記入欄"')."</dl>\n";
print <<"HTML";
        </div>

        <div id="status" class="in-toc" data-content-title="能力値">
          <dl class="box" id="stt-base-tec"><dt>技<dd>@{[input('sttBaseTec','number','calcStt')]}</dl>
          <dl class="box" id="stt-base-phy"><dt>体<dd>@{[input('sttBasePhy','number','calcStt')]}</dl>
          <dl class="box" id="stt-base-spi"><dt>心<dd>@{[input('sttBaseSpi','number','calcStt')]}</dl>
          
          <dl class="box" id="stt-base-A"><dt>Ａ<dd>@{[input('sttBaseA','number','calcStt')]}</dl>
          <dl class="box" id="stt-base-B"><dt>Ｂ<dd>@{[input('sttBaseB','number','calcStt')]}</dl>
          <dl class="box" id="stt-base-C"><dt>Ｃ<dd>@{[input('sttBaseC','number','calcStt')]}</dl>
          <dl class="box" id="stt-base-D"><dt>Ｄ<dd>@{[input('sttBaseD','number','calcStt')]}</dl>
          <dl class="box" id="stt-base-E"><dt>Ｅ<dd>@{[input('sttBaseE','number','calcStt')]}</dl>
          <dl class="box" id="stt-base-F"><dt>Ｆ<dd>@{[input('sttBaseF','number','calcStt')]}</dl>
          
          <dl class="box" id="stt-grow-A"><dt>成長<dd id="stt-grow-A-value">$pc{sttGrowA}</dl>
          <dl class="box" id="stt-grow-B"><dt>成長<dd id="stt-grow-B-value">$pc{sttGrowB}</dl>
          <dl class="box" id="stt-grow-C"><dt>成長<dd id="stt-grow-C-value">$pc{sttGrowC}</dl>
          <dl class="box" id="stt-grow-D"><dt>成長<dd id="stt-grow-D-value">$pc{sttGrowD}</dl>
          <dl class="box" id="stt-grow-E"><dt>成長<dd id="stt-grow-E-value">$pc{sttGrowE}</dl>
          <dl class="box" id="stt-grow-F"><dt>成長<dd id="stt-grow-F-value">$pc{sttGrowF}</dl>
          
          <dl class="box" id="stt-dex"><dt>器用度<dd id="stt-dex-value">$pc{sttDex}</dl>
          <dl class="box" id="stt-agi"><dt>敏捷度<dd id="stt-agi-value">$pc{sttAgi}</dl>
          <dl class="box" id="stt-str"><dt>筋力  <dd id="stt-str-value">$pc{sttStr}</dl>
          <dl class="box" id="stt-vit"><dt>生命力<dd id="stt-vit-value">$pc{sttVit}</dl>
          <dl class="box" id="stt-int"><dt>知力  <dd id="stt-int-value">$pc{sttInt}</dl>
          <dl class="box" id="stt-mnd"><dt>精神力<dd id="stt-mnd-value">$pc{sttMnd}</dl>
          
          <dl class="box" id="stt-add-A"><dt>増強<dd>@{[input('sttAddA','number','calcStt')]}</dl>
          <dl class="box" id="stt-add-B"><dt>増強<dd>@{[input('sttAddB','number','calcStt')]}</dl>
          <dl class="box" id="stt-add-C"><dt>増強<dd>@{[input('sttAddC','number','calcStt')]}</dl>
          <dl class="box" id="stt-add-D"><dt>増強<dd>@{[input('sttAddD','number','calcStt')]}</dl>
          <dl class="box" id="stt-add-E"><dt>増強<dd>@{[input('sttAddE','number','calcStt')]}</dl>
          <dl class="box" id="stt-add-F"><dt>増強<dd>@{[input('sttAddF','number','calcStt')]}</dl>
          
          <dl class="box" id="stt-bonus-dex"><dt><span>器用度</span><dd id="stt-bonus-dex-value">$pc{bonusDex}</dl>
          <dl class="box" id="stt-bonus-agi"><dt><span>敏捷度</span><dd id="stt-bonus-agi-value">$pc{bonusAgi}</dl>
          <dl class="box" id="stt-bonus-str"><dt><span>筋力  </span><dd id="stt-bonus-str-value">$pc{bonusStr}</dl>
          <dl class="box" id="stt-bonus-vit"><dt><span>生命力</span><dd id="stt-bonus-vit-value">$pc{bonusVit}</dl>
          <dl class="box" id="stt-bonus-int"><dt><span>知力  </span><dd id="stt-bonus-int-value">$pc{bonusInt}</dl>
          <dl class="box" id="stt-bonus-mnd"><dt><span>精神力</span><dd id="stt-bonus-mnd-value">$pc{bonusMnd}</dl>
          
          <dl class="box" id="stt-pointbuy-TPS">
            <dt>割振りPt.
            <dd id="stt-pointbuy-TPS-value">
          </dl>
          <dl class="box" id="stt-pointbuy-AtoF">
            <dt>割振りPt.
            <dd id="stt-pointbuy-AtoF-value">
          </dl>
          <dl class="box" id="stt-grow-total">
            <dt>成長合計
            <dd><span><span id="stt-grow-total-value"></span><span id="stt-grow-max-value"></span></span>
          </dl>
          <dl class="box" id="stt-pointbuy-type">
            <dt>ポイント割り振りの計算式
            <dd><select name="pointbuyType" onchange="calcStt();">
            <option value="2.5" @{[$pc{pointbuyType} eq '2.5' ? 'selected':'']}>2.5式(ET)</option>
            <option value="2.0" @{[$pc{pointbuyType} eq '2.0' ? 'selected':'']}>2.0式(AW,EX)</option>
            </select>
          </dl>
        </div>

        <div class="box-union in-toc" id="sub-status" data-content-title="ＨＰ・ＭＰ・抵抗力">
          <dl class="box">
            <dt id="vit-resist">生命抵抗力
            <dd><span id="vit-resist-base">$pc{vitResistBase}</span>+<span id="vit-resist-auto-add">$pc{vitResistAutoAdd}</span>+@{[input('vitResistAdd','number','calcSubStt')]}=<b id="vit-resist-total">$pc{vitResistTotal}</b>
          </dl>
          <dl class="box">
          <dt id="mnd-resist">精神抵抗力
          <dd><span id="mnd-resist-base">$pc{mndResistBase}</span>+<span id="mnd-resist-auto-add">$pc{mndResistAutoAdd}</span>+@{[input('mndResistAdd','number','calcSubStt')]}=<b id="mnd-resist-total">$pc{mndResistTotal}</b>
          </dl>
          <dl class="box">
            <dt id="hp">ＨＰ
            <dd><span id="hp-base">$pc{hpBase}</span>+<span id="hp-auto-add">$pc{hpAutoAdd}</span>+@{[input('hpAdd','number','calcSubStt')]}=<b id="hp-total">$pc{hpTotal}</b>
          </dl>
          <dl class="box">
            <dt id="mp">ＭＰ
            <dd><span id="mp-base">$pc{mpBase}</span>+<span id="mp-auto-add">$pc{mpAutoAdd}</span>+@{[input('mpAdd','number','calcSubStt')]}=<b id="mp-total">$pc{mpTotal}</b>
          </dl>
        </div>
        
        <dl class="box" id="level">
          <dt>冒険者レベル<dd id="level-value">$pc{level}
        </dl>
        <dl class="box" id="exp">
          <dt>経験点<dd><div><span id="exp-rest">$pc{expRest}</span><br>／<br><span id="exp-total">$pc{expTotal}</span></div>
        </dl>
      </div>
      
      <div id="area-ability">
        <div id="area-classes" class="in-toc" data-content-title="技能">
          <div class="box" id="classes">
            <h2>技能</h2>
            <div>使用経験点：<span id="exp-use"></span></div>
HTML
print '<div class="classes-group" id="classes-weapon-user"><h3>戦士系技能</h3><dl class="edit-table side-margin">';
foreach my $name (@data::class_names){ print classInputBox($name) if $data::class{$name}{type} eq 'weapon-user'; }
print '</dl></div>';
print '<div class="classes-group" id="classes-magic-user"><h3>魔法使い系技能</h3><dl class="edit-table side-margin">';
foreach my $name (@data::class_names){ print classInputBox($name) if $data::class{$name}{type} eq 'magic-user'; }
print '</dl></div>';
print '<div class="classes-group" id="classes-other-user"><h3>その他系技能</h3><dl class="edit-table side-margin">';
foreach my $name (@data::class_names){ print classInputBox($name) if !$data::class{$name}{type}; }
print '</dl></div>';

sub classInputBox {
  my $name = shift;
  return if $data::class{$name}{2.0} && !$set::all_class_on;
  my $id = $data::class{$name}{id};
  my $out;
  $out .= '<dt id="class'.$id.'"';
  $out .= ' class="zero-data"' if $data::class{$name}{'2.0'};
  $out .= '>';
  $out .= '[2.0] ' if $data::class{$name}{'2.0'};
  $out .= $name;
  $out .= '<select name="faithType" style="width:auto;">'.option('faithType','†|<†セイクリッド系>','‡|<‡ヴァイス系>','†‡|<†‡両系統使用可>').'</select>' if($name eq 'プリースト');
  $out .= '<dd>' . input("lv${id}", 'number','changeLv','min="0" max="17"');
  return $out;
}
print <<"HTML";
            </dl>
          </div>
          <div class="box" id="common-classes">
            <h2>一般技能</h2>
            <table id="common-classes-table" class="edit-table side-margin">
            <tbody>
HTML
foreach my $i (1..10){
print <<"HTML";
              <tr id="common-class${i}"><td class="handle"><td>@{[input('commonClass'.$i)]}<td>@{[input('lvCommon'.$i, 'number','','min="0" max="17"')]}
HTML
}
print <<"HTML";
            </tbody>
            </table>
          </div>
        </div>
        <p class="left">@{[ input "failView", "checkbox", "checkFeats()" ]} 習得レベルの足りない項目（特技／練技・呪歌など）も表示する</p>
        <div>
          <div class="box" id="combat-feats">
            <h2 class="in-toc">戦闘特技</h2>
            <ul class="edit-table side-margin">
HTML
foreach my $lv ('1bat',@set::feats_lv) {
  (my $data_lv = $lv) =~ s/^([0-9]+)[^0-9].*?$/$1/;
  print '<li id="combat-feats-lv'.$lv.'" data-lv="'.$data_lv.($data_lv eq $lv ? '':'+').'"><select name="combatFeatsLv'.$lv.'" oninput="checkFeats()">';
  print '<option></option>';
  foreach my $type ('常','宣','主') {
    print '<optgroup label="'.($type eq '常' ? '常時' : $type eq '宣' ? '宣言' : $type eq '宣' ? '宣言' : '主動作').'特技">';
    foreach my $feats (@data::combat_feats){
      next if $data_lv < @$feats[1];
      next if $type ne @$feats[0];
      next if @$feats[3] =~ /2.0/ && !$set::all_class_on;
      if($lv =~ /bat/ && @$feats[3] !~ /バトルダンサー/){ next; }
      if(@$feats[3] =~ /ヴァグランツ/){
        print '<option class="vagrants"'.(($pc{"combatFeatsLv$lv"} eq @$feats[2])?' selected':'').' value="'.@$feats[2].'">'.@$feats[2];
        $pc{featsVagrantsOn} = 1 if $pc{"combatFeatsLv$lv"} eq @$feats[2];
      }
      elsif(@$feats[3] =~ /2.0/){
        print '<option class="zero-data"'.(($pc{"combatFeatsLv$lv"} eq @$feats[2])?' selected':'').' value="'.@$feats[2].'">[2.0]'.@$feats[2];
        $pc{featsZeroOn} = 1 if $pc{"combatFeatsLv$lv"} eq @$feats[2];
      }
      else { print '<option'.(($pc{"combatFeatsLv$lv"} eq @$feats[2])?' selected':'').'>'.@$feats[2]; }
    }
    print '</optgroup>';
  }
  print "</select>\n";
}
print <<"HTML";
            </ul>
            <ul id="combat-feat-vagrants-auto">
              <li id="combat-feat-vagrants-sco5" data-label="スカウト5"  ><select name="combatFeatsExcSco5">@{[ option 'combatFeatsExcSco5', 'def=トレジャーハント','掠め取り','クルードテイク' ]}</select>
              <li id="combat-feat-vagrants-ran5" data-label="レンジャー5"><select name="combatFeatsExcRan5">@{[ option 'combatFeatsExcRan5', 'def=サバイバビリティ','掠め取り','クルードテイク' ]}</select>
              <li id="combat-feat-vagrants-sag5" data-label="セージ5"    ><select name="combatFeatsExcSag5">@{[ option 'combatFeatsExcSag5', 'def=鋭い目','掠め取り','クルードテイク' ]}</select>
            </ul>
            <div class="feats-options">
              <ul>
                <li>@{[ input 'featsVagrantsOn','checkbox','checkFeats' ]}<span>ヴァグランツ戦闘特技を追加</span>
                <li>@{[ input 'featsZeroOn','checkbox','checkFeats' ]}<span>2.0戦闘特技を追加</span>
                <li>@{[ input 'featsAutoOn','checkbox','checkFeats' ]}<span>特技自動置き換え（非推奨）</span>
              </ul>
            </div>
            <p>置き換え可能な場合<span class="mark">強調</span>されます。</p>
          </div>
          <div class="box in-toc" id="mystic-arts" data-content-title="秘伝・秘伝魔法">
            <h2>秘伝</h2>
            <div>所持名誉点：<span id="honor-value-MA"></span></div>
            <ul id="mystic-arts-list" class="edit-table side-margin">
HTML
foreach my $num ('TMPL',1 .. $pc{mysticArtsNum}){
  if($num eq 'TMPL'){ print '<template id="mystic-arts-template">' }
  print '<li id="mystic-arts'.$num.'"><span class="handle"></span>'.(input 'mysticArts'.$num).(input 'mysticArts'.$num.'Pt', 'number', 'calcHonor');
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </ul>
            <div class="add-del-button"><a onclick="addMysticArts()">▼</a><a onclick="delMysticArts()">▲</a></div>
            @{[input('mysticArtsNum','hidden')]}

            <h2>秘伝魔法</h2>
            <ul id="mystic-magic-list" class="edit-table side-margin">
HTML
$pc{mysticMagicNum} ||= 0;
foreach my $num ('TMPL',1 .. $pc{mysticMagicNum}){
  if($num eq 'TMPL'){ print '<template id="mystic-magic-template">' }
  print '<li id="mystic-magic'.$num.'"><span class="handle"></span>'.(input 'mysticMagic'.$num).(input 'mysticMagic'.$num.'Pt', 'number', 'calcHonor');
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </ul>
            <div class="add-del-button"><a onclick="addMysticMagic()">▼</a><a onclick="delMysticMagic()">▲</a></div>
            @{[input('mysticMagicNum','hidden')]}
          </div>
        </div>
        <div id="crafts">
HTML
foreach my $class (@data::class_names){
  next if !$data::class{$class}{magic}{data};
  my $name = $data::class{$class}{magic}{eName};
  my $Name = ucfirst($data::class{$class}{magic}{eName});
  print <<"HTML";
            <div class="box" id="magic-${name}">
              <h2 class="in-toc">$data::class{$class}{magic}{jName}</h2>
              <ul class="edit-table side-margin">
HTML
  foreach my $lv (1..17){
    print '<li id="magic-'.$name.$lv.'"><div class="select-input"><select name="magic'.$Name.$lv.'" oninput="selectInputCheck(\'magic'.$Name.$lv.'\',this);">';
    print '<option></option>';
    my %only; my $hit; my $value = $pc{"magic${Name}${lv}"};
    foreach my $data (@{$data::class{$class}{magic}{data}}){
      next if $lv < @$data[0];
      my $item = '<option';
      if($value eq @$data[1]){
        $item .= ' selected';
        $hit = 1;
      }
      $item .= ' value="'.@$data[1].'">'.@$data[1];
      print $item;
      if ($class eq 'グリモワール'){ print "（@$data[2]）"; }
    }
    foreach my $key (sort keys %only) {
      print "<optgroup label=\"${key}\">$only{$key}</optgroup>";
    }
    print '<option value="free">その他（自由記入）';
    if(!$hit && $value){ print '<option value="'.$value.'" selected>'.$value; }
    print '</select><input type="text" name="magic'.$Name.$lv.'Free"></div>'."\n";
  }
  print <<"HTML";
            </ul>
          </div>
HTML
}
foreach my $class (@data::class_names){
  next if !$data::class{$class}{craft}{data};
  my $name = $data::class{$class}{craft}{eName};
  my $Name = ucfirst($data::class{$class}{craft}{eName});
  print <<"HTML";
            <div class="box" id="craft-${name}">
              <h2 class="in-toc">$data::class{$class}{craft}{jName}</h2>
              <ul class="edit-table side-margin">
HTML
  my $c_max = $class =~ /バード|ウォーリーダー/ ? 20 : $class eq 'アーティザン' ? 19 : 17;
  foreach my $lv (1..$c_max){
    print '<li id="craft-'.$name.$lv.'"><div class="select-input"><select name="craft'.$Name.$lv.'" oninput="'.($class =~ /ウォーリーダー/ ? 'calcPackage();':'').'selectInputCheck(\'craft'.$Name.$lv.'\',this);">';
    print '<option></option>';
    my %only; my $hit; my $value = $pc{"craft${Name}${lv}"};
    foreach my $data (@{$data::class{$class}{craft}{data}}){
      next if $lv < @$data[0];
      my $item = '<option';
      if($value eq @$data[1]){
        $item .= ' selected';
        $hit = 1;
      }
      $item .= ' value="'.@$data[1].'">'.@$data[1];
      
      if(@$data[2] =~ /^(.*?)専用/){ $only{@$data[2]} .= $item; }
      if(@$data[2] =~ /^2.0/)      { $only{'旧(2.0)データ'} .= $item; }
      else { print $item; }
    }
    foreach my $key (sort keys %only) {
      print "<optgroup label=\"${key}\">$only{$key}</optgroup>";
    }
    print '<option value="free">その他（自由記入）';
    if(!$hit && $value){ print '<option value="'.$value.'" selected>'.$value; }
    print '</select><input type="text" name="craft'.$Name.$lv.'Free"></div>'."\n";
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
            <h2 class="in-toc">判定パッケージ</h2>
            <table class="edit-table side-margin">
HTML
foreach my $class (@data::class_names){
  next if !$data::class{$class}{package};
  my $c_id = $data::class{$class}{id};
  my $c_en = $data::class{$class}{eName};
  my %data = %{$data::class{$class}{package}};
  my $rowspan = keys %data;
  print '<tbody id="package-'. $c_en .'"'. display($pc{'lv'.$c_id}) .'>';
  my $i;
  foreach my $p_id (sort{$data{$a}{stt} cmp $data{$b}{stt}} keys %data){
    (my $p_name = $data{$p_id}{name}) =~ s/(\(.+?\))/<small>$1<\/small>/;
    print '<tr>';
    print '<th rowspan="'.$rowspan.'">'.$class if !$i;
    print '<th>'. $p_name;
    print '<td id="package-'.$c_en.'-'.lc($p_id).'-auto" class="small">';
    print '<td>+'. (input "pack${c_id}${p_id}Add", 'number','calcPackage' ) .'=';
    print '<td id="package-'.$c_en.'-'.lc($p_id).'">'. $data{"pack${c_id}${p_id}"};
    $i++;
  }
  print "</tbody>\n";
}
print <<"HTML";
            </table>
          </div>
        </div>
        <div id="area-other-actions">
          <dl class="box" id="monster-lore">
            <dt>魔物知識
            <dd>+@{[ input 'monsterLoreAdd', 'number','calcPackage' ]}=<span id="monster-lore-value">$pc{monsterLore}</span>
          </dl>
          <dl class="box" id="initiative">
            <dt>先制力
            <dd>+@{[ input 'initiativeAdd', 'number','calcPackage' ]}=<span id="initiative-value">$pc{initiative}</span>
          </dl>
          <dl class="box" id="mobility">
            <dt>制限移動<dd><b id="mobility-limited">$pc{mobilityLimited}</b> m
            <dt>移動力<dd><span id="mobility-base">$pc{mobilityBase}</span>+@{[input('mobilityAdd','number','calcMobility')]}=<b id="mobility-total">0</b> m
            <dt>全力移動<dd><b id="mobility-full">$pc{mobilityFull}</b> m
          </dl>
        </div>
        <div class="box" id="language">
          <h2 class="in-toc">言語</h2>
          <table class="edit-table side-margin">
            <tr><th><th>会話<th>読文
          </table>
          <dl class="edit-table side-margin" id="language-default">
HTML
foreach (@{$data::races{ $pc{race} }{language}}){
  print '<dt>'.@$_[0].'<dd>'.(@$_[1] ? '○' : '－').'<dd>'.(@$_[2] ? '○' : '－');
}
print <<"HTML";
          </dl>
          <table class="edit-table side-margin" id="language-table">
            <tbody>
HTML
my @langoptionT = ('auto|<○ 自動習得／その他の習得>','listen|<△ 聞き取り限定（通辞の耳飾りなど）>');
my @langoptionR = ('auto|<○ 自動習得／その他の習得>');
foreach my $key (reverse keys %data::class) {
  next if !$data::class{$key}{language} || !$data::class{$key}{language}{any};
  if($data::class{$key}{language}{any}{talk}){
    unshift(@langoptionT, "$data::class{$key}{id}|<○ ${key}技能による習得>");
  }
  if($data::class{$key}{language}{any}{read}){
    unshift(@langoptionR, "$data::class{$key}{id}|<○ ${key}技能による習得>");
  }
}

foreach my $num ('TMPL', 1 .. $pc{languageNum}){
  if($num eq 'TMPL'){ print '<template id="language-template">' }
  print '<tr id="language-item'.$num.'"><td class="handle"><td>'.input('language'.$num, '','checkLanguage','list="list-language"').
  '<td><select name="language'.$num.'Talk" oninput="checkLanguage()">'.(option "language${num}Talk",@langoptionT).'</select><span class="lang-select-view"></span>'.
  '<td><select name="language'.$num.'Read" oninput="checkLanguage()">'.(option "language${num}Read",@langoptionR).'</select><span class="lang-select-view"></span>'.
  "\n";
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          </table>
          <div class="add-del-button"><a onclick="addLanguage()">▼</a><a onclick="delLanguage()">▲</a></div>
          <p>@{[ input 'languageAutoOff','checkbox','changeRace' ]}初期習得言語を自動記入しない</p>
          <p id="language-notice"></p>
          @{[input('languageNum','hidden')]}
        </div>
        <div class="box" id="magic-power">
          <h2 class="in-toc" data-content-title="魔法・呪歌・賦術などの基準値">魔法／呪歌／賦術など</h2>
          <table class="edit-table line-tbody">
            <thead>
            <tr>
              <th><th><th>専用化<th>魔力／奏力<th>行使<small>／演奏など</small><th class="small">ダメージ<br>上昇効果
            <tbody>
              <tr id="magic-power-raceability">
                <td>［<span id="magic-power-raceability-name"></span>］
                <td id="magic-power-raceability-type">
                <td>
                <td class="center">+<span id="magic-power-raceability-value">0</span>
                <td>
                <td>
              <tr id="magic-power-magicenhance">
                <td>《魔力強化》
                <td>魔法全般
                <td>
                <td class="center">+<span id="magic-power-magicenhance-value">0</span>
                <td>
                <td>
              <tr id="magic-power-common">
                <td>装備補正など
                <td>魔法全般
                <td>
                <td>+@{[ input 'magicPowerAdd','number','calcMagic' ]}
                <td>+@{[ input 'magicCastAdd','number','calcMagic' ]}
                <td>+@{[ input 'magicDamageAdd','number','calcMagic' ]}
HTML
my $fairyset = <<"HTML";
<small>ランク</small><b id="fairy-rank"></b>
<div id="fairycontact">
  <label class="ft-earth">@{[ input 'fairyContractEarth', 'checkbox','calcFairy' ]}<span>土</span></label>
  <label class="ft-water">@{[ input 'fairyContractWater', 'checkbox','calcFairy' ]}<span>水</span></label>
  <label class="ft-fire" >@{[ input 'fairyContractFire' , 'checkbox','calcFairy' ]}<span>炎</span></label>
  <label class="ft-wind" >@{[ input 'fairyContractWind' , 'checkbox','calcFairy' ]}<span>風</span></label>
  <label class="ft-light">@{[ input 'fairyContractLight', 'checkbox','calcFairy' ]}<span>光</span></label>
  <label class="ft-dark" >@{[ input 'fairyContractDark' , 'checkbox','calcFairy' ]}<span>闇</span></label>
</div>
HTML
foreach my $name (@data::class_caster){
  next if (!$data::class{$name}{magic}{jName});
  my $id    = $data::class{$name}{id};
  my $ename = $data::class{$name}{eName};
  print <<"HTML";
            <tr@{[ display $pc{'lv'.$id} ]} id="magic-power-${ename}">
              <td>${name}
              <td>$data::class{$name}{magic}{jName} @{[ $name eq 'フェアリーテイマー' ? $fairyset : '' ]}
              <td><label>@{[ input 'magicPowerOwn'.$id, 'checkbox','calcMagic' ]}知力+2</label>
              <td>+@{[ input 'magicPowerAdd'.$id,  'number','calcMagic' ]}=<b id="magic-power-${ename}-value">0</b>
              <td>+@{[ input 'magicCastAdd'.$id,   'number','calcMagic' ]}=<b id="magic-cast-${ename}-value" >0</b>
              <td>+@{[ input 'magicDamageAdd'.$id, 'number','calcMagic' ]}=<b id="magic-damage-${ename}-value" >0</b>
HTML
}
print <<"HTML";
            <tr id="magic-power-hr">
              <td colspan="8">
HTML
foreach my $name (@data::class_names){
  next if (!$data::class{$name}{craft}{stt});
  my $id    = $data::class{$name}{id};
  my $ename = $data::class{$name}{eName};
  print <<"HTML";
            <tr@{[ display $pc{'lv'.$id} ]} id="magic-power-${ename}">
              <td>${name}
              <td>$data::class{$name}{craft}{jName}
              <td><label>@{[ input 'magicPowerOwn'.$id, 'checkbox','calcMagic' ]}$data::class{$name}{craft}{stt}+2</label>
              <td>
HTML
  if($data::class{$name}{craft}{power}){
    print '+'.input('magicPowerAdd'.$id, 'number','calcMagic')."=<b id=\"magic-power-${ename}-value\">0</b>";
  }
  print <<"HTML";
              </td>
              <td>+@{[ input 'magicCastAdd'.$id, 'number','calcMagic' ]}=<b id="magic-cast-${ename}-value" >0</b>
              <td>
HTML
  if($data::class{$name}{craft}{power}){
    print '+'.input('magicDamageAdd'.$id, 'number','calcMagic')."=<b id=\"magic-damage-${ename}-value\">0</b>";
  }
}
print <<"HTML";
          </table>
        </div>
      </div>
      
      <div id="area-equipment">
        <div class="box" id="attack-classes">
          <table class="edit-table line-tbody">
            <thead>
              <tr>
                <th>技能・特技
                <th>必筋<br>上限
                <th>命中力
                <th>
                <th>Ｃ値
                <th>追加Ｄ
              </tr>
            <tbody>
HTML
my @weapon_users;
foreach my $name (@data::class_names){
  next if $data::class{$name}{type} ne 'weapon-user';
  push(@weapon_users, $name);
  my $ename = $data::class{$name}{eName};
  print <<"HTML";
              <tr id="attack-${ename}"@{[ display $pc{'lv'.$data::class{$name}{id}} ]}>
                <td>${name}技能
                <td id="attack-${ename}-str">0
                <td id="attack-${ename}-acc">0
                <td>―
                <td>@{[ $name eq 'フェンサー' ? '-1' : '―' ]}
                <td id="attack-${ename}-dmg">―
HTML
}
print <<"HTML";
              <tr id="attack-enhancer"@{[ display ($pc{lvEnh} >= 10) ]}>
                <td>エンハンサー技能
                <td id="attack-enhancer-str">0
                <td id="attack-enhancer-acc">0
                <td>―
                <td>―
                <td id="attack-enhancer-dmg">0
              <tr id="attack-demonruler"@{[ display $pc{lvDem} ]}>
                <td>デーモンルーラー技能
                <td id="attack-demonruler-str">0
                <td id="attack-demonruler-acc">0
                <td>―
                <td>―
                <td id="attack-demonruler-dmg">0
HTML
foreach my $weapon (@data::weapons){
print <<"HTML";
              <tr id="attack-@$weapon[1]-mastery"@{[ display $pc{'mastery'.ucfirst(@$weapon[1])} ]}>
                <td>《武器習熟／@$weapon[0]》
                <td>―
                <td>―
                <td>―
                <td>―
                <td id="attack-@$weapon[1]-mastery-dmg">$pc{'mastery'.ucfirst(@$weapon[1])}
HTML
}
print <<"HTML";
              <tr id="attack-artisan-mastery"@{[ display $pc{masteryArtisan} ]}>
                <td>《魔器習熟》
                <td>―
                <td>―
                <td>―
                <td>―
                <td id="attack-artisan-mastery-dmg">$pc{masteryArtisan}
              <tr id="accuracy-enhance"@{[ display $pc{accuracyEnhance} ]}>
                <td>《命中強化》
                <td>―
                <td id="accuracy-enhance-acc">$pc{accuracyEnhance}
                <td>―
                <td>―
                <td>―
              <tr id="throwing"@{[ display $pc{throwing} ]}>
                <td>《スローイング》
                <td>―
                <td id="throwing-acc">1
                <td>―
                <td>―
                <td>―
            </tbody>
          </table>
        </div>
        <div class="box in-toc" id="weapons" data-content-title="武器">
          <table class="edit-table line-tbody" id="weapons-table">
            <thead id="weapon-head">
              <tr>
                <th>武器
                <th>用法
                <th>必筋
                <th>命中力
                <th>威力
                <th>Ｃ値
                <th>追加Ｄ
                <th>専用
                <th>カテゴリ
                <th>使用技能
                <th>
              </tr>
            </thead>
HTML

foreach my $num ('TMPL',1 .. $pc{weaponNum}) {
  if($num eq 'TMPL'){ print '<template id="weapon-template">' }
print <<"HTML";
            <tbody id="weapon-row$num">
              <tr>
                <td rowspan="2">@{[input("weapon${num}Name",'','','placeholder="名称"')]}<span class="handle"></span>
                <td rowspan="2">@{[input("weapon${num}Usage","text",'','list="list-usage"')]}
                <td rowspan="2">@{[input("weapon${num}Reqd",'text','calcWeapon')]}
                <td rowspan="2">+@{[input("weapon${num}Acc",'number','calcWeapon')]}<b id="weapon${num}-acc-total">0</b>
                <td rowspan="2">@{[input("weapon${num}Rate")]}
                <td rowspan="2">@{[input("weapon${num}Crit")]}
                <td rowspan="2">+@{[input("weapon${num}Dmg",'number','calcWeapon')]}<b id="weapon${num}-dmg-total">0</b>
                <td>@{[input("weapon${num}Own",'checkbox','calcWeapon')]}
                <td><select name="weapon${num}Category" oninput="calcWeapon()">@{[option("weapon${num}Category",@data::weapon_names,'ガン（物理）','盾')]}</select>
                <td><select name="weapon${num}Class" oninput="calcWeapon()">@{[option("weapon${num}Class",@weapon_users,'エンハンサー','デーモンルーラー','自動計算しない')]}</select>
                <td rowspan="2"><span class="button" onclick="addWeapons(${num});">複<br>製</span>
              <tr>
                <td colspan="3">@{[input("weapon${num}Note",'','calcWeapon','placeholder="備考"')]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          </table>
          <div class="annotate">
            ※Ｃ値は自動計算されません。<br>
            <span id="artisan-annotate" @{[ display $pc{masteryArtisan} ]}>※備考欄に<code>〈魔器〉</code>と記入すると魔器習熟が反映されます。</span>
          </div>
          <div class="add-del-button"><a onclick="addWeapons()">▼</a><a onclick="delWeapons()">▲</a></div>
          @{[input('weaponNum','hidden')]}
        </div>
        <div class="box" id="evasion-classes">
          <table class="edit-table">
            <thead>
              <tr>
                <th>技能・特技
                <th>必筋<br>上限
                <th>回避力
                <th>防護点
              </tr>
            <tbody>
              <tr id="evasion-class-row">
                <td>
                  <span class="flex">
                    <span class="bold nowrap">使用技能:</span>
                    <select id="evasion-class" name="evasionClass" oninput="calcDefense()">
                      @{[ option 'evasionClass',@weapon_users,'デーモンルーラー' ]}
                    </select>
                  </span>
                <td id="evasion-str">$pc{EvasionStr}
                <td id="evasion-eva">$pc{EvasionEva}
                <td>―
              <tr id="race-ability-def"@{[ display $pc{raceAbilityDef} ]}>
                <td id="race-ability-def-name">［@{[
                    ($pc{raceAbility} =~ /［鱗の皮膚］/) ? '鱗の皮膚'
                  : ($pc{raceAbility} =~ /［晶石の身体］/) ? '晶石の身体'
                  : ($pc{raceAbility} =~ /［奈落の身体／アビストランク］/)?'奈落の身体／アビストランク'
                  : ($pc{raceAbility} =~ /［トロールの体躯］/)?'トロールの体躯'
                  : ''
                ]}］
                <td>―
                <td>―
                <td id="race-ability-def-value">$pc{raceAbilityDef}
              <tr id="mastery-metalarmour"@{[ display $pc{masteryMetalArmour} ]}>
                <td>《防具習熟／金属鎧》
                <td>―
                <td>―
                <td id="mastery-metalarmour-value">$pc{masteryMetalArmour}
              <tr id="mastery-nonmetalarmour"@{[ display $pc{masteryNonMetalArmour} ]}>
                <td>《防具習熟／非金属鎧》
                <td>―
                <td>―
                <td id="mastery-nonmetalarmour-value">$pc{masteryNonMetalArmour}
              <tr id="mastery-shield"@{[ display $pc{masteryShield} ]}>
                <td>《防具習熟／盾》
                <td>―
                <td>―
                <td id="mastery-shield-value">$pc{masteryShield}
              <tr id="mastery-artisan-def"@{[ display $pc{masteryArtisan} ]}>
                <td>《魔器習熟》
                <td>―
                <td>―
                <td id="mastery-artisan-def-value">$pc{masteryArtisan}
              <tr id="evasive-maneuver"@{[ display $pc{evasiveManeuver} ]}>
                <td>《回避行動》
                <td>―
                <td id="evasive-maneuver-value">$pc{evasiveManeuver}
                <td>―
              <tr id="minds-eye"@{[ display $pc{mindsEye} ]}>
                <td>《心眼》
                <td>―
                <td id="minds-eye-value">$pc{mindsEye}
                <td>―
              </tr>
            </tbody>
          </table>
        </div>
        <div class="box in-toc" id="armours" data-content-title="防具">
          <table class="edit-table">
            <thead>
              <tr>
                <th class="type">
                <th class="cate">カテゴリ
                <th class="name">防具
                <th class="reqd">必筋
                <th class="eva ">回避力
                <th class="def ">防護点
                <th class="own ">専用
                <th class="note">備考
              </tr>
            </thead>
            <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{armourNum}) {
  if($num eq 'TMPL'){ print '<template id="armour-template">' }
  print <<"HTML";
              <tr id="armour${num}" data-type="">
                <th class="type handle">
                <td><select name="armour${num}Category" oninput="calcDefense()">@{[ option "armour${num}Category",'金属鎧','非金属鎧','盾','その他' ]}</select>
                <td>@{[ input "armour${num}Name",'','calcDefense' ]}
                <td>@{[ input "armour${num}Reqd",'','calcDefense' ]}
                <td>@{[ input "armour${num}Eva",'number','calcDefense' ]}
                <td>@{[ input "armour${num}Def",'number','calcDefense' ]}
                <td>@{[ input "armour${num}Own",'checkbox','calcDefense','style="display:none"' ]}
                <td>@{[ input "armour${num}Note" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
  print <<"HTML";
            </tbody>
            @{[ input 'armourNum','hidden' ]}
            <tfoot>
              <tr><td colspan="8">
                <div class="add-del-button"><a onclick="addArmour()">▼</a><a onclick="delArmour()">▲</a></div>
              <tr><th colspan="8">合計
HTML
foreach my $i (1..3){
  print <<"HTML";
              <tr class="defense-total">
                <td colspan="4" class="defense-total-checklist">
HTML
  foreach my $num (1 .. $pc{armourNum}) {
    print checkbox("defTotal${i}CheckArmour${num}",($pc{"armour${num}Name"}||'―'),'calcDefense',"data-id='armour${num}'");
  }
  print "</td>";
  print <<"HTML";
                <td id="defense-total${i}-eva">0
                <td id="defense-total${i}-def">0
                <td colspan="3">@{[input("defenseTotal${i}Note")]}
HTML
}
print <<"HTML";
            </tfoot>
          </table>
        </div>
        <div class="box in-toc" id="accessories" data-content-title="装飾品">
          <table class="edit-table">
            <thead>
              <tr>
                <th>
                <th>
                <th>装飾品
                <th>専用
                <th>効果
              </tr>
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
  my $show;
  my $addbase = @$_[1];
     $addbase =~ s/_//;
  if   (@$_[0] eq '他2' &&  $pc{raceAbility} !~ '［見えざる手］')                    { $show = 0; }
  elsif(@$_[0] eq '他3' && ($pc{raceAbility} !~ '［見えざる手］' || $pc{level} <  6)){ $show = 0; }
  elsif(@$_[0] eq '他4' && ($pc{raceAbility} !~ '［見えざる手］' || $pc{level} < 16)){ $show = 0; }
  elsif(@$_[0] =~ /┗/  && !$pc{'accessory'.$addbase.'Add'}){ $show = 0; }
  else { $show = 1; }
  print '  <tr id="accessory-row'.@$_[1].'" data-type="'.@$_[1].'" '.display($show).">\n";
  print '  <td>';
  if (@$_[1] !~ /__/) {
    print '  <input type="checkbox"' .
          " name=\"accessory@$_[1]Add\" value=\"1\"" .
          ($pc{"accessory@$_[1]Add"}?' checked' : '') .
          " onChange=\"addAccessory('@$_[1]')\">";
  }
  print "</td>\n";
  print <<"HTML";
  <th>@$_[0]
    <td>@{[input('accessory'.@$_[1].'Name')]}
    <td>
      <select name="accessory@$_[1]Own" oninput="calcSubStt()">
        <option></option>
        <option value="HP" @{[ $pc{"accessory@$_[1]Own"} eq 'HP' ? 'selected':'']}>HP</option>
        <option value="MP" @{[ $pc{"accessory@$_[1]Own"} eq 'MP' ? 'selected':'' ]}>MP</option>
      </select>
    <td>@{[input('accessory'.@$_[1].'Note')]}
HTML
}
print <<"HTML";
          </tbody>
          </table>
          <div class="annotate">※左のボックスにチェックを入れると欄が一つ追加されます</div>
        </div>
      </div>
      <div id="area-items">
        <div id="area-items-L">
          <dl class="box" id="money">
            <dt class="in-toc">所持金<dd>@{[ input 'money' ]} G
            <dt>預金／借金<dd>@{[ input 'deposit' ]} G
          </dl>
          <div class="box" id="items">
            <h2 class="in-toc">所持品</h2>
            <textarea name="items">$pc{items}</textarea>
          </div>
        </div>
        <div id="area-items-R">
          <div class="box" id="material-cards"@{[ display $pc{lvAlc} ]}>
            <h2 class="in-toc">マテリアルカード</h2>
            <table class="edit-table no-border-cells" >
            <tr><th>  <th>B<th>A<th>S<th>SS
            <tr class="cards-red"><th>赤<td>@{[input 'cardRedB','number']}<td>@{[input 'cardRedA','number']}<td>@{[input 'cardRedS','number']}<td>@{[input 'cardRedSS','number']}
            <tr class="cards-gre"><th>緑<td>@{[input 'cardGreB','number']}<td>@{[input 'cardGreA','number']}<td>@{[input 'cardGreS','number']}<td>@{[input 'cardGreSS','number']}
            <tr class="cards-bla"><th>黒<td>@{[input 'cardBlaB','number']}<td>@{[input 'cardBlaA','number']}<td>@{[input 'cardBlaS','number']}<td>@{[input 'cardBlaSS','number']}
            <tr class="cards-whi"><th>白<td>@{[input 'cardWhiB','number']}<td>@{[input 'cardWhiA','number']}<td>@{[input 'cardWhiS','number']}<td>@{[input 'cardWhiSS','number']}
            <tr class="cards-gol"><th>金<td>@{[input 'cardGolB','number']}<td>@{[input 'cardGolA','number']}<td>@{[input 'cardGolS','number']}<td>@{[input 'cardGolSS','number']}
            </table>
          </div>
          <div class="box" id="battle-items"@{[ display $set::battleitem ]}>
          <h2>戦闘用アイテム</h2>
          <ul id="battle-items-list">
HTML
foreach my $num (1 .. 16){
  print '<li id="battle-item'.$num.'"><span class="handle"></span><input type="text" name="battleItem'.$num.'" value="'.$pc{'battleItem'.$num}.'">';
}
print <<"HTML";
          </ul>
          </div>
          <dl class="box in-toc" id="honor" data-content-title="名誉点・名誉アイテム">
            <dt>名誉点<dd id="honor-value">$pc{honor}
            <dt>ランク
            <dd id="honor-rank"><select name="rank" oninput="calcHonor()">@{[ option "rank",@set::adventurer_rank_name ]}</select>@{[ input 'rankStar','number','calcHonor','min="1"' ]}
          </dl>
          <div class="box honor-items" id="honor-items">
            <h2>名誉アイテム</h2>
            <table class="edit-table side-margin">
              <thead>
                <tr><th><th><th>点数
              </thead>
              <tbody>
                <tr><td class="center" colspan="2">冒険者ランク<td id="rank-honor-value">0
                <tr id="honor-items-mystic-arts"><td class="center" class="center" colspan="2">秘伝／秘伝魔法<td id="mystic-arts-honor-value">0
              <tbody id="honor-items-table">
HTML
foreach my $num ('TMPL',1 .. $pc{honorItemsNum}){
  if($num eq 'TMPL'){ print '<template id="honor-item-template">' }
  print '<tr id="honor-item'.$num.'"><td class="handle"><td>'.(input "honorItem${num}", "text").'<td>'.(input "honorItem${num}Pt", "number", "calcHonor");
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </table>
            <div class="add-del-button"><a onclick="addHonorItems()">▼</a><a onclick="delHonorItems()">▲</a></div>
            @{[ input 'honorItemsNum','hidden' ]}
            <p>フリー条件適用可能な（名誉点消費を0点にして良い）場合、<span class="mark">この表示</span>になります。</p>
            <dl class="edit-table side-margin" id="honor-offset">
              <dt>不名誉点相殺<dd>@{[ input "honorOffset", "number", "calcHonor();calcDishonor" ]}
            </dl>
          </div>
          <dl class="box" id="dishonor">
            <dt>不名誉点<dd id="dishonor-value">$pc{dishonor}
            <dt>不名誉称号<dd id="notoriety">
          </dl>
          <div class="box honor-items" id="dishonor-items">
            <h2>不名誉詳細</h2>
            <table class="edit-table side-margin">
              <thead><tr><th><th><th>点数
              <tbody id="dishonor-items-table">
HTML
foreach my $num ('TMPL',1 .. $pc{dishonorItemsNum}){
  if($num eq 'TMPL'){ print '<template id="dishonor-item-template">' }
  print '<tr id="dishonor-item'.$num.'"><td class="handle"><td>'.(input "dishonorItem${num}", "text").'<td>'.(input "dishonorItem${num}Pt", "number", "calcDishonor");
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </table>
          <div class="add-del-button"><a onclick="addDishonorItems()">▼</a><a onclick="delDishonorItems()">▲</a></div>
          @{[ input 'dishonorItemsNum','hidden' ]}
          </div>
        </div>
      </div>
      <details class="box" id="cashbook" @{[ $pc{cashbook} || $pc{money} =~ /^(?:自動|auto)$/i ? 'open' : '' ]}>
        <summary class="in-toc">収支履歴</summary>
        <textarea name="cashbook" oninput="calcCash();" placeholder="例）冒険者セット  ::-100&#13;&#10;　　剣のかけら売却::+200">$pc{cashbook}</textarea>
        <p>
          所持金：<span id="cashbook-total-value">$pc{moneyTotal}</span> G
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
      
      <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
        <summary class="in-toc">容姿・経歴・その他メモ</summary>
        <textarea name="freeNote">$pc{freeNote}</textarea>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeNote\')">最新のメモを適用する</button>' : '' ]}
      </details>
      
      <details class="box" id="free-history" @{[$pc{freeHistory}?'open':'']}>
        <summary>履歴（自由記入）</summary>
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
              <th class="exp   ">経験点
              <th class="money ">ガメル
              <th class="honor ">名誉点
              <th class="grow  ">成長
              <th class="gm    ">GM
              <th class="member">参加者
            <tr>
              <td>-
              <td>
              <td>キャラクター作成
              <td id="history0-exp">$pc{history0Exp}
              <td id="history0-money">$pc{history0Money}
              <td id="history0-honor">$pc{history0Honor}
              <td id="history0-grow">$pc{history0Grow}
            </tr>
HTML
foreach my $num ('TMPL',1 .. $pc{historyNum}) {
  if($num eq 'TMPL'){ print '<template id="history-template">' }
print <<"HTML";
          <tbody id="history${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td class="date  " rowspan="2">@{[input("history${num}Date")]}
              <td class="title " rowspan="2">@{[input("history${num}Title")]}
              <td class="exp   ">@{[input("history${num}Exp",'text','calcExp')]}
              <td class="money ">@{[input("history${num}Money",'text','calcCash')]}
              <td class="honor ">@{[input("history${num}Honor",'text','calcHonor')]}
              <td class="grow  ">@{[input("history${num}Grow",'text','calcStt','list="list-grow"')]}
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
              <td id="history-money-total">
              <td id="history-honor-total">
              <td id="history-grow-total"><span id="history-grow-total-value"></span><span id="history-grow-max-value"></span>
              <td colspan="2">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="exp   ">経験点
              <th class="money ">ガメル
              <th class="honor ">名誉点
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
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="exp   ">経験点
              <th class="money ">ガメル
              <th class="honor ">名誉点
              <th class="grow  ">成長
              <th class="gm    ">GM
              <th class="member">参加者
            </tr>
          <tbody>
            <tr>
              <td>-
              <td><input type="text" value="2015-05-01" disabled>
              <td><input type="text" value="第三話「記入例」" disabled>
              <td><input type="text" value="3000+50*3" disabled>
              <td><input type="text" value="100000" disabled>
              <td><input type="text" value="300" disabled>
              <td><input type="text" value="筋力" disabled>
              <td><input type="text" value="サンプルさん" disabled>
              <td><input type="text" value="ウィル　メネル　ルゥ　レイストフ　ゲルレイズ" disabled>
            </tr>
          </tbody>
        </table>
        <div class="annotate">
        ※経験点欄は<code>1000+50*2</code>など四則演算が有効です（ファンブル経験点などを分けて書けます）。<br>
        ※成長は欄1つの欄に<code>敏捷生命知力</code>など複数書いても自動計算されます。<br>
        　また、<code>敏捷×2</code><code>知力*3</code>など同じ成長が複数ある場合は纏めて記述できます（×や*は省略できます）。<br>
        　<code>器敏2知3</code>と能力値の頭文字1つで記述することもできます。<br>
        </div>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
      </div>
      </section>
      
      <section id="section-fellow" style="display:none;">
      <h2 id="fellow">フェロー関連データ</h2>
      <div class="box" id="f-public">
        @{[ input 'fellowPublic', 'checkbox']} フェローを公開する
      </div>
      <div class="box" id="f-checkboxes">
        <dl><dt>経験点</dt>
          <dd><input type="radio" name="fellowExpCheck" value="1" @{[ $pc{fellowExpCheck}?'checked':'' ]}>あり</dd>
          <dd><input type="radio" name="fellowExpCheck" value="0" @{[ $pc{fellowExpCheck}?'':'checked' ]}>なし</dd>
        </dl>
        <dl><dt>報酬</dt>
          <dd><input type="radio" name="fellowRewardCheck" value="1" @{[ $pc{fellowRewardCheck}?'checked':'' ]}>要望</dd>
          <dd><input type="radio" name="fellowRewardCheck" value="0" @{[ $pc{fellowRewardCheck}?'':'checked' ]}>不要</dd>
        </dl>
      </div>
      <div class="box" id="f-profile">
        <h2>自己紹介</h2>
        <textarea name="fellowProfile">$pc{fellowProfile}</textarea>
      </div>
      <div class="box" id="f-actions">
        <h2>行動表</h2>
      <table>
        <tr>
          <th>1d
          <th>想定<br>出目
          <th>行動
          <th>台詞
          <th>達成値
          <th>効果
        <tr class="border-top">
          <td rowspan="2">⚀<br>⚁
          <td class="number">7
          <td>@{[ input 'fellow1Action' ]}
          <td>@{[ input 'fellow1Words' ]}
          <td>@{[ input 'fellow1Num' ]}
          <td>@{[ input 'fellow1Note' ]}
        <tr>
          <td class="number">6
          <td>@{[ input 'fellow1-2Action' ]}
          <td>@{[ input 'fellow1-2Words' ]}
          <td>@{[ input 'fellow1-2Num' ]}
          <td>@{[ input 'fellow1-2Note' ]}
        <tr class="border-top">
          <td rowspan="2">⚂<br>⚃
          <td class="number">8
          <td>@{[ input 'fellow3Action' ]}
          <td>@{[ input 'fellow3Words' ]}
          <td>@{[ input 'fellow3Num' ]}
          <td>@{[ input 'fellow3Note' ]}
        <tr>
          <td class="number">5
          <td>@{[ input 'fellow3-2Action' ]}
          <td>@{[ input 'fellow3-2Words' ]}
          <td>@{[ input 'fellow3-2Num' ]}
          <td>@{[ input 'fellow3-2Note' ]}
        <tr class="border-top">
          <td rowspan="2">⚄
          <td class="number">9
          <td>@{[ input 'fellow5Action' ]}
          <td>@{[ input 'fellow5Words' ]}
          <td>@{[ input 'fellow5Num' ]}
          <td>@{[ input 'fellow5Note' ]}
        <tr>
          <td class="number">4
          <td>@{[ input 'fellow5-2Action' ]}
          <td>@{[ input 'fellow5-2Words' ]}
          <td>@{[ input 'fellow5-2Num' ]}
          <td>@{[ input 'fellow5-2Note' ]}
        <tr class="border-top">
          <td rowspan="2">⚅
          <td class="number">10
          <td>@{[ input 'fellow6Action' ]}
          <td>@{[ input 'fellow6Words' ]}
          <td>@{[ input 'fellow6Num' ]}
          <td>@{[ input 'fellow6Note' ]}
        <tr>
          <td class="number">3
          <td>@{[ input 'fellow6-2Action' ]}
          <td>@{[ input 'fellow6-2Words' ]}
          <td>@{[ input 'fellow6-2Num' ]}
          <td>@{[ input 'fellow6-2Note' ]}
        </tr>
      </table>
      </div>
      <div class="box" id="f-note">
        <h2>備考</h2>
        <textarea name="fellowNote">$pc{fellowNote}</textarea>
      </div>
      </section>
      
      @{[ chatPaletteForm ]}
      
      @{[ colorCostomForm ]}

      @{[ input 'birthTime','hidden' ]}
      <input type="hidden" name="id" value="$::in{id}">
    </form>
HTML
if($mode eq 'edit'){
print <<"HTML";
    <form name="del" method="post" action="./" class="deleteform">
      <p style="font-size: 80%;">
      <input type="hidden" name="mode" value="delete">
      <input type="hidden" name="id" value="$::in{id}">
      <input type="hidden" name="pass" value="$::in{pass}">
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
      <input type="hidden" name="id" value="$::in{id}">
      <input type="hidden" name="pass" value="$::in{pass}">
      <input type="checkbox" name="check1" value="1" required>
      <input type="checkbox" name="check2" value="1" required>
      <input type="checkbox" name="check3" value="1" required>
      <input type="submit" value="画像削除"><br>
      </p>
    </form>
    <p class="right">@{[ $::in{log}?$::in{log}:'最終' ]}更新時のIP:$pc{IP}</p>
HTML
  }
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
print textRuleArea( $text_rule,'「容姿・経歴・その他メモ」「履歴（自由記入）」「所持品」「収支履歴」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">(C)Group SNE「ソード・ワールド2.5」</p>
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
</body>

</html>
HTML

1;