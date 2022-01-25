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
our %pc = pcDataGet();

### 閲覧禁止データ ###################################################################################
if($pc{'forbidden'}){
  my $author = $pc{'playerName'};
  my $protect   = $pc{'protect'};
  my $forbidden = $pc{'forbidden'};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{'aka'} = '';
    $pc{'characterName'} = noiseText(6,14);
    $pc{'group'} = $pc{'stage'} = $pc{'tags'} = '';
  
    $pc{'factor'}  = noiseText(2,3);
    $pc{'age'}    = noiseText(1,2);
    $pc{'gender'} = noiseText(1,2);
    
    $pc{'partner1Name'} = noiseText(6,14);
    $pc{'partner2Name'} = noiseText(6,14);
    
    $pc{'freeNote'} = '';
    foreach(1..int(rand 3)+2){
      $pc{'freeNote'} .= '　'.noiseText(18,40)."\n";
    }
    $pc{'freeHistory'} = '';
  }
  
  $pc{'type'}  = noiseText(4);
  $pc{'negaiOutside'} = noiseText(2);
  $pc{'negaiInside'}  = noiseText(2);
  $pc{'endurance'} = noiseText(1,2);
  $pc{'operation'} = noiseText(1,2);
  $pc{'enduranceAdd'}  = 0;
  $pc{'operationAdd'}  = 0;
  $pc{'enduranceGrow'} = 0;
  $pc{'operationGrow'} = 0;
  $pc{'enduranceFormula'} = noiseText(5,7);
  $pc{'operationFormula'} = noiseText(5,7);
  
  foreach(1..3){
    $pc{'bloodarts'.$_.'Name'}     = noiseText(5,10);
    $pc{'bloodarts'.$_.'Timing'}   = noiseText(3,4);
    $pc{'bloodarts'.$_.'Target'}   = noiseText(2,5);
    $pc{'bloodarts'.$_.'Note'}     = noiseText(10,15);
  }
  $pc{'kizuatoNum'} = int(rand 3) + 1;
  foreach(1..$pc{'kizuatoNum'}){
    $pc{'kizuato'.$_.'Name'}     = noiseText(5,10);
    $pc{'kizuato'.$_.'DramaTiming'}   = noiseText(3,4);
    $pc{'kizuato'.$_.'DramaTarget'}   = noiseText(2,5);
    $pc{'kizuato'.$_.'DramaHitogara'} = noiseText(4,8);
    $pc{'kizuato'.$_.'DramaLimited'}  = noiseText(2,4);
    $pc{'kizuato'.$_.'DramaNote'}     = noiseText(10,15);
    $pc{'kizuato'.$_.'BattleTiming'}   = noiseText(3,4);
    $pc{'kizuato'.$_.'BattleTarget'}   = noiseText(2,5);
    $pc{'kizuato'.$_.'BattleCost'}     = noiseText(2,5);
    $pc{'kizuato'.$_.'BattleLimited'}  = noiseText(2,4);
    $pc{'kizuato'.$_.'BattleNote'}     = noiseText(10,15);
  }
  $pc{'historyNum'} = 0;
  $pc{'history0Exp'} = noiseText(1,3);
  
  $pc{'playerName'} = $author;
  $pc{'protect'} = $protect;
  $pc{'forbidden'} = $forbidden;
  $pc{'forbiddenMode'} = 1;
}

