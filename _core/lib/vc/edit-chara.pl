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
  
  $pc{'history0Result'} = $set::make_exp || 0;
  
  $pc{'level'} = 1;
  
  $pc{'paletteUseVar'} = 1;
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
$pc{'goodsNum'}   ||= 2;
$pc{'itemsNum'}   ||= 2;
$pc{'historyNum'} ||= 3;

### 折り畳み判断 --------------------------------------------------
my %open;
$open{'skills'} = 'open';
#foreach (3..$pc{'skillsNum'}){ if($pc{"skill${_}Name"} || $pc{"skill${_}Lv"}){ $open{'skills'} = 'open'; last; } }

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
foreach my $i (1 .. $pc{'geisesNum'}){
  $pc{"geis${i}Note"} =~ s/&lt;br&gt;/\n/g;
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
  print '<input type="hidden" name="_token" value="'.tokenMake().'">'."\n";
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
        </dd>
        <dd>
          ※一覧に非表示でもタグ検索結果・マイリストには表示されます
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
            <dd>@{[input('characterName','text',"nameSet")]}</dd>
          </dl>
        </div>
        <dl id="player-name">
          <dt>プレイヤー名</dt>
          <dd>@{[input('playerName')]}</dd>
        </dl>
      </div>
      
      <div id="area-status">
        @{[ imageForm("${set::char_dir}${file}/image.$pc{'image'}?$pc{'imageUpdate'}") ]}
        
        <div id="levels">
          <dl class="box">
            <dt>戦果点</dt>
            <dd>
              @{[ input 'history0Result', 'number','calcResultPoint' ]}
              + <span id="resultpoint-history">0</span>
              - <span id="resultpoint-cost">0</span>
              = <b id="resultpoint-total">0</b>
            </dd>
          </dl>
          <dl class="box">
            <dt>レベル</dt>
            <dd>@{[ input 'level', 'number', 'calcBattle' ]}</dd>
          </dl>
        </div>

        <div id="personal">
          <div class="box-union">
            <dl class="box" id="">
              <dt>種族</dt>
              <dd>@{[ selectInput 'race','',@races ]}</dd>
            </dl>
            <dl class="box" id="">
              <dt>クラス</dt>
              <dd>@{[ selectInput 'class','',@classes ]}</dd>
            </dl>
          </div>

          <div class="box-union">
            <dl class="box" id="">
              <dt>スタイル</dt>
              <dd>@{[ selectInput 'style1','',@styles ]}</dd>
              <dd>@{[ selectInput 'style2','',@styles ]}</dd>
            </dl>
          </div>
        </div>

        <div class="box" id="appearance">
          <h2>キャラクター外見</h2>
          <dl class="">
            <dt>性別</dt>
            <dd>@{[ input 'gender','','','list="list-gender"' ]}</dd>
            <dt>年齢</dt>
            <dd>@{[ input 'age' ]}</dd>
            <dt>瞳の色</dt>
            <dd>@{[ input 'eye' ]}</dd>
            <dt>肌の色</dt>
            <dd>@{[ input 'skin' ]}</dd>
            <dt>髪の色</dt>
            <dd>@{[ input 'hair' ]}</dd>
            <dt>身長</dt>
            <dd>@{[ input 'height' ]}</dd>
          </dl>
        </div>

        <div id="status">
          <div class="box" id="user-status">
            <h2>能力値</h2>
            <dl class="">
              <dt>バイタリティ</dt>
              <dd>@{[ input 'vitality','number','calcStatus' ]}</dd>
              <dt>テクニック</dt>
              <dd>@{[ input 'technic','number' ]}</dd>
              <dt>クレバー</dt>
              <dd>@{[ input 'clever','number' ]}</dd>
              <dt>カリスマ</dt>
              <dd>@{[ input 'carisma','number' ]}</dd>
            </dl>
          </div>
          <div class="box-union" id="hp-and-stamina">
            <dl class="box" id="hp">
              <dt>HP</dt>
              <dd>
                +@{[ input 'hpAdd','number','calcBattle' ]}=
                <b id="hp-value">0</b>
              </dd>
            </dl>
            <dl class="box" id="stamina">
              <dt>スタミナ</dt>
              <dd>
                +@{[ input 'staminaAdd','number','calcStatus' ]}=
                <b id="stamina-value">0</b> <small>(半分:<span id="stamina-half">0</span>)</small>
              </dd>
            </dl>
          </div>
        </div>
      </div>
      

      <div class="box" id="specialities" $open{'specialities'}>
        <h2>特技</h2>
        <table class="edit-table no-border-cells" id="speciality-table">
          <thead>
            <tr><th>名称</th><th class="left">効果</th></tr>
          </thead>
          <tbody>
            <tr id="skill1">
              <td>@{[input "speciality1Name" ]}</td>
              <td>@{[input "speciality1Note" ]}</td>
            </tr>
            <tr id="skill2">
              <td>@{[input "speciality2Name" ]}</td>
              <td>@{[input "speciality2Note" ]}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="box" id="goods" $open{'goods'}>
        <h2>グッズ</h2>
        @{[input 'goodsNum','hidden']}
        <table class="edit-table no-border-cells" id="goods-table">
          <thead>
            <tr><th></th><th>名称</th><th>種別</th><th>戦果点</th><th>効果</th></tr>
          </thead>
          <tbody>
HTML
foreach my $num (1 .. $pc{'goodsNum'}){
  print <<"HTML";
            <tr id="goods${num}">
              <td class="handle"></td>
              <td>@{[input "goods${num}Name" ]}</td>
              <td>@{[input "goods${num}Type",'','','list="list-goods-type"' ]}</td>
              <td>@{[input "goods${num}Cost",'number','calcResultPoint' ]}</td>
              <td>@{[input "goods${num}Note" ]}</td>
            </tr>
HTML
}
  print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addGoods()">▼</a><a onclick="delGoods()">▲</a></div>
      </div>

      <div class="box" id="battle">
        <h2>戦闘値表</h2>
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
              <th colspan="2"></th>
              <th>命中値</th>
              <th>詠唱値</th>
              <th>回避値</th>
              <th>攻撃値</th>
              <th>意志値</th>
              <th>物防値</th>
              <th>魔防値</th>
              <th>行動値</th>
              <th>耐久値</th>
              <th></th>
              <th></th>
            </tr>
          </thead>
          <tbody>
              <tr>
                <th colspan="2" class="right">基本戦闘値</th>
                <td>@{[ input "battleBaseAcc", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleBaseSpl", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleBaseEva", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleBaseAtk", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleBaseDet", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleBaseDef", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleBaseMdf", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleBaseIni", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleBaseStr", 'number','calcBattle' ]}</td>
              </tr>
              <tr>
                <th>種族特性</th>
                <td>@{[ input "battleRaceName" ]}</td>
                <td>@{[ input "battleRaceAcc", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleRaceSpl", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleRaceEva", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleRaceAtk", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleRaceDet", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleRaceDef", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleRaceMdf", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleRaceIni", 'number','calcBattle' ]}</td>
                <td>@{[ input "battleRaceStr", 'number','calcBattle' ]}</td>
              </tr>
            <tr class="subtotal">
              <th colspan="2" class="right">小計</th>
              <td id="battle-subtotal-acc"></td>
              <td id="battle-subtotal-spl"></td>
              <td id="battle-subtotal-eva"></td>
              <td id="battle-subtotal-atk"></td>
              <td id="battle-subtotal-det"></td>
              <td id="battle-subtotal-def"></td>
              <td id="battle-subtotal-mdf"></td>
              <td id="battle-subtotal-ini"></td>
              <td id="battle-subtotal-str"></td>
            </tr>
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
              <th>@{[ length($th) > 3 ? "<span>$th</span>" : $th ]}</th>
              <td>@{[ input "battle${id}Name" ]}</td>
              <td>@{[ input "battle${id}Acc", 'number','calcBattle' ]}</td>
              <td>@{[ input "battle${id}Spl", 'number','calcBattle' ]}</td>
              <td>@{[ input "battle${id}Eva", 'number','calcBattle' ]}</td>
              <td>@{[ input "battle${id}Atk", 'number','calcBattle' ]}</td>
              <td>@{[ input "battle${id}Det", 'number','calcBattle' ]}</td>
              <td>@{[ input "battle${id}Def", 'number','calcBattle' ]}</td>
              <td>@{[ input "battle${id}Mdf", 'number','calcBattle' ]}</td>
              <td>@{[ input "battle${id}Ini", 'number','calcBattle' ]}</td>
              <td>@{[ input "battle${id}Str", 'number','calcBattle' ]}</td>
            </tr>
HTML
}
print <<"HTML";
            <tr>
              <th colspan="2" class="right">その他修正</th>
              <td>@{[ input "battleOtherAcc", 'number','calcBattle' ]}</td>
              <td>@{[ input "battleOtherSpl", 'number','calcBattle' ]}</td>
              <td>@{[ input "battleOtherEva", 'number','calcBattle' ]}</td>
              <td>@{[ input "battleOtherAtk", 'number','calcBattle' ]}</td>
              <td>@{[ input "battleOtherDet", 'number','calcBattle' ]}</td>
              <td>@{[ input "battleOtherDef", 'number','calcBattle' ]}</td>
              <td>@{[ input "battleOtherMdf", 'number','calcBattle' ]}</td>
              <td>@{[ input "battleOtherIni", 'number','calcBattle' ]}</td>
              <td>@{[ input "battleOtherStr", 'number','calcBattle' ]}</td>
            </tr>
            <tr>
              <th colspan="2" class="right">キャラクターレベル</th>
              <td colspan="9" id="battle-level-value"></td>
            </tr>
            <tr class="total">
              <th colspan="2" class="right">合計</th>
              <td id="battle-total-acc">0</td>
              <td id="battle-total-spl">0</td>
              <td id="battle-total-eva">0</td>
              <td id="battle-total-atk">0</td>
              <td id="battle-total-det">0</td>
              <td id="battle-total-def">0</td>
              <td id="battle-total-mdf">0</td>
              <td id="battle-total-ini">0</td>
              <td id="battle-total-str">0</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="box" id="items" $open{'items'}>
        <h2>アイテム</h2>
        @{[input 'itemsNum','hidden']}
        <table class="edit-table no-border-cells" id="items-table">
          <thead>
            <tr><th></th><th>名称</th><th>種別</th><th>レベル</th><th>戦果点</th><th>効果</th></tr>
          </thead>
          <tbody>
HTML
foreach my $num (1 .. $pc{'itemsNum'}){
  print <<"HTML";
            <tr id="item${num}">
              <td class="handle"></td>
              <td>@{[input "item${num}Name" ]}</td>
              <td>@{[input "item${num}Type",'','','list="list-item-type"' ]}</td>
              <td>@{[input "item${num}Lv"  ,'number' ]}</td>
              <td>@{[input "item${num}Cost",'number','calcResultPoint' ]}</td>
              <td>@{[input "item${num}Note" ]}</td>
            </tr>
HTML
}
  print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addItem()">▼</a><a onclick="delItem()">▲</a></div>
      </div>
      
      <details class="box" id="free-note" @{[$pc{'freeNote'}?'open':'']}>
        <summary>設定・メモ</summary>
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
              <th>戦果点</th>
              <th>GM</th>
              <th>参加者</th>
            </tr>
            <tr>
              <td>-</td>
              <td></td>
              <td>キャラクター作成</td>
              <td id="history0-exp">$pc{'history0Exp'}</td>
              <td></td>
              <td id="history0-money">$pc{'history0Money'}</td>
            </tr>
          </thead>
HTML
foreach my $num (1 .. $pc{'historyNum'}) {
print <<"HTML";
          <tbody id="history${num}">
            <tr>
              <td rowspan="2" class="handle"></td>
              <td rowspan="2">@{[input("history${num}Date")]}</td>
              <td rowspan="2">@{[input("history${num}Title")]}</td>
              <td>@{[input("history${num}Result",'text','calcResultPoint')]}</td>
              <td>@{[input("history${num}Gm")]}</td>
              <td>@{[input("history${num}Member")]}</td>
            </tr>
            <tr><td colspan="6" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}</td></tr>
          </tbody>
HTML
}
print <<"HTML";
          <tfoot>
            <tr>
              <td></td>
              <td></td>
              <td>取得総計</td>
              <td id="history-result-total"></td>
            </tr>
            <tr>
              <th></th>
              <th>日付</th>
              <th>タイトル</th>
              <th>戦果点</th>
              <th>GM</th>
              <th>参加者</th>
            </tr>
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
            <th>戦果点</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
          </thead>
          <tbody>
          <tr>
            <td>-</td>
            <td><input type="text" value="2019/07/02" disabled></td>
            <td><input type="text" value="第十四話「記入例」" disabled></td>
            <td><input type="text" value="5*14" disabled></td>
            <td><input type="text" value="サンプルさん" disabled></td>
            <td><input type="text" value="アルバート　ラミミ　ブランヘルツ　ジャ・ルマレ　ナイユベール" disabled></td>
          </tr>
          </tbody>
        </table>
        <div class="annotate">
        ※戦果点欄は<code>5*2</code>など四則演算が有効です。<br>
        </div>
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
          <label>@{[ input 'chatPalettePropertiesAll', 'checkbox']} 全ての変数を出力する</label><br>
          （デフォルトだと、未使用の変数は出力されません）
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
    'level'      : @{[ $pc{'expUsedLevel'        } || 0 ]},
    'skills'     : @{[ $pc{'expUsedGeneralSkills'} || 0 ]},
    'connections': @{[ $pc{'expUsedConnections'  } || 0 ]},
    'geises'     : @{[ $pc{'expUsedGeises'} || 0 ]},
  };
  </script>
</body>

</html>
HTML

1;