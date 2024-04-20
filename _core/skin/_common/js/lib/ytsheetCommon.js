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

output.length = (str='') => {
	// https://zukucode.com/2017/04/javascript-string-length.html
	let length = 0;
	for (let i = 0; i < str.length; i++) {
			const c = str.charCodeAt(i);
			if ((c >= 0x0 && c < 0x81) || (c === 0xf8f0) || (c >= 0xff61 && c < 0xffa0) || (c >= 0xf8f1 && c < 0xf8f4)) {
				length += 1;
			} else {
				length += 2;
			}
	}
	return length;
};

output._getColumnLength = (list, header) => {
	return list.reduce((currentMax, targetEffect)=>{
		const result = {};
		for(var key in currentMax) {
			result[key] = Math.max(output.length(targetEffect[key]), currentMax[key]);
		}
		return result;
	}, header);
};

output._convertList = (list, columns, opt_separator = '/') => {
	const headerLength = output._getLengthWithoutNote(columns || list[0]);
	const length = output._getColumnLength(list, headerLength);
	const convertDataToString = (data) => {
		const result = [];
		for(var key in headerLength) {
			if(data === '-'){
				result.push(''.padEnd(length[key], '-'));
			}
			else {
				result.push(`${data[key]}${''.padEnd(length[key] - output.length(data[key]), ' ')}`);
			}
		}
		result.push(data.note);
		return result.join(opt_separator);
	};
	return (columns ? [columns].concat(list) : list).map(convertDataToString).join('\n');
};

output._getLengthWithoutNote = (baseHeader) => {
	const result = {};
	for(let key in baseHeader) {
		if(key !== 'note') {
			result[key] = output.length(baseHeader[key]);
		}
	}
	return result;
};

output.isNumberValue = (value) => {
	return Number(value) || (value === '0');
};

output.getPicture = (src, fileName) => {
	return new Promise((resolve, reject) => {
		let xhr = new XMLHttpRequest();
		xhr.open('GET', src, true);
		xhr.responseType = "blob";
		xhr.onload = (e) => {
			fileName ||= src.slice(src.lastIndexOf("/") + 1);
			const currentTarget = e.currentTarget;
			if(! Boolean(jsSHA)) {
				console.warn('To calculate SHA256 value of the picture, jsSHA is required: https://github.com/Caligatio/jsSHA');
				resolve({ event:e, data: e.currentTarget.response, fileName: fileName, hash: '' });
				return;
			}
			e.currentTarget.response.arrayBuffer().then((arraybuffer)=>{
				const sha = new jsSHA("SHA-256", 'ARRAYBUFFER');
				sha.update(arraybuffer);
				const hash = sha.getHash("HEX");
				resolve({ event:e, data: currentTarget.response, fileName: fileName, hash: hash });
				return;
			});
		};
		xhr.onerror = () => resolve({ data: null });
		xhr.onabort = () => resolve({ data: null });
		xhr.ontimeout = () => resolve({ data: null });
		xhr.send();
	});
};

output.separateParametersFromChatPalette = (chatPalette) => {
	const result = {
		palette: '',
		parameters: []
	};
	const palette = [];
	const parameterRegExp = /^\/\/(.+)=([0-9\+\-\/\*]+)?$/;
	chatPalette.split('\n').forEach((line)=>{
		const parameterExecResult = parameterRegExp.exec(line);
		if(parameterExecResult) {
			result.parameters.push({
				label:parameterExecResult[1],
				value:(parameterExecResult[2] !== undefined ? parameterExecResult[2] : '')
			});
		} else {
			palette.push(line);
		}
	});
	result.palette = palette.join('\n');
	return result;
};

