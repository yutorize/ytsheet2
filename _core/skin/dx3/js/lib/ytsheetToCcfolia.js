"use strict";

var output = output || {};

output.generateCcfoliaJsonOfDoubleCross3PC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName || json.aka;
  
  character.memo = '';
  character.memo += json.namePlate?json.characterName+"\n":'';
  character.memo += json.characterNameRuby ? '('+json.characterNameRuby+')\n' :'';
  character.memo += json.aka ? `コードネーム: ${json.aka}` : '';
  character.memo += json.aka && json.akaRuby ? ` (${json.akaRuby})` : '';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `${json.works || ''} / ${json.cover || ''}\n`;
  character.memo += `${json.syndrome1 || ''}${json.syndrome2 ? '、'+json.syndrome2 : ''}${json.syndrome3 ? '、'+json.syndrome3 : ''}\n`;
  character.memo += `\n`;
  character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}`;
  
  character.params = character.params.concat(defaultPalette.parameters || []);

  return character;
};

output.generateCcfoliaJsonOfDoubleCross3Enemy = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.enemyName;

  character.memo = '';
  character.memo += json.namePlate ? `${json.enemyName || ''}\n` : '';
  character.memo += `データ製作者: ${json.author || ''}\n`;
  character.memo += `種別: ${json.enemyType || ''}\n`;
  character.memo += `ステージ: ${json.stage || ''}\n`;
  character.memo += `${json.syndrome1 || ''}${json.syndrome2 ? '、'+json.syndrome2 : ''}${json.syndrome3 ? '、'+json.syndrome3 : ''}\n`;
  character.memo += (json.freeNote || '').replace(/&lt;br&gt;/g, '\n');

  character.params = character.params.concat(defaultPalette.parameters || []);

  return character;
};
