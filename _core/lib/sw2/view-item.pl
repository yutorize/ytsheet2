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

### アイテムデータ読み込み ###########################################################################
our %pc = getSheetData();

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
    $pc{itemName}   = noiseText(6,14);
    $pc{tags} = '';
  }
  
  $pc{price}      = noiseText(1,8);
  $pc{reputation} = noiseText(2,3);
  $pc{shape}      = noiseText(8,20);
  $pc{category}   = noiseText(2,8);
  $pc{age}        = noiseText(2,6);
  $pc{summary}    = noiseText(8,28);
  
  $pc{effects} = '';
  foreach(1..int(rand 4)+1){
    $pc{effects} .= noiseText(6,18)."\n";
    $pc{effects} .= '　'.noiseText(18,40)."\n";
    $pc{effects} .= '　'.noiseText(18,40)."\n" if(int rand 2);
    $pc{effects} .= "\n";
  }
  
  $pc{author} = $author;
  $pc{protect} = $protect;
  $pc{forbidden} = $forbidden;
  $pc{forbiddenMode} = 1;
}

### その他 --------------------------------------------------
$SHEET->param(rawName => $pc{itemName});

### タグ置換 #########################################################################################
foreach (keys %pc) {
  if($_ =~ /^(?:effects|description)$/){
    $pc{$_} = unescapeTagsLines($pc{$_});
  }
  $pc{$_} = unescapeTags($pc{$_});
}
$pc{effects} =~ s/<br>/\n/gi;
$pc{effects} =~ s#(<p>|</p>|</details>)#$1\n#gi;
$pc{effects} =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
if($::SW2_0){
  $pc{effects} =~ s/^((?:[○◯〇＞▶〆☆≫»□☐☑🗨▽▼]|&gt;&gt;)+.*?)(　|$)/&textToIcon($1).$2/egim;
} else {
  $pc{effects} =~ s/^((?:[○◯〇△＞▶〆☆≫»□☐☑🗨]|&gt;&gt;)+.*?)(　|$)/&textToIcon($1).$2/egim;
}
$pc{effects} =~ s/^((?:<i class="s-icon [a-z0]+?">.+?<\/i>)+.*?)(　|$)/<\/p><h5>$1<\/h5><p>$2/gim;
$pc{effects} =~ s/\n+<\/p>/<\/p>/gi;
$pc{effects} =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
$pc{effects} = "<p>$pc{effects}</p>";
$pc{effects} =~ s#(</p>|</details>)\n#$1#gi;
$pc{effects} =~ s/<p><\/p>//gi;
$pc{effects} =~ s#<h2>(.+?)</h2>#</dd><dt>$1</dt><dd class="box">#gi;
$pc{effects} =~ s/\n/<br>/gi;

### アップデート --------------------------------------------------
if($pc{ver}){
  %pc = data_update_item(\%pc);
}

### カラー設定 --------------------------------------------------
setColors();

### 出力準備 #########################################################################################
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

### 魔法の武器アイコン --------------------------------------------------
$SHEET->param(magic => ($pc{magic} ? "<img class=\"i-icon\" src=\"${set::icon_dir}wp_magic.png\">" : ''));

### カテゴリ --------------------------------------------------
$pc{category} =~ s/((?:\G|>)[^<]*?)[ 　]/$1<hr>/g;
$SHEET->param(category => $pc{category});

### 武器 --------------------------------------------------
my @weapons;
foreach (1 .. $pc{weaponNum}){
  next if !existsRow "weapon$_",'Usage','Reqd','Acc','Rate','Crit','Dmg','Note';
  push(@weapons, {
    USAGE => $pc{'weapon'.$_.'Usage'},
    REQD  => $pc{'weapon'.$_.'Reqd'},
    ACC   => $pc{'weapon'.$_.'Acc'} // '―',
    RATE  => $pc{'weapon'.$_.'Rate'},
    CRIT  => $pc{'weapon'.$_.'Crit'},
    DMG   => $pc{'weapon'.$_.'Dmg'} // '―',
    NOTE  => $pc{'weapon'.$_.'Note'},
  } );
}
$SHEET->param(WeaponData => \@weapons) if !$pc{forbiddenMode};

### 防具 --------------------------------------------------
my @armours;
foreach (1 .. $pc{armourNum}){
  next if !existsRow "armour$_",'Usage','Reqd','Eva','Def','Note';
  push(@armours, {
    USAGE => $pc{'armour'.$_.'Usage'},
    REQD  => $pc{'armour'.$_.'Reqd'},
    EVA   => $pc{'armour'.$_.'Eva'} // '―',
    DEF   => $pc{'armour'.$_.'Def'} // 0,
    NOTE  => $pc{'armour'.$_.'Note'},
  } );
}
$SHEET->param(ArmourData => \@armours) if !$pc{forbiddenMode};

### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{tags})){
    push(@tags, {
      URL  => uri_escape_utf8($_),
      TEXT => $_,
    });
}
$SHEET->param(Tags => \@tags);


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
  $SHEET->param(titleName => '非公開データ');
}
else {
  $SHEET->param(titleName => removeTags nameToPlain $pc{itemName});
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
#if($pc{image}) { $SHEET->param(ogImg => url()."/".$imgsrc); }
$SHEET->param(ogDescript => removeTags "カテゴリ:$pc{category}　形状:$pc{shape}　製作時期:$pc{age}　概要:$pc{summary}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'sw2');
$SHEET->param(sheetType => 'item');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{modeDownload}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './?type=i', });
  if($::in{url}){
    push(@menu, { TEXT => 'コンバート', TYPE => "href", VALUE => "./?mode=convert&url=$::in{url}" });
  }
  else {
    if($pc{logId}){
      push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => 'loglistOn()', });
      if($pc{reqdPassword}){ push(@menu, { TEXT => '復元', TYPE => "onclick", VALUE => "editOn()", }); }
      else                   { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}&log=$pc{logId}", }); }
    }
    else {
      if(!$pc{forbiddenMode}){
        push(@menu, { TEXT => '出力'    , TYPE => "onclick", VALUE => "downloadListOn()",  });
        push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => "loglistOn()",      });
      }
      if($pc{reqdPassword}){ push(@menu, { TEXT => '編集', TYPE => "onclick", VALUE => "editOn()", }); }
      else                   { push(@menu, { TEXT => '編集', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}", }); }
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