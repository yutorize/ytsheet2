/* MIT License

Copyright 2020 @Shunshun94

Customize & Refactoring by @yutorize

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
"use strict";

var output = output || {};
output.consts = output.consts || {};

output.consts.dicebot = 'DoubleCross';

output.consts.EFFECT_COLUMNS = {
	name: '《エフェクト名》',
	level: 'Lv',
	timing: 'タイミング',
	difficulty: '難易度',
	target: '対象',
	range: '射程',
	cost: '侵蝕値',
	limitation: '制限',
	note: '効果'
};

output.consts.COMBO_COLUMNS = {
	name: 'コンボ名',
	combination: '組み合わせ',
	skill: '技能',
	hit: '命中',
	attack: '攻撃力',
	target: '対象',
	range: '射程',
	cost: '侵蝕値',
	limitation: '条件',
	note: '効果'
};

output.consts.LOISES_COLUMNS = {
	name: '名前',
	relation: '関係',
	positive: 'ポジティブ',
	negative: 'ネガティブ',
	color: '属性',
	condition: '状態',
	note: 'メモ'
};

output.consts.WEAPON_COLUMNS = {
	name: '名前',
	cost: '常備化',
	experience: '経験点',
	type: '種別',
	skill: '技能',
	hit: '命中',
	attack: '攻撃力',
	guard: 'ガード値',
	range: '射程',
	note: '解説'
};

output.consts.ARMOR_COLUMNS = {
	name: '名前',
	cost: '常備化',
	experience: '経験点',
	type: '種別',
	value: '装甲値',
	move: '行動値',
	dodge: 'ドッジ',
	note: '解説'
};

output.consts.ITEM_COLUMNS = {
	name: '名前',
	cost: '常備化',
	experience: '経験点',
	type: '種別',
	skill: '技能',
	note: '解説'
};

output.consts.MEMORIES_COLUMNS = {
	name: '名前',
	relation: '関係',
	emotion: '感情',
	note: 'メモ'
};

output.consts.DX3_STATUS = [
	{
		name: '肉体',
		column: 'Body',
		skills: [
			{
				name: '白兵',
				column: 'Melee'
			}, {
				name: '回避',
				column: 'Dodge'
			}
		],
		extendableSkill: {
			name: '運転',
			column: 'Ride'
		}
	}, {
		name: '感覚',
		column: 'Sense',
		skills: [
			{
				name: '射撃',
				column: 'Ranged'
			}, {
				name: '知覚',
				column: 'Percept'
			}
		],
		extendableSkill: {
			name: '芸術',
			column: 'Art'
		}
	}, {
		name: '精神',
		column: 'Mind',
		skills: [
			{
				name: 'RC',
				column: 'RC'
			}, {
				name: '意志',
				column: 'Will'
			}
		],
		extendableSkill: {
			name: '知識',
			column: 'Know'
		}
	}, {
		name: '社会',
		column: 'Social',
		skills: [
			{
				name: '交渉',
				column: 'Negotiate'
			}, {
				name: '調達',
				column: 'Procure'
			}
		],
		extendableSkill: {
			name: '情報',
			column: 'Info'
		}
	}
];