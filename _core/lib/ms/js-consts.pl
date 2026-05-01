use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP;

### データ読み込み ###################################################################################
require $set::data_magi;

### 出力 #############################################################################################
my %settings = (
  gameSystem => $set::game,
  pcMagiNames => \@data::pcMagiNames,
  pcMagiData => \%data::pcMagiData,
  clanMagiNames => \@data::clanMagiNames,
  clanMagiData => \%data::clanMagiData,
);
print "const SET = ". JSON::PP->new->encode(\%settings);
print "\n";
print "console.log('=====SET=====')";


1;