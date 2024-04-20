/* MIT License

Copyright 2020 @Shunshun94

Customize & Refactoring by @yutorize

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
"use strict";

var output = output || {};

output.generateUdonariumXmlDetailOfDoubleCross3PC = (json, opt_url, defaultPalette, resources)=>{
	const dataDetails = {'リソース':resources};
	
	dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
	];
	if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);}

	let addedParam = {};
	dataDetails['能力値'] = output.consts.DX3_STATUS.map((s)=>{
		addedParam[s.name] = 1;
		return `        <data name="${s.name}">${json['sttTotal' + s.column]}</data>`
	});
	dataDetails['技能'] = output.consts.DX3_STATUS.map((s)=>{
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

	dataDetails['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
		if(addedParam[param.label]){ return `` }
		return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
	});


	return dataDetails
};
