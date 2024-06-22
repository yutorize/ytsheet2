"use strict";

var output = output || {};

output.generateCcfoliaJsonOfVisionConnectPC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName;
  
  character.memo = '';
  character.memo += json.namePlate?json.characterName+"\n":'';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `${json.age || ''} / ${json.gender || ''} / ${json.race || ''}\n`;
  character.memo += `${json.classMain || ''}${json.classSupport ? ' / '+json.classSupport : ''}${json.classTitle ? ' / '+json.classTitle : ''}\n`;
  character.memo += `\n`;
  character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}\n`;
  
  let addedParam = {};
  output.consts.VC_PARAMS.forEach((s)=>{
    character.params.push({
      label: s.name, value: json[s.value] || 0
    });
    addedParam[s.name] = 1;
  });

  defaultPalette.parameters.forEach(s => {
    if(addedParam[s.label]){ return ''; }
    character.params.push(s);
  });

  return character;
};
