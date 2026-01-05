################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_races;
require $set::data_class;

sub data_calc {
  my %pc = %{$_[0]};
  my %st;
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = data_update_chara(\%pc);
  }

  ### 戦果点 --------------------------------------------------
  foreach my $num (0 .. $pc{historyNum}){ $pc{resultPoint} += s_eval($pc{"history${num}Result"}); }
  $pc{historyResultTotal} = $pc{resultPoint};
  foreach my $num (0 .. $pc{goodsNum  }){ $pc{resultPoint} -= $pc{"goods${num}Cost"}; }
  foreach my $num (0 .. $pc{itemsNum  }){ $pc{resultPoint} -= $pc{"item${num}Cost"}; }

  ### 能力値 --------------------------------------------------
  $pc{staminaMax} = 5 + $pc{vitality} + $pc{staminaAdd};
  $pc{staminaHalf} = int($pc{staminaMax} / 2);

  foreach my $stt ('Acc','Spl','Eva','Atk','Det','Def','Mdf','Ini','Str'){
    $pc{'battleSubtotal'.$stt} = $pc{'battleBase'.$stt} + $pc{'battleRace'.$stt};
    $pc{'battleTotal'.$stt} = $pc{'battleSubtotal'.$stt};
    foreach my $type ('Weapon','Head','Body','Acc1','Acc2','Other'){
      $pc{'battleTotal'.$stt} += $pc{'battle'.$type.$stt};
    }
    $pc{'battleTotal'.$stt} += $pc{level};
  }
  $pc{hpMax} = $pc{battleTotalStr} + $pc{hpAdd};

  ### 0を消去 --------------------------------------------------
  foreach my $stt ('Acc','Spl','Eva','Atk','Det','Def','Mdf','Ini','Str'){
    foreach my $type ('Race','Weapon','Head','Body','Acc1','Acc2','Other'){
      delete $pc{'battle'.$type.$stt} if !$pc{'battle'.$type.$stt};
    }
  }
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
  foreach ('characterName','playerName','gender','race','class','style1','style2','gender','age','height'){
    $NL{$_} = $pc{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/gr;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  $NL{characterName} = substr($NL{characterName}, 0, 108).'..' if length($NL{characterName}) > 108;
  $NL{playerName}    = substr($NL{playerName}   , 0,  25).'..' if length($NL{playerName}   ) >  25;
  $NL{race}   = substr($NL{race}  , 0, 20).'..' if length($NL{race}  ) > 20;
  $NL{class}  = substr($NL{class} , 0, 20).'..' if length($NL{class} ) > 20;
  $NL{style1} = substr($NL{style1}, 0, 20).'..' if length($NL{style1}) > 20;
  $NL{style2} = substr($NL{style2}, 0, 20).'..' if length($NL{style2}) > 20;
  $NL{gender} = substr($NL{gender}, 0, 20).'..' if length($NL{gender}) > 20;
  $NL{age}    = substr($NL{age}   , 0, 20).'..' if length($NL{age}   ) > 20;
  $NL{height} = substr($NL{height}, 0, 20).'..' if length($NL{height}) > 20;
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$NL{characterName}<>$NL{playerName}<>$pc{group}<>".
               "$pc{image}<> $pc{tags} <>$pc{hide}<>".

               "$NL{race}<>$NL{class}<>$NL{style1}／$NL{style2}<>".
               "$pc{level}<>$pc{resultPointsTotal}<>".
               "$NL{gender}<>$NL{age}<>$NL{height}<>$pc{lastSession}<>";

  return %pc;
}

1;