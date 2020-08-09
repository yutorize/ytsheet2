/*  Copyright 2020 @Shunshun94

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
var io = io || {};
io.github = io.github || {};
io.github.shunshun94 = io.github.shunshun94 || {};
io.github.shunshun94.trpg = io.github.shunshun94.trpg || {};
io.github.shunshun94.trpg.ytsheet = io.github.shunshun94.trpg.ytsheet || {};
io.github.shunshun94.trpg.ytsheet.generateCharacterTextFromYtSheet2SwordWorldPC = (json) => {
	const result = [];
	result.push(`キャラクター名：${json.characterName}`);
	result.push(`種族：${json.race} ${json.raceAbility}`);
	result.push(`生まれ：${json.birth}`);
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
	result.push(`${'ダイス'.padEnd(leftThLength - 3, ' ')}${json.sttBaseA.padStart(halfColumnLength, ' ')}${json.sttBaseB.padStart(singleColumnLength, ' ')}${json.sttBaseC.padStart(singleColumnLength, ' ')}${json.sttBaseD.padStart(singleColumnLength, ' ')}${json.sttBaseE.padStart(singleColumnLength, ' ')}${json.sttBaseF.padStart(singleColumnLength, ' ')}`);
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
	result.push(`${'冒険者レベル'.padEnd(skillNameColumnLength - 6, ' ')}: ${json.level.padStart(3, ' ')} Lv`);
	for(let key in io.github.shunshun94.trpg.ytsheet.consts.skills) {
		if(json[key]) {
			const name = io.github.shunshun94.trpg.ytsheet.consts.skills[key];
			result.push(`${name.padEnd(skillNameColumnLength - name.length, ' ')}: ${json[key].padStart(3, ' ')} Lv`);
		}
	}
	result.push('');

	result.push('●戦闘特技 (自動習得は省略)');
	for(let i = 0; i < io.github.shunshun94.trpg.ytsheet.consts.maxLevel; i++) {
		if(json[`combatFeatsLv${i + 1}`]) {
			result.push(`${String(i + 1).padStart(4, ' ')}： ${json[`combatFeatsLv${i + 1}`]}`);
		} 
	}
	const mysticArtsLength = json.mysticArtsNum ? Number(json.mysticArtsNum) : 0;
	for(let i = 0; i < mysticArtsLength; i++) {
		result.push(`秘伝：${json[`mysticArts${i+1}`]}`);
	}
	result.push('');

	result.push('●習得特技');
	for(var key in io.github.shunshun94.trpg.ytsheet.consts.levelSkills) {
		if(json[`${key}1`]) {			
			result.push(`　- ${io.github.shunshun94.trpg.ytsheet.consts.levelSkills[key]}`);
			for(let i = 0; i < io.github.shunshun94.trpg.ytsheet.consts.maxLevel; i++) {
				if(json[`${key}${i + 1}`]) {
					result.push(`${String(i + 1).padStart(2, ' ')}： ${json[`${key}${i + 1}`]}`);
				}
			}
		}
	}
	result.push('');

	result.push('●装備');
	const weaponCount = Number(json.weaponNum);
	const equipsColumnLength = 10;
	const equipsPrefix = '    ';
	const equipsWeaponHeader = `${equipsPrefix}${'用法'.padStart(equipsColumnLength-2, ' ')}${'必筋'.padStart(equipsColumnLength-2, ' ')}${'命中修正'.padStart(equipsColumnLength-4, ' ')}${'命中'.padStart(equipsColumnLength-2, ' ')}${'威力'.padStart(equipsColumnLength-2, ' ')}${'C値'.padStart(equipsColumnLength-1, ' ')}${'ダメ修正'.padStart(equipsColumnLength-4, ' ')}${'追加ダメ'.padStart(equipsColumnLength-4, ' ')}`;
	const equipsHeader = ``;
	const equipsProtectorPrefix = `${equipsPrefix}${'必筋'.padStart(equipsColumnLength-2, ' ')}${'回避'.padStart(equipsColumnLength-2, ' ')}${'防護'.padStart(equipsColumnLength-2, ' ')}${'メモ'.padStart(equipsColumnLength-2, ' ')}`;
	if(weaponCount) {
		result.push(`　- 武器`);
	}
	for(var i = 0; i < weaponCount; i++) {
		result.push(`${equipsPrefix}名前：${json[`weapon${i+1}Name`]}${json[`weapon${i+1}Own`] ? '(専)' : ''} ${json[`weapon${i+1}Category`] ? `(カテゴリ ${json[`weapon${i+1}Category`]})` : ''}`);
		if(json[`weapon${i+1}Note`]){ result.push(`${equipsPrefix}メモ： ${json[`weapon${i+1}Note`]}`); }
		result.push(equipsWeaponHeader);
		result.push(`${equipsPrefix}${(json[`weapon${i+1}Usage`] || '').padStart(equipsColumnLength, ' ')}${(json[`weapon${i+1}Reqd`] || '').padStart(equipsColumnLength, ' ')}${(json[`weapon${i+1}Acc`] || '').padStart(equipsColumnLength, ' ')}${(json[`weapon${i+1}AccTotal`] || '').padStart(equipsColumnLength, ' ')}${(json[`weapon${i+1}Rate`] || '').padStart(equipsColumnLength, ' ')}${(json[`weapon${i+1}Crit`] || '').padStart(equipsColumnLength, ' ')}${(json[`weapon${i+1}Dmg`] || '').padStart(equipsColumnLength, ' ')}${(json[`weapon${i+1}DmgTotal`] || '').padStart(equipsColumnLength, ' ')}`)
	}
	if(json.armourName || json.shieldName || json.defOtherName) {
		result.push(`　- 防具`);
	} else {
		result.push(`　- 回避・防護点`);
	}
	if(json.armourName) {
		result.push(`${equipsPrefix}鎧: ${json.armourName}${json.armourOwn ? '(専)' : ''}`);
		result.push(equipsProtectorPrefix)
		result.push(`${equipsPrefix}${(json.armourReqd || '0').padStart(equipsColumnLength, ' ')}${(json.armourEva || '0').padStart(equipsColumnLength, ' ')}${(json.armourDef || '0').padStart(equipsColumnLength, ' ')}      ${json.armourNote || ''}`);
	}
	if(json.shieldName) {
		result.push(`${equipsPrefix}盾: ${json.shieldName}${json.shieldOwn ? '(専)' : ''}`);
		result.push(equipsProtectorPrefix)
		result.push(`${equipsPrefix}${(json.shieldReqd || '0').padStart(equipsColumnLength, ' ')}${(json.shieldEva || '0').padStart(equipsColumnLength, ' ')}${(json.shieldDef || '0').padStart(equipsColumnLength, ' ')}      ${json.shieldNote || ''}`);
	}
	if(json.defOtherName) {
		result.push(`${equipsPrefix}他: ${json.defOtherName}`);
		result.push(equipsProtectorPrefix)
		result.push(`${equipsPrefix}${(json.defOtherReqd || '0').padStart(equipsColumnLength, ' ')}${(json.defOtherEva || '0').padStart(equipsColumnLength, ' ')}${(json.defOtherDef || '0').padStart(equipsColumnLength, ' ')}      ${json.defOtherNote || ''}`);
	}
	if(json.armourName || json.shieldName || json.defOtherName) {
		result.push(`${equipsPrefix}${''.padStart(equipsColumnLength*3, '-')}`);
	}
	result.push(`${equipsPrefix}${' '.padStart(equipsColumnLength, ' ')}${'回避'.padStart(equipsColumnLength-2, ' ')}${'防護'.padStart(equipsColumnLength-2, ' ')}`);
	result.push(`${equipsPrefix}${'合計'.padStart(equipsColumnLength-2, ' ')}${json.defenseTotalAllEva.padStart(equipsColumnLength, ' ')}${json.defenseTotalAllDef.padStart(equipsColumnLength, ' ')}`);

	const accessoryPartList = [];
	const accessoryPartsNameColumnLength = 6;
	for(let key in io.github.shunshun94.trpg.ytsheet.consts.accessory.part) {
		if(json[`accessory${key}Name`]) { accessoryPartList.push(key); }
	}
	if(accessoryPartList.length) {result.push(`　- 装飾品`);}
	accessoryPartList.forEach((part)=>{
		const rawPartName = io.github.shunshun94.trpg.ytsheet.consts.accessory.part[part];
		const partName = rawPartName.padEnd(accessoryPartsNameColumnLength - rawPartName.length, ' ');
		let i = 0;
		while(json[`accessory${part}${''.padStart(i, '_')}Name`]) {
			const name = json[`accessory${part}${''.padStart(i, '_')}Name`];
			const isCustom = json[`accessory${part}${''.padStart(i, '_')}Own`] ? '(先)' : '';
			const note = json[`accessory${part}${''.padStart(i, '_')}Note`] || '';
			result.push(`${equipsPrefix}${partName}： ${name}${isCustom} ${note}`);
			i++;
		}
	});
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

	result.push('●魔力');
	const magicColumnLength = 8;
	for(let key in io.github.shunshun94.trpg.ytsheet.consts.magic) {
		if(json[key.replace('magicPower', 'lv')]) {
			const name = io.github.shunshun94.trpg.ytsheet.consts.magic[key];
			result.push(`  ${name.padStart(magicColumnLength - name.length, ' ')}：${json[key].padStart(3, ' ')}`);
		}
	}
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
