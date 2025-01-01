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
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  path => ['./', $::core_dir."/skin/blp", $::core_dir."/skin/_common", $::core_dir],
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
    $pc{group} = $pc{stage} = $pc{tags} = '';
  
    $pc{factor}  = noiseText(2,3);
    $pc{age}    = noiseText(1,2);
    $pc{gender} = noiseText(1,2);
    
    $pc{partner1Name} = noiseText(6,14);
    $pc{partner2Name} = noiseText(6,14);
    
    $pc{freeNote} = '';
    foreach(1..int(rand 3)+2){
      $pc{freeNote} .= '　'.noiseText(18,40)."\n";
    }
    $pc{freeHistory} = '';
  }
  
  $pc{factorCore}  = noiseText(2);
  $pc{factorStyle} = noiseText(2);
  $pc{level} = noiseText(1,2);
  $pc{statusMain1} = noiseText(1,2);
  $pc{statusMain2} = noiseText(1,2);
  $pc{endurance}  = noiseText(1,2);
  $pc{initiative} = noiseText(1,2);
  $pc{enduranceAdd}  = 0;
  $pc{initiativeAdd} = 0;
  $pc{enduranceGrow}  = 0;
  $pc{initiativeGrow} = 0;
  
  $pc{scarName} = noiseText(4,6);
  $pc{scarNote} = noiseText(10,15);
  
  foreach(1..3){
    $pc{'bloodarts'.$_.'Name'}     = noiseText(5,10);
    $pc{'bloodarts'.$_.'Timing'}   = noiseText(3,4);
    $pc{'bloodarts'.$_.'Target'}   = noiseText(2,5);
    $pc{'bloodarts'.$_.'Note'}     = noiseText(10,15);
  }
  $pc{artsNum} = int(rand 3) + 3;
  foreach('S',1..$pc{artsNum}){
    $pc{'arts'.$_.'Name'}     = noiseText(5,10);
    $pc{'arts'.$_.'Timing'}   = noiseText(3,4);
    $pc{'arts'.$_.'Target'}   = noiseText(2,5);
    $pc{'arts'.$_.'Cost'}     = noiseText(2,5);
    $pc{'arts'.$_.'Limited'}  = noiseText(2,4);
    $pc{'arts'.$_.'Note'}     = noiseText(10,15);
  }
  $pc{weaponNum} = $pc{armorNum} = $pc{itemNum} = $pc{historyNum} = 0;
  $pc{history0Exp} = noiseText(1,3);
  
  $pc{playerName} = $author;
  $pc{protect} = $protect;
  $pc{forbidden} = $forbidden;
  $pc{forbiddenMode} = 1;
}

