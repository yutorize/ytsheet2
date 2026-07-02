################## データ保存 ##################
use strict;
#use warnings;
use utf8;

sub dataCalc {
  my %pc = %{$_[0]};
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = upgradeCharaData(\%pc);
  }

  ### レベル・成長 --------------------------------------------------
  ## 履歴から 
  $pc{enduranceGrow}  = $pc{endurancePreGrow};
  $pc{initiativeGrow} = $pc{initiativePreGrow};
  
  foreach my $i (0 .. $pc{historyNum}){
    if   ($pc{"history${i}Grow"} eq 'endurance' ) { $pc{enduranceGrow}  += 5; }
    elsif($pc{"history${i}Grow"} eq 'initiative') { $pc{initiativeGrow} += 2; }
    $pc{level} = 1 + ($pc{enduranceGrow} / 5) + ($pc{initiativeGrow} / 2);
  }

  ### 能力値 --------------------------------------------------
  if($pc{convertSource} ne 'キャラクターシート倉庫'){
    $pc{statusMain1} = $pc{statusMain1Core} + $pc{statusMain1Style};
    $pc{statusMain2} = $pc{statusMain2Core} + $pc{statusMain2Style};
  }
  if   ($pc{factor} eq '人間'){
    $pc{endurance}  = $pc{statusMain1} * 2 + $pc{statusMain2};
    $pc{initiative} = $pc{statusMain2} + 10;
  }
  elsif($pc{factor} eq '吸血鬼'){
    $pc{endurance}  = $pc{statusMain1} + 20;
    $pc{initiative} = $pc{statusMain2} + 4;
  }
  $pc{endurance}  += $pc{enduranceAdd}  + $pc{enduranceGrow};
  $pc{initiative} += $pc{initiativeAdd} + $pc{initiativeGrow};

  ### 0を消去 --------------------------------------------------
  #foreach (
  #  '',
  #){
  #  delete $pc{$_} if !$pc{$_};
  #}

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{'words'.$_} =~ s/\r\n?|\n/<br>/g foreach('', 2 .. ($set::image_maxcount || 1));
  $pc{freeNote}    =~ s/\r\n?|\n/<br>/g;
  $pc{freeHistory} =~ s/\r\n?|\n/<br>/g;
  $pc{chatPalette} =~ s/\r\n?|\n/<br>/g;
  $pc{scarNote}    =~ s/\r\n?|\n/<br>/g;
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### updatedLine --------------------------------------------------
  my %NL;
  foreach ('characterName','playerName','factor','factorCore','factorStyle','gender','age','ageApp','belong','missing'){
    $NL{$_} = $pc{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/gr;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  $NL{characterName} = substr($NL{characterName}, 0, 108).'..' if length($NL{characterName}) > 108;
  $NL{playerName}    = substr($NL{playerName}   , 0,  25).'..' if length($NL{playerName}   ) >  25;
  $NL{factor}      = substr($NL{factor}     , 0,  10).'..' if length($NL{factor}     ) >  10;
  $NL{factorCore}  = substr($NL{factorCore} , 0,  10).'..' if length($NL{factorCore} ) >  10;
  $NL{factorStyle} = substr($NL{factorStyle}, 0,  10).'..' if length($NL{factorStyle}) >  10;
  $NL{gender}  = substr($NL{gender} , 0, 20).'..' if length($NL{gender} ) > 20;
  $NL{age}     = substr($NL{age}    , 0, 20).'..' if length($NL{age}    ) > 20;
  $NL{ageApp}  = substr($NL{ageApp} , 0, 20).'..' if length($NL{ageApp} ) > 20;
  $NL{belong}  = substr($pc{belong} , 0, 30).'..' if length($pc{belong} ) > 30;
  $NL{missing} = substr($pc{missing}, 0, 30).'..' if length($pc{missing}) > 30;
  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{characterName}<>$NL{playerName}<>$pc{group}<>"
    . "$NL{factor}<>$NL{factorCore}<>$NL{factorStyle}<>"
    . "$NL{gender}<>$NL{age}<>$NL{ageApp}<>"
    . "$NL{belong}<>$NL{missing}<>"
    . "$pc{level}<>"
    . "$pc{lastSession}<>"
    . $pc{"image".imageSuffix($pc{mainImage})}."<> $pc{tags} <>$pc{hide}<><>";

  return %pc;
}

1;