############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';
use Encode;

require $set::lib_palette_sub;

my $mode = $main::mode;
my $message = $main::message;
our %pc;

my $LOGIN_ID = check;

### 読込前処理 #######################################################################################
### エラーメッセージ --------------------------------------------------
if($main::make_error) {
  $mode = 'blanksheet';
  for (param()){ $pc{$_} = param($_); }
  $message = $main::make_error;
}
## 新規作成＆コピー時 --------------------------------------------------
my $token;
if($mode eq 'blanksheet' || $mode eq 'copy' || $mode eq 'convert'){
  $token = token_make();
}
## 更新後処理 --------------------------------------------------
if($mode eq 'save'){
  $message .= 'データを更新しました。<a href="./?id='.param('id').'">⇒シートを確認する</a>';
  $mode = 'edit';
}

### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_syndrome;
my @awakens;
my @impulses;
push(@awakens , @$_[0]) foreach(@data::awakens);
push(@impulses, @$_[0]) foreach(@data::impulses);

### データ読み込み ###################################################################################
my $id;
my $pass;
my $file;
### 編集時 --------------------------------------------------
if($mode eq 'edit'){
  $id = param('id');
  $pass = param('pass');
  (undef, undef, $file, undef) = getfile($id,$pass,$LOGIN_ID);
  open my $IN, '<', "${set::char_dir}${file}/data.cgi" or &login_error;
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
}
elsif($mode eq 'copy'){
  $id = param('id');
  $file = (getfile_open($id))[0];
  open my $IN, '<', "${set::char_dir}${file}/data.cgi" or error 'キャラクターシートがありません。';
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
  
  delete $pc{'image'};  
  
  $message = '「<a href="./?id='.$id.'" target="_blank">'.$pc{"characterName"}.'</a>」をコピーして新規作成します。<br>（まだ保存はされていません）';
}
elsif($mode eq 'convert'){
  require $set::lib_convert;
  %pc = data_convert(param('url'));
  $message = '「<a href="'.param('url').'" target="_blank">'.($pc{"characterName"}||$pc{"aka"}||'無題').'</a>」をコンバートして新規作成します。<br>（まだ保存はされていません）';
}

### プレイヤー名 --------------------------------------------------
if($mode eq 'blanksheet' || $mode eq 'copy' || $mode eq 'convert'){
  $pc{'playerName'} = (getplayername($LOGIN_ID))[0] if !$main::make_error;
}

### 出力準備 #########################################################################################
### 初期設定 --------------------------------------------------
$pc{'protect'} = $pc{'protect'} ? $pc{'protect'} : 'password';
$pc{'group'} = $pc{'group'} ? $pc{'group'} : $set::group_default;

$pc{'history0Exp'} = $pc{'history0Exp'} ne '' ? $pc{'history0Exp'} : $set::make_exp;

$pc{'skillNum'}   = $pc{'skillNum'}   || 2;
$pc{'effectNum'}  = $pc{'effectNum'}  || 5;
$pc{'weaponNum'}  = $pc{'weaponNum'}  || 1;
$pc{'armorNum'}   = $pc{'armorNum'}   || 1;
$pc{'itemNum'}    = $pc{'itemNum'}    || 2;
$pc{'historyNum'} = $pc{'historyNum'} || 3;

if(!$pc{'comboNum'}){
  $pc{'comboNum'} = 1;
  $pc{'combo1Condition1'} = '100%未満';
  $pc{'combo1Condition2'} = '100%以上';
}
if(!$pc{'effect1Name'}){
  ($pc{'effect1Type'},$pc{'effect1Name'},$pc{'effect1Lv'},$pc{'effect1Timing'},$pc{'effect1Skill'},$pc{'effect1Dfclty'},$pc{'effect1Target'},$pc{'effect1Range'},$pc{'effect1Encroach'},$pc{'effect1Restrict'},$pc{'effect1Note'})
    = ('auto','リザレクト',1,'オート','―','自動成功','自身','至近','効果参照','―','(Lv)D点HP回復、侵蝕値上昇');
}
if(!$pc{'effect2Name'}){
  ($pc{'effect2Type'},$pc{'effect2Name'},$pc{'effect2Lv'},$pc{'effect2Timing'},$pc{'effect2Skill'},$pc{'effect2Dfclty'},$pc{'effect2Target'},$pc{'effect2Range'},$pc{'effect2Encroach'},$pc{'effect2Restrict'},$pc{'effect2Note'})
    = ('auto','ワーディング',1,'オート','―','自動成功','シーン','視界','0','―','非オーヴァードをエキストラ化');
}

