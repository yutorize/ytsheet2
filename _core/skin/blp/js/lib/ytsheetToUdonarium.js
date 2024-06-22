"use strict";

var output = output || {};

output.generateUdonariumXmlDetailOfBloodPathPC = (json, opt_url, defaultPalette, resources)=>{
  const dataDetails = {'リソース':resources};

  dataDetails['能力値'] = [
    `        <data name="練度">${json.level || 0}</data>`,
  ]
  if(json.factor === '人間'){
    dataDetails['能力値'].push(
      `        <data name="技">${json.statusMain1 || 0}</data>`,
      `        <data name="情">${json.statusMain2 || 0}</data>`,
    );
  }
  else if(json.factor === '吸血鬼'){
    dataDetails['能力値'].push(
      `        <data name="心">${json.statusMain1 || 0}</data>`,
      `        <data name="想">${json.statusMain2 || 0}</data>`,
    );
  }

  dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data name="ファクター">${json.factor || ''}／${json.factorCore || ''}／${json.factorStyle || ''}</data>`,
    `        <data name="年齢">${json.age || ''}${json.ageApp ? '（外見年齢：'+json.ageApp+'）' : ''}</data>`,
    `        <data name="性別">${json.gender || ''}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);}

  return dataDetails
};