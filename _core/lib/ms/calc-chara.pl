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
  $pc{level} = 0;
  
  foreach my $i (0 .. $pc{historyNum}){
    $pc{level} += s_eval($pc{"history${i}Level"});;
  }

  ### 能力値 --------------------------------------------------
  $pc{statusPhysical} = $pc{statusPhysicalBase} + $pc{statusPhysicalGrow};
  $pc{statusSpecial } = $pc{statusSpecialBase } + $pc{statusSpecialGrow };
  $pc{statusSocial  } = $pc{statusSocialBase  } + $pc{statusSocialGrow  };

  ### 耐久値 --------------------------------------------------
  $pc{endurance} = 20 + $pc{enduranceMod};


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
  foreach ('characterName','playerName','taxa','home','origin','background','clan','clanEmotion','address'){
    $NL{$_} = $pc{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/gr;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  $NL{characterName} = substr($NL{characterName}, 0, 108).'..' if length($NL{characterName}) > 108;
  $NL{playerName}    = substr($NL{playerName}   , 0,  25).'..' if length($NL{playerName}   ) >  25;
  $NL{taxa}        = substr($NL{taxa}       , 0, 20).'..' if length($NL{taxa}       ) >  20;
  $NL{home}        = substr($NL{home}       , 0, 30).'..' if length($NL{home}       ) >  30;
  $NL{origin}      = substr($NL{origin}     , 0, 20).'..' if length($NL{origin}     ) >  20;
  $NL{background}  = substr($NL{background} , 0, 30).'..' if length($NL{background} ) >  30;
  $NL{clan}        = substr($NL{clan}       , 0,108).'..' if length($NL{clan}       ) > 108;
  $NL{clanEmotion} = substr($NL{clanEmotion}, 0, 30).'..' if length($NL{clanEmotion}) >  30;
  $NL{address}     = substr($NL{address}    , 0, 30).'..' if length($NL{address}    ) >  30;
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$NL{characterName}<>$NL{playerName}<>$pc{group}<>".
               "$pc{image}<> $pc{tags} <>$pc{hide}<>$pc{lastSession}<>".

               "$pc{level}<>$pc{endurance}<>".
               "$NL{taxa}<>$NL{home}<>".
               "$NL{origin}<>$NL{background}<>".
               "$NL{clan}<>$NL{clanEmotion}<>$NL{address}<>";

  return %pc;
}

1;