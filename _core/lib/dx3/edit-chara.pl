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
  
  $pc{'history0Exp'}   = $set::make_exp;
  
  ($pc{'effect1Type'},$pc{'effect1Name'},$pc{'effect1Lv'},$pc{'effect1Timing'},$pc{'effect1Skill'},$pc{'effect1Dfclty'},$pc{'effect1Target'},$pc{'effect1Range'},$pc{'effect1Encroach'},$pc{'effect1Restrict'},$pc{'effect1Note'})
    = ('auto','リザレクト',1,'オート','―','自動成功','自身','至近','効果参照','―','(Lv)D点HP回復、侵蝕値上昇');
  ($pc{'effect2Type'},$pc{'effect2Name'},$pc{'effect2Lv'},$pc{'effect2Timing'},$pc{'effect2Skill'},$pc{'effect2Dfclty'},$pc{'effect2Target'},$pc{'effect2Range'},$pc{'effect2Encroach'},$pc{'effect2Restrict'},$pc{'effect2Note'})
    = ('auto','ワーディング',1,'オート','―','自動成功','シーン','視界','0','―','非オーヴァードをエキストラ化');
  
  $pc{'comboNum'} = 1;
  $pc{'combo1Condition1'} = '100%未満';
  $pc{'combo1Condition2'} = '100%以上';
  
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
$pc{'skillRideNum'} ||= 2;
$pc{'skillArtNum'}  ||= 2;
$pc{'skillKnowNum'} ||= 2;
$pc{'skillInfoNum'} ||= 2;
$pc{'effectNum'}  ||= 5;
$pc{'magicNum'}   ||= 2;
$pc{'weaponNum'}  ||= 1;
$pc{'armorNum'}   ||= 1;
$pc{'itemNum'}    ||= 2;
$pc{'historyNum'} ||= 3;

### 折り畳み判断 --------------------------------------------------
my %open;
foreach (
  'skillMelee','skillRanged','skillRC','skillNegotiate',
  'skillDodge','skillPercept','skillWill','skillProcure',
){
  if ($pc{$_}){ $open{'skill'} = 'open'; last; }
}
foreach (
    'skillRide','skillArt','skillKnow','skillInfo',
){
  foreach my $num (1..$pc{$_.'Num'}){
    if ($pc{$_.$num}){ $open{'skill'} = 'open'; last; }
  }
}
if  ($pc{"lifepathOrigin"}
  || $pc{"lifepathExperience"}
  || $pc{"lifepathEncounter"}
  || $pc{"lifepathAwaken"}
  || $pc{"lifepathImpulse"}  ){ $open{'lifepath'} = 'open'; }
if  ($pc{"insanity"}
  || $pc{"insanityNote"}){ $open{'insanity'} = 'open'; }
foreach (1..7){ if($pc{"lois${_}Relation"} || $pc{"lois${_}Name"}  ){ $open{'lois'}   = 'open'; last; } }
foreach (1..3){ if($pc{"memory${_}Gain"}   || $pc{"memory${_}Name"}){ $open{'memory'} = 'open'; last; } }
foreach (1..$pc{'comboNum'}) { if($pc{"combo${_}Name"} || $pc{"combo${_}Combo"}){ $open{'combo'} = 'open'; last; } }
foreach (3..$pc{'effectNum'}){ if($pc{"effect${_}Name"} || $pc{"effect${_}Lv"}){ $open{'effect'} = 'open'; last; } }
foreach (1..$pc{'magicNum'}){ if($pc{"magic${_}Name"} || $pc{"magic${_}Exp"}){ $open{'magic'} = 'open'; last; } }
foreach (1..$pc{'weaponNum'})  { if($pc{"weapon${_}Name"})  { $open{'item'} = 'open'; last; } }
foreach (1..$pc{'armorNum'})   { if($pc{"armor${_}Name"})   { $open{'item'} = 'open'; last; } }
foreach (1..$pc{'vehiclesNum'}){ if($pc{"vehicles${_}Name"}){ $open{'item'} = 'open'; last; } }
foreach (1..$pc{'itemNum'})    { if($pc{"item${_}Name"})    { $open{'item'} = 'open'; last; } }


