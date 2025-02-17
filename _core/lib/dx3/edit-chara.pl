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
require $set::data_syndrome;
my @awakens;
my @impulses;
push(@awakens , @$_[0]) foreach(@data::awakens);
push(@impulses, @$_[0]) foreach(@data::impulses);

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
  
  $pc{history0Exp}   = 0;
  
  ($pc{effect1Type},$pc{effect1Name},$pc{effect1Lv},$pc{effect1Timing},$pc{effect1Skill},$pc{effect1Dfclty},$pc{effect1Target},$pc{effect1Range},$pc{effect1Encroach},$pc{effect1Restrict},$pc{effect1Note})
    = ('auto','リザレクト',1,'オート','―','自動成功','自身','至近','効果参照','―','(LV)D点HP回復、侵蝕値上昇');
  ($pc{effect2Type},$pc{effect2Name},$pc{effect2Lv},$pc{effect2Timing},$pc{effect2Skill},$pc{effect2Dfclty},$pc{effect2Target},$pc{effect2Range},$pc{effect2Encroach},$pc{effect2Restrict},$pc{effect2Note})
    = ('auto','ワーディング',1,'オート','―','自動成功','シーン','視界','0','―','非オーヴァードをエキストラ化');
  
  $pc{comboNum} = 1;
  $pc{combo1Condition1} = '100%未満';
  $pc{combo1Condition2} = '100%以上';
  
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
$pc{createType} ||= 'F';

$pc{skillRideNum} ||= 2;
$pc{skillArtNum}  ||= 2;
$pc{skillKnowNum} ||= 2;
$pc{skillInfoNum} ||= 2;
$pc{effectNum}  ||= 5;
$pc{magicNum}   ||= 2;
$pc{weaponNum}  ||= 1;
$pc{armorNum}   ||= 1;
$pc{itemNum}    ||= 2;
$pc{historyNum} ||= 3;

### 折り畳み判断 --------------------------------------------------
my %open;
foreach (
  'skillMelee','skillRanged','skillRC','skillNegotiate',
  'skillDodge','skillPercept','skillWill','skillProcure',
){
  if ($pc{$_}){ $open{skill} = 'open'; last; }
}
foreach (
    'skillRide','skillArt','skillKnow','skillInfo',
){
  foreach my $num (1..$pc{$_.'Num'}){
    if ($pc{$_.$num}){ $open{skill} = 'open'; last; }
  }
}
if(existsRowStrict "lifepath",'Origin','Experience','Encounter','Awaken','Impulse'){ $open{lifepath} = 'open'; }
if(existsRowStrict "insanity",'','Note'){ $open{insanity} = 'open'; }
foreach (1..7){ if(existsRowStrict "lois$_"  ,'Relation','Name'){ $open{lois  } = 'open'; last; } }
foreach (1..3){ if(existsRowStrict "memory$_",'Relation','Name'){ $open{memory} = 'open'; last; } }
foreach (3..$pc{effectNum}){ if(existsRow "effect$_",'Name','Lv' ){ $open{effect} = 'open'; last; } }
foreach (1..$pc{magicNum }){ if(existsRow "magic$_" ,'Name','Exp'){ $open{magic } = 'open'; last; } }
foreach (1..$pc{comboNum}) { if(existsRowStrict "combo$_" ,'Name','Combo'){ $open{combo } = 'open'; last; } }
foreach (1..$pc{weaponNum  }){ if(existsRow "weapon$_"  ,'Name','Stock','Exp'){ $open{item} = 'open'; last; } }
foreach (1..$pc{armorNum   }){ if(existsRow "armor$_"   ,'Name','Stock','Exp'){ $open{item} = 'open'; last; } }
foreach (1..$pc{vehiclesNum}){ if(existsRow "vehicles$_",'Name','Stock','Exp'){ $open{item} = 'open'; last; } }
foreach (1..$pc{itemNum    }){ if(existsRow "item$_"    ,'Name','Stock','Exp'){ $open{item} = 'open'; last; } }

if(exists $data::syndrome_status{$pc{syndrome1}}){
  $pc{sttSyn1Body} = $pc{sttSyn1Sense}  = $pc{sttSyn1Mind} = $pc{sttSyn1Social} = '';
}
if(exists $data::syndrome_status{$pc{syndrome2}}){
  $pc{sttSyn2Body} = $pc{sttSyn2Sense}  = $pc{sttSyn2Mind} = $pc{sttSyn2Social} = '';
}

