"use strict";

var output = output || {};

output._getKizunaBulletKizuna = (json) => {
  let number = 1;
  const kizunaData = [];
  for(let cursor = 1; cursor <= json.kizunaNum; cursor++) {
    if(json[`kizuna${cursor}Name`] || json[`kizuna${cursor}Note`] || json[`kizuna${cursor}Hibi`]){
      kizunaData.push({
        num: `${cursor}`,
        name: json[`kizuna${cursor}Name`] || '',
        note: json[`kizuna${cursor}Note`] || '',
        hibi: json[`kizuna${cursor}Hibi`] ? '✔':'',
        ware: json[`kizuna${cursor}Ware`] ? '✔':''
      });
      number++;
    }
  }
  return kizunaData;
};

output._getKizunaBulletKizuato = (json) => {
	let cursor = 1;
	const kizuatoDate = [];
	while(json[`kizuato${cursor}Name`]) {
		['Drama','Battle'].forEach((type)=>{
			kizuatoDate.push({
				name: (type === 'Drama' ? '《'+(json[`kizuato${cursor}Name`]||'')+'》' : ''),
				type: (type === 'Drama' ? 'ドラマ' : '　決戦')+'効果',
				timing: (json[`kizuato${cursor+type}Timing`] || '').trim(),
				target: (json[`kizuato${cursor+type}Target`] || '').trim(),
				cost: ((type === 'Drama' ? json[`kizuato${cursor}DramaHitogara`] : json[`kizuato${cursor}BattleCost`]) || '').trim(),
				limited: (json[`kizuato${cursor+type}Limited`] || '').trim(),
				note: json[`kizuato${cursor+type}Note`] || ''
			});
		});
		cursor++;
	}
	return kizuatoDate;
};

output.generateCharacterTextOfKizunaBulletPC = (json) => {
  const result = [];
  
  result.push(`キャラクター名：${json.characterName}
種別　　　：${json.class || ''}
ネガイ(表)：${json.negaiOutside || ''}
ネガイ(裏)：${json.negaiInside || ''}

【耐久値】：${json.endurance || 0}
【作戦力】：${json.operation || 0}

■ヒトガラ■

年齢　　　：${json.age || ''}
性別　　　：${json.gender || ''}
所属　　　：${json.belong || ''}
過去　　　：${json.past   || ''}
${json.type === 'オーナー' ? '経緯' : '遭遇'}　　　：${json.background || ''}
外見の特徴：${json.appearance || ''}
${json.type === 'オーナー' ? '住居　' : 'ケージ'}　　：${json.dwelling || ''}
好きなもの：${json.like    || ''}
嫌いなもの：${json.dislike || ''}
得意なこと：${json.good    || ''}
苦手なこと：${json.notgood || ''}
喪失　　　：${json.missing || ''}
${json.type === 'オーナー' ? 'ペアリングの副作用' : 'リミッターの影響'}：${json.sideeffect || ''}
${json.type === 'オーナー' ? '使命' : '決意'}　　　：${json.resolution || ''}
おもな武器：${json.weapon  || ''}`);
  result.push('');

  result.push('■キズナ■\n');
  const kizunaData = output._getKizunaBulletKizuna(json);
  result.push(output._convertList(kizunaData, output.consts.KIZUNA_COLUMNS, ' / '));
  result.push('');
  result.push('');

  result.push('■キズアト■\n');
  const kizuatoData = output._getKizunaBulletKizuato(json);
  result.push(output._convertList(kizuatoData, output.consts.KIZUATO_COLUMNS, ' / '));
  result.push('');
  result.push('');
  
  result.push(`■パートナー１■\n
キャラクター名：${json.partner1Name}
年齢　　　：${json.partner1Age || ''}
性別　　　：${json.partner1Gender || ''}
ネガイ(表)：${json.partner1NegaiOutside || ''}
ネガイ(裏)：${json.partner1NegaiInside || ''}

自分のマーカーの位置：${json.fromPartner1MarkerPosition || ''}
自分のマーカーの色　：${json.fromPartner1MarkerColor || ''}
相手からの感情1：${json.fromPartner1Emotion1 || ''}
相手からの感情2：${json.fromPartner1Emotion2 || ''}`);
  result.push('');
  result.push('');
  
  if(json.partner2On){
    if(json.factor === 'オーナー'){
      result.push(`■パートナー２■\n
キャラクター名：${json.partner2Name}
年齢　　　：${json.partner2Age || ''}
性別　　　：${json.partner2Gender || ''}
ネガイ(表)：${json.partner2NegaiOutside || ''}
ネガイ(裏)：${json.partner2NegaiInside || ''}

自分のマーカーの位置：${json.fromPartner2MarkerPosition || ''}
自分のマーカーの色　：${json.fromPartner2MarkerColor || ''}
相手からの感情1：${json.fromPartner2Emotion1 || ''}
相手からの感情2：${json.fromPartner2Emotion2 || ''}`);
    }
    else if(json.factor === 'ハウンド'){
      result.push(`■アナザー■\n
キャラクター名：${json.partner2Name}
年齢　　　：${json.partner2Age || ''}
性別　　　：${json.partner2Gender || ''}
ネガイ(表)：${json.partner2NegaiOutside || ''}
ネガイ(裏)：${json.partner2NegaiInside || ''}

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