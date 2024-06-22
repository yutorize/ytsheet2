"use strict";

var output = output || {};

output._convertArianrhodStatus = (json, s) => {
  const result = [];
  result.push(
    `【${s.name}】`
    + ( String(json[`stt${s.column}Base`    ] || '').padStart(4, ' ') ) + '  /3='
    + ( String(json[`stt${s.column}Bonus`   ] || '').padStart(5, ' ') ) + ' +'
    + ( String(json[`stt${s.column}Main`    ] || '').padStart(5, ' ') ) + ' +'
    + ( String(json[`stt${s.column}Support` ] || '').padStart(5, ' ') ) + ' +'
    + ( String(json[`stt${s.column}Add`     ] || '').padStart(5, ' ') ) + ' ='
    + ( String(json[`stt${s.column}Total`   ] || '').padStart(5, ' ') ) + ' +'
    + ( String(json[`roll${s.column}Add`    ] || '').padStart(5, ' ') ) + ' ='
    + ( String(json[`roll${s.column}`       ] || '').padStart(5, ' ') ) + '+'
    +   String(json[`roll${s.column}Dice`] || '')+'D'
  );

  return result.join('\n');
};

output._getArianrhodSkills = (json) => {
  let cursor = 1;
  const skillData = [];
  while(json[`skill${cursor}Name`]) {
    skillData.push({
      name: '《' + json[`skill${cursor}Name`] + '》',
      level: json[`skill${cursor}Lv`] || ' ',
      timing: json[`skill${cursor}Timing`] || '',
      target: json[`skill${cursor}Target`] || '',
      range: json[`skill${cursor}Range`] || '',
      cost: json[`skill${cursor}Cost`] || '',
      reqd: json[`skill${cursor}Reqd`] || '',
      note: json[`skill${cursor}Note`] || ''
    });
    cursor++;
  }
  return skillData;
};

output._getArianrhodConnections = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`connection${cursor}Name`]) {
    data.push({
      name: json[`connection${cursor}Name`],
      relation: json[`connection${cursor}Relation`] || '',
    });
    cursor++;
  }
  return data;
};

output._getArianrhodGeises = (json) => {
  let cursor = 1;
  const data = [];
  while(json[`geis${cursor}Name`]) {
    data.push({
      name: json[`geis${cursor}Name`] || '',
      cost: json[`geis${cursor}Cost`] || '',
      note: json[`geis${cursor}Note`] || ''
    });
    cursor++;
  }
  return data;
};

output._getArianrhodArmament = (json) => {
  const data = [];
  [
    ['HandR','　　右手'],
    ['HandL','　　左手'],
    ['Head' ,'　　頭部'],
    ['Body' ,'　　胴部'],
    ['Sub'  ,'補助防具'],
    ['Other','　装身具']
  ].forEach(cursor => {
    data.push({
      type  : cursor[1],
      name  : json[`armament${cursor[0]}Name`] || '',
      weight: json[`armament${cursor[0]}Weight`] || '',
      acc   : json[`armament${cursor[0]}Acc`] || '',
      atk   : json[`armament${cursor[0]}Atk`] || '',
      eva   : json[`armament${cursor[0]}Eva`] || '',
      def   : json[`armament${cursor[0]}Def`] || '',
      mdef  : json[`armament${cursor[0]}MDef`] || '',
      ini   : json[`armament${cursor[0]}Ini`] || '',
      move  : json[`armament${cursor[0]}Move`] || '',
      range : json[`armament${cursor[0]}Range`] || '',
      note  : json[`armament${cursor[0]}Note`] || ''
    });
  });
  return data;
};

output._getArianrhodBattle = (json) => {
  const data = [];
  data.push({
    type  : '　------',
    name  : '----------',
    weight: '-----',
    acc   : '-----',
    atk   : '-----',
    eva   : '----',
    def   : '----',
    mdef  : '----',
    ini   : '----',
    move  : '----',
    range : '----',
    note  : '----'
  });
  [
    ['Skill','　スキル'],
    ['Other','　その他'],
  ].forEach(cursor => {
    data.push({
      type  : cursor[1],
      name  : json[`battle${cursor[0]}Name`]   || '',
      weight: json[`battle${cursor[0]}Weight`] || '',
      acc   : json[`battle${cursor[0]}Acc`]    || '',
      atk   : json[`battle${cursor[0]}Atk`]    || '',
      eva   : json[`battle${cursor[0]}Eva`]    || '',
      def   : json[`battle${cursor[0]}Def`]    || '',
      mdef  : json[`battle${cursor[0]}MDef`]   || '',
      ini   : json[`battle${cursor[0]}Ini`]    || '',
      move  : json[`battle${cursor[0]}Move`]   || '',
      range : json[`battle${cursor[0]}Range`]  || '',
      note  : json[`battle${cursor[0]}Note`]   || ''
    });
  });
  data.push({
    type  : '　　合計',
    name  : '',
    weight: json[`battleTotalWeight`] || '',
    acc   : json[`battleTotalAcc`]+'+'+json[`battleDiceAcc`]+'D' || '',
    atk   : json[`battleTotalAtk`]+'+'+json[`battleDiceAtk`]+'D'    || '',
    eva   : json[`battleTotalEva`]+'+'+json[`battleDiceEva`]+'D'    || '',
    def   : json[`battleTotalDef`]    || '',
    mdef  : json[`battleTotalMDef`]   || '',
    ini   : json[`battleTotalIni`]    || '',
    move  : json[`battleTotalMove`]   || '',
    range : json[`battleTotalRange`]  || '',
    note  : json[`battleTotalNote`]   || ''
  });
  return data;
};

