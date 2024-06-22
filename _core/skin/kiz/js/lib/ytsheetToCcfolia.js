"use strict";

var output = output || {};

output.generateCcfoliaJsonOfKizunaBulletPC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName;
  
  character.memo = '';
  character.memo += json.namePlate?json.characterName+"\n":'';
  character.memo += json.characterNameRuby ? '('+json.characterNameRuby+')\n' :'';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `${json.class || ''} / ${json.negaiOutside || ''} / ${json.negaiInside || ''}\n`;
  character.memo += `\n`;
  character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}`;

  character.params = defaultPalette.parameters || [];

  return character;
};