### パートナーデータ取得 --------------------------------------------------
require $set::lib_convert if !$::in{url};
if(!$::in{log}){
  ## パートナー1
  if($pc{partner1Url} && $pc{partner1Auto}){
    my %pr = dataPartnerGet($pc{partner1Url});
    if($pr{convertSource}){
      if($pr{ver}){ %pr = data_update_chara(\%pr); }
      $pc{'p1_'.$_} = $pr{$_} foreach keys %pr;
      $pc{partner1Name}     = $pr{characterName};
      $pc{partner1NameRuby} = $pr{characterNameRuby};
      $pc{partner1Factor}  = $pr{factorCore}.'／'.$pr{factorStyle};
      $pc{partner1Age}     = ($pr{factor} eq '吸血鬼' ? $pr{ageApp}.'／' : '').$pr{age};
      $pc{partner1Gender}  = $pr{gender};
      $pc{partner1Missing} = $pr{missing};
      if($pr{convertSource} eq 'キャラクターシート倉庫'){
        $pc{partner1Url} = './?url='.$pc{partner1Url};
      }
      else {
        $pc{fromPartner1SealPosition} = $pr{'toPartner'.$pc{partnerOrder}.'SealPosition'};
        $pc{fromPartner1SealShape}    = $pr{'toPartner'.$pc{partnerOrder}.'SealShape'};
        $pc{fromPartner1Emotion1}     = $pr{'toPartner'.$pc{partnerOrder}.'Emotion1'};
        $pc{fromPartner1Emotion2}     = $pr{'toPartner'.$pc{partnerOrder}.'Emotion2'};
      }

      if($pr{forbidden}){
        $pc{partner1Name} = noiseText(6,14);
        $pc{partner1Factor} = noiseTextTag(noiseText(2)).'／'.noiseTextTag(noiseText(2));
        if($pr{forbidden} ne 'battle'){
          $pc{partner1Age}     = noiseTextTag(noiseText(2));
          $pc{partner1Gender}  = noiseTextTag(noiseText(2));
          $pc{partner1Missing} = noiseTextTag(noiseText(2));
        }
      }
    }
  }
  ## パートナー2
  if($pc{partner2Url} && $pc{partner2Auto}){
    my %pr = dataPartnerGet($pc{partner2Url});
    if($pr{convertSource}){
      $pc{'p2_'.$_} = $pr{$_} foreach keys %pr;
      $pc{partner2Name}     = $pr{characterName};
      $pc{partner2NameRuby} = $pr{characterNameRuby};
      $pc{partner2Factor}  = $pr{factorCore}.'／'.$pr{factorStyle};
      $pc{partner2Age}     = ($pr{factor} eq '吸血鬼' ? $pr{ageApp}.'／' : '').$pr{age};
      $pc{partner2Gender}  = $pr{gender};
      $pc{partner2Missing} = $pr{missing};
      my $num = ($pc{factor} eq '人間') ? 1 : ($pc{factor} eq '吸血鬼') ? 2 : 0;
      if($pr{convertSource} eq 'キャラクターシート倉庫'){
        $pc{partner2Url} = './?url='.$pc{partner2Url};
      }
      else {
        $pc{fromPartner2SealPosition} = $pr{'toPartner'.$num.'SealPosition'};
        $pc{fromPartner2SealShape}    = $pr{'toPartner'.$num.'SealShape'};
        $pc{fromPartner2Emotion1}     = $pr{'toPartner'.$num.'Emotion1'};
        $pc{fromPartner2Emotion2}     = $pr{'toPartner'.$num.'Emotion2'};
      }

      if($pr{forbidden}){
        $pc{partner2Name} = noiseText(6,14);
        $pc{partner2Factor} = noiseTextTag(noiseText(2)).'／'.noiseTextTag(noiseText(2));
        if($pr{forbidden} ne 'battle'){
          $pc{partner2Age}     = noiseTextTag(noiseText(2));
          $pc{partner2Gender}  = noiseTextTag(noiseText(2));
          $pc{partner2Missing} = noiseTextTag(noiseText(2));
        }
      }
    }
  }
  ## パートナー画像
  foreach my $num (1,2){
    next if !$pc{"p${num}_imageURL"};
    $pc{"p${num}_imageSrc"} = $pc{"p${num}_imageURL"};
    $pc{images} .= "'p${num}': \"".($pc{modeDownload} ? urlToBase64($pc{"p${num}_imagePath"}) : $pc{"p${num}_imageURL"})."\", ";
    if($pc{"p${num}_imageFit"} eq "p${num}_percentY"){
      $pc{"p${num}_imageFit"} = 'auto '.$pc{imagePercent}.'%';
    }
    elsif($pc{"p${num}_imageFit"} =~ /^percentX?$/){
      $pc{"p${num}_imageFit"} = $pc{"p${num}_imagePercent"}.'%';
    }
    if($pc{"p${num}_imageCopyrightURL"}){
      $pc{"p${num}_imageCopyright"} = "<a href=\"$pc{\"p${num}_imageCopyrightURL\"}\" target=\"_blank\">".($pc{"p${num}_imageCopyright"}||$pc{"p${num}_imageCopyrightURL"})."</a>";
    }
  }
}

### その他 --------------------------------------------------
$SHEET->param(rawName => $pc{characterName} || ($pc{aka} ? "“$pc{aka}”" : ''));

### タグ置換 #########################################################################################
if($pc{ver}){
  foreach (keys %pc) {
    next if($_ =~ /^(?:partner[12]Url|(?:p[12]_)?(?:image))/);
    if($_ =~ /^(?:freeNote|freeHistory)$/){
      $pc{$_} = unescapeTagsLines($pc{$_});
    }
    $pc{$_} = unescapeTags($pc{$_});

    $pc{$_} = noiseTextTag $pc{$_} if $pc{forbiddenMode};
  }
}

### アップデート --------------------------------------------------
if($pc{ver}){
  %pc = data_update_chara(\%pc);
}

### カラー設定 --------------------------------------------------
setColors();
setColors('p1_');
setColors('p2_');

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
### キャラクター名 --------------------------------------------------
foreach ('characterName','partner1Name','partner2Name'){
  $SHEET->param($_ => stylizeCharacterName $pc{$_},$pc{$_.'Ruby'});
}
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
foreach ('','p1_','p2_'){
  my ($words, $x, $y) = stylizeWords($pc{$_."words"},$pc{$_."wordsX"},$pc{$_."wordsY"});
  $SHEET->param($_."words" => $words);
  $SHEET->param($_."wordsX" => $x);
  $SHEET->param($_."wordsY" => $y);
}
### ファクター --------------------------------------------------
if   ($pc{factor} eq '人間'){
  $SHEET->param(typeH  => 1);
  $SHEET->param(head_statusMain1 => '<i class="spade">♠</i>技');
  $SHEET->param(head_statusMain2 => '<i class="club" >♣</i>情');
  $SHEET->param(enduranceFormula  => "($pc{statusMain1}×2+$pc{statusMain2})" . addNum($pc{enduranceAdd}) . addNum($pc{enduranceGrow}));
  $SHEET->param(initiativeFormula => "($pc{statusMain2}+10)" . addNum($pc{initiativeAdd}) . addNum($pc{initiativeGrow}));
  $SHEET->param(head_p1 => '血契'.($pc{partner2On}?'１':''));
  $SHEET->param(head_p2 => '血契２');
  $SHEET->param(class_p2 => 'seal');
}
elsif($pc{factor} eq '吸血鬼'){
  $SHEET->param(typeV  => 1);
  $SHEET->param(head_statusMain1 => '<i class="heart">♥</i>血');
  $SHEET->param(head_statusMain2 => '<i class="dia"  >♦</i>想');
  $SHEET->param(enduranceFormula  => "($pc{statusMain1}+20)" . addNum($pc{enduranceAdd}) . addNum($pc{enduranceGrow}));
  $SHEET->param(initiativeFormula => "($pc{statusMain2}+4)" . addNum($pc{initiativeAdd}) . addNum($pc{initiativeGrow}));
  $SHEET->param(head_p1 => '血契');
  $SHEET->param(head_p2 => '連血鬼');
  $SHEET->param(class_p2 => 'union');
}
else {
  $SHEET->param(head_p1 => '血契');
  $SHEET->param(head_p2 => noiseText(2));
}
### パートナー --------------------------------------------------