output.generateCharacterTextOfArianrhod2PC = (json) => {
  const result = [];

  result.push(`キャラクター名：${json.characterName || ''}
年齢：${json.age || ''}
性別：${json.gender || ''}
種族：${json.race || ''}`);
  result.push('');

  result.push(`■クラス■
メイン　：${json.classMain || ''}
サポート：${json.classSupport || ''}
称号　　：${json.classTitle || ''}`);
  result.push('');

  result.push(`■ライフパス■
出自：${json.lifepathOrigin || ''}／${json.lifepathOriginNote || ''}
境遇：${json.lifepathExperience || ''}／${json.lifepathExperienceNote || ''}
目的：${json.lifepathMotive || ''}／${json.lifepathMotiveNote || ''}`);
  result.push('');

  result.push('■能力値■');
  result.push('　　　　基本値 　ﾎﾞｰﾅｽ　  ﾒｲﾝ　ｻﾎﾟｰﾄ　ｽｷﾙ他 　合計　ｽｷﾙ他　　　判定');
  output.consts.AR2_STATUS.forEach((statusPattern)=>{
    result.push(output._convertArianrhodStatus(json, statusPattern));
  });
  result.push('');
  result.push(`【ＨＰ】　　${String(json.hpTotal).padStart(3, ' ')}`);
  result.push(`【ＭＰ】　　${String(json.mpTotal).padStart(3, ' ')}`);
  result.push(`【フェイト】${String(json.fateTotal).padStart(3, ' ')}／使用上限:${json.fateLimit||0}`);
  result.push('');

  result.push('■装備品■');
  const armamentData = output._getArianrhodArmament(json);
  const battleData = armamentData.concat(output._getArianrhodBattle(json));
  result.push(output._convertList(battleData, output.consts.ARMAMENT_COLUMNS, ' / '));

  result.push('');
  result.push('');

  result.push(`■特殊な判定■
　　　　　　　　ｽｷﾙ　 他　　合計
トラップ探知： +${(json.rollTrapDetectSkill  ||'').padStart(3, ' ')} +${(json.rollTrapDetectOther  ||'').padStart(3, ' ')} =${(json.rollTrapDetect  ||0).padStart(3, ' ')}+${json.rollTrapDetectDice  ||''}D
トラップ解除： +${(json.rollAppraisalSkill   ||'').padStart(3, ' ')} +${(json.rollAppraisalOther   ||'').padStart(3, ' ')} =${(json.rollAppraisal   ||0).padStart(3, ' ')}+${json.rollAppraisalDice   ||''}D
　　危険感知： +${(json.rollTrapReleaseSkill ||'').padStart(3, ' ')} +${(json.rollTrapReleaseOther ||'').padStart(3, ' ')} =${(json.rollTrapRelease ||0).padStart(3, ' ')}+${json.rollTrapReleaseDice ||''}D
エネミー識別： +${(json.rollMagicSkill       ||'').padStart(3, ' ')} +${(json.rollMagicOther       ||'').padStart(3, ' ')} =${(json.rollMagic       ||0).padStart(3, ' ')}+${json.rollMagicDice       ||''}D
アイテム鑑定： +${(json.rollDangerDetectSkill||'').padStart(3, ' ')} +${(json.rollDangerDetectOther||'').padStart(3, ' ')} =${(json.rollDangerDetect||0).padStart(3, ' ')}+${json.rollDangerDetectDice||''}D
　　魔術判定： +${(json.rollSongSkill        ||'').padStart(3, ' ')} +${(json.rollSongOther        ||'').padStart(3, ' ')} =${(json.rollSong        ||0).padStart(3, ' ')}+${json.rollSongDice        ||''}D
　　呪歌判定： +${(json.rollEnemyLoreSkill   ||'').padStart(3, ' ')} +${(json.rollEnemyLoreOther   ||'').padStart(3, ' ')} =${(json.rollEnemyLore   ||0).padStart(3, ' ')}+${json.rollEnemyLoreDice   ||''}D
　錬金術判定： +${(json.rollAlchemySkill     ||'').padStart(3, ' ')} +${(json.rollAlchemyOther     ||'').padStart(3, ' ')} =${(json.rollAlchemy     ||0).padStart(3, ' ')}+${json.rollAlchemyDice     ||''}D
`);
  result.push('');

  result.push('■携帯品・所持品■');
  result.push((json.items || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));
  result.push(`携帯重量：${json.weightItems||0}／${json.weightLimitItems}`);
  result.push('');
  result.push('');

  result.push('■スキル■');
  const skillData = output._getArianrhodSkills(json);
  result.push(output._convertList(skillData, output.consts.SKILL_COLUMNS, ' / '));
  result.push('');
  result.push('');

  result.push(`■ギルド■
所属ギルド　　：${json.guildName || ''}
ギルドマスター：${json.guildMaster || ''}
`);
  result.push('');

  result.push('■コネクション■');
  const connectionData = output._getArianrhodConnections(json);
  result.push(output._convertList(connectionData, output.consts.CONNECTION_COLUMNS, ' / '));
  result.push('');
  result.push('');

  result.push('■誓約■');
  const geisesData = output._getArianrhodGeises(json);
  result.push(output._convertList(geisesData, output.consts.GEIS_COLUMNS, ' / '));
  result.push('');
  result.push('');

  result.push('■その他■');
  result.push((json.freeNote || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));
  
  return result.join('\n');
};