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

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2Arianrhod2PC = async (json, opt_url='', opt_imageHash='')=>{
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
		`        <data type="numberResource" currentValue="${json.hpTotal}" name="HP">${json.hpTotal}</data>`,
		`        <data type="numberResource" currentValue="${json.mpTotal}" name="MP">${json.mpTotal}</data>`,
		`        <data type="numberResource" currentValue="${json.fateTotal}" name="フェイト">${json.fateTotal}</data>`,
    `        <data name="フェイト使用上限">${json.fateLimit || 0}</data>`,
		`        <data name="所持金">${json.moneyTotal}</data>`,
	];
	data_character_detail['情報'] = [
        `        <data name="PL">${json.playerName || '?'}</data>`,
        `        <data name="年齢">${json.age || ''}</data>`,
        `        <data name="性別">${json.gender || ''}</data>`,
        `        <data name="種族">${json.race || ''}</data>`,
        `        <data name="レベル">${json.level || ''}</data>`,
        `        <data name="メインクラス">${json.classMain || ''}</data>`,
        `        <data name="サポートクラス">${json.classSupport || ''}</data>`,
        `        <data name="称号クラス">${json.classTitle || ''}</data>`,
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
	data_character_detail['能力値'] = io.github.shunshun94.trpg.ytsheet.consts.AR2_STATUS.map((s)=>{
		addedParam[s.name] = 1;
		return `        <data name="${s.name}">${json['roll' + s.column]}</data>`
	});
	data_character_detail['戦闘'] = [
        `        <data name="命中">{器用}+${json.battleAddAcc || 0}</data>`,
        `        <data name="命中ダイス">${json.battleDiceAcc || 0}</data>`,
        `        <data name="攻撃力">${json.battleTotalAtk || 0}</data>`,
        `        <data name="攻撃ダイス">${json.battleDiceAtk || 0}</data>`,
        `        <data name="回避">{敏捷}+${json.battleAddEva || 0}</data>`,
        `        <data name="回避ダイス">${json.battleDiceEva || 0}</data>`,
				`        <data name="物理防御力">${json.battleTotalDef || 0}</data>`,
				`        <data name="魔法防御力">${json.battleTotalMDef || 0}</data>`,
				`        <data name="行動値">${json.battleTotalIni || 0}</data>`,
				`        <data name="移動力">${json.battleTotalMove || 0}</data>`
	];
	addedParam['命中'] = addedParam['命中ダイス'] = addedParam['攻撃力'] = addedParam['攻撃ダイス'] = addedParam['回避'] = addedParam['回避ダイス'] = addedParam['物理防御力'] = addedParam['魔法防御力'] = addedParam['行動値'] = addedParam['移動力'] = 1;
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

	let palette = `<chat-palette dicebot="Arianrhod">\n`;
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
