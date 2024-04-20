"use strict";

var output = output || {};

output.generateUdonariumXmlDetailOfKizunaBulletPC = (json, opt_url, defaultPalette, resources)=>{
	const dataDetails = {'リソース':resources};

  const typeH = json.class === 'ハウンド' ? 1 : 0;
  
  dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data name="種別">${json.class || ''}</data>`,
    `        <data name="ネガイ(表)">${json.negaiOutside || ''}</data>`,
    `        <data name="ネガイ(裏)">${json.negaiInside || ''}</data>`,
    `        <data name="年齢">${json.age || ''}</data>`,
    `        <data name="性別">${json.gender || ''}</data>`,
    `        <data name="過去">${json.past || ''}</data>`,
    `        <data name="${typeH ? '遭遇':'経緯'}">${json.background || ''}</data>`,
    `        <data name="外見の特徴">${json.appearance || ''}</data>`,
    `        <data name="${typeH ? 'ケージ':'住居'}">${json.dwelling || ''}</data>`,
    `        <data name="好きなもの">${json.like || ''}</data>`,
    `        <data name="嫌いなもの">${json.dislike || ''}</data>`,
    `        <data name="得意なこと">${json.good || ''}</data>`,
    `        <data name="苦手なこと">${json.notgood || ''}</data>`,
    `        <data name="喪失">${json.missing || ''}</data>`,
    `        <data name="${typeH ? 'リミッターの影響':'ペアリングの副作用'}">${json.sideeffect || ''}</data>`,
    `        <data name="${typeH ? '決意':'使命'}">${json.resolution || ''}</data>`,
    `        <data name="所属">${json.belong || ''}</data>`,
    `        <data name="おもな武器">${json.weapon || ''}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);}

	return dataDetails
};