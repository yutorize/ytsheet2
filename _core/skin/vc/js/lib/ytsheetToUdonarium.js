"use strict";

var output = output || {};

output.generateUdonariumXmlDetailOfVisionConnectPC = (json, opt_url, defaultPalette, resources)=>{
  const dataDetails = {'リソース':resources};

  dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data name="種族">${json.race || ''}</data>`,
    `        <data name="クラス">${json.class || ''}</data>`,
    `        <data name="スタイル1">${json.style1 || ''}</data>`,
    `        <data name="スタイル2">${json.style2 || ''}</data>`,
    `        <data name="年齢">${json.age || ''}</data>`,
    `        <data name="性別">${json.gender || ''}</data>`,
    `        <data name="瞳の色">${json.eye || ''}</data>`,
    `        <data name="肌の色">${json.skin || ''}</data>`,
    `        <data name="髪の色">${json.hair || ''}</data>`,
    `        <data name="身長">${json.height || ''}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);}

  let addedParam = {};
  dataDetails['能力値・戦闘値'] = [];
  for(let data of output.consts.VC_PARAMS){
    dataDetails['能力値・戦闘値'].push(`        <data name="${data.name}">${json[data.value] || 0}</data>`);
    addedParam[data.name] = 1;
  }

  dataDetails['その他のパラメータ'] = defaultPalette.parameters.map((param)=>{
    if(addedParam[param.label]){ return `` }
    return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
  });


  return dataDetails
};
