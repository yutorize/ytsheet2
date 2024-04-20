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

output._convertDoubleCrossStatus = (json, s) => {
	const result = [];
	result.push(`【${s.name}】：${json['sttTotal' + s.column]} (内成長：${json['sttGrow' + s.column] || 0})`);
	s.skills.forEach((skill)=>{
		result.push(`〈${skill.name}〉：${json['skillTotal' + skill.column] || 0} / 判定 ${json['sttTotal' + s.column]}r+${json['skillTotal' + skill.column] || 0}`);
	});
	let cursor = 1;
	if(json[`skill${s.extendableSkill.column}${cursor}`]) {
		while(json[`skill${s.extendableSkill.column}${cursor}Name`]) {
			result.push('〈' + json[`skill${s.extendableSkill.column}${cursor}Name`] +`〉：${json[`skillTotal${s.extendableSkill.column}${cursor}`] || 0} / 判定 ${json['sttTotal' + s.column]}r+${json[`skillTotal${s.extendableSkill.column}${cursor}`] || 0}`);
			cursor++;
		}
	} else {
		result.push(`〈${s.extendableSkill.name}〉：0 / 判定 ${json['sttTotal' + s.column]}r+0`);
	}

	result.push('');
	return result.join('\n');
};

output._getDoubleCrossEffects = (json) => {
	let cursor = 1;
	const effectData = [];
	while(json[`effect${cursor}Name`]) {
		effectData.push({
			name: '《' + json[`effect${cursor}Name`] + '》',
			level: json[`effect${cursor}Lv`] || '1',
			timing: json[`effect${cursor}Timing`] || '',
			difficulty: json[`effect${cursor}Dfclty`] || '',
			target: json[`effect${cursor}Target`] || '',
			range: json[`effect${cursor}Range`] || '',
			cost: json[`effect${cursor}Encroach`] || '',
			limitation: json[`effect${cursor}Restrict`] || '',
			note: json[`effect${cursor}Note`] || ''
		});
		cursor++;
	}
	return effectData;
};

output._getDoubleCrossCombos = (json) => {
	let cursor = 1;
	const comboData = [];
	while(json[`combo${cursor}Name`]) {
		let limitationCursor = 1;
		while(json[`combo${cursor}Condition${limitationCursor}`]) {
			comboData.push({
				name: json[`combo${cursor}Name`] || '',
				combination: (json[`combo${cursor}Combo`] || '').trim(),
				skill: (json[`combo${cursor}Skill`] || '').trim(),
				hit: (json[`combo${cursor}Dice${limitationCursor}`]) ? '(' + json[`combo${cursor}Dice${limitationCursor}`] + ')dx' + '+(' + (json[`combo${cursor}Fixed${limitationCursor}`] || '0') + ')' + '@' + (json[`combo${cursor}Crit${limitationCursor}`] || 10) : '',
				attack: json[`combo${cursor}Atk${limitationCursor}`] || '',
				target: (json[`combo${cursor}Target`] || '').trim(),
				range: (json[`combo${cursor}Range`] || '').trim(),
				cost: json[`combo${cursor}Encroach`] || '0',
				limitation: (json[`combo${cursor}Condition${limitationCursor}`] || '').trim(),
				note: json[`combo${cursor}Note`] || ''
			});			
			limitationCursor++;
		}
		cursor++;
	}
	return comboData;
};

output._getDoubleCrossLoises = (json) => {
	let cursor = 1;
	const data = [];
	while(json[`lois${cursor}Name`]) {
		data.push({
			name: json[`lois${cursor}Name`],
			relation: json[`lois${cursor}Relation`] || '',
			positive: json[`lois${cursor}EmoPosi`] || '', 
			negative: json[`lois${cursor}EmoNega`] || '',
			color: json[`lois${cursor}Color`] || '',
			condition: json[`lois${cursor}State`],
			note: json[`lois${cursor}Note`] || ''
		});
		cursor++;
	}
	return data;
};

output._getDoubleCrossMemories = (json) => {
	let cursor = 1;
	const data = [];
	while(json[`memory${cursor}Gain`]) {
		data.push({
			name: json[`memory${cursor}Name`] || '',
			relation: json[`memory${cursor}Relation`] || '',
			emotion: json[`memory${cursor}Emo`] || '',
			note: json[`memory${cursor}Note`] || ''
		});
		cursor++;
	}
	return data;
};

output._getDoubleCrossWeapons = (json) => {
	let cursor = 1;
	const data = [];
	while(json[`weapon${cursor}Name`]) {
		data.push({
			name: json[`weapon${cursor}Name`] || '',
			cost: json[`weapon${cursor}Stock`] || '',
			experience: json[`weapon${cursor}Exp`] || '',
			type: json[`weapon${cursor}Type`] || '',
			skill: json[`weapon${cursor}Skill`] || '',
			hit: json[`weapon${cursor}Acc`] || '',
			attack: json[`weapon${cursor}Atk`] || '',
			guard: json[`weapon${cursor}Guard`] || '',
			range: json[`weapon${cursor}Range`] || '',
			note: json[`weapon${cursor}Note`] || ''
		});
		cursor++;
	}
	return data;
};

