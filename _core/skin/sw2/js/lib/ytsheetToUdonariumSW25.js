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
io.github.shunshun94.trpg.udonarium = io.github.shunshun94.trpg.udonarium || {};

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2SwordWorld2Enemy = async (json, opt_url='', opt_imageHash='')=>{
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_url);
	const data_character = {};
	data_character.image = `
    <data name="image">
      <data type="image" name="imageIdentifier">${opt_imageHash}</data>
    </data>`;

	data_character.common = `
    <data name="common">
      <data name="name">${json.monsterName}</data>
      <data name="size">1</data>
    </data>`;
	data_character_detail = {};
	const statusLenght = Number(json.statusNum);
	data_character_detail['リソース'] = [];
	if(statusLenght.length === 1) {
		data_character_detail['リソース'].push(
			`        <data type="numberResource" currentValue="${json.status1Hp || '0'}" name="HP">${json.status1Hp || '0'}</data>`,
			`        <data type="numberResource" currentValue="${json.status1Mp || '0'}" name="MP">${json.status1Mp || '0'}</data>`
		);
	} else {
		for(let i = 0; i < statusLenght; i++) {
			const cursor = i + 1;
			data_character_detail['リソース'].push(
					`        <data type="numberResource" currentValue="${json['status' + cursor + 'Hp'] || '0'}" name="HP${cursor}">${json['status' + cursor + 'Hp'] || '0'}</data>`,
					`        <data type="numberResource" currentValue="${json['status' + cursor + 'Mp'] || '0'}" name="MP${cursor}">${json['status' + cursor + 'Mp'] || '0'}</data>`
			);
		}
	}
	if(defaultPalette === '') {
		data_character_detail['能力値'] = [];
		if(statusLenght.length === 1) {
			data_character_detail['能力値'].push(
				`        <data currentValue="${json.status1Accuracy || '0'}" name="命中">${json.status1Accuracy || '0'}</data>`,
				`        <data currentValue="${json.status1Damag || '0'}" name="打撃点">${json.status1Damage || '0'}</data>`,
				`        <data currentValue="${json.status1Evasion || '0'}" name="回避力">${json.status1Evasion || '0'}</data>`,
				`        <data type="numberResource" currentValue="${json.status1Defense || '0'}" name="防護点">${json.status1Defense || '0'}</data>`
			);
		} else {
			for(let i = 0; i < statusLenght; i++) {
				const cursor = i + 1;
				data_character_detail['能力値'].push(
						`        <data currentValue="${json['status' + cursor + 'Accuracy'] || '0'}" name="命中${cursor}">${json['status' + cursor + 'Accuracy'] || '0'}</data>`,
						`        <data currentValue="${json['status' + cursor + 'Damage'] || '0'}" name="打撃点${cursor}">${json['status' + cursor + 'Damage'] || '0'}</data>`,
						`        <data currentValue="${json['status' + cursor + 'Evasion'] || '0'}" name="回避力${cursor}">${json['status' + cursor + 'Evasion'] || '0'}</data>`,
						`        <data type="numberResource" currentValue="${json['status' + cursor + 'Defense'] || '0'}" name="防護点${cursor}">${json['status' + cursor + 'Defense'] || '0'}</data>`,
				);
			}
		}
		data_character_detail['能力値'].push(`        <data type="numberResource" currentValue="${json.sin || 0}" name="穢れ度">5</data>`);
	}
	if(defaultPalette && defaultPalette.parameters.length) {
		data_character_detail['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
			return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
		});
	}
	
	if(opt_url) { data_character_detail['情報'] = [`        <data name="URL">${opt_url}</data>`];}
	data_character.detail = `  <data name="detail">\n`;
	for(const key in data_character_detail) {
		data_character.detail += `      <data name="${key}">\n`;
		data_character.detail += data_character_detail[key].join(('\n'));
		data_character.detail += `\n      </data>\n`;
	}
	data_character.detail += `    </data>`;

	let palette = `<chat-palette dicebot="SwordWorld2_5">\n`;
	if(defaultPalette) {
		palette += defaultPalette.palette.replace('<','&lt;').replace('>','&gt;');
	} else {
		const palette_detail = {};
		palette_detail['情報共有'] = '';
		palette_detail['戦闘'] = '';
		if(statusLenght.length === 1) {
			palette_detail['情報共有'] += `現在の状態　HP:{HP} / MP:{MP}\n`;
			palette_detail['戦闘'] += `2d6+{命中} 命中判定\n`;
			palette_detail['戦闘'] += `{打撃点} 打撃ダメージ\n`;
			palette_detail['戦闘'] += `2d6+{回避力} 回避\n`;
		} else {
			palette_detail['情報共有'] += `現在の状態 | `;
			for(let i = 0; i < statusLenght; i++) {
				const cursor = i + 1;
				palette_detail['情報共有'] += `${json['status' + cursor + 'Style'] || ''}: HP:{HP${cursor}} / MP:{MP${cursor}} | `;
				palette_detail['戦闘'] += `2d6+{命中${cursor}} ${json['status' + cursor + 'Style'] || ''} 命中判定\n`;
				palette_detail['戦闘'] += `{打撃点${cursor}} ${json['status' + cursor + 'Style'] || ''} 打撃ダメージ\n`;
				palette_detail['戦闘'] += `2d6+{回避力${cursor}} ${json['status' + cursor + 'Style'] || ''} 回避\n`;
			}
		}
		palette_detail['戦闘'] += `2d6+${json.vitResist || '0'} 生命抵抗\n`;
		palette_detail['戦闘'] += `2d6+${json.mndResist || '0'} 精神抵抗\n`;
		if(opt_url) { palette_detail['情報共有'] += `\nキャラクターシート　{URL}\n`;}
	
		for(const key in palette_detail) {
			palette += `// ${key}\n${palette_detail[key]}\n`;
		}
		if(json.chatPalette) {
			palette += json.chatPalette.replace(/&lt;br&gt;/gm, '\n');
		}	
	}
	palette += `  </chat-palette>`;

	return `<?xml version="1.0" encoding="UTF-8"?>
<character location.name="table" location.x="0" location.y="0" posZ="0" rotate="0" roll="0">
  <data name="character">
  ${data_character.image}
  ${data_character.common}
  ${data_character.detail}
  </data>
  ${palette}
</character>
`;
};

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2SwordWorld2PC = async (json, opt_url='', opt_imageHash='')=>{
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_url);
	const data_character = {};

	data_character.image = `
    <data name="image">
      <data type="image" name="imageIdentifier">${opt_imageHash}</data>
    </data>`;

	data_character.common = `
    <data name="common">
      <data name="name">${json.characterName || json.aka}</data>
      <data name="size">1</data>
    </data>`;

	data_character_detail = {};
	data_character_detail['リソース'] = [
		`        <data type="numberResource" currentValue="${json.hpTotal}" name="HP">${json.hpTotal}</data>`,
		`        <data type="numberResource" currentValue="${json.mpTotal}" name="MP">${json.mpTotal}</data>`,
        `        <data type="numberResource" currentValue="${json.defenseTotalAllDef || '0'}" name="防護点">${json.defenseTotalAllDef || 0}</data>`,
        `        <data type="numberResource" currentValue="0" name="1ゾロ">10</data>`,
        `        <data type="numberResource" currentValue="${json.sin || 0}" name="穢れ度">5</data>`,
        `        <data name="所持金">${json.moneyTotal}</data>`,
        `        <data name="残名誉点">${json.honor}</data>`
	];
	data_character_detail['情報'] = [
        `        <data name="PL">${json.playerName || '?'}</data>`,
        `        <data name="種族">${json.race || '?'}</data>`,
        `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
	];
	if(opt_url) { data_character_detail['情報'].push(`        <data name="URL">${opt_url}</data>`);}

	const addToStr = (val)=>{
		if(val) {
			if(Number(val) < 0) {
				return `${val}`;
			} else {
				return `+${val}`;
			}
		} else {
			return '';
		}
	};
	const skills = [
		{level:json.level, name:'冒険者レベル'},
		{level:json.lvFig, name:'ファイター'},
		{level:json.lvGra, name:'グラップラー'},
		{level:json.lvFen, name:'フェンサー'},
		{level:json.lvSho, name:'シューター'},
		{level:json.lvSor, name:'ソーサラー'},
		{level:json.lvCon, name:'コンジャラー'},
		{level:json.lvPri, name:'プリースト'},
		{level:json.lvFai, name:'フェアリーテイマー'},
		{level:json.lvMag, name:'マギテック'},
		{level:json.lvSco, name:'スカウト'},
		{level:json.lvRan, name:'レンジャー'},
		{level:json.lvSag, name:'セージ'},
		{level:json.lvEnh, name:'エンハンサー'},
		{level:json.lvBar, name:'バード'},
		{level:json.lvRid, name:'ライダー'},
		{level:json.lvAlc, name:'アルケミスト'},
		{level:json.lvWar, name:'ウォーリーダー'},
		{level:json.lvMys, name:'ミスティック'},
		{level:json.lvDem, name:'デーモンルーラー'},
		{level:json.lvDru, name:'ドルイド'},
		{level:json.lvPhy, name:'フィジカルマスター'},
		{level:json.lvGri, name:'グリモワール'},
		{level:json.lvAri, name:'アリストクラシー'},
		{level:json.lvArt, name:'アーティザン'}].filter((d)=>{return d.level});
	if(defaultPalette) {
		data_character_detail['能力値'] = [
	        `        <data name="器用度">${json.sttDex}${addToStr(json.sttAddA)}</data>`,
	        `        <data name="敏捷度">${json.sttAgi}${addToStr(json.sttAddB)}</data>`,
	        `        <data name="筋力">${json.sttStr}${addToStr(json.sttAddC)}</data>`,
	        `        <data name="生命力">${json.sttVit}${addToStr(json.sttAddD)}</data>`,
	        `        <data name="知力">${json.sttInt}${addToStr(json.sttAddE)}</data>`,
	        `        <data name="精神力">${json.sttMnd}${addToStr(json.sttAddF)}</data>`
		];
		data_character_detail['技能'] = skills.map((s)=>{
			return `<data name="${s.name}">${s.level}</data>`
		});
		data_character_detail['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
			for (const s of skills){
				if(s.name === param.label){ return `` }
			}
			if(param.label.match(/^(器用度|敏捷度|筋力|生命力|知力|精神力)$/)){ return `` }
			return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
		});
	} else {
		data_character_detail['能力値'] = [
	        `        <data name="器用度">${json.sttDex}${addToStr(json.sttAddA)}</data>`,
	        `        <data name="敏捷度">${json.sttAgi}${addToStr(json.sttAddB)}</data>`,
	        `        <data name="筋力">${json.sttStr}${addToStr(json.sttAddC)}</data>`,
	        `        <data name="生命力">${json.sttVit}${addToStr(json.sttAddD)}</data>`,
	        `        <data name="知力">${json.sttInt}${addToStr(json.sttAddE)}</data>`,
	        `        <data name="精神力">${json.sttMnd}${addToStr(json.sttAddF)}</data>`
		];
		data_character_detail['能力値ボーナス'] = [
	        `        <data name="器用度B">${json.bonusDex}</data>`,
	        `        <data name="敏捷度B">${json.bonusAgi}</data>`,
	        `        <data name="筋力B">${json.bonusStr}</data>`,
	        `        <data name="生命力B">${json.bonusVit}</data>`,
	        `        <data name="知力B">${json.bonusInt}</data>`,
	        `        <data name="精神力B">${json.bonusMnd}</data>`
		];
		data_character_detail['技能'] = skills.map((s)=>{
			return `<data name="${s.name}">${s.level}</data>`
		});
		data_character_detail['バフ・デバフ'] = [
			`        <data type="numberResource" currentValue="0" name="命中">10</data>`,
			`        <data type="numberResource" currentValue="0" name="回避">10</data>`,
			`        <data type="numberResource" currentValue="0" name="攻撃">20</data>`,
			`        <data type="numberResource" currentValue="0" name="クリレイ">10</data>`,
			`        <data type="numberResource" currentValue="0" name="ダメージ出目上昇">10</data>`,
			`        <data type="numberResource" currentValue="0" name="クリティカル値減少">10</data>`,
			`        <data type="numberResource" currentValue="0" name="魔法行使">10</data>`,
			`        <data type="numberResource" currentValue="0" name="魔法ダメージ">10</data>`,
			`        <data type="numberResource" currentValue="0" name="生命抵抗">10</data>`,
			`        <data type="numberResource" currentValue="0" name="精神抵抗">10</data>`,
			`        <data type="numberResource" currentValue="0" name="ダメージ軽減">20</data>`
		];
	}

	data_character.detail = `  <data name="detail">\n`;
	for(const key in data_character_detail) {
		data_character.detail += `      <data name="${key}">\n`;
		data_character.detail += data_character_detail[key].join(('\n'));
		data_character.detail += `\n      </data>\n`;
	}
	data_character.detail += `    </data>`;

	let palette = `<chat-palette dicebot="SwordWorld2_5">\n`;
	if(defaultPalette) {
		palette += defaultPalette.palette.replace('<','&lt;').replace('>','&gt;');
	} else {
		const palette_detail = {};
		palette_detail['情報共有'] = `現在の状態　HP:{HP} / MP:{MP}\n`;
		if(opt_url) { palette_detail['情報共有'] += `キャラクターシート　{URL}\n`;}
		palette_detail['戦闘前'] = ``;
		if(json.lvSco) {
			palette_detail['戦闘前'] += `2d6+{スカウト}+{敏捷度B} 先制判定 (スカウト)\n`;
		}
		if(json.lvWar) {
			palette_detail['戦闘前'] += `2d6+{ウォーリーダー}+{敏捷度B} 先制判定 (ウォーリーダー・敏捷)\n`;
			palette_detail['戦闘前'] += `2d6+{ウォーリーダー}+{知力B} 先制判定 (ウォーリーダー・知力)\n`;
		}
		if(json.lvSag) {
			palette_detail['戦闘前'] += `2d6+{セージ}+{知力B} 魔物知識判定（セージ）\n`;
		}
		if(json.lvRid) {
			palette_detail['戦闘前'] += `2d6+{ライダー}+{知力B} 魔物知識判定（ライダー）\n`;
		}
	
		palette_detail['戦闘中'] = ``;
		const weaponLength = Number(json.weaponNum);
		for(let i = 0; i < weaponLength; i++) {
			if(json['weapon' + (i + 1) + 'Name']) {
				palette_detail['戦闘中'] += `2d6+${json['weapon' + (i + 1) + 'AccTotal'] || '0'}+{命中} 命中判定 (${json['weapon' + (i + 1) + 'Name']})\n`;
				palette_detail['戦闘中'] += `k${json['weapon' + (i + 1) + 'Rate'] || '0'}+${json['weapon' + (i + 1) + 'DmgTotal'] || '0'}+{攻撃}@(${json['weapon' + (i + 1) + 'Crit'] || '10'}-{クリティカル値減少})$+{クリレイ}   ダメージ判定 (${json['weapon' + (i + 1) + 'Name']})\n`;				
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
			palette_detail['戦闘中'] += `\n2d6+${v[1]}+{魔法行使} ${v[2]}行使判定\n`;
			for(let i = 0; i < 6; i++) {
				palette_detail['戦闘中'] += `k${i*10}+${v[1]}+{魔法ダメージ}@(10-{クリティカル値減少}) ${v[2]}ダメージ (威力 ${i*10})\n`;
			}
		});
		palette_detail['戦闘中'] += `2d6+${json.defenseTotalAllEva || '0'}+{回避} 回避判定\n`;
		palette_detail['戦闘中'] += `2d6+${json.vitResistTotal}+{生命抵抗} 生命抵抗判定\n`;
		palette_detail['戦闘中'] += `2d6+${json.mndResistTotal}+{精神抵抗} 精神抵抗判定\n`;
	
		palette_detail['探索中'] = skills.map((s)=>{
			return ['器用度B', '敏捷度B', '知力B'].map((v)=>{
				return `2d6+{${s.name}}+{${v}} ${s.name}+${v}`
			}).join('\n')
		}).join('\n')
	
		for(const key in palette_detail) {
			palette += `// ${key}\n${palette_detail[key]}\n`;
		}
		if(json.chatPalette) {
			palette += json.chatPalette.replace(/&lt;br&gt;/gm, '\n');
		}
	}
	palette += `  </chat-palette>`;
	return `<?xml version="1.0" encoding="UTF-8"?>
<character location.name="table" location.x="0" location.y="0" posZ="0" rotate="0" roll="0">
  <data name="character">
  ${data_character.image}
  ${data_character.common}
  ${data_character.detail}
  </data>
  ${palette}
</character>
`;
};