### 改行処理 --------------------------------------------------
$pc{'words'}         =~ s/&lt;br&gt;/\n/g;
$pc{'freeNote'}      =~ s/&lt;br&gt;/\n/g;
$pc{'freeHistory'}   =~ s/&lt;br&gt;/\n/g;
$pc{'chatPalette'}   =~ s/&lt;br&gt;/\n/g;
$pc{"combo${_}Note"}   =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'comboNum'});
$pc{"weapon${_}Note"}  =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'weaponNum'});
$pc{"armor${_}Note"}   =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'armorNum'});
$pc{"vehicle${_}Note"} =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'vehicleNum'});
$pc{"item${_}Note"}    =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'itemNum'});

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
      background-image: url("$pc{'imageURL'}");
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
          <dt>タグ</dt><dd>@{[ input 'tags','','checkStage','' ]}</dd>
        </dl>
      </div>
      
      <div class="box" id="name-form">
        <div>
          <dl id="character-name">
            <dt>キャラクター名</dt>
            <dd>@{[input('characterName','text',"nameSet")]}</dd>
            <dt class="ruby">ふりがな</dt>
            <dd>@{[input('characterNameRuby','text',"nameSet")]}</dd>
          </dl>
          <dl id="aka">
            <dt>コードネーム</dt>
            <dd>@{[input('aka','text',"nameSet")]}</dd>
            <dt class="ruby">フリガナ</dt>
            <dd>@{[input('akaRuby','text',"nameSet")]}</dd>
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
          <dt>ステージ</dt>
          <dd>@{[input("stage",'','checkStage','list="list-stage"')]}</dd>
          <dt>経験点</dt>
          <dd>@{[input("history0Exp",'number','changeRegu',($set::make_fix?' readonly':''))]}</dd>
        </dl>
        <div class="annotate">※ステージの入力値に「クロウリングケイオス」が含まれる場合、専用項目が表示されます。</div>
      </details>

      <div id="area-status">
        @{[ imageForm($pc{'imageURL'}) ]}

        <div class="box-union" id="personal">
          <dl class="box"><dt>年齢  </dt><dd>@{[input "age"]}</dd></dl>
          <dl class="box"><dt>性別  </dt><dd>@{[input "gender",'','','list="list-gender"']}</dd></dl>
          <dl class="box"><dt>星座  </dt><dd>@{[input "sign",'','','list="list-sign"']}</dd></dl>
          <dl class="box"><dt>身長  </dt><dd>@{[input "height"]}</dd></dl>
          <dl class="box"><dt>体重  </dt><dd>@{[input "weight"]}</dd></dl>
          <dl class="box"><dt>血液型</dt><dd>@{[input "blood",'','','list="list-blood"']}</dd></dl>
        </div>
        <div class="box-union" id="works-cover">
          <dl class="box"><dt>ワークス</dt><dd>@{[input "works"]}</dd></dl>
          <dl class="box"><dt>カヴァー</dt><dd>@{[input "cover"]}</dd></dl>
        </div>

        <div class="box" id="syndrome-status">
          <h2>シンドローム／能力値 [<span id="exp-status">0</span>]</h2>
          <table>
            <thead>
              <tr><th colspan="2">シンドローム</th><th>肉体</th><th>感覚</th><th>精神</th><th>社会</th></tr>
            </thead>
            <tbody>
              <tr>
                <th>ピュア</th>
                <td><select name="syndrome1" oninput="changeSyndrome(1,this.value);">@{[ option 'syndrome1',@data::syndromes ]}</select></td>
                <td id="stt-syn1-body"  ></td>
                <td id="stt-syn1-sense" ></td>
                <td id="stt-syn1-mind"  ></td>
                <td id="stt-syn1-social"></td>
              </tr>
              <tr>
                <th>クロス</th>
                <td><select name="syndrome2" oninput="changeSyndrome(2,this.value);">@{[ option 'syndrome2',@data::syndromes ]}</select></td>
                <td id="stt-syn2-body"  ></td>
                <td id="stt-syn2-sense" ></td>
                <td id="stt-syn2-mind"  ></td>
                <td id="stt-syn2-social"></td>
              </tr>
              <tr>
                <th>トライ</th>
                <td><select name="syndrome3" oninput="changeSyndrome(3,this.value);">@{[ option 'syndrome3',@data::syndromes ]}</select></td>
                <td colspan="4"></td>
              </tr>
              <tr>
                <th colspan="2" class="right">ワークスによる修正</th>
                <td><input type="radio" name="sttWorks" value="body"   onchange="calcStt();" @{[ $pc{'sttWorks'} eq 'body'   ? 'checked':'' ]}></td>
                <td><input type="radio" name="sttWorks" value="sense"  onchange="calcStt();" @{[ $pc{'sttWorks'} eq 'sense'  ? 'checked':'' ]}></td>
                <td><input type="radio" name="sttWorks" value="mind"   onchange="calcStt();" @{[ $pc{'sttWorks'} eq 'mind'   ? 'checked':'' ]}></td>
                <td><input type="radio" name="sttWorks" value="social" onchange="calcStt();" @{[ $pc{'sttWorks'} eq 'social' ? 'checked':'' ]}></td>
              </tr>
              </tr>
              <tr>
                <th colspan="2" class="right">成長</th>
                <td>@{[input "sttGrowBody"  ,'number','calcStt']}</td>
                <td>@{[input "sttGrowSense" ,'number','calcStt']}</td>
                <td>@{[input "sttGrowMind"  ,'number','calcStt']}</td>
                <td>@{[input "sttGrowSocial",'number','calcStt']}</td>
              </tr>
              <tr>
                <th colspan="2" class="right">その他の修正</th>
                <td>@{[input "sttAddBody"  ,'number','calcStt']}</td>
                <td>@{[input "sttAddSense" ,'number','calcStt']}</td>
                <td>@{[input "sttAddMind"  ,'number','calcStt']}</td>
                <td>@{[input "sttAddSocial",'number','calcStt']}</td>
              </tr>
              <tr>
                <th colspan="2" class="right">合計</th>
                <td id="stt-total-body"  >0</td>
                <td id="stt-total-sense" >0</td>
                <td id="stt-total-mind"  >0</td>
                <td id="stt-total-social">0</td>
              </tr>
            </tbody>
          </table>
          <div class="annotate" style="border-top-width:1px;border-top-style:dotted;">※コンストラクション作成のフリーポイント3点は「成長」欄に記入してください。</div>
        </div>
        <div class="box-union" id="sub-status">
          <dl class="box" id="max-hp">
            <dt>HP最大値</dt>
            <dd>+@{[input "maxHpAdd",'number','calcMaxHp']}=<b id="max-hp-total"></b></dd>
          </dl>
          <dl class="box" id="stock-pt">
            <dt>常備化ポイント</dt>
            <dd>+@{[input "stockAdd",'number','calcStock']}=<b id="stock-total"></b></dd>
          </dl>
          <dl class="box" id="saving">
            <dt>財産ポイント</dt>
            <dd>+@{[input "savingAdd",'number','calcSaving']}=<b id="saving-total"></b></dd>
          </dl>
          <dl class="box" id="initiative">
            <dt>行動値</dt>
            <dd>+@{[input "initiativeAdd",'number','calcInitiative']}=<b id="initiative-total"></b></dd>
          </dl>
          <dl class="box" id="move">
            <dt>戦闘移動</dt>
            <dd>+@{[input "moveAdd",'number','calcMove']}=<b id="move-total"></b></dd>
          </dl>
          <dl class="box" id="dash">
            <dt>全力移動</dt>
            <dd><b id="dash-total"></b></dd>
          </dl>
          <dl class="box cc-only" id="magic-dice">
            <dt>魔術ダイス</dt>
            <dd>+@{[input "magicAdd",'number','calcMagicDice']}=<b id="magic-total"></b></dd>
          </dl>
        </div>
      </div>

      <details class="box" id="status" $open{'skill'}>
        <summary>技能 [<span id="exp-skill">0</span>]</summary>
        @{[input 'skillRideNum','hidden']}
        @{[input 'skillArtNum' ,'hidden']}
        @{[input 'skillKnowNum','hidden']}
        @{[input 'skillInfoNum','hidden']}
        <dl id="status-table">
          <dt>肉体</dt><dd id="skill-body"  >0</dd>
          <dt>感覚</dt><dd id="skill-sense" >0</dd>
          <dt>精神</dt><dd id="skill-mind"  >0</dd>
          <dt>社会</dt><dd id="skill-social">0</dd>
        </dl>
        <dl id="skill-table">
          <dt>【肉体】を使用する技能</dt>
          <dd>
            <dl id="skill-body-table">
              <dt class="left">白兵</dt><dd>@{[input "skillMelee"  ,'number','calcSkill']}+@{[input "skillAddMelee"  ,'number','calcSkill']}</dd>
              <dt class="left">回避</dt><dd>@{[input "skillDodge"  ,'number','calcSkill']}+@{[input "skillAddDodge"  ,'number','calcSkill']}</dd>