### 改行処理 --------------------------------------------------
$pc{words}         =~ s/&lt;br&gt;/\n/g;
$pc{freeNote}      =~ s/&lt;br&gt;/\n/g;
$pc{freeHistory}   =~ s/&lt;br&gt;/\n/g;
$pc{chatPalette}   =~ s/&lt;br&gt;/\n/g;
$pc{"combo${_}Note"}   =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{comboNum});
$pc{"weapon${_}Note"}  =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{weaponNum});
$pc{"armor${_}Note"}   =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{armorNum});
$pc{"vehicle${_}Note"} =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{vehicleNum});
$pc{"item${_}Note"}    =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{itemNum});

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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/dx3/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/dx3/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/dx3/edit-chara.js?${main::ver}" defer></script>
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
            <dt class="ruby">ふりがな
            <dd>@{[input('characterNameRuby','text',"setName")]}
          </dl>
          <dl id="aka">
            <dt>コードネーム
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
          <dt>作成方法
          <dd>@{[ radios 'createType', 'changeCreateType', 'C=>コンストラクション','F=>フルスクラッチ' ]}
          <dt>消費経験点
          <dd>@{[input("history0Exp",'number','changeRegu',($set::make_fix?' readonly':''))]} <span class="fullscratch-only">※フルスクラッチ作成時の130点は含みません。</span>
          <dt>ステージ
          <dd>@{[input("stage",'','checkStage','list="list-stage"')]}<br>
            ※ステージの入力値に「クロウリングケイオス」が“含まれる”場合、専用項目が表示されます。
          <dt>備考
          <dd>@{[ input "history0Note" ]}
        </dl>
      </details>

      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}

        <div class="box-union" id="personal">
          <dl class="box"><dt>年齢  <dd>@{[input "age"]}</dl>
          <dl class="box"><dt>性別  <dd>@{[input "gender",'','','list="list-gender"']}</dl>
          <dl class="box"><dt>星座  <dd>@{[input "sign",'','','list="list-sign"']}</dl>
          <dl class="box"><dt>身長  <dd>@{[input "height"]}</dl>
          <dl class="box"><dt>体重  <dd>@{[input "weight"]}</dl>
          <dl class="box"><dt>血液型<dd>@{[input "blood",'','','list="list-blood"']}</dl>
        </div>
        <div class="box-union" id="works-cover">
          <dl class="box"><dt>ワークス<dd>@{[input "works",'','checkWorks']}</dl>
          <dl class="box"><dt>カヴァー<dd>@{[input "cover"]}</dl>
        </div>

        <div class="box" id="syndrome-status">
          <h2 class="in-toc" data-content-title="シンドローム／能力値">シンドローム／能力値 [<span id="exp-status">0</span>]</h2>
          <table>
            <thead>
              <tr>
                <th class="breed"><span class="small">ブリード<span>
                <th>シンドローム
                <th>肉体
                <th>感覚
                <th>精神
                <th>社会
            <tbody class="syndrome-rows">
              <tr>
                <th class="breed" rowspan="3"><span id="breed-value"></span><span class="small">ブリード</span>
                <td>@{[ selectInput 'syndrome1','changeSyndrome(1,this.value)',@data::syndromes ]}
                <td><span id="stt-syn1-body"  ></span>@{[ input "sttSyn1Body"  ,'number','calcStt' ]}
                <td><span id="stt-syn1-sense" ></span>@{[ input "sttSyn1Sense" ,'number','calcStt' ]}
                <td><span id="stt-syn1-mind"  ></span>@{[ input "sttSyn1Mind"  ,'number','calcStt' ]}
                <td><span id="stt-syn1-social"></span>@{[ input "sttSyn1Social",'number','calcStt' ]}
              <tr>
                <td>@{[ selectInput 'syndrome2','changeSyndrome(2,this.value)',@data::syndromes ]}
                <td><span id="stt-syn2-body"  ></span>@{[ input "sttSyn2Body"  ,'number','calcStt' ]}
                <td><span id="stt-syn2-sense" ></span>@{[ input "sttSyn2Sense" ,'number','calcStt' ]}
                <td><span id="stt-syn2-mind"  ></span>@{[ input "sttSyn2Mind"  ,'number','calcStt' ]}
                <td><span id="stt-syn2-social"></span>@{[ input "sttSyn2Social",'number','calcStt' ]}
              <tr>
                <td>@{[ selectInput 'syndrome3','changeSyndrome(3,this.value)',@data::syndromes ]}
                <td colspan="4">
            <tbody>
              <tr class="works-row">
                <th colspan="2" class="right">ワークスによる修正
                <td>@{[ radio 'sttWorks', 'deselectable,calcStt', 'body'  , '+1' ]}
                <td>@{[ radio 'sttWorks', 'deselectable,calcStt', 'sense' , '+1' ]}
                <td>@{[ radio 'sttWorks', 'deselectable,calcStt', 'mind'  , '+1' ]}
                <td>@{[ radio 'sttWorks', 'deselectable,calcStt', 'social', '+1' ]}
              <tr>
                <th colspan="2" class="right"><span class="construction-only">フリーポイント＋</span>成長
                <td>@{[input "sttGrowBody"  ,'number','calcStt', 'min="0"']}
                <td>@{[input "sttGrowSense" ,'number','calcStt', 'min="0"']}
                <td>@{[input "sttGrowMind"  ,'number','calcStt', 'min="0"']}
                <td>@{[input "sttGrowSocial",'number','calcStt', 'min="0"']}
              <tr>
                <th colspan="2" class="right">その他の修正
                <td>@{[input "sttAddBody"  ,'number','calcStt']}
                <td>@{[input "sttAddSense" ,'number','calcStt']}
                <td>@{[input "sttAddMind"  ,'number','calcStt']}
                <td>@{[input "sttAddSocial",'number','calcStt']}
              <tr>
                <th colspan="2" class="right">合計
                <td id="stt-total-body"  >0
                <td id="stt-total-sense" >0
                <td id="stt-total-mind"  >0
                <td id="stt-total-social">0
              </tr>
            </tbody>
          </table>
        </div>
        <div class="box-union" id="sub-status">
          <dl class="box" id="max-hp">
            <dt>HP最大値
            <dd>+@{[input "maxHpAdd",'number','calcMaxHp']}=<b id="max-hp-total"></b>
          </dl>
          <dl class="box" id="stock-pt">
            <dt>常備化ポイント
            <dd>+@{[input "stockAdd",'number','calcStock']}=<b id="stock-total"></b>
          </dl>
          <dl class="box" id="saving">
            <dt>財産ポイント
            <dd>+@{[input "savingAdd",'number','calcSaving']}=<b id="saving-total"></b>
          </dl>
          <dl class="box" id="initiative">
            <dt>行動値
            <dd>+@{[input "initiativeAdd",'number','calcInitiative']}=<b id="initiative-total"></b>
          </dl>
          <dl class="box" id="move">
            <dt>戦闘移動
            <dd>+@{[input "moveAdd",'number','calcMove']}=<b id="move-total"></b>
          </dl>
          <dl class="box" id="dash">
            <dt>全力移動
            <dd><b id="dash-total"></b>
          </dl>
          <dl class="box crc-only" id="magic-dice">
            <dt>魔術ダイス
            <dd>+@{[input "magicAdd",'number','calcMagicDice']}=<b id="magic-total"></b>
          </dl>
        </div>
      </div>

      <details class="box" id="status" $open{skill}>
        <summary class="in-toc" data-content-title="技能">技能 [<span id="exp-skill">0</span>]</summary>
        @{[input 'skillRideNum','hidden']}
        @{[input 'skillArtNum' ,'hidden']}
        @{[input 'skillKnowNum','hidden']}
        @{[input 'skillInfoNum','hidden']}
        <dl id="status-table">
          <dt>肉体<dd id="skill-body"  >0
          <dt>感覚<dd id="skill-sense" >0
          <dt>精神<dd id="skill-mind"  >0
          <dt>社会<dd id="skill-social">0
        </dl>
        <dl id="skill-table">
          <dt>【肉体】を使用する技能
          <dd>
            <dl id="skill-body-table">
              <dt class="left">白兵<dd>@{[input "skillMelee"  ,'number','calcSkill', 'min="0"']}+@{[input "skillAddMelee"  ,'number','calcSkill']}
              <dt class="left">回避<dd>@{[input "skillDodge"  ,'number','calcSkill', 'min="0"']}+@{[input "skillAddDodge"  ,'number','calcSkill']}
