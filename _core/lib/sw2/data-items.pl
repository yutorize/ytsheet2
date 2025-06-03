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
);

our @weapon_names;
our %weapon_id;
foreach (@weapons){
  push (@weapon_names, @$_[0]);
  $weapon_id{@$_[0]} = @$_[1];
}

our @drugs = (
    {
        name     => '救命草',
        category => '薬草',
        rate     => 10,
    },
    {
        name     => '救難草',
        category => '薬草',
        rate     => 50,
    },
    {
        name     => '魔香草',
        category => '薬草',
        rate     => 0,
    },
    {
        name     => '魔海草',
        category => '薬草',
        rate     => 10,
    },
    {
        name     => 'ヒーリングポーション',
        category => 'ポーション',
        rate     => 20,
    },
    {
        name     => 'ヒーリングポーション+1',
        category => 'ポーション',
        rate     => 20,
        add      => 1,
    },
    {
        name     => 'トリートポーション',
        category => 'ポーション',
        rate     => 30,
    },
    {
        name     => 'テインテッドポーション',
        category => 'ポーション',
        rate     => 20,
        add      => '{穢れ}',
    },
    {
        name     => '魔香水',
        category => 'ポーション',
    },
);

1;