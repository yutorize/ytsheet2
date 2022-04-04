################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_races;
require $set::data_items;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_mons, utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### モンスターデータ読み込み #########################################################################
our %pc = pcDataGet();

if($pc{'description'} =~ s/#login-only//i){
  $pc{'description'} .= '<span class="login-only">［ログイン限定公開］</span>';
  $pc{'forbidden'} = 'all' if !$::LOGIN_ID;
}
### 閲覧禁止データ ###################################################################################
if($pc{'forbidden'} && !$pc{'yourAuthor'}){
  my $author = $pc{'author'};
  my $protect   = $pc{'protect'};
  my $forbidden = $pc{'forbidden'};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{'monsterName'} = noiseText(6,14);
    $pc{'tags'} = '';
    
    $pc{'description'} = '';
    foreach(1..int(rand 3)+1){
      $pc{'description'} .= '　'.noiseText(18,40)."\n";
    }
  }
  
  $pc{'lv'}   = noiseText(1);
  $pc{'taxa'} = noiseText(2,5);
  $pc{'intellect'}   = noiseText(3);
  $pc{'perception'}  = noiseText(3);
  $pc{'disposition'} = noiseText(3);
  $pc{'sin'}         = noiseText(1);
  $pc{'language'}    = noiseText(4,18);
  $pc{'habitat'}     = noiseText(3,8);
  $pc{'reputation'}  = noiseText(2);
  $pc{'reputation+'} = noiseText(2);
  $pc{'weakness'}    = noiseText(6,10);
  $pc{'initiative'}  = noiseText(2);
  $pc{'mobility'}    = noiseText(2,6);
  $pc{'statusNum'} = int(rand 3)+1;
  $pc{'partsNum'}  = noiseText(2);
  $pc{'parts'}     = noiseText(3,9);
  $pc{'coreParts'} = noiseText(2,5);
  
  foreach(1..$pc{'statusNum'}){
    $pc{'status'.$_.'Style'} = noiseText(3,10);
    $pc{'status'.$_.'Accuracy'}    = noiseText(1,2);
    $pc{'status'.$_.'AccuracyFix'} = noiseText(2);
    $pc{'status'.$_.'Damage'}      = noiseText(4);
    $pc{'status'.$_.'Evasion'}     = noiseText(1,2);
    $pc{'status'.$_.'EvasionFix'}  = noiseText(2);
    $pc{'status'.$_.'Defense'}     = noiseText(2);
    $pc{'status'.$_.'Hp'}          = noiseText(2,3);
    $pc{'status'.$_.'Mp'}          = noiseText(2,3);
  }
  $pc{'skills'} = '';
  foreach(1..int(rand 4)+1){
    $pc{'skills'} .= noiseText(6,18)."\n";
    $pc{'skills'} .= '　'.noiseText(18,40)."\n";
    $pc{'skills'} .= '　'.noiseText(18,40)."\n" if(int rand 2);
    $pc{'skills'} .= "\n";
  }
  
  $pc{'author'} = $author;
  $pc{'protect'} = $protect;
  $pc{'forbidden'} = $forbidden;
  $pc{'forbiddenMode'} = 1;
}

### 置換前出力 #######################################################################################
$SHEET->param(rawName => $pc{'characterName'}?"$pc{'characterName'}（$pc{'monsterName'}）":$pc{'monsterName'});

### 置換 #############################################################################################
foreach (keys %pc) {
  if($_ =~ /^(?:skills|description)$/){
    $pc{$_} = tag_unescape_lines($pc{$_});
  }
  $pc{$_} = tag_unescape($pc{$_},$pc{'oldSignConv'});
}
$pc{'skills'} =~ s/<br>/\n/gi;
$pc{'skills'} =~ s#(<p>|</p>|</details>)#$1\n#gi;
$pc{'skills'} =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
if($::SW2_0){
  $pc{'skills'} =~ s/^((?:[○◯〇＞▶〆☆≫»□☑🗨▽▼]|&gt;&gt;)+)(.*?)([ 　]|$)/"<\/p><h5>".&text_convert_icon($1)."$2<\/h5><p>".$3;/egim;
} else {
  $pc{'skills'} =~ s/^((?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+)(.*?)([ 　]|$)/"<\/p><h5>".&text_convert_icon($1)."$2<\/h5><p>".$3;/egim;
}
$pc{'skills'} =~ s/\n+<\/p>/<\/p>/gi;
$pc{'skills'} =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
$pc{'skills'} = "<p>$pc{'skills'}</p>";
$pc{'skills'} =~ s#(</p>|</details>)\n#$1#gi;
$pc{'skills'} =~ s/<p><\/p>//gi;
$pc{'skills'} =~ s/\n/<br>/gi;

### 置換後出力 #######################################################################################
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
### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{'tags'})){
    push(@tags, {
      "URL"  => uri_escape_utf8($_),
      "TEXT" => $_,
    });
}
$SHEET->param(Tags => \@tags);

