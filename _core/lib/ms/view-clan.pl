################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_magi;

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  unescapeLinesKeys => [qw/freeNote freeHistory/],
  unescapeSkipRe    => qr/^(?:member[0-9]+URL$|(?:image))/,
  nameKeys          => [qw/clanName/],
  updateSub => \&upgradeCharaData,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{aka} = '';
    $pc->{clanName} = noiseText(6,14);
    $pc->{group} = $pc->{clan} = $pc->{tags} = '';
  
    $pc->{rule}  = noiseText(6,12);
    $pc->{base}  = noiseText(2,6);
    $pc->{belong} = noiseText(2,6);
    $pc->{leaderName} = noiseText(2,10);
    $pc->{leaderURL} = '';

    foreach(1..$pc->{memberNum}){
      $pc->{'member'.$_.'Name'} = noiseText(2,10);
      $pc->{'member'.$_.'URL'} = '';
    }
    
    $pc->{freeNote} = '';
    foreach(1..int(rand 3)+2){
      $pc->{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }

  $pc->{level}  = noiseText(1,2);

  foreach(1..4){
    $pc->{'magi'.$_.'Name'}   = noiseText(5,10);
    $pc->{'magi'.$_.'Timing'} = noiseText(3,4);
    $pc->{'magi'.$_.'Target'} = noiseText(2,5);
    $pc->{'magi'.$_.'Cond'}   = noiseText(3,4);
    $pc->{'magi'.$_.'Note'}   = noiseText(10,15);
  }
  $pc->{historyNum} = 0;
  $pc->{history0Exp} = noiseText(1,3);
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
  next if !existsRow "magi$_",'','Timing','Target','Cond','Note';
  my $magi = $pc{"magi$_"};
  my ($name, $baseName) = ($magi,'');
  if($pc{"magi${_}NC"}){
    $name = $pc{"magi${_}Name"};
    $baseName = "<b class=\"base-name\">《${magi}》</b> " if $magi ne 'その他';
  }
  push(@magi, {
    NAME   => ($name ? "《${name}》" : ''),
    TIMING => ($data::clanMagiData{$magi}{timing} // $pc{"magi${_}Timing"}),
    TARGET => ($data::clanMagiData{$magi}{target} // $pc{"magi${_}Target"}),
    COND   => ($data::clanMagiData{$magi}{cond  } // $pc{"magi${_}Cond"}),
    NOTE   => $baseName.($data::clanMagiData{$magi}{note} // $pc{"magi${_}Note"}),
  });
}
$SHEET->param(Magi => \@magi);

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
#$pc{history0Title} = 'キャラクター作成';
foreach (1 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Level','Gm','Member','Note');
  $h_num++ if $pc{'history'.$_.'Gm'};
  if ($set::log_dir && $pc{'history'.$_.'Date'} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
    my $room = $1;
    (my $date = $pc{'history'.$_.'Date'}) =~ y#\-\/##d;
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

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "強度:$pc{level}ルール:$pc{rule}　拠点:$pc{base}　所属:$pc{belong}　リーダー:$pc{leaderName}");

### メニュー --------------------------------------------------
setSheetMenu();

### 出力 #############################################################################################
printFinalizedView();

1;
