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
io.github.shunshun94.trpg.ccfolia = io.github.shunshun94.trpg.ccfolia || {};

io.github.shunshun94.trpg.ccfolia.CONSTS = {};
io.github.shunshun94.trpg.ccfolia.CONSTS.DEFAULT_PC_PICTURE = 'https://shunshun94.github.io/shared/hiyoko.jpg';
io.github.shunshun94.trpg.ccfolia.CONSTS.DEFAULT_ENEMY_PICTURE = 'https://shunshun94.github.io/shared/pics/default_enemy.png';

io.github.shunshun94.trpg.ccfolia.getCharacterSeed = ()=>{
	return {
		meta: {
			version: "1.1.0"
		},
		entities: {
			room: {},
			items: {},
			decks: {},
			characters: {},
			scenes: {}
		},
		resources: {}
	};
};

io.github.shunshun94.trpg.ccfolia.generateRndStr = () => {
	let randomString = '';
	const baseString ='0123456789abcdefghijklmnopqrstuvwxyz';
	for(let i = 0; i < 64; i++) {
		randomString += baseString.charAt( Math.floor( Math.random() * baseString.length));
	}
	return randomString;
};

io.github.shunshun94.trpg.ccfolia.getPcSkillList = (json) => {
	return [
		{value:json.level, label:'冒険者レベル'},
		{value:json.lvFig, label:'ファイター'},
		{value:json.lvGra, label:'グラップラー'},
		{value:json.lvFen, label:'フェンサー'},
		{value:json.lvSho, label:'シューター'},
		{value:json.lvSor, label:'ソーサラー'},
		{value:json.lvCon, label:'コンジャラー'},
		{value:json.lvPri, label:'プリースト'},
		{value:json.lvFai, label:'フェアリーテイマー'},
		{value:json.lvMag, label:'マギテック'},
		{value:json.lvSco, label:'スカウト'},
		{value:json.lvRan, label:'レンジャー'},
		{value:json.lvSag, label:'セージ'},
		{value:json.lvEnh, label:'エンハンサー'},
		{value:json.lvBar, label:'バード'},
		{value:json.lvRid, label:'ライダー'},
		{value:json.lvAlc, label:'アルケミスト'},
		{value:json.lvWar, label:'ウォーリーダー'},
		{value:json.lvMys, label:'ミスティック'},
		{value:json.lvDem, label:'デーモンルーラー'},
		{value:json.lvDru, label:'ドルイド'},
		{value:json.lvPhy, label:'フィジカルマスター'},
		{value:json.lvGri, label:'グリモワール'},
		{value:json.lvAri, label:'アリストクラシー'},
		{value:json.lvArt, label:'アーティザン'}].filter((d)=>{return d.value});	
};

