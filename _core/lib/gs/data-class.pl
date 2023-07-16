#################### データ ####################
use strict;
use utf8;

package data;

### 技能名一覧 --------------------------------------------------
# 基本的な並び
our @class_names = (
  '戦士',
  '武道家',
  '野伏',
  '斥候',
  '魔術師',
  '神官',
  '竜司祭',
  '精霊使い',
  '死人占い師',
);

### 技能初出順一覧 --------------------------------------------------
# （並べ替えるとキャラ一覧での技能表示が入れ替わるので注意）
our @class_list = @class_names;

### 技能詳細データ --------------------------------------------------
our %class = (
  '戦士' => {
    type   => 'warrior,dodge,block',
    id     => 'Fig',
    eName  => 'fighter',
    kana   => 'ファイター',
    proper => {
      hitscore => 'Melee',
      weight   => '軽重',
      weapon   => '片手剣,両手剣,斧,槍,戦鎚',
      armor    => 'すべて',
      shield   => 'すべて',
    },
  },
  '武道家' => {
    type   => 'warrior,dodge',
    id     => 'Mon',
    eName  => 'monk',
    kana   => 'モンク',
    proper => {
      hitscore => 'Melee',
      weight   => '軽重',
      weapon   => '格闘武器,棍杖,投擲武器',
      armor    => '衣鎧',
      shield   => '',
    },
  },
  '野伏' => {
    type   => 'warrior',
    id     => 'Ran',
    eName  => 'ranger',
    kana   => 'レンジャー',
    proper => {
      hitscore => 'Throwing,Projectile',
      weight   => '軽重',
      weapon   => '弩弓,投擲武器',
      armor    => '衣鎧,軽鎧',
      shield   => '',
    },
  },
  '斥候' => {
    type   => 'warrior,dodge,block',
    id     => 'Sco',
    eName  => 'scout',
    kana   => 'スカウト',
    proper => {
      hitscore => 'Melee,Throwing',
      weight   => '軽',
      weapon   => '片手剣,両手剣,斧,槍,戦鎚,格闘武器,棍杖,投擲武器',
      armor    => 'すべて',
      shield   => 'すべて',
    },
  },
  '魔術師' => {
    type   => 'spell',
    id     => 'Sor',
    eName  => 'sorcerer',
    kana   => 'ソーサラー',
    proper => {
      weight   => '軽',
      armor    => 'すべて',
    },
    magic => '真言呪文',
    cast  => 'IntFoc',
  },
  '神官' => {
    type   => 'spell',
    id     => 'Pri',
    eName  => 'priest',
    kana   => 'プリースト',
    proper => {
      weight   => '軽重',
      armor    => 'すべて',
      armor    => 'すべて',
    },
    magic => '奇跡',
    cast  => 'PsyFoc',
  },
  '竜司祭' => {
    type   => 'spell',
    id     => 'Dra',
    eName  => 'dragonpriest',
    kana   => 'ドラゴンプリースト',
    proper => {
      weight   => '軽重',
      armor    => 'すべて',
      armor    => 'すべて',
    },
    magic => '祖竜術',
    cast  => 'PsyFoc',
  },
  '精霊使い' => {
    type   => 'spell',
    id     => 'Sha',
    eName  => 'shaman',
    kana   => 'シャーマン',
    proper => {
      weight   => '軽',
      armor    => 'すべて',
      armor    => 'すべて',
    },
    magic => '精霊術',
    cast  => 'PsyFoc',
  },
  '死人占い師' => {
    type   => 'spell',
    id     => 'Nec',
    eName  => 'necromancer',
    kana   => 'ネクロマンサー',
    proper => {
      weight   => '軽',
      armor    => 'すべて',
      armor    => 'すべて',
    },
    magic => '死霊術',
    cast  => 'IntFoc',
  },
);


1;