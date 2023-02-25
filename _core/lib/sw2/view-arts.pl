################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;
use URI;

### データ読み込み ###################################################################################
# なし

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_arts, utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### キャラクターデータ読み込み #######################################################################
our %pc = pcDataGet();

### 閲覧禁止データ ###################################################################################
if($pc{'forbidden'} && !$pc{'yourAuthor'}){
  my $author = $pc{'author'};
  my $protect   = $pc{'protect'};
  my $forbidden = $pc{'forbidden'};
  my $category  = $pc{'category'};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{'tags'} = '';

    $pc{'magicName'} = noiseText(6,14);
    $pc{"magicDescription"} = '';
    foreach(1..int(rand 3)+3){
      $pc{"magicDescription"} .= noiseText(18,50)."\n";
    }

    $pc{'godName'}   = noiseText(2,12);
    $pc{'godAka'}    = noiseText(2,5);
    $pc{'godClass'}  = noiseText(3);
    $pc{'godRank'}   = noiseText(2,3);
    $pc{'godArea'}   = noiseText(5,10);

    $pc{"godSymbol"} = '';
    foreach(1..int(rand 3)+2){ $pc{"godSymbol"} .= noiseText(18,40)."\n"; }
    $pc{"godDeity"} = '';
    foreach(1..int(rand 5)+8){ $pc{"godDeity"} .= noiseText(18,40)."\n"; }
    foreach(1..3){ $pc{"godMaxim".$_} .= noiseText(8,30); }
  }
  
  $pc{"magicClass"}    = noiseText(3,14);
  
  $pc{"magicLevel"}    = noiseText(2);
  $pc{"magicCost"}     = noiseText(3,4);
  $pc{"magicTarget"}   = noiseText(2,14);
  $pc{"magicRange"}    = noiseText(2,4);
  $pc{"magicForm"}     = noiseText(2,4);
  $pc{"magicDuration"} = noiseText(2,9);
  $pc{"magicResist"}   = noiseText(2);
  $pc{"magicElement"}  = noiseText(1,6);
  $pc{"magicSummary"}  = noiseText(8,25);
  $pc{"magicActionTypeMinor"} = 0;
  $pc{"magicActionTypeSetup"} = 0;
  $pc{"magicEffect"} = '';
  foreach(1..int(rand 3)+2){
    $pc{"magicEffect"} .= noiseText(18,40)."\n";
  }
  $pc{"magicMagisphere"}  = noiseText(1,3);

  foreach my $lv (2,4,7,10,13){
    $pc{"godMagic${lv}Name"}     = noiseText(3,14);
    $pc{"godMagic${lv}Cost"}     = noiseText(3,4);
    $pc{"godMagic${lv}Target"}   = noiseText(2,14);
    $pc{"godMagic${lv}Range"}    = noiseText(2,4);
    $pc{"godMagic${lv}Form"}     = noiseText(2,4);
    $pc{"godMagic${lv}Duration"} = noiseText(2,9);
    $pc{"godMagic${lv}Resist"}   = noiseText(2);
    $pc{"godMagic${lv}Element"}  = noiseText(1,6);
    $pc{"godMagic${lv}Summary"}  = noiseText(8,25);
    $pc{"godMagic${lv}ActionTypeMinor"} = 0;
    $pc{"godMagic${lv}ActionTypeSetup"} = 0;
    $pc{"godMagic${lv}Effect"} = '';
    foreach(1..int(rand 3)+2){
      $pc{"godMagic${lv}Effect"} .= noiseText(18,40)."\n";
    }
  }
  
  $pc{'effects'} = '';
  foreach(1..int(rand 4)+1){
    $pc{'effects'} .= noiseText(6,18)."\n";
    $pc{'effects'} .= '　'.noiseText(18,40)."\n";
    $pc{'effects'} .= '　'.noiseText(18,40)."\n" if(int rand 2);
    $pc{'effects'} .= "\n";
  }
  
  $pc{'author'}    = $author;
  $pc{'protect'}   = $protect;
  $pc{'forbidden'} = $forbidden;
  $pc{'category'}  = $category;
  $pc{'forbiddenMode'} = 1;
}

