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
			let cursor = i + 1;
			let name = json['status' + cursor + 'Style'] || '';
			name = name.replace(/^.+?[(（](.+?)[）)]$/, "$1");
			if(json.mount){
				if(json.lv){
					const lvNum = (json.lv - json.lvMin + 1);
					cursor += lvNum > 1 ? "-"+lvNum : '';
				}
			}
			data_character_detail['リソース'].push(
					`        <data type="numberResource" currentValue="${json['status' + cursor + 'Hp'] || '0'}" name="${name}HP">${json['status' + cursor + 'Hp'] || '0'}</data>`,
					`        <data type="numberResource" currentValue="${json['status' + cursor + 'Mp'] || '0'}" name="${name}MP">${json['status' + cursor + 'Mp'] || '0'}</data>`
			);
		}
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

	let palette = `<chat-palette dicebot="SwordWorld2.5">\n`;
	if(defaultPalette) {
		palette += defaultPalette.palette.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
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
		{level:json.lvMag, name:'マギテック'},
		{level:json.lvFai, name:'フェアリーテイマー'},
		{level:json.lvDru, name:'ドルイド'},
		{level:json.lvDem, name:'デーモンルーラー'},
		{level:json.lvSco, name:'スカウト'},
		{level:json.lvRan, name:'レンジャー'},
		{level:json.lvSag, name:'セージ'},
		{level:json.lvEnh, name:'エンハンサー'},
		{level:json.lvBar, name:'バード'},
		{level:json.lvRid, name:'ライダー'},
		{level:json.lvAlc, name:'アルケミスト'},
		{level:json.lvGeo, name:'ジオマンサー'},
		{level:json.lvWar, name:'ウォーリーダー'},
		{level:json.lvMys, name:'ミスティック'},
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

			if(param.value.match(/[^0-9]/) || param.value === ''){ return `        <data name="${param.label}">${param.value}</data>`; }
			else { return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; }
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

	let palette = `<chat-palette dicebot="SwordWorld2.5">\n`;
	if(defaultPalette) {
		palette += defaultPalette.palette.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
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