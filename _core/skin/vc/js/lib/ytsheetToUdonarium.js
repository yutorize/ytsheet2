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

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2VisionConnectPC = async (json, opt_url='', opt_imageHash='')=>{
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_url);
	const data_character = {};

	data_character.image = `
    <data name="image">
      <data type="image" name="imageIdentifier">${opt_imageHash}</data>
    </data>`;

	data_character.common = `
    <data name="common">
      <data name="name">${json.characterName || ''}</data>
      <data name="size">1</data>
    </data>`;

	data_character_detail = {};
	data_character_detail['リソース'] = [
		`        <data type="numberResource" currentValue="${json.hpMax}" name="HP">${json.hpMax}</data>`,
		`        <data type="numberResource" currentValue="${json.staminaMax}" name="スタミナ">${json.staminaMax}</data>`,
		`        <data name="ヘイト"></data>`,
	];
	data_character_detail['情報'] = [
        `        <data name="PL">${json.playerName || '?'}</data>`,
        `        <data name="種族">${json.race || ''}</data>`,
        `        <data name="クラス">${json.class || ''}</data>`,
        `        <data name="スタイル1">${json.style1 || ''}</data>`,
        `        <data name="スタイル2">${json.style2 || ''}</data>`,
        `        <data name="年齢">${json.age || ''}</data>`,
        `        <data name="性別">${json.gender || ''}</data>`,
        `        <data name="瞳の色">${json.eye || ''}</data>`,
        `        <data name="肌の色">${json.skin || ''}</data>`,
        `        <data name="髪の色">${json.hair || ''}</data>`,
        `        <data name="身長">${json.height || ''}</data>`,
        `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
	];
	if(opt_url) { data_character_detail['情報'].push(`        <data name="URL">${opt_url}</data>`);}

	let addedParam = output.consts.VC_PARAMS;
	data_character_detail['能力値'] = [
		`        <data name="バイタリティ">${json.vitality || 0}</data>`,
		`        <data name="テクニック">${json.technic || 0}</data>`,
		`        <data name="クレバー">${json.clever || 0}</data>`,
		`        <data name="カリスマ">${json.carisma || 0}</data>`,
];
	data_character_detail['戦闘値'] = [
        `        <data name="命中値">${json.battleTotalAcc || 0}</data>`,
        `        <data name="詠唱値">${json.battleTotalSpl || 0}</data>`,
        `        <data name="回避値">${json.battleTotalEva || 0}</data>`,
        `        <data name="攻撃値">${json.battleTotalAtk || 0}</data>`,
        `        <data name="意志値">${json.battleTotalDet || 0}</data>`,
        `        <data name="物防値">${json.battleTotalDef || 0}</data>`,
        `        <data name="魔防値">${json.battleTotalMdf || 0}</data>`,
        `        <data name="行動値">${json.battleTotalIni || 0}</data>`,
        `        <data name="耐久値">${json.battleTotalStr || 0}</data>`,
	];
	if(defaultPalette) {
		data_character_detail['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
			if(addedParam[param.label]){ return `` }
			return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
		});
	}

	data_character.detail = `  <data name="detail">\n`;
	for(const key in data_character_detail) {
		data_character.detail += `      <data name="${key}">\n`;
		data_character.detail += data_character_detail[key].join(('\n'));
		data_character.detail += `\n      </data>\n`;
	}
	data_character.detail += `    </data>`;

	let palette = `<chat-palette>\n`;
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
