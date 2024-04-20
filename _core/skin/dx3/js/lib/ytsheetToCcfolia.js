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
	
  character.initiative = Number(json.initiative || 0);
	
  character.params = defaultPalette.parameters || [];

	return character;
};
