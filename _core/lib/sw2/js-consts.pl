use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP;

### データ読み込み ###################################################################################
require $set::data_class;
require $set::data_races;
require $set::data_items;
require $set::data_faith;

### 出力 #############################################################################################
foreach (keys %data::class){
  $data::class{$_}{magic}{data} &&= 1 if exists($data::class{$_}{magic});
  $data::class{$_}{craft}{data} &&= 1 if exists($data::class{$_}{craft});
}
my %aRank; my %bRank; my %effects;
$aRank{@$_[0]} = { num => @$_[1], free => @$_[2] } foreach(@set::adventurer_rank);
$bRank{@$_[0]} = { num => @$_[1], free => @$_[2] } foreach(@set::barbaros_rank);
foreach (@set::effects){
  $effects{$_->{name}} = $_;
  delete $effects{$_->{name}}{name};
}
my %settings = (
  gameSystem => $set::game,
  allClassOn => $set::all_class_on,
  battleItemOn => $set::battleitem,
  growType => $set::growtype,
  featsLv => ['1bat',@set::feats_lv],
  races => \%data::races,
  class      => \%data::class,
  classNames => \@data::class_names,
  classCasters => \@data::class_caster,
  weapons => \@data::weapons,
  aRank => \%aRank,
  bRank => \%bRank,
  nRank => \@set::notoriety_rank,
  nBRank => \@set::notoriety_barbaros_rank,
  partsData => \%data::partsData,
  effects => \%effects,
);
print "const SET = ". JSON::PP->new->encode(\%settings);
print "\n";
print "console.log('=====SET=====')";


1;