HTML
foreach my $num (1 .. $pc{'skillRideNum'}) {
print <<"HTML";
              <dt>@{[input "skillRide${num}Name",'','comboSkillSetAll','list="list-ride"']}</dt><dd>@{[input "skillRide$num",'number','calcSkill']}+@{[input "skillAddRide$num",'number','calcSkill']}</dd>
HTML
}
print <<"HTML";
            </dl>
            <div class="add-del-button"><a onclick="addSkill('Ride')">▼</a><a onclick="delSkill('Ride')">▲</a></div>
          </dd>
          <dt>【感覚】を使用する技能</dt>
          <dd>
            <dl id="skill-sense-table">
              <dt class="left">射撃</dt><dd>@{[input "skillRanged" ,'number','calcSkill']}+@{[input "skillAddRanged"    ,'number','calcSkill']}</dd>
              <dt class="left">知覚</dt><dd>@{[input "skillPercept",'number','calcSkill']}+@{[input "skillAddPercept",'number','calcSkill']}</dd>
HTML
foreach my $num (1 .. $pc{'skillArtNum'}) {
print <<"HTML";
              <dt>@{[input "skillArt${num}Name" ,'','comboSkillSetAll','list="list-art"' ]}</dt><dd>@{[input "skillArt$num" ,'number','calcSkill']}+@{[input "skillAddArt$num" ,'number','calcSkill']}</dd>
HTML
}
print <<"HTML";
            </dl>
            <div class="add-del-button"><a onclick="addSkill('Art')">▼</a><a onclick="delSkill('Art')">▲</a></div>
          </dd>
          <dt>【精神】を使用する技能</dt>
          <dd>
            <dl id="skill-mind-table">
              <dt class="left">ＲＣ</dt><dd>@{[input "skillRC"  ,'number','calcSkill']}+@{[input "skillAddRC"  ,'number','calcSkill']}</dd>
              <dt class="left">意志</dt><dd>@{[input "skillWill",'number','calcSkill']}+@{[input "skillAddWill",'number','calcSkill']}</dd>