$pc{'colorHeadBgH'} = $pc{'colorHeadBgH'} eq '' ? 225 : $pc{'colorHeadBgH'};
$pc{'colorHeadBgS'} = $pc{'colorHeadBgS'} eq '' ?   9 : $pc{'colorHeadBgS'};
$pc{'colorHeadBgL'} = $pc{'colorHeadBgL'} eq '' ?  65 : $pc{'colorHeadBgL'};
$pc{'colorBaseBgH'} = $pc{'colorBaseBgH'} eq '' ? 210 : $pc{'colorBaseBgH'};
$pc{'colorBaseBgS'} = $pc{'colorBaseBgS'} eq '' ?   0 : $pc{'colorBaseBgS'};
$pc{'colorBaseBgL'} = $pc{'colorBaseBgL'} eq '' ? 100 : $pc{'colorBaseBgL'};

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
  foreach my $num (1..$pc{'skillNum'}){
    if ($pc{$_.$num}){ $open{'skill'} = 'open'; last; }
  }
}
if  ($pc{"lifepathOrigin"}
  || $pc{"lifepathExperience"}
  || $pc{"lifepathEncounter"}
  || $pc{"lifepathAwaken"}
  || $pc{"lifepathImpulse"}  ){ $open{'lifepath'} = 'open'; }
foreach (1..7){ if($pc{"lois${_}Relation"} || $pc{"lois${_}Name"}  ){ $open{'lois'}   = 'open'; last; } }
foreach (1..3){ if($pc{"memory${_}Gain"}   || $pc{"memory${_}Name"}){ $open{'memory'} = 'open'; last; } }
foreach (1..$pc{'comboNum'}) { if($pc{"combo${_}Name"} || $pc{"combo${_}Combo"}){ $open{'combo'} = 'open'; last; } }
foreach (3..$pc{'effectNum'}){ if($pc{"effect${_}Name"} || $pc{"effect${_}Lv"}){ $open{'effect'} = 'open'; last; } }
foreach (1..$pc{'weaponNum'})  { if($pc{"weapon${_}Name"})  { $open{'item'} = 'open'; last; } }
foreach (1..$pc{'armorNum'})   { if($pc{"armor${_}Name"})   { $open{'item'} = 'open'; last; } }
foreach (1..$pc{'vehiclesNum'}){ if($pc{"vehicles${_}Name"}){ $open{'item'} = 'open'; last; } }
foreach (1..$pc{'itemNum'})    { if($pc{"item${_}Name"})    { $open{'item'} = 'open'; last; } }

### 改行処理 --------------------------------------------------
$pc{'freeNote'}      =~ s/&lt;br&gt;/\n/g;
$pc{'freeHistory'}   =~ s/&lt;br&gt;/\n/g;
$pc{'chatPalette'}   =~ s/&lt;br&gt;/\n/g;
$pc{"combo${_}Note"}   =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'comboNum'});
$pc{"weapon${_}Note"}  =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'weaponNum'});
$pc{"armor${_}Note"}   =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'armorNum'});
$pc{"vehicle${_}Note"} =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'vehicleNum'});
$pc{"item${_}Note"}    =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{'itemNum'});

### フォーム表示 #####################################################################################
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>@{[$mode eq 'edit'?"編集：$pc{'characterName'}":'新規作成']} - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/base.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/sheet.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/dx3/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/dx3/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/lib/dx3/edit-chara.js?${main::ver}" defer></script>
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.3.1/css/all.css" integrity="sha384-mzrmE5qonljUremFsqc01SB46JvROS7bZs3IO2EmfFsd15uHvIt+Y8vEf7N7fWAU" crossorigin="anonymous">
  <style>
    #image {
      background-image: url("${set::char_dir}${file}/image.$pc{'image'}") !important;
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
      <aside class="message">$message</aside>
      <form name="sheet" method="post" action="./" enctype="multipart/form-data">
