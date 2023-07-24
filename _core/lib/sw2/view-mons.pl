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

if($pc{description} =~ s/#login-only//i){
  $pc{description} .= '<span class="login-only">［ログイン限定公開］</span>';
  $pc{forbidden} = 'all' if !$::LOGIN_ID;
}

### タグ置換前処理 ###################################################################################
### 閲覧禁止データ --------------------------------------------------
if($pc{forbidden} && !$pc{yourAuthor}){
  my $author = $pc{author};
  my $protect   = $pc{protect};
  my $forbidden = $pc{forbidden};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{monsterName} = noiseText(6,14);
    $pc{tags} = '';
    
    $pc{description} = '';
    foreach(1..int(rand 3)+1){
      $pc{description} .= '　'.noiseText(18,40)."\n";
    }
  }
  
  $pc{lv}   = noiseText(1);
  $pc{taxa} = noiseText(2,5);
  $pc{intellect}   = noiseText(3);
  $pc{perception}  = noiseText(3);
  $pc{disposition} = noiseText(3);
  $pc{sin}         = noiseText(1);
  $pc{language}    = noiseText(4,18);
  $pc{habitat}     = noiseText(3,8);
  $pc{reputation}  = noiseText(2);
  $pc{'reputation+'} = noiseText(2);
  $pc{weakness}    = noiseText(6,10);
  $pc{initiative}  = noiseText(2);
  $pc{mobility}    = noiseText(2,6);
  $pc{statusNum} = int(rand 3)+1;
  $pc{partsNum}  = noiseText(2);
  $pc{parts}     = noiseText(3,9);
  $pc{coreParts} = noiseText(2,5);
  
  foreach(1..$pc{statusNum}){
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
  $pc{skills} = '';
  foreach(1..int(rand 4)+1){
    $pc{skills} .= noiseText(6,18)."\n";
    $pc{skills} .= '　'.noiseText(18,40)."\n";
    $pc{skills} .= '　'.noiseText(18,40)."\n" if(int rand 2);
    $pc{skills} .= "\n";
  }
  
  $pc{author} = $author;
  $pc{protect} = $protect;
  $pc{forbidden} = $forbidden;
  $pc{forbiddenMode} = 1;
}

### その他 --------------------------------------------------
$SHEET->param(rawName => $pc{characterName}?"$pc{characterName}（$pc{monsterName}）":$pc{monsterName});

### タグ置換 #########################################################################################
foreach (keys %pc) {
  if($_ =~ /^(?:skills|description)$/){
    $pc{$_} = tagUnescapeLines($pc{$_});
  }
  $pc{$_} = tagUnescape($pc{$_});
}
$pc{skills} =~ s/<br>/\n/gi;
$pc{skills} =~ s#(<p>|</p>|</details>)#$1\n#gi;
$pc{skills} =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
if($::SW2_0){
  $pc{skills} =~ s/^((?:[○◯〇＞▶〆☆≫»□☐☑🗨▽▼]|&gt;&gt;)+.*?)(　|$)/"<\/p><h5>".&textToIcon($1)."<\/h5><p>".$2;/egim;
} else {
  $pc{skills} =~ s/^((?:[○◯〇△＞▶〆☆≫»□☐☑🗨]|&gt;&gt;)+.*?)(　|$)/"<\/p><h5>".&textToIcon($1)."<\/h5><p>".$2;/egim;
}
$pc{skills} =~ s/\n+<\/p>/<\/p>/gi;
$pc{skills} =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
$pc{skills} = "<p>$pc{skills}</p>";
$pc{skills} =~ s#(</p>|</details>)\n#$1#gi;
$pc{skills} =~ s/<p><\/p>//gi;
$pc{skills} =~ s/\n/<br>/gi;

### カラー設定 --------------------------------------------------
setColors();

### 置換後出力 #######################################################################################
### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param(id => $::in{id});

if($::in{url}){
  $SHEET->param(convertMode => 1);
  $SHEET->param(convertUrl => $::in{url});
}
### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{tags})){
    push(@tags, {
      URL  => uri_escape_utf8($_),
      TEXT => $_,
    });
}
$SHEET->param(Tags => \@tags);