HTML
foreach my $num (1 .. $pc{'skillKnowNum'}) {
print <<"HTML";
              <dt>@{[input "skillKnow${num}Name",'','comboSkillSetAll','list="list-know"']}</dt><dd>@{[input "skillKnow$num",'number','calcSkill']}+@{[input "skillAddKnow$num",'number','calcSkill']}</dd>
HTML
}
print <<"HTML";
            </dl>
            <div class="add-del-button"><a onclick="addSkill('Know')">▼</a><a onclick="delSkill('Know')">▲</a></div>
          </dd>
          <dt>【社会】を使用する技能</dt>
          <dd>
            <dl id="skill-social-table">
              <dt class="left">交渉</dt><dd>@{[input "skillNegotiate",'number','calcSkill']}+@{[input "skillAddNegotiate",'number']}</dd>
              <dt class="left">調達</dt><dd>@{[input "skillProcure"  ,'number','calcSkill();calcStock']}+@{[input "skillAddProcure",  'number','calcSkill();calcStock']}</dd>
HTML
foreach my $num (1 .. $pc{'skillInfoNum'}) {
print <<"HTML";
              <dt>@{[input "skillInfo${num}Name",'','comboSkillSetAll','list="list-info"']}</dt><dd>@{[input "skillInfo$num",'number','calcSkill']}+@{[input "skillAddInfo$num",'number','calcSkill']}</dd>
HTML
}
print <<"HTML";
            </dl>
            <div class="add-del-button"><a onclick="addSkill('Info')">▼</a><a onclick="delSkill('Info')">▲</a></div>
          </dd>
        </dl>
        <div class="annotate">
        ※右側は、DロイスなどによるLv補正の欄です（経験点が計算されません）
        </div>
      </details>
      <details class="box" id="lifepath" $open{'lifepath'}>
        <summary>ライフパス</summary>
        <table class="edit-table line-tbody">
          <tbody>
          <tr>
            <th>出自</th>
            <td colspan="2">@{[input "lifepathOrigin"]}</td>
            <td colspan="2" class="left">@{[input "lifepathOriginNote",'','','placeholder="備考"']}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th>経験</th>
            <td colspan="2">@{[input "lifepathExperience"]}</td>
            <td colspan="2" class="left">@{[input "lifepathExperienceNote",'','','placeholder="備考"']}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th>邂逅/欲望</th>
            <td colspan="2">@{[input "lifepathEncounter"]}</td>
            <td colspan="2" class="left">@{[input "lifepathEncounterNote",'','','placeholder="備考"']}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th>覚醒</th>
            <td><select name="lifepathAwaken" oninput="calcEncroach()">@{[option "lifepathAwaken",@awakens]}</select></td>
            <th class="small">侵蝕値</th>
            <td class="center" id="awaken-encroach"></td>
            <td class="left">@{[input "lifepathAwakenNote",'','','placeholder="備考"']}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th rowspan="2">衝動</th>
            <td><select name="lifepathImpulse" oninput="refreshByImpulse()">@{[option "lifepathImpulse",@impulses]}</select></td>
            <th class="small">侵蝕値</th>
            <td class="center" id="impulse-encroach"></td>
            <td class="left">@{[input "lifepathImpulseNote",'','','placeholder="備考"']}</td>
          </tr>
          <tr>
            <th class="small">@{[input "lifepathUrgeCheck",'checkbox']}変異暴走</th>
            <th class="small">効果</th>
            <td class="left" colspan="2">@{[input "lifepathUrgeNote",'','','placeholder="効果"']}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th colspan="3" class="right small">その他の修正</th>
            <td class="center">@{[input "lifepathOtherEncroach",'number','calcEncroach']}</td>
            <td class="left">@{[input "lifepathOtherNote",'','','placeholder="備考"']}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th colspan="3" class="right">侵蝕率基本値</th>
            <td class="center bold" id="base-encroach"></td>
          </tr>
          </tbody>
        </table>
      </details>
      <div id="enc-bonus" style="position: relative;">
        <div class="box">
          <h2>侵蝕率効果表</h2>
          <p>
            <!-- 現在侵蝕率:@{[ input 'currentEncroach','number','encroachBonusSet(this.value)','style="width: 4em;"' ]} -->
            @{[ checkbox 'encroachEaOn','エフェクトアーカイブ適用','encroachBonusType' ]}
          </p>
          <table class="data-table" id="enc-table">
            <colgroup></colgroup>
            <tr id="enc-table-head"></tr>
            <tr id="enc-table-dices"></tr>
            <tr id="enc-table-level"></tr>
          </table>
        </div>
      </div>
      <details class="box" id="lois" $open{'lois'} style="position:relative">
        <summary>ロイス</summary>
        <table class="edit-table no-border-cells" id="lois-table">
          <colgroup><col><col><col><col><col><col><col></colgroup>
          <thead>
            <tr>
              <th>関係</th>
              <th>名前</th>
              <th colspan="3">感情<span class="small">(Positive／Negative)</span></th>
              <th>属性</th>
              <th colspan="2" class="right">状態</th>
            </tr>
          </thead>
          <tbody>
