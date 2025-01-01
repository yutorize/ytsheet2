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
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### モンスターデータ読み込み #########################################################################
our %pc = getSheetData();

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
    $pc{$_} = unescapeTagsLines($pc{$_});
  }
  $pc{$_} = unescapeTags($pc{$_});
}
$pc{skills} =~ s/<br>/\n/gi;
$pc{skills} =~ s#(<p>|</p>|</details>)#$1\n#gi;
$pc{skills} =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
$pc{skills} = checkSkillName($pc{skills});
$pc{skills} =~ s/^((?:<i class="s-icon [a-z0]+?">.+?<\/i>)+.*?)(　|$)/<\/p><h5>$1<\/h5><p>$2/gim;
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

### キャラクター名 --------------------------------------------------
$SHEET->param(characterName => stylizeCharacterName $pc{characterName});
$SHEET->param(monsterName => stylizeCharacterName $pc{monsterName});

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

  my @prices = (
      ['購入', $pc{price}],
      ['レンタル', $pc{priceRental}],
      ['部位再生', $pc{priceRegenerate}],
  );

  foreach (@prices) {
    (my $term, my $value) = @{$_};
    my $annotation = $value =~ s/([(（].+?[）)])$// ? $1 : '';
    my $unit = $value =~ /\d$/ ? 'G' : '';

    $unit = "<small>$unit</small>" if $unit ne '';
    $annotation = "<small>$annotation</small>" if $annotation ne '';

    $price .= "<dt>$term</dt><dd>$value$unit$annotation</dd>" if $value;
  }

  if(!$price){ $price = '―' }
  $SHEET->param(price => "<dl class=\"price\">$price</dl>");
}
### 適正レベル --------------------------------------------------
my $appLv = $pc{lvMin}.($pc{lvMax} != $pc{lvMin} ? "～$pc{lvMax}":'');
{
  $SHEET->param(appLv => $appLv);
}
### 穢れ --------------------------------------------------
unless(
  ($pc{taxa} eq 'アンデッド' && ($pc{sin} == 5 || $pc{sin} eq '')) ||
  ($pc{taxa} ne '蛮族'       && ($pc{sin} == 0 || $pc{sin} eq ''))
){
  $SHEET->param(displaySin => 1);
}
### ステータス --------------------------------------------------
if($pc{vitResist} ne ''){ $SHEET->param(vitResist => $pc{vitResist}.(!$pc{statusTextInput}?' ('.$pc{vitResistFix}.')':'')) }
if($pc{mndResist} ne ''){ $SHEET->param(mndResist => $pc{mndResist}.(!$pc{statusTextInput}?' ('.$pc{mndResistFix}.')':'')) }

my @status_tbody;
my @status_row;
foreach (1 .. $pc{statusNum}){
  if ($pc{'status'.$_.'Accuracy'} ne ''){ $pc{'status'.$_.'Accuracy'} = $pc{'status'.$_.'Accuracy'}.(!$pc{statusTextInput} && !$pc{mount}?' ('.$pc{'status'.$_.'AccuracyFix'}.')':'') }
  if ($pc{'status'.$_.'Evasion'}  ne ''){ $pc{'status'.$_.'Evasion'}  = $pc{'status'.$_.'Evasion'} .(!$pc{statusTextInput} && !$pc{mount}?' ('.$pc{'status'.$_.'EvasionFix'}.')' :'') }

  $pc{'status'.$_.'Damage'} = '―' if $pc{'status'.$_.'Damage'} eq '2d+' && ($pc{'status'.$_.'Accuracy'} eq '' || $pc{'status'.$_.'Accuracy'} eq '―');
  
  push(@status_row, {
    LV       => $pc{lvMin},
    STYLE    => ($pc{'status'.$_.'Style'} =~ s#[(（].+[）)]#<span class="part">$&</span>#r),
    ACCURACY => $pc{'status'.$_.'Accuracy'} // '―',
    DAMAGE   => $pc{'status'.$_.'Damage'  } // '―',
    EVASION  => $pc{'status'.$_.'Evasion' } // '―',
    DEFENSE  => $pc{'status'.$_.'Defense' } // '―',
    HP       => $pc{'status'.$_.'Hp'      } // '―',
    MP       => $pc{'status'.$_.'Mp'      } // '―',
    VIT      => $pc{'status'.$_.'Vit'     } // '―',
    MND      => $pc{'status'.$_.'Mnd'     } // '―',
  } );
}
push(@status_tbody, { "ROW" => \@status_row }) if !$pc{mount} || $pc{lv} eq '' || $pc{lvMin} == $pc{lv};
foreach my $lv (2 .. ($pc{lvMax}-$pc{lvMin}+1)){
  my @status_row;
  foreach (1 .. $pc{statusNum}){
    my $num = "$_-$lv";

    $pc{'status'.$num.'Damage'} = '―' if $pc{'status'.$num.'Damage'} eq '2d+' && ($pc{'status'.$num.'Accuracy'} eq '' || $pc{'status'.$num.'Accuracy'} eq '―');

    push(@status_row, {
      LV       => $lv+$pc{lvMin}-1,
      STYLE    => ($pc{'status'.$_.'Style'} =~ s#[(（].+[）)]#<span class="part">$&</span>#r),
      ACCURACY => $pc{'status'.$num.'Accuracy'} // '―',
      DAMAGE   => $pc{'status'.$num.'Damage'  } // '―',
      EVASION  => $pc{'status'.$num.'Evasion' } // '―',
      DEFENSE  => $pc{'status'.$num.'Defense' } // '―',
      HP       => $pc{'status'.$num.'Hp'      } // '―',
      MP       => $pc{'status'.$num.'Mp'      } // '―',
      VIT      => $pc{'status'.$num.'Vit'     } // '―',
      MND      => $pc{'status'.$num.'Mnd'     } // '―',
    } );
  }
  push(@status_tbody, { ROW => \@status_row }) if !$pc{mount} || $pc{lv} eq '' || $lv+$pc{lvMin}-1 == $pc{lv};
}
$SHEET->param(Status => \@status_tbody);

### 部位 --------------------------------------------------
$SHEET->param(partsOn => 1) if ($pc{partsNum} > 1 || $pc{parts} || $pc{coreParts});
$SHEET->param(parts => $pc{parts} =~ s#([^／]+)#<span>$1</span>#gr);


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
  my($selected, $list) = getLogList($set::char_dir, $main::file);
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
  my $name    = removeTags removeRuby($pc{characterName});
  my $species = removeTags removeRuby($pc{monsterName});
  if($name && $species){ $SHEET->param(titleName => "${name}（${species}）"); }
  else { $SHEET->param(titleName => $name || $species); }
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
#if($pc{image}) { $SHEET->param(ogImg => url()."/".$imgsrc); }
$SHEET->param(ogDescript => removeTags(
  ($pc{mount} && $pc{lv} eq '' ? "適正レベル:$appLv" : "レベル:$pc{lv}").
  "　分類:$pc{taxa}".
  ($pc{partsNum} > 1 ? "　部位数:$pc{partsNum}" : '').
  (!$pc{mount} ? "　知名度:$pc{reputation}／$pc{'reputation+'}" : '')
));

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