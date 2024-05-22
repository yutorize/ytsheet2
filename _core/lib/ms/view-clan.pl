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
  path => ['./', $::core_dir."/skin/ms", $::core_dir."/skin/_common", $::core_dir],
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
    $pc{clanName} = noiseText(6,14);
    $pc{group} = $pc{clan} = $pc{tags} = '';
  
    $pc{rule}  = noiseText(6,12);
    $pc{base}  = noiseText(2,6);
    $pc{belong} = noiseText(2,6);
    $pc{leaderName} = noiseText(2,10);
    $pc{leaderURL} = '';

    foreach(1..$pc{memberNum}){
      $pc{'member'.$_.'Name'} = noiseText(2,10);
      $pc{'member'.$_.'URL'} = '';
    }
    
    $pc{freeNote} = '';
    foreach(1..int(rand 3)+2){
      $pc{freeNote} .= '　'.noiseText(18,40)."\n";
    }
    $pc{freeHistory} = '';
  }

  $pc{level}  = noiseText(1,2);

  foreach(1..4){
    $pc{'magi'.$_.'Name'}   = noiseText(5,10);
    $pc{'magi'.$_.'Timing'} = noiseText(3,4);
    $pc{'magi'.$_.'Target'} = noiseText(2,5);
    $pc{'magi'.$_.'Cond'}   = noiseText(3,4);
    $pc{'magi'.$_.'Note'}   = noiseText(10,15);
  }
  $pc{historyNum} = 0;
  $pc{history0Exp} = noiseText(1,3);
  
  $pc{playerName} = $author;
  $pc{protect} = $protect;
  $pc{forbidden} = $forbidden;
  $pc{forbiddenMode} = 1;
}

### その他 --------------------------------------------------
$SHEET->param(rawName => $pc{clanName} || '');

### タグ置換 #########################################################################################
if($pc{ver}){
  foreach (keys %pc) {
    next if($_ =~ /^(?:(leader|member[0-9]+)URL$|(?:image))/);
    if($_ =~ /^(?:freeNote|freeHistory)$/){
      $pc{$_} = unescapeTagsLines($pc{$_});
    }
    $pc{$_} = unescapeTags($pc{$_});

    $pc{$_} = noiseTextTag $pc{$_} if $pc{forbiddenMode};
  }
}

### アップデート --------------------------------------------------
if($pc{ver}){
  %pc = data_update_clan(\%pc);
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
### キャラクター名 --------------------------------------------------
$SHEET->param(clanName => "<ruby>$pc{clanName}<rp>(</rp><rt>$pc{'clanNameRuby'}</rt><rp>)</rp></ruby>") if $pc{'clanNameRuby'};
### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $::in{id}))[0];
  $SHEET->param(playerName => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{playerName}.'</a>');
}
### グループ --------------------------------------------------
if($::in{url} || !@set::groups_clan){
  $SHEET->param(group => '');
}
else {
  if(!$pc{group}) {
    $pc{group} = $set::group_default;
    $SHEET->param(group => $set::group_default);
  }
  foreach (@set::groups_clan){
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
    "URL"  => uri_escape_utf8($_),
    "TEXT" => $_,
  });
}
$SHEET->param(Tags => \@tags);

### リーダー --------------------------------------------------
$SHEET->param(leader => $pc{leaderURL} ? "<a href=\"$pc{leaderURL}\">$pc{leaderName}</a>" : $pc{leaderName});
### メンバー --------------------------------------------------
my @member;
foreach (1 .. $pc{memberNum}){
  next if !$pc{'member'.$_.'Name'};
  push(@member, {
    NAME => $pc{'member'.$_.'URL'} ? "<a href=\"$pc{'member'.$_.'URL'}\">$pc{'member'.$_.'Name'}</a>" : $pc{'member'.$_.'Name'},
  });
}
$SHEET->param(Members => \@member);

### 特性 --------------------------------------------------
my @attribute;
foreach (1 .. 6){
  next if !$pc{'attribute'.$_};
  $pc{'attribute'.$_} &&= "《$pc{'attribute'.$_}》";
  push(@attribute, { NAME => $pc{'attribute'.$_} });
}
$SHEET->param('Attribute' => \@attribute);

### マギ --------------------------------------------------
my @magi;
foreach (1 .. 5){
  next if(
       !$pc{'magi'.$_.'Name'}
    && !$pc{'magi'.$_.'Timing'}
    && !$pc{'magi'.$_.'Target'}
    && !$pc{'magi'.$_.'Cond'}
    && !$pc{'magi'.$_.'Note'}
  );
  $pc{'magi'.$_.'Name'} &&= "《$pc{'magi'.$_.'Name'}》";
  push(@magi, {
    NAME   => $pc{'magi'.$_.'Name'},
    TIMING => $pc{'magi'.$_.'Timing'},
    TARGET => $pc{'magi'.$_.'Target'},
    COND   => $pc{'magi'.$_.'Cond'},
    NOTE   => $pc{'magi'.$_.'Note'},
  });
}
$SHEET->param(Magi => \@magi);

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
#$pc{history0Title} = 'キャラクター作成';
foreach (1 .. $pc{historyNum}){
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
    "LEVEL"  => $pc{'history'.$_.'Level'},
    "GM"     => $pc{'history'.$_.'Gm'},
    "MEMBER" => $members,
    "NOTE"   => $pc{'history'.$_.'Note'},
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
  $SHEET->param(titleName => removeTags nameToPlain($pc{clanName}||"“$pc{aka}”"));
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
if($pc{image}) { $SHEET->param(ogImg => $pc{imageURL}); }
$SHEET->param(ogDescript => removeTags "強度:$pc{level}ルール:$pc{rule}　拠点:$pc{base}　所属:$pc{belong}　リーダー:$pc{leaderName}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'ms');
$SHEET->param(sheetType => 'clan');
$SHEET->param(generateType => 'MamonoScrambleClan');
$SHEET->param(defaultImage => $::core_dir.'/skin/ms/img/default_pc.png');

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