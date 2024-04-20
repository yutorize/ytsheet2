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

  let addedParam = output.consts.VC_PARAMS;
  dataDetails['能力値'] = [
    `        <data name="バイタリティ">${json.vitality || 0}</data>`,
    `        <data name="テクニック">${json.technic || 0}</data>`,
    `        <data name="クレバー">${json.clever || 0}</data>`,
    `        <data name="カリスマ">${json.carisma || 0}</data>`,
  ];
  dataDetails['戦闘値'] = [
    `        <data name="命中値">${json.battleTotalAcc || 0}</data>`,
    `        <data name="詠唱値">${json.battleTotalSpl || 0}</data>`,
    `        <data name="回避値">${json.battleTotalEva || 0}</data>`,
    `        <data name="攻撃値">${json.battleTotalAtk || 0}</data>`,
    `        <data name="意志値">${json.battleTotalDet || 0}</data>`,
    `        <data name="物防値">${json.battleTotalDef || 0}</data>`,
    `        <data name="魔防値">${json.battleTotalMdf || 0}</data>`,
    `        <data name="行動値">${json.battleTotalIni || 0}</data>`,
    `        <data name="耐久値">${json.battleTotalStr || 0}</data>`,
  ];

    dataDetails['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
      if(addedParam[param.label]){ return `` }
      return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
    });


  return dataDetails
};
