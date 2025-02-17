"use strict";

var output = output || {};

output.generateCcfoliaJsonOfSwordWorld2PC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName || json.aka;

  character.memo = '';
  character.memo += json.characterName && json.aka ? `“${json.aka}”` : '';
  character.memo += json.characterName && json.aka && json.akaRuby ? ` (${json.akaRuby})` : '';
  character.memo += json.namePlate?json.characterName+"\n":'';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `${json.race||'種族不明'}／${json.gender||'性別不明'}／${json.age||'年齢不明'}\n`;
  character.memo += `穢れ: ${json.sin || 0}　`;
  character.memo += `信仰: ${json.faith || '―'}\n`;
  character.memo += `ランク: ${json.rank || '―'}\n`;
  character.memo += `\n`;
  character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}`;

  const originalParams = character.params;
  character.params = defaultPalette.parameters;
  character.params = character.params.filter(data => !/^(威力|C値|防護)[0-9]$/.test(data.label));
  character.params = character.params.filter(data => !/^最大[MH]P$/.test(data.label));
  if(!json.lvCaster){
    character.params = character.params.filter(data => !/^(魔力修正|行使修正)$/.test(data.label));
    if(!json.lvBar){
      character.params = character.params.filter(data => !/^(魔法C|魔法D修正)$/.test(data.label));
    }
  }
  character.params = originalParams.concat(character.params);

  return character;
};

output.generateCcfoliaJsonOfSwordWorld2Enemy = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName || json.monsterName;
  
  character.memo = '';
  character.memo += json.namePlate?(json.characterName||json.monsterName)+"\n":'';
  character.memo += json.characterName?"("+json.monsterName+")\n":'';
  character.memo += json.sheetDescriptionM || '';

  character.params = character.params.concat(defaultPalette.parameters);
  
  return character;
};

