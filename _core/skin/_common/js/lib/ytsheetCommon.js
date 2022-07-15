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
io.github.shunshun94.trpg.ytsheet = io.github.shunshun94.trpg.ytsheet || {};

io.github.shunshun94.trpg.ytsheet.length = (str='') => {
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

io.github.shunshun94.trpg.ytsheet._getColumnLength = (list, header) => {
	return list.reduce((currentMax, targetEffect)=>{
		const result = {};
		for(var key in currentMax) {
			result[key] = Math.max(io.github.shunshun94.trpg.ytsheet.length(targetEffect[key]), currentMax[key]);
		}
		return result;
	}, header);
};

io.github.shunshun94.trpg.ytsheet._convertList = (list, columns, opt_separator = '/') => {
	const headerLength = io.github.shunshun94.trpg.ytsheet._getLengthWithoutNote(columns || list[0]);
	const length = io.github.shunshun94.trpg.ytsheet._getColumnLength(list, headerLength);
	const convertDataToString = (data) => {
		const result = [];
		for(var key in headerLength) {
			result.push(`${data[key]}${''.padEnd(length[key] - io.github.shunshun94.trpg.ytsheet.length(data[key]), ' ')}`);
		}
		result.push(data.note);
		return result.join(opt_separator);
	};
	return (columns ? [columns].concat(list) : list).map(convertDataToString).join('\n');
};

io.github.shunshun94.trpg.ytsheet._getLengthWithoutNote = (baseHeader) => {
	const result = {};
	for(let key in baseHeader) {
		if(key !== 'note') {
			result[key] = io.github.shunshun94.trpg.ytsheet.length(baseHeader[key]);
		}
	}
	return result;
};

io.github.shunshun94.trpg.ytsheet.isNumberValue = (value) => {
	return Number(value) || (value === '0');
};

io.github.shunshun94.trpg.ytsheet.getPicture = (src) => {
	return new Promise((resolve, reject) => {
		let xhr = new XMLHttpRequest();
		xhr.open('GET', src, true);
		xhr.responseType = "blob";
		xhr.onload = (e) => {
			const fileName = src.slice(src.lastIndexOf("/") + 1);
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

io.github.shunshun94.trpg.ytsheet.separateParametersFromChatPalette = (chatPalette) => {
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

io.github.shunshun94.trpg.ytsheet.getChatPalette = () => {
	const paramId = /id=[1-9a-zA-Z]+/.exec(location.href)[0];
	return new Promise((resolve, reject)=>{
		let xhr = new XMLHttpRequest();
		xhr.open('GET', `./?${paramId}&tool=bcdice&mode=palette`, true);
		xhr.responseType = "text";
		xhr.onload = (e) => {
			resolve(io.github.shunshun94.trpg.ytsheet.separateParametersFromChatPalette(e.currentTarget.response));
		};
		xhr.onerror = () => resolve('');
		xhr.onabort = () => resolve('');
		xhr.ontimeout = () => resolve('');
		xhr.send();
  });
};
