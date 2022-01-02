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

io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2Arianrhod2PC = async (json, opt_sheetUrl = '') => {
	const result = io.github.shunshun94.trpg.ccfolia.getCharacterSeed();
	const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_sheetUrl);
	const character = {
			name: json.characterName || json.aka,
			playerName: json.playerName,
			memo: `${json.characterNameRuby ? '('+json.characterNameRuby+')\n' :''}PL: ${json.playerName || 'PL情報無し'}\n${json.age || ''} / ${json.gender || ''} / ${json.race || ''}\n${json.classMain || ''}${json.classSupport ? ' / '+json.classSupport : ''}${json.classTitle ? ' / '+json.classTitle : ''}\n\n${json.imageURL ? '立ち絵：' + (json.imageCopyright || '権利情報なし') : ''}`,
			initiative: Number(json.initiativeTotal || 0),
			externalUrl: opt_sheetUrl,
			status: [
				{
					label: 'HP',
					value: json.hpTotal || 0,
					max: json.hpTotal || 0
				}, {
					label: 'MP',
					value: json.mpTotal || 0,
					max: json.mpTotal || 0
				}, {
					label: 'フェイト',
					value: json.fateTotal || 5,
					max: json.fateTotal || 5
				}
			],
			params: [],
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
	
	let addedParam = {};
	io.github.shunshun94.trpg.ytsheet.consts.AR2_STATUS.forEach((s)=>{
		character.params.push({
			label: s.name, value: json[`stt${s.column}Total`] || 0
		});
		addedParam[s.name] = 1;
	});

	defaultPalette.parameters.forEach(s => {
		if(addedParam[s.label]){ return ''; }
		character.params.push(s);
	});

	result.data = character;
	return JSON.stringify(result);
};
