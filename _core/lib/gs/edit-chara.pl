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
require $set::data_races;

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
  $pc{history0Adp}   = $set::make_adp;
  $pc{history0Money} = $set::make_money;
  $pc{history0Adventures} = $set::adventures;
  $pc{history0Completed}  = $set::completed;
  $pc{expTotal} = $pc{history0Exp};

  $pc{moneyAuto}   = 1;
  $pc{depositAuto} = 1;
  
  if($::in{stt}){
    ($pc{sttBaseTec}, $pc{sttBasePhy}, $pc{sttBaseSpi}, $pc{sttBaseA}, $pc{sttBaseB}, $pc{sttBaseC}, $pc{sttBaseD}, $pc{sttBaseE}, $pc{sttBaseF}) = split(/_/, $::in{stt});
    $pc{race} = Encode::decode('utf8', $::in{race});
    if($data::races{$pc{race}}{variant}){
      $pc{race} .= "（$data::races{$pc{race}}{variantSort}[0]）";
    }
    if($::in{making_num}){
      $pc{history0Note} = "能力値作成履歴#$::in{making_num}";
    }
  }
  
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
$pc{weaponNum}       ||=  3;
$pc{skillNum}        ||=  5;
$pc{generalSkillNum} ||=  3;
$pc{spellNum}        ||=  2;
$pc{artsNum}         ||=  2;
$pc{historyNum}      ||=  3;

### 折り畳み判断 --------------------------------------------------
my %open;
foreach (1..$pc{skillNum       }) { if(existsRow        "skill$_",'Name','Grade')  { $open{skill       } = 'open'; last; } }
foreach (1..$pc{generalSkillNum}) { if(existsRow "generalSkill$_",'Name','Grade')  { $open{generalSkill} = 'open'; last; } }
foreach (1..$pc{spellNum}) { if($pc{"spell${_}Name"}) { $open{spell} = 'open'; last; } }
foreach (1..$pc{artsNum }) { if($pc{"arts${_}Name" }) { $open{arts } = 'open'; last; } }

