################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;

sub data_calc {
  my %pc = %{$_[0]};
  my %st;
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = data_update_chara(\%pc);
  }

  ### カウント・レベル・爵位 --------------------------------------------------
  $pc{countsTotal} = $set::peerageRank{$pc{makePeerage}}{counts};
  foreach my $num (0 .. $pc{historyNum}){ $pc{countsTotal} += s_eval($pc{"history${num}Counts"}); }
  foreach my $num (1 .. $pc{academySupportNum}){ $pc{countsUsed} += $pc{"academySupport${num}Cost"}; }
  foreach my $num (1 .. $pc{artifactNum}){ $pc{countsUsed} += $pc{"artifact${num}Cost"} * $pc{"artifact${num}Quantity"}; }
  $pc{countsRest} = $pc{countsTotal} - $pc{countsUsed};

  $pc{level} = int($pc{countsTotal} / 1000);
  foreach my $key (
    sort { $set::peerageRank{$a}{lv} <=> $set::peerageRank{$b}{lv} } keys %set::peerageRank
  ){
    if($pc{countsTotal} >= $set::peerageRank{$key}{counts}){
      $pc{peerage} = $key;
    }
  }
  ### 資源 --------------------------------------------------
  foreach my $type ('Food','Tech','Horse','Mineral','Forest','Funds'){
    $pc{"resource${type}Total"} = 1;
    foreach my $i (1 .. $pc{characteristicNum}){
      $pc{"resource${type}Total"} += $pc{"characteristic${i}${type}"};
    }
      $pc{"resource${type}Total"} += $pc{"grow${type}"};
    
    $pc{"resource${type}Used"} = 0;
    foreach my $i (1 .. $pc{forceNum}){
      $pc{"resource${type}Used"} += $pc{"force${i}Cost${type}"};
    }
  }

  ### 0を消去 --------------------------------------------------

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
  my $countryName = ($pc{aka} ? "“$pc{aka}”" : "").$pc{countryName};
  $countryName =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  my $lordName = ($pc{aka} ? "“$pc{aka}”" : "").$pc{lordName};
  $lordName =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$countryName<>$pc{playerName}<>$pc{group}<>".
               "$pc{image}<> $pc{tags} <>$pc{hide}<>".

               "$lordName<>".
               "$pc{level}<>$pc{countsTotal}<>$pc{peerage}<>".
               "$pc{lastSession}<>";

  return %pc;
}

1;