################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

#require $set::data_item;

sub data_calc {
  my %pc = %{$_[0]};
  
  my $name;
  my $sub;
  my $summary;
  if($pc{'category'} eq 'magic'){
    $name = $pc{'magicName'};
    $sub = $pc{'magicClass'}.'／'.$pc{'magicLevel'};
    if($pc{'magicMinor'}){ $sub .= '／小魔法'; }
    $summary = $pc{'magicSummary'};
  }
  if($pc{'category'} eq 'god'){
    $name = ($pc{'godAka'} ? "“$pc{'godAka'}”" : "").$pc{'godName'};
    $sub = ($pc{'godClass'}||'―').'／'.($pc{'godRank'}||'―');
    $summary = substr($pc{'godDeity'}, 0, 35).'..';
    $summary =~ s/\r|\n//g;
  }
  $pc{'artsName'} = $name;
  #### カテゴリの全角半角変換 --------------------------------------------------
  $pc{'category'} =~ tr/ａ-ｚＡ-Ｚ/a-zA-Z/;

  #### 改行を<br>に変換 --------------------------------------------------
  foreach (
    'magicEffect',
    'magicDescription',
    'godSymbol',
    'godDeity',
    'godNote',
    'godMagic2Effect',
    'godMagic4Effect',
    'godMagic7Effect',
    'godMagic10Effect',
    'godMagic13Effect',
  ){
    $pc{$_} =~ s/\r\n?|\n/<br>/g;
  }
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{'tags'} = pcTagsEscape($pc{'tags'});

  ### newline --------------------------------------------------
  $name =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $::newline = "$pc{'id'}<>$::file<>".
                "$pc{'birthTime'}<>$::now<>$name<>$pc{'author'}<>".
                "$pc{'category'}<>$sub<>$summary<>".
                "$pc{'image'}<> $pc{'tags'} <>$pc{'hide'}<>";
  
  return %pc;
}

1;