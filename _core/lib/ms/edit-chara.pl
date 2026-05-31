############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'signatures';
no warnings 'experimental::signatures';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::data_magi;
require $set::lib_palette_sub;

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{characterName} || $pc{aka} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{playerName} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode eq 'convert' && $pc{ver})){
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
elsif($::mode eq 'blanksheet'){
  $pc{group} = $set::group_default;

  $pc{level} = 0;
  $pc{endurance} = 20;

  %pc = applyCustomizedInitialValues(\%pc, '');
}

## 画像・セリフ位置
setDefaultImageStyle(\%pc);
setDefaultWordsPosition(\%pc);

## カラー
setDefaultColors(\%pc);

## その他
$pc{historyNum} ||= 3;
$pc{attributeRows} ||= 4;

$pc{paletteTool} ||= 'bcdice';

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/words freeNote freeHistory chatPalette/,
);

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ($pc{characterName} || qq|“$pc{aka}”|)),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>キャラ<span class="shorten">クター</span></span><span>データ</span>
    <li onclick="sectionSelect('palette');" class="unit-setting"><span><span class="shorten">ユニット(</span>コマ<span class="shorten">)</span></span><span>設定</span>
  HTML
);
print qq|<aside class="message">$message</aside>| if $message;

print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box" id="group">
      <dl>
        <dt>グループ
        <dd><select name="group">@{[ renderGroupOptions ]}</select>
        <dt>タグ
        <dd>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box" id="support-hub">
      <div class="annotate"><a href="https://karasuba-sei.biz/officialsite/?p=80" target="_blank">⇒キャラクター作成の手順（サポートハブ）</a></div>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="東京名・プレイヤー名">
      <div>
        <dl id="character-name">
          <dt>東京名
          <dd>@{[ input 'characterName','text',"setName",'id="main-name" required' ]}
          <dt class="ruby">ふりがな
          <dd>@{[ input 'characterNameRuby','text',"setName" ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>プレイヤー名
        <dd>@{[ input 'playerName' ]}
      </dl>
    </div>

    <!--
    <details class="box" id="regulation" @{[$::mode eq 'edit' ? '':'open']} style="display:none">
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
      @{[ renderImageForm($pc{imageURL}) ]}

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
            <ul id="attribute-physical">
              @{[ map { '<li>《'.(input "attributePhysical$_",'','checkAttribute').'》' } (1 .. $pc{attributeRows}) ]}
            </ul>
            <ul id="attribute-special">
              @{[ map { '<li>《'.(input "attributeSpecial$_", '','checkAttribute').'》' } (1 .. $pc{attributeRows}) ]}
            </ul>
            <ul id="attribute-social">
              @{[ map { '<li>《'.(input "attributeSocial$_",  '','checkAttribute').'》' } (1 .. $pc{attributeRows}) ]}
            </ul>
            @{[ renderAddDelButtons('attribute','','attributeRows') ]}
            <div class="annotate caution"></div>
          </dd>
        </dl>
        <div class="annotate"><a href="https://karasuba-sei.biz/officialsite/?p=142" target="_blank">⇒特性の例（サポートハブ）</a></div>
      </div>

    </div>

    <div class="box" id="magi">
      <h2 class="in-toc">マギ</h2>
      <table class="edit-table line-tbody no-border-cells" id="magi-table">
        <colgroup id="magi-col">
          <col class="name  ">
          <col class="check ">
          <col class="timing">
          <col class="target">
          <col class="cond  ">
          <col class="note  ">
        </colgroup>
        <thead id="magi-thead">
          <tr>
            <th class="name  ">名前
            <th class="check small nowrap">名前<br>変更
            <th class="timing">タイミング
            <th class="target">対象
            <th class="cond  ">条件
            <th class="note  ">効果
        @{[ map {
          my $num = $_;
          <<~"ROW"
          <tbody id="magi${num}">
            <tr>
              <td class="name  ">
                《@{[ selectBox "magi${num}",'checkMagi',@data::pcMagiNames,'その他' ]}》
                <div class="changed-name hidden">《@{[ input "magi${num}Name",'','','placeholder="任意の名前"' ]}》</div>
              <td class="check ">@{[ checkbox "magi${num}NC",'','checkMagi' ]}
              <td class="timing">@{[ input "magi${num}Timing" ,'','','list="list-timing"' ]}<div class="text-timing"></div>
              <td class="target">@{[ input "magi${num}Target" ,'','','list="list-target"' ]}<div class="text-target"></div>
              <td class="cond  ">@{[ input "magi${num}Cond"   ,'','','list="list-cond"'   ]}<div class="text-cond"></div>
              <td class="left">@{[ input "magi${num}Note" ]}<div class="text-note"></div>
          ROW
        } 1 .. 4 ]}
      </table>
      <div class="annotate caution"></div>
      <div class="annotate"><a href="https://karasuba-sei.biz/officialsite/?p=149#index_id1" target="_blank">⇒PC用マギの一覧（サポートハブ）</a></div>
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
        @{[ renderTemplateLoop(
          'history',
          sub ($num) {
            return <<~"ROW";
            <tbody id="history-row${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td class="date  " rowspan="2">@{[ input"history${num}Date" ]}
              <td class="title " rowspan="2">@{[ input"history${num}Title" ]}
              <td class="level " rowspan="2">@{[ input"history${num}Level",'','calcLevel' ]}
              <td class="gm    ">@{[ input "history${num}Gm" ]}
              <td class="member">@{[ input "history${num}Member" ]}
            <tr>
              <td colspan="5" class="left">@{[ input "history${num}Note",'','','placeholder="備考"' ]}
            ROW
          }
        ) ]}
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
      @{[ renderAddDelButtons('history') ]}
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
HTML
print renderChatPaletteForm( tool => ['bcdice=>その他(BCDice)'], buff => 0 );

print renderEditPageEnd(
  notes => '©からすば晴「マモノスクランブル」',
  multilineTargets => '「容姿・経歴・その他メモ」「履歴（自由記入）」',
  extraHtml => renderDataList(),
);

sub renderDataList {
  return <<~"HTML";
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
  HTML
}

1;
