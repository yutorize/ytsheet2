"use strict";

var output = output || {};

output.generateUdonariumXmlDetailOfGoblinSlayerPC = (json, opt_url, defaultPalette, resources)=>{
	const dataDetails = {'リソース':resources};

  dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data name="種族">${json.race || ''}${ json.raceFree ? `／${json.raceFree}` : '' }</data>`,
    (json.raceBase ? `        <data name="本来の種族">${json.raceBase || ''}${ json.raceBaseFree ? `／${json.raceBaseFree}` : '' }</data>` : null),
    `        <data name="年齢">${json.age || ''}${json.ageApp ? '（外見年齢：'+json.ageApp+'）' : ''}</data>`,
    `        <data name="性別">${json.gender || ''}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);}

	dataDetails['能力値'] = [
    `<data name="体力点">${json.ability1Str}</data>`,
    `<data name="魂魄点">${json.ability1Psy}</data>`,
    `<data name="技量点">${json.ability1Tec}</data>`,
    `<data name="知力点">${json.ability1Int}</data>`,
    `<data name="集中度">${json.ability2Foc}</data>`,
    `<data name="持久度">${json.ability2Edu}</data>`,
    `<data name="反射度">${json.ability2Ref}</data>`,
  ];
	dataDetails['職業'] = [];
  for(const name of SET.classNames){
    const level = json['lv'+SET.class[name].id];
    if(!level) continue;
    dataDetails['職業'].push(`<data name="${name}">${level}</data>`)
  }
  dataDetails['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
    for (const name of SET.classNames){
      if(name === param.label){ return `` }
    }
    if(param.label.match(/^(冒険者レベル|体力点|魂魄点|技量点|知力点|集中度|持久度|反射度)$/)){ return `` }

    if(param.value.match(/[^0-9]/) || param.value === ''){ return `        <data name="${param.label}">${param.value}</data>`; }
    else { return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; }
  });

	return dataDetails
};