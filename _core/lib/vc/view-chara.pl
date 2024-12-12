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
  path => ['./', $::core_dir."/skin/vc", $::core_dir."/skin/_common", $::core_dir],
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
    $pc{aka} = '';
    $pc{characterName} = noiseText(6,14);
    $pc{group} = $pc{areaTags} = $pc{tags} = '';
    
    $pc{age}    = noiseText(1,2);
    $pc{gender} = noiseText(1,2);
    $pc{eye}    = noiseText(1,6);
    $pc{skin}   = noiseText(1,6);
    $pc{hair}   = noiseText(1,6);
    $pc{height} = noiseText(2,4);

    $pc{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc{freeHistory} = '';
  }

  $pc{level} = noiseText(1);
  
  $pc{race}  = noiseText(3,8);
  $pc{class} = noiseText(3,8);
  $pc{style1} = noiseText(3,8);
  $pc{style2} = noiseText(3,8);
  $pc{vitality} = noiseText(1);
  $pc{technic}  = noiseText(1);
  $pc{clever}   = noiseText(1);
  $pc{carisma}  = noiseText(1);
  $pc{hpMax}  = noiseText(1,2);
  $pc{staminaAdd}  = 0;
  $pc{staminaMax}  = noiseText(1);
  $pc{staminaHalf}  = noiseText(1);

  foreach my $type ('Base','Race','Subtotal','Weapon','Head','Body','Acc1','Acc2','Other','Total'){
    $pc{'battle'.$type.'Name'} = noiseText(3,10);
    foreach my $stt ('Acc','Spl','Eva','Atk','Det','Def','Mdf','Ini','Str'){
      $pc{'battle'.$type.$stt} = noiseText(1);
    }
  }
  foreach my $num (1..2){
    $pc{'speciality'.$num.'Name'} = noiseText(3,8);
    $pc{'speciality'.$num.'Note'} = noiseText(8,22);
  }
  $pc{goodsNum} = int(rand 4)+2;
  foreach my $num (1..$pc{goodsNum}){
    $pc{'goods'.$num.'Name'} = noiseText(3,8);
    $pc{'goods'.$num.'Type'} = noiseText(2,5);
    $pc{'goods'.$num.'Note'} = noiseText(8,22);
  }
  $pc{itemsNum} = int(rand 4)+1;
  foreach my $num (1..$pc{itemsNum}){
    $pc{'item'.$num.'Name'} = noiseText(3,8);
    $pc{'item'.$num.'Type'} = noiseText(2,5);
    $pc{'item'.$num.'Note'} = noiseText(8,22);
  }

  $pc{resultPoint} = noiseText(1,3);

  $pc{historyNum} = 0;
  $pc{history0Result}   = noiseText(1,3);
  
  $pc{playerName} = $author;
  $pc{protect} = $protect;
  $pc{forbidden} = $forbidden;
  $pc{forbiddenMode} = 1;
}

### その他 --------------------------------------------------
$SHEET->param(rawName => $pc{characterName} || ($pc{aka} ? "“$pc{aka}”" : ''));