io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2SwordWorldPC = async (json, opt_sheetUrl = '', opt_defaultPictureUrl = io.github.shunshun94.trpg.ccfolia.CONSTS.DEFAULT_PC_PICTURE) => {
	const result = io.github.shunshun94.trpg.ccfolia.getCharacterSeed();
	const skills = io.github.shunshun94.trpg.ccfolia.getPcSkillList(json);
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_sheetUrl);
	const character = {
			name: json.characterName,
			playerName: json.playerName,
			memo: `PL: ${json.playerName || 'PL情報無し'}\n${json.race || '種族不明'}\n\n${json.imageURL ? '立ち絵：' + (json.imageCopyright || '権利情報なし') : ''}`,
			initiative: '2',
			externalUrl: opt_sheetUrl,
			status: [
				{
					label: 'HP',
					value: json.hpTotal,
					max: json.hpTotal
				}, {
					label: 'MP',
					value: json.mpTotal,
					max: json.mpTotal
				}
			],
			params: defaultPalette.parameters || [
				{label:'器用度B', value:json.bonusDex},
				{label:'敏捷度B', value:json.bonusAgi},
				{label:'筋力B',value:json.bonusStr},
				{label:'生命力B',value:json.bonusVit},
				{label:'知力B', value:json.bonusInt},
				{label:'精神力B', value:json.bonusMnd}
			].concat(skills),
			iconUrl: json.imageURL || opt_defaultPictureUrl,
			faces: [],
			x: 0, y: 0, z: 0,
			angle: 0, width: 4, height: 4,
			active: true, secret: false,
			invisible: false, hideStatus: false,
			color: '',
			roomId: null,
			commands: defaultPalette.palette,
			speaking: true
	};

	if(defaultPalette === '') {
		const palette = [];
		palette.push(`現在の状態　HP:{HP} / MP:{MP}`);
		if(json.lvSco) {
			palette.push(`2d6+{スカウト}+{敏捷度B} 先制判定 (スカウト)`);
		}
		if(json.lvWar) {
			palette.push(`2d6+{ウォーリーダー}+{敏捷度B} 先制判定 (ウォーリーダー・敏捷)`);
			palette.push(`2d6+{ウォーリーダー}+{知力B} 先制判定 (ウォーリーダー・知力)`);
		}
		if(json.lvSag) {
			palette.push(`2d6+{セージ}+{知力B} 魔物知識判定（セージ）`);
		}
		if(json.lvRid) {
			palette.push(`2d6+{ライダー}+{知力B} 魔物知識判定（ライダー）`);
		}
		const weaponLength = Number(json.weaponNum);
		for(let i = 0; i < weaponLength; i++) {
			if(json['weapon' + (i + 1) + 'Name']) {
				palette.push(`2d6+${json['weapon' + (i + 1) + 'AccTotal'] || '0'}+0 命中判定 (${json['weapon' + (i + 1) + 'Name']})`);
				palette.push(`k${json['weapon' + (i + 1) + 'Rate'] || '0'}+${json['weapon' + (i + 1) + 'DmgTotal'] || '0'}+0@(${json['weapon' + (i + 1) + 'Crit'] || '10'}-0)$+0   ダメージ (${json['weapon' + (i + 1) + 'Name']})`);				
			}
		}
		[[json.lvSor, json.magicPowerSor, '真語魔法'],
		 [json.lvCon, json.magicPowerCon, '操霊魔法'],
		 [json.lvPri, json.magicPowerPri, '神聖魔法'],
		 [json.lvMag, json.magicPowerMag, '魔動機術'],
		 [json.lvFai, json.magicPowerFai, '妖精魔法'],
		 [json.lvDem, json.magicPowerDem, '召異魔法'],
		 [json.lvDru, json.magicPowerDru, '森羅魔法'],
		 [json.lvGri, json.magicPowerGri, '秘奥魔法'],].filter((d)=>{
			return d[0];
		}).forEach((v)=>{
			palette.push(`\n2d6+${v[1]}+{魔法行使} ${v[2]}行使判定`);
			for(let i = 0; i < 6; i++) {
				palette.push(`k${i*10}+${v[1]}+0@(10-0) ${v[2]}ダメージ (威力 ${i*10})`);
			}
		});
		palette.push(`2d6+${json.defenseTotalAllEva || '0'}+0 回避判定`);
		palette.push(`2d6+${json.vitResistTotal || '0'}+0 生命抵抗判定`);
		palette.push(`2d6+${json.mndResistTotal || '0'}+0 精神抵抗判定`);
	
		skills.forEach((s)=>{
			['器用度B', '敏捷度B', '知力B'].forEach((v)=>{
				palette.push(`2d6+{${s.label}}+{${v}} ${s.label}+${v}`);
			});
		});
		if(json.chatPalette) {
			palette.push(json.chatPalette.replace(/&lt;br&gt;/gm, '\n'));
		}
		character.commands = palette.join('\n');
	}

	result.entities.characters[json.id] = character;
	return JSON.stringify(result);
};