### 置換前出力 #######################################################################################
if($pc{'category'} eq 'magic'){
  if($pc{'magicMinor'}){ $pc{'magicClass'} .= ' (小魔法)' }
  $SHEET->param(categoryMagic => 1);
  $pc{'artsName'} = '【'.$pc{'magicName'}.'】';
  $SHEET->param(rawName => $pc{'magicName'});
}
elsif($pc{'category'} eq 'god'){
  $SHEET->param(categoryGod => 1);
  $SHEET->param(wideMode => 1);
  $pc{'artsName'} = ($pc{'godAka'} ? "“$pc{'godAka'}”" : "").$pc{'godName'};
  $SHEET->param(rawName => $pc{'artsName'});
}
elsif($pc{'category'} eq 'school'){
  $SHEET->param(categorySchool => 1);
  $SHEET->param(wideMode => 1);
  $pc{'artsName'} = '【'.$pc{'schoolName'}.'】';
  $SHEET->param(rawName => $pc{'schoolName'});
}
my $item_urls = $pc{'schoolItemList'};

### 置換 #############################################################################################
foreach (keys %pc) {
  if($_ =~ /(?:Effect|Description|Note)$/){
    $pc{$_} = tag_unescape_lines($pc{$_});
  }
  $pc{$_} = tag_unescape($pc{$_});
}

### アップデート --------------------------------------------------
if($pc{'ver'}){
  %pc = data_update_arts(\%pc);
}

### カラー設定 --------------------------------------------------
setColors();

### 出力準備 #########################################################################################
### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param(id => $::in{'id'});

if($::in{'url'}){
  $SHEET->param(convertMode => 1);
  $SHEET->param(convertUrl => $::in{'url'});
}

### 魔法の武器アイコン --------------------------------------------------
$SHEET->param(magic => ($pc{'magic'} ? "<img class=\"i-icon\" src=\"${set::icon_dir}wp_magic.png\">" : ''));

### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{'tags'})){
    push(@tags, {
      "URL"  => uri_escape_utf8($_),
      "TEXT" => $_,
    });
}
$SHEET->param(Tags => \@tags);

