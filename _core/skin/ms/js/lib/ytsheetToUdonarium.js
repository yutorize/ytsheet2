"use strict";

var output = output || {};

output.generateUdonariumXmlDetailOfMamonoScramblePC = (json, opt_url, defaultPalette, resources)=>{
  const dataDetails = {'リソース':resources};

  dataDetails['能力値'] = [
    `        <data name="身体">${json.statusPhysical || ''}</data>`,
    `        <data name="異質">${json.statusSpecial || ''}</data>`,
    `        <data name="社会">${json.statusSocial || ''}</data>`,
  ]
  dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data name="分類名">${json.taxa || ''}</data>`,
    `        <data name="出身地">${json.home || ''}</data>`,
    `        <data name="根源">${json.origin || ''}</data>`,
    `        <data name="クラン">${json.clan || ''}</data>`,
    `        <data name="クランへの感情">${json.clanEmotion || ''}</data>`,
    `        <data name="住所">${json.address || ''}</data>`,
    `        <data type="note" name="その他">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);}

  return dataDetails
};