io.github.shunshun94.trpg.ccfolia.getPartsFromYtSheetEnemyWithPartsNum = (json, opt_num = '') => {
	const result = {
			status: [],
			commands: ''
	};
	const name = opt_num ? (json[`status${opt_num}Style`] || `? (${opt_num})`) : '';	
	result.status.push({
		label: `${name}HP`,
		value: Number(json[`status${opt_num || '1'}Hp`]) || 0,
		max: Number(json[`status${opt_num || '1'}Hp`]) || 0
	});

	result.status.push({
		label: `${name}MP`,
		value: Number(json[`status${opt_num || '1'}Mp`]) || 0,
		max: Number(json[`status${opt_num || '1'}Mp`]) || 0
	});

	result.commands = [
		{name:'命中判定', column:`status${opt_num || '1'}Accuracy`},
		{name:'回避判定', column:`status${opt_num || '1'}Evasion`}
	].filter((d)=>{
		return Number(json[d.column])
	}).map((d)=>{
		return `2d6+${json[d.column]}+0 ${name} ${d.name}`;
	}).join('\n');
	result.commands += `\n${json[`status${opt_num || '1'}Damage`] || '0'} ${name} ダメージ`;
	return result;
};

io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2SwordWorldEnemies = async (count, json, opt_sheetUrl = '', opt_defaultPictureUrl = io.github.shunshun94.trpg.ccfolia.CONSTS.DEFAULT_ENEMY_PICTURE) => {
	if(count > 26) {
		throw "26体までしか一度に生成できません";
	}
	if(count > 1){
		const result = io.github.shunshun94.trpg.ccfolia.getCharacterSeed();
		const singleJsonString = await io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2SwordWorldEnemy(json, opt_sheetUrl, opt_defaultPictureUrl);
		const characterDataJsonString = JSON.stringify(JSON.parse(singleJsonString).entities.characters[json.id]);
		for(var i = 0; i < count; i++) {
			const suffix = String.fromCharCode(65 + i);
			const character = JSON.parse(characterDataJsonString);
			character.name = `${character.name} ${suffix}`;
			result.entities.characters[`${json.id}_${suffix}`] = character;
		}
		return JSON.stringify(result);
	} else { 
		return io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2SwordWorldEnemy(json, opt_sheetUrl, opt_defaultPictureUrl);
	}
};

io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2SwordWorldEnemy = async (json, opt_sheetUrl = '', opt_defaultPictureUrl = io.github.shunshun94.trpg.ccfolia.CONSTS.DEFAULT_ENEMY_PICTURE) => {
	const result = io.github.shunshun94.trpg.ccfolia.getCharacterSeed();
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_sheetUrl);
	const character = {
			name: json.characterName || json.monsterName,
			playerName: 'GM',
			memo: '',
			initiative: '0',
			externalUrl: opt_sheetUrl,
			status: [],
			params: defaultPalette.parameters || [],
			iconUrl: json.imageURL || opt_defaultPictureUrl,
			faces: [],
			x: 0, y: 0, z: 0,
			angle: 0, width: 4, height: 4,
			active: true, secret: false,
			invisible: false, hideStatus: false,
			color: '',
			roomId: null,
			commands: defaultPalette.palette || '',
			speaking: true
	};
	const partsLenght = Number(json.statusNum);
	character.commands += (defaultPalette === '') ? `2d6+${json.vitResist || '0'}+0 生命抵抗\n2d6+${json.mndResist || '0'}+0 精神抵抗\n` : '';
	if(partsLenght === 1) {
		const partsInfo = io.github.shunshun94.trpg.ccfolia.getPartsFromYtSheetEnemyWithPartsNum(json);
		character.status = character.status.concat(partsInfo.status);
		character.commands += (defaultPalette === '') ? partsInfo.commands + '\n' : '';
	} else {
		for(let i = 0; i < partsLenght; i++) {
			const partsInfo = io.github.shunshun94.trpg.ccfolia.getPartsFromYtSheetEnemyWithPartsNum(json, i + 1);
			character.status = character.status.concat(partsInfo.status);
			character.commands += (defaultPalette === '') ? partsInfo.commands + '\n' : '';
		}
	}
	if(json.chatPalette) {
		character.commands += (defaultPalette === '') ? json.chatPalette.replace(/&lt;br&gt;/gm, '\n') : '';
	}
	result.entities.characters[json.id] = character;
	return JSON.stringify(result);
};

