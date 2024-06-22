"use strict";

var output = output || {};

output._getBloodPathBloodArts = (json) => {
  let cursor = 1;
  const bloodartsData = [];
  while(json[`bloodarts${cursor}Name`]) {
    bloodartsData.push({
      name: '〈' + json[`bloodarts${cursor}Name`] + '〉',
      timing: json[`bloodarts${cursor}Timing`] || '',
      target: json[`bloodarts${cursor}Target`] || '',
      note: json[`bloodarts${cursor}Note`] || ''
    });
    cursor++;
  }
  return bloodartsData;
};
output._getBloodPathArts = (json) => {
  let cursor = 1;
  const artsData = [];
  while(json[`arts${cursor}Name`]) {
    artsData.push({
      name: '〈' + json[`arts${cursor}Name`] + '〉',
      timing: json[`arts${cursor}Timing`] || '',
      target: json[`arts${cursor}Target`] || '',
      cost: json[`arts${cursor}Cost`] || '',
      limited: json[`arts${cursor}Limited`] || '',
      note: json[`arts${cursor}Note`] || ''
    });
    cursor++;
  }
  return artsData;
};

output.generateCharacterTextOfBloodPathPC = (json) => {
  const result = [];

  result.push(`キャラクター名：${json.characterName}`);
  result.push('');
  
  result.push(`ファクター：${json.factor}`);
  if(json.factor === '人間'){
    result.push(`信念／職能：${json.factorCore || ''}／${json.factorStyle || ''}`);
  }
  else if(json.factor === '吸血鬼'){
    result.push(`起源／流儀：${json.factorCore || ''}／${json.factorStyle || ''}`);
  }
  result.push('');
  
  result.push(`年齢　　　：${json.age || ''}${json.ageApp ? "（外見年齢："+json.ageApp+"）" : ''}
性別　　　：${json.gender || ''}
所属　　　：${json.belong     || ''}${json.belongNote     ? '／'+json.belongNote     : ''}
過去　　　：${json.past       || ''}${json.pastNote       ? '／'+json.pastNote       : ''}
経緯　　　：${json.background || ''}${json.backgroundNote ? '／'+json.backgroundNote : ''}
喪失　　　：${json.missing    || ''}${json.missingNote    ? '／'+json.missingNote    : ''}
外見的特徴：${json.appearance || ''}${json.appearanceNote ? '／'+json.appearanceNote : ''}
住まい　　：${json.dwelling   || ''}${json.dwellingNote   ? '／'+json.dwellingNote   : ''}
使用武器　：${json.weapon     || ''}${json.weaponNote     ? '／'+json.weaponNote     : ''}`);
  result.push('');

  result.push('■能力値■\n');
  result.push(`練度：${json.level || ''}`);
  result.push('');
  if(json.factor === '人間'){
    result.push(`【♠技】：${(json.statusMain1 || '').padStart(2, ' ')}`);
    result.push(`【♣情】：${(json.statusMain2 || '').padStart(2, ' ')}`);
  }
  else if(json.factor === '吸血鬼'){
    result.push(`【♥血】：${(json.statusMain1 || '').padStart(2, ' ')}`);
    result.push(`【♦想】：${(json.statusMain2 || '').padStart(2, ' ')}`);
  }
  result.push(`【耐久値】：${json.endurance  || ''}`);
  result.push(`【先制値】：${json.initiative || ''}`);
  result.push('');
  result.push('');
  
  result.push('■傷号■\n');
  result.push(`［${json.scarName || ''}］`);
  result.push((json.scarNote || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));
  result.push('');
  result.push('');

  result.push('■血威■\n');
  const bloodartsData = output._getBloodPathBloodArts(json);
  result.push(output._convertList(bloodartsData, output.consts.BLOODARTS_COLUMNS, ' / '));
  result.push('');
  result.push('');

  result.push('■特技■\n');
  const artsData = output._getBloodPathArts(json);
  result.push(output._convertList(artsData, output.consts.ARTS_COLUMNS, ' / '));
  result.push('');
  result.push('');
  
  result.push('■血契■\n');
  result.push(`キャラクター名：${json.partner1Name}`);
  if(json.factor === '人間'){
    result.push(`起源／流儀：${json.partner1Factor || ''}
外見年齢／実年齢：${json.partner1Age || ''}
性別：${json.partner1Gender || ''}
欠落：${json.partner1Missing || ''}`);
  }
  else if(json.factor === '吸血鬼'){
    result.push(`信念／職能：${json.partner1Factor || ''}
年齢：${json.partner1Age || ''}
性別：${json.partner1Gender || ''}
喪失：${json.partner1Missing || ''}`);
  }
  result.push('');
  result.push(`［痕印］
位置：${json.fromPartner1SealPosition || ''}
形状：${json.fromPartner1SealShape || ''}
相手からの感情1：${json.fromPartner1Emotion1 || ''}
相手からの感情2：${json.fromPartner1Emotion2 || ''}`);
  result.push('');
  result.push('');
  
  if(json.partner2On){
    if(json.factor === '人間'){
      result.push(`■血契２■\n
キャラクター名：${json.partner2Name}
起源／流儀：${json.partner2Factor || ''}
外見年齢／実年齢：${json.partner2Age || ''}
性別：${json.partner2Gender || ''}
欠落：${json.partner2Missing || ''}`);
      result.push(`［痕印］
位置：${json.fromPartner2SealPosition || ''}
形状：${json.fromPartner2SealShape || ''}
相手からの感情1：${json.fromPartner2Emotion1 || ''}
相手からの感情2：${json.fromPartner2Emotion2 || ''}`);
    }
    else if(json.factor === '吸血鬼'){
      result.push(`■連血鬼■\n
キャラクター名：${json.partner2Name}
起源／流儀：${json.partner2Factor || ''}
年齢：${json.partner2Age || ''}
性別：${json.partner2Gender || ''}
欠落：${json.partner2Missing || ''}
相手からの感情1：${json.fromPartner2Emotion1 || ''}
相手からの感情2：${json.fromPartner2Emotion2 || ''}`);
    }
    result.push('');
    result.push('');
  }

  result.push('■その他■');
  result.push((json.freeNote || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));
  
  return result.join('\n');
};
