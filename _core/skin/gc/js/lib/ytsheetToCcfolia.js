"use strict";

var output = output || {};

output.generateCcfoliaJsonOfGranCrestPC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName;
  
  character.memo = '';
  character.memo += json.namePlate?json.characterName+"\n":'';
  character.memo += `PL: ${json.playerName || 'PL情報無し'}\n`;
  character.memo += `クラス:${json.class || '―'} / スタイル:${json.style || '―'}\n`;
  character.memo += `ワークス:${json.works || '―'} / サブスタイル:${json.styleSub || '―'}\n`;
  character.memo += `${json.age || ''} / ${json.gender || ''} / ${json.height || ''} / ${json.weight || ''}\n`;
  character.memo += `\n`;
  character.memo += `${json.imageURL ? '立ち絵: ' + (json.imageCopyright || '権利情報なし') : ''}\n`;
  
  let addedParam = {};

  defaultPalette.parameters.forEach(s => {
    if(addedParam[s.label]){ return ''; }
    character.params.push(s);
  });

  return character;
};
