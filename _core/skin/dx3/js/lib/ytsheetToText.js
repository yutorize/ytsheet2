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

output._convertDoubleCrossStatus = (json, s, showGrowth = true) => {
  const result = [];
  result.push(`【${s.name}】：${json['sttTotal' + s.column]}${showGrowth ? ` (内成長：${json['sttGrow' + s.column] || 0})` : ''}`);
  s.skills.forEach((skill)=>{
    result.push(`〈${skill.name}〉：${json['skillTotal' + skill.column] || 0} / 判定 ${json['sttTotal' + s.column]}r+${json['skillTotal' + skill.column] || 0}`);
  });
  let cursor = 1;
  if(json[`skill${s.extendableSkill.column}${cursor}`]) {
    while(json[`skill${s.extendableSkill.column}${cursor}Name`]) {
      result.push('〈' + json[`skill${s.extendableSkill.column}${cursor}Name`] +`〉：${json[`skillTotal${s.extendableSkill.column}${cursor}`] || 0} / 判定 ${json['sttTotal' + s.column]}r+${json[`skillTotal${s.extendableSkill.column}${cursor}`] || 0}`);
      cursor++;
    }
  } else {
    result.push(`〈${s.extendableSkill.name}〉：0 / 判定 ${json['sttTotal' + s.column]}r+0`);
  }

  result.push('');
  return result.join('\n');
};

output._getDoubleCrossEffects = (json) => {
  let cursor = 1;
  const effectData = [];
  while(json[`effect${cursor}Name`]) {
    effectData.push({
      name: '《' + json[`effect${cursor}Name`] + '》',
      level: json[`effect${cursor}Lv`] || '1',
      timing: json[`effect${cursor}Timing`] || '',
      difficulty: json[`effect${cursor}Dfclty`] || '',
      target: json[`effect${cursor}Target`] || '',
      range: json[`effect${cursor}Range`] || '',
      cost: json[`effect${cursor}Encroach`] || '',
      limitation: json[`effect${cursor}Restrict`] || '',
      note: json[`effect${cursor}Note`] || ''
    });
    cursor++;
  }
  return effectData;
};

output._getDoubleCrossCombos = (json) => {
  let cursor = 1;
  const comboData = [];
  while(json[`combo${cursor}Name`]) {
    for(let limitationCursor = 1; limitationCursor <= 5; limitationCursor++) {
      if(limitationCursor > 1 && !json[`combo${cursor}Condition${limitationCursor}`]) {
        continue;
      }
      comboData.push({
        name: json[`combo${cursor}Name`] || '',
        combination: (json[`combo${cursor}Combo`] || '').trim(),
        skill: (json[`combo${cursor}Skill`] || '').trim(),
        hit: (json[`combo${cursor}Dice${limitationCursor}`]) ? '(' + json[`combo${cursor}Dice${limitationCursor}`] + ')dx' + '+(' + (json[`combo${cursor}Fixed${limitationCursor}`] || '0') + ')' + '@' + (json[`combo${cursor}Crit${limitationCursor}`] || 10) : '',
        attack: json[`combo${cursor}Atk${limitationCursor}`] || '',
        target: (json[`combo${cursor}Target`] || '').trim(),
        range: (json[`combo${cursor}Range`] || '').trim(),
        cost: json[`combo${cursor}Encroach`] || '0',
        limitation: (json[`combo${cursor}Condition${limitationCursor}`] || '').trim(),
        note: json[`combo${cursor}Note`] || ''
      });
    }
    cursor++;
  }
  return comboData;
};

output._getDoubleCrossLoises = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`lois${cursor}Name`]) {
    data.push({
      name: json[`lois${cursor}Name`],
      relation: json[`lois${cursor}Relation`] || '',
      positive: json[`lois${cursor}EmoPosi`] || '',
      negative: json[`lois${cursor}EmoNega`] || '',
      color: json[`lois${cursor}Color`] || '',
      condition: json[`lois${cursor}State`],
      note: json[`lois${cursor}Note`] || ''
    });
    cursor++;
  }
  return data;
};

output._getDoubleCrossMemories = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`memory${cursor}Gain`]) {
    data.push({
      name: json[`memory${cursor}Name`] || '',
      relation: json[`memory${cursor}Relation`] || '',
      emotion: json[`memory${cursor}Emo`] || '',
      note: json[`memory${cursor}Note`] || ''
    });
    cursor++;
  }
  return data;
};

