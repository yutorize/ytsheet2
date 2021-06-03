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

io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2DoubleCross3PC = async (json, opt_sheetUrl = '', opt_defaultPictureUrl = io.github.shunshun94.trpg.ccfolia.CONSTS.DEFAULT_PC_PICTURE) => {
	const result = io.github.shunshun94.trpg.ccfolia.getCharacterSeed();
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_sheetUrl);
	const character = {
			name: json.characterName || json.aka,
			playerName: json.playerName,
			memo: `${json.characterNameRuby ? '('+json.characterNameRuby+')\n' :''}PL: ${json.playerName || 'PL情報無し'}\n${json.works || ''} / ${json.cover || ''}\n${json.syndrome1 || ''}${json.syndrome2 ? '、'+json.syndrome2 : ''}${json.syndrome3 ? '、'+json.syndrome3 : ''}\n\n${json.imageURL ? '立ち絵：' + (json.imageCopyright || '権利情報なし') : ''}`,
			initiative: Number(json.initiativeTotal || 0),
			externalUrl: opt_sheetUrl,
			status: [
				{
					label: 'HP',
					value: json.maxHpTotal,
					max: json.maxHpTotal
				}, {
					label: '侵蝕率',
					value: json.baseEncroach || 0,
					max: 300
				}, {
					label: 'ロイス',
					value: json.loisHave || 3,
					max: json.loisMax || 7
				}, {
					label: '財産点',
					value: json.savingTotal,
					max: json.savingTotal
				}
			],
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
	io.github.shunshun94.trpg.ytsheet.consts.DX3_STATUS.forEach((s)=>{
		character.params.push({
			label: s.name, value: json['sttTotal' + s.column] || 0
		});
		s.skills.forEach((skill)=>{
			character.params.push({
				label: skill.name, value: json['skillTotal' + skill.column] || 0
			});
		});
		let cursor = 1;
		while(json[`skill${s.extendableSkill.column}${cursor}Name`]) {
			character.params.push({label: json[`skill${s.extendableSkill.column}${cursor}Name`], value: json[`skillTotal${s.extendableSkill.column}${cursor}`] || 0});
			cursor++;
		}
	});

	result.entities.characters[json.id] = character;
	return JSON.stringify(result);
};