output.getChatPalette = (sheetUrl) => {
	sheetUrl = sheetUrl.replace(/&?mode=([^&]+)/g, '');
	return new Promise((resolve, reject)=>{
		let xhr = new XMLHttpRequest();
		xhr.open('GET', `${sheetUrl}&mode=palette&tool=bcdice`, true);
		xhr.responseType = "text";
		xhr.onload = (e) => {
			resolve(output.separateParametersFromChatPalette(e.currentTarget.response));
		};
		xhr.onerror = () => resolve('');
		xhr.onabort = () => resolve('');
		xhr.ontimeout = () => resolve('');
		xhr.send();
  });
};


output.generateUdonariumXml = async (generateType, json, opt_url='', opt_imageHash='') => {
	const defaultPalette = await output.getChatPalette(opt_url);
	const dataCharacter = {};

	dataCharacter.image = `
		<data name="image">
  	  <data type="image" name="imageIdentifier">${opt_imageHash}</data>
  	</data>`;

	dataCharacter.common = `
    <data name="common">
      <data name="name">${json.namePlate || json.characterName || json.monsterName || json.aka}</data>
      <data name="size">1</data>
    </data>`;

  const resources = [];
  for(let unitData of json.unitStatus){
    for (const label in unitData) {
      if(/^[0-9/]+$/.test(unitData[label])){
        const value = String(unitData[label]).split('/');
        resources.push(`        <data type="numberResource" currentValue="${value[0]}" name="${label}">${value[1]||0}</data>`)
      }
      else {
        resources.push(`        <data name="${label}">${unitData[label]||''}</data>`)
      }
    }
  }

  const dataCharacterDetail = output['generateUdonariumXmlDetailOf'+generateType](json,opt_url,defaultPalette,resources);
  
  dataCharacter.detail = `  <data name="detail">\n`;
  for(const key in dataCharacterDetail) {
    dataCharacter.detail += `      <data name="${key}">\n`;
    dataCharacter.detail += dataCharacterDetail[key].join(('\n'));
    dataCharacter.detail += `\n      </data>\n`;
  }
  dataCharacter.detail += `    </data>`;

	
  let chatColorFly = '';
  let chatColorLily = '';
  if(json.nameColor){
    let num = 0;
    json.nameColor.split(',').forEach(color => {
      if(!num){	chatColorFly = color; }
      chatColorLily += ` chatColorCode.${num}="${color}"`;
      num++;
    })
  }

  let palette = `<chat-palette dicebot="${output.consts.dicebot||'DiceBot'}" paletteColor="${chatColorFly}">\n`;
  palette += defaultPalette.palette.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  palette += `  </chat-palette>`;

  return `<?xml version="1.0" encoding="UTF-8"?>
<character location.name="table" location.x="0" location.y="0" posZ="0" rotate="0" roll="0"${chatColorLily}>
  <data name="character">
  ${dataCharacter.image}
  ${dataCharacter.common}
  ${dataCharacter.detail}
  </data>
  ${palette}
</character>
`;
};


output.generateCcfoliaJson = async (generateType, json, opt_sheetUrl = '') => {
	const result = { kind: "character" };
	const defaultPalette = await output.getChatPalette(opt_sheetUrl+'&propertiesall=1');

  const resources = [];
  for(let unitData of json.unitStatus){
    for (const label in unitData) {
			if(label == output.consts.initiativeLabel) continue;
      if(/^[0-9/]+$/.test(unitData[label])){
        const value = String(unitData[label]).split('/');
        resources.push({label: label, value: value[0], max: value[1]})
      }
      else {
        resources.push({label: label, value: unitData[label]})
      }
    }
  }
  
	const character = {
    playerName: json.playerName,
    externalUrl: opt_sheetUrl,
    status: resources,
    params: [],
    faces: [],
    x: 0, y: 0, z: 0,
    angle: 0, width: 4, height: 4,
    active: true, secret: false,
    invisible: false, hideStatus: false,
    color: (json.nameColor || '').split(',')[0],
    roomId: null,
    commands: defaultPalette.palette || '',
    speaking: true
  };

  result.data = output['generateCcfoliaJsonOf'+generateType](json, character, defaultPalette);
  
	return JSON.stringify(result);
};