output._getDoubleCrossWeapons = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`weapon${cursor}Name`]) {
    data.push({
      name: json[`weapon${cursor}Name`] || '',
      cost: json[`weapon${cursor}Stock`] || '',
      experience: json[`weapon${cursor}Exp`] || '',
      type: json[`weapon${cursor}Type`] || '',
      skill: json[`weapon${cursor}Skill`] || '',
      hit: json[`weapon${cursor}Acc`] || '',
      attack: json[`weapon${cursor}Atk`] || '',
      guard: json[`weapon${cursor}Guard`] || '',
      range: json[`weapon${cursor}Range`] || '',
      note: json[`weapon${cursor}Note`] || ''
    });
    cursor++;
  }
  return data;
};

output._getDoubleCrossArmors = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`armor${cursor}Name`]) {
    data.push({
      name: json[`armor${cursor}Name`] || '',
      cost: json[`armor${cursor}Stock`] || '',
      experience: json[`armor${cursor}Exp`] || '',
      type: json[`armor${cursor}Type`] || '',
      value: json[`armor${cursor}Armor`] || '',
      move: json[`armor${cursor}Initiative`] || '',
      dodge: json[`armor${cursor}Dodge`] || '',
      note: json[`armor${cursor}Note`] || ''
    });
    cursor++;
  }
  return data;
};

output._getDoubleCrossVehicles = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`vehicle${cursor}Name`]) {
    data.push({
      name: json[`vehicle${cursor}Name`] || '',
      skill: json[`vehicle${cursor}Skill`] || '',
      move: json[`vehicle${cursor}Initiative`] || '',
      attack: json[`vehicle${cursor}Atk`] || '',
      value: json[`vehicle${cursor}Armor`] || '',
      dash: json[`vehicle${cursor}Dash`] || '',
      note: json[`vehicle${cursor}Note`] || ''
    });
    cursor++;
  }
  return data;
};

output._getDoubleCrossItems = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`item${cursor}Name`]) {
    data.push({
      name: json[`item${cursor}Name`] || '',
      cost: json[`item${cursor}Stock`] || '',
      experience: json[`item${cursor}Exp`] || '',
      type: json[`item${cursor}Type`] || '',
      skill: json[`item${cursor}Skill`] || '',
      note: json[`item${cursor}Note`] || ''
    });
    cursor++;
  }
  return data;
};

output.generateCharacterTextOfDoubleCross3PC = (json) => {
  const result = [];

  result.push(`キャラクター名：${json.characterName || ''}
コードネーム：${json.aka || ''}
年齢：${json.age || ''}
性別：${json.gender || ''}
身長：${json.height || ''}
体重：${json.weight || ''}`);
  result.push('');

  result.push(`ワークス　　：${json.works || ''}
カヴァー　　：${json.cover || ''}
シンドローム：${json.syndrome1 || ''}${json.syndrome2 ? '、'+json.syndrome2 : ''}${json.syndrome3 ? '、'+json.syndrome3 : ''}`);
  result.push('');

  result.push(`■ライフパス■
覚醒：${json.lifepathAwaken || ''}
衝動：${json.lifepathImpulse || ''}`);
  result.push('');

  result.push('■能力値と技能■\n');
  output.consts.DX3_STATUS.forEach((statusPattern)=>{
    result.push(output._convertDoubleCrossStatus(json, statusPattern));
  });
  result.push('');
  result.push(`【ＨＰ】　　　${String(json.maxHpTotal).padStart(3, ' ')}
【侵蝕基本値】${String(json.baseEncroach).padStart(3, ' ')}％
【行動値】　　${String(json.initiativeTotal).padStart(3, ' ')}
【戦闘移動】　${String(json.moveTotal).padStart(3, ' ')}ｍ`);
  result.push('');

  result.push('■エフェクト■\n');
  const effectData = output._getDoubleCrossEffects(json);
  result.push(output._convertList(effectData, output.consts.EFFECT_COLUMNS, ' / '));
  result.push('');
  result.push('');

  result.push('■コンボ■\n');
  const comboData = output._getDoubleCrossCombos(json);
  result.push(output._convertList(comboData, output.consts.COMBO_COLUMNS, ' / '));
  result.push('');
  result.push('');

  result.push('■アイテム■');
  result.push('');

  result.push('・武器');
  const weaponData = output._getDoubleCrossWeapons(json);
  result.push(output._convertList(weaponData, output.consts.WEAPON_COLUMNS, ' / '));
  result.push('');

  result.push('・防具');
  const armorData = output._getDoubleCrossArmors(json);
  result.push(output._convertList(armorData, output.consts.ARMOR_COLUMNS, ' / '));
  result.push('');

  result.push('・その他');
  const itemData = output._getDoubleCrossItems(json);
  result.push(output._convertList(itemData, output.consts.ITEM_COLUMNS, ' / '));
  result.push('');

  result.push(`【常備化ポイント】${(String(json.stockTotal || 2)).padStart(4, ' ')} pt`);
  result.push(`【財産ポイント】　${(String(json.savingTotal || 2)).padStart(4, ' ')} pt`);
  result.push('');
  result.push('');

  result.push('■ロイス■');
  const loisData = output._getDoubleCrossLoises(json);
  result.push(output._convertList(loisData, output.consts.LOISES_COLUMNS, ' / '));
  result.push('');
  result.push('');

  result.push('■メモリー■');
  const memoryData = output._getDoubleCrossMemories(json);
  result.push(output._convertList(memoryData, output.consts.MEMORIES_COLUMNS, ' / '));
  result.push('');
  result.push('');

  result.push('■その他■');
  result.push((json.freeNote || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));

  return result.join('\n');
};


