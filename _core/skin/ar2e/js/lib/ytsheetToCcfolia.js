"use strict";

var output = output || {};

output.generateCcfoliaJsonOfArianrhod2PC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName || json.aka;

  character.memo = '';
  character.memo += json.namePlate?json.characterName+"\n":'';
  character.memo += json.characterNameRuby ? '('+json.characterNameRuby+')\n' :'';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `${json.age || ''} / ${json.gender || ''} / ${json.race || ''}\n`;
  character.memo += `${json.classMain || ''}${json.classSupport ? ' / '+json.classSupport : ''}${json.classTitle ? ' / '+json.classTitle : ''}\n`;
  character.memo += `\n`;
  character.memo += json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : '';
  
  let addedParam = {};
  output.consts.AR2_STATUS.forEach((s)=>{
    character.params.push({
      label: s.name, value: json[`stt${s.column}Total`] || 0
    });
    addedParam[s.name] = 1;
  });

  defaultPalette.parameters.forEach(s => {
    if(addedParam[s.label]){ return ''; }
    character.params.push(s);
  });

  return character;
};
