"use strict";

var output = output || {};

output.generateUdonariumXmlDetailOfGranCrestPC = (json, opt_url, defaultPalette, resources)=>{
  const dataDetails = {'リソース':resources};

  dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data name="クラス">${json.class || ''}</data>`,
    `        <data name="スタイル">${json.style || ''}</data>`,
    `        <data name="ワークス">${json.works || ''}</data>`,
    `        <data name="サブスタイル">${json.styleSub || ''}</data>`,
    `        <data name="所属国">${json.country || ''}</data>`,
    `        <data name="性別">${json.gender || ''}</data>`,
    `        <data name="年齢">${json.age || ''}</data>`,
    `        <data name="身長">${json.height || ''}</data>`,
    `        <data name="体重">${json.weight || ''}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);}

  let addedParam = {};
  dataDetails['レベル・判定値'] = [];
  output.consts.GC_PARAMS.forEach(data => {
    dataDetails['レベル・判定値'].push(`        <data name="${data.name}">${json[data.value] || 0}</data>`);
    addedParam[data.name] = 1;
  });
  if(json.forceLead){
    output.consts.GC_PARAMS.forEach(data => {
      dataDetails['レベル・判定値'].push(`        <data name="部隊${data.name}">${json[data.force.replace('1',json.forceLead)] || 0}</data>`);
      addedParam['部隊'+data.name] = 1;
    });
  }
  dataDetails['技能'] = [];
  for(const stt of ['Str','Ref','Per','Int','Mnd','Emp']){
    for(let i = 1; i <= json[`skill${stt}Num`]; i++){
      dataDetails['技能'].push(`        <data name="${json[`skill${stt}${i}Label`] || 0}">${json[`skill${stt}${i}Lv`] || 0}</data>`);
      addedParam[json[`skill${stt}${i}Label`]] = 1;
    }
  }

  dataDetails['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
    if(addedParam[param.label]){ return `` }
    return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
  });


  return dataDetails
};
