############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'signatures';
no warnings 'experimental::signatures';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_class;
require $set::data_feats;
require $set::data_races;
require $set::data_items;
require $set::data_faith;

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

  $pc{history0Exp}   = $set::make_exp;
  $pc{history0Honor} = $set::make_honor;
  $pc{history0Money} = $set::make_money;
  $pc{expTotal} = $pc{history0Exp};

  $pc{moneyAuto}   = 1;
  $pc{depositAuto} = 1;

  if($::in{stt}){
    ($pc{sttBaseTec}, $pc{sttBasePhy}, $pc{sttBaseSpi}, $pc{sttBaseA}, $pc{sttBaseB}, $pc{sttBaseC}, $pc{sttBaseD}, $pc{sttBaseE}, $pc{sttBaseF}) = split(/_/, $::in{stt});
    $pc{race} = Encode::decode('utf8', $::in{race});
    if($data::races{$pc{race}}{variant} && !$data::races{$pc{race}}{ability}){
      $pc{race} .= "（$data::races{$pc{race}}{variantSort}[0]）";
    }
    $pc{sin} = $data::races{$pc{race}}{sin} || 0;
    if($::in{making_num}){
      $pc{history0Note} = "能力値作成履歴#$::in{making_num}";
      if($pc{race} eq '魔動天使'){ $pc{raceAbilitySelect1} = '新たな契約の絆' }
    }
    if($data::races{$pc{race}}{parts}){
      foreach my $name (@{$data::races{$pc{race}}{parts}}){
        $pc{partNum}++;
        $pc{"part$pc{partNum}Name"} = $name;
      }
      $pc{partCore} = 1;
    }
  }

  $pc{defTotal1CheckArmour1} = $pc{defTotal1CheckArmour2} = $pc{defTotal1CheckArmour3} = 1;
  $pc{armour2Category} = '盾';
  $pc{armour3Category} = 'その他';

  $pc{paletteUseBuff} = 1;

  %pc = applyCustomizedInitialValues(\%pc, '');
}

## 画像・セリフ位置
setDefaultImageStyle(\%pc);
setDefaultWordsPosition(\%pc);

## カラー
setDefaultColors(\%pc);

## その他
$pc{freeClassNum}    ||= 1;
$pc{commonClassNum}  ||= 10;
$pc{mysticArtsNum}   ||= 0;
$pc{mysticMagicNum}  ||= 0;
$pc{weaponNum}       ||= 1;
$pc{armourNum}       ||= 3;
$pc{defenseTotalNum} ||= 2;
$pc{partNum}         ||= 0;
$pc{languageNum}     ||= 3;
$pc{honorItemsNum}   ||= 3;
$pc{historyNum}      ||= 3;
$pc{cashbookOtherNum}||= 1;
$pc{effectNum}       ||= 1;
$pc{bibliomancyTemporaryNum} ||= 0;

$pc{accuracyEnhance} ||= 0;
$pc{evasiveManeuver} ||= 0;

$pc{unlockZeroData} = 1 if $pc{level} > 15 && !$::SW2_0;

foreach my $name (@data::class_names){
  if ($data::class{$name}{type} eq 'extra' && $pc{'lv'.$data::class{$name}{id}}){
    $pc{unlockRyugai} = 1;
  }
}
my $freeClassOpen;
foreach my $num (1 .. $pc{freeClassNum}){
  if($pc{"freeClass${num}Name"}){ $freeClassOpen = 1; last; }
}

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/items freeNote freeHistory cashbook fellowProfile fellowNote chatPalette/,
  ( map { 'words'.$_ } '', 2 .. ($set::image_maxcount || 1) ),
  ( map { 'chatPaletteInsert'.$_ } 1..$pc{chatPaletteInsertNum} ),
  ( map { 'cashbookOther'    .$_ } 1..$pc{cashbookOtherNum} ),
  ( grep {/^fellow[-0-9]+(?:Action|Note)$/} keys %pc ),
);


### 技能データ各種変換 --------------------------------------------------
## 公式技能
my %baseClassNames;
my %stageClassNames;
foreach my $name (@data::class_names){
  if($data::class{$name}{stage}){
    push(@{$stageClassNames{ $data::class{$name}{stage} }}, $name);
  }
  else {
    push(@{$baseClassNames{ $data::class{$name}{type} || 'other' }}, $name);
  }
}
## 自由記入技能
my %classData; my @allClassNames; my @casterClassNames;
addFreeClassData(\%pc, \%classData, \@allClassNames, \@casterClassNames);
## 武器攻撃が行える技能
my @weaponUsers;
foreach my $name (@allClassNames){
  next if $classData{$name}{type} ne 'weapon-user' && !$classData{$name}{accUnlock};
  push(@weaponUsers, $name);
}
## 武器カテゴリ
my @weaponCategories = map { $_ eq 'ガン' ? ($_, 'ガン（物理）') : $_ } @data::weapon_names;
## 回避が行える技能
my @evasionClasses;
foreach my $name (@allClassNames){
  next if $classData{$name}{type} ne 'weapon-user' && !$classData{$name}{evaUnlock};
  push(@evasionClasses, $name);
}
## 言語
my @langoptionT = ('auto|<○ 自動習得／その他の習得>','listen|<△ 聞き取り限定（通辞の耳飾りなど）>');
my @langoptionR = ('auto|<○ 自動習得／その他の習得>');
foreach my $key (reverse keys %classData) {
  next if !$classData{$key}{language} || !$classData{$key}{language}{any};
  if($classData{$key}{language}{any}{talk}){
    unshift(@langoptionT, "$classData{$key}{id}|<○ ${key}技能による習得>");
  }
  if($classData{$key}{language}{any}{read}){
    unshift(@langoptionR, "$classData{$key}{id}|<○ ${key}技能による習得>");
  }
}

### 影響表 --------------------------------------------------
my @effectNames = map {
  my $name = $_->{name};
  my $label = $name;
  my $notes = $_->{notes};

  $label .= "（$notes）" if $_->{notes};

  "$name|<$label>";

} @set::effects;

