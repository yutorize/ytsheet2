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
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### newline --------------------------------------------------
  my %NL;
  $NL{type} = $pc{magic} ? '[ma]' : '';
  foreach ('itemName','author','category','price','age','summary'){
    $NL{$_} = $pc{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/gr;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  $NL{name}    = substr($NL{name}   , 0, 108).'..' if length($NL{name}   ) > 108;
  $NL{author}  = substr($NL{author} , 0,  25).'..' if length($NL{author} ) >  25;
  $NL{sub}     = substr($NL{sub}    , 0,  40).'..' if length($NL{sub}    ) >  40;
  $NL{summary} = substr($NL{summary}, 0,  35).'..' if length($NL{summary}) >  35;
  $::newline =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{itemName}<>$NL{author}<>"
    . "$NL{category}<>$NL{price}<>$NL{age}<>$NL{summary}<>$NL{type}<>"
    . $pc{"image".imageSuffix($pc{mainImage})}."<> $pc{tags} <>$pc{hide}<>";
  
  return %pc;
}

1;