### 改行処理 --------------------------------------------------
$pc{words}         =~ s/&lt;br&gt;/\n/g;
$pc{items}         =~ s/&lt;br&gt;/\n/g;
$pc{freeNote}      =~ s/&lt;br&gt;/\n/g;
$pc{freeHistory}   =~ s/&lt;br&gt;/\n/g;
$pc{cashbook}      =~ s/&lt;br&gt;/\n/g;
$pc{chatPalette}   =~ s/&lt;br&gt;/\n/g;

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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/gs/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/gs/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="./?mode=js-consts&ver=${main::ver}"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/gs/edit-chara.js?${main::ver}" defer></script>
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
          <dd>@{[ input "history0Exp",'number','changeRegu','step="500"'.($set::make_fix?' readonly':'') ]}
          <dt>成長点
          <dd>@{[ input "history0Adp",'number','changeRegu', ($set::make_fix?' readonly':'') ]}
          <dt>所持金
          <dd>@{[ input "history0Money",'number','changeRegu', ($set::make_fix?' readonly':'') ]}
          <dt>冒険回数／達成数
          <dd style="display:flex;align-items:center">
            @{[ input "history0Adventures",'number','changeRegu', ($set::make_fix?' readonly':'') ]}
            ／
            @{[ input "history0Completed",'number','changeRegu', ($set::make_fix?' readonly':'') ]}
        </dl>
        <ul class="annotate"><li>成長点は、初期10点と累計経験点による追加を除きます。</ul>
        <dl class="regulation-note"><dt>備考<dd>@{[ input "history0Note" ]}</dl>
      </details>
      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}

        <div id="personal" class="in-toc" data-content-title="種族・年齢・性別">
          <dl class="box" id="race">
            <dt>種族<dd>
              <select name="race" oninput="changeRace()">@{[ option 'race', @data::race_list ]}</select>
              @{[ input 'raceFree','','','placeholder="自由記入（獣人等向け）"' ]}
            <dt id="race-base">本来の種族<dd>
              <select name="raceBase" oninput="changeRace()">@{[ option 'raceBase', @data::race_list,$pc{raceBase} ]}</select>
              @{[ input 'raceBaseFree','','','placeholder="自由記入（獣人等向け）"' ]}
          </dl>
          <dl class="box" id="age">
            <dt>年齢<dd>@{[ input 'age' ]}
          </dl>
          <dl class="box" id="gender">
            <dt>性別<dd>@{[ input 'gender','','','list="list-gender"' ]}
          </dl>
          <dl class="box" id="rank">
            <dt class="in-toc">等級<dd><select name="rank">@{[ option 'rank', @set::adventurer_rank_name ]}</select>
          </dl>
          <dl class="box" id="career">
            <dt class="in-toc">経歴（出自／来歴／邂逅）
            <dd>
              @{[input 'careerOrigin' ]}/@{[input 'careerGenesis' ]}/@{[input 'careerEncounter' ]}
            <dd>
              <b class="nowrap small">出自によって習得する職業:</b><select name="careerOriginClass" onchange="changeOriginClass()">@{[ option 'careerOriginClass', @data::class_names ]}</select>
          </dl>
        </div>

        <div class="box in-toc" id="ability" data-content-title="能力値">
          <table class="edit-table">
            <colgroup>
              <col><col><col><col><col><col>
            </colgroup>
            <thead>
              <tr>
                <th colspan="4" class="status-head"><span>能力値</span>
                <th colspan="3" class="status-second-head">第二能力値
              </tr>
            </thead>
            <tbody>
              <tr>
                <th colspan="4">
                <th><dl><dt>集中度<dd>@{[ input 'ability2FocBase', 'number', 'calcAbility' ]}</dl>
                <th><dl><dt>持久度<dd>@{[ input 'ability2EduBase', 'number', 'calcAbility' ]}</dl>
                <th><dl><dt>反射度<dd>@{[ input 'ability2RefBase', 'number', 'calcAbility' ]}</dl>
              <tr>
                <th colspan="2">
                <th><span class="thin">ボーナス</span>
                <th>修正
                <td class="right">@{[ input 'ability2FocMod', 'number', 'calcAbility' ]}
                <td class="right">@{[ input 'ability2EduMod', 'number', 'calcAbility' ]}
                <td class="right">@{[ input 'ability2RefMod', 'number', 'calcAbility' ]}
              <tr>
                <th rowspan="5" class="status-first-head">第一能力値
                <th><dl><dt>体力点<dd>@{[ input 'ability1StrBase', 'number', 'calcAbility' ]}</dl>
                <td>@{[ radio 'ability1Bonus', 'deselectable,calcAbility', 'Str' ]}
                <td>@{[ input 'ability1StrMod', 'number', 'calcAbility' ]}
                <td><dl><dt>体力集中<dd id="ability-value-StrFoc"></dl>
                <td><dl><dt>体力持久<dd id="ability-value-StrEdu"></dl>
                <td><dl><dt>体力反射<dd id="ability-value-StrRef"></dl>
              <tr>
                <th><dl><dt>魂魄点<dd>@{[ input 'ability1PsyBase', 'number', 'calcAbility' ]}</dl>
                <td>@{[ radio 'ability1Bonus', 'deselectable,calcAbility', 'Psy' ]}
                <td>@{[ input 'ability1PsyMod', 'number', 'calcAbility' ]}
                <td><dl><dt>魂魄集中<dd id="ability-value-PsyFoc"></dl>
                <td><dl><dt>魂魄持久<dd id="ability-value-PsyEdu"></dl>
                <td><dl><dt>魂魄反射<dd id="ability-value-PsyRef"></dl>
              <tr>
                <th><dl><dt>技量点<dd>@{[ input 'ability1TecBase', 'number', 'calcAbility' ]}</dl>
                <td>@{[ radio 'ability1Bonus', 'deselectable,calcAbility', 'Tec' ]}
                <td>@{[ input 'ability1TecMod', 'number', 'calcAbility' ]}
                <td><dl><dt>技量集中<dd id="ability-value-TecFoc"></dl>
                <td><dl><dt>技量持久<dd id="ability-value-TecEdu"></dl>
                <td><dl><dt>技量反射<dd id="ability-value-TecRef"></dl>
              <tr>
                <th><dl><dt>知力点<dd>@{[ input 'ability1IntBase', 'number', 'calcAbility' ]}</dl>
                <td>@{[ radio 'ability1Bonus', 'deselectable,calcAbility', 'Int' ]}
                <td>@{[ input 'ability1IntMod', 'number', 'calcAbility' ]}
                <td><dl><dt>知力集中<dd id="ability-value-IntFoc"></dl>
                <td><dl><dt>知力持久<dd id="ability-value-IntEdu"></dl>
                <td><dl><dt>知力反射<dd id="ability-value-IntRef"></dl>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="box" id="status">
          <h2 class="in-toc">状態</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th>
                <th>2d6
                <th>計算式
                <th>修正
                <th>
            <tbody>
            <tr>
              <th>生命力
              <td>@{[ input 'statusLifeDice', 'number', 'calcStatus', 'min="2" max="12"' ]}
              <td id="status-life-calc">+体力点<b id="status-life-str">0</b>+魂魄点<b id="status-life-psy">0</b>+持久度<b id="status-life-edu">0</b>+
              <td>@{[ input 'statusLifeMod', 'number', 'calcStatus', ]}
              <td id="status-life-total" class="bold">0
            <tr>
              <th>生命力×2
              <th colspan="3" class="right">
              <td id="status-life-twice" class="bold">0
            <tr>
              <th>移動力
              <td>@{[ input 'statusMoveDice', 'number', 'calcStatus', 'min="2" max="12"' ]}
              <td id="status-move-calc">×種族修正<b id="status-move-race">0</b>+
              <td>@{[ input 'statusMoveMod', 'number', 'calcStatus', ]}
              <td id="status-move-total" class="bold">0
            <tr>
              <th>呪文使用回数
              <td>@{[ input 'statusSpellDice', 'number', 'calcStatus', 'min="2" max="12"' ]}
              <td id="status-spell-calc">(2-6:0／7-9:1／10-11:2／12:3) +
              <td>@{[ input 'statusSpellMod', 'number', 'calcStatus', ]}
              <td id="status-spell-total" class="bold">0
            <tr>
              <th>呪文抵抗基準値
              <td>―
              <td id="status-resist-calc">魂魄反射<b id="status-resist-psyref">0</b>+冒険者レベル<b id="status-resist-level">0</b>+
              <td>@{[ input 'statusResistMod', 'number', 'calcStatus', ]}
              <td id="status-resist-total" class="bold">0
            <tr>
          </table>
        </div>
        
        <dl class="box" id="level">
          <dt>冒険者レベル<dd id="level-value">$pc{level}
        </dl>
        <div class="box" id="exp">
          <h2>経験点</h2>
          <dl>
            <dt>消費<dd><span id="exp-used">$pc{expUsed}</span>
            <dt>現在<dd><span id="exp-rest">$pc{expRest}</span>
            <dt>累計<dd><span id="exp-total">$pc{expTotal}</span>
          </dl>
        </div>
        
        <div class="box" id="adp">
          <h2>成長点</h2>
          <dl>
            <dt>消費<dd><span id="adp-used">$pc{growPointUsed}</span>
            <dt>現在<dd><span id="adp-rest">$pc{growPointRest}</span>
            <dt>累計<dd><span id="adp-total">$pc{growPointTotal}</span>
          </dl>
        </div>

        <dl class="box" id="session-total">
          <dt>冒険回数／達成数<dd><span id="adventures-value">0</span> 回 ／ <span id="adventures-complete-value">0</span> 回
        </dl>
      </div>
      
      <div id="area-classes" style="margin-top:var(--box-v-gap)">
        <div id="adp-and-faith">
          <dl class="box" id="adp-from-exp">
            <dt>成長点追加取得<dd>@{[ input 'adpFromExp','number','calcExp' ]}
          </dl>
          
          <dl class="box" id="faith">
            <dt>信仰<dd>@{[ input 'faith','','','list="list-faith"' ]}
          </dl>
        </div>

        <div class="box" id="classes">
          <h2 class="in-toc">職業</h2>