HTML
if($mode eq 'blanksheet' || $mode eq 'copy' || $mode eq 'convert'){
  print '<input type="hidden" name="_token" value="'.$token.'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      <div id="area-name">
        <div id="character-name">
          <div>キャラクター名@{[input('characterName','text','','required placeholder="漢字:るび"')]}</div>
          <div>コードネーム　@{[input('aka','text','','placeholder="漢字:ルビ"')]}</div>
        </div>
        <div>
          <p id="update-time"></p>
          <p id="player-name">プレイヤー名@{[input('playerName')]}</p>
        </div>
HTML
if($mode eq 'edit'){
print <<"HTML";
        <input type="button" value="複製" onclick="window.open('./?mode=copy&id=${id}');">
HTML
}
print <<"HTML";
        <input type="submit" value="保存">
        <ul id="header-menu">
          <li onclick="sectionSelect('common');">キャラクターデータ</li>
          <li onclick="sectionSelect('palette');">チャットパレット</li>
          <li onclick="sectionSelect('color');">カラーカスタム</li>
        </ul>
      </div>
HTML
if($set::user_reqd){
  print <<"HTML";
    <input type="hidden" name="protect" value="account">
    <input type="hidden" name="protectOld" value="$pc{'protect'}">
    <input type="hidden" name="pass" value="$pass">
HTML
}
else {
  if($set::registerkey && ($mode eq 'blanksheet' || $mode eq 'copy' || $mode eq 'convert')){
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
  if ($mode eq 'edit' && $pc{'protect'} eq 'password') {
    print '<input type="hidden" name="pass" value="'.$pass.'"><br>';
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
      <section id="section-common">
      <div id="hide-options">
        <p id="hide-checkbox">
        @{[ input 'hide','checkbox' ]} 一覧に表示しない<br>
        ※タグ検索結果に合致した場合は表示されます
        </p>
      </div>
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
      <details class="box" id="regulation" @{[$mode eq 'edit' ? '':'open']}>
        <summary>作成レギュレーション</summary>
        <dl>
          <dt>ステージ</dt>
          <dd>@{[input("stage",'','','list="list-stage"')]}</dd>
          <dt>経験点</dt>
          <dd>@{[input("history0Exp",'number','changeRegu',($set::make_fix?' readonly':''))]}</dd>
        </dl>
      </details>
      <div id="area-status">
        <div class="box" id="image" style="max-height:550px;">
          <h2>キャラクター画像</h2>
          <p>
            <input type="file" accept="image/*" name="imageFile"><br>
            ※ @{[ int($set::image_maxsize / 1024) ]}KBまでのJPG/PNG/GIF
          </p>
          <p>
            表示方式：<select name="imageFit" oninput="imagePosition()">
            <option value="cover"   @{[$pc{'imageFit'} eq 'cover'  ?'selected':'']}>枠いっぱいに表示
            <option value="contain" @{[$pc{'imageFit'} eq 'contain'?'selected':'']}>画像全体を表示
            <option value="unset"   @{[$pc{'imageFit'} eq 'unset'  ?'selected':'']}>拡大／縮小せず表示
            <option value="percent" @{[$pc{'imageFit'} eq 'percent'?'selected':'']}>拡大率を指定
            </select><br>
            <br>
            拡大率：@{[ input "imagePercent",'number','imagePosition','style="width:4em;"' ]}%<br>
            （「拡大率を指定」時／100で横幅ピッタリ）<br>
            <br>
            枠をはみ出る際の基準位置(50%が中心)<br>
            横@{[ input "imagePositionX",'number','imagePosition','style="width:4em;"' ]}% ／ 
            縦@{[ input "imagePositionY",'number','imagePosition','style="width:4em;"' ]}%
          </p>
          <p>
          画像の注釈（作者や権利表記など）
          @{[ input 'imageCopyright' ]}
          </p>
          <p>
            <input type="checkbox" name="imageDelete" value="1"> 画像を削除する
            @{[input('image','hidden')]}
          </p>
          <h2>セリフ</h2>
          <p class="words-input">
          @{[ input 'words' ]}<br>
          セリフの配置：
          <select name="wordsX">@{[ option 'wordsX','右','左' ]}</select>
          <select name="wordsY">@{[ option 'wordsY','上','下' ]}</select>
          </p>
        </div>

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
        </div>
        <div class="box-union" id="sub-status">
          <dl class="box">
            <dt id="max-hp">HP最大値</dt>
            <dd>+@{[input "maxHpAdd",'number','calcMaxHp']}=<b id="max-hp-total"></b></dd>
          </dl>
          <dl class="box">
            <dt id="stock-pt">常備化ポイント</dt>
            <dd>+@{[input "stockAdd",'number','calcStock']}=<b id="stock-total"></b></dd>
          </dl>
          <dl class="box">
            <dt id="saving">財産ポイント</dt>
            <dd>+@{[input "savingAdd",'number','calcSaving']}=<b id="saving-total"></b></dd>
          </dl>
          <dl class="box">
            <dt id="initiative">行動値</dt>
            <dd>+@{[input "initiativeAdd",'number','calcInitiative']}=<b id="initiative-total"></b></dd>
          </dl>
          <dl class="box">
            <dt id="move">戦闘移動</dt>
            <dd>+@{[input "moveAdd",'number','calcMove']}=<b id="move-total"></b></dd>
          </dl>
          <dl class="box">
            <dt id="dash">全力移動</dt>
            <dd><b id="dash-total"></b></dd>
          </dl>
        </div>
      </div>

      <details class="box" id="status" $open{'skill'}>
        <summary>技能 [<span id="exp-skill">0</span>]</summary>
        @{[input 'skillNum','hidden']}
        <table class="edit-table" id="skill-table">
          <thead>
          <tr>
            <th>肉体</th><td id="skill-body"  >0</td>
            <th>感覚</th><td id="skill-sense" >0</td>
            <th>精神</th><td id="skill-mind"  >0</td>
            <th>社会</th><td id="skill-social">0</td>
          </tr>
          </thead>
          <tbody>
          <tr>
            <td class="left">白兵</td><td class="right">@{[input "skillMelee"    ,'number','calcSkill']}+@{[input "skillAddMelee"    ,'number']}</td>
            <td class="left">射撃</td><td class="right">@{[input "skillRanged"   ,'number','calcSkill']}+@{[input "skillAddRanged"   ,'number']}</td>
            <td class="left">ＲＣ</td><td class="right">@{[input "skillRC"       ,'number','calcSkill']}+@{[input "skillAddRC"       ,'number']}</td>
            <td class="left">交渉</td><td class="right">@{[input "skillNegotiate",'number','calcSkill']}+@{[input "skillAddNegotiate",'number']}</td>
          </tr>
          <tr>
            <td class="left">回避</td><td class="right">@{[input "skillDodge"  ,'number','calcSkill']}+@{[input "skillAddDodge"  ,'number']}</td>
            <td class="left">知覚</td><td class="right">@{[input "skillPercept",'number','calcSkill']}+@{[input "skillAddPercept",'number']}</td>
            <td class="left">意思</td><td class="right">@{[input "skillWill"   ,'number','calcSkill']}+@{[input "skillAddWill"   ,'number']}</td>
            <td class="left">調達</td><td class="right">@{[input "skillProcure",'number','calcSkill();calcStock']}+@{[input "skillAddProcure",'number','calcStock']}</td>
          </tr>
HTML
foreach my $num (1 .. $pc{'skillNum'}) {
print <<"HTML";
          <tr>
            <td class="left">@{[input "skillRide${num}Name",'','','list="list-ride"']}</td><td class="right">@{[input "skillRide$num",'number','calcSkill']}+@{[input "skillAddRide$num",'number','calcSkill']}</td>
            <td class="left">@{[input "skillArt${num}Name" ,'','','list="list-art"' ]}</td><td class="right">@{[input "skillArt$num" ,'number','calcSkill']}+@{[input "skillAddArt$num" ,'number','calcSkill']}</td>
            <td class="left">@{[input "skillKnow${num}Name",'','','list="list-know"']}</td><td class="right">@{[input "skillKnow$num",'number','calcSkill']}+@{[input "skillAddKnow$num",'number','calcSkill']}</td>
            <td class="left">@{[input "skillInfo${num}Name",'','','list="list-info"']}</td><td class="right">@{[input "skillInfo$num",'number','calcSkill']}+@{[input "skillAddInfo$num",'number','calcSkill']}</td>
          </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addSkill()">▼</a><a onclick="delSkill()">▲</a></div>
      </details>
      <details class="box" id="lifepath" $open{'lifepath'}>
        <summary>ライフパス</summary>
        <table class="edit-table line-tbody">
          <tbody>
          <tr>
            <th>出自</th>
            <td colspan="2">@{[input "lifepathOrigin"]}</td>
            <td colspan="2" class="left">@{[input "lifepathOriginNote"]}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th>経験</th>
            <td colspan="2">@{[input "lifepathExperience"]}</td>
            <td colspan="2" class="left">@{[input "lifepathExperienceNote"]}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th>邂逅/欲望</th>
            <td colspan="2">@{[input "lifepathEncounter"]}</td>
            <td colspan="2" class="left">@{[input "lifepathEncounterNote"]}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th>覚醒</th>
            <td><select name="lifepathAwaken" oninput="calcEncroach()">@{[option "lifepathAwaken",@awakens]}</select></td>
            <th class="small">侵蝕値</th>
            <td class="center" id="awaken-encroach"></td>
            <td class="left">@{[input "lifepathAwakenNote"]}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th rowspan="2">衝動</th>
            <td><select name="lifepathImpulse" oninput="calcEncroach()">@{[option "lifepathImpulse",@impulses]}</select></td>
            <th class="small">侵蝕値</th>
            <td class="center" id="impulse-encroach"></td>
            <td class="left">@{[input "lifepathImpulseNote"]}</td>
          </tr>
          <tr>
            <th class="small">@{[input "lifepathUrgeCheck",'checkbox']}変異暴走</th>
            <th class="small">効果</th>
            <td class="left" colspan="2">@{[input "lifepathUrgeNote"]}</td>
          </tr>
          </tbody>
          <tbody>
          <tr>
            <th colspan="3" class="right small">その他の修正</th>
            <td class="center">@{[input "lifepathOtherEncroach",'number','calcEncroach']}</td>
            <td class="left">@{[input "lifepathOtherNote"]}</td>
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
      <details class="box" id="lois" $open{'lois'}>
        <summary>ロイス</summary>
        <table class="edit-table" id="lois-table">
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
              <td>@{[input "lois${num}Name"]}</td>
              <td class="emo">@{[input "lois${num}EmoPosiCheck",'checkbox',"emoP($num)"]}@{[input "lois${num}EmoPosi"]}</td>
              <td>／</td>
              <td class="emo">@{[input "lois${num}EmoNegaCheck",'checkbox',"emoN($num)"]}@{[input "lois${num}EmoNega"]}</td>
              <td>@{[input "lois${num}Color",'',"changeLoisColor($num)",'list="list-lois-color"']}</td>
              <td>@{[input "lois${num}Note"]}</td>
              <td onclick="changeLoisState(this.parentNode.id)"><span id="lois${num}-state" data-state="$pc{"lois${num}State"}"></span>@{[input "lois${num}State",'hidden']}</td>
            </tr>
HTML
}
print <<"HTML";
          </tbody>
        </table>
      </details>
      <details class="box" id="memory" $open{'memory'}>
        <summary>メモリー [<span id="exp-memory">0</span>]</summary>
        <table class="edit-table " id="memory-table">
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
      <details class="box" id="effect" $open{'effect'}>
        <summary>エフェクト [<span id="exp-effect">0</span>]</summary>
        @{[input 'effectNum','hidden']}
        <table class="edit-table line-tbody" id="effect-table">
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
              <td>@{[input "effect${num}Encroach",'','','placeholder="侵蝕値"']}</td>
              <td>@{[input "effect${num}Restrict",'','','placeholder="制限" list="list-restrict"']}</td>
            </tr>
            <tr><td colspan="9"><div>
              <b>種別</b><select name="effect${num}Type" oninput="calcEffect()">@{[ option "effect${num}Type",'auto|<自動>','dlois|<Dロイス>','easy|<イージー>','enemy|<エネミー>' ]}</select>
              <b class="small">経験点修正</b>@{[input "effect${num}Exp",'number','calcEffect']}
              <b>効果</b>@{[input "effect${num}Note"]}
            </div></td></tr>
          </tbody>
HTML
}
print <<"HTML";
          <tfoot>
            <tr><th></th><th>名称</th><th>Lv</th><th>タイミング</th><th>技能</th><th>難易度</th><th>対象</th><th>射程</th><th>侵蝕値</th><th>制限</th></tr>
          </thead>
        </table>
        <div class="annotate">
        ※種別「自動」「Dロイス」を選択した場合、取得時（1Lv）の経験点を0として計算します。<br>
        　経験点修正の欄は、自動計算で対応しきれない例外的な取得・成長に使用してください（Dロイス転生者など）
        </div>
        <div class="add-del-button"><a onclick="addEffect()">▼</a><a onclick="delEffect()">▲</a></div>
      </details>
      
      <details class="box" id="combo" $open{'combo'}>
        <summary>コンボ</summary>
        @{[input 'comboNum','hidden']}
        <table class="edit-table line-tbody" id="combo-table">
          <colgroup><col><col><col><col><col><col><col><col><col><col><col><col></colgroup>
HTML
foreach my $num (1 .. $pc{'comboNum'}) {
print <<"HTML";
          <tbody id="combo${num}">
            <tr>
              <td class="handle" rowspan="7"></td>
              <th colspan="3">名称</th><th colspan="8">組み合わせ</th>
            </tr>
            <tr>
              <td colspan="3" class="bold">@{[input "combo${num}Name"]}</td>
              <td colspan="8">@{[input "combo${num}Combo"]}</td>
            </tr>
            <tr><th>タイミング</th><th>技能</th><th>難易度</th><th>対象</th><th>射程</th><th>侵蝕値</th><th>条件</th><th>ダイス</th><th>Ｃ値</th><th>基準値</th><th>攻撃力</th></tr>
            <tr>
              <td>@{[input "combo${num}Timing",'','','list="list-combo-timing"']}</td>
              <td>@{[input "combo${num}Skill",'','','list="list-combo-skill"']}</td>
              <td>@{[input "combo${num}Dfclty",'','','list="list-dfclty"']}</td>
              <td>@{[input "combo${num}Target",'','','list="list-target"']}</td>
              <td>@{[input "combo${num}Range",'','','list="list-range"']}</td>
              <td>@{[input "combo${num}Encroach"]}</td>
              <td>@{[input "combo${num}Condition1"]}</td>
              <td>@{[input "combo${num}Dice1"]}</td>
              <td>@{[input "combo${num}Crit1"]}</td>
              <td>@{[input "combo${num}Fixed1"]}</td>
              <td>@{[input "combo${num}Atk1"]}</td>
            </tr>
            <tr>
              <td rowspan="3" colspan="6"><textarea name="combo${num}Note" rows="4" placeholder="解説">$pc{"combo${num}Note"}</textarea></td>
              <td>@{[input "combo${num}Condition2"]}</td>
              <td>@{[input "combo${num}Dice2"]}</td>
              <td>@{[input "combo${num}Crit2"]}</td>
              <td>@{[input "combo${num}Fixed2"]}</td>
              <td>@{[input "combo${num}Atk2"]}</td>
            </tr>
HTML
  foreach my $i (3 .. 4) {
  print <<"HTML";
            <tr>
              <td>@{[input "combo${num}Condition${i}"]}</td>
              <td>@{[input "combo${num}Dice${i}"]}</td>
              <td>@{[input "combo${num}Crit${i}"]}</td>
              <td>@{[input "combo${num}Fixed${i}"]}</td>
              <td>@{[input "combo${num}Atk${i}"]}</td>
            </tr>
HTML
  }
print <<"HTML";
          </tbody>
HTML
}
print <<"HTML";
        </table>
        <div class="add-del-button"><a onclick="addCombo()">▼</a><a onclick="delCombo()">▲</a></div>
      </details>
      
      <details class="box box-union" id="items" $open{'item'}>
      <summary>アイテム [<span id="exp-item">0</span>]</summary>
      <div class="box">
        @{[input 'weaponNum','hidden']}
        <table class="edit-table" id="weapon-table">
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
        <table class="edit-table" id="armor-table">
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
        <table class="edit-table" id="vehicle-table">
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
        <table class="edit-table" id="item-table">
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
        <details class="annotate">
        <summary>テキスト装飾・整形ルール（クリックで展開）</summary>
        ※メモ欄以外でも有効です。<br>
        太字　：<code>''テキスト''</code>：<b>テキスト</b><br>
        斜体　：<code>'''テキスト'''</code>：<span class="oblique">テキスト</span><br>
        打消線：<code>%%テキスト%%</code>：<span class="strike">テキスト</span><br>
        下線　：<code>__テキスト__</code>：<span class="underline">テキスト</span><br>
        透明　：<code>{{テキスト}}</code>：<span style="color:transparent">テキスト</span><br>
        ルビ　：<code>|テキスト《てきすと》</code>：<ruby>テキスト<rt>てきすと</rt></ruby><br>
        傍点　：<code>《《テキスト》》</code>：<span class="text-em">テキスト</span><br>
        透明　：<code>{{テキスト}}</code>：<span style="color:transparent">テキスト</span>（ドラッグ反転で見える）<br>
        リンク：<code>[[テキスト>URL]]</code><br>
        別シートへのリンク：<code>[テキスト#シートのID]</code><br>
        <hr>
        ※以下は複数行の欄でのみ有効です。<br>
        大見出し：行頭に<code>*</code><br>
        中見出し：行頭に<code>**</code><br>
        少見出し：行頭に<code>***</code><br>
        左寄せ　：行頭に<code>LEFT:</code>：以降のテキストがすべて左寄せになります。<br>
        中央寄せ：行頭に<code>CENTER:</code>：以降のテキストがすべて中央寄せになります。<br>
        右寄せ　：行頭に<code>RIGHT:</code>：以降のテキストがすべて右寄せになります。<br>
        横罫線（直線）：<code>----</code>（4つ以上のハイフン）<br>
        横罫線（点線）：<code> * * * *</code>（4つ以上の「スペース＋アスタリスク」）<br>
        横罫線（破線）：<code> - - - -</code>（4つ以上の「スペース＋ハイフン」）<br>
        表組み　　：<code>|テキスト|テキスト|</code><br>
        定義リスト：<code>:項目名|説明文</code><br>
        　　　　　　<code>:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|説明文2行目</code> 項目名を記入しないか、半角スペースで埋めると上と結合<br>
        コメントアウト：行頭に<code>//</code>：記述した行を非表示にします。
        </details>
      </details>
      
      <details class="box" id="free-history" @{[$pc{'freeHistory'}?'open':'']}>
        <summary>履歴（自由記入）</summary>
        <textarea name="freeHistory">$pc{'freeHistory'}</textarea>
      </details>
      
      <div class="box" id="history">
        <h2>セッション履歴</h2>
        @{[input 'historyNum','hidden']}
        <table class="edit-table lines-tbody" id="history-table">
          <thead>
          <tr>
            <th></th>
            <th>日付</th>
            <th>タイトル</th>
            <th>経験点</th>
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
            <td rowspan="2">@{[input("history${num}Date")]}</td>
            <td rowspan="2">@{[input("history${num}Title")]}</td>
            <td>@{[input("history${num}Exp",'text','calcExp')]}</td>
            <td>@{[input("history${num}Gm")]}</td>
            <td>@{[input("history${num}Member")]}</td>
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
        <table class="example">
          <tr>
            <th>No.</th>
            <th>日付</th>
            <th>タイトル</th>
            <th>経験点</th>
            <th>GM</th>
            <th>参加者</th>
          </tr>
        <tr>
          <td>-</td>
          <td>2020-03-18</td>
          <td>第一話「記入例」</td>
          <td>10+5+1</td>
          <td class="gm">サンプルさん</td>
          <td class="member">鳴瓢秋人　本堂町小春　百貴船太郎　富久田保津</td>
        </tr>
        </table>
        <div class="annotate">
        ※経験点欄は<code>1000+50*2</code>など四則演算が有効です（ファンブル経験点などを分けて書けます）。<br>
        ※成長は欄1つの欄に<code>敏捷生命知力</code>など複数書いても自動計算されます。<br>
        　また、<code>敏捷×2</code><code>知力*3</code>など同じ成長が複数ある場合は纏めて記述できます（×や*は省略できます）。<br>
        　<code>器敏2知3</code>と能力値の頭文字1つで記述することもできます。<br>
        ※成長はリアルタイムでの自動計算はされません。反映するには一度保存してください。
        </div>
      </div>
      
      <div class="box" id="exp-footer">
        <p>
        経験点[<b id="exp-total"></b>] - 
        ( 能力値[<b id="exp-used-status"></b>]
        - 技能[<b id="exp-used-skill"></b>]
        - エフェクト[<b id="exp-used-effect"></b>]
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
        <textarea name="chatPalette" style="height:20em" placeholder="例）&#13;&#10;2d6+{冒険者}+{器用}&#13;&#10;&#13;&#10;※入力がない場合、プリセットがそのまま反映されます。">$pc{'chatPalette'}</textarea>
        
        <div class="palette-column">
        <h2>デフォルト変数 （自動的に末尾に出力されます）</h2>
        <textarea readonly style="height:20em">
HTML
  say $_ foreach(paletteProperties('','all'));
print <<"HTML";
</textarea>
        <p>
          <label>@{[ input 'chatPalettePropertiesAll', 'checkbox']} 全ての変数を出力する</label><br>
          （デフォルトだと、未使用の変数は出力されません）
        </p>
        </div>
        <div class="palette-column">
        <h2>プリセット （コピーペースト用）</h2>
        <textarea id="palettePreset" readonly style="height:20em">@{[ palettePresetRaw(param('type')) ]}</textarea>
        <p><label><input type="checkbox" name="paletteUseVar" @{[ $pc{'paletteUseVar'}?'checked':'' ]} value="1">変数を使う</label></p>
        </div>
      </div>
      </section>
      <section id="section-color" style="display:none;">
      <h2>キャラクターシートのカラー設定</h2>
      <label class="box color-custom">
        <input type="checkbox" name="colorCustom" value="1" onchange="changeColor();" @{[ $pc{'colorCustom'} ? 'checked':'' ]}><i></i>キャラクターシートの色をカスタムする
      </label>
      <span class="box color-custom night-switch" onclick="nightModeChange()"><i></i>ナイトモード</span>
      <div class="box color-custom">
        <h2>見出し背景</h2>
        <table>
        <tr class="color-range-H"><th>色相</th><td><input type="range" name="colorHeadBgH" min="0" max="360" value="$pc{'colorHeadBgH'}" oninput="changeColor();"></td><td id="colorHeadBgHValue">$pc{'colorHeadBgH'}</td></tr>
        <tr class="color-range-S"><th>彩度</th><td><input type="range" name="colorHeadBgS" min="0" max="100" value="$pc{'colorHeadBgS'}" oninput="changeColor();"></td><td id="colorHeadBgSValue">$pc{'colorHeadBgS'}</td></tr>
        <tr class="color-range-L"><th>輝度</th><td><input type="range" name="colorHeadBgL" min="0" max="100" value="$pc{'colorHeadBgL'}" oninput="changeColor();"></td><td id="colorHeadBgLValue">$pc{'colorHeadBgL'}</td></tr>
        </table>
      </div>
      <div class="box color-custom">
        <h2>ベース背景</h2>
        <table>
        <tr class="color-range-H"><th>色相</th><td><input type="range" name="colorBaseBgH"  min="0" max="360" value="$pc{'colorBaseBgH'}" oninput="changeColor();"></td><td id="colorBaseBgHValue">$pc{'colorBaseBgH'}</td></tr>
        <tr class="color-range-S"><th>色の濃さ</th><td><input type="range" name="colorBaseBgS"  min="0" max="100" value="$pc{'colorBaseBgS'}" oninput="changeColor();"></td><td id="colorBaseBgSValue">$pc{'colorBaseBgS'}</td></tr>
        </table>
      </div>
      </section>
      
      
      @{[ input 'birthTime','hidden' ]}
      @{[ input 'id','hidden' ]}
    </form>
HTML
if($mode eq 'edit'){
print <<"HTML";
    <form name="del" method="post" action="./" id="deleteform">
      <p style="font-size: 80%;">
      <input type="hidden" name="mode" value="delete">
      <input type="hidden" name="id" value="$id">
      <input type="hidden" name="pass" value="$pass">
      <input type="checkbox" name="check1" value="1" required>
      <input type="checkbox" name="check2" value="1" required>
      <input type="checkbox" name="check3" value="1" required>
      <input type="submit" value="シート削除"><br>
      ※チェックを全て入れてください
      </p>
    </form>
HTML
}
print <<"HTML";
    </article>
  </main>
  <footer>
    <p class="notes"><span>『ダブルクロスThe 3rd Edition』は、</span><span>は「矢野俊策」及び「有限会社F.E.A.R.」の著作物です。</span></p>
    <p class="copyright">ゆとシートⅡ for DX3rd ver.${main::ver} - ゆとらいず工房</p>
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
  </datalist>
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="その他">
    <option value="不明">
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
  </datalist>
  <datalist id="list-blood">
    <option value="A型"><option value="B型"><option value="AB型"><option value="O型"><option value="不明">
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
    <option value="〈意思〉">
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
    <option value="〈意思〉">
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
  <datalist id="list-restrict">
    <option value="―">
    <option value="ピュア">
    <option value="80%">
    <option value="100%">
    <option value="120%">
    <option value="Dロイス">
    <option value="リミット">
    <option value="RB">
  </datalist>
  <script>
HTML
print 'const synStats = {';
foreach (keys %data::syndrome_status) {
  my @ar = @{$data::syndrome_status{$_}};
  print '"'.$_.'":{"body":'.$ar[0].',"sense":'.$ar[1].',"mind":'.$ar[2].',"social":'.$ar[3].'},'
}
print "};\n";
print 'const awakens = {';
foreach (@data::awakens) {
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