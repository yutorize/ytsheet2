############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use open ":std";
use Encode;

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
if($mode eq 'blanksheet' || $mode eq 'copy'){
  $token = token_make();
  
  if(!$pc{'author'}){
    $pc{'author'} = (getplayername($LOGIN_ID))[0];
  }
}
## 更新後処理 --------------------------------------------------
if($mode eq 'save'){
  $message .= 'データを更新しました。<a href="./?id='.param('id').'">⇒シートを確認する</a>';
  $mode = 'edit';
}
### データ読み込み ###################################################################################
my $id;
my $pass;
my $file;
### 編集時 --------------------------------------------------
if($mode eq 'edit'){
  $id = param('id');
  $pass = param('pass');
  (undef, undef, $file, undef) = getfile($id,$pass,$LOGIN_ID);
  open my $IN, '<', "${set::mons_dir}${file}/data.cgi" or error &login_error;
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
}
if($mode eq 'copy'){
  $id = param('id');
  $file = (getfile_open($id))[0];
  open my $IN, '<', "${set::mons_dir}${file}/data.cgi" or error '魔物データがありません。';
  $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
  close($IN);
  
  delete $pc{'image'};  
  
  $message = '「<a href="./?id='.$id.'" target="_blank">'.$pc{"monsterName"}.'</a>」コピーして新規作成します。<br>（まだ保存はされていません）';
}

### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_mons;

### 出力準備 #########################################################################################
### 初期設定 --------------------------------------------------
$pc{'protect'} = $pc{'protect'} ? $pc{'protect'} : 'password';
$pc{'group'} = $pc{'group'} ? $pc{'group'} : $set::group_default;

$pc{'statusNum'}  = $pc{'statusNum'} ? $pc{'statusNum'} : 1;
$pc{'lootsNum'}   = $pc{'lootsNum'} ? $pc{'lootsNum'} : 2;

### 改行処理 --------------------------------------------------
$pc{'skills'}      =~ s/&lt;br&gt;/\n/g;
$pc{'description'} =~ s/&lt;br&gt;/\n/g;


### フォーム表示 #####################################################################################
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>@{[$mode eq 'edit'?"編集：$pc{'monsterName'}":'新規作成']} - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="./skin/css/base.css?20180910800">
  <link rel="stylesheet" media="all" href="./skin/css/sheet.css?20180910800">
  <link rel="stylesheet" media="all" href="./skin/css/monster.css?20180910800">
  <link rel="stylesheet" media="all" href="./skin/css/monster-sp.css?20180910800">
  <link rel="stylesheet" media="all" href="./skin/css/edit.css?20180910800">
  <link rel="stylesheet" id="nightmode">
  <script src="./skin/js/common.js?201808211430" ></script>
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.3.1/css/all.css" integrity="sha384-mzrmE5qonljUremFsqc01SB46JvROS7bZs3IO2EmfFsd15uHvIt+Y8vEf7N7fWAU" crossorigin="anonymous">
  <style>
    #image {
      background-image: url("${set::char_dir}${file}/image.$pc{'image'}");
    }
    #image > * {
      background: rgba(255,255,255,0.8);
    }
  </style>
</head>
<body>
  <header>
    <h1>$set::title</h1>
  </header>

  <main>
    <article>
      <aside class="message">$message</aside>
      <form id="monster" name="sheet" method="post" action="./" enctype="multipart/form-data">
      <input type="hidden" name="type" value="m">