HTML
print '<div class="classes-group" id="classes-weapon-user"><h3>戦士系</h3><dl class="edit-table side-margin">';
foreach my $name (@data::class_names){ print classInputBox($name) if $data::class{$name}{type} =~ 'warrior'; }
print '</dl></div>';
print '<div class="classes-group" id="classes-magic-user"><h3>呪文使い系</h3><dl class="edit-table side-margin">';
foreach my $name (@data::class_names){ print classInputBox($name) if $data::class{$name}{type} =~ 'spell'; }
print '</dl></div>';

sub classInputBox {
  my $name = shift;
  my $id = $data::class{$name}{id};
  my $out;
  $out .= '<dt id="class'.$id.'">';
  $out .= '<ruby>'.$name.'<rt>'.$data::class{$name}{kana}.'</ruby>';
  $out .= '<dd>' . input("lv${id}", 'number','changeLv','min="0" max="10"');
  return $out;
}
print <<"HTML";
        </div>
      </div>
      

      <details class="box" id="skills" $open{skill}>
        <summary class="in-toc" data-content-title="冒険者技能">冒険者技能 <span class="small">[残り成長点:<b class="adp-rest">0</b>]</span></summary>
        @{[input 'skillNum','hidden']}
        <table class="edit-table no-border-cells" id="skills-table">
          <thead>
            <tr>
              <th>
              <th class="adp small">成長点
              <th class="auto small">自動
              <th class="name ">名称
              <th class="grade">習得段階
              <th class="note ">効果
              <th class="page ">参照
            </tr>
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{skillNum}) {
  if($num eq 'TMPL'){ print '<template id="skill-template">' }
print <<"HTML";
            <tr id="skill-row${num}">
              <td class="handle">
              <td class="adp  ">0
              <td class="auto ">@{[ checkbox "skill${num}Auto", '','calcAdp' ]}
              <td class="name "><span class="flex">【@{[ input "skill${num}Name" ]}】</span>
              <td class="grade"><select name="skill${num}Grade" onchange="calcAdp()">@{[ option "skill${num}Grade", '初歩','習熟','熟練','達人','伝説' ]}</select>
              <td class="note ">@{[ input "skill${num}Note" ]}
              <td class="page ">@{[ input "skill${num}Page",'','','list="list-page"' ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addSkill()">▼</a><a onclick="delSkill()">▲</a></div>
        <ul class="annotate">
          <li>「自動」にチェックを入れると、習得段階「初歩」で消費する成長点を0として計算します。<br>
            （経歴や種族によって自動的に習得する技能で、チェックを入れてください）
        </ul>
      </details>
      
      <details class="box" id="general-skills" $open{generalSkill}>
        <summary class="in-toc" data-content-title="一般技能">一般技能 <span class="small">[残り成長点:<b class="adp-rest">0</b>]</span></summary>
        @{[input 'generalSkillNum','hidden']}
        <table class="edit-table no-border-cells" id="general-skills-table">
          <thead>
            <tr>
              <th>
              <th class="adp small">成長点
              <th class="auto small">自動
              <th class="name ">名称
              <th class="grade">習得段階
              <th class="note ">効果
              <th class="page ">参照
            </tr>
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{generalSkillNum}) {
  if($num eq 'TMPL'){ print '<template id="general-skill-template">' }
print <<"HTML";
            <tr id="general-skill-row${num}">
              <td class="handle">
              <td class="adp  ">0
              <td class="auto ">@{[ checkbox "generalSkill${num}Auto", '','calcAdp' ]}
              <td class="name "><span class="flex">【@{[ input "generalSkill${num}Name" ]}】</span>
              <td class="grade"><select name="generalSkill${num}Grade" onchange="calcAdp()">@{[ option "generalSkill${num}Grade", '初歩','習熟','熟練' ]}</select>
              <td class="note ">@{[ input "generalSkill${num}Note" ]}
              <td class="page ">@{[ input "generalSkill${num}Page",'','','list="list-page"' ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addGeneralSkill()">▼</a><a onclick="delGeneralSkill()">▲</a></div>
        <ul class="annotate">
          <li>「自動」にチェックを入れると、習得段階「初歩」で消費する成長点を0として計算します。<br>
            （経歴や種族によって自動的に習得する技能で、チェックを入れてください）
        </ul>
      </details>

      <div class="box" id="spell-cast">
        <h2 class="in-toc">呪文行使基準値</h2>
        <table class="edit-table">
          <colgroup>
            <col class="base ">
            <col class="value">
            <col class="class">
            <col class="level">
            <col class="total">
          </colgroup>
          <tbody>
            <tr>
              <td colspan="4"><span class="flex"><b class="small">技能などの修正</b>@{[ input 'spellCastModName', '', '', 'placeholder="技能名など"' ]}</span>
              <td><span class="flex">+@{[ input 'spellCastModValue','number','calcSpellCast' ]}</span>
HTML

foreach my $name (grep { $data::class{$_}{type} =~ 'spell' } @data::class_names){
  print <<"HTML";
            <tr id="spell-cast-$data::class{$name}{eName}">
              <th class="base ">@{[ abilityToName($data::class{$name}{cast}) ]}
              <td class="value" id="spell-cast-$data::class{$name}{eName}-base">0
              <th class="class">$name
              <td class="level" id="spell-cast-$data::class{$name}{eName}-lv">0
              <td class="total bold" id="spell-cast-$data::class{$name}{eName}-total">0
HTML
}
print <<"HTML";
        </table>
      </div>
      <details class="box" id="spells" $open{spell}>
        <summary class="in-toc">呪文</summary>
        @{[input 'spellNum','hidden']}
        <table class="edit-table no-border-cells" id="spells-table">
          <thead>
            <tr>
              <th>
              <th class="name  ">名称
              <th class="system">呪文系統
              <th class="type  ">種別
              <th class="attr  ">属性
              <th class="dfclt ">難易度
              <th class="note  ">効果
              <th class="page  ">参照
            </tr>
          <tbody>
HTML
my @spell_names;
push(@spell_names, $data::class{$_}{magic}) foreach(grep { $data::class{$_}{magic} } @data::class_names);
foreach my $num ('TMPL',1 .. $pc{spellNum}) {
  if($num eq 'TMPL'){ print '<template id="spell-template">' }
print <<"HTML";
            <tr id="spell-row${num}">
              <td class="handle">
              <td class="name  "><span class="flex">《@{[ input "spell${num}Name" ]}》</span>
              <td class="system"><select name="spell${num}System">@{[ option "spell${num}System", @spell_names ]}</select>
              <td class="type  "><select name="spell${num}Type">@{[ option "spell${num}Type", '攻撃','付与','創造','支配','治癒','汎用' ]}</select>
              <td class="attr  ">@{[ input "spell${num}Attr",'','','list="list-spell-attr"' ]}
              <td class="dfclt ">@{[ input "spell${num}Dfclt" ]}
              <td class="note  ">@{[ input "spell${num}Note" ]}
              <td class="page  ">@{[ input "spell${num}Page",'','','list="list-page"' ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addSpell()">▼</a><a onclick="delSpell()">▲</a></div>
      </details>

      <details class="box" id="arts" $open{arts}>
        <summary class="in-toc">武技</summary>
        @{[input 'artsNum','hidden']}
        <table class="edit-table line-tbody no-border-cells" id="arts-table">
          <thead id="arts-head">
            <tr>
              <th>
              <th class="name  ">名称
              <th class="weapon">使用武器
              <th class="skill ">関連技能
              <th class="cost  ">消費／回数制限
              <th class="terms ">使用条件
              <th class="page  ">参照
            </tr>
HTML
foreach my $num ('TMPL',1 .. $pc{artsNum}) {
  if($num eq 'TMPL'){ print '<template id="arts-template">' }
print <<"HTML";
          <tbody id="arts-row${num}">
            <tr>
              <td rowspan="2" class="handle">
              <td class="name  ">@{[ input "arts${num}Name" ]}
              <td class="weapon">@{[ input "arts${num}Weapon" ]}
              <td class="skill ">@{[ input "arts${num}Skill" ]}
              <td class="cost  ">@{[ input "arts${num}Cost" ]}
              <td class="terms ">@{[ input "arts${num}Terms" ]}
              <td class="page  ">@{[ input "arts${num}Page",'','','list="list-page"' ]}
            <tr>
              <th class="right">効果
              <td colspan="5">@{[ input "arts${num}Note" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addArts()">▼</a><a onclick="delArts()">▲</a></div>
      </details>
      
      <div id="area-equipment">
        <div class="box" id="attack-classes">
          <h2 class="in-toc">命中基準値</h2>
          <table class="edit-table line-tbody">
            <colgroup>
              <col>
              <col class="name">
              <col class="level">
              <col class="value">
              <col class="value">
              <col class="value">
            </colgroup>
            <thead>
              <tr>
                <th class="name" colspan="2">
                <th class="level">
                <th class="value">近接
                <th class="value">投擲
                <th class="value">弩弓
            </thead>
            <tbody>
              <tr id="attack-ability">
                <th colspan="3">基本値：技量集中
                <td colspan="3"><b id="attack-ability-value">0</b>
              <tr id="attack-skill">
                <th colspan="3"><span class="flex"><b class="small">技能などの修正</b>@{[ input 'hitScoreModName', '', '', 'placeholder="技能名など"' ]}</span>
                <td>@{[ input 'hitScoreModMelee'     , 'number', 'calcAttack' ]}
                <td>@{[ input 'hitScoreModThrowing'  , 'number', 'calcAttack' ]}
                <td>@{[ input 'hitScoreModProjectile', 'number', 'calcAttack' ]}
              <tr id="attack-class-head-row">
                <th rowspan="5" class="attack-class-head">職業
HTML
my @weapon_users;
foreach my $name (@data::class_names){
  next if $data::class{$name}{type} !~ 'warrior';
  my $ename = $data::class{$name}{eName};
  print <<"HTML";
              <tr id="attack-${ename}">
                <th class="name">${name}
                <td class="level" id="attack-${ename}-level">0
                <td class="bold" id="attack-${ename}-melee">0
                <td class="bold" id="attack-${ename}-throwing">0
                <td class="bold" id="attack-${ename}-projectile">0
HTML
}
print <<"HTML";
          </table>
        </div>
        <div class="box in-toc" id="weapons" data-content-title="武器">
          <table class="edit-table line-tbody" id="weapons-table">
            <thead id="weapon-head">
              <tr>
                <th class="name ">武器
                <th class="type ">種別
                <th class="usage">用法<br>属性
                <th class="hit  ">命中基準値<br><span class="small">(+修正=合計)</span>
                <th class="power">威力<br><span class="small">(武器+職業Lv+技能など)</span>
                <th class="range">射程
                <th class="class small">判定に<br>適用する職業
                <th>
              <tr>
HTML
foreach my $num ('TMPL',1 .. $pc{weaponNum}) {
  if($num eq 'TMPL'){ print '<template id="weapon-template">' }
  print <<"HTML";
            <tbody id="weapon-row$num">
              <tr>
                <td class="name " rowspan="2">@{[ input "weapon${num}Name",'','','placeholder="武器名"' ]}<span class="handle"></span>
                <td class="type " rowspan="2"><select name="weapon${num}Type" oninput="calcWeapon()">@{[ option "weapon${num}Type", @set::weapon_names ]}</select><span class="flex">／<select name="weapon${num}Weight" oninput="calcWeapon()">@{[ option "weapon${num}Weight", '軽','重' ]}</select></span>
                <td class="usage" rowspan="2">@{[ input "weapon${num}Usage","text",'','list="list-usage"' ]}@{[ input "weapon${num}Attr",'text','','list="list-attr"' ]}
                <td class="hit  "><span class="flex">+@{[ input "weapon${num}HitMod",'number','calcWeapon' ]}=<b id="weapon${num}-hit-total" class="bold">$pc{"weapon${num}HitMod"}</b></span>
                <td class="power"><span class="flex">@{[ input "weapon${num}Power",'','','placeholder="xDy+z"' ]}+<b id="weapon${num}-power-lv">0</b>+@{[ input "weapon${num}PowerMod",'number' ]}
                <td class="range">@{[ input "weapon${num}Range",'','','list="list-range"' ]}
                <td class="class"><select name="weapon${num}Class" oninput="calcWeapon()">@{[ option "weapon${num}Class", (grep { $data::class{$_}{type} =~ /warrior/ } @data::class_names) ]}</select>
                <td rowspan="2"><span class="button" onclick="addWeapons(${num});">複<br>製</span>
              <tr>
                <td class="note right" colspan="4"><span class="flex"><b class="bold">備考</b>@{[ input "weapon${num}Note",'','calcWeapon' ]}</span>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          </table>
          <div class="add-del-button"><a onclick="addWeapons()">▼</a><a onclick="delWeapons()">▲</a></div>
          @{[input('weaponNum','hidden')]}
        </div>
        <div class="box defense-classes" id="dodge-classes">
          <h2 class="in-toc">回避基準値／移動力</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th>
                <th>
                <th>回避<br>基準値
                <th>
                <th>
                <th>移動力
            <tbody>
              <tr>
                <th>基本値
                <th class="right small">技量反射:
                <td id="dodge-base-value">0
                <th class="right small" colspan="2">2d6×種族修正:
                <td id="dodge-move-base-value">0
              <tr>
                <th class="small">判定に<br>適用する職業
                <td>
                  <select id="dodge-class" name="dodgeClass" oninput="calcDodge()">
                    @{[ option 'dodgeClass', (grep { $data::class{$_}{type} =~ /dodge/ } @data::class_names) ]}
                    <optgroup label="その他（装備等による例外）">
                      @{[ option 'dodgeClass', (grep { $data::class{$_}{type} !~ /dodge/ } @data::class_names) ]}
                  </select>
                <td id="dodge-class-value">―
                <td colspan="2">
                <td>―
              <tr>
                <th class="small">技能や所持品<br>などの修正
                <td>@{[ input 'dodgeModName','','','placeholder="技能名など"' ]}
                <td>@{[ input 'dodgeModValue','number','calcDodge' ]}
                <td colspan="2">
                <td>@{[ input 'MoveModValue','number','calcDodge' ]}
          </table>
        </div>
        <div class="box in-toc" id="armor" data-content-title="鎧">
          <table class="edit-table">
            <thead>
              <tr>
                <th class="name   ">鎧
                <th class="type   ">種別
                <th class="dodge  ">回避<br>基準値
                <th class="armor  ">装甲値
                <th class="stealth">隠密性
                <th class="move   ">移動力
                <th class="note   ">備考
              </tr>
            <tbody>
              <tr>
                <td>@{[ input 'armor1Name' ]}
                <td><select name="armor1Type" oninput="calcDodge()">@{[ option "armor1Type", '衣鎧','軽鎧','重鎧' ]}</select><span class="flex">@{[ input 'armor1Material','','','placeholder="材質" list="list-material"' ]}/<select name="armor1Weight" oninput="calcDodge()">@{[ option "armor1Weight", '軽','重' ]}</select></span>
                <td><span class="flex">+@{[ input 'armor1DodgeMod','number','calcDodge' ]}</span>=<b id="armor1-dodge-total" class="bold"></b>
                <td>@{[ input 'armor1Armor','number','calcBlock' ]}
                <td>@{[ input 'armor1Stealth','','','list="list-stealth"' ]}
                <td><span class="flex">+@{[ input 'armor1MoveMod','number','calcDodge' ]}</span>=<b id="armor1-move-total" class="bold"></b>
                <td>@{[ input 'armor1Note' ]}
              </tr>
            </tbody>
          </table>
        </div>
        <div class="box defense-classes" id="block-classes">
          <h2 class="in-toc">盾受け基準値</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th>
                <th>
                <th>盾受け<br>基準値
              </tr>
            </thead>
            <tbody>
              <tr>
                <th>基本値
                <th class="right small">技量反射:
                <td id="block-base-value">0
              <tr>
                <th class="small">判定に<br>適用する職業
                <td>
                  <select id="block-class" name="blockClass" oninput="calcDodge()">
                    @{[ option 'blockClass', (grep { $data::class{$_}{type} =~ /block/ } @data::class_names) ]}
                    <optgroup label="その他（装備等による例外）">
                      @{[ option 'blockClass', (grep { $data::class{$_}{type} !~ /block/ } @data::class_names) ]}
                  </select>
                <td id="block-class-value">―
              <tr>
                <th class="small">技能や所持品<br>などの修正
                <td>@{[ input 'blockModName','','','placeholder="技能名など"' ]}
                <td>@{[ input 'blockModValue','number','calcDodge' ]}
            </tbody>
          </table>
        </div>
        <div class="box in-toc" id="shield" data-content-title="盾">
          <table class="edit-table">
            <thead>
              <tr>
                <th class="name   ">盾
                <th class="type   ">種別
                <th class="block  ">盾受け<br>基準値
                <th class="armor  ">盾受け値<br><span class="small">+装甲値</span>
                <th class="stealth">隠密性
                <th class="note   ">備考
              </tr>
            <tbody>
              <tr>
                <td>@{[ input 'shield1Name' ]}
                <td><select name="shield1Type" oninput="calcBlock()">@{[ option "shield1Type", '小型盾','大型盾' ]}</select><span class="flex">@{[ input 'shield1Material','','','placeholder="材質" list="list-material"' ]}/<select name="shield1Weight" oninput="calcBlock()">@{[ option "shield1Weight", '軽','重' ]}</select></span>
                <td><span class="flex">+@{[ input 'shield1BlockMod','number','calcBlock' ]}</span>=<b id="shield1-block-total" class="bold"></b>
                <td><span class="flex">@{[ input 'shield1Armor','number','calcBlock' ]}</span>+<span id="shield1-armor-base">0</span>=<b id="shield1-armor-total" class="bold"></b>
                <td>@{[ input 'shield1Stealth','','','list="list-stealth"' ]}
                <td>@{[ input 'shield1Note' ]}
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div id="area-items">
        <div id="area-items-L">
          <div class="box" id="items">
            <h2 class="in-toc">所持品</h2>
            <textarea name="items">$pc{items}</textarea>
          </div>
        </div>
        <div id="area-items-R">
          <dl class="box" id="money">
            <dt class="in-toc">所持金 @{[ checkbox 'moneyAuto', '自動', 'calcCash' ]}
            <dd>
              <dl id="money-coins">
                <dt id="money-coins-s">銀貨  <dd>@{[ input 'money','' ]}
                <dt id="money-coins-g">金貨  <dd>@{[ input 'moneyGold','number',"calcCoins", 'min="0"' ]}
                <dt id="money-coins-l">大金貨<dd>@{[ input 'moneyLargeGold','number',"calcCoins", 'min="0"' ]}
              </dl>
              @{[ checkbox 'moneyAllCoins', '銀貨以外も管理する', 'openCoins' ]}
            <dt>預金／借金 @{[ checkbox 'depositAuto', '自動', 'calcCash' ]}
            <dd>@{[ input 'deposit' ]}
          </dl>
        </div>
      </div>
      <details class="box" id="cashbook" @{[ $pc{cashbook} || $pc{money} =~ /^(?:自動|auto)$/i ? 'open' : '' ]}>
        <summary class="in-toc">収支履歴</summary>
        <textarea name="cashbook" oninput="calcCash();" placeholder="例）治癒の水薬  ::-10&#13;&#10;　　粗悪な剣売却::+2">$pc{cashbook}</textarea>
        <p>
          所持金：銀貨 <span id="cashbook-total-value">$pc{moneyTotal}</span> 枚
          　預金：銀貨 <span id="cashbook-deposit-value">－</span> 枚
          　借金：銀貨 <span id="cashbook-debt-value">－</span> 枚
        </p>
        <ul class="annotate">
            <li><code>::+n</code> <code>::-n</code>の書式で入力すると加算・減算されます。（<code>n</code>には金額を入れてください）<br>
              預金は<code>:>+n</code>、借金は<code>:<+n</code>で増減できます。（それに応じて所持金も増減します）
            <li><span class="underline">セッション履歴に記入された銀貨報酬は自動的に加算されます。</span>
            <li>所持金欄、預金／借金欄の<code>自動</code>チェックを入れると、収支の計算結果を反映します。
        </ul>
      </details>

      <dl class="box" id="physical-traits">
        <dt class="in-toc">身体的特徴
        <dd>@{[ input "traits" ]}
        <dt>髪
        <dd>@{[ input "traitsHair" ]}
        <dt>瞳
        <dd>@{[ input "traitsEyes" ]}
      </dl>
      
      <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
        <summary class="in-toc">容姿詳細・経歴詳細・その他メモ</summary>
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
              <th class="comp  ">目標達成
              <th class="exp   ">経験点
              <th class="adp   ">成長点
              <th class="money ">銀貨
              <th class="gm    ">GM
              <th class="member">参加者
            <tr>
              <td>-
              <td>
              <td>キャラクター作成
              <td id="history0-comp">$pc{history0Adventures}／$pc{history0Completed}
              <td id="history0-exp">$pc{history0Exp}
              <td id="history0-adp">$pc{history0Adp}
              <td id="history0-money" class="money">$pc{history0Money}
            </tr>
HTML
foreach my $num ('TMPL',1 .. $pc{historyNum}) {
  if($num eq 'TMPL'){ print '<template id="history-template">' }
print <<"HTML";
          <tbody id="history-row${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td class="date  " rowspan="2">@{[ input "history${num}Date" ]}
              <td class="title " rowspan="2">@{[ input "history${num}Title" ]}
              <td class="comp  "><select name="history${num}Completed" oninput="calcAdvCompleted()">@{[ option "history${num}Completed", '1|<達成>','-1|<失敗>' ]}</select>
              <td class="exp   ">@{[ input "history${num}Exp",'text','calcExp' ]}
              <td class="adp   ">@{[ input "history${num}Adp",'text','calcAdp' ]}
              <td class="money ">@{[ input "history${num}Money",'text','calcCash' ]}
              <td class="gm    ">@{[ input "history${num}Gm" ]}
              <td class="member">@{[ input "history${num}Member" ]}
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
              <td id="history-comp-total">
              <td id="history-exp-total">
              <td id="history-adp-total">
              <td id="history-money-total" class="money">
              <td colspan="2">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="comp  ">目標達成
              <th class="exp   ">経験点
              <th class="adp   ">成長点
              <th class="money ">銀貨
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
              <th class="comp  ">目標達成
              <th class="exp   ">経験点
              <th class="adp   ">成長点
              <th class="money ">銀貨
              <th class="gm    ">GM
              <th class="member">参加者
          <tbody>
            <tr>
              <td>-
              <td class="date  "><input type="text" value="2015-05-01" disabled>
              <td class="title "><input type="text" value="第一話「記入例」" disabled>
              <td class="comp  "><input type="checkbox" value="1" checked disabled>
              <td class="exp   "><input type="text" value="1000" disabled>
              <td class="adp   "><input type="text" value="3" disabled>
              <td class="money "><input type="text" value="30" disabled>
              <td class="gm    "><input type="text" value="サンプルさん" disabled>
              <td class="member"><input type="text" value="小鬼殺し　女神官　妖精弓手　鉱人道士　蜥蜴僧侶" disabled>
            </tr>
          </tbody>
        </table>
        <ul class="annotate">
          <li>達成欄の値が（達成でも失敗でも）選択されているぶんだけ「冒険回数」が増加します。
          <li>経験点欄は<code>1000+100</code>など四則演算が有効です。
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
print textRuleArea( '','「容姿詳細・経歴詳細・その他メモ」「履歴（自由記入）」「所持品」「収支履歴」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">©Group SNE ©Kumo Kagyu「ゴブリンスレイヤーTRPG」</p>
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
    <option value="片手">
    <option value="両手">
  </datalist>
  <datalist id="list-attr">
    <option value="斬">
    <option value="刺">
    <option value="殴">
    <option value="斬刺">
    <option value="斬殴">
    <option value="刺殴">
    <option value="斬刺殴">
  </datalist>
  <datalist id="list-range">
    <option value="近接">
    <option value="10m">
    <option value="20m">
    <option value="30m">
    <option value="60m">
    <option value="120m">
  </datalist>
  <datalist id="list-material">
    <option value="布">
    <option value="革">
    <option value="木">
    <option value="金属">
    <option value="木、革">
    <option value="木、金属">
  </datalist>
  <datalist id="list-spell-attr">
    <option value="なし">
    <option value="火">
    <option value="水">
    <option value="土">
    <option value="風">
    <option value="光">
    <option value="闇">
    <option value="生命">
    <option value="精神">
    <option value="物質">
    <option value="時間">
    <option value="空間">
  </datalist>
  <datalist id="list-stealth">
    <option value="良い">
    <option value="普通">
    <option value="悪い">
  </datalist>
  <datalist id="list-page">
    <option value="基本">
    <option value="サプリ">
  </datalist>
  <datalist id="list-race-padfoots">
    @{[ option '', @data::padfoots_names ]}
  </datalist>
  <datalist id="list-race-beastbind">
    @{[ option '', @data::beastbind_names ]}
  </datalist>
  <datalist id="list-faith">
    @{[ option '', @set::faith_name ]}
  </datalist>
</body>

</html>
HTML

1;