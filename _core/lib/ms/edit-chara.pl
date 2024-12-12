############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;

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
  
  $pc{level} = 0;
  $pc{endurance} = 20;

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
$pc{historyNum} ||= 3;
$pc{attributeRow} ||= 4;

$pc{paletteTool} ||= 'bcdice';

### 改行処理 --------------------------------------------------
foreach (
  'words',
  'freeNote',
  'freeHistory',
  'chatPalette',
){
  $pc{$_} =~ s/&lt;br&gt;/\n/g;
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
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/ms/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/ms/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/ms/edit-chara.js?${main::ver}" defer></script>
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

      <div class="box in-toc" id="name-form" data-content-title="東京名・プレイヤー名">
        <div>
          <dl id="character-name">
            <dt>東京名
            <dd>@{[input('characterName','text',"setName",'required')]}
            <dt class="ruby">ふりがな
            <dd>@{[input('characterNameRuby','text',"setName")]}
          </dl>
        </div>
        <dl id="player-name">
          <dt>プレイヤー名
          <dd>@{[input('playerName')]}
        </dl>
      </div>

      <!--
      <details class="box" id="regulation" @{[$mode eq 'edit' ? '':'open']} style="display:none">
        <summary>作成レギュレーション</summary>
        <dl>
          <dt>初期成長
          <dd id="level-pre-grow">
          <dt>強度
          <dd>
        </dl>
      </details>
      -->
      
      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}

        <div id="profile" class="box-union in-toc" data-content-title="キャラクターの背景">
          <dl class="box" id="taxa"        ><dt>分類名<dd>@{[ input 'taxa' ]}</dl>
          <dl class="box" id="home"        ><dt>出身地<dd>@{[ input 'home' ]}</dl>
          <dl class="box" id="origin"      ><dt>根源<dd>@{[ input 'origin','','','list="list-origin"' ]}</dl>
          <dl class="box" id="background"  ><dt>経緯<dd>@{[ input 'background','','','list="list-background"' ]}</dl>
          <dl class="box" id="clan-emotion"><dt>クランへの感情<dd>@{[ input 'clanEmotion','','','list="list-clan-emotion"' ]}</dl>
          <dl class="box" id="address"     ><dt>住所<dd>@{[ input 'address','','','list="list-address"' ]}</dl>
        </div>

        <div id="clan" class="box-union in-toc" data-content-title="所属クラン">
          <dl class="box"><dt>所属クラン名<dd>@{[ input 'clan' ]}</dl>
          <dl class="box"><dt>クランシートURL<dd>@{[ input 'clanURL' ]}</dl>
        </div>

        <div id="level" class="box-union in-toc" data-content-title="強度・耐久値">
          <dl class="box"><dt>強度  <dd><b id="level-value">$pc{level}</b></dl>
          <dl class="box"><dt>耐久値<dd>+@{[ input 'enduranceMod','number','calcEndurance' ]}=<b id="endurance-total">$pc{endurance}</b></dl>
        </div>

        <div class="box in-toc" id="status" data-content-title="能力値・特性">
          <dl>
            <dt>能力値
            <dd class="status">
              <dl>
                <dt>身体
                <dd><select name="statusPhysicalBase" oninput="checkStatus()">@{[ option 'statusPhysicalBase',6,4,2 ]}</select>
                <dd class="grow">+成長@{[ input 'statusPhysicalGrow','number' ]}
              </dl>
              <dl>
                <dt>異質
                <dd><select name="statusSpecialBase" oninput="checkStatus()">@{[ option 'statusSpecialBase',6,4,2 ]}</select>
                <dd class="grow">+成長@{[ input 'statusSpecialGrow','number' ]}
              </dl>
              <dl>
                <dt>社会
                <dd><select name="statusSocialBase" oninput="checkStatus()">@{[ option 'statusSocialBase',6,4,2 ]}</select>
                <dd class="grow">+成長@{[ input 'statusSocialGrow','number' ]}
              </dl>
              <div class="annotate caution"></div>
            </dd>
            <dt>特性
            <dd class="attribute">
        @{[input 'attributeRow','hidden']}
HTML
print '<ul id="attribute-physical">';
print '<li>《'.input('attributePhysical'.$_,'','checkAttribute').'》' foreach (1 .. $pc{attributeRow});
print '</ul>';
print '<ul id="attribute-special">';
print '<li>《'.input('attributeSpecial'.$_,'','checkAttribute').'》' foreach (1 .. $pc{attributeRow});
print '</ul>';
print '<ul id="attribute-social">';
print '<li>《'.input('attributeSocial'.$_,'','checkAttribute').'》' foreach (1 .. $pc{attributeRow});
print '</ul>';
print <<"HTML";
              <div class="add-del-button"><a onclick="addAttribute()">▼</a><a onclick="delAttribute()">▲</a></div>
              <div class="annotate caution"></div>
            </dd>
          </dl>
        </div>

      </div>

      <div class="box" id="magi">
        <h2 class="in-toc">マギ</h2>
          <table class="edit-table line-tbody no-border-cells" id="magi-table">
            <colgroup id="magi-col">
              <col class="name  ">
              <col class="timing">
              <col class="target">
              <col class="cond  ">
              <col class="note  ">
            </colgroup>
            <thead id="magi-thead">
              <tr>
                <th class="name  ">名称
                <th class="timing">タイミング
                <th class="target">対象
                <th class="cond  ">条件
                <th class="note  ">効果