output._formatDoubleCrossEnemyName = (name, brackets) => {
  const isBracketed = /^(?:\(.*\)|\[.*\]|\{.*\}|（.*）|［.*］|｛.*｝|「.*」|『.*』|【.*】|〔.*〕|〈.*〉|《.*》)$/s.test(name);
  return isBracketed ? name : `${brackets[0]}${name}${brackets[1]}`;
};

output._convertDoubleCrossEnemyList = (list, columns) => {
  const result = [];
  for(const data of list) {
    const details = [data.name];
    for(const key in columns) {
      if(key === 'name' || key === 'note') { continue; }
      details.push(`${columns[key]}：${data[key] ?? ''}`);
    }
    result.push(details.join('　'), data.note || '');
  }
  return result.join('\n');
};

output._convertDoubleCrossEnemyEquipment = (json, type, columns) => {
  const fields = {
    skill: 'Skill', hit: 'Acc', attack: 'Atk', guard: 'Guard',
    move: 'Initiative', dodge: 'Dodge', value: 'Armor', dash: 'Dash'
  };
  const result = [];
  for(let cursor = 1; cursor <= Number(json[`${type}Num`] || 0) || json[`${type}${cursor}Name`]; cursor++) {
    const prefix = `${type}${cursor}`;
    if(!json[`${prefix}Name`]) { continue; }
    const data = { name: json[`${prefix}Name`], note: json[`${prefix}Note`] || '' };
    for(const key in fields) {
      data[key] = json[prefix + fields[key]] ?? '';
    }
    result.push(data);
  }
  return output._convertDoubleCrossEnemyList(result, columns);
};

output._convertDoubleCrossEnemyCombos = (json) => {
  const result = [];
  for(let cursor = 1; cursor <= Number(json.comboNum || 0) || json[`combo${cursor}Name`]; cursor++) {
    const prefix = `combo${cursor}`;
    if(!json[`${prefix}Name`]) { continue; }
    const lines = [
      `▼${json[`${prefix}Name`]}`,
      (json[`${prefix}Combo`] || '').trim(),
      `タイミング：${json[`${prefix}Timing`] || ''}`,
      `技能：${json[`${prefix}Skill`] || ''}　難易度：${json[`${prefix}Dfclty`] || ''}`,
      `対象：${json[`${prefix}Target`] || ''}　射程：${json[`${prefix}Range`] || ''}`
    ];
    const rows = [['条件', 'ダイス', 'C値', '達成値修正', '攻撃力']];
    for(let condition = 1; condition <= 5; condition++) {
      if(condition > 1 && !json[`${prefix}Condition${condition}`]) { continue; }
      rows.push(['Condition', 'Dice', 'Crit', 'Fixed', 'Atk'].map((field) => String(json[`${prefix}${field}${condition}`] ?? '')));
    }
    const widths = rows[0].map((_, column) => Math.max(...rows.map((row) => output.length(row[column]))));
    lines.push(...rows.map((row) => row.map((value, column) => value + ' '.repeat(widths[column] - output.length(value))).join(' / ')));
    result.push(lines.join('\n'));
  }
  return result.join('\n\n');
};