HTML
if($mode eq 'blanksheet' || $mode eq 'copy'){
  print '<input type="hidden" name="_token" value="'.$token.'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      <div id="area-name">
        <div id="monster-name">
          <div>名称@{[ input 'monsterName','text','','required' ]}</div>
          <div>名前@{[ input 'characterName','text','','placeholder="※名前を持つ魔物のみ"' ]}</div>
        </div>
        <div>
        <p id="update-time"></p>
        <p id="author-name">製作者@{[input('author')]}</p>
        </div>
HTML
if($mode eq 'edit'){
print <<"HTML";
        <input type="button" value="複製" onclick="window.open('./?mode=copy&type=m&id=${id}');">
HTML
}
print <<"HTML";
        <input type="submit" value="保存">
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
  if($set::registerkey && ($mode eq 'blanksheet' || $mode eq 'copy')){
    print '登録キー：<input type="text" name="registerkey" required>'."\n";
  }
  print <<"HTML";
      <div class="box" id="edit-protect">
      <h2 onclick="view('edit-protect-view')">編集保護設定 ▼</h2>
      <p id="edit-protect-view" @{[$mode eq 'edit' ? 'style="display:none"':'']}><input type="hidden" name="protectOld" value="$pc{'protect'}">
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
      </div>
HTML
}
  print <<"HTML";
      <div id="hide-options">
        <p id="forbidden-checkbox">
        @{[ input 'forbidden','checkbox' ]} 閲覧を禁止する
        </p>
        <p id="hide-checkbox">
        @{[ input 'hide','checkbox' ]} 一覧に表示しない<br>
        ※タグ検索結果に合致した場合は表示されます
        </p>
      </div>
      <div class="box" id="group">
        <dl>
          <dt>分類</dt><dd><select name="taxa">
HTML
foreach (@data::taxa){
  print '<option '.($pc{'taxa'} eq @$_[0] ? ' selected': '').'>'.@$_[0].'</option>';
}
print <<"HTML";
          </select></dd>
          <dt>タグ</dt><dd>@{[ input 'tags' ]}</dd>
        </dl>
      </div>
    <div class="box status">
      <dl><dt>レベル</dt><dd>@{[ input 'lv','number','','min="0"' ]}</dd></dl>
      <dl><dt>知能</dt><dd>@{[ input 'intellect','','','list="data-intellect"' ]}</dd></dl>
      <dl><dt>知覚</dt><dd>@{[ input 'perception','','','list="data-perception"' ]}</dd></dl>
      <dl><dt>反応</dt><dd>@{[ input 'disposition','','','list="data-disposition"' ]}</dd></dl>
      <dl><dt>穢れ</dt><dd>@{[ input 'sin','number','','min="0"' ]}</dd></dl>
      <dl><dt>言語</dt><dd>@{[ input 'language' ]}</dd></dl>
      <dl><dt>生息地</dt><dd>@{[ input 'habitat' ]}</dd></dl>
      <dl><dt>知名度／弱点値</dt><dd>@{[ input 'reputation' ]}／@{[ input 'reputation+' ]}</dd></dl>
      <dl><dt>弱点</dt><dd>@{[ input 'weakness','','','list="data-weakness"' ]}</dd></dl>
      <dl><dt>先制値</dt><dd>@{[ input 'initiative' ]}</dd></dl>
      <dl><dt>移動速度</dt><dd>@{[ input 'mobility' ]}</dd></dl>
      <dl><dt>生命抵抗力</dt><dd>@{[ input 'vitResist','number','calcVit' ]} (@{[ input 'vitResistFix','number','calcVitF' ]})</dd></dl>
      <dl><dt>精神抵抗力</dt><dd>@{[ input 'mndResist','number','calcMnd' ]} (@{[ input 'mndResistFix','number','calcMndF' ]})</dd></dl>
    </div>
    <div class="box">
    <table id="status-table" class="status">
      <tr>
        <th>攻撃方法</th>
        <th>命中力</th>
        <th>打撃点</th>
        <th>回避力</th>
        <th>防護点</th>
        <th>ＨＰ</th>
        <th>ＭＰ</th>
      </tr>