HTML
foreach my $num (1 .. $pc{skillRideNum}) {
print <<"HTML";
              <dt>@{[input "skillRide${num}Name",'','comboSkillSetAll','list="list-ride"']}<dd>@{[input "skillRide$num",'number','calcSkill', 'min="0"']}+@{[input "skillAddRide$num",'number','calcSkill']}
HTML
}
print <<"HTML";
            </dl>
            <div class="add-del-button"><a onclick="addSkill('Ride')">▼</a><a onclick="delSkill('Ride')">▲</a></div>
          </dd>
          <dt>【感覚】を使用する技能
          <dd>
            <dl id="skill-sense-table">
              <dt class="left">射撃<dd>@{[input "skillRanged" ,'number','calcSkill', 'min="0"']}+@{[input "skillAddRanged"    ,'number','calcSkill']}
              <dt class="left">知覚<dd>@{[input "skillPercept",'number','calcSkill', 'min="0"']}+@{[input "skillAddPercept",'number','calcSkill']}
HTML
foreach my $num (1 .. $pc{skillArtNum}) {
print <<"HTML";
              <dt>@{[input "skillArt${num}Name" ,'','comboSkillSetAll','list="list-art"' ]}<dd>@{[input "skillArt$num" ,'number','calcSkill', 'min="0"']}+@{[input "skillAddArt$num" ,'number','calcSkill']}
HTML
}
print <<"HTML";
            </dl>
            <div class="add-del-button"><a onclick="addSkill('Art')">▼</a><a onclick="delSkill('Art')">▲</a></div>
          </dd>
          <dt>【精神】を使用する技能
          <dd>
            <dl id="skill-mind-table">
              <dt class="left">ＲＣ<dd>@{[input "skillRC"  ,'number','calcSkill', 'min="0"']}+@{[input "skillAddRC"  ,'number','calcSkill']}
              <dt class="left">意志<dd>@{[input "skillWill",'number','calcSkill', 'min="0"']}+@{[input "skillAddWill",'number','calcSkill']}
HTML
foreach my $num (1 .. $pc{skillKnowNum}) {
print <<"HTML";
              <dt>@{[input "skillKnow${num}Name",'','comboSkillSetAll','list="list-know"']}<dd>@{[input "skillKnow$num",'number','calcSkill', 'min="0"']}+@{[input "skillAddKnow$num",'number','calcSkill']}
HTML
}
print <<"HTML";
            </dl>
            <div class="add-del-button"><a onclick="addSkill('Know')">▼</a><a onclick="delSkill('Know')">▲</a></div>
          </dd>
          <dt>【社会】を使用する技能
          <dd>
            <dl id="skill-social-table">
              <dt class="left">交渉<dd>@{[input "skillNegotiate",'number','calcSkill', 'min="0"']}+@{[input "skillAddNegotiate",'number']}
              <dt class="left">調達<dd>@{[input "skillProcure"  ,'number','calcSkill();calcStock', 'min="0"']}+@{[input "skillAddProcure",  'number','calcSkill();calcStock']}
HTML
foreach my $num (1 .. $pc{skillInfoNum}) {
print <<"HTML";
              <dt>@{[input "skillInfo${num}Name",'','comboSkillSetAll','list="list-info"']}<dd>@{[input "skillInfo$num",'number','calcSkill', 'min="0"']}+@{[input "skillAddInfo$num",'number','calcSkill']}
HTML
}
print <<"HTML";
            </dl>
            <div class="add-del-button"><a onclick="addSkill('Info')">▼</a><a onclick="delSkill('Info')">▲</a></div>
          </dd>
        </dl>
        <ul class="annotate">
          <li>右側は、Dロイスなどによるレベル補正の欄です（経験点が計算されません）
          <li>ワークスによる技能取得ぶんとして、無入力時は<span class="fullscratch-only">消費経験点の表示が「-9」</span><span class="construction-only">技能フリーポイントの表示が「-4.5」</span>になっています。<br>
            ワークスぶんを正しく入力すると「0」点になります（一部書籍収録のワークスを除く）
        </ul>
      </details>
      <details class="box" id="lifepath" $open{lifepath}>
        <summary class="in-toc">ライフパス</summary>
        <table class="edit-table line-tbody">
          <tbody>
            <tr>
              <th>出自
              <td colspan="2">@{[input "lifepathOrigin"]}
              <td colspan="2" class="left">@{[input "lifepathOriginNote",'','','placeholder="備考"']}
          <tbody>
            <tr>
              <th>経験
              <td colspan="2">@{[input "lifepathExperience"]}
              <td colspan="2" class="left">@{[input "lifepathExperienceNote",'','','placeholder="備考"']}
          <tbody>
            <tr>
              <th id="encounter-or-desire">邂逅/欲望
              <td colspan="2">@{[input "lifepathEncounter"]}
              <td colspan="2" class="left">@{[input "lifepathEncounterNote",'','','placeholder="備考"']}
          <tbody>
            <tr>
              <th>覚醒
              <td><select name="lifepathAwaken" oninput="calcEncroach()">@{[option "lifepathAwaken",@awakens]}</select>
              <th class="small">侵蝕値
              <td class="center" id="awaken-encroach">
              <td class="left">@{[input "lifepathAwakenNote",'','','placeholder="備考"']}
          <tbody>
            <tr>
              <th rowspan="2">衝動
              <td><select name="lifepathImpulse" oninput="refreshByImpulse()">@{[option "lifepathImpulse",@impulses]}</select>
              <th class="small">侵蝕値
              <td class="center" id="impulse-encroach">
              <td class="left">@{[input "lifepathImpulseNote",'','','placeholder="備考"']}
            <tr>
              <th class="small">@{[input "lifepathUrgeCheck",'checkbox']}変異暴走
              <th class="small">効果
              <td class="left" colspan="2">@{[input "lifepathUrgeNote",'','','placeholder="効果"']}
          <tbody>
            <tr>
              <th colspan="3" class="right small">その他の修正
              <td class="center">@{[input "lifepathOtherEncroach",'number','calcEncroach']}
              <td class="left">@{[input "lifepathOtherNote",'','','placeholder="備考"']}
          <tbody>
            <tr>
              <th colspan="3" class="right">侵蝕率基本値
              <td class="center bold" id="base-encroach">
          </tbody>
        </table>
      </details>
      <div id="enc-bonus" style="position: relative;">
        <div class="box">
          <h2 class="in-toc">侵蝕率効果表</h2>
          <p>
            <!-- 現在侵蝕率:@{[ input 'currentEncroach','number','encroachBonusSet(this.value)','style="width: 4em;"' ]} -->
            @{[ checkbox 'encroachEaOn','エフェクトアーカイブ適用','encroachBonusType' ]}
          </p>
          <table class="data-table" id="enc-table">
            <colgroup></colgroup>
            <tr id="enc-table-head">
            <tr id="enc-table-dices">
            <tr id="enc-table-level">
          </table>
        </div>
      </div>
      <details class="box" id="lois" $open{lois} style="position:relative">
        <summary class="in-toc">ロイス</summary>
        <div>
          <table class="edit-table no-border-cells" id="lois-table">
            <colgroup>
            <col class="relation">
            <col class="name">
            <col class="emo">
            <col class="slash">
            <col class="emo">
            <col class="color">
            <col class="note">
            <col class="sperior">
            <col class="state">
            </colgroup>
            <thead>
              <tr>
                <th>関係
                <th>名前
                <th colspan="3">感情<span class="small">(Positive／Negative)</span>
                <th>属性
                <th colspan="2" class="right small">Sロイス
                <th class="right">状態
              </tr>
            <tbody>
