################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

#require $set::data_item;

sub data_calc {
  my %pc = %{$_[0]};

  #### カテゴリの全角半角変換 --------------------------------------------------
  $pc{category} =~ tr/ａ-ｚＡ-Ｚ/a-zA-Z/;

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{effects}     =~ s/\r\n?|\n/<br>/g;
  $pc{description} =~ s/\r\n?|\n/<br>/g;
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### newline --------------------------------------------------
  my $name = $pc{itemName};
  my $type = $pc{magic} ? '[ma]' : '';
  $name =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $::newline = "$pc{id}<>$::file<>".
                "$pc{birthTime}<>$::now<>$name<>$pc{author}<>".
                "$pc{category}<>$pc{price}<>$pc{age}<>$pc{summary}<>$type<>".
                "$pc{image}<> $pc{tags} <>$pc{hide}<>";
  
  return %pc;
}

1;