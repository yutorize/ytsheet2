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

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2DoubleCross3PC = async (json, opt_url='', opt_imageHash='')=>{
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_url);
	const data_character = {};

	data_character.image = `
    <data name="image">
      <data type="image" name="imageIdentifier">${opt_imageHash}</data>
    </data>`;

	data_character.common = `
    <data name="common">
      <data name="name">${json.characterName || json.aka || ''}</data>
      <data name="size">1</data>
    </data>`;

	data_character_detail = {};
	data_character_detail['リソース'] = [
		`        <data type="numberResource" currentValue="${json.maxHpTotal}" name="HP">${json.maxHpTotal}</data>`,
		`        <data type="numberResource" currentValue="${json.baseEncroach}" name="侵蝕率">300</data>`,
        `        <data type="numberResource" currentValue="${json.initiativeTotal || 0}" name="行動値">100</data>`,
        `        <data type="numberResource" currentValue="${json.loisHave || 3}" name="ロイス">${json.loisMax || 7}</data>`,
        `        <data type="numberResource" currentValue="${json.savingTotal || 0}" name="財産点">300</data>`
	];
	data_character_detail['情報'] = [
        `        <data name="PL">${json.playerName || '?'}</data>`,
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
	let addedParam = {};
	data_character_detail['能力値'] = io.github.shunshun94.trpg.ytsheet.consts.DX3_STATUS.map((s)=>{
		addedParam[s.name] = 1;
		return `        <data name="${s.name}">${json['sttTotal' + s.column]}</data>`
	});
	data_character_detail['技能'] = io.github.shunshun94.trpg.ytsheet.consts.DX3_STATUS.map((s)=>{
		const result = [];
		result.push(s.skills.map((skill)=>{
			addedParam[skill.name] = 1;
			return `        <data name="${skill.name}">${json['skillTotal' + skill.column] || '0'}</data>`;
		}).join('\n'));
		let cursor = 1;
		while(json[`skill${s.extendableSkill.column}${cursor}Name`]) {
			addedParam[json[`skill${s.extendableSkill.column}${cursor}Name`]] = 1;
			result.push(`        <data name="${json[`skill${s.extendableSkill.column}${cursor}Name`]}">${json[`skillTotal${s.extendableSkill.column}${cursor}`] || 0}</data>`);
			cursor++;
		}
		return result.join('\n');
	});
	if(defaultPalette) {
		data_character_detail['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
			if(addedParam[param.label]){ return `` }
			return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
		});
	} else {
		data_character_detail['バフ・デバフ'] = [
			`        <data type="numberResource" currentValue="0" name="侵蝕率によるダイスボーナス">10</data>`,
			`        <data type="numberResource" currentValue="0" name="ダイス">50</data>`,
			`        <data type="numberResource" currentValue="0" name="達成値">50</data>`,
			`        <data type="numberResource" currentValue="0" name="攻撃力">100</data>`,
			`        <data type="numberResource" currentValue="0" name="クリティカル値減少">9</data>`,
		];
	}

	data_character.detail = `  <data name="detail">\n`;
	for(const key in data_character_detail) {
		data_character.detail += `      <data name="${key}">\n`;
		data_character.detail += data_character_detail[key].join(('\n'));
		data_character.detail += `\n      </data>\n`;
	}
	data_character.detail += `    </data>`;

	let palette = `<chat-palette dicebot="DoubleCross">\n`;
	if(defaultPalette) {
		palette += defaultPalette.palette.replace('<','&lt;').replace('>','&gt;');
	} else {
		const tmp_palette = [];

		tmp_palette.push(`現在の状態　HP:{HP} / 侵蝕率:{侵蝕率}`);
		if(opt_url) { tmp_palette.push(`キャラクターシート　{URL}`);}
		io.github.shunshun94.trpg.ytsheet.consts.DX3_STATUS.forEach((s)=>{
			const base = json['sttTotal' + s.column];
			s.skills.forEach((skill)=>{
				tmp_palette.push(`(${base}+{侵蝕率によるダイスボーナス}+{ダイス})DX+(${json['skill' + skill.column] || 0}+{達成値})@(10-{クリティカル値減少}) ${skill.name}`);
			});
			let cursor = 1;
			while(json[`skill${s.extendableSkill.column}${cursor}Name`]) {
				tmp_palette.push(`(${base}+{侵蝕率によるダイスボーナス}+{ダイス})DX+(${json[`skill${s.extendableSkill.column}${cursor}`] || 0}+{達成値})@(10-{クリティカル値減少}) ${json[`skill${s.extendableSkill.column}${cursor}Name`]}`);
				cursor++;
			}
		});
		let comboCursor = 1;
		while(json[`combo${comboCursor}Name`]) {
			let limitationCursor = 1;
			while(json[`combo${comboCursor}Condition${limitationCursor}`] && json[`combo${comboCursor}Dice${limitationCursor}`]) {
				tmp_palette.push('(' + json[`combo${comboCursor}Dice${limitationCursor}`] + '+{侵蝕率によるダイスボーナス}+{ダイス})dx' +
						'+(' + (json[`combo${comboCursor}Fixed${limitationCursor}`] || '0') + '+{達成値})' +
						'@(' + (json[`combo${comboCursor}Crit${limitationCursor}`] || '10') + '-{クリティカル値減少}) ' +
						json[`combo${comboCursor}Name`] + '(' + json[`combo${comboCursor}Condition${limitationCursor}`] + ') ' + (json[`combo${comboCursor}Note`] || '') + ' ' +
						(json[`combo${comboCursor}Combo`] || '').trim() + ' ' + (json[`combo${comboCursor}Atk${limitationCursor}`] ? json[`combo${comboCursor}Atk${limitationCursor}`] : ''));
				limitationCursor++;
			}
			comboCursor++;
		}
		palette += tmp_palette.join('\n');

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
