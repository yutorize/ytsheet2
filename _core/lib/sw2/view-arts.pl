################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
require $::core_dir.'/lib/sw2/data-arts.pl';

### データ／テンプレート読込 #########################################################################
my $magicRecords = magicRecordList();
my $magicNumber;
(my $pcRef, my $SHEET) = setupViewBase(
  unescapeLinesRe   => qr/(?:Effect|Description|Note|QnA)$/,
  unescapeSkipKeys  => [qw/schoolItemList/],
  maskSkipKeys      => ['category'],
  nameSub           => \&setArtsName,
  updateSub => \&upgradeArtsData,
);
our %pc = %{ $pcRef };
$SHEET->param(modeZero => $::SW2_0 ? 1 : 0, magicNumber => $magicNumber);
setRecordViewParams($SHEET, $magicRecords->key, $magicNumber, $pc{magicName});

sub setArtsName {
  my ($pc) = @_;
  if($pc->{category} eq 'magic'){
    # 全体が非公開の場合は、番号の有効・無効を表示しない。
    if(defined $::in{magic} && !($pc->{forbiddenMode} && $pc->{forbidden} eq 'all')){
      my ($magic, $message) = $magicRecords->select($pc, $::in{magic});
      error($message) if !$magic;
      %$pc = %$magic;
      $magicNumber = $::in{magic};
    }
    $pc->{titleName} = $magicRecords->sheetName($pc);
    $pc->{artsName} = $pc->{titleName};
    if($magicRecords->count($pc) == 1){
      my $name = $pc->{magicName};
      (undef, $name) = extractDivineMark($name) if $pc->{magicClass} eq '神聖魔法' && !$pc->{magicMinor};
      $pc->{artsName} = "【$name】";
    }
  }
  elsif($pc->{category} eq 'god'){
    $pc->{artsName} = ($pc->{godAka} ? "“$pc->{godAka}”" : "").$pc->{godName};
    $pc->{titleName} = $pc->{artsName};
  }
  elsif($pc->{category} eq 'school'){
    $pc->{artsName} = '【'.$pc->{schoolName}.'】';
    $pc->{titleName} = $pc->{schoolName};
  }
  elsif($pc->{category} eq 'skill'){
    $pc->{artsName} = "「$pc->{skillName}」";
    $pc->{titleName} = $pc->{skillName};
  }
  $pc->{encodedNameLetter} = $pc->{artsName};
}

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{tags} = '';
  }
  ## 魔法
  unless($forbidden eq 'battle'){
    $pc->{magicPageTitle} = '';
    $pc->{magicDescription} = '';
    delete $pc->{head_magicDescription};
    foreach(1..int(rand 3)+3){
      $pc->{magicDescription} .= noiseText(18,50)."<br>";
    }
  }

  $pc->{magicClass} = noiseText(3,14);

  foreach my $recordPrefix ($magicRecords->prefixes($pc)){
    my $prefix = $recordPrefix.'magic';
    $pc->{"${prefix}Name"}     = noiseText(6,14) if $forbidden ne 'battle';
    $pc->{"${prefix}Level"}    = noiseText(2);
    $pc->{"${prefix}Cost"}     = noiseText(3,4);
    $pc->{"${prefix}Target"}   = noiseText(2,14);
    $pc->{"${prefix}Range"}    = noiseText(2,4);
    $pc->{"${prefix}Form"}     = noiseText(2,4);
    $pc->{"${prefix}Duration"} = noiseText(2,9);
    $pc->{"${prefix}Resist"}   = noiseText(2);
    $pc->{"${prefix}Element"}  = noiseText(1,6);
    $pc->{"${prefix}Summary"}  = noiseText(8,25);
    $pc->{"${prefix}ActionType$_"} = 0 foreach qw/Passive Major Minor Setup/;
    $pc->{"${prefix}Effect"} = '';
    foreach(1..int(rand 3)+2){
      $pc->{"${prefix}Effect"} .= noiseText(18,40)."<br>";
    }
    delete $pc->{"head_${prefix}Effect"};
    $pc->{"${prefix}Magisphere"} = noiseText(1,3);

    foreach my $num (1..($pc->{"${prefix}DataNum"} || 0)){
      $pc->{"${prefix}Data${num}Label"} = noiseText(2,8);
      $pc->{"${prefix}Data${num}Value"} = noiseText(3,14);
    }
  }

  ## 神格
  unless($forbidden eq 'battle'){
    $pc->{godName}   = noiseText(2,12);
    $pc->{godAka}    = noiseText(2,5);
    $pc->{godClass}  = noiseText(3);
    $pc->{godRank}   = noiseText(2,3);
    $pc->{godArea}   = noiseText(5,10);

    $pc->{godSymbol} = '';
    foreach(1..int(rand 3)+2){ $pc->{godSymbol} .= noiseText(18,40)."<br>"; }
    $pc->{godDeity} = '';
    foreach(1..int(rand 5)+8){ $pc->{godDeity} .= noiseText(18,40)."<br>"; }
    foreach(1..3){ $pc->{"godMaxim".$_} .= noiseText(8,30); }
  }
  foreach my $lv (2,4,7,10,13){
    $pc->{"godMagic${lv}Name"}     = noiseText(3,14);
    $pc->{"godMagic${lv}Cost"}     = noiseText(3,4);
    $pc->{"godMagic${lv}Target"}   = noiseText(2,14);
    $pc->{"godMagic${lv}Range"}    = noiseText(2,4);
    $pc->{"godMagic${lv}Form"}     = noiseText(2,4);
    $pc->{"godMagic${lv}Duration"} = noiseText(2,9);
    $pc->{"godMagic${lv}Resist"}   = noiseText(2);
    $pc->{"godMagic${lv}Element"}  = noiseText(1,6);
    $pc->{"godMagic${lv}Summary"}  = noiseText(8,25);
    $pc->{"godMagic${lv}ActionTypeMinor"} = 0;
    $pc->{"godMagic${lv}ActionTypeSetup"} = 0;
    $pc->{"godMagic${lv}Effect"} = '';
    foreach(1..int(rand 3)+2){
      $pc->{"godMagic${lv}Effect"} .= noiseText(18,40)."<br>";
    }
  }
  ## 流派
  unless($forbidden eq 'battle'){
    $pc->{schoolName} = noiseText(2,12);
    $pc->{schoolArea} = noiseText(5,10);
    $pc->{schoolReq}  = noiseText(5,10);
    $pc->{schoolNote} = '';
    foreach(1..int(rand 5)+5){
      $pc->{schoolNote} .= noiseText(18,40)."<br>";
    }
    $pc->{schoolItemNote} = '';
    foreach(1..int(rand 3)+1){
      $pc->{schoolItemNote} .= noiseText(18,40)."<br>";
    }
  }
  $pc->{schoolArtsNote} = '';
  foreach(1..int(rand 2)+1){
    $pc->{schoolArtsNote} .= noiseText(18,40)."<br>";
  }
  $pc->{"schoolArtsNum"} = 3;
  foreach my $num (1..3){
    $pc->{"schoolArts${num}Name"} = noiseText(3,14);
    $pc->{"schoolArts${num}Type"} = noiseText(3,9);
    $pc->{"schoolArts${num}Premise"} = noiseText(3,9);
    $pc->{"schoolArts${num}Equip"} = noiseText(3,9);
    $pc->{"schoolArts${num}Use"} = noiseText(3,9);
    $pc->{"schoolArts${num}Apply"} = noiseText(3,9);
    $pc->{"schoolArts${num}Risk"} = noiseText(3,9);
    $pc->{"schoolArts${num}Summary"} = noiseText(6,16);
    $pc->{"schoolArts${num}Effect"} = '';
    foreach(1..int(rand 3)+2){
      $pc->{"schoolArts${num}Effect"} .= noiseText(18,40)."<br>";
    }
  }
  $pc->{"schoolMagicNum"} = 0;
  ## 特殊能力
  unless($forbidden eq 'battle'){
    $pc->{skillName} = noiseText(2,12);
  }
  foreach('Passive','Minor','Setup','Major'){ $pc->{"skillAction$_"} = 0; }
  $pc->{skillResist} = noiseText(2);
  $pc->{skillActionBaseValue} = noiseText(13,14);
  $pc->{skillResistBaseValue} = noiseText(5);
  $pc->{skillRankMode} = 0;
  $pc->{skillRankB_summary} = noiseText(6,16);
  $pc->{skillRankB_effect} = '';
  foreach(1..int(rand 3)+2){
    $pc->{skillRankB_effect} .= noiseText(18,40)."<br>";
  }
}

