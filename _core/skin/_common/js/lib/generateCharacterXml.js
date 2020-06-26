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
io.github.shunshun94.trpg.udonarium = io.github.shunshun94.trpg.udonarium || {};

io.github.shunshun94.trpg.udonarium.getPicture = (src) => {
	return new Promise((resolve, reject) => {
		let xhr = new XMLHttpRequest();
		xhr.open('GET', src, true);
		xhr.responseType = "blob";
		xhr.onload = (e) => {
			const fileName = src.slice(src.lastIndexOf("/") + 1);
			if(! Boolean(jsSHA)) {
				console.warn('To calculate SHA256 value of the picture, jsSHA is required: https://github.com/Caligatio/jsSHA');
				resolve({ event:e, data: e.currentTarget.response, fileName: fileName, hash: '' });
				return;
			}
			e.currentTarget.response.arrayBuffer().then((arraybuffer)=>{
				const sha = new jsSHA("SHA-256", 'ARRAYBUFFER');
				sha.update(arraybuffer);
				const hash = sha.getHash("HEX");
				resolve({ event:e, data: e.currentTarget.response, fileName: fileName, hash: hash });
				return;
			});
		};
		xhr.onerror = () => resolve({ data: null });
		xhr.onabort = () => resolve({ data: null });
		xhr.ontimeout = () => resolve({ data: null });
		xhr.send();
	});
};

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2SwordWorldEnemy = (json, opt_url='')=>{
	const data_character = {};
	data_character.image = `
    <data name="image">
      <data type="image" name="imageIdentifier"></data>
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
			`        <data type="numberResource" currentValue="${json.status1Hp}" name="HP">${json.status1Hp}</data>`,
			`        <data type="numberResource" currentValue="${json.status1Mp}" name="MP">${json.status1Mp}</data>`
		);
	} else {
		for(let i = 0; i < statusLenght; i++) {
			const cursor = i + 1;
			data_character_detail['リソース'].push(
					`        <data type="numberResource" currentValue="${json['status' + cursor + 'Hp']}" name="HP${cursor}">${json['status' + cursor + 'Hp']}</data>`,
					`        <data type="numberResource" currentValue="${json['status' + cursor + 'Mp']}" name="MP${cursor}">${json['status' + cursor + 'Mp']}</data>`
			);
		}
	}
	data_character_detail['能力値'] = [];
	if(statusLenght.length === 1) {
		data_character_detail['能力値'].push(
			`        <data currentValue="${json.status1Accuracy}" name="命中">${json.status1Accuracy}</data>`,
			`        <data currentValue="${json.status1Damage}" name="打撃点">${json.status1Damage}</data>`,
			`        <data currentValue="${json.status1Evasion}" name="回避力">${json.status1Evasion}</data>`,
			`        <data type="numberResource" currentValue="${json.status1Defense}" name="防護点">${json.status1Defense}</data>`
		);
	} else {
		for(let i = 0; i < statusLenght; i++) {
			const cursor = i + 1;
			data_character_detail['能力値'].push(
					`        <data currentValue="${json['status' + cursor + 'Accuracy']}" name="命中${cursor}">${json['status' + cursor + 'Accuracy']}</data>`,
					`        <data currentValue="${json['status' + cursor + 'Damage']}" name="打撃点${cursor}">${json['status' + cursor + 'Damage']}</data>`,
					`        <data currentValue="${json['status' + cursor + 'Evasion']}" name="回避力${cursor}">${json['status' + cursor + 'Evasion']}</data>`,
					`        <data type="numberResource" currentValue="${json['status' + cursor + 'Defense']}" name="防護点${cursor}">${json['status' + cursor + 'Defense']}</data>`,
			);
		}
	}
	data_character_detail['能力値'].push(`        <data type="numberResource" currentValue="${json.sin || 0}" name="穢れ度">5</data>`);
	if(opt_url) { data_character_detail['情報'] = [`        <data name="URL">${opt_url}</data>`];}
	data_character.detail = `  <data name="detail">\n`;
	for(const key in data_character_detail) {
		data_character.detail += `      <data name="${key}">\n`;
		data_character.detail += data_character_detail[key].join(('\n'));
		data_character.detail += `\n      </data>\n`;
	}
	data_character.detail += `    </data>`;
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
			palette_detail['情報共有'] += `${json['status' + cursor + 'Style']}: HP:{HP${cursor}} / MP:{MP${cursor}} | `;
			palette_detail['戦闘'] += `2d6+{命中${cursor}} ${json['status' + cursor + 'Style']} 命中判定\n`;
			palette_detail['戦闘'] += `{打撃点${cursor}} ${json['status' + cursor + 'Style']} 打撃ダメージ\n`;
			palette_detail['戦闘'] += `2d6+{回避力${cursor}} ${json['status' + cursor + 'Style']} 回避\n`;
		}
	}
	palette_detail['戦闘'] += `2d6+${json.vitResist} 生命抵抗\n`;
	palette_detail['戦闘'] += `2d6+${json.mndResist} 精神抵抗\n`;
	if(opt_url) { palette_detail['情報共有'] += `\nキャラクターシート　{URL}\n`;}

	let palette = `<chat-palette dicebot="SwordWorld2_5">\n`;
	for(const key in palette_detail) {
		palette += `// ${key}\n${palette_detail[key]}\n`;
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

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2SwordWorldPC = (json, opt_url='', opt_imageHash='')=>{
	const data_character = {};

	data_character.image = `
    <data name="image">
      <data type="image" name="imageIdentifier">${opt_imageHash}</data>
    </data>`;

	data_character.common = `
    <data name="common">
      <data name="name">${json.characterName}</data>
      <data name="size">1</data>
    </data>`;

	data_character_detail = {};
	data_character_detail['リソース'] = [
		`        <data type="numberResource" currentValue="${json.hpTotal}" name="HP">${json.hpTotal}</data>`,
		`        <data type="numberResource" currentValue="${json.mpTotal}" name="MP">${json.mpTotal}</data>`,
        `        <data type="numberResource" currentValue="${json.defenseTotalAllDef}" name="防護点">${json.defenseTotalAllDef}</data>`,
        `        <data type="numberResource" currentValue="0" name="1ゾロ">10</data>`,
        `        <data type="numberResource" currentValue="${json.sin || 0}" name="穢れ度">5</data>`,
        `        <data name="所持金">${json.moneyTotal}</data>`,
        `        <data name="残名誉点">${json.honor}</data>`
	];
	data_character_detail['情報'] = [
        `        <data name="PL">${json.playerName}</data>`,
        `        <data name="種族">${json.race}</data>`,
        `        <data type="note" name="説明">${json.freeNote.replace(/&lt;br&gt;/g, '\n')}</data>`
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
	data_character_detail['能力値'] = [
        `        <data name="器用度">${json.sttDex}${addToStr(json.sttAddA)}</data>`,
        `        <data name="敏捷度">${json.sttAgi}${addToStr(json.sttAddB)}</data>`,
        `        <data name="筋力">${json.sttStr}${addToStr(json.sttAddC)}</data>`,
        `        <data name="生命力">${json.sttVit}${addToStr(json.sttAddD)}</data>`,
        `        <data name="知力">${json.sttInt}${addToStr(json.sttAddE)}</data>`,
        `        <data name="精神力">${json.sttMnd}${addToStr(json.sttAddF)}</data>`
	];

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
		{level:json.lvPhy, name:'フィジカルマスター'},
		{level:json.lvGri, name:'グリモワール'},
		{level:json.lvAri, name:'アリストクラシー'},
		{level:json.lvArt, name:'アーティザン'}].filter((d)=>{return d.level});
	data_character_detail['技能'] = [
		`        ${json.level ? '' : '<!--'}<data name="冒険者レベル">${json.level}</data>${json.level ? '' : '-->'}`,
		`        ${json.lvFig ? '' : '<!--'}<data name="ファイター">${json.lvFig}</data>${json.lvFig ? '' : '-->'}`,
		`        ${json.lvGra ? '' : '<!--'}<data name="グラップラー">${json.lvGra}</data>${json.lvGra ? '' : '-->'}`,
		`        ${json.lvFen ? '' : '<!--'}<data name="フェンサー">${json.lvFen}</data>${json.lvFen ? '' : '-->'}`,
		`        ${json.lvSho ? '' : '<!--'}<data name="シューター">${json.lvSho}</data>${json.lvSho ? '' : '-->'}`,
		`        ${json.lvSor ? '' : '<!--'}<data name="ソーサラー">${json.lvSor}</data>${json.lvSor ? '' : '-->'}`,
		`        ${json.lvCon ? '' : '<!--'}<data name="コンジャラー">${json.lvCon}</data>${json.lvCon ? '' : '-->'}`,
		`        ${json.lvPri ? '' : '<!--'}<data name="プリースト">${json.lvPri}</data>${json.lvPri ? '' : '-->'}`,
		`        ${json.lvFai ? '' : '<!--'}<data name="フェアリーテイマー">${json.lvFai}</data>${json.lvFai ? '' : '-->'}`,
		`        ${json.lvMag ? '' : '<!--'}<data name="マギテック">${json.lvMag}</data>${json.lvMag ? '' : '-->'}`,
		`        ${json.lvSco ? '' : '<!--'}<data name="スカウト">${json.lvSco}</data>${json.lvSco ? '' : '-->'}`,
		`        ${json.lvRan ? '' : '<!--'}<data name="レンジャー">${json.lvRan}</data>${json.lvRan ? '' : '-->'}`,
		`        ${json.lvSag ? '' : '<!--'}<data name="セージ">${json.lvSag}</data>${json.lvSag ? '' : '-->'}`,
		`        ${json.lvEnh ? '' : '<!--'}<data name="エンハンサー">${json.lvEnh}</data>${json.lvEnh ? '' : '-->'}`,
		`        ${json.lvBar ? '' : '<!--'}<data name="バード">${json.lvBar}</data>${json.lvBar ? '' : '-->'}`,
		`        ${json.lvRid ? '' : '<!--'}<data name="ライダー">${json.lvRid}</data>${json.lvRid ? '' : '-->'}`,
		`        ${json.lvAlc ? '' : '<!--'}<data name="アルケミスト">${json.lvAlc}</data>${json.lvAlc ? '' : '-->'}`,
		`        ${json.lvWar ? '' : '<!--'}<data name="ウォーリーダー">${json.lvWar}</data>${json.lvWar ? '' : '-->'}`,
		`        ${json.lvMys ? '' : '<!--'}<data name="ミスティック">${json.lvMys}</data>${json.lvMys ? '' : '-->'}`,
		`        ${json.lvDem ? '' : '<!--'}<data name="デーモンルーラー">${json.lvDem}</data>${json.lvDem ? '' : '-->'}`,
		`        ${json.lvPhy ? '' : '<!--'}<data name="フィジカルマスター">${json.lvPhy}</data>${json.lvPhy ? '' : '-->'}`,
		`        ${json.lvGri ? '' : '<!--'}<data name="グリモワール">${json.lvGri}</data>${json.lvGri ? '' : '-->'}`,
		`        ${json.lvAri ? '' : '<!--'}<data name="アリストクラシー">${json.lvAri}</data>${json.lvAri ? '' : '-->'}`,
		`        ${json.lvArt ? '' : '<!--'}<data name="アーティザン">${json.lvArt}</data>${json.lvArt ? '' : '-->'}`
	];
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

	data_character.detail = `  <data name="detail">\n`;
	for(const key in data_character_detail) {
		data_character.detail += `      <data name="${key}">\n`;
		data_character.detail += data_character_detail[key].join(('\n'));
		data_character.detail += `\n      </data>\n`;
	}
	data_character.detail += `    </data>`;
	const palette_detail = {};
	palette_detail['情報共有'] = `現在の状態　HP:{HP} / MP:{MP}\n`;
	if(opt_url) { palette_detail['情報共有'] += `キャラクターシート　{URL}\n`;}
	palette_detail['戦闘前'] = ``;
	if(json.lvSco) {
		palette_detail['戦闘前'] += `2d6+{スカウト}+(({敏捷度})/6) 先制判定 (スカウト)\n`;
	}
	if(json.lvWar) {
		palette_detail['戦闘前'] += `2d6+{ウォーリーダー}+(({敏捷度})/6) 先制判定 (ウォーリーダー・敏捷)\n`;
		palette_detail['戦闘前'] += `2d6+{ウォーリーダー}+(({知力})/6) 先制判定 (ウォーリーダー・知力)\n`;
	}
	if(json.lvSag) {
		palette_detail['戦闘前'] += `2d6+{セージ}+(({知力})/6) 魔物知識判定（セージ）\n`;
	}
	if(json.lvRid) {
		palette_detail['戦闘前'] += `2d6+{ライダー}+(({知力})/6) 魔物知識判定（ライダー）\n`;
	}

	palette_detail['戦闘中'] = ``;
	const weaponLength = Number(json.weaponNum);
	for(let i = 0; i < weaponLength; i++) {
		palette_detail['戦闘中'] += `2d6+${json['weapon' + (i + 1) + 'AccTotal']}+{命中} 命中判定 (${json['weapon' + (i + 1) + 'Name']})\n`;
		palette_detail['戦闘中'] += `k${json['weapon' + (i + 1) + 'Rate']}+${json['weapon' + (i + 1) + 'DmgTotal']}+{攻撃}@(${json['weapon' + (i + 1) + 'Crit']}-{クリティカル値減少})$+{クリレイ}   ダメージ判定 (${json['weapon' + (i + 1) + 'Name']})\n`;
	}
	[[json.lvSor, json.magicPowerSor, '真語魔法'],
	 [json.lvCon, json.magicPowerCon, '操霊魔法'],
	 [json.lvPri, json.magicPowerPri, '神聖魔法'],
	 [json.lvMag, json.magicPowerMag, '魔動機術'],
	 [json.lvFai, json.magicPowerFai, '妖精魔法'],
	 [json.lvDem, json.magicPowerDem, '召異魔法'],
	 [json.lvGri, json.magicPowerGri, '秘奥魔法'],].filter((d)=>{
		return d[0];
	}).forEach((v)=>{
		palette_detail['戦闘中'] += `\n2d6+${v[1]}+{魔法行使} ${v[2]}行使判定\n`;
		for(let i = 0; i < 6; i++) {
			palette_detail['戦闘中'] += `k${i*10}+${v[1]}+{魔法ダメージ}@(10-{クリティカル値減少}) ${v[2]}ダメージ (威力 ${i*10})\n`;
		}
	});
	palette_detail['戦闘中'] += `2d6+${json.defenseTotalAllEva}+{回避} 回避判定\n`;
	palette_detail['戦闘中'] += `2d6+${json.vitResistTotal}+{生命抵抗} 生命抵抗判定\n`;
	palette_detail['戦闘中'] += `2d6+${json.mndResistTotal}+{精神抵抗} 精神抵抗判定\n`;

	palette_detail['探索中'] = skills.map((s)=>{
		return ['器用度', '敏捷度', '知力'].map((v)=>{
			return `2d6+{${s.name}}+{${v}} ${s.name}+${v}`
		}).join('\n')
	}).join('\n')

	let palette = `<chat-palette dicebot="SwordWorld2_5">\n`;
	for(const key in palette_detail) {
		palette += `// ${key}\n${palette_detail[key]}\n`;
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