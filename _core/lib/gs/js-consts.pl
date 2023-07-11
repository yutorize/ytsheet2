use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP;

### データ読み込み ###################################################################################
require $set::data_class;
require $set::data_races;

### 出力 #############################################################################################
my %settings = (
  gameSystem => $set::game,
  races => \%data::races,
  class      => \%data::class,
  classNames => \@data::class_names,
  weaponType => \%set::weapon_type,
);
print "const SET = ". JSON::PP->new->encode(\%settings);
print "\n";
print "console.log('=====SET=====')";


1;