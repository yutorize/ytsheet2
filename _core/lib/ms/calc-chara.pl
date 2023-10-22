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
  $pc{tags} = pcTagsEscape($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = tagDelete tagUnescape $pc{"history${i}Title"}; last; }
  }

  ### newline --------------------------------------------------
  my %NL;
  foreach ('characterName','taxa','home','origin','background','clan','clanEmotion','address'){
    $NL{$_} = $pc{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/gr;
    $NL{$_} = tagDelete tagUnescape $NL{$_};
  }
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$NL{characterName}<>$pc{playerName}<>$pc{group}<>".
               "$pc{image}<> $pc{tags} <>$pc{hide}<>$pc{lastSession}<>".

               "$pc{level}<>$pc{endurance}<>".
               "$NL{taxa}<>$NL{home}<>".
               "$NL{origin}<>$NL{background}<>".
               "$NL{clan}<>$NL{clanEmotion}<>$NL{address}<>";

  return %pc;
}

1;