HTML
foreach my $num (1 .. 7) {
if(!$pc{"lois${num}State"}){ $pc{"lois${num}State"} = 'ロイス' }
print <<"HTML";
              <tr id="lois${num}">
                <td class="relation"><span class="handle"></span>@{[input "lois${num}Relation",'','','list="list-lois-relation"']}
                <td class="name    ">@{[input "lois${num}Name",'','encroachBonusType']}
                <td class="emo     ">@{[input "lois${num}EmoPosiCheck",'checkbox',"emoP($num)"]}@{[input "lois${num}EmoPosi",'','','list="list-emotionP"']}
                <td class="slash   ">／
                <td class="emo     ">@{[input "lois${num}EmoNegaCheck",'checkbox',"emoN($num)"]}@{[input "lois${num}EmoNega",'','','list="list-emotionN"']}
                <td class="color   ">@{[input "lois${num}Color",'',"changeLoisColor($num)",'list="list-lois-color"']}
                <td class="note    ">@{[input "lois${num}Note"]}
                <td class="sperior ">@{[input "lois${num}S",'checkbox',"sLois($num)"]}
                <td class="state   " onclick="changeLoisState(this.parentNode.id)"><span id="lois${num}-state" data-state="$pc{"lois${num}State"}"></span>@{[input "lois${num}State",'hidden']}
HTML
}
print <<"HTML";
            </tbody>
          </table>
        </div>
        <div class="right lois-reset-buttons">
          <button type="button" class="small" onclick="resetLoisAll()">全ロイスをリセット</button>
          <button type="button" class="small" onclick="resetLoisAdd()">4番目以降をリセット</button>
        </div>
      </details>
      <details class="box" id="memory" $open{memory}>
        <summary class="in-toc" data-content-title="メモリー">メモリー [<span id="exp-memory">0</span>]</summary>
        <div>
          <table class="edit-table no-border-cells" id="memory-table">
            <thead>
              <tr>
                <th>
                <th>関係
                <th>名前
                <th>感情
                <th>
              </tr>
            <tbody>
HTML
foreach my $num (1 .. 3) {
print <<"HTML";
            <tr id="memory${num}">
              <td><span class="handle"></span>
              <td>@{[input "memory${num}Relation",'','calcMemory']}
              <td>@{[input "memory${num}Name",'','calcMemory']}
              <td>@{[input "memory${num}Emo"]}
              <td>@{[input "memory${num}Note"]}
HTML
}
print <<"HTML";
            </tbody>
          </table>
        </div>
        <ul class="annotate"><li>「関係」か「名前」を入力すると経験点が計算されます。</ul>
      </details>
      <details class="box crc-only" id="insanity" $open{insanity}>
        <summary class="in-toc">永続的狂気</summary>
        <dl class="edit-table " id="insanity-table">
          <dt>@{[input "insanity",'','','placeholder="名称"']}
          <dd>@{[input "insanityNote",'','','placeholder="効果"']}
        </dl>
      </details>

      <details class="box" id="effect" $open{effect}>
        <summary class="in-toc" data-content-title="エフェクト">エフェクト [<span id="exp-effect">0</span>]</summary>
        <div>
          <table class="edit-table line-tbody no-border-cells" id="effect-table">
            <thead id="effect-head">
              <tr><th><th>名称<th>LV<th>タイミング<th>技能<th>難易度<th>対象<th>射程<th>侵蝕値<th>制限
