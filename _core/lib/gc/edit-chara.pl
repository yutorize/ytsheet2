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

my @skillNames;
foreach ("Str","Ref","Per","Int","Mnd","Emp"){
  push(@skillNames, grep { !/:$/ } @{$set::skill{$_}});
}

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
  
  $pc{history0Result} = $set::make_exp || 0;
  
  $pc{level} = $pc{makeLv} = 1;
  
  $pc{paletteUseVar} = 1;
  $pc{paletteUseBuff} = 1;

  %pc = applyCustomizedInitialValues(\%pc, '');
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
$pc{classAbilityNum} ||= 3;
$pc{worksAbilityNum} ||= 3;
$pc{magicNum}        ||= 3;
$pc{itemNum}         ||= 3;
$pc{forceNum}        ||= 1;
$pc{actionSetNum}    ||= 2;
$pc{reactionSetNum}  ||= 2;
$pc{historyNum} ||= 3;

### 折り畳み判断 --------------------------------------------------
my %open;
$open{classAbility} = 'open';
$open{worksAbility} = 'open';
foreach (1..$pc{magicNum       }){ if($pc{"magic${_}Name"       } || $pc{"magic${_}Lv"       }){ $open{magic} = 'open'; last; } }
foreach ('Main','Sub','Other'){ if($pc{"weapon${_}Name" }){ $open{weapons} = 'open'; last; } }
foreach ('Main','Sub','Other'){ if($pc{"armor${_}Name"  }){ $open{armors } = 'open'; last; } }
foreach (1..$pc{itemNum     }){ if($pc{"item${_}Name"   }){ $open{items  } = 'open'; last; } }
foreach (1                   ){ if($pc{"vehicle${_}Name"}){ $open{vehicle} = 'open'; last; } }
foreach (1..$pc{forceNum    }){ if($pc{"force${_}Type"  }){ $open{force  } = 'open'; last; } }
foreach (1..$pc{actionSetNum   }){ if($pc{"actionSet${_}Name"  }){ $open{actionSets  } = 'open'; last; } }
foreach (1..$pc{reactionSetNum }){ if($pc{"reactionSet${_}Name"}){ $open{reactionSets} = 'open'; last; } }

