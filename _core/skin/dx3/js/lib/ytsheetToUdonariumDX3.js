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

io.github.shunshun94.trpg.udonarium.getChatPallet = (sheetUrl) => {
	return new Promise((resolve, reject)=>{
		if(sheetUrl === '' || ! sheetUrl.startsWith(location.origin)) {resolve('');return;}
		let xhr = new XMLHttpRequest();
		xhr.open('GET', `${sheetUrl}&tool=bcdice&mode=palette`, true);
		xhr.responseType = "text";
		xhr.onload = (e) => {
			console.log('aaa', e.currentTarget);
			resolve(e.currentTarget.response);
		};
		xhr.onerror = () => resolve('');
		xhr.onabort = () => resolve('');
		xhr.ontimeout = () => resolve('');
		xhr.send();
  });
};

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2DoubleCross3PC = async (json, opt_url='', opt_imageHash='')=>{
	const defaultPallet = await io.github.shunshun94.trpg.udonarium.getChatPallet(opt_url);
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
		`        <data type="numberResource" currentValue="${json.maxHpTotal}" name="HP">${json.maxHpTotal}</data>`,
		`        <data type="numberResource" currentValue="${json.baseEncroach}" name="侵蝕率">300</data>`,
        `        <data type="numberResource" currentValue="${json.initiativeTotal || '0'}" name="行動値">100</data>`,
        `        <data type="numberResource" currentValue="5" name="ロイス">7</data>`,
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
	data_character_detail['能力値'] = io.github.shunshun94.trpg.udonarium.consts.DX3_STATUS.map((s)=>{
		return `        <data name="${s.name}">${json['sttTotal' + s.column]}</data>`
	});

	data_character_detail['技能'] = io.github.shunshun94.trpg.udonarium.consts.DX3_STATUS.map((s)=>{
		const result = [];
		result.push(s.skills.map((skill)=>{
			return `        <data name="${skill.name}">${json['skill' + skill.column] || '0'}</data>`;
		}).join('\n'));
		let cursor = 1;
		while(json[`skill${s.extendableSkill.column}${cursor}Name`]) {
			result.push(`        <data name="${json[`skill${s.extendableSkill.column}${cursor}Name`]}">${json[`skill${s.extendableSkill.column}${cursor}`] || 0}</data>`);
			cursor++;
		}
		return result.join('\n');
	});

	data_character_detail['バフ・デバフ'] = [
		`        <data type="numberResource" currentValue="0" name="侵蝕率によるダイスボーナス">10</data>`,
		`        <data type="numberResource" currentValue="0" name="ダイス">50</data>`,
		`        <data type="numberResource" currentValue="0" name="達成値">50</data>`,
		`        <data type="numberResource" currentValue="0" name="攻撃力">100</data>`,
		`        <data type="numberResource" currentValue="0" name="クリティカル値減少">9</data>`,
	];

	data_character.detail = `  <data name="detail">\n`;
	for(const key in data_character_detail) {
		data_character.detail += `      <data name="${key}">\n`;
		data_character.detail += data_character_detail[key].join(('\n'));
		data_character.detail += `\n      </data>\n`;
	}
	data_character.detail += `    </data>`;

	let palette = `<chat-palette dicebot="DoubleCross">\n`;
	if(defaultPallet) {
		palette += defaultPallet;
	} else {
		const tmp_palette = [];

		tmp_palette.push(`現在の状態　HP:{HP} / 侵蝕率:{侵蝕率}`);
		if(opt_url) { tmp_palette.push(`キャラクターシート　{URL}`);}
		io.github.shunshun94.trpg.udonarium.consts.DX3_STATUS.forEach((s)=>{
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

io.github.shunshun94.trpg.udonarium.consts = io.github.shunshun94.trpg.udonarium.consts || {};
io.github.shunshun94.trpg.udonarium.consts.DX3_STATUS = [
	{
		name: '肉体',
		column: 'Body',
		skills: [
			{
				name: '白兵',
				column: 'Melee'
			}, {
				name: '回避',
				column: 'Dodge'
			}
		],
		extendableSkill: {
			name: '運転',
			column: 'Ride'
		}
	}, {
		name: '感覚',
		column: 'Sense',
		skills: [
			{
				name: '射撃',
				column: 'Ranged'
			}, {
				name: '回避',
				column: 'Percept'
			}
		],
		extendableSkill: {
			name: '芸術',
			column: 'Art'
		}
	}, {
		name: '精神',
		column: 'Mind',
		skills: [
			{
				name: 'ＲＣ',
				column: 'RC'
			}, {
				name: '意志',
				column: 'Will'
			}
		],
		extendableSkill: {
			name: '知識',
			column: 'Know'
		}
	}, {
		name: '社会',
		column: 'Social',
		skills: [
			{
				name: '交渉',
				column: 'Negotiate'
			}, {
				name: '調達',
				column: 'Procure'
			}
		],
		extendableSkill: {
			name: '情報',
			column: 'Info'
		}
	}
];