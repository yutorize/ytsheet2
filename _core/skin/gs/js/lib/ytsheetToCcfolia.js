"use strict";

var output = output || {};

output.generateCcfoliaJsonOfGoblinSlayerPC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName;

  character.memo = '';
  character.memo += json.namePlate?json.characterName+"\n":'';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `${json.race||'種族不明'}／${json.gender||'性別不明'}／${json.age||'年齢不明'}\n`;
  character.memo += `身体的特徴: ${json.traits || ''} 髪(${json.traitsHair} 瞳(${json.traitsEyes})\n`;
  character.memo += `等級: ${json.rank || '―'}\n`;
  character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}`;

  character.params = character.params.concat(defaultPalette.parameters || []);

  return character;
};
