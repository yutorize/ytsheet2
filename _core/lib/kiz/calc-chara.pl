################## データ保存 ##################
use strict;
#use warnings;
use utf8;

sub data_calc {
  my %pc = %{$_[0]};
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = data_update_chara(\%pc);
  }

  ### レベル・成長 --------------------------------------------------
  ## 履歴から 
  $pc{enduranceGrow} = $pc{endurancePreGrow} || 0;
  $pc{operationGrow} = $pc{operationPreGrow} || 0;
  
  foreach my $i (0 .. $pc{historyNum}){
    if   ($pc{"history${i}Grow"} eq 'endurance') { $pc{enduranceGrow} += 2; }
    elsif($pc{"history${i}Grow"} eq 'operation') { $pc{operationGrow} += 1; }
  }
  $pc{growCount} = ($pc{enduranceGrow} / 2) + $pc{operationGrow};

  ### 能力値 --------------------------------------------------
  $pc{endurance} = $pc{enduranceType} + $pc{enduranceOutside} + $pc{enduranceInside} + $pc{enduranceAdd} + $pc{enduranceGrow};
  $pc{operation} = $pc{operationType} + $pc{operationOutside} + $pc{operationInside} + $pc{operationAdd} + $pc{operationGrow};

  ### キズナ --------------------------------------------------
  my $kizuna_count = 0;
  my $hibiware_count = 0;
  foreach (1 .. $pc{kizunaNum}){
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
  $pc{tags} = normalizeHashtags($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### newline --------------------------------------------------
  my %NL;
  foreach ('characterName','playerName','class','negaiOutside','negaiInside','gender','age','belong'){
    $NL{$_} = $pc{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/gr;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  $NL{characterName} = substr($NL{characterName}, 0, 108).'..' if length($NL{characterName}) > 108;
  $NL{playerName}    = substr($NL{playerName}   , 0,  25).'..' if length($NL{playerName}   ) >  25;
  $NL{class}        = substr($NL{class}       , 0,  10).'..' if length($NL{class}       ) >  10;
  $NL{negaiOutside} = substr($NL{negaiOutside}, 0,  10).'..' if length($NL{negaiOutside}) >  10;
  $NL{negaiInside}  = substr($NL{negaiInside} , 0,  10).'..' if length($NL{negaiInside} ) >  10;
  $NL{gender} = substr($NL{gender}, 0, 20).'..' if length($NL{gender}) > 20;
  $NL{age}    = substr($NL{age}   , 0, 20).'..' if length($NL{age}   ) > 20;
  $NL{belong} = substr($pc{belong}, 0, 30).'..' if length($pc{belong}) > 30;
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$NL{characterName}<>$NL{playerName}<>$pc{group}<>".
               "$pc{image}<> $pc{tags} <>$pc{hide}<>".

               "$NL{class}<>$NL{negaiOutside}<>$NL{negaiInside}<>".
               "$NL{gender}<>$NL{age}<>".
               "$NL{belong}<>$pc{partner2On}<>".
               "$kizuna_count<>$hibiware_count<>$pc{lastSession}<>";

  return %pc;
}

1;