### 魔法 --------------------------------------------------
{
  my $icon;
  my $class = $pc{'magicClass'};
  if($pc{'magicActionTypePassive'}){ $icon .= '<i class="s-icon passive">○</i>' }
  if($pc{'magicActionTypeMajor'}  ){ $icon .= '<i class="s-icon major">▶</i>' }
  if($pc{'magicActionTypeMinor'}  ){ $icon .= '<i class="s-icon minor">≫</i>' }
  if($pc{'magicActionTypeSetup'}  ){ $icon .= '<i class="s-icon setup">△</i>' }
  $SHEET->param(magicIcon => $icon);
  $SHEET->param(magicTarget   => textMagic($pc{'magicTarget'}));
  $SHEET->param(magicDuration => textMagic($pc{'magicDuration'}));

  if($pc{'magicClass'} eq '魔動機術'){ $SHEET->param(magicNameNotes => 'マギスフィア:'.$pc{'magicMagisphere'}); }
  
  if   ($class eq '練技'){
    $SHEET->param(magicClassEn => 'enhance');
    magicItemViewOn('Duration');
  }
  elsif   ($class eq '呪歌'){
    $SHEET->param(magicClassEn => 'song');
    $SHEET->param(magicSongSing => $pc{'magicSongSing'} ? '必要':'なし');
    $SHEET->param(magicCondition => textSongPoint($pc{'magicCondition'}));
    $SHEET->param(magicSongBasePoint => textSongPoint($pc{'magicSongBasePoint'}));
    $SHEET->param(magicSongAddPoint => textSongPoint($pc{'magicSongAddPoint'}));
    magicItemViewOn('Song','Condition','Resist','Element');
  }
  elsif   ($class eq '終律'){
    $SHEET->param(magicClassEn => 'finale');
    $SHEET->param(magicCost => textSongPoint($pc{'magicCost'}));
    magicItemViewOn('Cost','Resist','Element');
  }
  elsif   ($class eq '騎芸'){
    $SHEET->param(magicClassEn => 'riding');
    $SHEET->param(magicPremise => $pc{'magicPremise'} || 'なし');
    magicItemViewOn('Premise','Type','Part');
  }
  elsif   ($class eq '相域'){
    $SHEET->param(magicClassEn => 'geomancy');
    magicItemViewOn('Cost','Duration','Element');
  }
  elsif   ($class eq '鼓咆'){
    $SHEET->param(magicClassEn => 'command');
    $SHEET->param(magicTypeDt   => '系統');
    $SHEET->param(magicCommandCost   => $pc{'magicCommandCost'}   ? "$pc{'magicCommandCost'}消費" : 'なし');
    $SHEET->param(magicCommandCharge => $pc{'magicCommandCharge'} ? "＋$pc{'magicCommandCharge'}" : 'なし');
    magicItemViewOn('Type','Rank','CommandCost','CommandCharge');
  }
  elsif   ($class eq '陣率'){
    $SHEET->param(magicClassEn => 'lead');
    $SHEET->param(magicCommandCost   => $pc{'magicCommandCost'}   ? "$pc{'magicCommandCost'}消費" : 'なし');
    magicItemViewOn('Premise','Condition','CommandCost');
  }
  elsif   ($class eq '占瞳'){
    $SHEET->param(magicClassEn => 'divination');
    $SHEET->param(magicTypeDt   => 'タイプなど');
    magicItemViewOn('Type','Target','Range','Duration');
  }
  elsif   ($class eq '魔装'){
    $SHEET->param(magicClassEn => 'potential');
    magicItemViewOn('Premise','Part');
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
    magicItemViewOn('Cost','Target','Range','Duration','Resist',($pc{'magicElement'}?'Element':undef));
  }
}
sub textMagic {
  $_[0] =~ s#／#／<br>#;
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
  push(@magics, {
    "NAME"     => $pc{'godMagic'.$lv.'Name'},
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
  } );
}
$SHEET->param(MagicData => \@magics);

### 流派装備 --------------------------------------------------
my @items;
foreach my $set_url (split ',',$item_urls){
  ## 同じゆとシートⅡ
  my $self = CGI->new()->url;
  my %item;
  if($set_url =~ m"^$self\?id=(.+?)(?:$|&)"){
    my $id = $1;
    my ($file, $type, $author) = getfile_open($id);
    
    open my $IN, '<', "${set::item_dir}${file}/data.cgi";
    while (<$IN>){
      chomp;
      my ($key, $value) = split(/<>/, $_, 2);
      $item{$key} = tag_unescape($value);
    }
    close($IN);
  }
  else {
  }
  $item{'price'} =~ s/[+＋]/<br>＋/;
  push(@items, {
    "NAME"      => "<a href=\"$set_url\" target=\"_blank\">".$item{'itemName'}."</a>",
    "PRICE"     => $item{'price'},
    "CATEGORY"  => $item{'category'},
    "REPUTATION"=> $item{'reputation'},
    "AGE"       => $item{'age'},
    "SUMMARY"   => $item{'summary'},
  } );
}
$SHEET->param(SchoolItems => \@items);

### 秘伝 --------------------------------------------------
my @arts;
foreach my $num (1..$pc{'schoolArtsNum'}){
  my $icon;
  push(@arts, {
    "NAME"     => $pc{'schoolArts'.$num.'Name'},
    "ICON"     => $icon,
    "COST"     => $pc{'schoolArts'.$num.'Cost'},
    "TYPE"     => $pc{'schoolArts'.$num.'Type'},
    "PREMISE"  => $pc{'schoolArts'.$num.'Premise'},
    "EQUIP"    => $pc{'schoolArts'.$num.'Equip'},
    "USE"      => $pc{'schoolArts'.$num.'Use'},
    "APPLY"    => $pc{'schoolArts'.$num.'Apply'},
    "RISK"     => $pc{'schoolArts'.$num.'Risk'},
    "SUMMARY"  => $pc{'schoolArts'.$num.'Summary'},
    "EFFECT"   => $pc{'schoolArts'.$num.'Effect'},
  } );
}
$SHEET->param(ArtsData => \@arts);

