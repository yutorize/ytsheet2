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

io.github.shunshun94.trpg.udonarium.generateCharacterXmlFromYtSheet2KizunaBulletPC = async (json, opt_url='', opt_imageHash='')=>{
  const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_url);
  const data_character = {};

  const typeH = json.type === 'ハウンド' ? 1 : 0;

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
    `        <data name="作戦力">${json.operation || '0'}</data>`,
    `        <data name="励起値">${json.excitation || '0'}</data>`,
  ];
  data_character_detail['情報'] = [
        `        <data name="PL">${json.playerName || '?'}</data>`,
        `        <data name="種別">${json.type || ''}</data>`,
        `        <data name="ネガイ(表)">${json.negaiOutside || ''}</data>`,
        `        <data name="ネガイ(裏)">${json.negaiInside || ''}</data>`,
        `        <data name="年齢">${json.age || ''}</data>`,
        `        <data name="過去">${json.past || ''}</data>`,
        `        <data name="性別">${json.gender || ''}</data>`,
        `        <data name="${typeH ? '遭遇':'経緯'}">${json.background || ''}</data>`,
        `        <data name="外見の特徴">${json.appearance || ''}</data>`,
        `        <data name="${typeH ? 'ケージ':'住居'}">${json.dwelling || ''}</data>`,
        `        <data name="好きなもの">${json.like || ''}</data>`,
        `        <data name="嫌いなもの">${json.dislike || ''}</data>`,
        `        <data name="得意なこと">${json.good || ''}</data>`,
        `        <data name="苦手なこと">${json.notgood || ''}</data>`,
        `        <data name="喪失">${json.missing || ''}</data>`,
        `        <data name="${typeH ? 'リミッターの影響':'ペアリングの副作用'}">${json.sideeffect || ''}</data>`,
        `        <data name="${typeH ? '決意':'使命'}">${json.resolution || ''}</data>`,
        `        <data name="所属">${json.belong || ''}</data>`,
        `        <data name="おもな武器">${json.weapon || ''}</data>`,
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