### タグ置換 #########################################################################################
if($pc{ver}){
  foreach (keys %pc) {
    next if($_ =~ /^image/);
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

### キャラクター名 --------------------------------------------------
$SHEET->param(characterName => stylizeCharacterName $pc{characterName});

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

### セリフ --------------------------------------------------
{
  my ($words, $x, $y) = stylizeWords($pc{words},$pc{wordsX},$pc{wordsY});
  $SHEET->param(words => $words);
  $SHEET->param(wordsX => $x);
  $SHEET->param(wordsY => $y);
}
### グッズ --------------------------------------------------
my @goods;
foreach my $num (1 .. $pc{goodsNum}){
  next if !existsRow "goods$num",'Name','Type','Note';
  push(@goods, {
    NAME => textName($pc{'goods'.$num.'Name'}),
    TYPE => textType($pc{'goods'.$num.'Type'}),
    NOTE => $pc{'goods'.$num.'Note'},
  });
}
$SHEET->param(Goods => \@goods);

sub textName {
  my $text = shift;
  my $check = $text;
  $check =~ s|<rp>(.+?)</rp>||g;
  $check =~ s|<rt>(.+?)</rt>||g;
  $check =~ s|<.+?>||g;
  if   (length($check) >= 11) { return '<span class="thinest">'.$text.'</span>'; }
  elsif(length($check) >= 10) { return '<span class="thiner">'.$text.'</span>'; }
  elsif(length($check) >=  9) { return '<span class="thin">'.$text.'</span>'; }
  return $text;
}
sub textType {
  my $text = shift;
  if(length($text) >= 5) { return '<span class="thinest">'.$text.'</span>'; }
  elsif(length($text) >= 4) { return '<span class="thin">'.$text.'</span>'; }
  return $text;
}

### アイテム --------------------------------------------------
my @items;
foreach my $num (1 .. $pc{itemsNum}){
  next if !existsRow "item$num",'Name','Type','Lv','Note';
  push(@items, {
    NAME => $pc{'item'.$num.'Name'},
    TYPE => textType($pc{'item'.$num.'Type'}),
    LV   => $pc{'item'.$num.'Lv'},
    NOTE => $pc{'item'.$num.'Note'},
  });
}
$SHEET->param(Items => \@items);
### 戦闘値 --------------------------------------------------
my @armaments;
foreach (
  ['Weapon','武器'],
  ['Head'  ,'頭防具'],
  ['Body'  ,'胴防具'],
  ['Acc1'  ,'装飾品'],
  ['Acc2'  ,'装飾品'],
){
  my $type = @{$_}[0];
  my $head = @{$_}[1];
  push(@armaments, {
    HEAD => $head,
    NAME => $pc{'battle'.$type.'Name'},
    ACC  => $pc{'battle'.$type.'Acc'},
    SPL  => $pc{'battle'.$type.'Spl'},
    EVA  => $pc{'battle'.$type.'Eva'},
    ATK  => $pc{'battle'.$type.'Atk'},
    DET  => $pc{'battle'.$type.'Det'},
    DEF  => $pc{'battle'.$type.'Def'},
    MDF  => $pc{'battle'.$type.'Mdf'},
    INI  => $pc{'battle'.$type.'Ini'},
    STR  => $pc{'battle'.$type.'Str'},
  });
}
$SHEET->param(Armaments => \@armaments);

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = 'キャラクター作成';
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Result','Gm','Member','Note');
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
    RESULT => $pc{'history'.$_.'Result'},
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);
$SHEET->param(historyExpTotal   => commify $pc{historyExpTotal}   );
$SHEET->param(payment           => commify $pc{payment}           );
$SHEET->param(historyMoneyTotal => commify $pc{historyMoneyTotal} );

### 携帯品 --------------------------------------------------
$pc{items} =~ s/[@＠]\[\s*?((?:[\+\-\*\/]?[0-9]+)+)\s*?\]/<i class="weight">$1<\/i>/g;
$SHEET->param(items => $pc{items});

### ゴールド --------------------------------------------------
if($pc{money} =~ /^(?:自動|auto)$/i){
  $SHEET->param(money => $pc{moneyTotal});
}
#if($pc{deposit} =~ /^(?:自動|auto)$/i){
#  $SHEET->param(deposit => $pc{depositTotal}.' G ／ '.$pc{debtTotal});
#}
$pc{cashbook} =~ s/(:(?:\:|&lt;|&gt;))((?:[\+\-\*\/]?[0-9]+)+)/$1.cashCheck($2)/eg;
  $SHEET->param(cashbook => $pc{cashbook});
sub cashCheck(){
  my $text = shift;
  my $num = s_eval($text);
  if   ($num > 0) { return '<b class="cash plus">'.$text.'</b>'; }
  elsif($num < 0) { return '<b class="cash minus">'.$text.'</b>'; }
  else { return '<b class="cash">'.$text.'</b>'; }
}

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
  $SHEET->param(titleName => removeTags removeRuby($pc{characterName}||"“$pc{aka}”"));
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
if($pc{image}) { $SHEET->param(ogImg => $pc{imageURL}); }
$SHEET->param(ogDescript => removeTags "種族:$pc{race}　クラス:$pc{class}　スタイル:$pc{style1}／$pc{style2}　レベル:$pc{level}　外見:$pc{gender}／$pc{age}／$pc{height}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'vc');
$SHEET->param(sheetType => 'chara');
$SHEET->param(generateType => 'VisionConnectPC');
$SHEET->param(defaultImage => $::core_dir.'/skin/vc/img/default_pc.png');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{modeDownload}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './', });
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