output._getDoubleCrossArmors = (json) => {
	let cursor = 1;
	const data = [];
	while(json[`armor${cursor}Name`]) {
		data.push({
			name: json[`armor${cursor}Name`] || '',
			cost: json[`armor${cursor}Stock`] || '',
			experience: json[`armor${cursor}Exp`] || '',
			type: json[`armor${cursor}Type`] || '',
			value: json[`armor${cursor}Armor`] || '',
			move: json[`armor${cursor}Initiative`] || '',
			dodge: json[`armor${cursor}Dodge`] || '',
			note: json[`armor${cursor}Note`] || ''
		});
		cursor++;
	}
	return data;
};

output._getDoubleCrossItems = (json) => {
	let cursor = 1;
	const data = [];
	while(json[`item${cursor}Name`]) {
		data.push({
			name: json[`item${cursor}Name`] || '',
			cost: json[`item${cursor}Stock`] || '',
			experience: json[`item${cursor}Exp`] || '',
			type: json[`item${cursor}Type`] || '',
			skill: json[`item${cursor}Skill`] || '',
			note: json[`item${cursor}Note`] || ''
		});
		cursor++;
	}
	return data;
};

output.generateCharacterTextOfDoubleCross3PC = (json) => {
	const result = [];

	result.push(`キャラクター名：${json.characterName || ''}
コードネーム：${json.aka || ''}
年齢：${json.age || ''}
性別：${json.gender || ''}
身長：${json.height || ''}
体重：${json.weight || ''}`);
	result.push('');

	result.push(`ワークス　　：${json.works || ''}
カヴァー　　：${json.cover || ''}
シンドローム：${json.syndrome1 || ''}${json.syndrome2 ? '、'+json.syndrome2 : ''}${json.syndrome3 ? '、'+json.syndrome3 : ''}`);
	result.push('');

	result.push(`■ライフパス■
覚醒：${json.lifepathAwaken || ''}
衝動：${json.lifepathImpulse || ''}`);
	result.push('');

	result.push('■能力値と技能■\n');
	output.consts.DX3_STATUS.forEach((statusPattern)=>{
		result.push(output._convertDoubleCrossStatus(json, statusPattern));
	});
	result.push('');
	result.push(`【ＨＰ】　　　${String(json.maxHpTotal).padStart(3, ' ')}
【侵蝕基本値】${String(json.baseEncroach).padStart(3, ' ')}％
【行動値】　　${String(json.initiativeTotal).padStart(3, ' ')}
【戦闘移動】　${String(json.moveTotal).padStart(3, ' ')}ｍ`);
	result.push('');

	result.push('■エフェクト■\n');
	const effectData = output._getDoubleCrossEffects(json);
	result.push(output._convertList(effectData, output.consts.EFFECT_COLUMNS, ' / '));
	result.push('');
	result.push('');

	result.push('■コンボ■\n');
	const comboData = output._getDoubleCrossCombos(json);
	result.push(output._convertList(comboData, output.consts.COMBO_COLUMNS, ' / '));
	result.push('');
	result.push('');

	result.push('■アイテム■');
	result.push('');

	result.push('・武器');
	const weaponData = output._getDoubleCrossWeapons(json);
	result.push(output._convertList(weaponData, output.consts.WEAPON_COLUMNS, ' / '));
	result.push('');

	result.push('・防具');
	const armorData = output._getDoubleCrossArmors(json);
	result.push(output._convertList(armorData, output.consts.ARMOR_COLUMNS, ' / '));
	result.push('');

	result.push('・その他');
	const itemData = output._getDoubleCrossItems(json);
	result.push(output._convertList(itemData, output.consts.ITEM_COLUMNS, ' / '));
	result.push('');

	result.push(`【常備化ポイント】${(String(json.stockTotal || 2)).padStart(4, ' ')} pt`);
	result.push(`【財産ポイント】　${(String(json.savingTotal || 2)).padStart(4, ' ')} pt`);
	result.push('');
	result.push('');

	result.push('■ロイス■');
	const loisData = output._getDoubleCrossLoises(json);
	result.push(output._convertList(loisData, output.consts.LOISES_COLUMNS, ' / '));
	result.push('');
	result.push('');

	result.push('■メモリー■');
	const memoryData = output._getDoubleCrossMemories(json);
	result.push(output._convertList(memoryData, output.consts.MEMORIES_COLUMNS, ' / '));
	result.push('');
	result.push('');

	result.push('■その他■');
	result.push((json.freeNote || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));
	
	return result.join('\n');
};