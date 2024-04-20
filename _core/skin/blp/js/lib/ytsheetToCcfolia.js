"use strict";

var output = output || {};

output.generateCcfoliaJsonOfBloodPathPC = (json, character, defaultPalette) => {
	character.name = json.namePlate || json.characterName;
  
	character.memo = '';
	character.memo += json.namePlate?json.characterName+"\n":'';
	character.memo += json.characterNameRuby ? '('+json.characterNameRuby+')\n' :'';
	character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
	character.memo += `${json.factor || ''} / ${json.factorCore || ''} / ${json.factorStyle || ''}\n`;
	character.memo += `\n`;
	character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}`;

  character.initiative = Number(json.initiative || 0);
  
  if(json.factor === '人間'){
    character.params.push({ label: '技', value: json.statusMain1 || 0 });
    character.params.push({ label: '情', value: json.statusMain2 || 0 });
  }
  else if(json.factor === '吸血鬼'){
    character.params.push({ label: '心', value: json.statusMain1 || 0 });
    character.params.push({ label: '想', value: json.statusMain2 || 0 });
  }

	return character;
};