my %effects = map { $_->{name} => $_ } @set::effects;

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ( $pc{characterName} || qq|“$pc{aka}”| )),
  systemId => ($::SW2_0 ? 'sw2.0' : 'sw2.5'),
  extraJsMid =>  ($::SW2_0 ? qq|<script src="$::core_dir/lib/sw2.0/edit-chara.js?$::ver" defer></script>| : ''),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>キャラ<span class="shorten">クター</span></span><span>データ</span>
    <li onclick="sectionSelect('fellow');"><span>フェロー</span><span>データ</span>
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

    <div class="box in-toc" id="name-form" data-content-title="キャラクター名・プレイヤー名">
      <div>
        <dl id="character-name">
          <dt>キャラクター名
          <dd>@{[ input 'characterName','text',"setName",'id="main-name"' ]}
        </dl>
        <dl id="aka">
          <dt>二つ名
          <dd>@{[ input 'aka','text',"setName" ]}
          <dt class="ruby">二つ名のフリガナ
          <dd>@{[ input 'akaRuby','text',"setName" ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>プレイヤー名
        <dd>@{[ input 'playerName' ]}
      </dl>
    </div>

    <details class="box" id="regulation" @{[$::mode eq 'edit' ? '':'open']}>
      <summary class="in-toc">作成レギュレーション</summary>
      <dl>
        <dt>経験点
        <dd>@{[ input "history0Exp",'number','changeRegu','step="500"'.($set::make_fix?' readonly':'') ]}
        <dt>所持金
        <dd>@{[ input "history0Money",'number','changeRegu', ($set::make_fix?' readonly':'') ]}
        <dt>名誉点
        <dd>@{[ input "history0Honor",'number','changeRegu', ($set::make_fix?' readonly':'') ]}
        ${\ do {
          if($::SW2_0){
            <<~"HTML";
            <dt>蛮族名誉点
            <dd>@{[ input "history0HonorB",'number','changeRegu', ($set::make_fix?' readonly':'') ]}
            <dt>盟竜点
            <dd>@{[ input "history0HonorD",'number','changeRegu', ($set::make_fix?' readonly':'') ]}
            HTML
          }
        } }
        <dt class="grow">成長
        <dd class="grow">
          <dl class="regulation-grow">
            <dt>器用度<dd>@{[ input "sttPreGrowA",'number','calcStt' ]}
            <dt>敏捷度<dd>@{[ input "sttPreGrowB",'number','calcStt' ]}
            <dt>筋力  <dd>@{[ input "sttPreGrowC",'number','calcStt' ]}
            <dt>生命力<dd>@{[ input "sttPreGrowD",'number','calcStt' ]}
            <dt>知力  <dd>@{[ input "sttPreGrowE",'number','calcStt' ]}
            <dt>精神力<dd>@{[ input "sttPreGrowF",'number','calcStt' ]}
          </dl>
      </dl>
      <ul class="annotate"><li>経験点は、初期所有技能のぶんを含みます。</ul>
      <dl class="regulation-note"><dt>備考<dd>@{[ input "history0Note" ]}</dl>
      <ul class="regulation-others">
        ${\ do {
          if($::SW2_0){
            <<~"HTML";
            <li class="left">@{[ checkbox 'unlockFiveData','『SW2.5』のデータを解禁（一部技能・特技）',"checkStage('2.5',this.checked)" ]}
            HTML
          }
          else {
            <<~"HTML";
            <li class="left">@{[ checkbox 'unlockRyugai','『龍骸諸島』用項目の表示（および一部項目名の変更）',"checkStage('龍骸諸島',this.checked)" ]}
            <li class="left">@{[ checkbox 'unlockDemonoPalace','『魔王宮殿』用項目の表示',"checkStage('魔王宮殿',this.checked)" ]}
            <li class="left">@{[ checkbox 'unlockZeroData','『SW2.0』のデータを解禁（LV16以上、一部技能・特技など）',"checkStage('2.0',this.checked)" ]}
            HTML
          }
        } }
      </ul>
    </details>
    <div id="area-status">
      @{[ renderImageForm() ]}

      <div id="personal" class="in-toc" data-content-title="種族・年齢・性別・穢れ・生まれ・信仰">
        <dl class="box" id="race">
          <dt>種族<dd>@{[ selectInput 'race', 'changeRace(this.value)', @data::race_list ]}
        </dl>
        <dl class="box" id="age">
          <dt>年齢<dd>@{[ input 'age' ]}
        </dl>
        <dl class="box" id="gender">
          <dt>性別<dd>@{[ input 'gender','','','list="list-gender"' ]}
        </dl>
        <dl class="box" id="race-ability">
          <dt>種族特徴
          <dd>
            <span id="race-ability-value">@{[ !$pc{race} ? '' : exists $data::races{$pc{race}} ? $pc{raceAbility} : input("raceAbilityFree",'','changeRaceAbility') ]}</span>
            ${\ do {
              my $i = 1;
              '<span id="race-ability-select">'
              . join('',
                map {
                  ref($_) eq 'ARRAY'
                  ? (
                      qq|<select name="raceAbilitySelect$i" oninput="changeRaceAbility()" class="hidden">| .
                      option('raceAbilitySelect'.$i++, @{$_}) .
                      '</select>'
                    )
                  : ''
                } (
                  @{$data::races{$pc{race}}{ability}},
                  @{$data::races{$pc{race}}{abilityLv6}},
                  @{$data::races{$pc{race}}{abilityLv11}},
                  @{$data::races{$pc{race}}{abilityLv16}},
                )
              )
              . '</span>';
            } }
        </dl>
        <dl class="box" id="sin">
          <dt>穢れ<dd>@{[ input 'sin','number','','min="0"' ]}
        </dl>
        <dl class="box" id="birth">
          <dt>生まれ<dd>@{[ input 'birth' ]}
        </dl>
        <dl class="box" id="faith">
        <dt>信仰<dd class="select-input @{[ ($pc{faith} eq 'その他の信仰') ? 'free' : '' ]}">
        <select name="faith" oninput="changeFaith(this)">
          <option>
          <option @{[ ($pc{faith} eq 'なし') ? ' selected' : '']}>なし
          @{[
            map {
              my $type = $_;
              <<~"OPTGROUP";
              <optgroup label="@{[ ($type eq 1) ? '第一の剣' : ($type eq 3) ? '第三の剣' : ($type eq 2) ? '第二の剣' : 'その他' ]}">
              @{[
                map {
                  my ($sword, $rank, $aka, $name) = @{ $_ };
                  my $value = $aka && $name ? qq|“$aka”$name| :$aka ? qq|“$aka”| : $name;
                  '<option'. (($pc{faith} eq $value)?' selected':'') .">$value";
                }
                grep { $type eq $_->[0] } @data::gods
              ]}
              </optgroup>
              OPTGROUP
            } (1,3,2,0)
          ]}
        </select>@{[ input 'faithOther','text','', ' placeholder="自由記入欄"' ]}</dl>
      </div>

      <div id="status" class="in-toc" data-content-title="能力値">
        <dl class="box" id="stt-base-tec"><dt>技<dd>@{[ input 'sttBaseTec','number','calcStt' ]}</dl>
        <dl class="box" id="stt-base-phy"><dt>体<dd>@{[ input 'sttBasePhy','number','calcStt' ]}</dl>
        <dl class="box" id="stt-base-spi"><dt>心<dd>@{[ input 'sttBaseSpi','number','calcStt' ]}</dl>

        <dl class="box" id="stt-base-A"><dt>Ａ<dd>@{[ input 'sttBaseA','number','calcStt' ]}</dl>
        <dl class="box" id="stt-base-B"><dt>Ｂ<dd>@{[ input 'sttBaseB','number','calcStt' ]}</dl>
        <dl class="box" id="stt-base-C"><dt>Ｃ<dd>@{[ input 'sttBaseC','number','calcStt' ]}</dl>
        <dl class="box" id="stt-base-D"><dt>Ｄ<dd>@{[ input 'sttBaseD','number','calcStt' ]}</dl>
        <dl class="box" id="stt-base-E"><dt>Ｅ<dd>@{[ input 'sttBaseE','number','calcStt' ]}</dl>
        <dl class="box" id="stt-base-F"><dt>Ｆ<dd>@{[ input 'sttBaseF','number','calcStt' ]}</dl>

        <dl class="box" id="stt-grow-A"><dt>成長<dd id="stt-grow-A-value">$pc{sttGrowA}</dl>
        <dl class="box" id="stt-grow-B"><dt>成長<dd id="stt-grow-B-value">$pc{sttGrowB}</dl>
        <dl class="box" id="stt-grow-C"><dt>成長<dd id="stt-grow-C-value">$pc{sttGrowC}</dl>
        <dl class="box" id="stt-grow-D"><dt>成長<dd id="stt-grow-D-value">$pc{sttGrowD}</dl>
        <dl class="box" id="stt-grow-E"><dt>成長<dd id="stt-grow-E-value">$pc{sttGrowE}</dl>
        <dl class="box" id="stt-grow-F"><dt>成長<dd id="stt-grow-F-value">$pc{sttGrowF}</dl>

        <dl class="box" id="stt-dex"><dt>器用度<dd id="stt-dex-value">$pc{sttDex}</dl>
        <dl class="box" id="stt-agi"><dt>敏捷度<dd id="stt-agi-value">$pc{sttAgi}</dl>
        <dl class="box" id="stt-str"><dt>筋力  <dd id="stt-str-value">$pc{sttStr}</dl>
        <dl class="box" id="stt-vit"><dt>生命力<dd id="stt-vit-value">$pc{sttVit}</dl>
        <dl class="box" id="stt-int"><dt>知力  <dd id="stt-int-value">$pc{sttInt}</dl>
        <dl class="box" id="stt-mnd"><dt>精神力<dd id="stt-mnd-value">$pc{sttMnd}</dl>

        <dl class="box" id="stt-add-A"><dt>増強<dd><span id="stt-equip-A-value"></span>@{[ input 'sttAddA','number','calcStt' ]}</dl>
        <dl class="box" id="stt-add-B"><dt>増強<dd><span id="stt-equip-B-value"></span>@{[ input 'sttAddB','number','calcStt' ]}</dl>
        <dl class="box" id="stt-add-C"><dt>増強<dd><span id="stt-equip-C-value"></span>@{[ input 'sttAddC','number','calcStt' ]}</dl>
        <dl class="box" id="stt-add-D"><dt>増強<dd><span id="stt-equip-D-value"></span>@{[ input 'sttAddD','number','calcStt' ]}</dl>
        <dl class="box" id="stt-add-E"><dt>増強<dd><span id="stt-equip-E-value"></span>@{[ input 'sttAddE','number','calcStt' ]}</dl>
        <dl class="box" id="stt-add-F"><dt>増強<dd><span id="stt-equip-F-value"></span>@{[ input 'sttAddF','number','calcStt' ]}</dl>

        <dl class="box" id="stt-bonus-dex"><dt><span>器用度</span><dd id="stt-bonus-dex-value">$pc{bonusDex}</dl>
        <dl class="box" id="stt-bonus-agi"><dt><span>敏捷度</span><dd id="stt-bonus-agi-value">$pc{bonusAgi}</dl>
        <dl class="box" id="stt-bonus-str"><dt><span>筋力  </span><dd id="stt-bonus-str-value">$pc{bonusStr}</dl>
        <dl class="box" id="stt-bonus-vit"><dt><span>生命力</span><dd id="stt-bonus-vit-value">$pc{bonusVit}</dl>
        <dl class="box" id="stt-bonus-int"><dt><span>知力  </span><dd id="stt-bonus-int-value">$pc{bonusInt}</dl>
        <dl class="box" id="stt-bonus-mnd"><dt><span>精神力</span><dd id="stt-bonus-mnd-value">$pc{bonusMnd}</dl>

        <dl class="box" id="stt-pointbuy-TPS">
          <dt>割振りPt.
          <dd id="stt-pointbuy-TPS-value">
        </dl>
        <dl class="box" id="stt-pointbuy-AtoF">
          <dt>割振りPt.
          <dd id="stt-pointbuy-AtoF-value">
        </dl>
        <dl class="box" id="stt-grow-total">
          <dt>成長合計
          <dd><span><span id="stt-grow-total-value"></span><span id="stt-grow-max-value"></span></span>
        </dl>
        <dl class="box" id="stt-pointbuy-type">
          <dt>ポイント割り振りの計算式
          <dd><select name="pointbuyType" onchange="calcStt();">
          <option value="2.5"@{[$pc{pointbuyType} eq '2.5' ? ' selected':'']}>2.5式(ET)</option>
          <option value="2.0"@{[$pc{pointbuyType} eq '2.0' ? ' selected':'']}>2.0式(AW,EX)</option>
          </select>
        </dl>
      </div>

      <div class="box-union in-toc" id="sub-status" data-content-title="ＨＰ・ＭＰ・抵抗力">
        <dl class="box">
          <dt id="vit-resist">生命抵抗力
          <dd><span id="vit-resist-base">$pc{vitResistBase}</span>+<span id="vit-resist-auto-add">$pc{vitResistAutoAdd}</span>+@{[ input 'vitResistAdd','number','calcSubStt' ]}=<b id="vit-resist-total">$pc{vitResistTotal}</b>
        </dl>
        <dl class="box">
        <dt id="mnd-resist">精神抵抗力
        <dd><span id="mnd-resist-base">$pc{mndResistBase}</span>+<span id="mnd-resist-auto-add">$pc{mndResistAutoAdd}</span>+@{[ input 'mndResistAdd','number','calcSubStt' ]}=<b id="mnd-resist-total">$pc{mndResistTotal}</b>
        </dl>
        <dl class="box">
          <dt id="hp">ＨＰ
          <dd><span id="hp-base">$pc{hpBase}</span>+<span id="hp-auto-add">$pc{hpAutoAdd}</span>+@{[ input 'hpAdd','number','calcSubStt' ]}=<b id="hp-total">$pc{hpTotal}</b>
        </dl>
        <dl class="box">
          <dt id="mp">ＭＰ
          <dd><span id="mp-base">$pc{mpBase}</span>+<span id="mp-auto-add">$pc{mpAutoAdd}</span>+@{[ input 'mpAdd','number','calcSubStt' ]}=<b id="mp-total">$pc{mpTotal}</b>
        </dl>
      </div>

      <dl class="box" id="level">
        <dt>冒険者レベル<dd id="level-value">$pc{level}
      </dl>
      <dl class="box" id="exp">
        <dt>経験点<dd><div><span id="exp-rest">$pc{expRest}</span><br>／<br><span id="exp-total">$pc{expTotal}</span></div>
      </dl>
    </div>

    <div id="area-ability">
      <div id="area-classes" class="in-toc" data-content-title="技能">
        <div class="box" id="classes">
          <h2>
            技能
            <small class="notes">使用経験点：<b id="exp-use"></b></small>
          </h2>
          <div class="classes-group" id="classes-weapon-user">
            <h3>戦士系技能</h3>
            <dl class="edit-table side-margin">@{[ map { classInputBox($_) } @{ $baseClassNames{'weapon-user'}} ]}</dl>
          </div>
          <div class="classes-group" id="classes-magic-user">
            <h3>魔法使い系技能</h3>
            <dl class="edit-table side-margin">@{[ map { classInputBox($_) } @{ $baseClassNames{'magic-user'}} ]}</dl>
          </div>
          <div class="classes-group" id="classes-others">
            <h3>その他系技能</h3>
            <dl class="edit-table side-margin">@{[ map { classInputBox($_) } @{ $baseClassNames{'other'}} ]}</dl>
          </div>
          <div class="classes-group" id="classes-stages">
            @{[
              map {
                my $key = $_;
                qq|<div data-stage="$key"><h3>${key}用技能</h3><dl class="edit-table side-margin">|
                . join('', map { classInputBox($_) } @{$stageClassNames{$key}} )
                . '</dl></div>'
              } sort keys %stageClassNames
            ]}
            <div data-stage="2.0" id="classes-seeker">
              <h3>求道者</h3>
              <dl class="edit-table side-margin">
                <dd style="grid-column:span 2">
                <select name="lvSeeker" onchange="calcLv();calcStt();">
                  ${\ do {
                    my $i = 0;
                    join ('',
                      map {
                        qq|<option value="$i"|. ($pc{lvSeeker} eq $i++ ? ' selected':'') .">$_</option>"
                      } @data::seeker_lv
                    );
                  } }
                </select>
                @{[
                  map {
                    qq|<dt id="seeker-buildup${_}" class="right">成長枠追加<dd>|
                    . selectBox("seekerBuildup${_}",'changeLv','戦闘特技','真語魔法','操霊魔法','深智魔法','神聖魔法','妖精魔法','魔動機術','召異魔法','秘奥魔法','練技','呪歌','騎芸','賦術','鼓咆','占瞳','魔装','呪印','貴格')
                    . '</select>'
                  } 1..5
                ]}
              </dl>
            </div>
          </div>
        </div>
        <details class="box" id="free-classes" @{[ $freeClassOpen ? 'open':'' ]}>
          <summary>技能（自由記入）</summary>
          <table class="edit-table side-margin">
            <thead>
              <tr>
                <th>
                <th class="name">技能名
                <th class="lv small">レベル
                <th class="exp small">経験点テーブル
                <th class="battle">戦闘系判定
                <th class="package">判定パッケージ
            <tbody>
              @{[ renderTemplateLoop(
                'free-class',
                sub ($num) {
                  return <<~"ROW";
                  <tr id="free-class-row$num"><td class="handle">
                  <td class="name">@{[ input "freeClass${num}Name",'','changeClassName' ]}
                  <td class="lv"  >@{[ input "freeClass${num}Lv",'number','changeLv','min="0" max="17"' ]}
                  <td class="exp" >@{[ selectBox "freeClass${num}ExpTable",'changeLv','A','B' ]}
                  <td class="battle">
                    @{[ checkbox "freeClass${num}Acc",'命中力','changeLv' ]}
                    @{[ checkbox "freeClass${num}Eva",'回避力','changeLv' ]}
                    @{[ checkbox "freeClass${num}Magic",'魔力','changeLv' ]}
                  <td class="package">
                    @{[ checkbox "freeClass${num}Tec",'技巧','changeLv' ]}
                    @{[ checkbox "freeClass${num}Agi",'運動','changeLv' ]}
                    @{[ checkbox "freeClass${num}Obs",'観察','changeLv' ]}
                    @{[ checkbox "freeClass${num}Kno",'知識','changeLv' ]}
                  ROW
                }
              ) ]}
            </tbody>
          </table>
          @{[ renderAddDelButtons('free-class') ]}
        </details>
        <div class="box" id="common-classes">
          <h2>
            一般技能
            <small class="notes">合計レベル：<b id="cc-total-lv"></b></small>
          </h2>
          <table id="common-classes-table" class="edit-table side-margin">
          <tbody>
            @{[ renderTemplateLoop(
              'common-class',
              sub ($num) {
                return <<~"ROW";
                <tr id="common-class-row${num}"><td class="handle">
                <td>@{[ input "commonClass$num",'','calcCommonClass' ]}
                <td>@{[ input "lvCommon$num", 'number','calcCommonClass','min="0" max="15"' ]}
                ROW
              }
            ) ]}
          </tbody>
          </table>
        @{[ renderAddDelButtons('common-class') ]}
        </div>
      </div>
      <p class="left">@{[ input "failView", "checkbox", "checkFeats()" ]} 習得レベルの足りない項目（特技／練技・呪歌など）も表示する</p>
      <div>
        <div class="box" id="combat-feats">
          <h2 class="in-toc">戦闘特技</h2>
          <ul class="edit-table side-margin">
            @{[
              map {
                my $id = $_;
                my $lv; my $dataset;
                if   ($id =~ /^([0-9]+)[^0-9].*?$/){ $lv = $1; $dataset = $lv.'+' }
                elsif($id =~ /^S/){ $lv = 16; $dataset = '+' }
                else { $lv = $dataset = $id; }

                qq|<li id="combat-feats-lv$id" data-lv="$dataset" |
                . ($pc{"combatFeatsLv$id"} eq 'その他' ? 'free' : '')
                . '">'
                . selectInput("combatFeatsLv$id", 'checkFeats', featsList($id, $lv));
              } setFeatsLvs()
            ]}
          </ul>
          <ul id="combat-feat-vagrants-auto" data-stage="2.5">
            <li id="combat-feat-vagrants-sco5" data-label="スカウト5"  ><select name="combatFeatsExcSco5">@{[ option 'combatFeatsExcSco5', 'def=トレジャーハント','掠め取り','クルードテイク' ]}</select>
            <li id="combat-feat-vagrants-ran5" data-label="レンジャー5"><select name="combatFeatsExcRan5">@{[ option 'combatFeatsExcRan5', 'def=サバイバビリティ','掠め取り','クルードテイク' ]}</select>
            <li id="combat-feat-vagrants-sag5" data-label="セージ5"    ><select name="combatFeatsExcSag5">@{[ option 'combatFeatsExcSag5', 'def=鋭い目','掠め取り','クルードテイク' ]}</select>
          </ul>
          <div class="feats-options">
            <ul>
              <li data-stage="2.5">@{[ input 'featsVagrantsOn','checkbox','checkFeats' ]}<span>ヴァグランツ戦闘特技を追加</span>
              <li>@{[ input 'featsAutoOn','checkbox','checkFeats' ]}<span>特技自動置き換え（非推奨）</span>
            </ul>
          </div>
          <p>置き換え可能な場合<span class="mark">強調</span>されます。</p>
        </div>
        <div class="box" id="seeker-abilities" @{[ display $pc{lvSeeker} ]}>
          <h2>特殊能力（求道者）</h2>
          <ul class="edit-table side-margin">
          @{[
            map {
              <<~"ROW"
              <li id="seeker-ability$_">
                <select name="seekerSkill$_" oninput="checkRace();calcStt();">
                  @{[ option "seekerSkill$_", @data::seeker_abilities ]}
                </select>
              ROW
            } 1 .. 5
          ]}
          </ul>
        </div>
        <div class="box in-toc" id="mystic-arts" data-content-title="秘伝・秘伝魔法">
          <h2>
            秘伝
            <small class="notes">所持名誉点：<b id="honor-value-MA"></b></small>
          </h2>
          <ul id="mystic-arts-list" class="edit-table side-margin">
            @{[ renderTemplateLoop(
              'mystic-arts',
              sub ($num) {
                qq|<li id="mystic-arts-row$num"><span class="handle"></span>《|
                . input('mysticArts'.$num)
                . '》'
                . honorInput('mysticArts'.$num.'Pt')
              }
            ) ]}
          </ul>
          @{[ renderAddDelButtons('mystic-arts') ]}

          <h2>秘伝魔法／地域魔法</h2>
          <ul id="mystic-magic-list" class="edit-table side-margin">
            @{[ renderTemplateLoop(
              'mystic-magic',
              sub ($num) {
                qq|<li id="mystic-magic-row$num"><span class="handle"></span>《|
                . input('mysticMagic'.$num)
                . '》'
                . honorInput('mysticMagic'.$num.'Pt')
              }
            ) ]}
          </ul>
          @{[ renderAddDelButtons('mystic-magic') ]}
        </div>
      </div>
      <div id="crafts">
      @{[
        map {
          my $class = $_;
          my $name = $data::class{$class}{magic}{eName};
          my $Name = ucfirst($name);
          my $jName = $data::class{$class}{magic}{jName};
          my $functions;
          my $min = $data::class{$class}{magic}{trancendOnly} ? 16 : 1;
          if($class eq 'ビブリオマンサー'){ $jName .= "／準備行使枠" }
          <<~"BOX";
          <div class="box" id="magic-${name}">
            <h2 class="in-toc">$jName</h2>
            <ul class="edit-table side-margin">
            @{[
              map {
                '<li id="magic-'.$name.$_.'">'
                . selectInput("magic$Name$_", $functions, craftList("magic$Name", $_, $data::class{$class}{magic}{data}));
              } $min .. 20
            ]}
            </ul>
          </div>
          ${\ do{
            if($class eq 'ビブリオマンサー'){
              <<~"BIBLIO";
              <div class="box" id="magic-bibliomancy-temporary">
                <h2 class="in-toc">秘奥魔法／応急行使枠</h2>
                <ul id="bibliomancy-temporary-list" class="edit-table side-margin">
                  @{[ renderTemplateLoop(
                    'bibliomancy-temporary',
                    sub ($num) {
                      qq|<li id="bibliomancy-temporary-row$num"><span class="handle"></span>|
                      . (selectInput "magicBibliomancyTemporary$num", 'checkBibliomancy',
                          ( map { $_->[1] } @{$data::class{$class}{magic}{data}} ),
                          'その他の1ランクすべて',
                          'その他の2ランクすべて',
                          'その他の3ランクすべて',
                          'その他の4ランクすべて',
                          'その他の5ランクすべて',
                          'その他の2ランク以下すべて',
                          'その他の3ランク以下すべて',
                          'その他の4ランク以下すべて',
                          'その他の5ランク以下すべて'
                        )
                    }
                  ) ]}
                </ul>
                @{[ renderAddDelButtons('bibliomancy-temporary') ]}
              </div>
              BIBLIO
            }
          }}
          BOX
        }
        grep { exists $data::class{$_}{magic}{data} } @data::class_caster
      ]}
      @{[
        map {
          my $class = $_;
          my $name = $data::class{$class}{craft}{eName};
          my $Name = ucfirst($data::class{$class}{craft}{eName});
          my $functions = 'checkCraft();';
          if(exists $data::class{$class}{package}){
            foreach(keys %{$data::class{$class}{package}}){
              if(exists $data::class{$class}{package}{$_}{unlockCraft}){
                $functions .= 'calcPackage();';
                last;
              }
            }
          }
          if($class eq 'フィジカルマスター'){
            $functions .= 'calcParts();calcAttack();calcDefense();'
          }
          if(exists $data::class{$class}{accUnlock} && exists $data::class{$class}{accUnlock}{craft}){
            $functions .= 'calcAttack();'
          }
          if(exists $data::class{$class}{evaUnlock} && exists $data::class{$class}{evaUnlock}{craft}){
            $functions .= 'calcDefense();'
          }
          my $max = 20 + ($class =~ /バード|ウォーリーダー/ ? 3 : $class eq 'アーティザン' ? 2 : 0);
          <<~"BOX";
          <div class="box" id="craft-${name}">
            <h2 class="in-toc">$data::class{$class}{craft}{jName}</h2>
            <ul class="edit-table side-margin">
            @{[
              map {
                '<li id="craft-'.$name.$_.'">'
                . selectInput("craft$Name$_", $functions, craftList("craft$Name", $_, $data::class{$class}{craft}{data}));
              } 1 .. $max
            ]}
            </ul>
          </div>
          BOX
        }
        grep  { exists $data::class{$_}{craft}{data} } @data::class_names
      ]}
      </div>
    </div>

    <div id="area-effects">
      @{[ renderTemplateLoop(
        { id => 'effect', placeholder => 'BOX'},
        sub ($box) {
          my $name = $pc{"effect${box}Name"};
          return <<~"BOX";
          <div id="effect-row${box}" class="box">
            <h2>
              <span class="handle"></span>
              <div class="select-input">
                @{[ selectBox "effect${box}Name","changeEffect(this)",'def=|<各種影響表（穢れや侵蝕など）>',@effectNames ]}
                @{[ input "effect${box}NameFree",'','','placeholder="例: 穢れ＠穢れ度"' ]}
            </h2>
            <dl class="effect-points"><dt>$effects{$name}{pointName}<dd>0</dl>
            <table class="edit-table side-margin">
              <thead>
                <tr>
                  <th>
                  <th class="text">$effects{$name}{header}[0]
                  <th class="num1 @{[ !$effects{$name}{header}[1] && !$effects{$name}{type}[1] ? 'hidden' : '' ]}"><span>$effects{$name}{header}[1]</span>
                  <th class="num2 @{[ !$effects{$name}{header}[2] && !$effects{$name}{type}[2] ? 'hidden' : '' ]}"><span>$effects{$name}{header}[2]</span>
              <tbody>
                @{[ renderTemplateLoop(
                  "effect${box}",
                  sub ($num) {
                    return <<~"ROW";
                    <tr id="effect${box}-row${num}">
                      <td class="handle">
                      <td class="left">@{[ input "effect${box}-${num}",'','',($effects{$name}{fix}[$num-1] ? 'readonly':'') ]}
                      @{[ map {
                        "<td class=\"num${_}\">"
                          . input "effect${box}-${num}Pt${_}", $effects{$name}{type}[$_], 'calcEffect(this)';
                      } 1 .. 2 ]}
                    ROW
                  }
                ) ]}
            </table>
            <div class="add-del-button ignore-sort"><a onclick="addEffect(this)">▼</a><a onclick="delEffect(this)">▲</a></div>
            @{[ input "effect${box}Num",'hidden' ]}
            <ul class="annotate">
              <li>自由記入の場合、表の1行目が項目の見出しになります
            </ul>
          </div>
          BOX
        },
      ) ]}
      <div class="add-del-button ignore-sort">
        <a onclick="addEffectBox()">▼</a><a onclick="delEffectBox()">▲</a>
        @{[ input 'effectNum','hidden' ]}
      </div>
    </div>
    <div class="annotate">
      各種影響表は、閲覧時においては、自由記入以外の表示順は固定されます。
    </div>

    <div id="area-actions">
      <div id="area-package">
        <div class="box" id="package">
          <h2 class="in-toc">@{[ $::SW2_0 ? '非戦闘判定' : '判定パッケージ' ]}</h2>
          <table class="edit-table side-margin">
          @{[
            map {
              my $class = $_;
              my $c_id = $classData{$class}{id};
              my $c_en = $classData{$class}{eName};
              my %data = %{$classData{$class}{package}};
              my $rowspan = keys %data;
              <<~TBODY
              <tbody id="package-$c_en" @{[ $c_id =~ /FC[0-9]+/ ? qq|data-free-class="$class"|:'' ]}@{[ display $pc{"lv$c_id"} ]}>
                <tr><th rowspan="@{[ $rowspan+1 ]}">$class
                @{[
                  map {
                    my $p_id = $_;
                    my $p_name = $data{$p_id}{name} =~ s/(\(.+?\))/<small>$1<\/small>/r;
                    <<~ROW
                    <tr class="@{[ lc $p_id ]}">
                    <th>$p_name
                    <td class="auto small">
                    <td>+@{[ input "pack${c_id}${p_id}Add", 'number','calcPackage' ]} =
                    <td class="total">$pc{"pack${c_id}${p_id}"}
                    ROW
                  } sort{$data{$a}{stt} cmp $data{$b}{stt} || $data{$a} cmp $data{$b}} keys %data
                ]}
              TBODY
            } grep { $classData{$_}{package} } @allClassNames
          ]}
          </table>
        </div>
      </div>
      <div id="area-other-actions">
        <dl class="box" id="monster-lore">
          <dt>魔物知識
          <dd>+@{[ input 'monsterLoreAdd', 'number','calcPackage' ]}=<span id="monster-lore-value">$pc{monsterLore}</span>
        </dl>
        <dl class="box" id="initiative">
          <dt>先制力
          <dd>+@{[ input 'initiativeAdd', 'number','calcPackage' ]}=<span id="initiative-value">$pc{initiative}</span>
        </dl>
        <dl class="box in-toc" id="mobility" data-content-title="移動力">
          <dt>制限移動<dd><b id="mobility-limited">$pc{mobilityLimited}</b> m
          <dt>移動力<dd><span id="mobility-base">$pc{mobilityBase}</span>+@{[ input 'mobilityAdd','number','calcMobility' ]}=<b id="mobility-total">0</b> m
          <dt>全力移動<dd><b id="mobility-full">$pc{mobilityFull}</b> m
        </dl>
      </div>
      <div class="box" id="language">
        <h2 class="in-toc">言語</h2>
        <table class="edit-table side-margin">
          <tr><th><th>会話<th>読文
        </table>
        <dl class="edit-table side-margin" id="language-default">
        @{[
          map {
            '<dt>'.@$_[0]
            .'<dd>'.(@$_[1] ? '○' : '－')
            .'<dd>'.(@$_[2] ? '○' : '－')
          } @{$data::races{ $pc{race} }{language}}
        ]}
        </dl>
        <table class="edit-table side-margin" id="language-table">
          <tbody>
          @{[ renderTemplateLoop(
            'language',
            sub ($num) {
              return <<~"ROW";
              <tr id="language-row$num"><td class="handle"><td>@{[ input "language$num", '', 'checkLanguage', 'list="list-language"' ]}
              <td><select name="language${num}Talk" oninput="checkLanguage()">@{[ option "language${num}Talk",@langoptionT ]}</select><span class="lang-select-view"></span>
              <td><select name="language${num}Read" oninput="checkLanguage()">@{[ option "language${num}Read",@langoptionR ]}</select><span class="lang-select-view"></span>
              ROW
            }
          ) ]}
        </table>
        @{[ renderAddDelButtons('language') ]}
        <p>@{[ input 'languageAutoOff','checkbox','changeRace' ]}初期習得言語を自動記入しない</p>
        <ul id="language-notice" class="annotate notice"></ul>
      </div>
      <div class="box" id="magic-power">
        <h2 class="in-toc" data-content-title="魔法・呪歌・賦術などの基準値">魔法／呪歌／賦術など</h2>
        <table class="edit-table">
          <thead>
          <tr>
            <th><th><th>専用化<th>魔力／奏力<th>行使<small>／演奏など</small><th class="small">ダメージ<br>上昇効果
          <tbody id="magic-consts">
          <tbody>
            <tr id="magic-power-common">
              <td>装備補正など
              <td>全ての魔法
              <td>
              <td>+@{[ input 'magicPowerAdd' ,'number','calcMagic' ]}<span id="magic-power-equip-value" ></span>
              <td>+@{[ input 'magicCastAdd'  ,'number','calcMagic' ]}<span id="magic-cast-equip-value"  ></span>
              <td>+@{[ input 'magicDamageAdd','number','calcMagic' ]}<span id="magic-damage-equip-value"></span>
          <tbody id="magic-power-casterclass">
          @{[
            map {
              my $name = $_;
              my $id    = $data::class{$name}{id};
              my $ename = $data::class{$name}{eName};
              <<~"HTML";
              <tr@{[ display $pc{'lv'.$id} ]} id="magic-power-${ename}">
                <td>${name}
                <td>$data::class{$name}{magic}{jName} @{[ $name eq 'フェアリーテイマー' ? renderFairyContract() : '' ]}
                <td><label>@{[ input 'magicPowerOwn'.$id, 'checkbox','calcMagic' ]}知力+2</label>
                <td>+@{[ input 'magicPowerAdd'.$id,  'number','calcMagic' ]}=<b id="magic-power-${ename}-value">0</b>
                <td>+@{[ input 'magicCastAdd'.$id,   'number','calcMagic' ]}=<b id="magic-cast-${ename}-value" >0</b>
                <td>+@{[ input 'magicDamageAdd'.$id, 'number','calcMagic' ]}=<b id="magic-damage-${ename}-value" >0</b>
              HTML
            }
            grep { $data::class{$_}{magic}{jName} } @data::class_caster
          ]}
          <tbody id="magic-power-freeclass">
          @{[
            map {
              my $num = $_;
              my $id = "FC${num}";
              <<~"HTML";
              <tr id="magic-power-freeclass${num}" data-class-id="$id" data-class-name="$pc{"freeClass${num}Name"}">
                <td>$pc{"freeClass${num}Name"}
                <td>@{[ input 'magicPowerName'.$id,'','calcMagic','placeholder="例: ＊＊魔法"' ]}
                <td><label>@{[ input 'magicPowerOwn'.$id, 'checkbox','calcMagic' ]}知力+2</label>
                <td>+@{[ input 'magicPowerAdd'.$id,  'number','calcMagic' ]}=<b id="magic-power-freeclass${num}-value">0</b>
                <td>+@{[ input 'magicCastAdd'.$id,   'number','calcMagic' ]}=<b id="magic-cast-freeclass${num}-value" >0</b>
                <td>+@{[ input 'magicDamageAdd'.$id, 'number','calcMagic' ]}=<b id="magic-damage-freeclass${num}-value" >0</b>
              HTML
            }
            grep { $pc{'lvFC'.$_} } 1 .. $pc{freeClassNum}
          ]}
          <tbody id="magic-power-hr"><tr><td colspan="8">
          <tbody id="magic-power-otherclass">
          @{[
            map {
              my $name  = $_;
              my $id    = $data::class{$name}{id};
              my $ename = $data::class{$name}{eName};
              <<~"HTML";
              <tr@{[ display $pc{'lv'.$id} ]} id="magic-power-${ename}">
                <td>${name}
                <td>$data::class{$name}{craft}{jName}
                <td><label>@{[ input 'magicPowerOwn'.$id, 'checkbox','calcMagic' ]}$data::class{$name}{craft}{stt}+2</label>
                <td>@{[ $data::class{$name}{craft}{power} ? '+'.input('magicPowerAdd'.$id, 'number','calcMagic')."=<b id=\"magic-power-${ename}-value\">0</b>" : '―' ]}
                <td>+@{[ input 'magicCastAdd'.$id, 'number','calcMagic' ]}=<b id="magic-cast-${ename}-value" >0</b>
                <td>@{[ $data::class{$name}{craft}{power} ? '+'.input('magicDamageAdd'.$id, 'number','calcMagic')."=<b id=\"magic-damage-${ename}-value\">0</b>" : '―' ]}
              HTML
            }
            grep { $data::class{$_}{craft}{stt} } @data::class_names
          ]}
        </table>
      </div>
    </div>

    <div id="area-equipment">
      <div class="box" id="attack-classes">
        <table class="edit-table">
          <thead>
            <tr>
              <th class="name ">技能・特技
              <th class="reqd ">必筋<br>上限
              <th class="acc  ">命中力
              <th class="rate ">
              <th class="crit ">Ｃ値
              <th class="dmg  ">追加Ｄ
            </tr>
          <tbody>
        </table>
      </div>
      <div class="box in-toc" id="weapons" data-content-title="武器">
        <table class="edit-table line-tbody" id="weapons-table">
          <thead id="weapon-head">
            <tr>
              <th class="name ">武器
              <th class="usage">用法
              <th class="reqd ">必筋
              <th class="acc  ">命中力
              <th class="rate ">威力
              <th class="crit ">Ｃ値
              <th class="dmg  ">追加Ｄ
              <th class="own  ">専用
              <th class="cate ">カテゴリ
              <th class="class">使用技能
              <th>
            </tr>
          </thead>
          @{[ renderTemplateLoop(
            'weapon',
            sub ($num) {
              return <<~"ROW";
              <tbody id="weapon-row$num">
                <tr>
                  <td rowspan="2">
                    @{[ input "weapon${num}Name",'','changeWeaponName','placeholder="名称" list="list-weapon-name"' ]}
                    <span class="handle"></span>
                    <dl><dt>部位<dd>@{[ selectBox "weapon${num}Part","calcWeapon",1..$pc{partNum} ]}</dl>
                  <td rowspan="2">@{[ input "weapon${num}Usage","text",'changeWeaponName','list="list-usage"' ]}
                  <td rowspan="2">@{[ input "weapon${num}Reqd",'text','calcWeapon' ]}
                  <td rowspan="2">+@{[ input "weapon${num}Acc",'number','calcWeapon' ]}<b id="weapon${num}-acc-total">0</b>
                  <td rowspan="2">@{[ input "weapon${num}Rate" ]}
                  <td rowspan="2">@{[ input "weapon${num}Crit" ]}
                  <td rowspan="2">+@{[ input "weapon${num}Dmg",'number','calcWeapon' ]}<b id="weapon${num}-dmg-total">0</b>
                  <td>@{[ input "weapon${num}Own",'checkbox','calcWeapon' ]}
                  <td><select name="weapon${num}Category" oninput="calcWeapon()">@{[option("weapon${num}Category",@weaponCategories,'その他|<その他（盾、魔導書など）>')]}</select>
                  <td><select name="weapon${num}Class" oninput="calcWeapon()">@{[option("weapon${num}Class",@weaponUsers,'自動計算しない')]}</select>
                  <td rowspan="2"><span class="button" onclick="addWeapon(${num});setupBracketInputCompletion()">複<br>製</span>
                <tr>
                  <td colspan="3">@{[ input "weapon${num}Note",'','calcWeapon','onchange="changeEquipMod()" placeholder="備考"' ]}
              ROW
            }
          ) ]}
        </table>
        @{[ renderAddDelButtons('weapon') ]}
        <ul class="annotate">
          <li>Ｃ値は自動計算されません。
          <li>備考欄に<code>\@防護点+1</code>や<code>\@回避力+1</code>のように記述すると、<span class="text-em">常時</span>有効な上昇効果が自動計算されます。<br>有効な項目は、装飾品欄と同様です。
          <li>備考欄に<code>〈レッサー・アームスフィアⅠ〉</code>のように記述すると、対応した筋力で計算されます。
          <li id="artisan-annotate" @{[ display $pc{masteryArtisan} ]}>備考欄に<code>〈魔器〉</code>と記入すると魔器習熟が反映されます。
          <li data-race-ability-only="巨人化">備考欄に<code>［巨人化］</code>と記述すると、［巨人化］後の筋力で計算されます。
        </ul>
      </div>
      <div class="box" id="evasion-classes">
        <table class="edit-table">
          <thead>
            <tr>
              <th class="name">技能・特技
              <th class="reqd">必筋<br>上限
              <th class="eva ">回避力
              <th class="def ">防護点
            </tr>
          <tbody>
        </table>
      </div>
      <div class="box in-toc" id="armours" data-content-title="防具">
        <table class="edit-table">
          <thead>
            <tr>
              <th class="type">
              <th class="cate">カテゴリ
              <th class="name">防具
              <th class="reqd">必筋
              <th class="eva ">回避力
              <th class="def ">防護点
              <th class="own ">専用
              <th class="note">備考
            </tr>
          </thead>
          <tbody id="armours-table">
            @{[ renderTemplateLoop(
              'armour',
              sub ($num) {
                return <<~"ROW";
                <tr id="armour-row${num}" data-type="">
                  <th class="type handle">
                  <td><select name="armour${num}Category" oninput="setArmourType();changeArmourName();calcDefense();calcMobility()">@{[ option "armour${num}Category",'金属鎧','非金属鎧','盾','龍骸','その他' ]}</select>
                  <td>@{[ input "armour${num}Name",'','changeArmourName','list="list-item-name"' ]}
                  <td>@{[ input "armour${num}Reqd",'','calcDefense' ]}
                  <td>@{[ input "armour${num}Eva",'number','calcDefense' ]}
                  <td>@{[ input "armour${num}Def",'number','calcDefense' ]}
                  <td>@{[ input "armour${num}Own",'checkbox','calcDefense();calcMobility','disabled' ]}
                  <td>@{[ input "armour${num}Note",'','','onchange="changeEquipMod();calcDefense()"' ]}
                ROW
              }
            ) ]}
          </tbody>
          <tfoot>
            <tr><td colspan="8">
              @{[ renderAddDelButtons('armour') ]}
            <tr>
              <th colspan="2">使用技能
              <th colspan="2" class="small" style="vertical-align:bottom">チェックを入れた防具の数値で合算▼
              <th colspan="2">合計
            @{[ renderTemplateLoop(
              'defense-total',
              sub ($num) {
                return <<~"ROW";
                <tr class="defense-total" id="defense-total-row${num}">
                  <td colspan="2">
                    @{[ selectBox "evasionClass$num","calcDefense", @evasionClasses ]}
                    <dl><dt>部位<dd>@{[ selectBox "evasionPart$num","calcDefense",1..$pc{partNum} ]}</dl>
                  <td colspan="2" class="defense-total-checklist">
                   @{[
                    map {
                      checkbox(
                        "defTotal${num}CheckArmour${_}",
                        ($pc{"armour${_}Name"} =~ s/[|｜](.+?)《(.+?)》/$1/gr =~ s/\[([^\[\]]+?)#[0-9a-zA-z\-]+\]/$1/gr || '―'),
                        'calcDefense',
                        "data-id='armour-row${_}'"
                      )
                    } 1 .. $pc{armourNum}
                  ]}
                  <td id="defense-total${num}-eva">0
                  <td id="defense-total${num}-def">0
                  <td colspan="3">@{[ input "defenseTotal${num}Note",'','','onchange="calcDefense()"' ]}
                ROW
              }
            ) ]}
          </tfoot>
        </table>
        @{[ renderAddDelButtons('defense-total') ]}
        <ul class="annotate">
          <li>防具の備考欄に<code>\@敏捷度-6</code>や<code>\@精神抵抗力+2</code>のように記述すると、<span class="text-em">常時</span>有効な上昇効果が自動計算されます。<br>
            有効な項目は、装飾品欄と同様です。<br>
            <code>\@</code>による修正は合算のチェックに関わらず計算されるため、予備装備や切り替えが想定されるものは注意してください。<br>
          <li data-race-ability-only="巨人化">合計行の備考欄に<code>［巨人化］</code>と記述すると、［巨人化］後の敏捷度で計算されます。
        </ul>
      </div>

      <details class="box-union" id="parts" @{[ $data::races{$pc{race}}{parts} ? 'open':'' ]}>
        <summary class="in-toc">部位</summary>
        <div class="box">
          <table class="edit-table line-tbody">
            <thead>
              <tr>
                <th class="name  ">
                <th class="core small">コア
                <th class="def   ">防護点
                <th class="hp    ">ＨＰ
                <th class="mp    ">ＭＰ
                <th class="note  ">備考
            <tbody>
              @{[ renderTemplateLoop(
                'part',
                sub ($num) {
                  return <<~"ROW";
                  <tr id="part-row${num}">
                    <td class="name  ">@{[ selectInput "part${num}Name","changeParts",'頭部','胴体','上半身','翼','邪眼','蠍','鋏' ]}
                    <td class="core  ">@{[ radio "partCore","deselectable,changeParts",$num ]}
                    <td class="def   "><span class="auto-mod"></span>+@{[ input "part${num}Def","number","changeParts" ]}=<b>0</b>
                    <td class="hp    "><span class="auto-mod"></span>+@{[ input "part${num}Hp" ,"number","changeParts" ]}=<b>0</b>
                    <td class="mp    "><span class="auto-mod"></span>+@{[ input "part${num}Mp" ,"number","changeParts" ]}=<b>0</b>
                    <td class="note  ">@{[ input "part${num}Note" ]}
                  ROW
                }
              ) ]}
            </tbody>
          </table>
          @{[ renderAddDelButtons('part') ]}
        </div>
        <div class="box" id="parts-stt-add">
          <h2>変身時に有効な増強</h2>
          <dl>
            <dt>器用度<dd>@{[ input "sttPartA","number","changeParts" ]}
            <dt>敏捷度<dd>@{[ input "sttPartB","number","changeParts" ]}
            <dt>筋力  <dd>@{[ input "sttPartC","number","changeParts" ]}
            <dt>生命力<dd>@{[ input "sttPartD","number","changeParts" ]}
            <dt>知力  <dd>@{[ input "sttPartE","number","changeParts" ]}
            <dt>精神力<dd>@{[ input "sttPartF","number","changeParts" ]}
          </dl>
          <ul class="annotate"><li>その他部位の計算には通常の増強欄ではなく、こちらの値が適用されます</ul>
        </div>
      </details>

      <div class="box in-toc" id="accessories" data-content-title="装飾品">
        <table class="edit-table">
          <thead>
            <tr>
              <th class="check">
              <th class="type ">
              <th class="name ">装飾品
              <th class="own  ">専用
              <th class="note ">効果
            </tr>
          <tbody id="accessories-table">
          ${ \do {
            my @rows = (
              ["頭","Head"],    ["┗","Head_"],   ["┗","Head__"],
              ["顔","Face"],    ["┗","Face_"],   ["┗","Face__"],
              ["耳","Ear"],     ["┗","Ear_"],    ["┗","Ear__"],
              ["首","Neck"],    ["┗","Neck_"],   ["┗","Neck__"],
              ["背中","Back"],  ["┗","Back_"],   ["┗","Back__"],
              ["右手","HandR"], ["┗","HandR_"],  ["┗","HandR__"],
              ["左手","HandL"], ["┗","HandL_"],  ["┗","HandL__"],
              ["腰","Waist"],   ["┗","Waist_"],  ["┗","Waist__"],
              ["足","Leg"],     ["┗","Leg_"],    ["┗","Leg__"],
              ["他","Other"],   ["┗","Other_"],  ["┗","Other__"],
              ["他2","Other2"], ["┗","Other2_"], ["┗","Other2__"],
              ["他3","Other3"], ["┗","Other3_"], ["┗","Other3__"],
              ["他4","Other4"], ["┗","Other4_"], ["┗","Other4__"],
            );
            my $invisibleHand = $pc{raceAbility} =~ /［見えざる手］/;

            join '', map {
              my ($label, $type) = @{ $_ };

              my $base = $type =~ s/_//r;
              my $show =
                  $label eq '他2' ?  $invisibleHand
                : $label eq '他3' ?  $invisibleHand && $pc{level} >=  6
                : $label eq '他4' ?  $invisibleHand && $pc{level} >= 16
                : $label eq '┗'  ?  $pc{'accessory'.$base.'Add'}
                : 1;

              my $own = $pc{"accessory${type}Own"};

              qq|<tr id="accessory-row$type" data-type="$type" @{[display $show]}><td>|
              . (
                $type =~ /__/
                ? ''
                : qq|<input type="checkbox" name="accessory${type}Add" value="1"|
                  . ($pc{"accessory${type}Add"} ? ' checked' : '')
                  . qq| onChange="addAccessory('$type')">|
              )
              . '</td>'
              . <<~"HTML"
              <th>$label
                <td>@{[input "accessory${type}Name",'','','list="list-item-name"']}
                <td>
                  <select name="accessory${type}Own" oninput="calcSubStt()">
                    <option></option>
                    <option value="HP"@{[$own eq 'HP' ? ' selected' : '']}>HP+2</option>
                    <option value="MP"@{[$own eq 'MP' ? ' selected' : '']}>MP+2</option>
                  </select>
                <td>@{[input "accessory${type}Note",'','','onchange="changeEquipMod()"']}
              HTML

            } @rows
          } }
        </tbody>
        </table>
        <ul class="annotate">
          <li>左のボックスにチェックを入れると欄が一つ追加されます
          <li>
            <code>\@器用度+1</code>や<code>\@防護点+1</code>のように記述すると、<span class="text-em">常時</span>有効な上昇効果が自動計算されます。<br>
            有効な項目は、<code>器用度</code>～<code>精神力</code> <code>生命抵抗力</code> <code>精神抵抗力</code> <code>HP</code> <code>MP</code> <code>回避力</code> <code>防護点</code> <code>移動力</code> <code>魔力</code> <code>行使判定</code> <code>武器必筋上限</code>です。<br>
            同じ項目へは累積するため、同名や効果排他のアイテムには注意してください。<br>
            能力値の増強にかぎり、<code>\@筋力増強+2</code>のように<code>増強</code>の文言を記述することで、能力値ごとに最大の値のみを採用できます。
        </ul>
      </div>
    </div>
    <div id="area-items">
      <div id="area-items-L">
        <dl class="box" id="money">
          <dt class="in-toc">所持金
          <dd>@{[ checkbox 'moneyAuto', '自動計算', 'calcCash' ]}
          <dd>@{[ input 'money' ]} G
          <dt>預金／借金
          <dd>@{[ checkbox 'depositAuto', '自動計算', 'calcCash' ]}
          <dd>@{[ input 'deposit' ]} G
        </dl>
        <div class="box" id="items">
          <h2 class="in-toc">所持品</h2>
          <textarea name="items">$pc{items}</textarea>
        </div>
      </div>
      <div id="area-items-R">
        <div class="box" id="material-cards"@{[ display $pc{lvAlc} ]}>
          <h2 class="in-toc">マテリアルカード</h2>
          <table class="edit-table no-border-cells" >
          <tr><th>  <th>B<th>A<th>S<th>SS
          <tr class="cards-red"><th>赤<td>@{[input 'cardRedB','number']}<td>@{[input 'cardRedA','number']}<td>@{[input 'cardRedS','number']}<td>@{[input 'cardRedSS','number']}
          <tr class="cards-gre"><th>緑<td>@{[input 'cardGreB','number']}<td>@{[input 'cardGreA','number']}<td>@{[input 'cardGreS','number']}<td>@{[input 'cardGreSS','number']}
          <tr class="cards-bla"><th>黒<td>@{[input 'cardBlaB','number']}<td>@{[input 'cardBlaA','number']}<td>@{[input 'cardBlaS','number']}<td>@{[input 'cardBlaSS','number']}
          <tr class="cards-whi"><th>白<td>@{[input 'cardWhiB','number']}<td>@{[input 'cardWhiA','number']}<td>@{[input 'cardWhiS','number']}<td>@{[input 'cardWhiSS','number']}
          <tr class="cards-gol"><th>金<td>@{[input 'cardGolB','number']}<td>@{[input 'cardGolA','number']}<td>@{[input 'cardGolS','number']}<td>@{[input 'cardGolSS','number']}
          </table>
        </div>
        <div class="box" id="battle-items"@{[ display $set::battleitem ]}>
          <h2 class="in-toc">戦闘用アイテム</h2>
          <ul id="battle-items-list">
          @{[ map { qq|<li id="battle-item$_"><span class="handle"></span><input type="text" name="battleItem$_" value="$pc{'battleItem'.$_}">| } 1 .. 16 ]}
          </ul>
        </div>
        ${\ do {
          if($::SW2_0){
            <<~"HTML"
            <dl class="box in-toc" id="honor" data-content-title="名誉点・名誉アイテム">
              <dt>人族名誉点<dd id="honor-value">$pc{honor}
              <dt>蛮族名誉点<dd id="honor-barbaros-value">$pc{honorBarbaros}
              <dt>盟竜点<dd id="honor-dragon-value">$pc{honorDragon}
            </dl>
            HTML
          }
          else {
            <<~"HTML"
            <div class="in-toc" id="honor" data-content-title="名誉点・名誉アイテム">
              <dl class="box"><dt>名誉点<dd id="honor-value">$pc{honor}</dl>
              <div class="box-union">
                <dl class="box" id="adventurer-rank">
                  <dt>冒険者ランク
                  <dd><select name="rank" oninput="calcHonor()">@{[ option "rank",@set::adventurer_rank_name ]}</select>@{[ input 'rankStar','number','calcHonor','min="1"' ]}
                </dl>
                <dl class="box" id="barbaros-rank">
                  <dt>バルバロス栄光ランク
                  <dd><select name="rankBarbaros" oninput="calcHonor()">@{[ option "rankBarbaros",@set::barbaros_rank_name ]}</select>@{[ input 'rankStarBarbaros','number','calcHonor','min="1"' ]}
                </dl>
              </div>
            </div>
            HTML
          }
        } }
        <div class="box honor-items" id="honor-items">
          <h2>名誉アイテム</h2>
          <table class="edit-table side-margin">
            <thead>
              <tr><th><th><th>@{[ $::SW2_0 ? '種別｜点数' : '点数' ]}
            </thead>
            <tbody>
              ${\ do {
                unless($::SW2_0){
                  <<~"HTML"
                  <tr><td class="center" colspan="2">冒険者ランク<td id="rank-honor-value">0
                  <tr><td class="center" colspan="2">バルバロス栄光ランク<td id="rankBarbaros-honor-value">0
                  HTML
                }
              } }
              <tr id="honor-items-mystic-arts"><td class="center" class="center" colspan="2">秘伝／秘伝魔法<td id="mystic-arts-honor-value">0
            <tbody id="honor-items-table">
            @{[ renderTemplateLoop(
              'honor-items',
              sub ($num) {
                return <<~"ROW";
                <tr id="honor-items-row${num}">
                <td class="handle">
                <td>@{[ input "honorItem${num}", "text", '', 'list="list-honor-item"' ]}
                <td>@{[ honorInput ("honorItem${num}Pt") ]}
                ROW
              }
            ) ]}
          </table>
          @{[ renderAddDelButtons('honor-items') ]}
          ${\ do {
            unless($::SW2_0){
              <<~"HTML"
              <p>フリー条件適用可能な（名誉点消費を0点にして良い）場合、<span class="mark">この表示</span>になります。</p>
              <dl class="edit-table side-margin" id="honor-offset">
                <dt>不名誉点相殺    <dd>@{[ input "honorOffset"        , "number", "calcHonor();calcDishonor" ]}
                <dt>不名誉点相殺(蛮族)<dd>@{[ input "honorOffsetBarbaros", "number", "calcHonor();calcDishonor" ]}
              </dl>
              HTML
            }
          } }
        </div>
        ${\ do {
          unless($::SW2_0){
            <<~"HTML"
            <div id="dishonor">
              <dl class="box"><dt>不名誉点<dd id="dishonor-value">$pc{dishonor}</dl>
              <dl class="box"><dt>不名誉称号<dd id="notoriety"></dl>
            </div>
            HTML
          }
        } }
        <div class="box honor-items" id="dishonor-items">
          <h2>@{[ $::SW2_0 ? '消失名誉アイテム' : '不名誉詳細' ]}</h2>
          <table class="edit-table side-margin">
            <thead><tr><th><th><th>点数
            <tbody id="dishonor-items-table">
            @{[ renderTemplateLoop(
              'dishonor-items',
              sub ($num) {
                return <<~"ROW";
                <tr id="dishonor-items-row${num}">
                <td class="handle">
                <td>@{[ input "dishonorItem${num}", "text" ]}
                <td>@{[ honorInput ("dishonorItem${num}Pt") ]}
                ROW
              }
            ) ]}
          </table>
          @{[ renderAddDelButtons('dishonor-items') ]}
        </div>
      </div>
    </div>
    <details class="box" id="cashbook" @{[ $pc{cashbook} || $pc{money} =~ /^(?:自動|auto)$/i ? 'open' : '' ]}>
      <summary class="in-toc">収支履歴</summary>
      <textarea name="cashbook" oninput="calcCash();" placeholder="例）冒険者セット  ::-100&#13;&#10;　　剣のかけら売却::+200">$pc{cashbook}</textarea>
      <p>
        所持金：<span id="cashbook-total-value">$pc{moneyTotal}</span> G
        　預金：<span id="cashbook-deposit-value">－</span> G
        　借金：<span id="cashbook-debt-value">－</span> G
      </p>
      <ul class="annotate">
        <li><code>::+n</code> <code>::-n</code>の書式で入力すると加算・減算されます。（<code>n</code>には金額を入れてください）<br>
          預金は<code>:>+n</code>、借金は<code>:<+n</code>で増減できます。（それに応じて所持金も増減します）
        <li><span class="underline">セッション履歴に記入されたガメル報酬は自動的に加算されます。</span>
        <li>所持金欄、預金／借金欄に<code>自動</code>または<code>auto</code>と記入すると、収支の計算結果を反映します。
      </ul>
    </details>

    <details class="box" id="cashbook-others" @{[ (grep { $pc{"cashbookOther${_}Name"} } 1 .. $pc{cashbookOtherNum}) ? 'open' : '' ]}>
      <summary class="in-toc">収支履歴（任意の通貨・ポイント等）</summary>
      <div id="cashbook-others-list">
        @{[ renderTemplateLoop(
          'cashbook-other',
          sub ($num) {
            return <<~"ROW";
            <div id="cashbook-other${num}" class="cashbook-row">
              <p>
                通貨名称：@{[ input "cashbookOther${num}Name",'','','list="list-currency-name"' ]}
                単位：@{[ input "cashbookOther${num}Unit",'','','list="list-currency-unit"' ]}
              </p>
              <textarea name="cashbookOther${num}" oninput="calcCashOther($num);">$pc{"cashbookOther${num}"}</textarea>
              <p>
                所持：<span id="cashbook-other${num}-total-value">0</span> <span class="cashbook-other${num}-unit"></span>
                　預：<span id="cashbook-other${num}-deposit-value">－</span> <span class="cashbook-other${num}-unit"></span>
                　借：<span id="cashbook-other${num}-debt-value">－</span> <span class="cashbook-other${num}-unit"></span>
              </p>
            </div>
            ROW
          }
        ) ]}
      </div>
      @{[ renderAddDelButtons('cashbook-other') ]}
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
      <table class="edit-table line-tbody no-border-cells" id="history-table">
        <thead id="history-head">
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="exp   ">経験点
            <th class="money ">ガメル
            <th class="honor ">名誉点
            <th class="grow  ">成長
            <th class="gm    ">GM
            <th class="member">参加者
          <tr>
            <td>-
            <td>
            <td>キャラクター作成
            <td id="history0-exp">@{[ commify $pc{history0Exp} ]}
            <td id="history0-money">@{[ commify $pc{history0Money} ]}
            <td id="history0-honor">@{[ commify $pc{history0Honor} ]}
            <td id="history0-grow">$pc{history0Grow}
          </tr>
        @{[ renderTemplateLoop(
          'history',
          sub ($num) {
            return <<~"ROW";
            <tbody id="history-row${num}">
              <tr>
                <td class="handle" rowspan="2">
                <td class="date  " rowspan="2">@{[ input "history${num}Date" ]}
                <td class="title " rowspan="2">@{[ input "history${num}Title" ]}
                <td class="exp   ">@{[ input "history${num}Exp",'text','calcExp' ]}
                <td class="money ">@{[ input "history${num}Money",'text','calcCash' ]}
                <td class="honor ">@{[ honorInput ("history${num}Honor") ]}
                <td class="grow  ">@{[ input "history${num}Grow",'text','calcStt','list="list-grow"' ]}
                <td class="gm    ">@{[ input "history${num}Gm" ]}
                <td class="member">@{[ input "history${num}Member" ]}
              <tr>
                <td colspan="6" class="left">@{[ input "history${num}Note",'','','placeholder="備考"' ]}
            ROW
          }
        ) ]}
        <tfoot id="history-foot">
          <tr>
            <td>
            <td>
            <td>取得総計
            <td id="history-exp-total">
            <td id="history-money-total">
            <td id="history-honor-total">
            <td id="history-grow-total"><span id="history-grow-total-value"></span><span id="history-grow-max-value"></span>
            <td colspan="2">
          <tr>
            <th>
            <th class="date  ">日付
            <th class="title ">タイトル
            <th class="exp   ">経験点
            <th class="money ">ガメル
            <th class="honor ">名誉点
            <th class="grow  ">成長
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
            <th class="exp   ">経験点
            <th class="money ">ガメル
            <th class="honor ">名誉点
            <th class="grow  ">成長
            <th class="gm    ">GM
            <th class="member">参加者
          </tr>
        <tbody>
          <tr>
            <td>-
            <td><input type="text" value="2015-05-01" disabled>
            <td><input type="text" value="第三話「記入例」" disabled>
            <td><input type="text" value="3000+50*3" disabled>
            <td><input type="text" value="100000" disabled>
            <td><input type="text" value="300" disabled>
            <td><input type="text" value="筋力" disabled>
            <td><input type="text" value="サンプルさん" disabled>
            <td><input type="text" value="ウィル　メネル　ルゥ　レイストフ　ゲルレイズ" disabled>
          </tr>
        </tbody>
      </table>
      <ul class="annotate">
        <li>経験点欄は<code>1000+50*2</code>など四則演算が有効です（１ゾロの経験点などを分けて書けます）。
        <li>成長は欄1つの欄に<code>敏捷生命知力</code>など複数書いても自動計算されます。<br>
          また、<code>敏捷×2</code><code>知力*3</code>など同じ成長が複数ある場合は纏めて記述できます（×や*は省略できます）。<br>
          <code>器敏2知3</code>と能力値の頭文字1つで記述することもできます。<br>
      </ul>
      @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
    </div>
  </section>
HTML
### フェロー --------------------------------------------------
print <<HTML;
  <section id="section-fellow" style="display:none;">
    <h2 id="fellow">フェロー関連データ</h2>
    <div class="box" id="f-public">
      @{[ checkbox 'fellowPublic', "フェローを公開する"]}
    </div>
    <div class="box" id="f-checkboxes">
      <dl><dt>経験点
        <dd>@{[ radio "fellowExpCheck","","1","あり" ]}
        <dd>@{[ radio "fellowExpCheck","","0","なし" ]}
      </dl>
      <dl><dt>報酬
        <dd>@{[ radio "fellowRewardCheck","","1","要望" ]}
        <dd>@{[ radio "fellowRewardCheck","","0","不要" ]}
      </dl>
    </div>
    <div class="box" id="f-profile">
      <h2>自己紹介</h2>
      <textarea name="fellowProfile">$pc{fellowProfile}</textarea>
    </div>
    <div class="box" id="f-actions">
      <h2>行動表</h2>
    <table>
      <thead>
      <tr>
        <th>1d
        <th><span class="small">想定出目</span>
        <th>行動
        <th>台詞
        <th>達成値
        <th>効果
      <tbody>
      <tr class="border-top">
        <td rowspan="2">⚀<br>⚁
        <td class="number">7
        <td>@{[ textarea 'fellow1Action','','rows="3"' ]}
        <td>@{[ input 'fellow1Words' ]}
        <td>@{[ input 'fellow1Num' ]}
        <td>@{[ textarea 'fellow1Note','','rows="3"' ]}
      <tr>
        <td class="number">6
        <td>@{[ textarea 'fellow1-2Action','','rows="3"' ]}
        <td>@{[ input 'fellow1-2Words' ]}
        <td>@{[ input 'fellow1-2Num' ]}
        <td>@{[ textarea 'fellow1-2Note','','rows="3"' ]}
      <tr class="border-top">
        <td rowspan="2">⚂<br>⚃
        <td class="number">8
        <td>@{[ textarea 'fellow3Action','','rows="3"' ]}
        <td>@{[ input 'fellow3Words' ]}
        <td>@{[ input 'fellow3Num' ]}
        <td>@{[ textarea 'fellow3Note','','rows="3"' ]}
      <tr>
        <td class="number">5
        <td>@{[ textarea 'fellow3-2Action','','rows="3"' ]}
        <td>@{[ input 'fellow3-2Words' ]}
        <td>@{[ input 'fellow3-2Num' ]}
        <td>@{[ textarea 'fellow3-2Note','','rows="3"' ]}
      <tr class="border-top">
        <td rowspan="2">⚄
        <td class="number">9
        <td>@{[ textarea 'fellow5Action','','rows="3"' ]}
        <td>@{[ input 'fellow5Words' ]}
        <td>@{[ input 'fellow5Num' ]}
        <td>@{[ textarea 'fellow5Note','','rows="3"' ]}
      <tr>
        <td class="number">4
        <td>@{[ textarea 'fellow5-2Action','','rows="3"' ]}
        <td>@{[ input 'fellow5-2Words' ]}
        <td>@{[ input 'fellow5-2Num' ]}
        <td>@{[ textarea 'fellow5-2Note','','rows="3"' ]}
      <tr class="border-top">
        <td rowspan="2">⚅
        <td class="number">10
        <td>@{[ textarea 'fellow6Action','','rows="3"' ]}
        <td>@{[ input 'fellow6Words' ]}
        <td>@{[ input 'fellow6Num' ]}
        <td>@{[ textarea 'fellow6Note','','rows="3"' ]}
      <tr>
        <td class="number">3
        <td>@{[ textarea 'fellow6-2Action','','rows="3"' ]}
        <td>@{[ input 'fellow6-2Words' ]}
        <td>@{[ input 'fellow6-2Num' ]}
        <td>@{[ textarea 'fellow6-2Note','','rows="3"' ]}
      </tr>
    </table>
    </div>
    <div class="box" id="f-note">
      <h2>備考</h2>
      <textarea name="fellowNote">$pc{fellowNote}</textarea>
    </div>
  </section>
HTML
print renderChatPaletteForm();

print renderEditPageEnd(
  notes => '(C)Group SNE「ソード・ワールド'.($::SW2_0 ? '2.0' : '2.5').'」',
  extraHtml => renderDataList(),
);

### サブルーチン #####################################################################################
## 技能入力欄
sub classInputBox {
  my $name = shift;
  return if $data::class{$name}{2.0} && !$set::all_class_on;
  my $id = $data::class{$name}{id};
  my $html;
  $html .= '<dt id="class'.$id.'"';
  $html .= ' data-stage="2.0"' if $data::class{$name}{'2.0'};
  $html .= ' data-stage="2.5"' if $data::class{$name}{'2.5'};
  $html .= '>';
  $html .= $name;
  $html .= '<select name="faithType">'.option('faithType','†|<†セイクリッド系>','‡|<‡ヴァイス系>','†‡|<†‡両系統使用可>').'</select>' if($name eq 'プリースト');
  $html .= '<dd';
  $html .= ' data-stage="2.0"' if $data::class{$name}{'2.0'};
  $html .= ' data-stage="2.5"' if $data::class{$name}{'2.5'};
  $html .= '>' . input("lv${id}", 'number','changeLv','min="0" max="17"');
  return $html;
}
## 名誉点入力欄
sub honorInput {
  my $name = shift;
  if($::SW2_0){
    my @honortypes = ('def=human|<人族名誉点（通常の名誉点）>','barbaros|<蛮族名誉点>','dragon|<盟竜点>');
    return '<span class="honor-pt">'
      .'<select name="'.$name.'Type" oninput="calcHonor()" data-type="human">'
      .(option $name.'Type',@honortypes).'</select>'
      .'<span class="honor-select-view"></span>'
      .(input $name, 'text', 'calcHonor')
      .'</span>';
  }
  else {
    return input($name, 'text', 'calcHonor');
  }
}
## 戦闘特技用配列
sub featsList {
  my ($id, $lv) = @_;

  my $value = $pc{"combatFeatsLv$id"};

  my %typeLabel = (
    '常' => '常時',
    '宣' => '宣言',
    '主' => '主動作',
  );

  my @LINES;
  foreach my $type (qw/常 宣 主/) {
    push @LINES, { label => $typeLabel{$type}.'特技' };

    foreach my $feats (@data::combat_feats){
      my ($fType, $fLv, $fName, $fNotes) = @{ $feats };

      next if $fType !~ /$type/;
      next if $lv < $fLv;
      next if $fNotes =~ /2\.0/ && !$set::all_class_on;
      next if $id =~ /bat/ && $fNotes !~ /バトルダンサー/;

      my $attr;
      if ($fNotes =~ /ヴァグランツ/) {
        $attr = 'class="vagrants"';
        $pc{featsVagrantsOn} = 1 if $value eq $fName;
      }
      elsif ($fNotes =~ /(龍骸諸島|魔王宮殿|2\.0)/) {
        $attr = qq|data-stage="$1"|;
      }

      push @LINES, { value => $fName, attr => $attr };
    }
  }
  push @LINES, { close => 1 };

  return @LINES;
}
## 技芸特技用配列
sub craftList {
  my ($name, $lv, $data) = @_;

  my $value = $pc{"$name$lv"};

  my %groups;
  my @LINES;
  foreach my $d (@{$data}){
    my ($cLv, $cName, $cNotes) = @{ $d };

    next if $lv < $cLv;

    my $attr;
    if ($cNotes =~ /(?:^|,)(2\.0|2\.5)/) {
      $attr = qq|data-stage="$1"|;
    }
    my $group;
    if ($cNotes =~ /(?:^|,)([^,]+?専用)/) {
      $group = $1;
    }

    my $item = { value => $cName, attr => $attr };

    if($group){ push @{ $groups{$group} }, $item; }
    else      { push @LINES, $item; }
  }

  foreach my $key (sort keys %groups) {
    push @LINES, { label => $key, attr => 'data-race-only="'.($key =~ s/専用$//r).'"' };
    push @LINES, $_ foreach (@{ $groups{$key} });
    push @LINES, { close => 1 };
  }

  return @LINES;
}
## 妖精契約
sub renderFairyContract {
  my @elements = (
    [ Earth => '土' ],
    [ Water => '水' ],
    [ Fire  => '炎' ],
    [ Wind  => '風' ],
    [ Light => '光' ],
    [ Dark  => '闇' ],
  );
  my $labels = join "\n", map {
    my ($id, $name) = @{ $_ };
    my $class = lc $id;

    $::SW2_0
      ? qq|<label class="ft-$class"><span>$name</span><br>@{[ input "fairyContract$id",'number','calcFairy','min="0" max="17"' ]}</label>|
      : qq|<label class="ft-$class">@{[ input "fairyContract$id",'checkbox','calcFairy' ]}<span>$name</span></label>|
  } @elements;

  return
    ($::SW2_0
      ? qq|<a id="fairy-sim-url" target="_blank">⇒シミュレータ</a>|
      : qq|<small>ランク</small><b id="fairy-rank"></b>|
    )
    . qq|<div id="fairycontact">$labels</div>|
}
## チャットパレットオプション
sub renderChatPaletteFormOptional {
  require($::core_dir . '/lib/sw2/edit-chara-palette-option.pl');
  return palette::renderChatPaletteFormOptional(\%pc);
}
## サジェスト用リスト
sub renderDataList {
  return <<~"HTML";
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="その他">
    <option value="なし">
    <option value="不明">
    <option value="不詳">
  </datalist>
  <datalist id="list-weapon-name">
    <option value="〈〉">
    <option value="〈〉[刃]">
    <option value="〈〉[打]">
    <option value="〈〉[刃][打]">
    <option value="[魔]〈〉">
    <option value="[魔]〈〉[刃]">
    <option value="[魔]〈〉[打]">
    <option value="[魔]〈〉[刃][打]">
  </datalist>
  <datalist id="list-item-name">
    <option value="〈〉">
    <option value="[魔]〈〉">
  </datalist>
  <datalist id="list-usage">
    <option value="1H">
    <option value="1H#">
    <option value="1H投">
    <option value="1H拳">
    <option value="1H両">
    <option value="1H騎">
    <option value="2H">
    <option value="2H#">
    <option value="2H投">
    <option value="振2H">
    <option value="突2H">
  </datalist>
  <datalist id="list-honor-item">
    <option value="〈〉">
    <option value="【】">
    <option value="《》">
  </datalist>
  <datalist id="list-grow">
    <option value="器用">
    <option value="敏捷">
    <option value="筋力">
    <option value="生命">
    <option value="知力">
    <option value="精神">
  </datalist>
  <datalist id="list-language">
    <option value="交易共通語">
    <option value="地方語（）">
    <option value="神紀文明語">
    <option value="魔法文明語">
    <option value="魔動機文明語">
    <option value="エルフ語">
    <option value="ドワーフ語">
    <option value="グラスランナー語">
    <option value="シャドウ語">
    <option value="ソレイユ語">
    <option value="ミアキス語">
    <option value="リカント語">
    <option value="ドラゴン語">
    <option value="妖精語">
    <option value="海獣語">
    <option value="ヴァルグ語">
    <option value="汎用蛮族語">
    <option value="妖魔語">
    <option value="巨人語">
    <option value="ドレイク語">
    <option value="バジリスク語">
    <option value="ノスフェラトゥ語">
    <option value="マーマン語">
    <option value="ケンタウロス語">
    <option value="ライカンスロープ語">
    <option value="リザードマン語">
    <option value="ハルピュイア語">
    <option value="バルカン語">
    <option value="翼人語">
    <option value="魔神語">
  </datalist>
  <datalist id="list-currency-name">
    <option value="闘技場ポイント">
  </datalist>
  <datalist id="list-currency-unit">
    <option value="P">
    <option value="点">
  </datalist>
  HTML
}

1;