HTML
foreach (1 .. $pc{'statusNum'}){
$pc{'status'.$_.'Damage'} = '2d6+' if $pc{'status'.$_.'Damage'} eq '' && $mode eq 'blanksheet';
print <<"HTML";
        <tr>
          <td>@{[ input 'status'.$_.'Style' ]}</td>
          <td>@{[ input 'status'.$_.'Accuracy','number','calcAcc('.$_.')' ]}<br>(@{[ input 'status'.$_.'AccuracyFix','number','calcAccF('.$_.')' ]})</td>
          <td>@{[ input 'status'.$_.'Damage' ]}</td>
          <td>@{[ input 'status'.$_.'Evasion','number','calcEva('.$_.')' ]}<br>(@{[ input 'status'.$_.'EvasionFix','number','calcEvaF('.$_.')' ]})</td>
          <td>@{[ input 'status'.$_.'Defense' ]}</td>
          <td>@{[ input 'status'.$_.'Hp' ]}</td>
          <td>@{[ input 'status'.$_.'Mp' ]}</td>
        </tr>
HTML
}
print <<"HTML";
    </table>
    <div class="add-del-button"><a onclick="addStatus()">▼</a><a onclick="delStatus()">▲</a></div>
    @{[input('statusNum','hidden')]}
    </div>
    <div class="box parts">
      <dl><dt>部位数</dt><dd>@{[ input 'partsNum','number','','min="0"' ]} (@{[ input 'parts' ]}) </dd></dl>
      <dl><dt>コア部位</dt><dd>@{[ input 'coreParts' ]}</dd></dl>
    </div>
    <div class="box">
      <h2>特殊能力</h2>
      <textarea name="skills">$pc{'skills'}</textarea>
      <div class="annotate">
        ※特殊能力の分類マークなどを記述すると自動的に見出し化します。<br>
        　2.0での分類マークでも構いません。また、入力簡易化の為に入力しやすい代替文字での入力も可能です。<br>
        　以下に見出しとして変換される記号を一覧にしています。<br>
        ●：部位見出し：<code>●</code><br>
        <i class="s-icon passive"></i>：常時型　　：<code>○</code> <code>◯</code> <code>〇</code><br>
        <i class="s-icon setup"  ></i>：戦闘準備型：<code>△</code><br>
        <i class="s-icon major"  ></i>：主動作型　：<code>＞</code> <code>▶</code> <code>〆</code><br>
        <i class="s-icon minor"  ></i>：補助動作型：<code>≫</code> <code>&gt;&gt;</code> <code>☆</code><br>
        <i class="s-icon active" ></i>：宣言型　　：<code>🗨</code> <code>□</code> <code>☑</code><br>
      </div>
    </div>
    <div class="box loots">
      <h2>戦利品</h2>
      <dl id="loots-list">
HTML
foreach (1 .. $pc{'lootsNum'}){
print <<"HTML";
        <dt>@{[ input 'loots'.$_.'Num' ]}</dt><dd>@{[ input 'loots'.$_.'Item' ]}</dd>
HTML
}
print <<"HTML";
      </dl>
    <div class="add-del-button"><a onclick="addLoots()">▼</a><a onclick="delLoots()">▲</a></div>
    @{[input('lootsNum','hidden')]}
    </div>
    <div class="box">
      <h2>解説</h2>
      <textarea name="description">$pc{'description'}</textarea>
    </div>
    
      @{[ input 'birthTime','hidden' ]}
      @{[ input 'id','hidden' ]}
    </form>
HTML
if($mode eq 'edit'){
print <<"HTML";
    <form name="del" method="post" action="./" id="deleteform">
      <p>
      <input type="hidden" name="mode" value="delete">
      <input type="hidden" name="type" value="m">
      <input type="hidden" name="id" value="$id">
      <input type="hidden" name="pass" value="$pass">
      <input type="checkbox" name="check1" value="1" required>
      <input type="checkbox" name="check2" value="1" required>
      <input type="checkbox" name="check3" value="1" required>
      <input type="submit" value="シート削除">
      </p>
    </form>
HTML
}
print <<"HTML";
    </article>
  </main>
  <footer>
    『ソード・ワールド2.5』は、「グループSNE」及び「KADOKAWA」の著作物です。<br>
    　ゆとシートⅡ for SW2.5 ver.${main::ver} - ゆとらいず工房
  </footer>
  <datalist id="data-intellect">
  <option value="なし">
  <option value="動物並み">
  <option value="低い">
  <option value="人間並み">
  <option value="高い">
  <option value="命令を聞く">
  </datalist>
  <datalist id="data-perception">
  <option value="五感">
  <option value="五感（暗視）">
  <option value="五感（）">
  <option value="魔法">
  <option value="機械">
  </datalist>
  <datalist id="data-disposition">
  <option value="友好的">
  <option value="中立">
  <option value="敵対的">
  <option value="腹具合による">
  <option value="命令による">
  </datalist>
  <datalist id="data-weakness">
  <option value="命中力+1">
  <option value="物理ダメージ+2点">
  <option value="魔法ダメージ+2点">
  <option value="属性ダメージ+3点">
  <option value="回復効果ダメージ+3点">
  <option value="なし">
  </datalist>
  <script src="./lib/edit-mons.js" ></script>
</body>

</html>
HTML

1;