### ステータス --------------------------------------------------
$SHEET->param(vitResist => $pc{'vitResist'} eq '' ? '' : $pc{'vitResist'}.(!$pc{'statusTextInput'}?' ('.$pc{'vitResistFix'}.')':''));
$SHEET->param(mndResist => $pc{'mndResist'} eq '' ? '' : $pc{'mndResist'}.(!$pc{'statusTextInput'}?' ('.$pc{'mndResistFix'}.')':''));

my @status;
foreach (1 .. $pc{'statusNum'}){
  $pc{'status'.$_.'Accuracy'} = $pc{'status'.$_.'Accuracy'} eq '' ? '―' : $pc{'status'.$_.'Accuracy'}.(!$pc{'statusTextInput'}?' ('.$pc{'status'.$_.'AccuracyFix'}.')':'');
  $pc{'status'.$_.'Evasion'}  = $pc{'status'.$_.'Evasion'}  eq '' ? '―' : $pc{'status'.$_.'Evasion'} .(!$pc{'statusTextInput'}?' ('.$pc{'status'.$_.'EvasionFix'}.')' :'');
  $pc{'status'.$_.'Damage'}  = '―' if $pc{'status'.$_.'Damage'} eq '';
  $pc{'status'.$_.'Defense'} = '―' if $pc{'status'.$_.'Defense'} eq '';
  $pc{'status'.$_.'Hp'} = '―' if $pc{'status'.$_.'Hp'} eq '';
  $pc{'status'.$_.'Mp'} = '―' if $pc{'status'.$_.'Mp'} eq '';
  push(@status, {
    "STYLE"    => $pc{'status'.$_.'Style'},
    "ACCURACY" => $pc{'status'.$_.'Accuracy'},
    "DAMAGE"   => $pc{'status'.$_.'Damage'},
    "EVASION"  => $pc{'status'.$_.'Evasion'},
    "DEFENSE"  => $pc{'status'.$_.'Defense'},
    "HP"       => $pc{'status'.$_.'Hp'},
    "MP"       => $pc{'status'.$_.'Mp'},
  } );
}
$SHEET->param(Status => \@status);

### 部位 --------------------------------------------------
$SHEET->param(partsOn => 1) if ($pc{'partsNum'} > 1 || $pc{'parts'} || $pc{'coreParts'});

### 戦利品 --------------------------------------------------
my @loots;
foreach (1 .. $pc{'lootsNum'}){
  next if !$pc{'loots'.$_.'Num'} && !$pc{'loots'.$_.'Item'};
  push(@loots, {
    "NUM"  => $pc{'loots'.$_.'Num'},
    "ITEM" => $pc{'loots'.$_.'Item'},
  } );
}
$SHEET->param(Loots => \@loots);

### バックアップ --------------------------------------------------
if($::in{'id'}){
  my($selected, $list) = getLogList($set::mons_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{'yourAuthor'} || $pc{'protect'} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{'forbidden'} eq 'all' && $pc{'forbiddenMode'}){
  $SHEET->param(monsterNameTitle => '非公開データ');
}
else {
  $SHEET->param(characterNameTitle => tag_delete name_plain $pc{'characterName'});
  $SHEET->param(monsterNameTitle => tag_delete name_plain $pc{'monsterName'});
}

### 画像 --------------------------------------------------
$pc{'imageUpdateTime'} = $pc{'updateTime'};
$pc{'imageUpdateTime'} =~ s/[\-\ \:]//g;
$SHEET->param(imageSrc => "${set::mons_dir}${main::file}/image.$pc{'image'}?$pc{'imageUpdateTime'}");

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{'url'} ? "?url=$::in{'url'}" : "?id=$::in{'id'}"));
#if($pc{'image'}) { $SHEET->param(ogImg => url()."/".$imgsrc); }
$SHEET->param(ogDescript => "レベル:$pc{'lv'}　分類:$pc{'taxa'}".($pc{'partsNum'}>1?"　部位数:$pc{'partsNum'}":'')."　知名度:$pc{'reputation'}／$pc{'reputation+'}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $SHEET->output;

1;