"use strict";

var output = output || {};

output.generateCharacterTextOfVisionConnectPC = (json) => {
	const result = [];
  result.push(`キャラクター名：${json.characterName}

種族　　：${json.race}
クラス　：${json.class}
スタイル：${json.style1}／${json.style2}

ＨＰ　　：${json.hpMax}
スタミナ：${json.staminaMax}

■能力値■
バイタリティ：${json.vitality}
テクニック　：${json.technic}
クレバー　　：${json.clever}
カリスマ　　：${json.carisma}

■特技■
${json.speciality1Name || ''} / ${json.speciality1Note || ''}
${json.speciality2Name || ''} / ${json.speciality2Note || ''}
`);
	result.push('■グッズ■');
	result.push(output._convertList(output.getGoods(json), output.consts.GOODS_COLUMNS, ' / '));
	result.push('');
	result.push('■アイテム■');
	result.push(output._convertList(output.getItems(json), output.consts.GOODS_COLUMNS, ' / '));
	result.push('');
	result.push('■戦闘値■');
	result.push(output._convertList(output.getBattles(json), output.consts.BATTLE_COLUMNS, ' | '));
	result.push('\n');
	result.push('■メモ■');
  result.push((json.freeNote || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));
	result.push('\n');
	result.push('■履歴■');
  result.push((json.freeHistory || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));

	return result.join('\n');
};

output.getGoods = (json) => {
  let number = 1;
  const data = [];
  for(let cursor = 1; cursor <= json.goodsNum; cursor++) {
    if(json[`goods${cursor}Name`] || json[`goods${cursor}Type`] || json[`goods${cursor}Note`]){
      data.push({
        name: json[`goods${cursor}Name`] || '',
        type: json[`goods${cursor}Type`] || '',
        note: json[`goods${cursor}Note`] || '',
      });
      number++;
    }
  }
  return data;
};

output.getItems = (json) => {
  const data = [];
  for(let cursor = 1; cursor <= json.goodsNum; cursor++) {
    if(json[`item${cursor}Name`] || json[`item${cursor}Type`] || json[`item${cursor}Lv`] || json[`item${cursor}Note`]){
      data.push({
        name: json[`item${cursor}Name`] || '',
        type: json[`item${cursor}Type`] || '',
        lv  : json[`item${cursor}Lv`] || '',
        note: json[`item${cursor}Note`] || '',
      });
    }
  }
  return data;
};

output.getBattles = (json) => {
  const data = [];
  const list = {
    'Base':'基本戦闘値',
    'Race':'種族特性：'+(json.battleRaceName || ''),
    'Subtotal':'小計',
    'Weapon':'武器：'+(json.battleWeaponName || ''),
    'Head':'頭防具：'+(json.battleHeadName   || ''),
    'Body':'胴防具：'+(json.battleBodyName   || ''),
    'Acc1':'装飾品：'+(json.battleAcc1Name   || ''),
    'Acc2':'装飾品：'+(json.battleAcc2Name   || ''),
    'Other':'その他修正',
    'Total':'合計',
  }
  for(let cursor in list) {
    if(cursor === 'Subtotal' || cursor === 'Weapon' || cursor === 'Total'){
      data.push('-');
    }
    data.push({
      name: list[cursor],
      acc : json[`battle${cursor}Acc`] || '',
      spl : json[`battle${cursor}Spl`] || '',
      eva : json[`battle${cursor}Eva`] || '',
      atk : json[`battle${cursor}Atk`] || '',
      det : json[`battle${cursor}Det`] || '',
      def : json[`battle${cursor}Def`] || '',
      mdf : json[`battle${cursor}Mdf`] || '',
      ini : json[`battle${cursor}Ini`] || '',
      str : json[`battle${cursor}Str`] || '',
    });
  }
  return data;
};