### 血威 --------------------------------------------------
my @bloodarts;
foreach (1 .. 3){
  next if !existsRow "bloodarts$_",'Name','Timing','Target','Note';
  push(@bloodarts, {
    NAME   => $pc{'bloodarts'.$_.'Name'},
    LV     => $pc{'bloodarts'.$_.'Lv'},
    TIMING => $pc{'bloodarts'.$_.'Timing'},
    TARGET => textTarget($pc{'bloodarts'.$_.'Target'}),
    NOTE   => $pc{'bloodarts'.$_.'Note'},
  });
}
$SHEET->param(Bloodarts => \@bloodarts);

### 特技 --------------------------------------------------
my @arts;
foreach (1 .. $pc{artsNum}){
  next if !existsRow "arts$_",'Name','Timing','Target','Cost','Limited','Note';
  push(@arts, {
    NAME    => $pc{'arts'.$_.'Name'},
    LV      => $pc{'arts'.$_.'Lv'},
    TIMING  => $pc{'arts'.$_.'Timing'},
    TARGET  => textTarget($pc{'arts'.$_.'Target'}),
    COST    => textCost($pc{'arts'.$_.'Cost'}),
    LIMITED => textCost($pc{'arts'.$_.'Limited'}),
    NOTE    => $pc{'arts'.$_.'Note'},
  });
}
if( $pc{scarName} && ($pc{artsSLv} || $pc{artsSLv} || $pc{artsSTiming} || $pc{artsSTarget} || $pc{artsSCost} || $pc{artsSLimited} || $pc{artsSNote}) ){
  push(@arts, {
    NAME    => '<b class="arts-scar-head">傷号:</b><span>'.$pc{scarName}.'</span>',
    LV      => $pc{artsSLv},
    TIMING  => $pc{artsSTiming},
    TARGET  => textTarget($pc{artsSTarget}),
    COST    => textCost($pc{artsSCost}),
    LIMITED => textCost($pc{artsSLimited}),
    NOTE    => $pc{artsSNote},
  });
}
$SHEET->param(Arts => \@arts);

sub textTarget {
  my $text = shift;
  $text =~ s#[(（](.+?)[)）]#<span>($1)</span>#;
  return $text;
}
sub textCost {
  my $text = shift;
  $text =~ s#^(.+?)((?:絵札)?[0-9０-９].*?)$#<span>$1</span><span>$2</span>#;
  return $text;
}

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
if($pc{endurancePreGrow }){ $pc{history0Grow} .= "耐久値+$pc{endurancePreGrow }" }
if($pc{history0Grow     }){ $pc{history0Grow} .= " " }
if($pc{initiativePreGrow}){ $pc{history0Grow} .= "先制値+$pc{initiativePreGrow}" }
if($pc{history0Grow}){
  $pc{history0Title} = 'キャラクター作成';
}
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Grow','Gm','Member','Note');
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
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、]+/$1　/g;
  foreach my $mem (split(/　/,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  push(@history, {
    NUM    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE   => $pc{'history'.$_.'Date'},
    TITLE  => $pc{'history'.$_.'Title'},
    GROW   => ($pc{'history'.$_.'Grow'} eq 'endurance'  ? '耐久値+5'
             : $pc{'history'.$_.'Grow'} eq 'initiative' ? '先制値+2'
             : $pc{'history'.$_.'Grow'}),
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);

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
  $SHEET->param(titleName => removeTags removeRuby($pc{characterName}||"“$pc{aka}”"));
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
if($pc{image}) { $SHEET->param(ogImg => $pc{imageURL}); }
$SHEET->param(ogDescript => removeTags "ファクター:$pc{factor}／$pc{factorCore}／$pc{factorStyle}　性別:$pc{gender}　年齢:$pc{age}　".($pc{factor} eq '吸血鬼' ? '欠落':'喪失').":$pc{missing}　所属:$pc{belong}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'blp');
$SHEET->param(sheetType => 'chara');
$SHEET->param(generateType => 'BloodPathPC');
$SHEET->param(defaultImage => $::core_dir.'/skin/blp/img/default_pc.png');

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
      else                   { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}&log=$pc{logId}", }); }
    }
    else {
      if(!$pc{forbiddenMode}){
        push(@menu, { TEXT => 'パレット', TYPE => "onclick", VALUE => "chatPaletteOn()",   });
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