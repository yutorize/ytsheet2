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

io.github.shunshun94.trpg.ccfolia.generateCharacterJsonFromYtSheet2BloodPathPC = async (json, opt_sheetUrl = '', opt_defaultPictureUrl = io.github.shunshun94.trpg.ccfolia.CONSTS.DEFAULT_PC_PICTURE) => {
  const result = io.github.shunshun94.trpg.ccfolia.getCharacterSeed();
  const defaultPalette = await io.github.shunshun94.trpg.ytsheet.getChatPalette(opt_sheetUrl);
  const character = {
      name: json.characterName,
      playerName: json.playerName,
      memo: `${json.characterNameRuby ? '('+json.characterNameRuby+')\n' :''}PL: ${json.playerName || 'PL情報無し'}\n${json.factor || ''} / ${json.factorCore || ''} / ${json.factorStyle || ''}\n\n${json.imageURL ? '立ち絵：' + (json.imageCopyright || '権利情報なし') : ''}`,
      initiative: json.initiative || '0',
      externalUrl: opt_sheetUrl,
      status: [
        {
          label: '耐久値',
          value: json.endurance || 0,
          max: json.endurance || 0
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
  if(json.factor === '人間'){
    character.params.push({ label: '技', value: json.statusMain1 || 0 });
    character.params.push({ label: '情', value: json.statusMain2 || 0 });
  }
  else if(json.factor === '吸血鬼'){
    character.params.push({ label: '心', value: json.statusMain1 || 0 });
    character.params.push({ label: '想', value: json.statusMain2 || 0 });
  }

  if(defaultPalette === '') {
    const palette = [];
    palette.push(`現在の状態　耐久値:{耐久値}`);
    character.commands = palette.join('\n');
  }

  result.entities.characters[json.id] = character;
  return JSON.stringify(result);
};


