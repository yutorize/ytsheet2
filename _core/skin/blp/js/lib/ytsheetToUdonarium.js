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

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2BloodPathPC = async (json, opt_url='', opt_imageHash='')=>{
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
    `        <data type="numberResource" currentValue="${json.endurance}" name="耐久値">${json.endurance}</data>`,
        `        <data type="numberResource" currentValue="${json.initiative || '0'}" name="先制値">100</data>`,
  ];
  data_character_detail['情報'] = [
        `        <data name="PL">${json.playerName || '?'}</data>`,
        `        <data name="ファクター">${json.factor || ''}／${json.factorCore || ''}／${json.factorStyle || ''}</data>`,
        `        <data name="年齢">${json.age || ''}${json.ageApp ? '（外見年齢：'+json.ageApp+'）' : ''}</data>`,
        `        <data name="性別">${json.gender || ''}</data>`,
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

  data_character.detail = `  <data name="detail">\n`;
  for(const key in data_character_detail) {
    data_character.detail += `      <data name="${key}">\n`;
    data_character.detail += data_character_detail[key].join(('\n'));
    data_character.detail += `\n      </data>\n`;
  }
  data_character.detail += `    </data>`;

  let palette = `<chat-palette dicebot="">\n`;
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