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

my @races   = data::raceNameList();
my @classes = data::classNameList();
my @styles  = data::styleNameList();

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
  
  $pc{level} = 1;
  
  $pc{paletteUseVar} = 1;
  $pc{paletteUseBuff} = 1;

  %pc = applyCustomizedInitialValues(\%pc;
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
$pc{goodsNum}   ||= 2;
$pc{itemsNum}   ||= 2;
$pc{historyNum} ||= 3;

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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/vc/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/vc/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/vc/edit-chara.js?${main::ver}" defer></script>
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
      
      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}
        
        <div id="levels">
          <dl class="box">
            <dt class="in-toc">戦果点</dt>
            <dd>
              @{[ input 'history0Result', 'number','calcResultPoint' ]}
              + <span id="resultpoint-history">0</span>
              - <span id="resultpoint-cost">0</span>
              = <b id="resultpoint-total">0</b>
            </dd>
          </dl>
          <dl class="box">
            <dt class="in-toc">レベル
            <dd>@{[ input 'level', 'number', 'calcBattle' ]}
          </dl>
        </div>

        <div id="personal">
          <div class="box-union" class="in-toc" data-content-title="種族・クラス">
            <dl class="box" id="">
              <dt>種族
              <dd>@{[ selectInput 'race','',@races ]}
            </dl>
            <dl class="box" id="">
              <dt>クラス
              <dd>@{[ selectInput 'class','',@classes ]}
            </dl>
          </div>

          <div class="box-union">
            <dl class="box" id="">
              <dt class="in-toc">スタイル
              <dd>@{[ selectInput 'style1','',@styles ]}
              <dd>@{[ selectInput 'style2','',@styles ]}
            </dl>
          </div>
        </div>

        <div class="box" id="appearance">
          <h2 class="in-toc">キャラクター外見</h2>
          <dl class="">
            <dt>性別
            <dd>@{[ input 'gender','','','list="list-gender"' ]}
            <dt>年齢
            <dd>@{[ input 'age' ]}
            <dt>瞳の色
            <dd>@{[ input 'eye' ]}
            <dt>肌の色
            <dd>@{[ input 'skin' ]}
            <dt>髪の色
            <dd>@{[ input 'hair' ]}
            <dt>身長
            <dd>@{[ input 'height' ]}
          </dl>
        </div>

        <div id="status">
          <div class="box" id="user-status">
            <h2 class="in-toc">能力値</h2>
            <dl class="">
              <dt>バイタリティ
              <dd>@{[ input 'vitality','number','calcStatus' ]}
              <dt>テクニック
              <dd>@{[ input 'technic','number' ]}
              <dt>クレバー
              <dd>@{[ input 'clever','number' ]}
              <dt>カリスマ
              <dd>@{[ input 'carisma','number' ]}
            </dl>
          </div>
          <div class="box-union in-toc" id="hp-and-stamina" data-content-title="ＨＰ・スタミナ">
            <dl class="box" id="hp">
              <dt>ＨＰ
              <dd>
                +@{[ input 'hpAdd','number','calcBattle' ]}=
                <b id="hp-value">0</b>
              </dd>
            </dl>
            <dl class="box" id="stamina">
              <dt>スタミナ
              <dd>
                +@{[ input 'staminaAdd','number','calcStatus' ]}=
                <b id="stamina-value">0</b> <small>(半分:<span id="stamina-half">0</span>)</small>
              </dd>
            </dl>
          </div>
        </div>
      </div>
      

      <div class="box" id="specialities" $open{specialities}>
        <h2 class="in-toc">特技</h2>
        <table class="edit-table no-border-cells" id="speciality-table">
          <thead>
            <tr><th>名称<th class="left">効果
          </thead>
          <tbody>
            <tr id="skill1">
              <td>@{[input "speciality1Name" ]}
              <td>@{[input "speciality1Note" ]}
            <tr id="skill2">
              <td>@{[input "speciality2Name" ]}
              <td>@{[input "speciality2Note" ]}
            </tr>
          </tbody>
        </table>
      </div>

      <div class="box" id="goods" $open{goods}>
        <h2 class="in-toc">グッズ</h2>
        @{[input 'goodsNum','hidden']}
        <table class="edit-table no-border-cells" id="goods-table">
          <thead>
            <tr><th><th>名称<th>種別<th>戦果点<th>効果
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{goodsNum}){
  if($num eq 'TMPL'){ print '<template id="goods-template">' }
  print <<"HTML";
            <tr id="goods-row${num}">
              <td class="handle">
              <td>@{[input "goods${num}Name" ]}
              <td>@{[input "goods${num}Type",'','','list="list-goods-type"' ]}
              <td>@{[input "goods${num}Cost",'number','calcResultPoint' ]}
              <td>@{[input "goods${num}Note" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
  print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addGoods()">▼</a><a onclick="delGoods()">▲</a></div>
      </div>

      <div class="box" id="battle">
        <h2 class="in-toc">戦闘値表</h2>
        <table class="edit-table no-border-cells">
          <colgroup>
            <col class="head">
            <col class="name">
            <col class="acc ">
            <col class="spl ">
            <col class="eva ">
            <col class="atk ">
            <col class="det ">
            <col class="def ">
            <col class="mdf ">
            <col class="ini ">
            <col class="str ">
          </colgroup>
          <thead>
            <tr>
              <th colspan="2">
              <th>命中値
              <th>詠唱値
              <th>回避値
              <th>攻撃値
              <th>意志値
              <th>物防値
              <th>魔防値
              <th>行動値
              <th>耐久値
            </tr>
          <tbody>
            <tr>
              <th colspan="2" class="right">基本戦闘値
              <td>@{[ input "battleBaseAcc", 'number','calcBattle' ]}
              <td>@{[ input "battleBaseSpl", 'number','calcBattle' ]}
              <td>@{[ input "battleBaseEva", 'number','calcBattle' ]}
              <td>@{[ input "battleBaseAtk", 'number','calcBattle' ]}
              <td>@{[ input "battleBaseDet", 'number','calcBattle' ]}
              <td>@{[ input "battleBaseDef", 'number','calcBattle' ]}
              <td>@{[ input "battleBaseMdf", 'number','calcBattle' ]}
              <td>@{[ input "battleBaseIni", 'number','calcBattle' ]}
              <td>@{[ input "battleBaseStr", 'number','calcBattle' ]}
            <tr>
              <th>種族特性
              <td>@{[ input "battleRaceName" ]}
              <td>@{[ input "battleRaceAcc", 'number','calcBattle' ]}
              <td>@{[ input "battleRaceSpl", 'number','calcBattle' ]}
              <td>@{[ input "battleRaceEva", 'number','calcBattle' ]}
              <td>@{[ input "battleRaceAtk", 'number','calcBattle' ]}
              <td>@{[ input "battleRaceDet", 'number','calcBattle' ]}
              <td>@{[ input "battleRaceDef", 'number','calcBattle' ]}
              <td>@{[ input "battleRaceMdf", 'number','calcBattle' ]}
              <td>@{[ input "battleRaceIni", 'number','calcBattle' ]}
              <td>@{[ input "battleRaceStr", 'number','calcBattle' ]}
            <tr class="subtotal">
              <th colspan="2" class="right">小計
              <td id="battle-subtotal-acc">
              <td id="battle-subtotal-spl">
              <td id="battle-subtotal-eva">
              <td id="battle-subtotal-atk">
              <td id="battle-subtotal-det">
              <td id="battle-subtotal-def">
              <td id="battle-subtotal-mdf">
              <td id="battle-subtotal-ini">
              <td id="battle-subtotal-str">
HTML
foreach (
  ['Weapon', '武器'   ],
  ['Head'  , '頭防具' ],
  ['Body'  , '胴防具' ],
  ['Acc1'  , '装飾品' ],
  ['Acc2'  , '装飾品' ],
){
  my $th = @{$_}[1];
  my $id = @{$_}[0];
  print <<"HTML";
            <tr>
              <th>@{[ length($th) > 3 ? "<span>$th</span>" : $th ]}
              <td>@{[ input "battle${id}Name" ]}
              <td>@{[ input "battle${id}Acc", 'number','calcBattle' ]}
              <td>@{[ input "battle${id}Spl", 'number','calcBattle' ]}
              <td>@{[ input "battle${id}Eva", 'number','calcBattle' ]}
              <td>@{[ input "battle${id}Atk", 'number','calcBattle' ]}
              <td>@{[ input "battle${id}Det", 'number','calcBattle' ]}
              <td>@{[ input "battle${id}Def", 'number','calcBattle' ]}
              <td>@{[ input "battle${id}Mdf", 'number','calcBattle' ]}
              <td>@{[ input "battle${id}Ini", 'number','calcBattle' ]}
              <td>@{[ input "battle${id}Str", 'number','calcBattle' ]}
HTML
}
print <<"HTML";
            <tr>
              <th colspan="2" class="right">その他修正
              <td>@{[ input "battleOtherAcc", 'number','calcBattle' ]}
              <td>@{[ input "battleOtherSpl", 'number','calcBattle' ]}
              <td>@{[ input "battleOtherEva", 'number','calcBattle' ]}
              <td>@{[ input "battleOtherAtk", 'number','calcBattle' ]}
              <td>@{[ input "battleOtherDet", 'number','calcBattle' ]}
              <td>@{[ input "battleOtherDef", 'number','calcBattle' ]}
              <td>@{[ input "battleOtherMdf", 'number','calcBattle' ]}
              <td>@{[ input "battleOtherIni", 'number','calcBattle' ]}
              <td>@{[ input "battleOtherStr", 'number','calcBattle' ]}
            <tr>
              <th colspan="2" class="right">キャラクターレベル
              <td colspan="9" id="battle-level-value">
            <tr class="total">
              <th colspan="2" class="right">合計
              <td id="battle-total-acc">0
              <td id="battle-total-spl">0
              <td id="battle-total-eva">0
              <td id="battle-total-atk">0
              <td id="battle-total-det">0
              <td id="battle-total-def">0
              <td id="battle-total-mdf">0
              <td id="battle-total-ini">0
              <td id="battle-total-str">0
            </tr>
          </tbody>
        </table>
      </div>

      <div class="box" id="items" $open{items}>
        <h2 class="in-toc">アイテム</h2>
        @{[input 'itemsNum','hidden']}
        <table class="edit-table no-border-cells" id="items-table">
          <thead>
            <tr><th><th>名称<th>種別<th>レベル<th>戦果点<th>効果
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{itemsNum}){
  if($num eq 'TMPL'){ print '<template id="item-template">' }
  print <<"HTML";
            <tr id="item-row${num}">
              <td class="handle">
              <td>@{[input "item${num}Name" ]}
              <td>@{[input "item${num}Type",'','','list="list-item-type"' ]}
              <td>@{[input "item${num}Lv"  ,'number' ]}
              <td>@{[input "item${num}Cost",'number','calcResultPoint' ]}
              <td>@{[input "item${num}Note" ]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
  print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addItem()">▼</a><a onclick="delItem()">▲</a></div>
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
          <thead id="history-head">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="result">戦果点
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
              <td class="result">@{[input("history${num}Result",'text','calcResultPoint')]}
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
              <td id="history-result-total">
              <td colspan="2">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="result">戦果点
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
              <th class="result">戦果点
              <th class="gm    ">GM
              <th class="member">参加者
          <tbody>
            <tr>
              <td>-
              <td><input type="text" value="2019/07/02" disabled>
              <td><input type="text" value="第十四話「記入例」" disabled>
              <td><input type="text" value="5*14" disabled>
              <td><input type="text" value="サンプルさん" disabled>
              <td><input type="text" value="アルバート　ラミミ　ブランヘルツ　ジャ・ルマレ　ナイユベール" disabled>
            </tr>
          </tbody>
        </table>
        <ul class="annotate">
          <li>戦果点欄は<code>5*2</code>など四則演算が有効です。
        </ul>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
      </div>
      
      <div class="box" id="exp-footer">
        <p>
        戦果点[<b id="result-total"></b>] - 
        ( グッズ[<b id="result-used-goods"></b>]
        + アイテム[<b id="result-used-items"></b>]
        ) = 残り[<b id="result-rest"></b>]点
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
    <p class="notes">©FarEast Amusement Research Co.,Ltd.「ヴィジョンコネクト」</p>
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
  <datalist id="list-goods-type">
    <option value="一般">
    <option value="デバイス">
    <option value="サポーター">
  </datalist>
  <datalist id="list-item-type">
    <option value="武器">
    <option value="頭防具">
    <option value="胴防具">
    <option value="装飾品">
    <option value="薬品">
    <option value="料理">
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
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;