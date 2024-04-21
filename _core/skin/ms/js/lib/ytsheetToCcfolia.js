"use strict";

var output = output || {};

output.generateCcfoliaJsonOfMamonoScramblePC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName;
  
  character.memo = '';
  character.memo += json.namePlate?json.characterName+"\n":'';
  character.memo += json.characterNameRuby ? '('+json.characterNameRuby+')\n' :'';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `分類名: ${json.taxa || ''} ／ 出身: ${json.home || ''} ／ 根源: ${json.origin || ''}\n`;
  character.memo += `クランへの感情: ${json.clanEmotion || ''} ／ 住所: ${json.address || ''}\n`;
  character.memo += `\n`;
  character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}`;
  
  character.params = defaultPalette.parameters || [];


  return character;
};


