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

io.github.shunshun94.trpg.ccfolia.getCharacterSeed = ()=>{
	return { kind: "character" };
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

io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2SwordWorld2PC = async (json, opt_sheetUrl = '') => {
	const result = io.github.shunshun94.trpg.ccfolia.getCharacterSeed();
	const skills = io.github.shunshun94.trpg.ccfolia.getPcSkillList(json);
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_sheetUrl);
	const character = {
			name: json.characterName,
			playerName: json.playerName,
			memo: `PL: ${json.playerName || 'PL情報無し'}\n${json.race || '種族不明'}\n\n${json.imageURL ? '立ち絵：' + (json.imageCopyright || '権利情報なし') : ''}`,
			initiative: 2,
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

	result.data = character;
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

io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2SwordWorld2Enemy = async (json, opt_sheetUrl = '') => {
	const result = io.github.shunshun94.trpg.ccfolia.getCharacterSeed();
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_sheetUrl);
	const character = {
			name: json.characterName || json.monsterName,
			playerName: 'GM',
			memo: '',
			initiative: 0,
			externalUrl: opt_sheetUrl,
			status: [],
			params: defaultPalette.parameters || [],
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
	if(partsLenght === 1) {
		const partsInfo = io.github.shunshun94.trpg.ccfolia.getPartsFromYtSheetEnemyWithPartsNum(json);
		character.status = character.status.concat(partsInfo.status);
	} else {
		for(let i = 0; i < partsLenght; i++) {
			const partsInfo = io.github.shunshun94.trpg.ccfolia.getPartsFromYtSheetEnemyWithPartsNum(json, i + 1);
			character.status = character.status.concat(partsInfo.status);
		}
	}
	result.data = character;
	return JSON.stringify(result);
};

