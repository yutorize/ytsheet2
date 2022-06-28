################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

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
  $pc{'artsName'} = $pc{'magicName'};
  $SHEET->param(rawName => $pc{'magicName'});
}
if($pc{'category'} eq 'god'){
  $SHEET->param(categoryGod => 1);
  $pc{'artsName'} = $pc{'godName'};
  $SHEET->param(rawName => $pc{'godName'});
}

### 置換 #############################################################################################
foreach (keys %pc) {
  if($_ =~ /(?:Effect|Description|Note)$/){
    $pc{$_} = tag_unescape_lines($pc{$_});
  }
  $pc{$_} = tag_unescape($pc{$_});
}

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
  if($pc{'magicActionTypeMinor'}){ $icon .= '<i class="s-icon minor">≫</i>' }
  if($pc{'magicActionTypeSetup'}){ $icon .= '<i class="s-icon setup">△</i>' }
  $SHEET->param(magicIcon => $icon);
  $SHEET->param(magicTarget   => textMagic($pc{'magicTarget'}));
  $SHEET->param(magicDuration => textMagic($pc{'magicDuration'}));

  if($pc{'magicClass'} =~ /魔動機術/){ $SHEET->param(magicNameNotes => 'マギスフィア:'.$pc{'magicMagisphere'}); }
}
sub textMagic {
  $_[0] =~ s#／#／<br>#;
  return $_[0];
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
  $SHEET->param(artsNameTitle => '非公開データ');
}
else {
  $SHEET->param(artsNameTitle => tag_delete name_plain $pc{'artsName'});
}

### 画像 --------------------------------------------------
my $imgsrc;
if($pc{'convertSource'} eq '別のゆとシートⅡ') {
  $imgsrc = $pc{'imageURL'}."?$pc{'imageUpdate'}";
}
else {
  $imgsrc = "${set::arts_dir}${main::file}/image.$pc{'image'}?$pc{'imageUpdate'}";
}
$SHEET->param(imageSrc => $imgsrc);

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $SHEET->output;

1;