### 置換前出力 #######################################################################################
### パートナーデータ取得 --------------------------------------------------
require $set::lib_convert if !$::in{'url'};
if(!$::in{'backup'}){
  if($pc{'partner1Url'} && $pc{'partner1Auto'}){
    my %pr = dataPartnerGet($pc{'partner1Url'});
    if($pr{'convertSource'}){
      if($pr{'ver'}){ %pr = data_update_chara(\%pr); }
      $pc{'p1_'.$_} = $pr{$_} foreach keys %pr;
      $pc{'partner1Name'}     = $pr{'characterName'};
      $pc{'partner1NameRuby'} = $pr{'characterNameRuby'};
      $pc{'partner1Type'}    = $pr{'type'};
      $pc{'partner1Age'}     = $pr{'age'};
      $pc{'partner1Gender'}  = $pr{'gender'};
      $pc{'partner1NegaiOutside'} = $pr{'negaiOutside'};
      $pc{'partner1NegaiInside'}  = $pr{'negaiInside'};
      if($pr{'convertSource'} eq 'キャラクターシート倉庫'){
        ($pc{'p1_imageSrc'} = $pc{'partner1Url'}) =~ s/edit\.html/image/;
        $pc{'p1_image'} = LWP::UserAgent->new->simple_request(HTTP::Request->new(GET => $pc{'p1_imageSrc'}))->code == 200;
        $pc{'partner1Url'} = './?url='.$pc{'partner1Url'};
      }
      else {
        $pc{'fromPartner1MarkerPosition'} = $pr{'toPartner'.$pc{'partnerOrder'}.'MarkerPosition'};
        $pc{'fromPartner1MarkerColor'}    = $pr{'toPartner'.$pc{'partnerOrder'}.'MarkerColor'};
        $pc{'fromPartner1Emotion1'}     = $pr{'toPartner'.$pc{'partnerOrder'}.'Emotion1'};
        $pc{'fromPartner1Emotion2'}     = $pr{'toPartner'.$pc{'partnerOrder'}.'Emotion2'};
        $pc{'p1_imageSrc'} = $pr{'imageURL'}."?$pr{'imageUpdate'}";
      }
      if($pr{'forbidden'}){
        $pc{'partner1Name'} = noiseText(6,14);
        $pc{'partner1Type'} = noiseTextTag(noiseText(4));
        if($pr{'forbidden'} ne 'battle'){
          $pc{'partner1Age'}     = noiseTextTag(noiseText(2));
          $pc{'partner1Gender'}  = noiseTextTag(noiseText(2));
          $pc{'partner1NegaiOutside'} = noiseTextTag(noiseText(2));
          $pc{'partner1NegaiInside'}  = noiseTextTag(noiseText(2));
        }
      }
    }
  }
  if($pc{'partner2Url'} && $pc{'partner2Auto'}){
    my %pr = dataPartnerGet($pc{'partner2Url'});
    if($pr{'convertSource'}){
      $pc{'p2_'.$_} = $pr{$_} foreach keys %pr;
      $pc{'partner2Name'}     = $pr{'characterName'};
      $pc{'partner2NameRuby'} = $pr{'characterNameRuby'};
      $pc{'partner2Type'}    = $pr{'type'};
      $pc{'partner2Age'}     = $pr{'age'};
      $pc{'partner2Gender'}  = $pr{'gender'};
      $pc{'partner2NegaiOutside'} = $pr{'negaiOutside'};
      $pc{'partner2NegaiInside'}  = $pr{'negaiInside'};
      my $num = ($pc{'type'} eq 'オーナー') ? 1 : ($pc{'type'} eq 'ハウンド') ? 2 : 0;
      $pc{'fromPartner2MarkerPosition'} = $pr{'toPartner'.$num.'MarkerPosition'};
      $pc{'fromPartner2MarkerColor'}    = $pr{'toPartner'.$num.'MarkerColor'};
      $pc{'fromPartner2Emotion1'}     = $pr{'toPartner'.$num.'Emotion1'};
      $pc{'fromPartner2Emotion2'}     = $pr{'toPartner'.$num.'Emotion2'};
      $pc{'p2_imageSrc'} = $pr{'imageURL'}."?$pr{'imageUpdate'}";
    }
  }
}
### 置換 #############################################################################################
if($pc{'ver'}){
  foreach (keys %pc) {
    next if($_ =~ /^(?:partner[12]Url|(?:p[12]_)?(?:imageURL|imageSrc|imageCopyrightURL))$/);
    if($_ =~ /^(?:freeNote|freeHistory)$/){
      $pc{$_} = tag_unescape_lines($pc{$_});
    }
    $pc{$_} = tag_unescape($pc{$_});

    $pc{$_} = noiseTextTag $pc{$_} if $pc{'forbiddenMode'};
  }
}

### アップデート --------------------------------------------------
if($pc{'ver'}){
  %pc = data_update_chara(\%pc);
}

### 出力準備 #########################################################################################
### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param("id" => $::in{'id'});