### 価格 --------------------------------------------------
{
  my $price;
  $price .= "<dt>購入</dt><dd>$pc{price}<small>G</small></dd>" if $pc{price};
  $price .= "<dt>レンタル</dt><dd>$pc{priceRental}<small>G</small></dd>"     if $pc{priceRental};
  $price .= "<dt>部位再生</dt><dd>$pc{priceRegenerate}<small>G</small></dd>" if $pc{priceRegenerate};
  if(!$price){ $price = '―' }
  $SHEET->param(price => "<dl class=\"price\">$price</dl>");
}
### 適正レベル --------------------------------------------------
{
  $SHEET->param(appLv => $pc{lvMin}.($pc{lvMax} != $pc{lvMin} ? " ～ $pc{lvMax}":''));
}
### ステータス --------------------------------------------------
$SHEET->param(vitResist => $pc{vitResist} eq '' ? '' : $pc{vitResist}.(!$pc{statusTextInput}?' ('.$pc{vitResistFix}.')':''));
$SHEET->param(mndResist => $pc{mndResist} eq '' ? '' : $pc{mndResist}.(!$pc{statusTextInput}?' ('.$pc{mndResistFix}.')':''));

my @status_tbody;
my @status_row;
foreach (1 .. $pc{statusNum}){
  $pc{'status'.$_.'Accuracy'} = $pc{'status'.$_.'Accuracy'} eq '' ? '―' : $pc{'status'.$_.'Accuracy'}.(!$pc{statusTextInput} && !$pc{mount}?' ('.$pc{'status'.$_.'AccuracyFix'}.')':'');
  $pc{'status'.$_.'Evasion'}  = $pc{'status'.$_.'Evasion'}  eq '' ? '―' : $pc{'status'.$_.'Evasion'} .(!$pc{statusTextInput} && !$pc{mount}?' ('.$pc{'status'.$_.'EvasionFix'}.')' :'');
  $pc{'status'.$_.'Damage'}   = $pc{'status'.$_.'Damage'}   eq '' ? '―' : $pc{'status'.$_.'Damage'} ;
  $pc{'status'.$_.'Defense'}  = $pc{'status'.$_.'Defense'}  eq '' ? '―' : $pc{'status'.$_.'Defense'};
  $pc{'status'.$_.'Hp'}       = $pc{'status'.$_.'Hp'}       eq '' ? '―' : $pc{'status'.$_.'Hp'}     ;
  $pc{'status'.$_.'Mp'}       = $pc{'status'.$_.'Mp'}       eq '' ? '―' : $pc{'status'.$_.'Mp'}     ;
  $pc{'status'.$_.'Vit'}      = $pc{'status'.$_.'Vit'}      eq '' ? '―' : $pc{'status'.$_.'Vit'}    ;
  $pc{'status'.$_.'Mnd'}      = $pc{'status'.$_.'Mnd'}      eq '' ? '―' : $pc{'status'.$_.'Mnd'}    ;
  push(@status_row, {
    LV       => $pc{lvMin},
    STYLE    => $pc{'status'.$_.'Style'},
    ACCURACY => $pc{'status'.$_.'Accuracy'},
    DAMAGE   => $pc{'status'.$_.'Damage'},
    EVASION  => $pc{'status'.$_.'Evasion'},
    DEFENSE  => $pc{'status'.$_.'Defense'},
    HP       => $pc{'status'.$_.'Hp'},
    MP       => $pc{'status'.$_.'Mp'},
    VIT      => $pc{'status'.$_.'Vit'},
    MND      => $pc{'status'.$_.'Mnd'},
  } );
}
push(@status_tbody, { "ROW" => \@status_row }) if !$pc{mount} || $pc{lv} eq '' || $pc{lvMin} == $pc{lv};
foreach my $lv (2 .. ($pc{lvMax}-$pc{lvMin}+1)){
  my @status_row;
  foreach (1 .. $pc{statusNum}){
    my $num = "$_-$lv";
    $pc{'status'.$num.'Accuracy'} = $pc{'status'.$num.'Accuracy'} eq '' ? '―' : $pc{'status'.$num.'Accuracy'};
    $pc{'status'.$num.'Evasion'}  = $pc{'status'.$num.'Evasion'}  eq '' ? '―' : $pc{'status'.$num.'Evasion'} ;
    $pc{'status'.$num.'Damage'}   = $pc{'status'.$num.'Damage'}   eq '' ? '―' : $pc{'status'.$num.'Damage'}  ;
    $pc{'status'.$num.'Defense'}  = $pc{'status'.$num.'Defense'}  eq '' ? '―' : $pc{'status'.$num.'Defense'} ;
    $pc{'status'.$num.'Hp'}       = $pc{'status'.$num.'Hp'}       eq '' ? '―' : $pc{'status'.$num.'Hp'}      ;
    $pc{'status'.$num.'Mp'}       = $pc{'status'.$num.'Mp'}       eq '' ? '―' : $pc{'status'.$num.'Mp'}      ;
    $pc{'status'.$num.'Vit'}      = $pc{'status'.$num.'Vit'}      eq '' ? '―' : $pc{'status'.$num.'Vit'}     ;
    $pc{'status'.$num.'Mnd'}      = $pc{'status'.$num.'Mnd'}      eq '' ? '―' : $pc{'status'.$num.'Mnd'}     ;
    push(@status_row, {
      LV       => $lv+$pc{lvMin}-1,
      STYLE    => $pc{'status'.$_.'Style'},
      ACCURACY => $pc{'status'.$num.'Accuracy'},
      DAMAGE   => $pc{'status'.$num.'Damage'},
      EVASION  => $pc{'status'.$num.'Evasion'},
      DEFENSE  => $pc{'status'.$num.'Defense'},
      HP       => $pc{'status'.$num.'Hp'},
      MP       => $pc{'status'.$num.'Mp'},
      VIT      => $pc{'status'.$num.'Vit'},
      MND      => $pc{'status'.$num.'Mnd'},
    } );
  }
  push(@status_tbody, { ROW => \@status_row }) if !$pc{mount} || $pc{lv} eq '' || $lv+$pc{lvMin}-1 == $pc{lv};
}
$SHEET->param(Status => \@status_tbody);

