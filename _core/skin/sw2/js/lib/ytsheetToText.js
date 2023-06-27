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

io.github.shunshun94.trpg.ytsheet.generateCharacterTextFromYtSheet2SwordWorld2Enemy = (json) => {
	const result = [];

	result.push(`種族名：${json.monsterName}`);
	if(json.characterName) {result.push(`個体名：${json.characterName}`);}
	if(json.taxa) {result.push(`　分類：${json.taxa}`);}
	if(json.sin) {result.push(`　穢れ：${json.sin}`);}
	result.push('');

	result.push(`知能：${(json.intellect || '').padEnd(12 - (json.intellect || '').length, ' ')}知覚：${(json.perception || '').padEnd(14-(json.perception || '').length, ' ')}反応：${json.disposition || ''}`);
	result.push(`言語：${json.language || ''}  生息地：${json.habitat || ''}`);
	result.push('');
	result.push('');

	result.push('□基本能力');
	result.push(`　知名度/弱点：${json.reputation || 0}/${json['reputation+'] || 0}  ` + `${json.weakness ? '弱点：' + json.weakness : ''}`);
	result.push(`　先制値：${json.initiative || 0}  移動速度：${json.mobility || 0}`);
	result.push(`　生命抵抗力：${json.vitResist || 0} (${json.vitResistFix || 0})  精神抵抗力：${json.mndResist || 0} (${json.mndResistFix || 0})`);
	result.push('');

	const partsLength = Number(json.statusNum);
	const parts = [];
	for(let i = 0; i < partsLength; i++) {
		parts.push({
			name: json[`status${i + 1}Style`] || '',
			hit: io.github.shunshun94.trpg.ytsheet.isNumberValue(json[`status${i + 1}Accuracy`]) ? `${json[`status${i + 1}Accuracy`]} (${json[`status${i + 1}AccuracyFix`]})` : '―', 
			damage: json[`status${i + 1}Damage`] || '―',
			dodge: io.github.shunshun94.trpg.ytsheet.isNumberValue(json[`status${i + 1}Evasion`]) ? `${json[`status${i + 1}Evasion`]} (${json[`status${i + 1}EvasionFix`]})` : '―',
			defense: json[`status${i + 1}Defense`] || '0',
			hp:json[`status${i + 1}Hp`] || '0',
			mp: json[`status${i + 1}Mp`] || '―'
		});
	}
	result.push(io.github.shunshun94.trpg.ytsheet._convertList(parts, io.github.shunshun94.trpg.ytsheet.consts.ENEMY_STATUS_COLUMNS, '|'));
	if(partsLength !== 1) {
		result.push(`　部位数：${partsLength}（${json.parts || '?'}） コア部位：${json.coreParts || '?'}`);
	}
	result.push('');
	result.push('');

	result.push('□特殊能力');
	result.push('　' + (json.skills || '').replaceAll('&lt;br&gt;', '\n　'));
	result.push('');
	result.push('');

	result.push('□戦利品');
	const lootsLength = Number(json.lootsNum);
	const lootsList = [];
	for(let i = 0; i < lootsLength; i++) {
		if(json[`loots${i + 1}Num`] && json[`loots${i + 1}Item`]) {
			lootsList.push({
				dice: json[`loots${i + 1}Num`],
				value: json[`loots${i + 1}Item`]
			});
		}
	}
	result.push(io.github.shunshun94.trpg.ytsheet._convertList(lootsList, null, '|'));
	result.push('');
	result.push('');

	result.push('□説明');
	result.push('　' + (json.description || '').replaceAll('&lt;br&gt;', '\n　'));
	return result.join('\n');
};

