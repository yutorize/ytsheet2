"use strict";

var output = output || {};
output.consts = output.consts || {};

output.consts.dicebot = 'Arianrhod';

output.consts.initiativeLabel = '行動値';

output.consts.SKILL_COLUMNS = {
  name: '《エフェクト名》',
  level: 'Lv',
  timing: 'タイミング',
  target: '対象',
  range: '射程',
  cost: 'コスト',
  reqd: '使用条件',
  note: '効果'
};

output.consts.CONNECTION_COLUMNS = {
  name: '名前',
  relation: '関係',
};

output.consts.GEIS_COLUMNS = {
  name: '名前',
  cost: '成長点',
  note: 'メモ'
};

output.consts.ARMAMENT_COLUMNS = {
  type: '',
  name: '名前',
  weight: '重量',
  acc: '命中',
  atk: '攻撃',
  eva: '回避',
  def: '物防',
  mdef: '魔防',
  ini: '行動',
  move: '移動',
  range: '射程',
  note: '備考'
};

output.consts.AR2_STATUS = [
  {
    name: '筋力',
    column: 'Str',
  },
  {
    name: '器用',
    column: 'Dex',
  },
  {
    name: '敏捷',
    column: 'Agi',
  },
  {
    name: '知力',
    column: 'Int',
  },
  {
    name: '感知',
    column: 'Sen',
  },
  {
    name: '精神',
    column: 'Mnd',
  },
  {
    name: '幸運',
    column: 'Luk',
  },
];