### バックアップ --------------------------------------------------
if($::in{'id'}){
  my($selected, $list) = getLogList($set::arts_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{'yourAuthor'} || $pc{'protect'} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{'forbidden'} eq 'all' && $pc{'forbiddenMode'}){
  $SHEET->param(titleName => '非公開データ');
}
else {
  $SHEET->param(titleName => tag_delete name_plain $pc{'artsName'});
}

### 画像 --------------------------------------------------
my $imgsrc;
if($pc{'image'}){
  if($pc{'convertSource'} eq '別のゆとシートⅡ') {
    $imgsrc = $pc{'imageURL'}."?$pc{'imageUpdate'}";
  }
  else {
    $imgsrc = "${set::arts_dir}${main::file}/image.$pc{'image'}?$pc{'imageUpdate'}";
  }
  $SHEET->param(imageSrc => $imgsrc);
  $SHEET->param(images    => "'1': \"".($pc{'modeDownload'} ? urlToBase64($imgsrc) : $imgsrc)."\", ");
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{'url'} ? "?url=$::in{'url'}" : "?id=$::in{'id'}"));
if($pc{'image'}) { $SHEET->param(ogImg => URI->new_abs($imgsrc, url())); }
{
  my $sub; my $category;
  if($pc{'category'} eq 'magic'){
    $category = '魔法';
    $sub = $pc{'magicClass'}.'／'.$pc{'magicLevel'};
    if($pc{'magicMinor'}){ $sub .= '／小魔法'; }
  }
  if($pc{'category'} eq 'god'){
    $category = '神格';
    $sub = ($pc{'godClass'}||'―').'／'.($pc{'godRank'}||'―');
  }
  $SHEET->param(ogDescript => tag_delete "カテゴリ:${category}／${sub}");
}

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'sw2');
$SHEET->param(sheetType => 'arts');
$SHEET->param(generateType => 'SwordWorld2PC');
$SHEET->param(defaultImage => $::core_dir.'/skin/sw2/img/default_pc.png');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{'modeDownload'}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './?type=i', SIZE => "small" });
  if($::in{'url'}){
    push(@menu, { TEXT => 'コンバート', TYPE => "href", VALUE => "./?mode=convert&url=$::in{'url'}" });
  }
  else {
    if($pc{'logId'}){
      push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => 'loglistOn()', SIZE => "small" });
      if($pc{'reqdPassword'}){ push(@menu, { TEXT => '復元', TYPE => "onclick", VALUE => "editOn()", SIZE => "small" }); }
      else                   { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{'id'}&log=$pc{'logId'}", SIZE => "small" }); }
    }
    else {
      if(!$pc{'forbiddenMode'}){
        push(@menu, { TEXT => '出力'    , TYPE => "onclick", VALUE => "downloadListOn()", SIZE => "small"  });
        push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => "loglistOn()",      SIZE => "small" });
      }
      if($pc{'reqdPassword'}){ push(@menu, { TEXT => '編集', TYPE => "onclick", VALUE => "editOn()", SIZE => "small" }); }
      else                   { push(@menu, { TEXT => '編集', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{'id'}", SIZE => "small" }); }
    }
  }
}
$SHEET->param(Menu => sheetMenuCreate @menu);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
if($pc{'modeDownload'}){
  if($pc{'forbidden'} && $pc{'yourAuthor'}){ $SHEET->param(forbidden => ''); }
  print downloadModeSheetConvert $SHEET->output;
}
else {
  print $SHEET->output;
}

1;
