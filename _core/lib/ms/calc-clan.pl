################## データ保存 ##################
use strict;
#use warnings;
use utf8;

sub data_calc {
  my %pc = %{$_[0]};
  ### アップデート --------------------------------------------------
  #if($pc{ver}){
  #  %pc = data_update_clan(\%pc);
  #}

  ### レベル・成長 --------------------------------------------------
  ## 履歴から 
  $pc{level} = 0;
  
  foreach my $i (0 .. $pc{historyNum}){
    $pc{level} += s_eval($pc{"history${i}Level"});;
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
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### newline --------------------------------------------------
  my %NL;
  foreach ('clanName','leaderName','base','belong'){
    $NL{$_} = $pc{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/gr;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  $NL{clanName}   = substr($NL{clanName}  , 0, 108).'..' if length($NL{clanName}  ) > 108;
  $NL{playerName} = substr($NL{playerName}, 0,  25).'..' if length($NL{playerName}) >  25;
  $NL{base}   = substr($pc{base}  , 0, 30).'..' if length($pc{base}  ) > 30;
  $NL{belong} = substr($pc{belong}, 0, 30).'..' if length($pc{belong}) > 30;
  $NL{rule}   = substr($pc{rule}  , 0, 50).'..' if length($pc{rule}  ) > 50;
  $NL{leaderName} = substr($NL{leaderName}, 0, 108).'..' if length($NL{leaderName}) > 108;
  $::newline =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{clanName}<>$pc{playerName}<>$pc{group}<>"
    . $pc{"image".imageSuffix($pc{mainImage})}."<> $pc{tags} <>$pc{hide}<>$pc{lastSession}<>"

    . "$pc{level}<>"
    . "$NL{base}<>$NL{belong}<>"
    . "$NL{rule}<>"
    . "$NL{leaderName}<>";

  return %pc;
}

1;