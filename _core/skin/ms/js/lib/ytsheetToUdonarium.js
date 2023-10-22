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

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2MamonoScramblePC = async (json, opt_url='', opt_imageHash='')=>{
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
  ];
  data_character_detail['能力値'] = [
    `        <data name="身体">${json.statusPhysical || ''}</data>`,
    `        <data name="異質">${json.statusSpecial || ''}</data>`,
    `        <data name="社会">${json.statusSocial || ''}</data>`,
  ]
  data_character_detail['情報'] = [
        `        <data name="PL">${json.playerName || '?'}</data>`,
        `        <data name="分類名">${json.taxa || ''}</data>`,
        `        <data name="出身地">${json.home || ''}</data>`,
        `        <data name="根源">${json.origin || ''}</data>`,
        `        <data name="クラン">${json.clan || ''}</data>`,
        `        <data name="クランへの感情">${json.clanEmotion || ''}</data>`,
        `        <data name="住所">${json.address || ''}</data>`,
        `        <data type="note" name="その他">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
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

  let palette = `<chat-palette dicebot="MamonoScramble">\n`;
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