### 部位 --------------------------------------------------
$SHEET->param(partsOn => 1) if ($pc{partsNum} > 1 || $pc{parts} || $pc{coreParts});

### 戦利品 --------------------------------------------------
my @loots;
foreach (1 .. $pc{lootsNum}){
  next if !$pc{'loots'.$_.'Num'} && !$pc{'loots'.$_.'Item'};
  push(@loots, {
    NUM  => $pc{'loots'.$_.'Num'},
    ITEM => $pc{'loots'.$_.'Item'},
  } );
}
$SHEET->param(Loots => \@loots);

### バックアップ --------------------------------------------------
if($::in{id}){
  my($selected, $list) = getLogList($set::mons_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{yourAuthor} || $pc{protect} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{forbidden} eq 'all' && $pc{forbiddenMode}){
  $SHEET->param(titleName => "非公開データ - $set::title");
}
else {
  my $name    = tagDelete nameToPlain($pc{characterName});
  my $species = tagDelete nameToPlain($pc{monsterName});
  if($name && $species){ $SHEET->param(titleName => "${name}（${species}）"); }
  else { $SHEET->param(titleName => $name || $species); }
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
#if($pc{image}) { $SHEET->param(ogImg => url()."/".$imgsrc); }
$SHEET->param(ogDescript => "レベル:$pc{lv}　分類:$pc{taxa}".($pc{partsNum}>1?"　部位数:$pc{partsNum}":'')."　知名度:$pc{reputation}／$pc{'reputation+'}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'sw2');
$SHEET->param(sheetType => 'monster');
$SHEET->param(generateType => 'SwordWorld2Enemy');
$SHEET->param(defaultImage => $::core_dir.'/skin/sw2/img/default_enemy.png');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{modeDownload}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './?type=m', });
  if($::in{url}){
    push(@menu, { TEXT => 'コンバート', TYPE => "href", VALUE => "./?mode=convert&url=$::in{url}" });
  }
  else {
    if($pc{logId}){
      push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => 'loglistOn()', });
      if($pc{reqdPassword}){ push(@menu, { TEXT => '復元', TYPE => "onclick", VALUE => "editOn()", }); }
      else                 { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}&log=$pc{logId}", }); }
    }
    else {
      if(!$pc{forbiddenMode}){
        push(@menu, { TEXT => 'パレット', TYPE => "onclick", VALUE => "chatPaletteOn()",   });
        push(@menu, { TEXT => '出力'    , TYPE => "onclick", VALUE => "downloadListOn()",  });
        push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => "loglistOn()",      });
      }
      if($pc{reqdPassword}){ push(@menu, { TEXT => '編集', TYPE => "onclick", VALUE => "editOn()", }); }
      else                 { push(@menu, { TEXT => '編集', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}", }); }
    }
  }
}
$SHEET->param(Menu => sheetMenuCreate @menu);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
if($pc{modeDownload}){
  if($pc{forbidden} && $pc{yourAuthor}){ $SHEET->param(forbidden => ''); }
  print downloadModeSheetConvert $SHEET->output;
}
else {
  print $SHEET->output;
}

1;