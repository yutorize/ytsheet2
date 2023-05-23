################## データ保存 ##################
use strict;
#use warnings;
use utf8;

sub data_calc {
  my %pc = %{$_[0]};
  ### アップデート --------------------------------------------------
  if($pc{'ver'}){
    %pc = data_update_chara(\%pc);
  }

  ### レベル・成長 --------------------------------------------------
  ## 履歴から 
  $pc{'enduranceGrow'} = $pc{'endurancePreGrow'} || 0;
  $pc{'operationGrow'} = $pc{'operationPreGrow'} || 0;
  
  foreach my $i (0 .. $pc{'historyNum'}){
    if   ($pc{"history${i}Grow"} eq 'endurance') { $pc{'enduranceGrow'} += 2; }
    elsif($pc{"history${i}Grow"} eq 'operation') { $pc{'operationGrow'} += 1; }
  }
  $pc{'growCount'} = ($pc{"enduranceGrow"} / 2) + $pc{"operationGrow"};

  ### 能力値 --------------------------------------------------
  $pc{'endurance'} = $pc{'enduranceType'} + $pc{'enduranceOutside'} + $pc{'enduranceInside'} + $pc{'enduranceAdd'} + $pc{'enduranceGrow'};
  $pc{'operation'} = $pc{'operationType'} + $pc{'operationOutside'} + $pc{'operationInside'} + $pc{'operationAdd'} + $pc{'operationGrow'};

  ### キズナ --------------------------------------------------
  my $kizuna_count = 0;
  my $hibiware_count = 0;
  foreach (1 .. $pc{'kizunaNum'}){
    next if(!$pc{'kizuna'.$_.'Name'} && !$pc{'kizuna'.$_.'Note'} && !$pc{'kizuna'.$_.'Hibi'} && !$pc{'kizuna'.$_.'Ware'});
    $kizuna_count++;
    if($pc{'kizuna'.$_.'Ware'}){ $hibiware_count++; }
  }


  ### 0を消去 --------------------------------------------------
  #foreach (
  #  '',
  #){
  #  delete $pc{$_} if !$pc{$_};
  #}

  #### 改行を<br>に変換 --------------------------------------------------
  foreach (
    'words',
    'freeNote',
    'freeHistory',
    'chatPalette',
    'partner1Memory',
    'partner2Memory',
  ){
    $pc{$_} =~ s/\r\n?|\n/<br>/g;
  }
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{'tags'} = pcTagsEscape($pc{'tags'});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{'historyNum'}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{"lastSession"} = tagDelete tagUnescape $pc{"history${i}Title"}; last; }
  }

  ### newline --------------------------------------------------
  my $charactername = ($pc{'aka'} ? "“$pc{'aka'}”" : "").$pc{'characterName'};
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $::newline = "$pc{'id'}<>$::file<>".
               "$pc{'birthTime'}<>$::now<>$charactername<>$pc{'playerName'}<>$pc{'group'}<>".
               "$pc{'image'}<> $pc{'tags'} <>$pc{'hide'}<>".

               "$pc{'class'}<>$pc{'negaiOutside'}<>$pc{'negaiInside'}<>".
               "$pc{'gender'}<>$pc{'age'}<>".
               "$pc{'belong'}<>$pc{'partner2On'}<>".
               "$kizuna_count<>$hibiware_count<>$pc{'lastSession'}<>";

  return %pc;
}

1;