HTML
foreach my $num (1 .. 4) {
  print <<"HTML";
            <tbody id="magi${num}">
              <tr>
                <td class="name  ">《@{[ input "magi${num}Name",'','checkMagi' ]}》
                <td class="timing">@{[ input "magi${num}Timing" ,'','','list="list-timing"' ]}
                <td class="target">@{[ input "magi${num}Target" ,'','','list="list-target"' ]}
                <td class="cond  ">@{[ input "magi${num}Cond",'','','list="list-cond"' ]}
                <td class="left">@{[ input "magi${num}Note" ]}
HTML
}
print <<"HTML";
        </table>
        <div class="annotate caution"></div>
      </div>
      
      <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
        <summary class="in-toc">その他<span class="small">（設定・メモなど）</summary>
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
              <th class="level ">強度
              <th class="gm    ">GM
              <th class="member">参加者
            <!--
            <tr>
              <td>-
              <td>
              <td>キャラクター作成
              <td id="history0-exp">$pc{history0Exp}
            -->
HTML
foreach my $num ('TMPL',1 .. $pc{historyNum}) {
  if($num eq 'TMPL'){ print '<template id="history-template">' }
print <<"HTML";
          <tbody id="history-row${num}">
          <tr>
            <td class="handle" rowspan="2">
            <td class="date  " rowspan="2">@{[ input"history${num}Date" ]}
            <td class="title " rowspan="2">@{[ input"history${num}Title" ]}
            <td class="level " rowspan="2">@{[ input"history${num}Level",'','calcLevel' ]}
            <td class="gm    ">@{[ input "history${num}Gm" ]}
            <td class="member">@{[ input "history${num}Member" ]}
          <tr>
            <td colspan="5" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          <tfoot id="history-foot">
            <tr>
              <td>
              <td>
              <td>取得総計
              <td id="history-level-total">
              <td colspan="2">
            <tr>
              <th>
              <th class="date  ">日付
              <th class="title ">タイトル
              <th class="level ">強度
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
              <th class="level ">強度
              <th class="gm    ">GM
              <th class="member">参加者
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>-
              <td><input type="text" value="2017-04-07" disabled>
              <td><input type="text" value="第一話「記入例」" disabled>
              <td>10
              <td class="gm"><input type="text" value="サンプルGM" disabled>
              <td class="member"><input type="text" value="" disabled>
            </tr>
          </tbody>
        </table>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
      </div>
      </section>
      
      @{[ chatPaletteForm( tool => ['bcdice=>その他(BCDice)'], buff => 0 ) ]}
      
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
    <p class="notes">©からすば晴「マモノスクランブル」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
  </footer>
  <datalist id="list-origin">
    <option value="闘争">
    <option value="守護">
    <option value="美学">
    <option value="正裁">
    <option value="奉仕">
    <option value="愛玩">
    <option value="享楽">
    <option value="善行">
    <option value="功名">
    <option value="自罰">
    <option value="究明">
    <option value="無垢">
  </datalist>
  <datalist id="list-background">
    <option value="謎">
    <option value="復讐">
    <option value="成り上がる">
    <option value="安心">
    <option value="守るもの">
    <option value="探しもの">
    <option value="好奇心">
    <option value="生きがい">
    <option value="主のため">
    <option value="大事なもの">
    <option value="取引">
    <option value="連行">
  </datalist>
  <datalist id="list-clan-emotion">
    <option value="どろどろ">
    <option value="警戒心">
    <option value="尽くしたい">
    <option value="くされ縁">
    <option value="劣等感">
    <option value="わくわく">
    <option value="連帯感">
    <option value="安らぎ">
    <option value="ビジネス">
    <option value="信頼">
    <option value="ライバル">
    <option value="責任感">
  </datalist>
  <datalist id="list-address">
    <option value="都心ブロック">
    <option value="副都心ブロック">
    <option value="都区東ブロック">
    <option value="都区南ブロック">
    <option value="都区西ブロック">
    <option value="都下北ブロック">
    <option value="都下南ブロック">
    <option value="都下西ブロック">
  </datalist>
  <datalist id="list-timing">
    <option value="常時">
    <option value="メイン">
    <option value="サブ">
    <option value="ダメージ増加">
    <option value="ダメージ減少">
    <option value="開始">
    <option value="終了">
    <option value="効果参照">
  </datalist>
  <datalist id="list-target">
    <option value="自身">
    <option value="単体">
    <option value="単体">
    <option value="～体">
    <option value="クラン全員">
    <option value="単体（クラン）">
    <option value="効果参照">
  </datalist>
  <datalist id="list-cond">
    <option value="なし">
  </datalist>
  <script>
HTML
print <<"HTML";
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;