if($::in{'url'}){
  $SHEET->param("convertMode" => 1);
  $SHEET->param("convertUrl" => $::in{'url'});
}
### キャラクター名 --------------------------------------------------
foreach ('characterName','partner1Name','partner2Name'){
  $SHEET->param($_ => "<ruby>$pc{$_}<rt>$pc{$_.'Ruby'}</rt></ruby>") if $pc{$_.'Ruby'};
}
### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $::in{'id'}))[0];
  $SHEET->param("playerName" => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{'playerName'}.'</a>');
}
### グループ --------------------------------------------------
if($::in{'url'}){
  $SHEET->param(group => '');
}
else {
  if(!$pc{'group'}) {
    $pc{'group'} = $set::group_default;
    $SHEET->param(group => $set::group_default);
  }
  foreach (@set::groups){
    if($pc{'group'} eq @$_[0]){
      $SHEET->param(groupName => @$_[2]);
      last;
    }
  }
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

### セリフ --------------------------------------------------
foreach ('','p1_','p2_'){
  $pc{$_.'words'} =~ s/<br>/\n/g;
  $pc{$_.'words'} =~ s/^([「『（])/<span class="brackets">$1<\/span>/gm;
  $pc{$_.'words'} =~ s/(.+?(?:[，、。？」』）]|$))/<span>$1<\/span>/g;
  $pc{$_.'words'} =~ s/\n<span>　/\n<span>/g;
  $pc{$_.'words'} =~ s/\n/<br>/g;
  $SHEET->param($_."words" => $pc{$_.'words'});
  $SHEET->param($_."wordsX" => ($pc{$_.'wordsX'} eq '左' ? 'left:0;' : 'right:0;'));
  $SHEET->param($_."wordsY" => ($pc{$_.'wordsY'} eq '下' ? 'bottom:0;' : 'top:0;'));
}

### 種別 --------------------------------------------------
if   ($pc{'type'} eq 'オーナー'){
  $SHEET->param(typeO  => 1);
  $SHEET->param(head_p1 => 'パートナー'.($pc{'partner2On'}?'１':''));
  $SHEET->param(head_p2 => 'パートナー２');
  $SHEET->param(class_p2 => 'marker');
}
elsif($pc{'type'} eq 'ハウンド'){
  $SHEET->param(typeH  => 1);
  $SHEET->param(head_p1 => 'パートナー');
  $SHEET->param(head_p2 => 'アナザー');
  $SHEET->param(class_p2 => 'another');
}
else {
  $SHEET->param(head_p1 => 'パートナー');
  $SHEET->param(head_p2 => noiseText(2));
}

### 能力値 --------------------------------------------------
if(!$pc{'forbiddenMode'}){
  $SHEET->param(enduranceFormula => "$pc{'enduranceType'}+$pc{'enduranceOutside'}+$pc{'enduranceInside'}".(addNum $pc{'enduranceAdd'}).(addNum $pc{'enduranceGrow'}));
  $SHEET->param(operationFormula => "$pc{'operationType'}+$pc{'operationOutside'}+$pc{'operationInside'}".(addNum $pc{'operationAdd'}).(addNum $pc{'operationGrow'}));
}

### キズナ --------------------------------------------------
my @kizuna;
foreach (1 .. $pc{'kizunaNum'}){
  next if(!$pc{'kizuna'.$_.'Name'} && !$pc{'kizuna'.$_.'Note'}   && !$pc{'kizuna'.$_.'Hibi'}  && !$pc{'kizuna'.$_.'Ware'});
  push(@kizuna, {
    "NAME" => $pc{'kizuna'.$_.'Name'},
    "NOTE" => $pc{'kizuna'.$_.'Note'},
    "HIBI" => ($pc{'kizuna'.$_.'Hibi'}?'hibi':''),
    "WARE" => ($pc{'kizuna'.$_.'Ware'}?'ware':''),
  });
}
$SHEET->param(Kizuna => \@kizuna);

### キズアト --------------------------------------------------
my @kizuato;
foreach (1 .. $pc{'kizuatoNum'}){
  next if(
    !$pc{'kizuato'.$_.'Name'} &&
    !$pc{'kizuato'.$_.'DramaTiming'}   && !$pc{'kizuato'.$_.'BattleTiming'}  && 
    !$pc{'kizuato'.$_.'DramaTarget'}   && !$pc{'kizuato'.$_.'BattleTarget'}  && 
    !$pc{'kizuato'.$_.'DramaHitogara'} && !$pc{'kizuato'.$_.'BattleCost'}    && 
    !$pc{'kizuato'.$_.'DramaLimited'}  && !$pc{'kizuato'.$_.'BattleLimited'} && 
    !$pc{'kizuato'.$_.'DramaNote'}     && !$pc{'kizuato'.$_.'BattleNote'}    
  );
  push(@kizuato, {
    "NAME"     => $pc{'kizuato'.$_.'Name'},
    "D-TIMING"   => $pc{'kizuato'.$_.'DramaTiming'},
    "D-TARGET"   => textTarget($pc{'kizuato'.$_.'DramaTarget'}),
    "D-HITOGARA" => textHitogara($pc{'kizuato'.$_.'DramaHitogara'}),
    "D-LIMITED"  => $pc{'kizuato'.$_.'DramaLimited'},
    "D-NOTE"     => $pc{'kizuato'.$_.'DramaNote'},
    "B-TIMING"   => $pc{'kizuato'.$_.'BattleTiming'},
    "B-TARGET"   => textTarget($pc{'kizuato'.$_.'BattleTarget'}),
    "B-COST"     => $pc{'kizuato'.$_.'BattleCost'},
    "B-LIMITED"  => $pc{'kizuato'.$_.'BattleLimited'},
    "B-NOTE"     => $pc{'kizuato'.$_.'BattleNote'},
  });
}
$SHEET->param(Kizuato => \@kizuato);

sub textHitogara {
  my $text = shift;
  $text =~ s#[:：](.+?)$#：<span>$1</span>#;
  return $text;
}
sub textTarget {
  my $text = shift;
  $text =~ s#[(（](.+?)[)）]#<span>($1)</span>#;
  return $text;
}

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{'history0Title'} = 'キャラクター作成';
foreach (0 .. $pc{'historyNum'}){
  #next if !$pc{'history'.$_.'Title'};
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
    "NUM"    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    "DATE"   => $pc{'history'.$_.'Date'},
    "TITLE"  => $pc{'history'.$_.'Title'},
    "GROW"   => ($pc{'history'.$_.'Grow'} eq 'endurance' ? '耐久値+2'
               : $pc{'history'.$_.'Grow'} eq 'operation' ? '先制値+1'
               : ''),
    "GM"     => $pc{'history'.$_.'Gm'},
    "MEMBER" => $members,
    "NOTE"   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);

### カラーカスタム --------------------------------------------------
foreach ('','p1_','p2_'){
  $SHEET->param($_."colorBaseBgS" => $pc{$_."colorBaseBgS"} * 0.7);
  $SHEET->param($_."colorBaseBgL" => 100 - $pc{$_."colorBaseBgS"} / 6);
  $SHEET->param($_."colorBaseBgD" => 15);
}

### バックアップ --------------------------------------------------
if($::in{'id'}){
  my($selected, $list) = getBackupList($set::char_dir, $main::file);
  $SHEET->param(Backup => $list);
  $SHEET->param(selectedBackupName => $selected);
  if($::in{'backup'} && ( $pc{'yourAuthor'} || $pc{'protect'} eq 'password' )){
    $SHEET->param(viewBackupNaming => 1);
  }
}

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{'forbidden'} eq 'all' && $pc{'forbiddenMode'}){
  $SHEET->param(characterNameTitle => '非公開データ');
}
else {
  $SHEET->param(characterNameTitle => tag_delete name_plain($pc{'characterName'}||"“$pc{'aka'}”"));
}

