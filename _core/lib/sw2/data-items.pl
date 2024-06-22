#################### アイテム ####################
use strict;
use utf8;

package data;

our @weapons = (
  ['ソード',        'sword'],
  ['アックス',      'axe'],
  ['スピア',        'spear'],
  ['メイス',        'mace'],
  ['スタッフ',      'staff'],
  ['フレイル',      'flail'],
  ['ウォーハンマー','hammer'],
  ['絡み',          'entangle'],
  ['格闘',          'grapple'],
  ['投擲',          'throw'],
  ['ボウ',          'bow'],
  ['クロスボウ',    'crossbow'],
  ['ブロウガン',    'blowgun'],
  ['ガン',          'gun'],
  ['魔導書'         'book'],
);

our @weapon_names;
our %weapon_id;
foreach (@weapons){
  push (@weapon_names, @$_[0]);
  $weapon_id{@$_[0]} = @$_[1];
}

1;