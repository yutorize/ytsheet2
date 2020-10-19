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
io.github.shunshun94.trpg.ccfolia = io.github.shunshun94.trpg.ccfolia || {};

io.github.shunshun94.trpg.ccfolia.CONSTS = {};
io.github.shunshun94.trpg.ccfolia.CONSTS.DEFAULT_PICTURE = 'https://shunshun94.github.io/shared/hiyoko.jpg';

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

var randomString = '';
var baseString ='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
for(var i=0; i<length; i++) {
	randomString += baseString.charAt( Math.floor( Math.random() * baseString.length));
}

io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2SwordWorldPC = (json, opt_sheetUrl = '', opt_defaultPictureUrl = io.github.shunshun94.trpg.ccfolia.CONSTS.DEFAULT_PICTURE) => {
	const result = io.github.shunshun94.trpg.ccfolia.getCharacterSeed();
	const character = {
			name: json.characterName,
			playerName: json.playerName,
			memo: `PL: ${json.playerName}\n${json.race}\n\n${json.imageURL ? '立ち絵：' + json.imageCopyright : ''}`,
			initiative: '2',
			externalurl: opt_sheetUrl,
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
			params: [
				{label:'器用度B', value:json.bonusDex},
				{label:'敏捷度B', value:json.bonusAgi},
				{label:'筋力B',value:json.bonusStr},
				{label:'生命力B',value:json.bonusVit},
				{label:'知力B', value:json.bonusInt},
				{label:'精神力B', value:json.bonusMnd}
			],
			iconUrl: json.imageURL || opt_defaultPictureUrl,
			faces: [],
			x: 0, y: 0, z: 0,
			angle: 0, width: 4, height: 4,
			active: true, secret: false,
			invisible: false, hideStatus: false,
			color: '',
			roomId: null,
			commands: '',
			speaking: true
	};
	const skills = [
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
	character.params = character.params.concat(skills);
	
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
		palette.push(`2d6+${json['weapon' + (i + 1) + 'AccTotal']}+0 命中判定 (${json['weapon' + (i + 1) + 'Name']})`);
		palette.push(`k${json['weapon' + (i + 1) + 'Rate']}+${json['weapon' + (i + 1) + 'DmgTotal']}+0@(${json['weapon' + (i + 1) + 'Crit']}-0)$+0   ダメージ判定 (${json['weapon' + (i + 1) + 'Name']})`);
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
	palette.push(`2d6+${json.defenseTotalAllEva}+0 回避判定`);
	palette.push(`2d6+${json.vitResistTotal}+0 生命抵抗判定`);
	palette.push(`2d6+${json.mndResistTotal}+0 精神抵抗判定`);

	skills.forEach((s)=>{
		['器用度B', '敏捷度B', '知力B'].forEach((v)=>{
			palette.push(`2d6+{${s.label}}+{${v}} ${s.label}+${v}`);
		});
	});
	if(json.chatPalette) {
		palette.push(json.chatPalette.replace(/&lt;br&gt;/gm, '\n'));
	}
	character.commands = palette.join('\n');
	result.entities.characters[json.id] = character;
	return JSON.stringify(result);
};