### 画像 --------------------------------------------------
my $imgsrc;
if($pc{'convertSource'} eq 'キャラクターシート倉庫'){
  ($imgsrc = $::in{'url'}) =~ s/edit\.html/image/;
  my $code = LWP::UserAgent->new->simple_request(HTTP::Request->new(GET => $imgsrc))->code == 200;
  $SHEET->param("image" => $code);
}
elsif($pc{'convertSource'} eq '別のゆとシートⅡ') {
  $imgsrc = $pc{'imageURL'}."?$pc{'imageUpdate'}";
}
else {
  $imgsrc = "${set::char_dir}${main::file}/image.$pc{'image'}?$pc{'imageUpdate'}";
}
$SHEET->param("imageSrc" => $imgsrc);

## パートナー
foreach ('','p1_','p2_'){
  if($pc{$_.'imageFit'} eq 'percentY'){
    $SHEET->param($_."imageFit" => 'auto '.$pc{$_.'imagePercent'}.'%');
  }
  elsif($pc{$_.'imageFit'} =~ /^percentX?$/){
    $SHEET->param($_."imageFit" => $pc{$_.'imagePercent'}.'%');
  }
  ## 権利表記
  if($pc{$_.'imageCopyrightURL'}){
    $pc{$_.'imageCopyright'} = $pc{$_.'imageCopyrightURL'} if !$pc{$_.'imageCopyright'};
    $SHEET->param($_."imageCopyright" => "<a href=\"$pc{$_.'imageCopyrightURL'}\" target=\"_blank\">$pc{$_.'imageCopyright'}</a>");
  }
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{'url'} ? "?url=$::in{'url'}" : "?id=$::in{'id'}"));
if($pc{'image'}) { $SHEET->param(ogImg => url()."/".$imgsrc); }
$SHEET->param(ogDescript => tag_delete "種別:$pc{'type'}　ネガイ:$pc{'negaiOutside'}／$pc{'negaiInside'}　性別:$pc{'gender'}　年齢:$pc{'age'}　所属:$pc{'belong'}");

### バージョン等 --------------------------------------------------
$SHEET->param("ver" => $::ver);
$SHEET->param("coreDir" => $::core_dir);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $SHEET->output;

1;