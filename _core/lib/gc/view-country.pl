################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_class;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  path => ['./', $::core_dir."/skin/gc", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  loop_context_vars => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### キャラクターデータ読み込み #######################################################################
our %pc = getSheetData();

### タグ置換前処理 ###################################################################################
### 閲覧禁止データ --------------------------------------------------
if($pc{forbidden} && !$pc{yourAuthor}){
  my $author = $pc{playerName};
  my $protect   = $pc{protect};
  my $forbidden = $pc{forbidden};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{countryName} = noiseText(6,14);
    $pc{group} = $pc{areaTags} = $pc{tags} = '';

    $pc{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc{freeHistory} = '';
  }

  $pc{historyNum} = 0;
  $pc{history0Result}   = noiseText(1,3);
  
  $pc{playerName} = $author;
  $pc{protect} = $protect;
  $pc{forbidden} = $forbidden;
  $pc{forbiddenMode} = 1;
}

### その他 --------------------------------------------------
$SHEET->param(rawName => $pc{countryName});

### タグ置換 #########################################################################################
if($pc{ver}){
  foreach (keys %pc) {
    next if($_ =~ /^image|URL$/);
    if($_ =~ /^(?:items|freeNote|freeHistory|cashbook)$/){
      $pc{$_} = unescapeTagsLines($pc{$_});
    }
    $pc{$_} = unescapeTags($pc{$_});

    $pc{$_} = noiseTextTag $pc{$_} if $pc{forbiddenMode};
  }
}
else {
  $pc{items} = $pc{itemsView} if $pc{itemsView};
  $pc{freeNote} = $pc{freeNoteView} if $pc{freeNoteView};
}

### アップデート --------------------------------------------------
if($pc{ver}){
  %pc = data_update_chara(\%pc);
}

### カラー設定 --------------------------------------------------
setColors();

### その他 --------------------------------------------------
if(!$pc{forbidden}){
  foreach my $stt ('Acc','Spl','Eva','Atk','Det','Def','Mdf','Ini','Str'){
    foreach my $type ('Race','Weapon','Head','Body','Acc1','Acc2','Other'){
      $pc{'battle'.$type.$stt} &&= addNum $pc{'battle'.$type.$stt};
    }
  }
}
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

### 国名 --------------------------------------------------
$SHEET->param(countryName => stylizeCharacterName $pc{countryName});

### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $::in{id}))[0];
  $SHEET->param(playerName => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{playerName}.'</a>');
}
### グループ --------------------------------------------------
if($::in{url}){
  $SHEET->param(group => '');
}
else {
  if(!$pc{group}) {
    $pc{group} = $set::group_default;
    $SHEET->param(group => $set::group_default);
  }
  foreach (@set::groups){
    if($pc{group} eq @$_[0]){
      $SHEET->param(groupName => @$_[2]);
      last;
    }
  }
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

### 国特徴 --------------------------------------------------
{
  my @row;
  foreach (1..$pc{characteristicNum}){
    next if (!existsRow "characteristic${_}",'Name','Food','Tech','Horse','Mineral','Forest','Funds','Note');
    push(@row, {
      NAME   => $pc{"characteristic${_}Name"},
      FOOD   => $pc{"characteristic${_}Food"},
      TECH   => $pc{"characteristic${_}Tech"},
      HORSE  => $pc{"characteristic${_}Horse"},
      MINERAL=> $pc{"characteristic${_}Mineral"},
      FOREST => $pc{"characteristic${_}Forest"},
      FUNDS  => $pc{"characteristic${_}Funds"},
      NOTE   => $pc{"characteristic${_}Note"},
    });
  }
  $SHEET->param(Characteristics => \@row);
}
### メンバー --------------------------------------------------
{
  my @row;
  foreach (1..$pc{memberNum}){
    next if (!existsRow "member${_}",'Name','Class','Style','Note');
    my $name = $pc{"member${_}Name"};
    if($pc{"member${_}URL"}){ $name = '<a href="'.$pc{"member${_}URL"}.'">'.$name.'</a>' }
    push(@row, {
      NAME  => $name,
      CLASS => $pc{"member${_}Class"},
      STYLE => $pc{"member${_}Style"},
      NOTE  => $pc{"member${_}Note"},
    });
  }
  $SHEET->param(Members => \@row);
}
### アカデミーサポート --------------------------------------------------
{
  my @row;
  foreach (1..$pc{academySupportNum}){
    next if (!existsRow "academySupport${_}",'Name','Class','Style','Cost','Note');
    push(@row, {
      NAME   => $pc{"academySupport${_}Name"},
      LV     => $pc{"academySupport${_}Lv"},
      TIMING => $pc{"academySupport${_}Timing"},
      TARGET => $pc{"academySupport${_}Target"},
      COST   => $pc{"academySupport${_}Cost"},
      NOTE   => $pc{"academySupport${_}Note"},
    });
  }
  $SHEET->param(AcademySupports => \@row);
}
### アーティファクト --------------------------------------------------
{
  my @row;
  foreach (1..$pc{artifactNum}){
    next if (!existsRow "artifact${_}",'Name','Class','Style','Cost','Note');
    push(@row, {
      NAME    => $pc{"artifact${_}Name"},
      TIMING  => $pc{"artifact${_}Timing"},
      TARGET  => $pc{"artifact${_}Target"},
      LV      => $pc{"artifact${_}Lv"},
      COST    => $pc{"artifact${_}Cost"},
      QUANTITY=> $pc{"artifact${_}Quantity"} || 0,
      NOTE    => $pc{"artifact${_}Note"},
    });
  }
  $SHEET->param(Artifacts => \@row);
}
### 部隊 --------------------------------------------------
{
  my @row;
  foreach (1..$pc{forceNum}){
    next if (!existsRow "force${_}",'Type','Lv','CostFood','CostTech','CostHorse','CostMineral','CostForest','CostFunds','Note');
    push(@row, {
      TYPE   => $pc{"force${_}Type"},
      LV     => $pc{"force${_}Lv"},
      FOOD   => $pc{"force${_}CostFood"},
      TECH   => $pc{"force${_}CostTech"},
      HORSE  => $pc{"force${_}CostHorse"},
      MINERAL=> $pc{"force${_}CostMineral"},
      FOREST => $pc{"force${_}CostForest"},
      FUNDS  => $pc{"force${_}CostFunds"},
      NOTE   => $pc{"force${_}Note"},
    });
  }
  $SHEET->param(Forces => \@row);
}

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = "シート作成（爵位：$pc{makePeerage}）";
$pc{history0Counts} = $set::peerageRank{$pc{makePeerage}}{counts};
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Counts','Gm','Member','Note');
  $h_num++ if $pc{'history'.$_.'Gm'};
  if ($set::log_dir && $pc{'history'.$_.'Date'} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
    my $room = $1;
    (my $date = $pc{'history'.$_.'Date'}) =~ s/[\-\/]//g;
    $pc{'history'.$_.'Date'} = "<a href=\"$set::log_dir$date$room.html\">$pc{'history'.$_.'Date'}<\/a>";
  }
  if ($set::sessionlist && $pc{'history'.$_.'Title'} =~ s/^#([0-9]+)//){
    $pc{'history'.$_.'Title'} = "<a href=\"$set::sessionlist?num=$1\" data-num=\"$1\">$pc{'history'.$_.'Title'}<\/a>";
  }
  my $members;
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、 ]+/$1　/g;
  foreach my $mem (split(/　/,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  $pc{'history'.$_.'Money'} = formatHistoryFigures($pc{'history'.$_.'Money'});
  push(@history, {
    NUM    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE   => $pc{'history'.$_.'Date'},
    TITLE  => $pc{'history'.$_.'Title'},
    COUNTS => $pc{'history'.$_.'Counts'},
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);
$SHEET->param(historyCountsTotal   => commify $pc{countsTotal}   );

### バックアップ --------------------------------------------------
if($::in{id}){
  my($selected, $list) = getLogList($set::char_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{yourAuthor} || $pc{protect} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

### フェロー --------------------------------------------------
$SHEET->param(FellowMode => $::in{f});

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{forbidden} eq 'all' && $pc{forbiddenMode}){
  $SHEET->param(titleName => '非公開データ');
}
else {
  $SHEET->param(titleName => removeTags removeRuby($pc{countryName}));
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
if($pc{image}) { $SHEET->param(ogImg => $pc{imageURL}); }
$SHEET->param(ogDescript => removeTags "レベル:$pc{level}　爵位:$pc{peerage}　ロード:$pc{lordName}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'gc');
$SHEET->param(sheetType => 'country');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{modeDownload}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './?type=c', });
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