io.github.shunshun94.trpg.ytsheet.generateCharacterTextFromYtSheet2SwordWorld2PC = (json) => {
	const result = [];
	result.push(`キャラクター名：${json.aka ? `“${json.aka}”` : '' }${json.characterName||''}`);
	result.push(`種族：${json.race || ''} ${json.raceAbility || ''}`);
	result.push(`生まれ：${json.birth || ''}`);
	if(json.faith) { result.push(`信仰：${json.faith}`); }
	result.push(`年齢：${json.age || '?'}`);
	result.push(`性別：${json.gender || '?'}`);
	result.push(`穢れ度：${json.sin || '0'}`);
	result.push('');

	result.push('●能力値');
	const leftThLength = 9;
	const singleColumnLength = 10;
	const halfColumnLength = singleColumnLength / 2;
	const doubleColumnLength = singleColumnLength * 2;
	const baseValuesPrefixSpaces = ''.padStart(leftThLength, ' '); 
	result.push(`${baseValuesPrefixSpaces}${'技'.padStart(singleColumnLength - 1, ' ')}${'体'.padStart(doubleColumnLength - 1, ' ')}${'心'.padStart(doubleColumnLength  - 1, ' ')}`);
	result.push(`${baseValuesPrefixSpaces}${(json.sttBaseTec || '').padStart(singleColumnLength, ' ')}${(json.sttBasePhy || '').padStart(doubleColumnLength, ' ')}${(json.sttBaseSpi || '').padStart(doubleColumnLength, ' ')}`);
	result.push(`${baseValuesPrefixSpaces}${'器用'.padStart(halfColumnLength - 2, ' ')}${'敏捷'.padStart(singleColumnLength - 2, ' ')}${'筋力'.padStart(singleColumnLength - 2, ' ')}${'生命'.padStart(singleColumnLength - 2, ' ')}${'知力'.padStart(singleColumnLength - 2, ' ')}${'精神'.padStart(singleColumnLength - 2, ' ')}`);
	result.push(`${'ダイス'.padEnd(leftThLength - 3, ' ')}${(json.sttBaseA || '').padStart(halfColumnLength, ' ')}${(json.sttBaseB || '').padStart(singleColumnLength, ' ')}${(json.sttBaseC || '').padStart(singleColumnLength, ' ')}${(json.sttBaseD || '').padStart(singleColumnLength, ' ')}${(json.sttBaseE || '').padStart(singleColumnLength, ' ')}${(json.sttBaseF || '').padStart(singleColumnLength, ' ')}`);
	result.push(`${'成長'.padEnd(leftThLength - 2, ' ')}${json.sttGrowA.padStart(halfColumnLength, ' ')}${json.sttGrowB.padStart(singleColumnLength, ' ')}${json.sttGrowC.padStart(singleColumnLength, ' ')}${json.sttGrowD.padStart(singleColumnLength, ' ')}${json.sttGrowE.padStart(singleColumnLength, ' ')}${json.sttGrowF.padStart(singleColumnLength, ' ')}`);
	result.push(''.padEnd(leftThLength + doubleColumnLength * 3, '-'));
	result.push(`${'合計'.padEnd(leftThLength - 2, ' ')}${json.sttDex.padStart(halfColumnLength, ' ')}${json.sttAgi.padStart(singleColumnLength, ' ')}${json.sttStr.padStart(singleColumnLength, ' ')}${json.sttVit.padStart(singleColumnLength, ' ')}${json.sttInt.padStart(singleColumnLength, ' ')}${json.sttMnd.padStart(singleColumnLength, ' ')}`);
	result.push(`${'修正'.padEnd(leftThLength - 2, ' ')}${(json.sttAddA || '').padStart(halfColumnLength, ' ')}${(json.sttAddB || '').padStart(singleColumnLength, ' ')}${(json.sttAddC || '').padStart(singleColumnLength, ' ')}${(json.sttAddD || '').padStart(singleColumnLength, ' ')}${(json.sttAddE || '').padStart(singleColumnLength, ' ')}${(json.sttAddF || '').padStart(singleColumnLength, ' ')}`);
	result.push(''.padEnd(leftThLength + doubleColumnLength * 3, '-'));
	result.push(`${'ボーナス'.padEnd(leftThLength - 4, ' ')}${json.bonusDex.padStart(halfColumnLength, ' ')}${json.bonusAgi.padStart(singleColumnLength, ' ')}${json.bonusStr.padStart(singleColumnLength, ' ')}${json.bonusVit.padStart(singleColumnLength, ' ')}${json.bonusInt.padStart(singleColumnLength, ' ')}${json.bonusMnd.padStart(singleColumnLength, ' ')}`)
	result.push('');

	result.push(`${baseValuesPrefixSpaces}${'生命抵抗'.padStart(singleColumnLength - 4, ' ')}${'精神抵抗'.padStart(singleColumnLength - 4, ' ')}${'HP'.padStart(singleColumnLength, ' ')}${'MP'.padStart(singleColumnLength, ' ')}`);
	result.push(`${'基本'.padEnd(leftThLength - 2, ' ')}${json.vitResistBase.padStart(singleColumnLength, ' ')}${json.mndResistBase.padStart(singleColumnLength, ' ')}${json.hpBase.padStart(singleColumnLength, ' ')}${json.mpBase.padStart(singleColumnLength, ' ')}`);
	result.push(`${'修正'.padEnd(leftThLength - 2, ' ')}${( json.vitResistAddTotal || '0' ).padStart(singleColumnLength, ' ')}${( json.mndResistAddTotal || '0' ).padStart(singleColumnLength, ' ')}${( json.hpAddTotal || '0' ).padStart(singleColumnLength, ' ')}${( json.mpAddTotal || '0' ).padStart(singleColumnLength, ' ')}`);
	result.push(''.padEnd(leftThLength + singleColumnLength * 4, '-'));
	result.push(`${'合計'.padEnd(leftThLength - 2, ' ')}${json.vitResistTotal.padStart(singleColumnLength, ' ')}${json.mndResistTotal.padStart(singleColumnLength, ' ')}${json.hpTotal.padStart(singleColumnLength, ' ')}${json.mpTotal.padStart(singleColumnLength, ' ')}`);
	result.push('');
	
	result.push(`${baseValuesPrefixSpaces}${'先制'.padStart(singleColumnLength - 4, ' ')}${'魔物知識'.padStart(singleColumnLength - 2, ' ')}${'通常移動'.padStart(singleColumnLength - 4, ' ')}`);
	result.push(`${'基本'.padEnd(leftThLength - 2, ' ')}${String( Number(json.initiative) - Number(json.initiativeAdd || '0') ).padStart(singleColumnLength, ' ')}${String( Number(json.monsterLore) - Number(json.monsterLoreAdd || '0') ).padStart(singleColumnLength, ' ')}${json.mobilityBase.padStart(singleColumnLength, ' ')}`);
	result.push(`${'修正'.padEnd(leftThLength - 2, ' ')}${( json.initiativeAdd || '0' ).padStart(singleColumnLength, ' ')}${( json.monsterLoreAdd || '0' ).padStart(singleColumnLength, ' ')}${( json.mobilityAddTotal || '0' ).padStart(singleColumnLength, ' ')}`);
	result.push(''.padEnd(leftThLength + singleColumnLength * 4, '-'));
	result.push(`${'合計'.padEnd(leftThLength - 2, ' ')}${json.initiative.padStart(singleColumnLength, ' ')}${json.monsterLore.padStart(singleColumnLength, ' ')}${json.mobilityTotal.padStart(singleColumnLength, ' ')}`);
	result.push('');

	result.push('●レベル・技能');
	const skillNameColumnLength = 20;
	result.push(`${'冒険者レベル'.padEnd(skillNameColumnLength - 6, ' ')}: ${(json.level || '').padStart(3, ' ')} Lv`);

	result.push('------------------------------');

	const lvSortedClassNames = SET.classNames.slice().sort((a,b) => {
		return (Number(json['lv'+SET.class[a].id] || 0) < Number(json['lv'+SET.class[b].id]) || 0) ? 1 : -1;
	});
	for(const name of lvSortedClassNames) {
		const lv = json['lv'+SET.class[name].id];
		if(lv) {
			result.push(`${name.padEnd(skillNameColumnLength - name.length, ' ')}: ${lv.padStart(3, ' ')} Lv`);
		}
	}
	result.push('');

	result.push('●戦闘特技 (自動習得は省略)');
	for(let i of SET.featsLv) {
		if(json[`combatFeatsLv${i}`]) {
			result.push(`${String(i).replace(/[^0-9]/g, '').padStart(4, ' ')}： ${json[`combatFeatsLv${i}`]}`);
		} 
	}
	const mysticArtsLength = json.mysticArtsNum ? Number(json.mysticArtsNum) : 0;
	for(let i = 0; i < mysticArtsLength; i++) {
		result.push(`秘伝：${json[`mysticArts${i+1}`]}`);
	}

	for(let name of SET.classNames) {
		const lv = Number(json['lv'+SET.class[name].id] || 0);
		if(!lv || !SET.class[name]) continue;
		if(SET.class[name].craft){
			const craftName = 'craft'
				+ SET.class[name].craft.eName.charAt(0).toUpperCase()
				+ SET.class[name].craft.eName.slice(1);

			result.push('');
			result.push(`●${SET.class[name].craft.jName}`);
			for(let i = 1; i < lv; i++) {
				if(json[`${craftName}${i}`]) {
					result.push(`${String(i).padStart(2, ' ')}： ${json[`${craftName}${i}`]}`);
				}
			}
		}
		else if(SET.class[name].magic && SET.class[name].magic.data){
			const magicName = 'magic'
				+ SET.class[name].magic.eName.charAt(0).toUpperCase()
				+ SET.class[name].magic.eName.slice(1);

			result.push('');
			result.push(`●${SET.class[name].magic.jName}`);
			for(let i = 1; i < lv; i++) {
				if(json[`${magicName}${i}`]) {
					result.push(`${String(i).padStart(2, ' ')}： ${json[`${magicName}${i}`]}`);
				}
			}
		}
	}
	result.push('');

	result.push('●魔力');
	const magicColumnLength = 8;
	console.log(SET.classCasters)
	for(let name of SET.classCasters) {
		const id = SET.class[name].id;
		if(json['lv'+id]) {
			const magicName = SET.class[name].magic.jName;
			result.push(`  ${magicName.padStart(magicColumnLength - magicName.length, ' ')}：${json['magicPower'+id].padStart(3, ' ')}`);
		}
	}
	result.push('');

	result.push('●装備');
	const weaponCount = Number(json.weaponNum);
	if(weaponCount) {
		result.push(`　- 武器`);
	}
	const weapons = [];
	for(var i = 0; i < weaponCount; i++) {
		if(json[`weapon${i+1}Name`]) {
			weapons.push({
				name: `${json[`weapon${i+1}Name`]}${json[`weapon${i+1}Own`] ? '(専)' : ''} ${json[`weapon${i+1}Category`] ? `(${json[`weapon${i+1}Category`]})` : ''}`,
				usage: json[`weapon${i+1}Usage`] || '',
				reqd: json[`weapon${i+1}Reqd`] || '',
				acc: json[`weapon${i+1}Acc`] || '',
				accTotal: json[`weapon${i+1}AccTotal`] || '',
				rate: json[`weapon${i+1}Rate`] || '',
				crit: json[`weapon${i+1}Crit`] || '',
				dmg: json[`weapon${i+1}Dmg`] || '',
				dmgTotal: json[`weapon${i+1}DmgTotal`] || '',
				note: json[`weapon${i+1}Note`] || ''
			});
		}
	}
	result.push(io.github.shunshun94.trpg.ytsheet._convertList(weapons, io.github.shunshun94.trpg.ytsheet.consts.PC_WEAPONS_COLUMNS, ' | '));
	result.push('');
	if(json.armourName || json.shield1Name || json.defOther1Name) {
		result.push(`　- 防具`);
	} else {
		result.push(`　- 回避・防護点`);
	}
	const armors = [];
	if(json.armour1Name) {
		armors.push({
			type: '鎧',
			name: `${json.armour1Name}${json.armour1Own ? '(専)' : ''}`,
			reqd: json.armour1Reqd || '0',
			dodge: json.armour1Eva || '0',
			defense: json.armour1Def || '0',
			note: json.armour1Note || ''
		});
	}
	if(json.shield1Name) {
		armors.push({
			type: '盾',
			name: `${json.shield1Name}${json.shield1Own ? '(専)' : ''}`,
			reqd: json.shield1Reqd || '0',
			dodge: json.shield1Eva || '0',
			defense: json.shield1Def || '0',
			note: json.shield1Note || ''
		});
	}
	for(let i = 0; i <= 3; i++) {
		if(json[`defOther${i}Name`] || json[`defOther${i}Eva`] || json[`defOther${i}Def`]) {
			armors.push({
				type: '他'+i,
				name: json[`defOther${i}Name`],
				reqd: json[`defOther${i}Reqd`] || '0',
				dodge: json[`defOther${i}Eva`] || '0',
				defense: json[`defOther${i}Def`] || '0',
				note: json[`defOther${i}Note`] || ''
			});
		}
	}
	for(let i = 1; i <= 3; i++) {
		let names = [];
		if (json[`defTotal${i}CheckArmour1`]){ names.push('鎧'); }
		if (json[`defTotal${i}CheckShield1`]){ names.push('盾'); }
		if (json[`defTotal${i}CheckDefOther1`] && (json.defOther1Name || json.defOther1Eva || json.defOther1Def)){ names.push('他1'); }
		if (json[`defTotal${i}CheckDefOther2`] && (json.defOther2Name || json.defOther2Eva || json.defOther2Def)){ names.push('他2'); }
		if (json[`defTotal${i}CheckDefOther3`] && (json.defOther3Name || json.defOther3Eva || json.defOther3Def)){ names.push('他3'); }
		if(names.length){
			armors.push({
				type: '合計',
				name: names.join('＋'),
				reqd: '',
				dodge: json[`defenseTotal${i}Eva`] || '0',
				defense: json[`defenseTotal${i}Def`] || '0',
				note: json[`defenseTotal${i}Note`] || ''
			});
		}
	}
	result.push(io.github.shunshun94.trpg.ytsheet._convertList(armors, io.github.shunshun94.trpg.ytsheet.consts.PC_ARMORS_COLUMNS, ' | '));
	result.push('');
	const accessoryPartList = [];
	const accessoryList = [];
	for(let key in io.github.shunshun94.trpg.ytsheet.consts.accessory.part) {
		if(json[`accessory${key}Name`]) { accessoryPartList.push(key); }
	}
	if(accessoryPartList.length) {result.push(`　- 装飾品`);}
	accessoryPartList.forEach((part)=>{
		const rawPartName = io.github.shunshun94.trpg.ytsheet.consts.accessory.part[part];
		const partName = rawPartName;
		let i = 0;
		while(json[`accessory${part}${''.padStart(i, '_')}Name`]) {
			const name = json[`accessory${part}${''.padStart(i, '_')}Name`];
			const isCustom = json[`accessory${part}${''.padStart(i, '_')}Own`] ? '(専)' : '';
			const note = json[`accessory${part}${''.padStart(i, '_')}Note`] || '';
			accessoryList.push({
				name: `${partName}： ${name}${isCustom}`,
				note: note
			});
			i++;
		}
	});
	result.push(io.github.shunshun94.trpg.ytsheet._convertList(accessoryList, null, ' / '));
	result.push('');

	result.push('●所持品');
	const itemListPrefix = '  ';
	result.push(itemListPrefix + (json.items || '').replace(/&lt;br&gt;&lt;br&gt;/gm, '&lt;br&gt;').replace(/&lt;br&gt;/gm, '\n').replace(/\n/gm, '\n  '));
	if(json.lvAlc) {
		result.push('');
		const cardColumnLength = 5;
		const cardTopColumnLength = 8;
		let cardTableHader = '';
		for(var key in io.github.shunshun94.trpg.ytsheet.consts.card.color) {
			cardTableHader += `${io.github.shunshun94.trpg.ytsheet.consts.card.color[key].padStart(cardColumnLength - 1, ' ')}`;
		}
		result.push(`${itemListPrefix}${'カード'.padStart(cardTopColumnLength - 3, ' ')}${cardTableHader}`);
		io.github.shunshun94.trpg.ytsheet.consts.card.rank.forEach((rank)=>{
			let line = itemListPrefix + rank.padStart(cardTopColumnLength, ' ');
			for(var key in io.github.shunshun94.trpg.ytsheet.consts.card.color) {
				line += (json[`card${key}${rank}`] || '').padStart(cardColumnLength, ' ');
			}
			result.push(line);
		});
	}
	result.push('');

	result.push('●資金');
	result.push('  所持金：' + (json.moneyTotal　|| json.money || 0));
	result.push('  　預金：' + (json.depositTotal || 0));
	result.push('  　借金：' + (json.debtTotal || 0));
	result.push('');

	result.push('●習得言語（初期習得の言語は除く）');
	const languageLength = Number(json.languageNum);
	const languageNameColumnLength = 24;
	const languageColumnLength = 5;
	result.push(`  ${'名称'.padStart(languageNameColumnLength - 2, ' ')}${'会話'.padStart(languageColumnLength - 2, ' ')}${'読文'.padStart(languageColumnLength - 2, ' ')}`);
	for(var i = 0; i < languageLength; i++) {
		const name = json[`language${i+1}`] || '？？？';
		const talk = json[`language${i+1}Talk`] ? '〇' : '　';
		const read = json[`language${i+1}Read`] ? '〇' : '　';
		if(json[`language${i+1}`] || json[`language${i+1}Talk`] || json[`language${i+1}Read`]) {
			result.push(`  ${name.padStart(languageNameColumnLength - name.length, ' ')}${talk.padStart(languageColumnLength - 1, ' ')}${read.padStart(languageColumnLength - 1, ' ')}`);
		}
	}
	result.push('');

	result.push('●名誉点');
	const historyLength = Number(json.historyNum || '0'); 
	let totalHonor = 0;
	let honorDiffCandidate = Number(json.honor);
	const honorPrefix = '  ';
	const honorLength = Number(json.honorItemsNum || '0');
	const dishonorLength = Number(json.dishonorItemsNum || '0')
	result.push(`　- 名誉`);
	result.push(`${honorPrefix}${honorPrefix}名誉点残高：${json.honor || 0}`);
	for(let i = 0; i < historyLength + 1; i++) {
		totalHonor += Number(json[`history${i}Honor`] || '0');
	}
	for(let i = 0; i < honorLength; i++) {
		if(json[`honorItem${i+1}`]) {
			result.push(`${honorPrefix}${honorPrefix}${json[`honorItem${i+1}`]}：${json[`honorItem${i+1}Pt`] || 0}`);
			honorDiffCandidate += Number(json[`honorItem${i+1}Pt`] || '0');
		}
	}
	if(totalHonor !== honorDiffCandidate) {
		result.push(`${honorPrefix}${honorPrefix}冒険者ランク(${json.rank || '？？？'})：${totalHonor - honorDiffCandidate}`);
	}
	result.push(`　- 不名誉`);
	for(let i = 0; i < dishonorLength; i++) {
		if(json[`dishonorItem${i+1}`]) {
			result.push(`${honorPrefix}${honorPrefix}${json[`dishonorItem${i+1}`]}：${json[`dishonorItem${i+1}Pt`] || 0}`);
		}
	}
	result.push(`${honorPrefix}${honorPrefix}合計：${json.dishonor || 0}`);
	result.push('');

	if(historyLength) {
		const historyCountColumnLength = 4;
		const historyColumnLength = 20;
		result.push('●成長');
		result.push(`${'回数'.padStart(historyCountColumnLength - 2, ' ')}${'名誉点'.padStart(historyColumnLength - 3, ' ')}${'経験点'.padStart(historyColumnLength - 3, ' ')}${'ガメル'.padStart(historyColumnLength - 3, ' ')}  情報`);		
		for(let i = 0; i < historyLength; i++) {
			result.push(`${String(i+1).padStart(historyCountColumnLength, ' ')}${(json[`history${i+1}Honor`] || '').padStart(historyColumnLength, ' ')}${(json[`history${i+1}Exp`] || '').padStart(historyColumnLength, ' ')}${(json[`history${i+1}Money`] || '').padStart(historyColumnLength, ' ')}  ${(json[`history${i+1}Title`] || '')}`);
		}		
	}


	return result.join('\n');
};
