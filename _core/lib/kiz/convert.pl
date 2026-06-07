################## データ保存 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP;

sub loadPartnerData {
  return importSheetData(
    shift,
    softError => 1,
    includeImage => 1,
    imageUrlBase => './',
    skipPermission => 1,
  );
}

## タグ：全角スペース・英数を半角に変換 --------------------------------------------------
sub convertTags {
  my $tags = shift;
  $tags =~ tr/　/ /;
  $tags =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
  $tags =~ tr/＋－＊／．，＿/\+\-\*\/\.,_/;
  $tags =~ tr/ / /s;
  return $tags
}

1;
