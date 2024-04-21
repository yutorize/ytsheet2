/* MIT License

Copyright 2020 @Shunshun94

Customize & Refactoring by @yutorize

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
"use strict";

var output = output || {};

output.generateUdonariumXmlDetailOfSwordWorld2Enemy = (json, opt_url, defaultPalette, resources)=>{
  const dataDetails = {'リソース':resources};
  
  dataDetails['能力値'] = defaultPalette.parameters.map((param)=>{
    return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
  });
  
  dataDetails['情報'] = [
    `        <data type="note" name="特殊能力">${(json.skills || '').replace(/&lt;br&gt;/g, '\n')}</data>`,
    `        <data type="note" name="説明">${(json.description || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`) }

  dataDetails['戦利品'] = [];
  for(let num = 1; num <= json.lootsNum; num++){
    dataDetails['戦利品'].push(`        <data name="${json[`loots${num}Num`]}">${json[`loots${num}Item`]}</data>`,)
  }

  return dataDetails
};

output.generateUdonariumXmlDetailOfSwordWorld2PC = (json, opt_url, defaultPalette, resources)=>{
  const dataDetails = {'リソース':resources};

  dataDetails['リソース'].push(
    `        <data type="numberResource" currentValue="0" name="1ゾロ">10</data>`,
    `        <data type="numberResource" currentValue="${json.sin || 0}" name="穢れ度">5</data>`,
    `        <data name="所持金">${json.moneyTotal}</data>`,
    `        <data name="残名誉点">${json.honor}</data>`
  )
  dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data name="種族">${json.race || '?'}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
  ];
  if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`) }

  const addToStr = (val)=>{
    if(val) {
      if(Number(val) < 0) {
        return `${val}`;
      } else {
        return `+${val}`;
      }
    } else {
      return '';
    }
  };
  dataDetails['能力値'] = [
    `        <data name="器用度">${json.sttDex}${addToStr(json.sttAddA)}</data>`,
    `        <data name="敏捷度">${json.sttAgi}${addToStr(json.sttAddB)}</data>`,
    `        <data name="筋力">${json.sttStr}${addToStr(json.sttAddC)}</data>`,
    `        <data name="生命力">${json.sttVit}${addToStr(json.sttAddD)}</data>`,
    `        <data name="知力">${json.sttInt}${addToStr(json.sttAddE)}</data>`,
    `        <data name="精神力">${json.sttMnd}${addToStr(json.sttAddF)}</data>`
  ];
  
  let addedParam = {
    '器用度':1,
    '敏捷度':1,
    '筋力':1,
    '生命力':1,
    '知力':1,
    '精神力':1,
    '冒険者レベル':1,
  }
  dataDetails['技能'] = [`        <data name="冒険者レベル">${json.level}</data>`];
  for(const name of SET.classNames){
    const level = json['lv'+SET.class[name].id];
    if(!level) continue;
    dataDetails['技能'].push(`        <data name="${name}">${level}</data>`);
    addedParam[name] = 1;
  }
  for(let num = 1; num <= json.commonClassNum; num++){
    const name = (json['commonClass'+num]||'').replace(/[(（].+?[）)]$/,'');
    const level = json['lvCommon'+num];
    if(!name) continue;
    dataDetails['技能'].push(`        <data name="${name}">${level}</data>`);
    addedParam[name] = 1;
  }
  dataDetails['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
    if(addedParam[param.label]){ return ''; }

    if(/修正$/.test(param.label) || /^(必殺効果|クリレイ|魔法C)$/.test(param.label)){
      addedParam[param.label] = 1;
      return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`;
    }
  });
  dataDetails['パラメータ'] = defaultPalette.parameters.map((param)=>{
    if(addedParam[param.label]){ return ''; }
    return `        <data name="${param.label}">${param.value}</data>`;
  });
  
  return dataDetails
};