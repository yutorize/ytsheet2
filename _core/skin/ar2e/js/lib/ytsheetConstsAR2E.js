/* MIT License

Copyright 2020 @Shunshun94

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
var io = io || {};
io.github = io.github || {};
io.github.shunshun94 = io.github.shunshun94 || {};
io.github.shunshun94.trpg = io.github.shunshun94.trpg || {};
io.github.shunshun94.trpg.ytsheet = io.github.shunshun94.trpg.ytsheet || {};
io.github.shunshun94.trpg.ytsheet.consts = io.github.shunshun94.trpg.ytsheet.consts || {};

io.github.shunshun94.trpg.ytsheet.consts.SKILL_COLUMNS = {
  name: '《エフェクト名》',
  level: 'Lv',
  timing: 'タイミング',
  target: '対象',
  range: '射程',
  cost: 'コスト',
  condition: '使用条件',
  note: '効果'
};

io.github.shunshun94.trpg.ytsheet.consts.CONNECTION_COLUMNS = {
  name: '名前',
  relation: '関係',
};

io.github.shunshun94.trpg.ytsheet.consts.GEIS_COLUMNS = {
  name: '名前',
  cost: '成長点',
  note: 'メモ'
};

io.github.shunshun94.trpg.ytsheet.consts.ARMAMENT_COLUMNS = {
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

io.github.shunshun94.trpg.ytsheet.consts.AR2_STATUS = [
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