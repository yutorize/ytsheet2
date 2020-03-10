################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_mons;

sub data_calc {
  my %pc = %{$_[0]};

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{'skills'}      =~ s/\r\n?|\n/<br>/g;
  $pc{'description'} =~ s/\r\n?|\n/<br>/g;
  $pc{'chatPalette'} =~ s/\r\n?|\n/<br>/g;

  ### newline --------------------------------------------------
  my $name = $pc{'characterName'} ? $pc{'characterName'} : $pc{'monsterName'};
  $name =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $pc{'hide'} = 'IN' if(!$pc{'hide'} && $pc{'description'} =~ /#login-only/i);
  $::newline = "$pc{'id'}<>$::file<>".
                "$pc{'birthTime'}<>$::now<>$name<>$pc{'author'}<>$pc{'taxa'}<>$pc{'lv'}<>".
                "$pc{'intellect'}<>$pc{'perception'}<>$pc{'disposition'}<>$pc{'sin'}<>$pc{'initiative'}<>$pc{'weakness'}<>".
                "$pc{'image'}<> $pc{'tags'} <>$pc{'hide'}<>";
  
  return %pc;
}

1;