### カテゴリ別 --------------------------------------------------
if($pc{category} eq 'magic'){
  $SHEET->param(categoryMagic => 1);
}
elsif($pc{category} eq 'god'){
  $SHEET->param(categoryGod => 1);
  $SHEET->param(wideMode => 1);
}
elsif($pc{category} eq 'school'){
  $SHEET->param(categorySchool => 1);
  $SHEET->param(wideMode => 1);
}
elsif($pc{category} eq 'skill'){
  $SHEET->param(categorySkill => 1);
}

### 魔法 --------------------------------------------------
if($pc{category} eq 'magic'){
  my @numbers = $magicRecords->order(\%pc);
  my $multiple = @numbers > 1;
  my $sheetURL = $pc{modeDownload} ? undef : recordSheetURL();
  if($multiple){
    $SHEET->param(multipleMagics => 1, magicPageName => renderCharacterName($magicRecords->sheetName(\%pc)));
  }
  if(defined $magicNumber && defined $sheetURL){
    $SHEET->param(magicSheetURL => $sheetURL);
  }
  my @magics;
  foreach my $index (0 .. $#numbers){
    my $prefix = $magicRecords->prefix($index + 1).'magic';
    my $magic = magicViewData($prefix, 'magic');
    if($multiple){
      $magic->{RecordNumber} = $numbers[$index];
      $magic->{TocName} = removeTags removeRuby $magic->{Name};
      $magic->{SingleViewURL} = "$sheetURL&magic=$numbers[$index]" if defined $sheetURL;
    }
    $magic->{HeadEffect} = $pc{"head_${prefix}Effect"};
    push @magics, $magic;
  }
  $SHEET->param(Magics => \@magics);
}