HTML
foreach my $num ('TMPL',1 .. $pc{effectNum}) {
  if($num eq 'TMPL'){ print '<template id="effect-template">' }
print <<"HTML";
          <tbody id="effect-row${num}">
            <tr>
              <td rowspan="2" class="handle"> 
              <td>@{[input "effect${num}Name",'','','placeholder="名称"']}
              <td>@{[input "effect${num}Lv",'number','calcEffect','placeholder="Lv" min="0"']}
              <td>@{[input "effect${num}Timing",'','','placeholder="タイミング" list="list-timing"']}
              <td>@{[input "effect${num}Skill",'','','placeholder="技能" list="list-effect-skill"']}
              <td>@{[input "effect${num}Dfclty",'','','placeholder="難易度" list="list-dfclty"']}
              <td>@{[input "effect${num}Target",'','','placeholder="対象" list="list-target"']}
              <td>@{[input "effect${num}Range",'','','placeholder="射程" list="list-range"']}
              <td>@{[input "effect${num}Encroach",'','','placeholder="侵蝕値" list="list-encroach"']}
              <td>@{[input "effect${num}Restrict",'','','placeholder="制限" list="list-restrict"']}
            <tr><td colspan="9">
              <div>
                <b>種別</b><select name="effect${num}Type" oninput="calcEffect()">@{[ option "effect${num}Type",'auto|<自動取得>','dlois|<Dロイス>','easy|<イージー>','enemy|<エネミー>' ]}</select>
                <b class="small">経験点修正</b>@{[input "effect${num}Exp",'number','calcEffect']}
                <b>効果</b>@{[input "effect${num}Note"]}
              </div>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            <tfoot id="effect-foot">
              <tr><th><th>名称<th>LV<th>タイミング<th>技能<th>難易度<th>対象<th>射程<th>侵蝕値<th>制限
          </table>
        </div>
        <div class="add-del-button"><a onclick="addEffect()">▼</a><a onclick="delEffect()">▲</a></div>
        @{[input 'effectNum','hidden']}
        <ul class="annotate">
          <li>種別「自動」「Dロイス」を選択した場合、取得時（1レベル）の経験点を0として計算します。
          <li>経験点修正の欄は、自動計算で対応しきれない例外的な取得・成長に使用してください（Dロイス転生者など）
        </ul>
      </details>
      <div class="box trash-box" id="effect-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除エフェクト</span></h2>
        <table class="edit-table line-tbody" id="effect-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('effect-trash').style.display = 'none';">close</i>
      </div>

      <details class="box crc-only" id="magic" $open{magic}>
        <summary class="in-toc" data-content-title="術式">術式 [<span id="exp-magic">0</span>]</summary>
        @{[input 'magicNum','hidden']}
        <div>
          <table class="edit-table line-tbody no-border-cells" id="magic-table">
            <thead id="magic-head">
              <tr><th><th>名称<th>種別<th>経験点<th>発動値<th>侵蝕値<th>効果
HTML
foreach my $num ('TMPL',1 .. $pc{magicNum}) {
  if($num eq 'TMPL'){ print '<template id="magic-template">' }
  print <<"HTML";
            <tbody id="magic-row${num}">
              <tr>
                <td class="handle"> 
                <td>@{[input "magic${num}Name"    ,'','','placeholder="名称"']}
                <td>@{[input "magic${num}Type"    ,'','','placeholder="種別" list="list-magic-type"']}
                <td>@{[input "magic${num}Exp"     ,'number','calcMagic']}
                <td>@{[input "magic${num}Activate",'','','placeholder="発動値"']}
                <td>@{[input "magic${num}Encroach",'','','placeholder="侵蝕値"']}
                <td>@{[input "magic${num}Note"    ,'','','placeholder="効果"']}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          </table>
        </div>
        <div class="add-del-button"><a onclick="addMagic()">▼</a><a onclick="delMagic()">▲</a></div>
      </details>
      <div class="box trash-box" id="magic-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除術式</span></h2>
        <table class="edit-table line-tbody" id="magic-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('magic-trash').style.display = 'none';">close</i>
      </div>
      
      <details class="box" id="combo" $open{combo} style="position:relative">
        <summary class="in-toc">コンボ</summary>
        @{[input 'comboNum','hidden']}
        <div id="combo-list">
HTML
sub comboSkillSet {
  my $num = shift;
  my @skills = ('白兵','射撃','RC','交渉','回避','知覚','意志','調達');
  foreach my $id ('Ride','Art','Know','Info'){
    foreach my $num (1 .. $pc{'skill'.$id.'Num'}){
      push(@skills, $pc{'skill'.$id.$num.'Name'}) if $pc{'skill'.$id.$num.'Name'};
    }
  }
  push(@skills, '解説参照');
  unshift(@skills, '―');
  my $output = '<option value="">';
  foreach my $skillname (@skills){
    $output .= '<option'
            . ($pc{"combo${num}Skill"} eq $skillname ? ' selected' : '')
            . '>'.$skillname;
  }
  return $output;
}
sub comboStatusSet {
  my $num = shift;
  my @status = ('肉体','感覚','精神','社会');
  my $output = '<option value="">自動（技能に合った能力値）';
  $output .= '<optgroup label="▼エフェクト等による差し替え">';
  foreach my $statusname (@status){
    $output .= '<option'
            . ($pc{"combo${num}Stt"} eq $statusname ? ' selected' : '')
            . '>'.$statusname;
  }
  $output .= '</optgroup>';
  return $output;
}
foreach my $num ('TMPL',1 .. $pc{comboNum}) {
  if($num eq 'TMPL'){ print '<template id="combo-template">' }
print <<"HTML";
        <div class="combo-table" id="combo-row${num}">
          <div class="handle"></div>
          <dl class="combo-name"><dt>名称</dt><dd>@{[input "combo${num}Name"]}</dd></dl>
          <dl class="combo-combo"><dt>組み合わせ</dt><dd>@{[input "combo${num}Combo"]}</dl>
          <div class="combo-in">
            <dl><dt>タイミング<dd>@{[input "combo${num}Timing",'','','list="list-combo-timing"']}</dl>
            <dl><dt>技能      <dd><select name="combo${num}Skill" oninput="calcCombo(${num})">@{[ comboSkillSet($num) ]}</select></dl>
            <dl><dt>能力値    <dd><select name="combo${num}Stt" oninput="calcCombo(${num})">@{[ comboStatusSet($num) ]}</select></dl>
            <dl><dt>難易度    <dd>@{[input "combo${num}Dfclty",'','','list="list-dfclty"']}</dl>
            <dl><dt>対象      <dd>@{[input "combo${num}Target",'','','list="list-target"']}</dl>
            <dl><dt>射程      <dd>@{[input "combo${num}Range",'','','list="list-range"']}</dl>
            <dl><dt>侵蝕値    <dd>@{[input "combo${num}Encroach"]}</dl>
          </div>
          <dl class="combo-out">
            <dt class="combo-cond">条件<span class="combo-condition-utility"></span>
            <dt class="combo-dice">ダイス
            <dt class="combo-crit">Ｃ値
            <dt class="combo-fixed">達成値修正<br><span class="very-small">(技能レベル+修正値)</span>
            <dt class="combo-atk">攻撃力
HTML
  foreach my $i (1 .. 5) {
  print <<"HTML";
            <dd>@{[input "combo${num}Condition${i}"]}
            <dd id="combo${num}Stt${i}"></dd>
            <dd>@{[input "combo${num}DiceAdd${i}"]}
            <dd>@{[input "combo${num}Crit${i}"]}
            <dd id="combo${num}SkillLv${i}"></dd>
            <dd>@{[input "combo${num}FixedAdd${i}"]}
            <dd>@{[input "combo${num}Atk${i}"]}
HTML
  }
print <<"HTML";
          </dl>
          <div class="combo-note"><textarea name="combo${num}Note" rows="3" placeholder="解説">$pc{"combo${num}Note"}</textarea></div>
          <div class="combo-other">@{[ checkbox "combo${num}Manual",'技能レベル・能力値を自動挿入しない',"calcCombo(${num})" ]} <span class="button" onclick="addCombo($num)">コンボ複製</span></div>
        </div>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </div>
        <div class="add-del-button"><a onclick="addCombo()">▼</a><a onclick="delCombo()">▲</a></div>
      </details>
      
      <details class="box box-union" id="items" $open{item}>
      <summary class="in-toc" data-content-title="アイテム">アイテム [<span id="exp-item">0</span>]</summary>
      <div class="box">
        @{[input 'weaponNum','hidden']}
        <table class="edit-table no-border-cells" id="weapon-table">
          <thead>
            <tr><th>武器<th>常備化<th>経験点<th>種別<th>技能<th>命中<th>攻撃力<th><span class="small">ガード値</span><th>射程<th>解説
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{weaponNum}) {
  if($num eq 'TMPL'){ print '<template id="weapon-template">' }
print <<"HTML";
            <tr id="weapon-row${num}">
              <td>@{[input "weapon${num}Name"]}<span class="handle"></span>
              <td>@{[input "weapon${num}Stock",'number','calcItem', 'min="0"']}
              <td>@{[input "weapon${num}Exp",'number','calcItem', 'min="0"']}
              <td>@{[input "weapon${num}Type",'','','list="list-weapon-type"']}
              <td>@{[input "weapon${num}Skill",'','','list="list-weapon-skill"']}
              <td>@{[input "weapon${num}Acc"]}
              <td>@{[input "weapon${num}Atk"]}
              <td>@{[input "weapon${num}Guard"]}
              <td>@{[input "weapon${num}Range"]}
              <td><textarea name="weapon${num}Note" rows="2">$pc{"weapon${num}Note"}</textarea>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addWeapon()">▼</a><a onclick="delWeapon()">▲</a></div>
      </div>
      <div class="box">
        @{[input 'armorNum','hidden']}
        <table class="edit-table no-border-cells" id="armor-table">
          <thead>
            <tr><th>防具<th>常備化<th>経験点<th>種別<th><th>行動<th>ドッジ<th>装甲値<th>解説
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{armorNum}) {
  if($num eq 'TMPL'){ print '<template id="armor-template">' }
print <<"HTML";
            <tr id="armor-row${num}">
              <td>@{[input "armor${num}Name"]}<span class="handle"></span>
              <td>@{[input "armor${num}Stock",'number','calcItem', 'min="0"']}
              <td>@{[input "armor${num}Exp",'number','calcItem', 'min="0"']}
              <td>@{[input "armor${num}Type",'','','list="list-armor-type"']}
              <td>
              <td>@{[input "armor${num}Initiative"]}
              <td>@{[input "armor${num}Dodge"]}
              <td>@{[input "armor${num}Armor"]}
              <td><textarea name="armor${num}Note" rows="2">$pc{"armor${num}Note"}</textarea>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addArmor()">▼</a><a onclick="delArmor()">▲</a></div>
      </div>
      <div class="box">
        @{[input 'vehicleNum','hidden']}
        <table class="edit-table no-border-cells" id="vehicle-table">
          <thead>
            <tr><th>ヴィークル<th>常備化<th>経験点<th>種別<th>技能<th>行動<th>攻撃力<th>装甲値<th><span class="small">全力移動</span><th>解説
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{vehicleNum}) {
  if($num eq 'TMPL'){ print '<template id="vehicle-template">' }
print <<"HTML";
            <tr id="vehicle-row${num}">
              <td>@{[input "vehicle${num}Name"]}<span class="handle"></span>
              <td>@{[input "vehicle${num}Stock",'number','calcItem', 'min="0"']}
              <td>@{[input "vehicle${num}Exp",'number','calcItem', 'min="0"']}
              <td>@{[input "vehicle${num}Type",'','','list="list-vehicle-type"']}
              <td>@{[input "vehicle${num}Skill",'','','list="list-vehicle-skill"']}
              <td>@{[input "vehicle${num}Initiative"]}
              <td>@{[input "vehicle${num}Atk"]}
              <td>@{[input "vehicle${num}Armor"]}
              <td>@{[input "vehicle${num}Dash"]}
              <td><textarea name="vehicle${num}Note" rows="2">$pc{"vehicle${num}Note"}</textarea>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addVehicle()">▼</a><a onclick="delVehicle()">▲</a></div>
      </div>
      <div class="box">
        @{[input 'itemNum','hidden']}
        <table class="edit-table no-border-cells" id="item-table">
          <thead>
            <tr><th>一般アイテム<th>常備化<th>経験点<th>種別<th>技能<th>解説
          <tbody>
HTML
foreach my $num ('TMPL',1 .. $pc{itemNum}) {
  if($num eq 'TMPL'){ print '<template id="item-template">' }
print <<"HTML";
            <tr id="item-row${num}">
              <td>@{[input "item${num}Name"]}<span class="handle"></span>
              <td>@{[input "item${num}Stock",'number','calcItem', 'min="0"']}
              <td>@{[input "item${num}Exp",'number','calcItem', 'min="0"']}
              <td>@{[input "item${num}Type",'','','list="list-item-type"']}
              <td>@{[input "item${num}Skill",'','','list="list-item-skill"']}
              <td><textarea name="item${num}Note" rows="2">$pc{"item${num}Note"}</textarea>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addItem()">▼</a><a onclick="delItem()">▲</a></div>
      </div>
      <div class="box">
        <table class="edit-table">
          <thead><tr><th><th>常備化<th>経験点<th>
          <tbody>
            <tr>
              <th>合計
              <td><b id="item-total-stock">0</b><wbr>/<b id="item-max-stock">0</b>
              <td class="bold" id="item-total-exp">0
              <td>
            </tr>
          </tbody>
        </table>
      </div>
      </details>
      
      
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
          <colgroup id="history-col">
            <col>
            <col class="date  ">
            <col class="title ">
            <col class="exp   ">
            <col class="apply ">
            <col class="gm    ">
            <col class="member">
          </colgroup>
          <thead id="history-head">
            <tr>
              <th>
              <th>日付
              <th>タイトル
              <th colspan="2">経験点
              <th>GM
              <th>参加者
            <tr>
              <td>-
              <td>
              <td>キャラクター作成
              <td id="history0-exp">$pc{history0Exp}
              <td><input type="checkbox" checked disabled>適用
HTML
foreach my $num ('TMPL',1 .. $pc{historyNum}) {
  if($num eq 'TMPL'){ print '<template id="history-template">' }
print <<"HTML";
          <tbody id="history-row${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td class="date  " rowspan="2">@{[input "history${num}Date" ]}
              <td class="title " rowspan="2">@{[input "history${num}Title" ]}
              <td class="exp   ">@{[ input "history${num}Exp",'text','calcExp' ]}
              <td class="apply "><label>@{[ input "history${num}ExpApply",'checkbox','calcExp' ]}<b>適用</b></label>
              <td class="gm    ">@{[ input "history${num}Gm" ]}
              <td class="member">@{[ input "history${num}Member" ]}
            <tr>
              <td colspan="4" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          <tfoot id="history-foot">
            <tr><th></th><th>日付</th><th>タイトル</th><th colspan="2">経験点</th><th>GM</th><th>参加者</th></tr>
        </table>
        <div class="add-del-button"><a onclick="addHistory()">▼</a><a onclick="delHistory()">▲</a></div>
        <h2>記入例</h2>
        <table class="example edit-table line-tbody no-border-cells">
          <colgroup>
            <col>
            <col class="date  ">
            <col class="title ">
            <col class="exp   ">
            <col class="apply ">
            <col class="gm    ">
            <col class="member">
          </colgroup>
          <thead>
            <tr>
              <th>
              <th>日付
              <th>タイトル
              <th colspan="2">経験点
              <th>GM
              <th>参加者
            </tr>
          <tbody>
            <tr>
              <td>-
              <td><input type="text" value="2020-03-18" disabled>
              <td><input type="text" value="第一話「記入例」" disabled>
              <td><input type="text" value="10+5+1" disabled>
              <td><label><input type="checkbox" checked disabled><b>適用</b></label>
              <td class="gm"><input type="text" value="サンプルGM" disabled>
              <td class="member"><input type="text" value="荒川ヨドミ　鎧畑ショウコ　橘シドウ　金床スズ" disabled>
            </tr>
          </tbody>
        </table>
        <ul class="annotate">
          <li>経験点欄は<code>10+5+1</code>など四則演算が有効です（獲得条件の違う経験点などを分けて書けます）。<br>
            経験点欄の右の適用チェックを入れると、その経験点が適用されます。
        </ul>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
      </div>
      
      <div class="box" id="exp-footer">
        <p class="construction-only">
          <b>コンストラクション作成</b>
          :  能力値フリーポイント[<b id="freepoint-status"></b>/3]
          ／ 技能フリーポイント[<b id="freepoint-skill"></b>/5]
          ／ 任意エフェクト[<b id="freepoint-effect"></b>/4]個
          ／ エフェクトレベルフリーポイント[<b id="freepoint-effectlv"></b>/2]
        </p>
        <p>
        経験点[<b id="exp-total"></b>] - 
        ( 能力値[<b id="exp-used-status"></b>]
        + 技能[<b id="exp-used-skill"></b>]
        + エフェクト[<b id="exp-used-effect"></b>]
        <span class="crc-only">+ 術式[<b id="exp-used-magic"></b>]</span>
        + アイテム[<b id="exp-used-item"></b>]
        + メモリー[<b id="exp-used-memory"></b>]
        ) = 残り[<b id="exp-rest"></b>]点
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
print textRuleArea( '','「容姿・経歴・その他メモ」「履歴（自由記入）」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">©FarEast Amusement Research Co.,Ltd.「ダブルクロスThe 3rd Edition」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
  </footer>
  <datalist id="list-stage">
    <option value="基本ステージ">
    <option value="基本ステージ(UA)">
    <option value="オーヴァードアカデミア">
    <option value="ナイトメアプリズン">
    <option value="デモンズシティ">
    <option value="陽炎の戦場">
    <option value="エンドライン">
    <option value="ホーリーグレイル">
    <option value="平安京物怪録">
    <option value="モダンタイムス">
    <option value="エピックヒーローズ">
    <option value="クロノスガーディアン">
    <option value="レネゲイドウォー">
    <option value="バッドシティ">
    <option value="ウィアードエイジ">
    <option value="カオスガーデン">
    <option value="クロウリングケイオス">
  </datalist>
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="その他">
    <option value="なし">
    <option value="不明">
    <option value="不詳">
  </datalist>
  <datalist id="list-sign">
    <option value="牡羊座">
    <option value="牡牛座">
    <option value="双子座">
    <option value="蟹座">
    <option value="獅子座">
    <option value="乙女座">
    <option value="天秤座">
    <option value="蠍座">
    <option value="射手座">
    <option value="山羊座">
    <option value="水瓶座">
    <option value="魚座">
    <option value="不明">
    <option value="不詳">
  </datalist>
  <datalist id="list-blood">
    <option value="A型"><option value="B型"><option value="AB型"><option value="O型"><option value="不明"><option value="不詳">
  </datalist>
  <datalist id="list-lois-relation">
    <option value="Dロイス">
    <option value="Eロイス">
  </datalist>
  <datalist id="list-emotionP">
    <option value="傾倒">
    <option value="好奇心">
    <option value="憧憬">
    <option value="尊敬">
    <option value="連帯感">
    <option value="慈愛">
    <option value="感服">
    <option value="純愛">
    <option value="友情">
    <option value="慕情">
    <option value="同情">
    <option value="遺志">
    <option value="庇護">
    <option value="幸福感">
    <option value="信頼">
    <option value="執着">
    <option value="親近感">
    <option value="誠意">
    <option value="好意">
    <option value="有為">
    <option value="尽力">
    <option value="懐旧">
  </datalist>
  <datalist id="list-emotionN">
    <option value="侮蔑">
    <option value="食傷">
    <option value="脅威">
    <option value="嫉妬">
    <option value="悔悟">
    <option value="恐怖">
    <option value="不安">
    <option value="劣等感">
    <option value="疎外感">
    <option value="恥辱">
    <option value="憐憫">
    <option value="偏愛">
    <option value="憎悪">
    <option value="隔意">
    <option value="嫌悪">
    <option value="猜疑心">
    <option value="厭気">
    <option value="不信感">
    <option value="不快感">
    <option value="憤懣">
    <option value="敵愾心">
    <option value="無関心">
  </datalist>
  <datalist id="list-ride">
    <option value="運転:">
    <option value="運転:二輪">
    <option value="運転:四輪">
    <option value="運転:船舶">
    <option value="運転:航空機">
    <option value="運転:馬">
    <option value="運転:多脚戦車">
    <option value="運転:宇宙船">
  </datalist>
  <datalist id="list-art" >
    <option value="芸術:">
    <option value="芸術:音楽">
    <option value="芸術:歌唱">
    <option value="芸術:演技">
    <option value="芸術:絵画">
    <option value="芸術:写真">
    <option value="芸術:彫刻">
    <option value="芸術:ゲーム">
  </datalist>
  <datalist id="list-know">
    <option value="知識:">
    <option value="知識:レネゲイド">
    <option value="知識:医療">
    <option value="知識:心理">
    <option value="知識:機械工学">
    <option value="知識:機械操作">
    <option value="知識:オカルト">
    <option value="知識:遺産">
  </datalist>
  <datalist id="list-info">
    <option value="情報:">
    <option value="情報:UGN">
    <option value="情報:FH">
    <option value="情報:ゼノス">
    <option value="情報:噂話">
    <option value="情報:裏社会">
    <option value="情報:警察">
    <option value="情報:軍事">
    <option value="情報:学問">
    <option value="情報:ウェブ">
    <option value="情報:メディア">
    <option value="情報:ビジネス">
  </datalist>
  <datalist id="list-lois-color">
    <option value="BK">ブラック
    <option value="BL">ブルー
    <option value="GR">グリーン
    <option value="OR">オレンジ
    <option value="PU">パープル
    <option value="RE">レッド
    <option value="WH">ホワイト
    <option value="YE">イエロー
  </datalist>
  <datalist id="list-timing">
    <option value="オート">
    <option value="マイナー">
    <option value="メジャー">
    <option value="メジャー／リア">
    <option value="リアクション">
    <option value="セットアップ">
    <option value="イニシアチブ">
    <option value="クリンナップ">
    <option value="常時">
    <option value="効果参照">
  </datalist>
  <datalist id="list-effect-skill">
    <option value="―">
    <option value="シンドローム">
    <option value="〈白兵〉">
    <option value="〈射撃〉">
    <option value="〈RC〉">
    <option value="〈交渉〉">
    <option value="〈白兵〉〈射撃〉">
    <option value="〈白兵〉〈RC〉">
    <option value="〈回避〉">
    <option value="〈知覚〉">
    <option value="〈意志〉">
    <option value="〈調達〉">
    <option value="【肉体】">
    <option value="【感覚】">
    <option value="【精神】">
    <option value="【社会】">
    <option value="〈運転:〉">
    <option value="〈芸術:〉">
    <option value="〈知識:〉">
    <option value="〈情報:〉">
    <option value="効果参照">
  </datalist>
  <datalist id="list-combo-timing">
    <option value="オート">
    <option value="マイナー">
    <option value="メジャー">
    <option value="リアクション">
    <option value="セットアップ">
    <option value="イニシアチブ">
    <option value="クリンナップ">
    <option value="常時">
    <option value="効果参照">
  </datalist>
  <datalist id="list-combo-skill">
    <option value="―">
    <option value="〈白兵〉">
    <option value="〈射撃〉">
    <option value="〈RC〉">
    <option value="〈交渉〉">
    <option value="〈白兵〉〈射撃〉">
    <option value="〈白兵〉〈RC〉">
    <option value="〈回避〉">
    <option value="〈知覚〉">
    <option value="〈意志〉">
    <option value="〈調達〉">
    <option value="【肉体】">
    <option value="【感覚】">
    <option value="【精神】">
    <option value="【社会】">
    <option value="〈運転:〉">
    <option value="〈芸術:〉">
    <option value="〈知識:〉">
    <option value="〈情報:〉">
    <option value="効果参照">
  </datalist>
  <datalist id="list-weapon-skill">
    <option value="―">
    <option value="〈白兵〉">
    <option value="〈射撃〉">
    <option value="〈白兵〉〈射撃〉">
    <option value="〈交渉〉">
    <option value="〈知識:機械工学〉">
    <option value="解説参照">
  </datalist>
  <datalist id="list-vehicle-skill">
    <option value="〈運転:〉">
    <option value="〈運転:二輪〉">
    <option value="〈運転:四輪〉">
    <option value="〈運転:船舶〉">
    <option value="〈運転:航空機〉">
    <option value="〈運転:馬〉">
    <option value="〈運転:多脚戦車〉">
    <option value="〈運転:宇宙船〉">
  </datalist>
  <datalist id="list-item-skill">
    <option value="―">
    <option value="〈調達〉">
    <option value="〈知識:〉">
    <option value="〈情報:〉">
    <option value="〈情報:UGN〉">
    <option value="〈情報:FH〉">
    <option value="〈情報:ゼノス〉">
    <option value="〈情報:噂話〉">
    <option value="〈情報:裏社会〉">
    <option value="〈情報:警察〉">
    <option value="〈情報:軍事〉">
    <option value="〈情報:学問〉">
    <option value="〈情報:ウェブ〉">
    <option value="〈情報:メディア〉">
    <option value="〈情報:ビジネス〉">
    <option value="解説参照">
  </datalist>
  <datalist id="list-weapon-type">
    <option value="白兵">
    <option value="射撃">
    <option value="白兵／射撃">
    <option value="エンブレム／白兵">
    <option value="エンブレム／射撃">
    <option value="リレーション／白兵">
    <option value="リレーション／射撃">
  </datalist>
  <datalist id="list-armor-type">
    <option value="防具">
    <option value="防具※">
    <option value="防具（補助）">
    <option value="エンブレム／防具">
    <option value="エンブレム／防具（補助）">
    <option value="リレーション／防具">
  </datalist>
  <datalist id="list-vehicle-type">
    <option value="ヴィークル">
    <option value="エンブレム／ヴィークル">
  </datalist>
  <datalist id="list-item-type">
    <option value="コネ">
    <option value="一般">
    <option value="その他">
    <option value="使い捨て">
    <option value="エンブレム／コネ">
    <option value="エンブレム／一般">
    <option value="エンブレム／その他">
    <option value="エンブレム／使い捨て">
    <option value="リレーション／コネ">
    <option value="リレーション／一般">
    <option value="リレーション／その他">
    <option value="リレーション／使い捨て">
  </datalist>
  <datalist id="list-dfclty">
    <option value="―">
    <option value="自動成功">
    <option value="対決">
    <option value="効果参照">
  </datalist>
  <datalist id="list-target">
    <option value="―">
    <option value="自身">
    <option value="単体">
    <option value="3体">
    <option value="[LV+1]体">
    <option value="範囲">
    <option value="範囲（選択）">
    <option value="シーン">
    <option value="シーン（選択）">
    <option value="効果参照">
  </datalist>
  <datalist id="list-range">
    <option value="―">
    <option value="至近">
    <option value="武器">
    <option value="視界">
    <option value="効果参照">
  </datalist>
  <datalist id="list-encroach">
    <option value="―">
    <option value="1">
    <option value="2">
    <option value="3">
    <option value="4">
    <option value="5">
    <option value="6">
    <option value="7">
    <option value="8">
    <option value="10">
    <option value="20">
    <option value="1D10">
    <option value="2D10">
    <option value="4D10">
    <option value="効果参照">
  </datalist>
  <datalist id="list-restrict">
    <option value="―">
    <option value="ピュア">
    <option value="80%">
    <option value="100%">
    <option value="120%" class="percent120">
    <option value="Dロイス">
    <option value="リミット">
    <option value="RB">
    <option value="従者専用">
  </datalist>
  <datalist id="list-magic-type">
    <option value="通常">
    <option value="通常／維持">
    <option value="印形">
    <option value="儀式">
    <option value="儀式／維持">
    <option value="儀式／呪詛">
    <option value="儀式／召喚">
    <option value="召喚">
    <option value="喚起">
    <option value="喚起／儀式">
  </datalist>
  <script>
HTML
print 'const makeExp = '.$set::make_exp.';';
print 'const synStats = {';
foreach (keys %data::syndrome_status) {
  next if !$_;
  my @ar = @{$data::syndrome_status{$_}};
  print '"'.$_.'":{"body":'.$ar[0].',"sense":'.$ar[1].',"mind":'.$ar[2].',"social":'.$ar[3].'},'
}
print "};\n";
print 'const awakens = {';
foreach (@data::awakens) {
  next if (@$_[0] =~ /^label=/);
  print '"'.@$_[0].'":'.@$_[1].','
}
print "};\n";
print 'const impulses = {';
foreach (@data::impulses) {
  print '"'.@$_[0].'":'.@$_[1].','
}
print "};\n";
print <<"HTML";
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;
