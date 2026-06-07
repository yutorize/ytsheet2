################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
# なし

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  unescapeLinesRe   => qr/(?:Effect|Description|Note|QnA)$/,
  unescapeSkipKeys  => [qw/schoolItemList/],
  maskSkipKeys      => ['category'],
  nameSub           => \&setArtsName,
  updateSub => \&data_update_arts,
);
our %pc = %{ $pcRef };

sub setArtsName {
  my ($pc) = @_;
  if($pc->{category} eq 'magic'){
    if($pc->{magicMinor}){ $pc->{magicClass} .= ' (小魔法)' }
    $pc->{artsName} = '【'.($pc->{magicClass} eq '神聖魔法' ? (extractDivineMark $pc->{magicName})[1] : $pc->{magicName}).'】';
    $pc->{titleName} = $pc->{magicName};
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
    $pc->{magicName} = noiseText(6,14);
    $pc->{magicDescription} = '';
    foreach(1..int(rand 3)+3){
      $pc->{magicDescription} .= noiseText(18,50)."<br>";
    }
  }
  
  $pc->{magicClass}    = noiseText(3,14);
  
  $pc->{magicLevel}    = noiseText(2);
  $pc->{magicCost}     = noiseText(3,4);
  $pc->{magicTarget}   = noiseText(2,14);
  $pc->{magicRange}    = noiseText(2,4);
  $pc->{magicForm}     = noiseText(2,4);
  $pc->{magicDuration} = noiseText(2,9);
  $pc->{magicResist}   = noiseText(2);
  $pc->{magicElement}  = noiseText(1,6);
  $pc->{magicSummary}  = noiseText(8,25);
  $pc->{magicActionTypeMinor} = 0;
  $pc->{magicActionTypeSetup} = 0;
  $pc->{magicEffect} = '';
  foreach(1..int(rand 3)+2){
    $pc->{magicEffect} .= noiseText(18,40)."<br>";
  }
  $pc->{magicMagisphere}  = noiseText(1,3);

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
{
  my $icon;
  my $class = $pc{magicClass};
  if($pc{magicActionTypePassive}){ $icon .= '<i class="s-icon passive"><span class="raw">[常]</span></i>' }
  if($pc{magicActionTypeMajor}  ){ $icon .= '<i class="s-icon major"><span class="raw">[主]</span></i>' }
  if($pc{magicActionTypeMinor}  ){ $icon .= '<i class="s-icon minor"><span class="raw">[補]</span></i>' }
  if($pc{magicActionTypeSetup}  ){ $icon .= '<i class="s-icon setup"><span class="raw">[準]</span></i>' }

  my $magicName = $pc{magicName};
  (my $divineMark, $magicName) = extractDivineMark $magicName if $pc{magicClass} eq '神聖魔法';
  my $alias;
  if($magicName =~ s/\s?[－―‐–—─\-](.+?)[－―‐–—─\-]$//){ $alias = "－$1－" }

  $SHEET->param(magicIcon => $icon);
  $SHEET->param(magicName => renderCharacterName $magicName);
  $SHEET->param(magicAlias => $alias);
  $SHEET->param(magicDivineMark => $divineMark) if defined $divineMark;
  $SHEET->param(magicTarget   => textMagic($pc{magicTarget}));
  $SHEET->param(magicDuration => textMagic($pc{magicDuration}));

  if($pc{magicClass} =~ /魔動機術/){ $SHEET->param(magicNameNotes => 'マギスフィア:'.$pc{magicMagisphere}); }
  
  if   ($class eq '練技'){
    $SHEET->param(magicClassEn => 'enhance');
    magicItemViewOn('Duration');
  }
  elsif   ($class eq '呪歌'){
    $SHEET->param(magicClassEn => 'song');
    $SHEET->param(magicSongSing => $pc{magicSongSing} ? '必要':'なし');
    $SHEET->param(magicCondition => textSongPoint($pc{magicCondition}));
    $SHEET->param(magicSongBasePoint => textSongPoint($pc{magicSongBasePoint}));
    $SHEET->param(magicSongAddPoint => textSongPoint($pc{magicSongAddPoint}));
    magicItemViewOn('Song','Condition','Resist','Element');
  }
  elsif   ($class eq '終律'){
    $SHEET->param(magicClassEn => 'finale');
    $SHEET->param(magicCost => textSongPoint($pc{magicCost}));
    magicItemViewOn('Cost','Resist','Element');
  }
  elsif   ($class eq '騎芸'){
    $SHEET->param(magicClassEn => 'riding');
    $SHEET->param(magicPremise => $pc{magicPremise} || 'なし');
    magicItemViewOn('Premise','Type','Part');
  }
  elsif   ($class eq '相域'){
    $SHEET->param(magicClassEn => 'geomancy');
    magicItemViewOn('Cost','Duration','Element');
  }
  elsif   ($class eq '鼓咆'){
    $SHEET->param(magicClassEn => 'command');
    $SHEET->param(magicTypeDt   => '系統');
    $SHEET->param(magicCommandCost   => $pc{magicCommandCost}   ? "$pc{magicCommandCost}消費" : 'なし');
    $SHEET->param(magicCommandCharge => $pc{magicCommandCharge} ? "＋$pc{magicCommandCharge}" : 'なし');
    magicItemViewOn('Type','Rank','CommandCost','CommandCharge');
  }
  elsif   ($class eq '陣率'){
    $SHEET->param(magicClassEn => 'lead');
    $SHEET->param(magicCommandCost   => $pc{magicCommandCost}   ? "$pc{magicCommandCost}消費" : 'なし');
    magicItemViewOn('Premise','Condition','CommandCost');
  }
  elsif   ($class eq '占瞳'){
    $SHEET->param(magicClassEn => 'divination');
    $SHEET->param(magicTypeDt   => 'タイプなど');
    magicItemViewOn('Type','Target','Range','Duration');
  }
  elsif   ($class eq '魔装'){
    $SHEET->param(magicClassEn => 'potential');
    $SHEET->param(magicApplyHumanForm =>
      ($pc{magicApplyHumanForm} eq 'available')   ? '有効' :
      ($pc{magicApplyHumanForm} eq 'unavailable') ? '無効' :
      '―'
    );
    magicItemViewOn('Premise','Part','HumanForm');
  }
  elsif   ($class eq '操気'){
    $SHEET->param(magicClassEn => 'psychokinesis');
    if($pc{magicActionTypePassive}){ magicItemViewOn('Cost','Premise') }
    else { magicItemViewOn('Cost','Premise','Target','Range','Duration','Resist') }
  }
  elsif   ($class eq '呪印'){
    $SHEET->param(magicClassEn => 'seal');
    magicItemViewOn('Premise','Type');
  }
  elsif   ($class eq '貴格'){
    $SHEET->param(magicClassEn => 'dignity');
    magicItemViewOn('Premise','Type','Target');
  }
  else {
    magicItemViewOn('Cost','Target','Range','Duration','Resist',($pc{magicElement}?'Element':undef));
  }
  
  $SHEET->param(magicEffect => $pc{magicEffect} =~ s#<h2>(.+?)</h2>#</dd><dt><span class="center">$1</span></dt><dd class="box">#gir);
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
sub magicItemViewOn {
  foreach my $name (@_){ $SHEET->param("magic${name}On" => 1); }
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
foreach my $set_url (split ',',$pc{schoolItemList}){
  eval { require $set::lib_convert; };
  my %item = loadItemData($set_url);
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
      "NAME"      => qq|<a href="$set_url" target="_blank">$icon|.unescapeTags($item{itemName})."</a>",
      "PRICE"     => unescapeTags($item{price}),
      "CATEGORY"  => unescapeTags($item{category}),
      "REPUTATION"=> unescapeTags($item{reputation}),
      "AGE"       => unescapeTags($item{age}),
      "SUMMARY"   => unescapeTags($item{summary}),
    } );
  }
  else {
    my $error = "データ取得失敗".($item{error} ? "<br><small>($item{error})</small>" : "");
    push(@items, {
      "NAME" => "<a href=\"$set_url\" target=\"_blank\" class=\"failed\">$error</a>",
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
  my $icon;
  if($pc{'schoolMagic'.$num.'ActionTypeMinor'}){ $icon .= '<i class="s-icon minor">≫</i>' }
  if($pc{'schoolMagic'.$num.'ActionTypeSetup'}){ $icon .= '<i class="s-icon setup">△</i>' }
  $pc{'schoolMagic'.$num.'Effect'} =~ s#<h2>(.+?)</h2>#</dd><dt><span class="center">$1</span></dt><dd class="box">#gi;

  my $schoolMagicName = $pc{'schoolMagic'.$num.'Name'};
  (my $divineMark, $schoolMagicName) = extractDivineMark $schoolMagicName;
  my $alias;
  if($schoolMagicName =~ s/\s?[－―‐–—─\-](.+?)[－―‐–—─\-]$//){ $alias = "－$1－" }

  push(@schoolmagics, {
    "NAME"     => renderCharacterName($schoolMagicName),
    "ALIAS"    => $alias,
    "DIVINE_MARK" => $divineMark,
    "LEVEL"    => $pc{'schoolMagic'.$num.'Lv'},
    "ICON"     => $icon,
    "A-COST"   => $pc{'schoolMagic'.$num.'AcquireCost'},
    "COST"     => $pc{'schoolMagic'.$num.'Cost'},
    "TARGET"   => textMagic($pc{'schoolMagic'.$num.'Target'}),
    "RANGE"    => $pc{'schoolMagic'.$num.'Range'},
    "FORM"     => $pc{'schoolMagic'.$num.'Form'},
    "DURATION" => textMagic($pc{'schoolMagic'.$num.'Duration'}),
    "RESIST"   => $pc{'schoolMagic'.$num.'Resist'},
    "ELEMENT"  => $pc{'schoolMagic'.$num.'Element'},
    "SUMMARY"  => $pc{'schoolMagic'.$num.'Summary'},
    "EFFECT"   => $pc{'schoolMagic'.$num.'Effect'},
    "head_EFFECT" => $pc{'head_schoolMagic'.$num.'Effect'},
  } );
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
    $sub = "／$pc{magicClass}／$pc{magicLevel}";
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