### 改行処理 --------------------------------------------------
foreach (
  'words',
  'freeNote',
  'freeHistory',
  'chatPalette',
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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/gc/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/gc/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/gc/edit-chara.js?${main::ver}" defer></script>
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
        <dt>閲覧可否設定</dt>
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
          <dt>グループ<dd><select name="group">
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
          <dt>タグ<dd>@{[ input 'tags','','','' ]}
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
          <dt>作成時レベル
          <dd>@{[ input "makeLv",'number','changeRegu','min="1"'.($set::make_fix?' readonly':'') ]}
          <dt>備考
          <dd>@{[ input "history0Note" ]}
        </dl>
        <ul class="annotate"><li>「作成時レベル」までに必要な経験点が0として計算されます。</ul>
      </details>
      
      <div id="area-status">
        <div class="box-union in-toc" id="class-and-style" data-content-title="クラス・スタイル・ワークス・レベル">
          <dl class="box" id="class">
            <dt>クラス
            <dd>@{[ selectInput 'class','checkClass',@data::classNames ]}
          </dl>
          <dl class="box" id="style">
            <dt>スタイル
            <dd>@{[ selectInput 'style','changeStyle', @data::styleNames ]}
          </dl>
          <dl class="box" id="works">
            <dt>ワークス
            <dd>@{[ selectInput 'works','changeWorks',@data::worksNames ]}
          </dl>
          <dl class="box" id="style-sub">
            <dt>サブスタイル
            <dd>@{[ input 'styleSub' ]}
          </dl>
          <dl class="box" id="level">
            <dt>レベル
            <dd>@{[ input 'level', 'number', 'changeLevel', 'min=1' ]}
          </dl>
        </div>

        <div class="box" id="exp">
          <h2 class="in-toc">経験点</h2>
          <dl>
            <dt>使用<dd id="exp-used">
            <dt>残り<dd id="exp-rest">
            <dt>総計<dd id="exp-total">
          </dl>
        </div>

        <div class="box" id="status">
          <h2 class="in-toc">能力値・副能力値</h2>
          <table class="edit-table" id="status-table">
            <colgroup>
              <col>
              <col class="Str   ">
              <col class="Ref   ">
              <col class="Per   ">
              <col class="Int   ">
              <col class="Mnd   ">
              <col class="Emp   ">
            <colgroup>
            <thead>
              <tr>
                <th>
                <th class="Str   ">筋力
                <th class="Ref   ">反射
                <th class="Per   ">感覚
                <th class="Int   ">知力
                <th class="Mnd   ">精神
                <th class="Emp   ">共感
            <tbody>
              <tr class="status-works">
                <th>ワークス
                <td class="Str">@{[ input 'sttStrWorks','number','calcStatus' ]}
                <td class="Ref">@{[ input 'sttRefWorks','number','calcStatus' ]}
                <td class="Per">@{[ input 'sttPerWorks','number','calcStatus' ]}
                <td class="Int">@{[ input 'sttIntWorks','number','calcStatus' ]}
                <td class="Mnd">@{[ input 'sttMndWorks','number','calcStatus' ]}
                <td class="Emp">@{[ input 'sttEmpWorks','number','calcStatus' ]}
              <tr class="status-make">
                <th>作成時ボーナス<small>[<span id="make-bonus-total">0</span>/5]</small>
                <td class="Str">@{[ input 'sttStrMake','number','calcStatus' ]}
                <td class="Ref">@{[ input 'sttRefMake','number','calcStatus' ]}
                <td class="Per">@{[ input 'sttPerMake','number','calcStatus' ]}
                <td class="Int">@{[ input 'sttIntMake','number','calcStatus' ]}
                <td class="Mnd">@{[ input 'sttMndMake','number','calcStatus' ]}
                <td class="Emp">@{[ input 'sttEmpMake','number','calcStatus' ]}
              <tr class="status-grow-total">
                <th>成長合計
                <td class="Str">
                <td class="Ref">
                <td class="Per">
                <td class="Int">
                <td class="Mnd">
                <td class="Emp">
              <tr class="status-grow-button">
                <td>
                <td colspan="6">
                  <span class="open-button" onclick="toggleGrowRows()" data-open="" data-text-open="各レベルの成長を全て表示" data-text-close="記入済みのレベルの成長を畳む"></span>
              </tr>
HTML
  foreach('TMPL',2..$pc{level}){
    print '<template id="status-grow-template">' if($_ eq 'TMPL');
    print <<"HTML";
              <tr id="status-grow$_" class="status-grow" @{[ displayGrowRow($_) ]}>
                <th>成長:${_}レベル
                <td class="Str">@{[ checkbox "sttStrGrow$_",'+1',"changeGrow($_)" ]}
                <td class="Ref">@{[ checkbox "sttRefGrow$_",'+1',"changeGrow($_)" ]}
                <td class="Per">@{[ checkbox "sttPerGrow$_",'+1',"changeGrow($_)" ]}
                <td class="Int">@{[ checkbox "sttIntGrow$_",'+1',"changeGrow($_)" ]}
                <td class="Mnd">@{[ checkbox "sttMndGrow$_",'+1',"changeGrow($_)" ]}
                <td class="Emp">@{[ checkbox "sttEmpGrow$_",'+1',"changeGrow($_)" ]}
HTML
    print '</template>' if($_ eq 'TMPL');
  }
  sub displayGrowRow {
    my $num = shift;
    my $count = 0;
    $count += $pc{"stt${_}Grow$num"} foreach ("Str","Ref","Per","Int","Mnd","Emp");
    return "data-checked=\"$count\"".($count == 3 ? " style=\"display:none\"" : "");
  }
  print <<"HTML";
              <tr class="status-other">
                <th>その他の修正
                <td class="Str">@{[ input 'sttStrMod','number','calcStatus' ]}
                <td class="Ref">@{[ input 'sttRefMod','number','calcStatus' ]}
                <td class="Per">@{[ input 'sttPerMod','number','calcStatus' ]}
                <td class="Int">@{[ input 'sttIntMod','number','calcStatus' ]}
                <td class="Mnd">@{[ input 'sttMndMod','number','calcStatus' ]}
                <td class="Emp">@{[ input 'sttEmpMod','number','calcStatus' ]}
              <tr class="status-total">
                <th>能力基本値
                <td class="Str">
                <td class="Ref">
                <td class="Per">
                <td class="Int">
                <td class="Mnd">
                <td class="Emp">
              <tr class="status-divide">
                <th>
                <td colspan="6">÷3
              <tr  class="status-check-base">
                <th>判定基本値
                <td class="Str">
                <td class="Ref">
                <td class="Per">
                <td class="Int">
                <td class="Mnd">
                <td class="Emp">
              <tr class="status-style">
                <th>スタイル
                <td class="Str   ">@{[ input 'sttStrStyle','number','calcStatus' ]}
                <td class="Ref   ">@{[ input 'sttRefStyle','number','calcStatus' ]}
                <td class="Per   ">@{[ input 'sttPerStyle','number','calcStatus' ]}
                <td class="Int   ">@{[ input 'sttIntStyle','number','calcStatus' ]}
                <td class="Mnd   ">@{[ input 'sttMndStyle','number','calcStatus' ]}
                <td class="Emp   ">@{[ input 'sttEmpStyle','number','calcStatus' ]}
              <tr class="status-check-total">
                <th>判定値
                <td class="Str">
                <td class="Ref">
                <td class="Per">
                <td class="Int">
                <td class="Mnd">
                <td class="Emp">
          </table>
          <table class="edit-table" id="hpmp-table">
            <colgroup>
              <col>
              <col class="Hp    ">
              <col class="Mp    ">
              <col class="HpGrow">
              <col class="MpGrow">
            <colgroup>
            <thead>
              <tr>
                <th>
                <th class="Hp    ">ＨＰ
                <th class="Mp    ">ＭＰ
                <th class="HpGrow"><span class="small">ＨＰ<br>成長</span>
                <th class="MpGrow"><span class="small">ＭＰ<br>成長</span>
            <tbody>
              <tr class="status-base">
                <th>基本値
                <td class="Hp">
                <td class="Mp">
                <td colspan="2">
              <tr class="status-works">
                <th>ワークス
                <td class="Hp">@{[ input 'sttHpWorks','number','calcStatus' ]}
                <td class="Mp">@{[ input 'sttMpWorks','number','calcStatus' ]}
                <td colspan="2">
              <tr class="status-style">
                <th>スタイル
                <td class="Hp    ">@{[ input 'sttHpStyle','number','calcStatus' ]}
                <td class="Mp    ">@{[ input 'sttMpStyle','number','calcStatus' ]}
                <td class="HpGrow">@{[ input 'sttHpGrowStyle','number','calcStatus' ]}
                <td class="MpGrow">@{[ input 'sttMpGrowStyle','number','calcStatus' ]}
              <tr class="status-grow-total">
                <th>成長合計
                <td class="Hp">
                <td class="Mp">
                <td>↵
                <td>↵
              <tr class="status-other">
                <th>その他の修正
                <td class="Hp">@{[ input 'sttHpMod','number','calcStatus' ]}
                <td class="Mp">@{[ input 'sttMpMod','number','calcStatus' ]}
              <tr class="status-total">
                <th>合計
                <td class="Hp">
                <td class="Mp">
                <td colspan="2">
          </table>
          <table class="edit-table" id="sub-status-table">
            <colgroup>
              <col>
              <col class="Init  ">
              <col class="Move  ">
              <col class="Weight">
              <col class="Fate  ">
            <colgroup>
            <thead>
              <tr>
                <th>
                <th class="Init  ">行動値
                <th class="Move  "><span class="small">移動力<br>基本値</span>
                <th class="Weight"><span class="small">所持可能<br>重量</span>
                <th class="Fate  ">天運
            <tbody>
              <tr class="status-base">
                <th>基本値
                <td class="Init  ">
                <td class="Move  ">
                <td class="Weight">
                <td class="Fate  ">3
              <tr class="status-equip">
                <th>装備修正
                <td class="Init  ">
                <td class="Move  ">
                <td class="Weight">―
                <td class="Fate  ">―
              <tr class="status-other">
                <th>その他の修正
                <td class="Init  ">@{[ input 'sttInitMod'     ,'number','calcStatus' ]}
                <td class="Move  ">@{[ input 'sttMoveMod'     ,'number','calcStatus' ]}
                <td class="Weight">@{[ input 'sttMaxWeightMod','number','calcStatus' ]}
                <td class="Fate  ">@{[ input 'sttFateMod'     ,'number','calcStatus' ]}
              <tr class="status-vehicle">
                <th>乗騎修正
                <td class="Init  ">
                <td class="Move  ">
                <td class="Weight">―
                <td class="Fate  ">―
              <tr class="status-total">
                <th>合計<br>(騎乗時)
                <td class="Init  ">
                <td class="Move  ">
                <td class="Weight">
                <td class="Fate  ">
              <tr class="status-divide">
                <td colspan="2">
                <td>÷5+1
                <td>
                <td>
              <tr class="status-header">
                <th colspan="2">
                <th class="Move">移動力
                <th colspan="2">
              <tr class="status-total">
                <td colspan="2">
                <td class="MoveTotal">
                <td colspan="2">
          </table>
        </div>
      </div>

      <div class="box" id="skill">
        <h2 class="in-toc">技能</h2>
        <table class="data-table">
          <thead>
            <tr>
              <th>筋力<span class="small">技能</span><td>判定値<b class="Str-value">0</b>
              <th>反射<span class="small">技能</span><td>判定値<b class="Ref-value">0</b>
              <th>感覚<span class="small">技能</span><td>判定値<b class="Per-value">0</b>
              <th>知力<span class="small">技能</span><td>判定値<b class="Int-value">0</b>
              <th>精神<span class="small">技能</span><td>判定値<b class="Mnd-value">0</b>
              <th>共感<span class="small">技能</span><td>判定値<b class="Emp-value">0</b>
          <tbody>
            <tr>
HTML
  foreach my $stt ("Str","Ref","Per","Int","Mnd","Emp"){
    print '<td colspan="2">';
    my $i = 1;
    foreach my $skill (@{$set::skill{$stt}}){
      if   ($pc{"skill${stt}${i}Lv"} < 2){ $pc{"skill${stt}${i}Lv"} = 2; }
      elsif($pc{"skill${stt}${i}Lv"} > 5){ $pc{"skill${stt}${i}Lv"} = 5; }
      print '<dl class="left">';
      print '<dt>'.$skill;
      if($skill =~ /:$/){ print input("skill${stt}${i}LabelBranch");  }
      print '<dd>'
        ."<span id=\"skill${stt}${i}-text\">"
        .('●' x $pc{"skill${stt}${i}Lv"})
        .('○' x (5-$pc{"skill${stt}${i}Lv"}))
        .'</span>'
        .input("skill${stt}${i}Lv",'number',"changeSkillLv(`${stt}${i}`)",'min=2 max=5');
      print '</dl>';
      $i++;
    }
  }
  print <<"HTML";
          </tbody>
        </table>
      </div>

      <details class="box" id="class-ability" $open{classAbility}>
        <summary class="in-toc">クラス特技</summary>
        @{[input 'classAbilityNum','hidden']}
        <table class="edit-table line-tbody no-border-cells ability-table" id="class-ability-table">
          <colgroup id="works-ability-col">
            <col class="handle">
            <col class="name  ">
            <col class="type  ">
            <col class="lv    ">
            <col class="timing">
            <col class="check ">
            <col class="target">
            <col class="range ">
            <col class="dfclty">
            <col class="cost  ">
            <col class="mc    ">
          </colgroup>
          <thead id="class-ability-head">
            <tr>
              <th>
              <th class="name  ">特技名
              <th class="type  ">種別
              <th class="lv    "><span class="small">レベル</span>
              <th class="timing">タイミング
              <th class="check ">判定
              <th class="target">対象
              <th class="range ">射程
              <th class="dfclty">目標値
              <th class="cost  ">コスト
              <th class="mc    ">MC
HTML
foreach my $num ('TMPL',1 .. $pc{classAbilityNum}){
  if($num eq 'TMPL'){ print '<template id="class-ability-template">' }
  print <<"HTML";
          <tbody id="class-ability-row${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td class="name  ">@{[ input "classAbility${num}Name" ]}
              <td class="type  ">@{[ input "classAbility${num}Type",'','','list="list-class-ability-type"' ]}
              <td class="lv    ">@{[ input "classAbility${num}Lv", 'number',"calcAbility('classAbility')" ]}
              <td class="timing">@{[ input "classAbility${num}Timing",'','','list="list-timing"' ]}
              <td class="check ">@{[ input "classAbility${num}Check",'','','list="list-ability-check"' ]}
              <td class="target">@{[ input "classAbility${num}Target",'','','list="list-target"' ]}
              <td class="range ">@{[ input "classAbility${num}Range",'','','list="list-range"' ]}
              <td class="dfclty">@{[ input "classAbility${num}Dfclty",'','','list="list-dfclty"' ]}
              <td class="cost  ">@{[ input "classAbility${num}Cost",'','','list="list-cost"' ]}
              <td class="mc    ">@{[ selectBox "classAbility${num}MC",'','○','×','FW' ]}
            <tr>
              <td class="note" colspan="10"><b>効果:</b>@{[ input "classAbility${num}Note" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
  print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addClassAbility()">▼</a><a onclick="delClassAbility()">▲</a></div>
      </details>
      <div class="box trash-box" id="class-ability-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除クラス特技</span></h2>
        <table class="edit-table line-tbody" id="class-ability-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('class-ability-trash').style.display = 'none';">close</i>
      </div>

      <details class="box" id="works-ability" $open{worksAbility}>
        <summary class="in-toc">ワークス特技</summary>
        @{[input 'worksAbilityNum','hidden']}
        <table class="edit-table line-tbody no-border-cells ability-table" id="works-ability-table">
          <colgroup id="works-ability-col">
            <col class="handle">
            <col class="name  ">
            <col class="type  ">
            <col class="lv    ">
            <col class="timing">
            <col class="check ">
            <col class="target">
            <col class="range ">
            <col class="dfclty">
            <col class="cost  ">
          </colgroup>
          <thead id="works-ability-head">
            <tr>
              <th>
              <th class="name  ">特技名
              <th class="type  ">種別
              <th class="lv    "><span class="small">レベル</span>
              <th class="timing">タイミング
              <th class="check ">判定
              <th class="target">対象
              <th class="range ">射程
              <th class="dfclty">目標値
              <th class="cost  ">コスト
HTML
foreach my $num ('TMPL',1 .. $pc{worksAbilityNum}){
  if($num eq 'TMPL'){ print '<template id="works-ability-template">' }
  print <<"HTML";
          <tbody id="works-ability-row${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td class="name  ">@{[ input "worksAbility${num}Name" ]}
              <td class="type  ">@{[ input "worksAbility${num}Type",'','','list="list-works-ability-type"' ]}
              <td class="lv    ">@{[ input "worksAbility${num}Lv", 'number',"calcAbility('worksAbility')" ]}
              <td class="timing">@{[ input "worksAbility${num}Timing",'','','list="list-timing"' ]}
              <td class="check ">@{[ input "worksAbility${num}Check",'','','list="list-ability-check"' ]}
              <td class="target">@{[ input "worksAbility${num}Target",'','','list="list-target"' ]}
              <td class="range ">@{[ input "worksAbility${num}Range",'','','list="list-range"' ]}
              <td class="dfclty">@{[ input "worksAbility${num}Dfclty",'','','list="list-dfclty"' ]}
              <td class="cost  ">@{[ input "worksAbility${num}Cost",'','','list="list-cost"' ]}
            <tr>
              <td class="note" colspan="9"><b>効果:</b>@{[ input "worksAbility${num}Note" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
  print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addWorksAbility()">▼</a><a onclick="delWorksAbility()">▲</a></div>
      </details>
      <div class="box trash-box" id="works-ability-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除ワークス特技</span></h2>
        <table class="edit-table line-tbody" id="works-ability-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('works-ability-trash').style.display = 'none';">close</i>
      </div>

      <details class="box" id="magic" $open{magic}>
        <summary class="in-toc">魔法</summary>
        @{[input 'magicNum','hidden']}
        <table class="edit-table line-tbody no-border-cells ability-table" id="magic-table">
          <colgroup id="magic-col">
            <col class="handle  ">
            <col class="name    ">
            <col class="type    ">
            <col class="lv      ">
            <col class="duration">
            <col class="timing  ">
            <col class="check   ">
            <col class="target  ">
            <col class="range   ">
            <col class="dfclty  ">
            <col class="cost    ">
            <col class="mc      ">
          </colgroup>
          <thead id="magic-head">
            <tr>
              <th>
              <th class="name    ">魔法名
              <th class="type    ">種別
              <th class="lv      "><span class="small">レベル</span>
              <th class="duration">効果時間
              <th class="timing  ">タイミング
              <th class="check   ">判定
              <th class="target  ">対象
              <th class="range   ">射程
              <th class="dfclty  ">目標値
              <th class="cost    ">コスト
              <th class="mc      ">MC
HTML
foreach my $num ('TMPL',1 .. $pc{magicNum}){
  if($num eq 'TMPL'){ print '<template id="magic-template">' }
  print <<"HTML";
          <tbody id="magic-row${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td class="name    ">@{[ input "magic${num}Name" ]}
              <td class="type    ">@{[ input "magic${num}Type",'','','list="list-magic-type"' ]}
              <td class="lv      ">@{[ input "magic${num}Lv",'number' ]}
              <td class="duration">@{[ input "magic${num}Duration",'','','list="list-magic-duration"' ]}
              <td class="timing  ">@{[ input "magic${num}Timing",'','','list="list-timing"' ]}
              <td class="check   ">@{[ input "magic${num}Check",'','','list="list-magic-check"' ]}
              <td class="target  ">@{[ input "magic${num}Target",'','','list="list-target"' ]}
              <td class="range   ">@{[ input "magic${num}Range",'','','list="list-range"' ]}
              <td class="dfclty  ">@{[ input "magic${num}Dfclty",'','','list="list-dfclty"' ]}
              <td class="cost    ">@{[ input "magic${num}Cost",'','','list="list-cost"' ]}
              <td class="mc      ">@{[ selectBox "magic${num}MC",'','○','×','FW' ]}
            <tr>
              <td class="note" colspan="11"><b>効果:</b>@{[ input "magic${num}Note" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
  print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addMagic()">▼</a><a onclick="delMagic()">▲</a></div>
      </details>
      <div class="box trash-box" id="magic-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除魔法</span></h2>
        <table class="edit-table line-tbody" id="magic-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('magic-trash').style.display = 'none';">close</i>
      </div>

      <details class="box" id="weapons" $open{weapons}>
        <summary class="in-toc">装備品：武器</summary>
        <table class="edit-table no-border-cells item-table">
          <colgroup>
            <col class="category">
            <col class="name    ">
            <col class="type    ">
            <col class="weight  ">
            <col class="skill   ">
            <col class="acc     ">
            <col class="atk     ">
            <col class="init    ">
            <col class="move    ">
            <col class="guard   ">
            <col class="range   ">
            <col class="note    ">
          </colgroup>
          <thead>
            <tr>
              <th class="category">
              <th class="name    ">
              <th class="type    ">種別
              <th class="weight  ">重量
              <th class="skill   ">技能
              <th class="acc     "><span class="small">命中<br>修正</span>
              <th class="atk     ">攻撃力
              <th class="init    "><span class="small">行動<br>修正</span>
              <th class="move    "><span class="small">移動<br>修正</span>
              <th class="range   ">射程
              <th class="guard   "><span class="small">ガード<br>値</span>
              <th class="note left">効果
          </thead>
          <tbody>
HTML
  foreach ('Main','Sub','Other'){
    print <<"HTML";
            <tr>
              <th class="category">@{[ $_ eq 'Main'?'メイン':$_ eq 'Sub'?'サブ':'その他' ]}
              <td class="name    ">@{[ input "weapon${_}Name" ]}
              <td class="type    ">@{[ input "weapon${_}Type",'','','list="list-weapon-type"' ]}
              <td class="weight  ">@{[ input "weapon${_}Weight","number",'changeWeapon' ]}
              <td class="skill   ">@{[ input "weapon${_}Skill",'','','list="list-weapon-skill"' ]}
              <td class="acc     ">@{[ input "weapon${_}Acc","number",'changeWeapon' ]}
              <td class="atk     ">@{[ input "weapon${_}Atk" ]}
              <td class="init    ">@{[ input "weapon${_}Init","number",'changeWeapon' ]}
              <td class="move    ">@{[ input "weapon${_}Move","number",'changeWeapon' ]}
              <td class="range   ">@{[ input "weapon${_}Range" ]}
              <td class="guard   ">@{[ input "weapon${_}Guard","number",'changeWeapon' ]}
              <td class="note    ">@{[ input "weapon${_}Note" ]}
HTML
  }
  print <<"HTML";
            <tr id="weapon-foot">
              <th class="category">合計
              <td class="name    ">@{[ input "weaponTotalName" ]}
              <td class="type    ">@{[ input "weaponTotalType" ]}
              <td class="weight  ">
              <td class="skill   ">@{[ input "weaponTotalSkill" ]}
              <td class="acc     ">
              <td class="atk     ">@{[ input "weaponTotalAtk" ]}
              <td class="init    ">
              <td class="move    ">
              <td class="range   ">@{[ input "weaponTotalRange" ]}
              <td class="guard   ">
              <td class="note    ">@{[ input "weaponTotalNote" ]}
        </table>
      </details>

      <details class="box" id="armors" $open{armors}>
        <summary class="in-toc">装備品：防具</summary>
        <table class="edit-table no-border-cells item-table">
          <colgroup>
            <col class="category">
            <col class="name    ">
            <col class="type    ">
            <col class="weight  ">
            <col class="eva     ">
            <col class="def     ">
            <col class="def     ">
            <col class="def     ">
            <col class="def     ">
            <col class="init    ">
            <col class="move    ">
            <col class="note    ">
          </colgroup>
          <thead>
            <tr>
              <th class="category" rowspan="2">
              <th class="name    " rowspan="2">
              <th class="type    " rowspan="2">種別
              <th class="weight  " rowspan="2">重量
              <th class="eva     " rowspan="2"><span class="small">回避<br>修正</span>
              <th class="def     " colspan="4"><span class="small">防御力</span>
              <th class="init    " rowspan="2"><span class="small">行動<br>修正</span>
              <th class="move    " rowspan="2"><span class="small">移動<br>修正</span>
              <th class="note left" rowspan="2">効果
            <tr>
              <th class="small">武器
              <th class="small">炎熱
              <th class="small">衝撃
              <th class="small">体内
          <tbody>
HTML
  foreach ('Main','Sub','Other'){
    print <<"HTML";
            <tr>
              <th class="category">@{[ $_ eq 'Main'?'メイン':$_ eq 'Sub'?'サブ':'その他' ]}
              <td class="name    ">@{[ input "armor${_}Name" ]}
              <td class="type    ">@{[ input "armor${_}Type",'','','list="list-armor-type"' ]}
              <td class="weight  ">@{[ input "armor${_}Weight","number",'changeArmor' ]}
              <td class="eva     ">@{[ input "armor${_}Eva","number",'changeArmor' ]}
              <td class="def     ">@{[ input "armor${_}DefWeapon","number",'changeArmor' ]}
              <td class="def     ">@{[ input "armor${_}DefFire","number",'changeArmor' ]}
              <td class="def     ">@{[ input "armor${_}DefShock","number",'changeArmor' ]}
              <td class="def     ">@{[ input "armor${_}DefInternal","number",'changeArmor' ]}
              <td class="init    ">@{[ input "armor${_}Init","number",'changeArmor' ]}
              <td class="move    ">@{[ input "armor${_}Move","number",'changeArmor' ]}
              <td class="note    ">@{[ input "armor${_}Note" ]}
HTML
  }
  print <<"HTML";
            <tr id="armor-foot">
              <th class="category">合計
              <td class="name    ">@{[ input "armorTotalName" ]}
              <td class="type    ">@{[ input "armorTotalType" ]}
              <td class="weight  ">
              <td class="eva     ">
              <td class="def weapon">
              <td class="def fire">
              <td class="def shock">
              <td class="def internal">
              <td class="init    ">
              <td class="move    ">
              <td class="note    ">@{[ input "armorTotalNote" ]}
        </table>
      </details>

      <details class="box" id="vehicle" $open{vehicle}>
        <summary class="in-toc">乗騎</summary>
        <table class="edit-table no-border-cells item-table">
          <colgroup>
            <col class="handle">
            <col class="name">
            <col class="atk ">
            <col class="acc ">
            <col class="eva ">
            <col class="def ">
            <col class="def ">
            <col class="def ">
            <col class="def ">
            <col class="init">
            <col class="move">
            <col class="note">
          </colgroup>
          <thead>
            <tr>
              <th rowspan="2">
              <th class="name" rowspan="2">
              <th class="atk " rowspan="2"><span class="small">攻撃<br>修正</span>
              <th class="acc " rowspan="2"><span class="small">命中<br>修正</span>
              <th class="eva " rowspan="2"><span class="small">回避<br>修正</span>
              <th class="def " colspan="4"><span class="small">防御力</span>
              <th class="init" rowspan="2"><span class="small">行動<br>修正</span>
              <th class="move" rowspan="2"><span class="small">移動<br>修正</span>
              <th class="note left" rowspan="2">効果
            <tr>
              <th class="small">武器
              <th class="small">炎熱
              <th class="small">衝撃
              <th class="small">体内
          <tbody>
            <tr>
              <td>
              <td>@{[ input "vehicle1Name" ]}
              <td>@{[ input "vehicle1Atk","number",'changeWeapon' ]}
              <td>@{[ input "vehicle1Acc","number",'changeWeapon' ]}
              <td>@{[ input "vehicle1Eva","number",'changeArmor' ]}
              <td>@{[ input "vehicle1DefWeapon","number",'changeArmor' ]}
              <td>@{[ input "vehicle1DefFire","number",'changeArmor' ]}
              <td>@{[ input "vehicle1DefShock","number",'changeArmor' ]}
              <td>@{[ input "vehicle1DefInternal","number",'changeArmor' ]}
              <td>@{[ input "vehicle1Init","number",'changeArmor' ]}
              <td>@{[ input "vehicle1Move","number",'changeArmor' ]}
              <td>@{[ input "vehicle1Note" ]}
            <tr id="vehicle-foot">
              <td>
              <td>装備品との合計
              <td class="atk">
              <td class="acc">
              <td class="eva">
              <td class="def weapon">
              <td class="def fire">
              <td class="def shock">
              <td class="def internal">
              <td class="init">
              <td class="move">
              <td>@{[ input "vehicleTotalNote" ]}
        </table>
      </details>

      <details class="box" id="items" $open{items}>
        <summary class="in-toc">アイテム</summary>
        @{[input 'itemNum','hidden']}
        <table class="edit-table no-border-cells item-table">
            <colgroup>
              <col class="handle  ">
              <col class="name    ">
              <col class="weight  ">
              <col class="quantity">
              <col class="note    ">
            </colgroup>
          <thead>
              <tr>
                <th>
                <th class="name    ">
                <th class="weight  ">重量
                <th class="quantity">個数
                <th class="note left">効果
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{itemNum}){
  if($num eq 'TMPL'){ print '<template id="item-template">' }
  print <<"HTML";
            <tr id="item-row${num}">
              <td class="handle  ">
              <td class="name    ">@{[ input "item${num}Name" ]}
              <td class="weight  ">@{[ input "item${num}Weight",'number','changeItem' ]}
              <td class="quantity">@{[ input "item${num}Quantity",'number','changeItem','min="0"' ]}
              <td class="note    ">@{[ input "item${num}Note" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
  print <<"HTML";
          <tfoot>
              <tr>
                <th class="small" colspan="2">その他アイテム重量合計
                <td class="weight" colspan="2">
                <td class="note left">
        </table>
        <div class="add-del-button"><a onclick="addItem()">▼</a><a onclick="delItem()">▲</a></div>
      </details>

      <details class="box" id="force" $open{force}>
        <summary class="in-toc">部隊</summary>
        @{[input 'forceNum','hidden']}
        <table class="edit-table line-tbody no-border-cells item-table">
          <colgroup id="force-col">
            <col class="handle">
            <col class="name">
          </colgroup>
          <thead id="force-head">
            <tr>
              <th rowspan="2">
              <th class="name" rowspan="2">種別
              <th class="lv small" rowspan="2">レベル
              <th class="morale small" rowspan="2">士気
              <th class="stt " colspan="6"><span class="small">能力修正</span>
              <th class="sstt" colspan="3"><span class="small">副能力修正</span>
              <th class="def " rowspan="2"><span class="small">攻撃力</span>
              <th class="def " colspan="4"><span class="small">防御力</span>
            <tr>
              <th class="small">筋力
              <th class="small">反射
              <th class="small">感覚
              <th class="small">知力
              <th class="small">精神
              <th class="small">共感
              <th class="small">ＨＰ
              <th class="small">行動値
              <th class="small">移動力
              <th class="small">武器
              <th class="small">炎熱
              <th class="small">衝撃
              <th class="small">体内
HTML
  foreach my $num ('TMPL',1 .. $pc{forceNum}){
    print '<template id="force-template">' if($num eq 'TMPL');
    print <<"HTML";
          <tbody id="force-row${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td>@{[ input "force${num}Type" ]}
              <td>@{[ input "force${num}Lv","number" ]}
              <td>@{[ input "force${num}Morale","number" ]}
              <td>@{[ input "force${num}Str","number" ]}
              <td>@{[ input "force${num}Ref","number" ]}
              <td>@{[ input "force${num}Per","number" ]}
              <td>@{[ input "force${num}Int","number" ]}
              <td>@{[ input "force${num}Mnd","number" ]}
              <td>@{[ input "force${num}Emp","number" ]}
              <td>@{[ input "force${num}Hp","number" ]}
              <td>@{[ input "force${num}Init","number" ]}
              <td>@{[ input "force${num}Move","number" ]}
              <td>@{[ input "force${num}Atk","number" ]}
              <td>@{[ input "force${num}DefWeapon","number" ]}
              <td>@{[ input "force${num}DefFire","number" ]}
              <td>@{[ input "force${num}DefShock","number" ]}
              <td>@{[ input "force${num}DefInternal","number" ]}
            <tr>
              <td class="right">@{[ radio "forceLead",'deselectable',$num,'この部隊を率いる' ]}
              <td colspan="16"><b>備考:</b>@{[ input "force${num}Note",'','','placeholder="部隊特技やメモなど"' ]}
HTML
    print '</template>' if($num eq 'TMPL');
  }
  print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addForce()">▼</a><a onclick="delForce()">▲</a></div>
      </details>

      <details class="box" id="action-sets" $open{actionSets}>
        <summary class="in-toc">アクションセット</summary>
        @{[input 'actionSetNum','hidden']}
        <div id="action-sets-list">
HTML
  foreach my $num ('TMPL',1 .. $pc{actionSetNum}){
    print '<template id="action-set-template">' if($num eq 'TMPL');
    print <<"HTML";
          <fieldset id="action-set-row${num}">
            <div class="handle"></div>
            <div class="top-row">
              <dl class="name"><dt>名称    <dd>@{[ input "actionSet${num}Name" ]}</dl>
              <dl class="ability"><dt>使用特技<dd>
                <dl>
                  <dt>マイナー<dd>@{[ input "actionSet${num}Minor" ]}
                  <dt>メジャー<dd>@{[ input "actionSet${num}Major" ]}
                  <dt>その他  <dd>@{[ input "actionSet${num}Other" ]}
                </dl>
              </dl>
              <dl class="check"><dt>判定<dd>
                <dl>
                  <dt>使用技能<dd>@{[ selectBox "actionSet${num}Skill","",@skillNames  ]}
                  <dt>ダイス  <dd><span>+</span>@{[ input "actionSet${num}Dice"   ]}
                  <dt>判定値  <dd>@{[ selectBox "actionSet${num}Check","",'def=|<自動（技能に合った判定値）>','筋力','反射','感覚','知力','精神','共感'  ]}
                  <dt>修正値  <dd><span>+</span>@{[ input "actionSet${num}Mod"    ]}
                  <dt>目標値  <dd>@{[ input "actionSet${num}Dfclty","","",'list="list-dfclty"' ]}
                </dl>
              </dl>
            </div>
            <div class="bottom-row">
              <dl class="target"><dt>対象    <dd>@{[ input "actionSet${num}Target","","",'list="list-target"' ]}</dl>
              <dl class="range "><dt>射程    <dd>@{[ input "actionSet${num}Range","","",'list="list-range"'  ]}</dl>
              <dl class="mc    "><dt>MC      <dd>@{[ selectBox "actionSet${num}MC","",'○','×','FW' ]}</dl>
              <dl class="cost  "><dt>コスト  <dd>@{[ input "actionSet${num}Cost","","",'list="list-cost"'   ]}</dl>
              <dl class="dmg   "><dt>ダメージ<dd>@{[ input "actionSet${num}Dmg"    ]}</dl>
              <dl class="note  "><dt>効果    <dd>@{[ input "actionSet${num}Note"   ]}</dl>
              <span class="button" onclick="addActionSet($num)">複<br>製</span>
            </div>
          </fieldset>
HTML
    print '</template>' if($num eq 'TMPL');
  }
  print <<"HTML";
        </div>
        <div class="add-del-button"><a onclick="addActionSet()">▼</a><a onclick="delActionSet()">▲</a></div>
      </details>

      <details class="box" id="reaction-sets" $open{reactionSets}>
        <summary class="in-toc">リアクションセット</summary>
        @{[input 'reactionSetNum','hidden']}
        <div id="reaction-sets-list">
HTML
  foreach my $num ('TMPL',1 .. $pc{reactionSetNum}){
    print '<template id="reaction-set-template">' if($num eq 'TMPL');
    print <<"HTML";
          <fieldset id="reaction-set-row${num}">
            <div class="handle"></div>
            <div class="top-row">
              <dl class="name"><dt>名称    <dd>@{[ input "reactionSet${num}Name" ]}</dl>
              <dl class="ability"><dt>使用特技<dd>
                <dl>
                  <dt>リアクション<dd>@{[ input "reactionSet${num}Reaction" ]}
                  <dt>その他  <dd>@{[ input "reactionSet${num}Other" ]}
                </dl>
              </dl>
              <dl class="check"><dt>判定<dd>
                <dl>
                  <dt>使用技能<dd>@{[ selectBox "reactionSet${num}Skill","",@skillNames  ]}
                  <dt>ダイス  <dd><span>+</span>@{[ input "reactionSet${num}Dice"   ]}
                  <dt>判定値  <dd>@{[ selectBox "reactionSet${num}Check","",'def=|<自動（技能に合った判定値）>','筋力','反射','感覚','知力','精神','共感'  ]}
                  <dt>修正値  <dd><span>+</span>@{[ input "reactionSet${num}Mod"    ]}
                  <dt>目標値  <dd>@{[ input "reactionSet${num}Dfclty","","",'list="list-dfclty"' ]}
                </dl>
              </dl>
            </div>
            <div class="bottom-row">
              <dl class="mc    "><dt>MC      <dd>@{[ selectBox "reactionSet${num}MC","",'○','×','FW' ]}</dl>
              <dl class="cost  "><dt>コスト  <dd>@{[ input "reactionSet${num}Cost","","",'list="list-cost"'   ]}</dl>
              <dl class="note  "><dt>効果    <dd>@{[ input "reactionSet${num}Note"   ]}</dl>
              <span class="button" onclick="addReactionSet($num)">複<br>製</span>
            </div>
          </fieldset>
HTML
    print '</template>' if($num eq 'TMPL');
  }
  print <<"HTML";
        </div>
        <div class="add-del-button"><a onclick="addReactionSet()">▼</a><a onclick="delReactionSet()">▲</a></div>
      </details>
      
      <div class="box" id="exp-footer">
        <p>
          <b>クラス特技レベル合計</b>
          [<b class="total-class-ability">0</b><!--/<b class="max-class-ability">0</b>-->]
          ｜
          <b>ワークス特技レベル合計</b>
          [<b class="total-works-ability">0</b>/<b class="max-works-ability">0</b>]
          ｜
          <b>魔法レベル合計</b>
          [<b class="total-magic">0</b>]
          ｜
          <b>重量合計</b>
          [<b class="total-weight">0</b>/<b class="max-weight">0</b>]
        </p>
      </div>

      <div id="area-profile">
        @{[ imageForm($pc{imageURL}) ]}
        <div class="box-union in-toc" id="personal" data-content-title="所属国・性別・年齢・身長・体重">
          <dl class="box" id="country">
            <dt>所属国
            <dd>@{[ input 'country','','','autocomplete="off"' ]}
            <dt>国シートURL
            <dd>@{[ input 'countryURL','url' ]}
          </dl>
          <dl class="box" id="gender">
            <dt>性別
            <dd>@{[ input 'gender','','','list="list-gender"' ]}
          </dl>
          <dl class="box" id="age">
            <dt>年齢
            <dd>@{[ input 'age' ]}
          </dl>
          <dl class="box" id="height">
            <dt>身長
            <dd>@{[ input 'height' ]}
          </dl>
          <dl class="box" id="weight">
            <dt>体重
            <dd>@{[ input 'weight' ]}
          </dl>
        </div>

        <div class="box" id="lifepath">
          <h2 class="in-toc">ライフパス</h2>
          <table class="edit-table line-tbody no-border-cells">
            <tbody>
              <tr>
                <th>出自表
                <td>@{[ input 'lifepathBirthType','','','list="list-lifepath-birth"' ]}
                <td>@{[ input 'lifepathBirth' ]}
            <tbody>
              <tr>
                <th>経験表1
                <td>@{[ input 'lifepathExp1Type','','','list="list-lifepath-exp1"' ]}
                <td>@{[ input 'lifepathExp1' ]}
            <tbody>
              <tr>
                <th>経験表2
                <td>@{[ input 'lifepathExp2Type','','','list="list-lifepath-exp2"' ]}
                <td>@{[ input 'lifepathExp2' ]}
          </table>
        </div>

        <div class="box" id="belief">
          <h2 class="in-toc">信念</h2>
          <table class="edit-table no-border-cells">
            <tbody>
              <tr>
                <th>目的
                <td>@{[ input 'beliefPurpose' ]}
              <tr>
                <th>禁忌
                <td>@{[ input 'beliefTaboo' ]}
              <tr>
                <th>趣味嗜好
                <td>@{[ input 'beliefQuirk' ]}
          </table>
        </div>

        <div class="box" id="bond">
          <h2 class="in-toc">因縁</h2>
          <table class="edit-table no-border-cells">
            <thead>
              <tr>
                <th>
                <th>対象
                <th>関係
                <th>感情<span class="small">(メイン/サブ)</span>
            <tbody>
HTML
  foreach my $num (1 .. 5){
  print <<"HTML";
              <tr id="bond-row${num}">
                <td class="handle  ">
                <td class="name    ">@{[ input "bond${num}Name" ]}
                <td class="relation">@{[ input "bond${num}Relation" ]}
                <td class="emotion ">
                  @{[ input "bond${num}EmotionMain",'','','list="list-emotion"' ]}
                  /
                  @{[ input "bond${num}EmotionSub",'','','list="list-emotion"' ]}
HTML
  }
  print <<"HTML";
          </table>
        </div>
      </div>
      
      <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
        <summary class="in-toc">設定・メモ</summary>
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
          <colgroup id="history-col">
            <col>
            <col class="date  ">
            <col class="title ">
            <col class="exp   ">
            <col class="gm    ">
            <col class="member">
          </colgroup>
          <thead id="history-head">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="exp   ">経験点
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
              <td class="handle" rowspan="2">
              <td class="date  " rowspan="2">@{[input("history${num}Date")]}
              <td class="title " rowspan="2">@{[input("history${num}Title")]}
              <td class="exp   ">@{[input("history${num}Exp",'','calcExp')]}
              <td class="gm    ">@{[input("history${num}Gm")]}
              <td class="member">@{[input("history${num}Member")]}
            <tr>
              <td colspan="3" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}
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
              <td colspan="2">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="exp   ">経験点
              <th class="gm    ">GM
              <th class="member">参加者
            </tr>
          </tfoot>
        </table>
        <div class="add-del-button"><a onclick="addHistory()">▼</a><a onclick="delHistory()">▲</a></div>
        <h2>記入例</h2>
        <table class="example edit-table line-tbody no-border-cells">
          <colgroup id="history-col">
            <col>
            <col class="date  ">
            <col class="title ">
            <col class="exp   ">
            <col class="gm    ">
            <col class="member">
          </colgroup>
          <thead>
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="exp   ">経験点
              <th class="gm    ">GM
              <th class="member">参加者
          <tbody>
            <tr>
              <td>-
              <td><input type="text" value="2013/08/20" disabled>
              <td><input type="text" value="第一話「記入例」" disabled>
              <td><input type="text" value="" disabled>
              <td><input type="text" value="サンプルさん" disabled>
              <td><input type="text" value="テオ　シルーカ" disabled class="left">
            </tr>
          </tbody>
        </table>
        <ul class="annotate">
          <li>経験点欄は<code>1+2*2</code>など四則演算が有効です。<br>
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
print textRuleArea( '','「容姿・経歴・その他メモ」「履歴（自由記入）」「所持品」「収支履歴」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">©Shunsaku Yano/Team Barrelroll.「グランクレストRPG」</p>
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
  <datalist id="list-lifepath-birth">
    <option value="一般">
    <option value="貴族">
    <option value="戦場">
    <option value="混沌">
  </datalist>
  <datalist id="list-lifepath-exp1">
    <option value="戦闘系ワークス">
    <option value="技術系ワークス">
    <option value="知識・魔法系ワークス">
    <option value="社会系ワークス">
  </datalist>
  <datalist id="list-lifepath-exp2">
    <option value="ロード">
    <option value="メイジ">
    <option value="アーティスト">
  </datalist>
  <datalist id="list-class-ability-type">
    <option value="―">
    <option value="天恵">
    <option value="天恵（）">
    <option value="魔法">
    <option value="魔法（）">
    <option value="邪紋">
    <option value="邪紋（）">
  </datalist>
  <datalist id="list-works-ability-type">
    <option value="―">
    <option value="戦闘">
    <option value="戦闘（）">
    <option value="技術">
    <option value="技術（）">
    <option value="知識">
    <option value="知識（）">
    <option value="社会">
    <option value="社会（）">
    <option value="魔法">
    <option value="魔法（）">
    <option value="共通">
    <option value="共通（）">
  </datalist>
  <datalist id="list-magic-type">
    <option value="魔法">
    <option value="魔法（）">
  </datalist>
  <datalist id="list-magic-duration">
    <option value="瞬間">
    <option value="解除まで">
    <option value="1プロセス">
    <option value="1ラウンド">
    <option value="1シーン">
    <option value="1シナリオ">
  </datalist>
  <datalist id="list-timing">
    <option value="常時">
    <option value="いつでも">
    <option value="セットアップ">
    <option value="イニシアチブ">
    <option value="クリンナップ">
    <option value="メジャー">
    <option value="マイナー">
    <option value="リアクション">
    <option value="ガード">
    <option value="判定の直前">
    <option value="判定の直後">
    <option value="攻撃の直前">
    <option value="ダメージロール直前">
    <option value="ダメージロール直後">
    <option value="ダイスロール直前">
    <option value="ダイスロール直後">
    <option value="魔法使用の直前">
    <option value="魔法使用の直後">
    <option value="魔法の使用時">
    <option value="隠密状態">
    <option value="効果参照">
  </datalist>
  <datalist id="list-ability-check">
    <option value="―">
    <option value="自動成功">
    <option value="白兵技能">
    <option value="〈格闘〉">
    <option value="〈格闘〉〈軽武器〉">
    <option value="〈軽武器〉">
    <option value="〈軽武器〉〈射撃〉">
    <option value="〈軽武器〉〈重武器〉">
    <option value="〈重武器〉">
    <option value="〈射撃〉">
    
    <option value="〈頑健〉">

    <option value="〈隠密〉">
    <option value="〈騎乗〉">
    
    <option value="〈知覚〉">
    <option value="〈霊感〉">
    
    <option value="〈軍略知識〉">

    <option value="〈意志〉">
    <option value="〈聖印〉">

    <option value="〈話術〉">
    <option value="〈感性〉">
    <option value="〈治療〉">
    <option value="〈情報収集〉">
  </datalist>
  <datalist id="list-magic-check">
    <option value="―">
    <option value="自動成功">
    <option value="〈知覚〉">
    <option value="〈霊感〉">
    <option value="〈混沌知識〉">
    <option value="〈軍略知識〉">
    <option value="〈専門知識:〉">
    <option value="〈感性〉">
    <option value="〈治療〉">
  </datalist>
  <datalist id="list-target">
    <option value="自身">
    <option value="単体">
    <option value="単体☆">
    <option value="2体">
    <option value="2体☆">
    <option value="LV体">
    <option value="範囲1">
    <option value="範囲LV">
    <option value="直線3">
    <option value="直線5">
    <option value="十字">
    <option value="特殊">
    <option value="特殊☆">
    <option value="シーン">
    <option value="シーン（選択）">
  </datalist>
  <datalist id="list-range">
    <option value="―">
    <option value="なし">
    <option value="武器">
    <option value="視界">
    <option value="効果参照">
    <option value="0Sq">
    <option value="1Sq">
    <option value="2Sq">
    <option value="3Sq">
    <option value="4Sq">
    <option value="5Sq">
    <option value="6Sq">
    <option value="8Sq">
    <option value="9Sq">
    <option value="[LV]Sq">
  </datalist>
  <datalist id="list-dfclty">
    <option value="―">
    <option value="対決">
    <option value="／対決">
    <option value="効果参照">
  </datalist>
  <datalist id="list-cost">
    <option value="―">
    <option value="LV×5">
    <option value="天運">
    <option value="天運1">
    <option value="天運2">
    <option value="効果参照">
  </datalist>
  <datalist id="list-mc">
    <option value="―">
    <option value="○">
    <option value="×">
    <option value="FW">
  </datalist>
  <datalist id="list-weapon-type">
    <option value="">
    <option value="格闘（素手）">
    <option value="軽武器（短剣）">
    <option value="軽武器（突剣）">
    <option value="軽武器（長剣）">
    <option value="軽武器（槍）">
    <option value="軽武器（斧）">
    <option value="軽武器（棍）">
    <option value="重武器（大剣）">
    <option value="重武器（槍）">
    <option value="重武器（斧）">
    <option value="重武器（斧／槍）">
    <option value="重武器（棍）">
    <option value="射撃（投擲）">
    <option value="射撃（弓）">
    <option value="射撃（弩）">
    <option value="盾">
    <option value="その他">
  </datalist>
  <datalist id="list-weapon-skill">
    <option value="―">
    <option value="〈格闘〉">
    <option value="〈軽武器〉">
    <option value="〈重武器〉">
    <option value="〈射撃〉">
    <option value="〈力技〉">
  </datalist>
  <datalist id="list-armor-type">
    <option value="衣服／布">
    <option value="衣服／金属">
    <option value="鎧／革">
    <option value="鎧／金属">
    <option value="頭部／革">
    <option value="頭部／金属">
    <option value="腕部／革">
    <option value="腕部／金属">
    <option value="脚部／革">
    <option value="脚部／金属">
    <option value="外套／革">
  </datalist>
  <datalist id="list-emotion">
    <!-- ポジティブ -->
    <option value="好奇心">
    <option value="憧憬">
    <option value="尊敬">
    <option value="同志">
    <option value="友情">
    <option value="慕情">
    <option value="庇護">
    <option value="幸福感">
    <option value="信頼">
    <option value="尽力">
    <option value="可能性">
    <option value="慈愛">
    <option value="かわいい">
    <option value="同情">
    <option value="連帯感">
    <option value="親近感">
    <option value="感服">
    <option value="誠意">
    <!-- ネガティブ -->
    <option value="憤懣">
    <option value="悲哀">
    <option value="寂しさ">
    <option value="食傷">
    <option value="敵愾心">
    <option value="不快感">
    <option value="猜疑心">
    <option value="嫌悪">
    <option value="隔意">
    <option value="憎悪">
    <option value="偏愛">
    <option value="疎外感">
    <option value="劣等感">
    <option value="不安">
    <option value="恐怖">
    <option value="嫉妬">
    <option value="脅威">
    <option value="侮蔑">
  </datalist>
HTML
my %settings = (
  gameSystem => $set::game,
  styleNames => \@data::styleNames,
  worksNames => \@data::worksNames,
  styleData => \%data::styleData,
  worksData => \%data::worksData,
);
print <<"HTML";
  <script>
  const SET = @{[ JSON::PP->new->encode(\%settings) ]};
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;