HTML
foreach my $num (1 .. 7) {
if(!$pc{"lois${num}State"}){ $pc{"lois${num}State"} = 'ロイス' }
print <<"HTML";
            <tr id="lois${num}">
              <td><span class="handle"></span>@{[input "lois${num}Relation"]}</td>
              <td>@{[input "lois${num}Name",'','encroachBonusType']}</td>
              <td class="emo">@{[input "lois${num}EmoPosiCheck",'checkbox',"emoP($num)"]}@{[input "lois${num}EmoPosi",'','','list="list-emotionP"']}</td>
              <td>／</td>
              <td class="emo">@{[input "lois${num}EmoNegaCheck",'checkbox',"emoN($num)"]}@{[input "lois${num}EmoNega",'','','list="list-emotionN"']}</td>
              <td>@{[input "lois${num}Color",'',"changeLoisColor($num)",'list="list-lois-color"']}</td>
              <td>@{[input "lois${num}Note"]}</td>
              <td onclick="changeLoisState(this.parentNode.id)"><span id="lois${num}-state" data-state="$pc{"lois${num}State"}"></span>@{[input "lois${num}State",'hidden']}</td>
            </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
        <div class="right" style="position: absolute; top: 0; right: 0;">
          <a class="button small" onclick="resetLoisAll()">全ロイスをリセット</a>
          <a class="button small" onclick="resetLoisAdd()">4番目以降をリセット</a>
        </div>
      </details>
      <details class="box" id="memory" $open{'memory'}>
        <summary>メモリー [<span id="exp-memory">0</span>]</summary>
        <table class="edit-table no-border-cells" id="memory-table">
          <thead>
            <tr>
              <th>取得</th>
              <th>関係</th>
              <th>名前</th>
              <th>感情</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
HTML
foreach my $num (1 .. 3) {
print <<"HTML";
            <tr id="memory${num}">
              <td><span class="handle"></span>@{[input "memory${num}Gain",'checkbox','calcMemory']}</td>
              <td>@{[input "memory${num}Relation"]}</td>
              <td>@{[input "memory${num}Name"]}</td>
              <td>@{[input "memory${num}Emo"]}</td>
              <td>@{[input "memory${num}Note"]}</td>
            </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
      </details>
      <details class="box cc-only" id="insanity" $open{'insanity'}>
        <summary>永続的狂気</summary>
        <dl class="edit-table " id="insanity-table">
          <dt>@{[input "insanity",'','','placeholder="名称"']}</dt>
          <dd>@{[input "insanityNote",'','','placeholder="効果"']}</dd>
        </dl>
      </details>

      <details class="box" id="effect" $open{'effect'}>
        <summary>エフェクト [<span id="exp-effect">0</span>]</summary>
        @{[input 'effectNum','hidden']}
        <table class="edit-table line-tbody no-border-cells" id="effect-table">
          <thead>
            <tr><th></th><th>名称</th><th>Lv</th><th>タイミング</th><th>技能</th><th>難易度</th><th>対象</th><th>射程</th><th>侵蝕値</th><th>制限</th></tr>
          </thead>
HTML
foreach my $num (1 .. $pc{'effectNum'}) {
print <<"HTML";
          <tbody id="effect${num}">
            <tr>
              <td rowspan="2" class="handle"> </td>
              <td>@{[input "effect${num}Name",'','','placeholder="名称"']}</td>
              <td>@{[input "effect${num}Lv",'number','calcEffect','placeholder="Lv"']}</td>
              <td>@{[input "effect${num}Timing",'','','placeholder="タイミング" list="list-timing"']}</td>
              <td>@{[input "effect${num}Skill",'','','placeholder="技能" list="list-effect-skill"']}</td>
              <td>@{[input "effect${num}Dfclty",'','','placeholder="難易度" list="list-dfclty"']}</td>
              <td>@{[input "effect${num}Target",'','','placeholder="対象" list="list-target"']}</td>
              <td>@{[input "effect${num}Range",'','','placeholder="射程" list="list-range"']}</td>
              <td>@{[input "effect${num}Encroach",'','','placeholder="侵蝕値" list="list-encroach"']}</td>
              <td>@{[input "effect${num}Restrict",'','','placeholder="制限" list="list-restrict"']}</td>
            </tr>
            <tr><td colspan="9"><div>
              <b>種別</b><select name="effect${num}Type" oninput="calcEffect()">@{[ option "effect${num}Type",'auto|<自動取得>','dlois|<Dロイス>','easy|<イージー>','enemy|<エネミー>' ]}</select>
              <b class="small">経験点修正</b>@{[input "effect${num}Exp",'number','calcEffect']}
              <b>効果</b>@{[input "effect${num}Note"]}
            </div></td></tr>
          </tbody>
HTML
}
print <<"HTML";
          <tfoot>
            <tr><th></th><th>名称</th><th>Lv</th><th>タイミング</th><th>技能</th><th>難易度</th><th>対象</th><th>射程</th><th>侵蝕値</th><th>制限</th></tr>
          </tfoot>
        </table>
        <div class="add-del-button"><a onclick="addEffect()">▼</a><a onclick="delEffect()">▲</a></div>
        <div class="annotate">
        ※種別「自動」「Dロイス」を選択した場合、取得時（1Lv）の経験点を0として計算します。<br>
        　経験点修正の欄は、自動計算で対応しきれない例外的な取得・成長に使用してください（Dロイス転生者など）
        </div>
      </details>
      <div class="box trash-box" id="effect-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除エフェクト</span></h2>
        <table class="edit-table line-tbody" id="effect-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('effect-trash').style.display = 'none';">close</i>
      </div>

      <details class="box cc-only" id="magic" $open{'magic'}>
        <summary>術式 [<span id="exp-magic">0</span>]</summary>
        @{[input 'magicNum','hidden']}
        <table class="edit-table line-tbody no-border-cells" id="magic-table">
          <thead>
            <tr><th></th><th>名称</th><th>種別</th><th>経験点</th><th>発動値</th><th>侵蝕値</th><th>効果</th></tr>
          </thead>
HTML
foreach my $num (1 .. $pc{'magicNum'}) {
print <<"HTML";
          <tbody id="magic${num}">
            <tr>
              <td class="handle"> </td>
              <td>@{[input "magic${num}Name"    ,'','','placeholder="名称"']}</td>
              <td>@{[input "magic${num}Type"    ,'','','placeholder="種別" list="list-magic-type"']}</td>
              <td>@{[input "magic${num}Exp"     ,'number','calcMagic']}</td>
              <td>@{[input "magic${num}Activate",'','','placeholder="発動値"']}</td>
              <td>@{[input "magic${num}Encroach",'','','placeholder="侵蝕値"']}</td>
              <td>@{[input "magic${num}Note"    ,'','','placeholder="効果"']}</td>
            </tr>
          </tbody>
HTML
}
print <<"HTML";
        <tfoot></tfoot>
        </table>
        <div class="add-del-button"><a onclick="addMagic()">▼</a><a onclick="delMagic()">▲</a></div>
      </details>
      <div class="box trash-box" id="magic-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除術式</span></h2>
        <table class="edit-table line-tbody" id="magic-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('magic-trash').style.display = 'none';">close</i>
      </div>
      
      <details class="box" id="combo" $open{'combo'} style="position:relative">
        <summary>コンボ</summary>
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
foreach my $num (1 .. $pc{'comboNum'}) {
print <<"HTML";
        <div class="combo-table" id="combo${num}">
          <div class="handle"></div>
          <dl class="combo-name"><dt>名称</dt><dd>@{[input "combo${num}Name"]}</dd></dl>
          <dl class="combo-combo"><dt>組み合わせ</dt><dd>@{[input "combo${num}Combo"]}</dl>
          <div class="combo-in">
            <dl><dt>タイミング</dt><dd>@{[input "combo${num}Timing",'','','list="list-combo-timing"']}</dd></dl>
            <dl><dt>技能      </dt><dd><select name="combo${num}Skill" oninput="calcCombo(${num})">@{[ comboSkillSet($num) ]}</select></dd></dl>
            <dl><dt>能力値    </dt><dd><select name="combo${num}Stt" oninput="calcCombo(${num})">@{[ comboStatusSet($num) ]}</select></dd></dl>
            <dl><dt>難易度    </dt><dd>@{[input "combo${num}Dfclty",'','','list="list-dfclty"']}</dd></dl>
            <dl><dt>対象      </dt><dd>@{[input "combo${num}Target",'','','list="list-target"']}</dd></dl>
            <dl><dt>射程      </dt><dd>@{[input "combo${num}Range",'','','list="list-range"']}</dd></dl>
            <dl><dt>侵蝕値    </dt><dd>@{[input "combo${num}Encroach"]}</dd></dl>
          </div>
          <dl class="combo-out">
            <dt class="combo-cond">条件</dt>
            <dt class="combo-dice">ダイス</dt>
            <dt class="combo-crit">Ｃ値</dt>
            <dt class="combo-fixed">判定固定値</dt>
            <dt class="combo-atk">攻撃力</dt>
HTML
  foreach my $i (1 .. 4) {
  print <<"HTML";
            <dd>@{[input "combo${num}Condition${i}"]}</dd>
            <dd id="combo${num}Stt${i}"></dd>
            <dd>@{[input "combo${num}DiceAdd${i}"]}</dd>
            <dd>@{[input "combo${num}Crit${i}"]}</dd>
            <dd id="combo${num}SkillLv${i}"></dd>
            <dd>@{[input "combo${num}FixedAdd${i}"]}</dd>
            <dd>@{[input "combo${num}Atk${i}"]}</dd>
HTML
  }
print <<"HTML";
          </dl>
          <p class="combo-note"><textarea name="combo${num}Note" rows="3" placeholder="解説">$pc{"combo${num}Note"}</textarea></p>
        </div>
HTML
}
print <<"HTML";
        </div>
        <div class="add-del-button"><a onclick="addCombo()">▼</a><a onclick="delCombo()">▲</a></div>
        <div class="annotate">
          @{[ input 'comboCalcOff','checkbox','calcComboAll' ]} 能力値・技能Lvを自動挿入しない（自分で計算する）
        </div>
      </details>
      
      <details class="box box-union" id="items" $open{'item'}>
      <summary>アイテム [<span id="exp-item">0</span>]</summary>
      <div class="box">
        @{[input 'weaponNum','hidden']}
        <table class="edit-table no-border-cells" id="weapon-table">
          <thead>
            <tr><th>武器</th><th>常備化</th><th>経験点</th><th>種別</th><th>技能</th><th>命中</th><th>攻撃力</th><th><span class="small">ガード値</span></th><th>射程</th><th>解説</th></tr>
          </thead>
          <tbody>
HTML
foreach my $num (1 .. $pc{'weaponNum'}) {
print <<"HTML";
            <tr id="weapon${num}">
              <td>@{[input "weapon${num}Name"]}<span class="handle"></span></td>
              <td>@{[input "weapon${num}Stock",'number','calcItem']}</td>
              <td>@{[input "weapon${num}Exp",'number','calcItem']}</td>
              <td>@{[input "weapon${num}Type",'','','list="list-weapon-type"']}</td>
              <td>@{[input "weapon${num}Skill",'','','list="list-weapon-skill"']}</td>
              <td>@{[input "weapon${num}Acc"]}</td>
              <td>@{[input "weapon${num}Atk"]}</td>
              <td>@{[input "weapon${num}Guard"]}</td>
              <td>@{[input "weapon${num}Range"]}</td>
              <td><textarea name="weapon${num}Note" rows="2">$pc{"weapon${num}Note"}</textarea></td>
            </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addWeapon()">▼</a><a onclick="delWeapon()">▲</a></div>
      </div>
      <div class="box">
        @{[input 'armorNum','hidden']}
        <table class="edit-table no-border-cells" id="armor-table">
          <thead>
            <tr><th>防具</th><th>常備化</th><th>経験点</th><th>種別</th><th></th><th>行動</th><th>ドッジ</th><th>装甲値</th><th>解説</th></tr>
          </thead>
          <tbody>
HTML
foreach my $num (1 .. $pc{'armorNum'}) {
print <<"HTML";
            <tr id="armor${num}">
              <td>@{[input "armor${num}Name"]}<span class="handle"></span></td>
              <td>@{[input "armor${num}Stock",'number','calcItem']}</td>
              <td>@{[input "armor${num}Exp",'number','calcItem']}</td>
              <td>@{[input "armor${num}Type",'','','list="list-armor-type"']}</td>
              <td></td>
              <td>@{[input "armor${num}Initiative"]}</td>
              <td>@{[input "armor${num}Dodge"]}</td>
              <td>@{[input "armor${num}Armor"]}</td>
              <td><textarea name="armor${num}Note" rows="2">$pc{"armor${num}Note"}</textarea></td>
            </tr>
HTML
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
            <tr><th>ヴィークル</th><th>常備化</th><th>経験点</th><th>種別</th><th>技能</th><th>行動</th><th>攻撃力</th><th>装甲値</th><th><span class="small">全力移動</span></th><th>解説</th></tr>
          </thead>
          <tbody>
HTML
foreach my $num (1 .. $pc{'vehicleNum'}) {
print <<"HTML";
            <tr id="vehicle${num}">
              <td>@{[input "vehicle${num}Name"]}<span class="handle"></span></td>
              <td>@{[input "vehicle${num}Stock",'number','calcItem']}</td>
              <td>@{[input "vehicle${num}Exp",'number','calcItem']}</td>
              <td>@{[input "vehicle${num}Type",'','','list="list-vehicle-type"']}</td>
              <td>@{[input "vehicle${num}Skill",'','','list="list-vehicle-skill"']}</td>
              <td>@{[input "vehicle${num}Initiative"]}</td>
              <td>@{[input "vehicle${num}Atk"]}</td>
              <td>@{[input "vehicle${num}Armor"]}</td>
              <td>@{[input "vehicle${num}Dash"]}</td>
              <td><textarea name="vehicle${num}Note" rows="2">$pc{"vehicle${num}Note"}</textarea></td>
            </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addVehicle()">▼</a><a onclick="delVehicle()">▲</a></div>
      </div>
      <div class="box">
        @{[input 'itemNum','hidden']}
        <table class="edit-table no-border-cells" id="item-table">
          <thead>
            <tr><th>一般アイテム</th><th>常備化</th><th>経験点</th><th>種別</th><th>技能</th><th>解説</th></tr>
          </thead>
          <tbody>
HTML
foreach my $num (1 .. $pc{'itemNum'}) {
print <<"HTML";
            <tr id="item${num}">
              <td>@{[input "item${num}Name"]}<span class="handle"></span></td>
              <td>@{[input "item${num}Stock",'number','calcItem']}</td>
              <td>@{[input "item${num}Exp",'number','calcItem']}</td>
              <td>@{[input "item${num}Type",'','','list="list-item-type"']}</td>
              <td>@{[input "item${num}Skill",'','','list="list-item-skill"']}</td>
              <td><textarea name="item${num}Note" rows="2">$pc{"item${num}Note"}</textarea></td>
            </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addItem()">▼</a><a onclick="delItem()">▲</a></div>
      </div>
      <div class="box">
        <table class="edit-table">
          <thead><tr><th></th><th>常備化</th><th>経験点</th><th></th></tr></thead>
          <tbody>
            <tr>
            <th>合計</th>
            <td><b id="item-total-stock">0</b>/<b id="item-max-stock">0</b></td>
            <td class="bold" id="item-total-exp">0</td>
            <td></td>
            </tr>
          </tbody>
        </table>
      </div>
      </details>
      
      
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
          <colgroup><col><col><col><col><col><col><col></colgroup>
          <thead>
          <tr>
            <th></th>
            <th>日付</th>
            <th>タイトル</th>
            <th colspan="2">経験点</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
          <tr>
            <td>-</td>
            <td></td>
            <td>キャラクター作成</td>
            <td id="history0-exp">$pc{'history0Exp'}</td>
            <td><input type="checkbox" checked disabled>適用</td>
          </tr>
          </thead>
HTML
foreach my $num (1 .. $pc{'historyNum'}) {
print <<"HTML";
          <tbody id="history${num}">
          <tr>
            <td rowspan="2" class="handle"></td>
            <td rowspan="2">@{[input "history${num}Date" ]}</td>
            <td rowspan="2">@{[input "history${num}Title" ]}</td>
            <td>@{[ input "history${num}Exp",'text','calcExp' ]}</td>
            <td><label>@{[ input "history${num}ExpApply",'checkbox','calcExp' ]}<b>適用</b></label>
            <td>@{[ input "history${num}Gm" ]}</td>
            <td>@{[ input "history${num}Member" ]}</td>
          </tr>
          <tr><td colspan="4" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}</td></tr>
          </tbody>
HTML
}
print <<"HTML";
          <tfoot>
            <tr><th></th><th>日付</th><th>タイトル</th><th colspan="2">経験点</th><th>GM</th><th>参加者</th></tr>
          </tfoot>
        </table>
        <div class="add-del-button"><a onclick="addHistory()">▼</a><a onclick="delHistory()">▲</a></div>
        <h2>記入例</h2>
        <table class="example edit-table line-tbody no-border-cells">
          <colgroup><col><col><col><col><col><col><col></colgroup>
          <thead>
          <tr>
            <th></th>
            <th>日付</th>
            <th>タイトル</th>
            <th colspan="2">経験点</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
          </thead>
          <tbody>
          <tr>
            <td>-</td>
            <td><input type="text" value="2020-03-18" disabled></td>
            <td><input type="text" value="第一話「記入例」" disabled></td>
            <td><input type="text" value="10+5+1" disabled></td>
            <td><label><input type="checkbox" checked disabled><b>適用</b></label></td>
            <td class="gm"><input type="text" value="サンプルGM" disabled></td>
            <td class="member"><input type="text" value="鳴瓢秋人　本堂町小春　百貴船太郎　富久田保津" disabled></td>
          </tr>
          </tbody>
        </table>
        <div class="annotate">
        ※経験点欄は<code>10+5+1</code>など四則演算が有効です（獲得条件の違う経験点などを分けて書けます）。<br>
        　経験点欄の右の適用チェックを入れると、その経験点が適用されます。
        </div>
      </div>
      
      <div class="box" id="exp-footer">
        <p>
        経験点[<b id="exp-total"></b>] - 
        ( 能力値[<b id="exp-used-status"></b>]
        - 技能[<b id="exp-used-skill"></b>]
        - エフェクト[<b id="exp-used-effect"></b>]
        <span class="cc-only">- 術式[<b id="exp-used-magic"></b>]</span>
        - アイテム[<b id="exp-used-item"></b>]
        - メモリー[<b id="exp-used-memory"></b>]
        ) = 残り[<b id="exp-rest"></b>]点
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
    <p class="notes">©FarEast Amusement Research Co.,Ltd.「ダブルクロスThe 3rd Edition」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
  </footer>
  <datalist id="list-stage">
    <option value="基本ステージ">
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
    <option value="効果参照">
  </datalist>
  <datalist id="list-weapon-skill">
    <option value="―">
    <option value="〈白兵〉">
    <option value="〈射撃〉">
    <option value="〈白兵〉〈射撃〉">
    <option value="効果参照">
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
    <option value="〈情報:学問">
    <option value="〈情報:ウェブ〉">
    <option value="〈情報:メディア〉">
    <option value="〈情報:ビジネス〉">
    <option value="効果参照">
  </datalist>
  <datalist id="list-weapon-type">
    <option value="白兵">
    <option value="射撃">
    <option value="白兵／射撃">
  </datalist>
  <datalist id="list-armor-type">
    <option value="防具">
    <option value="防具※">
  </datalist>
  <datalist id="list-item-type">
    <option value="コネ">
    <option value="その他">
    <option value="使い捨て">
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
  </script>
</body>

</html>
HTML

1;