output.generateCharacterTextOfDoubleCross3Enemy = (json) => {
  const result = [];

  result.push(`エネミー名：${json.enemyName || ''}`);
  if(json.aka) { result.push(`コードネーム：${json.aka}`); }
  result.push(`種別：${json.enemyType || ''}
ステージ：${json.stage || ''}
データ製作者：${json.author || ''}
シンドローム：${json.syndrome1 || ''}${json.syndrome2 ? '、'+json.syndrome2 : ''}${json.syndrome3 ? '、'+json.syndrome3 : ''}`);
  result.push('');

  result.push('◆能力値\n');
  output.consts.DX3_STATUS.forEach((statusPattern) => {
    const skills = statusPattern.skills.map((skill) => `〈${skill.name}〉${json['skillTotal' + skill.column] || 0}`);
    const skillColumn = statusPattern.extendableSkill.column;
    for(let cursor = 1; cursor <= Number(json[`skill${skillColumn}Num`] || 0) || json[`skill${skillColumn}${cursor}Name`]; cursor++) {
      const name = json[`skill${skillColumn}${cursor}Name`];
      if(name) {
        skills.push(`${output._formatDoubleCrossEnemyName(name, '〈〉')}${json[`skillTotal${skillColumn}${cursor}`] || 0}`);
      }
    }
    if(skills.length === statusPattern.skills.length) {
      skills.push(`〈${statusPattern.extendableSkill.name}〉0`);
    }
    result.push(`【${statusPattern.name}】${json['sttTotal' + statusPattern.column] ?? 0}　${skills.join(' ')}`);
  });
  result.push('');
  result.push(`【ＨＰ】　${String(json.maxHpTotal ?? '').padStart(3, ' ')}
【行動値】${String(json.initiativeTotal ?? '').padStart(3, ' ')}
【装甲値】${String(json.armorTotal ?? '').padStart(3, ' ')}
【侵蝕率】${String(json.encroachTotal ?? '').padStart(3, ' ')}％`);
  result.push('');

  result.push('◆エフェクト\n');
  const effects = [];
  const dLoises = [];
  const eLoises = [];
  const perks = [];
  for(let cursor = 1; cursor <= Number(json.effectNum || 0) || json[`effect${cursor}Name`]; cursor++) {
    const name = json[`effect${cursor}Name`];
    if(!name) { continue; }
    const type = json[`effect${cursor}Type`];
    if(type === 'dlois' || type === 'elois') {
      const loises = type === 'dlois' ? dLoises : eLoises;
      loises.push(output._formatDoubleCrossEnemyName(name, '「」'));
    }
    else if(type === 'perk') {
      const level = json[`effect${cursor}Lv`];
      perks.push(`${output._formatDoubleCrossEnemyName(name, '《》')}${level === '' ? 1 : (level ?? 1)}`);
    }
    else {
      const level = json[`effect${cursor}Lv`];
      effects.push(`${output._formatDoubleCrossEnemyName(name, '《》')}${level === '' ? 1 : (level ?? 1)}`);
    }
  }
  result.push(effects.join('、'));
  if(perks.length)   { result.push('▼パーク',  perks.join('、')); }
  if(dLoises.length) { result.push('▼Dロイス', dLoises.join('、')); }
  if(eLoises.length) { result.push('▼Eロイス', eLoises.join('、')); }
  result.push('');

  result.push('◆コンボ\n');
  result.push(output._convertDoubleCrossEnemyCombos(json));
  result.push('');

  result.push('◆装備\n');
  result.push(output._convertDoubleCrossEnemyEquipment(json, 'weapon', output.consts.ENEMY_WEAPON_COLUMNS));
  result.push('');

  result.push(output._convertDoubleCrossEnemyEquipment(json, 'armor', output.consts.ENEMY_ARMOR_COLUMNS));
  result.push('');

  result.push(output._convertDoubleCrossEnemyEquipment(json, 'vehicle', output.consts.ENEMY_VEHICLE_COLUMNS));
  result.push('');

  result.push(output._convertDoubleCrossEnemyEquipment(json, 'item', output.consts.ENEMY_ITEM_COLUMNS));
  result.push('');

  result.push('◆解説・戦闘プランなど');
  result.push(json.freeNote || '');

  return result.join('\n').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"');
};