# 接頭辞を外した表示データを返し、通常魔法と秘伝魔法で共有する。
sub magicViewData {
  my ($prefix, $classPrefix) = @_;
  my %magic = map { substr($_, length $prefix) => $pc{$_} }
    grep { /^\Q$prefix\E[A-Z]/ } keys %pc;
  my $icon = '';
  my $isSchool = !defined $classPrefix;
  $classPrefix //= $prefix;
  my $className = $pc{"${classPrefix}Class"};
  my $class = data::arts::baseClass($className);
  if($pc{"${classPrefix}DataCustom"} || $class eq '騎芸' || $class eq '操気'){
    if($magic{ActionTypePassive}){ $icon .= '<i class="s-icon passive"><span class="raw">[常]</span></i>' }
    if($magic{ActionTypeMajor}  ){ $icon .= '<i class="s-icon major"><span class="raw">[主]</span></i>' }
  }
  if($magic{ActionTypeMinor}  ){ $icon .= ($isSchool ? '<i class="s-icon minor">≫</i>' : '<i class="s-icon minor"><span class="raw">[補]</span></i>') }
  if($magic{ActionTypeSetup}  ){ $icon .= ($isSchool ? '<i class="s-icon setup">△</i>' : '<i class="s-icon setup"><span class="raw">[準]</span></i>') }

  my $magicName = $magic{Name};
  (my $divineMark, $magicName) = extractDivineMark $magicName if $isSchool || ($className eq '神聖魔法' && !$pc{magicMinor});
  my $alias;
  if($magicName =~ s/\s?[－―‐–—─\-](.+?)[－―‐–—─\-]$//){ $alias = "－$1－" }

  $magic{Icon} = $icon;
  $magic{Name} = renderCharacterName $magicName;
  $magic{Alias} = $alias;
  $magic{DivineMark} = $divineMark;
  $magic{Target} = textMagic($magic{Target});
  $magic{Duration} = textMagic($magic{Duration});

  $magic{ClassEn} = data::arts::layout($class);
  my ($rows,$extras,$notes) = magicDataViewRows($prefix,$class,$classPrefix);
  $magic{DataRows} = $rows;
  $magic{ExtraDataRows} = $extras;
  $magic{NameNotes} = $notes;

  $magic{Effect} = $magic{Effect} =~ s#<h2>(.+?)</h2>#</dd><dt><span class="center">$1</span></dt><dd class="box">#gir;
  return \%magic;
}
sub textMagic {
  $_[0] =~ s#／#／<wbr>#;
  return $_[0];
}
sub textSongPoint {
  $_[0] =~ s#[⤴↺↑]#<i class="s-icon uplift">⤴</i>#g;
  $_[0] =~ s#[⤵↴↷↓]#<i class="s-icon calm">⤵</i>#g;
  $_[0] =~ s#[♡♥❤]#<i class="s-icon heart">♡</i>#g;
  return '<span>'.$_[0].'</span>';
}
# 項目名は固定の対応表でクラスへ変換し、独自名をCSSに直接埋め込まない。
sub magicDataViewRows {
  my ($prefix,$class,$classPrefix) = @_;
  my $layout = data::arts::layout($class);
  my $ids = $layout ? data::arts::preset($class,0) : data::arts::schema()->{default};
  my %allowed = map { data::arts::fieldDefinition($_)->{class} => 1 } @$ids;
  $allowed{element} = 1 if !$layout || $layout eq 'psychokinesis';
  my $items = data::arts::rows(\%pc,$prefix,$classPrefix);
  my $custom = $pc{"${classPrefix}DataCustom"};
  if($custom){
    my @group = qw/Target Range Duration Resist/;
    my %present = map { (data::arts::fieldId($_->{Label}) // '') => 1 } @$items;
    # 自由記入で4項目が揃わない場合は、通常の配置を使わず追加欄にまとめる。
    if(grep { !$present{$_} } @group){
      delete $allowed{ data::arts::fieldDefinition($_)->{class} } foreach @group;
    }
  }
  my (@rows,@extras,%seen,$notes);
  foreach my $item (@$items){
    my ($label,$value) = @{$item}{'Label','Value'};
    next if $label eq '' && $value eq '';
    my $id = data::arts::fieldId($label);
    my $css = $id ? data::arts::fieldDefinition($id)->{class} : 'custom';
    if($id && $id eq 'Magisphere' && ($classPrefix eq 'magic' || $class ne '') && !$seen{sphere}++){
      $notes = "$label:$value";
      next;
    }
    if($id && $id eq 'Element'){
      next if !$custom && $value eq '' && $class !~ /^(?:呪歌|終律|相域)$/;
      $value = '―' if $value eq '';
    }
    if($id && ($id eq 'Target' || $id eq 'Range' || $id eq 'Duration')){ $value = textMagic($value); }
    if($id && ($id =~ /^Song(?:Base|Add)Point$/ || ($id eq 'Condition' && ($class eq '呪歌' || $label eq '効果発生条件')) || ($id eq 'Cost' && $class eq '終律'))){
      $value = textSongPoint($value);
    }
    if($id && $id eq 'SongSing' && $value eq ''){ $value = 'なし'; }
    if($id && ($id eq 'SongPet' || $id eq 'ApplyHumanForm') && $value eq ''){ $value = '―'; }
    if($id && $id eq 'Premise' && $class eq '騎芸' && $value eq ''){ $value = 'なし'; }
    if($id && $id eq 'CommandCost'){
      $value = !$value ? 'なし' : $value =~ /^\d+$/ ? "${value}消費" : $value;
    }
    if($id && $id eq 'CommandCharge'){
      $value = !$value ? 'なし' : $value =~ /^\d+$/ ? "＋$value" : $value;
    }
    my $row = { Label => $label, Value => $value, CssClass => $css };
    if($allowed{$css} && !$seen{$css}++){ push @rows,$row; }
    else { push @extras,$row; }
  }
  return \@rows,\@extras,$notes;
}

### 特殊神聖魔法 --------------------------------------------------
my @magics;
foreach my $lv (2,4,7,10,13){
  my $icon;
  if($pc{'godMagic'.$lv.'ActionTypeMinor'}){ $icon .= '<i class="s-icon minor">≫</i>' }
  if($pc{'godMagic'.$lv.'ActionTypeSetup'}){ $icon .= '<i class="s-icon setup">△</i>' }
  $pc{'godMagic'.$lv.'Effect'} =~ s#<h2>(.+?)</h2>#</dd><dt><span class="center">$1</span></dt><dd class="box">#gi;
  push(@magics, {
    "NAME"     => renderCharacterName($pc{'godMagic'.$lv.'Name'}),
    "LEVEL"    => $lv,
    "ICON"     => $icon,
    "COST"     => $pc{'godMagic'.$lv.'Cost'},
    "TARGET"   => textMagic($pc{'godMagic'.$lv.'Target'}),
    "RANGE"    => $pc{'godMagic'.$lv.'Range'},
    "FORM"     => $pc{'godMagic'.$lv.'Form'},
    "DURATION" => textMagic($pc{'godMagic'.$lv.'Duration'}),
    "RESIST"   => $pc{'godMagic'.$lv.'Resist'},
    "ELEMENT"  => $pc{'godMagic'.$lv.'Element'},
    "SUMMARY"  => $pc{'godMagic'.$lv.'Summary'},
    "EFFECT"   => $pc{'godMagic'.$lv.'Effect'},
    "head_EFFECT" => $pc{'head_godMagic'.$lv.'Effect'},
  } );
}
$SHEET->param(MagicData => \@magics);

### 流派アイテム --------------------------------------------------
my @items;
my @itemReferences;
if(my @itemUrls = split ',', $pc{schoolItemList}){
  require $set::lib_convert;
  @itemReferences = prepareItemReferences(@itemUrls);
}
foreach my $reference (@itemReferences){
  my %item = loadItemData($reference);
  if(exists $item{itemName}){
    $item{price} =~ s/[+＋]/<br>＋/;
    $item{price} = commify($item{price}) if $item{price} =~ /\d{4,}/;
    $item{category} =~ s/\s/<hr>/g;
    my $icon;
    foreach (qw/magic local school school_a school_t/){
      next unless $item{snakeToCamel("icon_$_")};
      $icon .= qq|<img class="i-icon" src="${set::icon_dir}item_${_}.png">|;
    }
    push(@items, {
      "NAME"      => qq|<a href="@{[ escapePcData($item{_itemUrl}) ]}" target="_blank">$icon|.unescapeTags($item{itemName})."</a>",
      "PRICE"     => unescapeTags($item{price}),
      "CATEGORY"  => unescapeTags($item{category}),
      "REPUTATION"=> unescapeTags($item{reputation}),
      "AGE"       => unescapeTags($item{age}),
      "SUMMARY"   => unescapeTags($item{summary}),
    } );
  }
  else {
    my $url = $reference->{sourceUrl};
    my $error = ($item{_error} ? qq|<span class="small">$item{_error}</span>| : "");
    push(@items, {
      NAME => qq|<a href="$url" target="_blank" class="failed">データ取得失敗</a>|,
      SUMMARY => $error,
    });
    next;
  }
}
$SHEET->param(SchoolItems => \@items);
### 秘伝 --------------------------------------------------
my @arts;
foreach my $num (1..$pc{schoolArtsNum}){
  next if !($pc{'schoolArts'.$num.'Name'});
  my $icon;
  if($pc{'schoolArts'.$num.'ActionTypeSetup'}){ $icon .= '<i class="s-icon setup">△</i>' }
  my @names;
  foreach (split '(?<!<)\s[/／]\s', $pc{'schoolArts'.$num.'Name'}){
    push(@names, "${icon}《".renderCharacterName($_)."》")
  }
  foreach my $type ('Cost','Type','Premise','Equip','Use','Apply','Risk'){
    my @texts;
    foreach (split '(?<!<)\s[/／]\s', $pc{'schoolArts'.$num.$type}){
      push(@texts, "<span>$_</span>")
    }
    $pc{'schoolArts'.$num.$type} = join('<hr class="dotted">', @texts)
  }
  $pc{'schoolArts'.$num.'Premise'} =~ s#(《.+?》、?)#<span class="keep-all">$1</span><wbr>#g;
  $pc{'schoolArts'.$num.'Premise'} =~ s#<wbr>$##g;
  $pc{'schoolArts'.$num.'Effect'} =~ s#<h2>(.+?)</h2>#</dd><dt><span class="center">$1</span></dt><dd class="box">#gi;
  push(@arts, {
    "NAME"     => join('</div><hr><div>', @names),
    "COST"     => $pc{'schoolArts'.$num.'Cost'},
    "TYPE"     => $pc{'schoolArts'.$num.'Type'},
    "PREMISE"  => $pc{'schoolArts'.$num.'Premise'},
    "EQUIP"    => $pc{'schoolArts'.$num.'Equip'},
    "USE"      => $pc{'schoolArts'.$num.'Use'},
    "APPLY"    => $pc{'schoolArts'.$num.'Apply'},
    "RISK"     => $pc{'schoolArts'.$num.'Risk'},
    "SUMMARY"  => $pc{'schoolArts'.$num.'Summary'},
    "EFFECT"   => $pc{'schoolArts'.$num.'Effect'},
    "head_EFFECT" => $pc{'head_schoolArts'.$num.'Effect'},
  } );
}
$SHEET->param(ArtsData => \@arts);
if(@arts || $pc{schoolArtsNote}){ $SHEET->param(ArtsView => 1); }

my @schoolmagics;
foreach my $num (1..$pc{schoolMagicNum}){
  next if !($pc{'schoolMagic'.$num.'Name'});
  my $magic = magicViewData("schoolMagic$num");
  $magic->{Level} = $magic->{Lv}; # 既存の保存キーを維持
  $magic->{head_Effect} = $pc{"head_schoolMagic${num}Effect"};
  push(@schoolmagics, $magic);
}
$SHEET->param(schoolMagicData => \@schoolmagics);
if(@schoolmagics || $pc{schoolMagicNote}){ $SHEET->param(schoolMagicView => 1); }

### 特殊能力 --------------------------------------------------
if ($pc{category} eq 'skill') {
  my $actionCode = '';
  $actionCode .= '[常]' if $pc{skillActionPassive};
  $actionCode .= '[補]' if $pc{skillActionMinor};
  $actionCode .= '[準]' if $pc{skillActionSetup};
  $actionCode .= '[主]' if $pc{skillActionMajor};
  $SHEET->param(skillIcon => textToIcon($actionCode)) if $actionCode ne '';

  my @ranks = ('B', 'A', 'S', 'SS');
  @ranks = (@ranks[0]) unless $pc{skillRankMode};

  my @rankList = ();
  foreach my $rank (@ranks) {
    my %data = (
        rank    => $rank,
        summary => $pc{"skillRank${rank}_summary"},
        effect  => $pc{"skillRank${rank}_effect"},
    );

    $data{rank} = undef unless $pc{skillRankMode};

    push(@rankList, \%data);
  }

  $SHEET->param(rankList => \@rankList);
}

### OGP --------------------------------------------------
{
  my $sub; my $category;
  if($pc{category} eq 'magic'){
    $category = '魔法';
    $sub = "／$pc{magicClass}";
    $sub .= "／$pc{magicLevel}" if $magicRecords->count(\%pc) == 1;
    $sub .= '／小魔法' if $pc{magicMinor};
  }
  if($pc{category} eq 'god'){
    $category = '神格';
    $sub = '／'.($pc{godClass}||'―').'／'.($pc{godRank}||'―');
  }
  if ($pc{category} eq 'school') {
    $category = '流派';
    $sub = "　地域:$pc{schoolArea}" if $pc{schoolArea};
  }
  if ($pc{category} eq 'skill') {
    $category = '特殊能力';
  }
  $SHEET->param(ogDescript => removeTags "カテゴリ:${category}${sub}");
}

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
