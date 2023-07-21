"use strict";
const gameSystem = SET.gameSystem;
let modeZero;

const expTable = {
  'A' : [
         0,
      1000,
      2000,
      3500,
      5000,
      7000,
      9500,
     12500,
     16500,
     21500,
     27500,
     35000,
     44000,
     54500,
     66500,
     80000,
     95000,
    125000
  ],
  'B' : [
         0,
       500,
      1500,
      2500,
      4000,
      5500,
      7500,
     10000,
     13000,
     17000,
     22000,
     28000,
     35500,
     44500,
     55000,
     67000,
     80500,
    105500
  ],
  'S' : [
         0,
      3000,
      6000,
      9000,
     12000,
     16000,
     20000,
     24000,
     28000,
     33000,
     38000,
     43000,
     48000,
     54000,
     60000,
     66000,
     72000,
     79000,
     86000,
     93000,
    100000
  ]
};

let race = '';
let level = 0;
let levelCasters = [];

window.onload = function() {
  console.log('=====START=====');

  nameSet();
  race = form.race.value;
  calcExp();
  calcLv();
  checkRace();
  calcStt();
  calcCash();
  calcHonor();
  calcDishonor();
  
  imagePosition();
  changeColor();
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.characterName.value === '' && form.aka.value === ''){
    alert('キャラクター名か二つ名のいずれかを入力してください。');
    form.characterName.focus();
    return false;
  }
  if(form.protect.value === 'password' && form.pass.value === ''){
    alert('パスワードが入力されていません。');
    form.pass.focus();
    return false;
  }
  return true;
}

// レギュレーション ----------------------------------------
function changeRegu(){
  document.getElementById("history0-exp").textContent = form.history0Exp.value;
  document.getElementById("history0-honor").textContent = form.history0Honor.value;
  document.getElementById("history0-money").textContent = form.history0Money.value;
  
  calcExp();
  calcLv();
  calcCash();
  calcHonor();
}

// 信仰チェック ----------------------------------------
function changeFaith(obj) {
  obj.parentNode.classList.toggle('free', obj.value === 'その他の信仰');
}

// レベル変更 ----------------------------------------
function changeLv() {
  calcLv();
  
  checkRace();
  calcPackage();
  checkFeats();
}

// レベル計算 ----------------------------------------
let expUse = 0;
let expTotal = 0;
let lv = {};
let lvSeeker = 0;
function calcLv(){
  expUse = 0;
  let allClassLv = [];
  levelCasters = [];
  for(const key in SET.class){
    const id = SET.class[key].id;
    if(SET.class[key].expTable){
      lv[id] = Number(form['lv'+id].value);
      if(SET.class[key]['2.0'] && !SET.allClassOn){ lv[id] = 0; }
      
      expUse += expTable[ SET.class[key].expTable ][ lv[id] ];
      
      allClassLv.push(lv[id]);
      if(SET.class[key].magic){ levelCasters.push(lv[id]); }
    }
  }
  if(form.lvSeeker){
    lvSeeker = Number(form.lvSeeker.value);
    expUse += expTable['S'][ lvSeeker ];
  }
  
  document.getElementById("exp-use").textContent = commify(expUse);
  document.getElementById("exp-rest").textContent = commify(expTotal - expUse);
  
  level = Math.max.apply(null, Object.values(lv));
  document.getElementById("level-value").textContent = level;
  
  lv['Wiz'] = (lv['Sor'] && lv['Con']) ? Math.max(lv['Sor'],lv['Con']) : 0;
  levelCasters.sort( function(a,b){ return (a < b ? 1 : -1); } );
  if(SET.battleItemOn){
    const sLevel = Math.max.apply(null, [ lv['Sco'], lv['Ran'], lv['Sag'] ]);
    const maxBattleItems = 8 + Math.ceil(sLevel / 2);
    for (let i = 1; i <= 16; i++) {
      let cL = document.getElementById("battle-item"+i).classList;
      if(i <= maxBattleItems) { cL.remove("fail"); }
      else { cL.add("fail"); }
    }
  }
  
  document.getElementById('material-cards').style.display = lv['Alc'] > 0 ? '' : 'none';
  
  calcFairy();
}

// 種族変更 ----------------------------------------
function changeRace(value){
  race = value;
  
  document.getElementById('race-ability-select').innerHTML = '';
  let selectCount = 1;
  for(let lv of ['','Lv6','Lv11','Lv16']){
    for(let ability of SET.races[race]?.['ability'+lv] || []){
      if(Array.isArray(ability)){
        let select = document.createElement('select');
        select.addEventListener('input', changeRaceAbility);
        select.name = 'raceAbilitySelect'+selectCount;
        select.innerHTML = '<option value="">';
        for(let set of ability){
          let opt = document.createElement('option');
          opt.value = opt.text = set;
          select.append(opt);
        }
        document.getElementById('race-ability-select').append(select);
        selectCount++;
      }
    }
  }
  if(!race){
    document.getElementById('race-ability-value').innerHTML = '';
  }
  else if(!SET.races[race]) {
    document.getElementById('race-ability-value').innerHTML = `<input type="text" name="raceAbilityFree" oninput="changeRaceAbility()" value="${form.raceAbilityFree?.value ?? '［］'}">`;
  }
  checkRace();
  calcStt();
}
function changeRaceAbility(){
  checkRace();
  calcStt();
}

// 種族チェック ----------------------------------------
let raceAbilityDef       = 0;
let raceAbilityMp        = 0;
let raceAbilityMndResist = 0;
let raceAbilityMagicPower= 0;
let raceAbilities = [];
function checkRace(){
  raceAbilityDef       = 0;
  raceAbilityMp        = 0;
  raceAbilityMndResist = 0;
  raceAbilityMagicPower= 0;
  for(const className in SET.class){
    const id = SET.class[className].id;
    if(document.getElementById("class"+id)){
      document.getElementById("class"+id).classList.remove('fail');
      if(SET.races[race]?.restrictedClass?.includes(className)){
        document.getElementById("class"+id).classList.add('fail');
      }
      else if(SET.class[className].onlyRace && !SET.class[className].onlyRace.includes(race)){
        document.getElementById("class"+id).classList.add('fail');
      }
    }
  }

  raceAbilities = [];
  if(SET.races[race]?.ability){
    raceAbilities = SET.races[race].ability.concat();
    document.getElementById('race-ability-value').innerHTML = '';
    let selectCount = 1;
    for(let lv of [0,6,11,16]){
      for(let ability of SET.races[race]?.['ability'+(lv?'Lv'+lv:'')] || []){
        if(Array.isArray(ability)){
          let isView = level >= lv ? 1 : 0;
          if(modeZero && lv >= 16){
            document.querySelectorAll('#seeker-abilities ul li:not(.fail) select').forEach(obj=>{
              if(obj.value === '種族特徴の獲得、強化'){ isView = 1 }
            });
          }
          form['raceAbilitySelect'+selectCount].classList.toggle('hidden', !isView);
          raceAbilities.push(form['raceAbilitySelect'+selectCount].value);
          selectCount++;
        }
        else {
          document.getElementById('race-ability-value').innerHTML += `［${ability}］`;
          raceAbilities.push(ability);
        }
      }
    }
  }
  else if(form.raceAbilityFree) {
    let ability = form.raceAbilityFree.value;
    ability.replace(/［(.+?)］/g, (all, match) => {
      raceAbilities.push(match);
    });
    console.log(raceAbilities)
  }
  
  if(raceAbilities.includes('鱗の皮膚')){
    raceAbilityDef += 1;
    document.getElementById("race-ability-def-name").textContent = '鱗の皮膚';
  }
  if(raceAbilities.includes('月光の守り')){
    raceAbilityMndResist += 4;
    if(level >= 11){ raceAbilityMndResist += 2; }
  }
  if(raceAbilities.includes('晶石の身体')){
    raceAbilityDef += 2;
    raceAbilityMp += 15;
    if(level >=  6){ raceAbilityDef += 1; raceAbilityMp += 15; }
    if(level >= 11){ raceAbilityDef += 1; raceAbilityMp += 15; }
    if(level >= 16){ raceAbilityDef += 2; raceAbilityMp += 30; }
    document.getElementById("race-ability-def-name").textContent = '晶石の身体';
  }
  if(raceAbilities.includes('奈落の身体／アビストランク')){
    raceAbilityDef += 1;
    if(level >=  6){ raceAbilityDef += 1; }
    if(level >= 11){ raceAbilityDef += 1; }
    document.getElementById("race-ability-def-name").textContent = '奈落の身体／アビストランク';
  }
  if(raceAbilities.includes('魔法の申し子')){
    raceAbilityMagicPower += (level >= 11) ? 2 : 1;
    document.getElementById("magic-power-raceability-value" ).textContent = raceAbilityMagicPower || 0;
    document.getElementById("magic-power-raceability-name").textContent = '魔法の申し子';
    document.getElementById("magic-power-raceability-type").textContent = '魔法全般';
  }
  if(raceAbilities.includes('神の御名と共に') && level >= 6){
    document.getElementById("magic-power-raceability-value" ).textContent = (level >= 11) ? 2 : 1;
    document.getElementById("magic-power-raceability-name").textContent = '神の御名と共に';
    document.getElementById("magic-power-raceability-type").textContent = '神聖魔法';
  }
  if(raceAbilities.includes('神への礼賛') && level >= 6){
    document.getElementById("magic-power-raceability-value" ).textContent = (level >= 11) ? 2 : 1;
    document.getElementById("magic-power-raceability-name").textContent = '神への礼賛';
    document.getElementById("magic-power-raceability-type").textContent = '神聖魔法';
  }
  if(raceAbilities.includes('神への祈り') && level >= 6){
    document.getElementById("magic-power-raceability-value" ).textContent = (level >= 11) ? 2 : 1;
    document.getElementById("magic-power-raceability-name").textContent = '神への祈り';
    document.getElementById("magic-power-raceability-type").textContent = '神聖魔法';
  }
  if(raceAbilities.includes('トロールの体躯')){
    raceAbilityDef = 1;
    if(level >= 16){ raceAbilityDef += 2; }
    document.getElementById("race-ability-def-name").textContent = 'トロールの体躯';
  }
  checkLanguage();
  setLanguageDefault();
}
function setLanguageDefault(){
  if (!form.languageAutoOff.checked) {
    let text = '';
    if(SET.races[race]?.language){
      for(let data of SET.races[race].language){
        text += `<dt>${data[0]}</dt><dd>${data[1]?'○':'―'}</dd><dd>${data[2]?'○':'―'}</dd>`;
      }
    }
    else {
      text += `<dt>初期習得言語</dt><dd>○</dd><dd>○</dd>`;
    }
    document.getElementById("language-default").innerHTML = text;
  }
  else { document.getElementById("language-default").innerHTML = ''; }
}
// ステータス計算 ----------------------------------------
let reqdStr = 0;
let reqdStrHalf = 0;
let stt = {
  Dex:0, addA:0, growDex:0,
  Agi:0, addB:0, growAgi:0,
  Str:0, addC:0, growStr:0,
  Vit:0, addD:0, growVit:0,
  Int:0, addE:0, growInt:0,
  Mnd:0, addF:0, growMnd:0,
};
let bonus = {
  Dex:0,
  Agi:0,
  Str:0,
  Vit:0,
  Int:0,
  Mnd:0,
}
function calcStt() {
  // 履歴から成長カウント
  stt.growDex = 0;
  stt.growAgi = 0;
  stt.growStr = 0;
  stt.growVit = 0;
  stt.growInt = 0;
  stt.growMnd = 0;
  for (let i = 1; i <= Number(form.historyNum.value); i++){
    const grow = form["history" + i + "Grow"].value;
    grow.replace(/器(?:用度?)?(?:×|\*)?([0-9]{1,3})?/g, (all,n) => { stt.growDex += Number(n) || 1; });
    grow.replace(/敏(?:捷度?)?(?:×|\*)?([0-9]{1,3})?/g, (all,n) => { stt.growAgi += Number(n) || 1; });
    grow.replace(/筋(?:力)?(?:×|\*)?([0-9]{1,3})?/g,    (all,n) => { stt.growStr += Number(n) || 1; });
    grow.replace(/生(?:命力?)?(?:×|\*)?([0-9]{1,3})?/g, (all,n) => { stt.growVit += Number(n) || 1; });
    grow.replace(/知(?:力)?(?:×|\*)?([0-9]{1,3})?/g,    (all,n) => { stt.growInt += Number(n) || 1; });
    grow.replace(/精(?:神力?)?(?:×|\*)?([0-9]{1,3})?/g, (all,n) => { stt.growMnd += Number(n) || 1; });
  }
  const seekerGrow
    = lvSeeker >= 17 ? 30
    : lvSeeker >= 13 ? 24
    : lvSeeker >=  9 ? 18
    : lvSeeker >=  5 ? 12
    : lvSeeker >=  1 ?  6
    : 0;

  // 計算
  let growTotal = 0;
  for(let i of [
    ['A','Dex'],
    ['B','Agi'],
    ['C','Str'],
    ['D','Vit'],
    ['E','Int'],
    ['F','Mnd'],
  ]){
    // 心技体
    const base = (i[0] === 'A' || i[0] === 'B') ? Number(form.sttBaseTec.value)
               : (i[0] === 'C' || i[0] === 'D') ? Number(form.sttBasePhy.value)
               : (i[0] === 'E' || i[0] === 'F') ? Number(form.sttBaseSpi.value)
               : 0;
    // 成長
    stt['grow'+i[1]] += Number(form['sttPreGrow'+i[0]].value) + seekerGrow;
    document.getElementById(`stt-grow-${i[0]}-value`).textContent = stt['grow'+i[1]];
    growTotal += stt['grow'+i[1]]; //成長回数合計

    // 種族特徴による修正
    const raceMod = SET.races[race]?.statusMod?.[i[1]] || 0;
    // 合計
    stt[i[1]] = base + Number(form['sttBase'+i[0]].value) + stt['grow'+i[1]] + raceMod;
    document.getElementById(`stt-${i[1].toLowerCase()}-value`).innerHTML = `<span>${modStatus(raceMod)}${stt[i[1]]}</span>`;

    // 増強
    stt['add'+i[0]] = Number(form['sttAdd'+i[0]].value);

    // ボーナス
    document.getElementById(`stt-bonus-${i[1].toLowerCase()}-value`).textContent
      = bonus[i[1]]
      = parseInt((stt[i[1]] + stt['add'+i[0]]) / 6);
  }

  document.getElementById("stt-grow-total-value").textContent = growTotal;
  document.getElementById("history-grow-total-value").textContent = growTotal;
  
  function modStatus(value){
    if(value > 0){ return `<span class="small">+${value}=</span>` }
    if(value < 0){ return `<span class="small">${value}=</span>` }
    return ''
  }
  
  reqdStr = stt.Str + stt.addC;
  reqdStrHalf = Math.ceil(reqdStr / 2);
  
  checkFeats();
  calcSubStt();
  calcMobility();
  calcPackage();
  calcMagic();
  calcAttack();
  calcDefense();
  calcPointBuy();
}

// 戦闘特技チェック ----------------------------------------
let feats = {};
function checkFeats(){
  feats = {};

  const featsVagrantsOn = form.featsVagrantsOn.checked;
  const featsZeroOn     = form.featsZeroOn.checked;
  document.querySelectorAll(`#combat-feats option.vagrants` ).forEach(obj=>{ obj.style.display = featsVagrantsOn ? '' : 'none'; });
  document.querySelectorAll(`#combat-feats option.zero-data`).forEach(obj=>{ obj.style.display = featsZeroOn     ? '' : 'none'; });
  document.getElementById('combat-feat-vagrants-sco5').style.display = (featsVagrantsOn && lv['Sco'] >= 5) ? '' : 'none';
  document.getElementById('combat-feat-vagrants-ran5').style.display = (featsVagrantsOn && lv['Ran'] >= 5) ? '' : 'none';
  document.getElementById('combat-feat-vagrants-sag5').style.display = (featsVagrantsOn && lv['Sag'] >= 5) ? '' : 'none';
  
  const array = SET.featsLv.map(n=>String(n));
  let acquire = '';
  for (let i = 0; i < array.length; i++) {
    let cL = document.getElementById("combat-feats-lv"+array[i]).classList;
    cL.remove("mark","error");
    if(array[i].match(/bat/) && lv['Bat'] <= 0){
      cL.add('hidden');
      continue;
    }
    if(level >= Number( array[i].replace(/[^0-9]/g, '') )){
      const f2 = (array[i+1] && level >= Number( array[i+1].replace(/[^0-9]/g, '') )) ? 1 : 0; //次枠の開放状況
      const f3 = (array[i+2] && level >= Number( array[i+2].replace(/[^0-9]/g, '') )) ? 1 : 0; //次々枠の開放状況
      const box = form["combatFeatsLv"+array[i]];
      const auto = form.featsAutoOn.checked;
      let feat = box.options[box.selectedIndex].value;
      acquire += feat + ',';
      
      if (feat.match(/追い打ち/)){
        if(!acquire.match('シールドバッシュ')){ cL.add("error"); }
      }
      else if (feat.match(/ガーディアン/)){
        if(!acquire.match('かばう')){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 9) { (auto) ? box.value = "ガーディアンⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 9) { (auto) ? box.value = "ガーディアンⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/回避行動/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fen'] >= 9 || lv['Bat'] >= 9)) { (auto) ? box.value = "回避行動Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fen'] < 9 && lv['Bat'] < 9)) { (auto) ? box.value = "回避行動Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/^頑強/)){
        if(lv['Fig'] < 5 && lv['Gra'] < 5 && lv['Fen'] < 5 && lv['Bat'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/鼓咆陣率追加/)){
        if(lv['War'] < 1){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lv['War'] >= 9) { (auto) ? box.value = "鼓咆陣率追加Ⅲ" : cL.add("mark") }
          else if(f2 && lv['War'] >= 5) { (auto) ? box.value = "鼓咆陣率追加Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['War'] >= 9) { (auto) ? box.value = "鼓咆陣率追加Ⅲ" : cL.add("mark") }
          else if(!f2 || lv['War'] < 5) { (auto) ? box.value = "鼓咆陣率追加Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || lv['War'] < 5) { (auto) ? box.value = "鼓咆陣率追加Ⅰ" : cL.add("error") }
          else if(!f3 || lv['War'] < 9) { (auto) ? box.value = "鼓咆陣率追加Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/射手の体術/)){
        if(lv['Sho'] < 7){ cL.add("error"); }
      }
      else if (feat.match(/終律増強/)){
        if(lv['Bar'] < 3){ cL.add("error"); }
      }
      else if (feat.match(/呪歌追加/)){
        if(lv['Bar'] < 1){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lv['Bar'] >= 13) { (auto) ? box.value = "呪歌追加Ⅲ" : cL.add("mark") }
          else if(f2 && lv['Bar'] >=  7) { (auto) ? box.value = "呪歌追加Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Bar'] >= 13) { (auto) ? box.value = "呪歌追加Ⅲ" : cL.add("mark") }
          else if(!f2 || lv['Bar'] <  7) { (auto) ? box.value = "呪歌追加Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || lv['Bar'] <  7) { (auto) ? box.value = "呪歌追加Ⅰ" : cL.add("error") }
          else if(!f3 || lv['Bar'] < 13) { (auto) ? box.value = "呪歌追加Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/双撃/)){
        if(!acquire.match('両手利き')){ cL.add("error"); }
      }
      else if (feat.match(/相克の標的/)){
        if(lv['Geo'] < 1){ cL.add("error"); }
      }
      else if (feat.match(/相克の別離/)){
        if(lv['Geo'] < 3){ cL.add("error"); }
      }
      else if (feat.match(/鷹の目/)){
        if(!acquire.match('ターゲッティング')){ cL.add("error"); }
      }
      else if (feat.match(/スローイング/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 5) { (auto) ? box.value = "スローイングⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 5) { (auto) ? box.value = "スローイングⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/超頑強/)){
        if((lv['Fig'] < 7 && lv['Gra'] < 7)|| !acquire.match('頑強')){ cL.add("error"); }
      }
      else if (feat.match(/抵抗強化/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 11) { (auto) ? box.value = "抵抗強化Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 11) { (auto) ? box.value = "抵抗強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/特殊楽器習熟/)){
        if(lv['Bar'] < 1){ cL.add("error"); }
      }
      else if (feat.match(/跳び蹴り/)){
        if(lv['Gra'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/投げ強化/)){
        if(lv['Gra'] < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Gra'] >= 9) { (auto) ? box.value = "投げ強化Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Gra'] < 9) { (auto) ? box.value = "投げ強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/二刀無双/)){
        if(level < 11){ cL.add("error"); }
      }
      else if (feat.match(/二刀流/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/ハーモニー/)){
        if(lv['Bar'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/武器習熟Ｓ／(.*)/)){
        if(level < 5 || !(acquire.match('武器習熟Ａ／' + RegExp.$1))){ cL.add("error"); }
      }
      else if (feat.match(/武器の達人/)){
        if(level < 11 || !(acquire.match('武器習熟Ｓ／'))){ cL.add("error"); }
      }
      else if (feat.match(/ブロッキング/)){
        if(level < 3){ cL.add("error"); }
      }
      else if (feat.match(/賦術強化/)){
        if(lv['Alc'] < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Alc'] >= 9) { (auto) ? box.value = "賦術強化Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Alc'] < 9) { (auto) ? box.value = "賦術強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/賦術全遠隔化/)){
        if(lv['Alc'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/踏みつけ/)){
        if(lv['Gra'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/変幻自在/)){
        if(lv['Gra'] < 5 && lv['Fen'] < 5 && lv['Bat'] < 5){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Gra'] >= 13 || lv['Fen'] >= 13 || lv['Bat'] >= 13)) { (auto) ? box.value = "変幻自在Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Gra'] < 13 && lv['Fen'] < 13 && lv['Bat'] < 13)) { (auto) ? box.value = "変幻自在Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/防具習熟Ｓ／(.*)/)){
        if(level < 5 || !acquire.match('防具習熟Ａ／' + RegExp.$1)){ cL.add("error"); }
      }
      else if (feat.match(/防具の達人/)){
        if(level < 11 || !acquire.match('防具習熟Ｓ／')){ cL.add("error"); }
      }
      else if (feat.match(/魔晶石の達人/)){
        if(level < 9){ cL.add("error"); }
      }
      else if (feat.match(/マリオネット/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/魔法拡大の達人/)){
        if(!acquire.match('魔法拡大すべて')){ cL.add("error"); }
      }
      else if (feat.match(/魔力強化/)){
        if(levelCasters[1] < 6){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 11 && levelCasters[1] >= 10) { (auto) ? box.value = "魔力強化Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 11 || levelCasters[1] < 10) { (auto) ? box.value = "魔力強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/命中強化/)){
        if(level < 7){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 13) { (auto) ? box.value = "命中強化Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 13) { (auto) ? box.value = "命中強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/連続賦術/)){
        if(lv['Alc'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/練体の極意/)){
        if(lv['Enh'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/ＭＰ軽減/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/インファイト/)){
        if(lv['Gra'] < 5){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Gra'] >= 9) { (auto) ? box.value = "インファイトⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Gra'] < 9) { (auto) ? box.value = "インファイトⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/囮攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 9) { (auto) ? box.value = "囮攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 9) { (auto) ? box.value = "囮攻撃Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/カード軽減/)){
        if(lv['Alc'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/楽素転換/)){
        if(lv['Bar'] < 3){ cL.add("error"); }
      }
      else if (feat.match(/かばう/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 7) { (auto) ? box.value = "かばうⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 7) { (auto) ? box.value = "かばうⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/影矢/)){
        if(lv['Sho'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/牙折り/)){
        if(lv['Gra'] < 9 && lv['Bat'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/斬り返し/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fig'] >= 7 || lv['Fen'] >= 7 || lv['Bat'] >= 7)) { (auto) ? box.value = "斬り返しⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fig'] < 7 && lv['Fen'] < 7 && lv['Bat'] < 7)) { (auto) ? box.value = "斬り返しⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/クリティカルキャスト/)){
        if(level < 7){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 11) { (auto) ? box.value = "クリティカルキャストⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 11) { (auto) ? box.value = "クリティカルキャストⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/牽制攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && level >= 11) { (auto) ? box.value = "牽制攻撃Ⅲ" : cL.add("mark") }
          else if(f2 && level >=  7) { (auto) ? box.value = "牽制攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && level >= 11) { (auto) ? box.value = "牽制攻撃Ⅲ" : cL.add("mark") }
          else if(!f2 || level <  7) { (auto) ? box.value = "牽制攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level <  7) { (auto) ? box.value = "牽制攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || level < 11) { (auto) ? box.value = "牽制攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/高度な柔軟性/)){
        if(lv['War'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/シールドバッシュ/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 5) { (auto) ? box.value = "シールドバッシュⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 5) { (auto) ? box.value = "シールドバッシュⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/シャドウステップ/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 7) { (auto) ? box.value = "シャドウステップⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 7) { (auto) ? box.value = "シャドウステップⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/シュアパフォーマー/)){
        if(lv['Bar'] < 3){ cL.add("error"); }
      }
      else if (feat.match(/スキルフルプレイ/)){
        if(lv['Bar'] < 7){ cL.add("error"); }
      }
      else if (feat.match(/捨て身攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && level >= 15){ (auto) ? box.value = "捨て身攻撃Ⅲ" : cL.add("mark") }
          else if(f2 && level >= 7) { (auto) ? box.value = "捨て身攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && level >= 15){ (auto) ? box.value = "捨て身攻撃Ⅲ" : cL.add("mark") }
          else if(!f2 || level < 7) { (auto) ? box.value = "捨て身攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level < 7) { (auto) ? box.value = "捨て身攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || level < 15){ (auto) ? box.value = "捨て身攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/先陣の才覚/)){
        if(lv['War'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/全力攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lv['Fig'] >= 15)               { (auto) ? box.value = "全力攻撃Ⅲ" : cL.add("mark") }
          else if(f2 && (lv['Fig'] >= 9 || lv['Gra'] >= 9 || lv['Bat'] >= 9)){ (auto) ? box.value = "全力攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Fig'] >= 15)               { (auto) ? box.value = "全力攻撃Ⅲ" : cL.add("mark") }
          else if(!f2 || (lv['Fig'] < 9 && lv['Gra'] < 9 && lv['Bat'] < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || (lv['Fig'] < 9 && lv['Gra'] < 9 && lv['Bat'] < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || lv['Fig'] < 15)               { (auto) ? box.value = "全力攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/ダブルキャスト/)){
        if(levelCasters[0] < 9){ cL.add("error"); }
      }
      else if (feat.match(/挑発攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fen'] >= 7 || lv['Bat'] >= 7)) { (auto) ? box.value = "挑発攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fen'] <  7 &&  lv['Bat'] < 7)) { (auto) ? box.value = "挑発攻撃Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/テイルスイング/)){
        if(level < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 9) { (auto) ? box.value = "テイルスイングⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 9) { (auto) ? box.value = "テイルスイングⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/薙ぎ払い/)){
        if(lv['Fig'] < 3 && lv['Bat'] < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fig'] >= 9 || lv['Bat'] >= 9)) { (auto) ? box.value = "薙ぎ払いⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fig'] < 9 && lv['Bat'] < 9)) { (auto) ? box.value = "薙ぎ払いⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/バイオレントキャスト/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 13) { (auto) ? box.value = "バイオレントキャストⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 13) { (auto) ? box.value = "バイオレントキャストⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/必殺攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && (lv['Fen'] >= 11 || lv['Bat'] >= 11)) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("mark") }
          else if(f2 && level >=  7) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && (lv['Fen'] >= 11 || lv['Bat'] >= 11)) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("mark") }
          else if(!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || (lv['Fen'] < 11 && lv['Bat'] < 11)) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/マルチアクション/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/鎧貫き/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lv['Gra'] >= 15) { (auto) ? box.value = "鎧貫きⅢ" : cL.add("mark") }
          else if(f2 && lv['Gra'] >=  9) { (auto) ? box.value = "鎧貫きⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Gra'] >= 15) { (auto) ? box.value = "鎧貫きⅢ" : cL.add("mark") }
          else if(!f2 || lv['Gra'] <  9) { (auto) ? box.value = "鎧貫きⅠ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || lv['Gra'] <  9) { (auto) ? box.value = "鎧貫きⅠ" : cL.add("error") }
          else if(!f3 || lv['Gra'] < 15) { (auto) ? box.value = "鎧貫きⅡ" : cL.add("error") }
        }
      }
      else if (feat.match(/魔法拡大すべて/)){
        if(!acquire.match('魔法拡大／')){ cL.add("error"); }
      }
      else if (feat.match(/魔法制御/)){
        if(!acquire.match('ターゲッティング') || !acquire.match('魔法収束')){ cL.add("error"); }
      }
      else if (feat.match(/乱撃/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 7) { (auto) ? box.value = "乱撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 7) { (auto) ? box.value = "乱撃Ⅰ" : cL.add("error") }
        }
      }
      feat = box.options[box.selectedIndex].value;
      
      const weaponsRegex = new RegExp('武器習熟(Ａ|Ｓ)／(' + SET.weapons.map(d => d[0]).join('|') + ')');
      if     (feat === "足さばき"){ feats['足さばき'] = 1; }
      else if(feat === "回避行動Ⅰ"){ feats['回避行動'] = 1; }
      else if(feat === "回避行動Ⅱ"){ feats['回避行動'] = 2; }
      else if(feat === "命中強化Ⅰ"){ feats['命中強化'] = 1; }
      else if(feat === "命中強化Ⅱ"){ feats['命中強化'] = 2; }
      else if(feat === "魔力強化Ⅰ"){ feats['魔力強化'] = 1; }
      else if(feat === "魔力強化Ⅱ"){ feats['魔力強化'] = 2; }
      else if(feat === "賦術強化Ⅰ"){ feats['賦術強化'] = 1; }
      else if(feat === "賦術強化Ⅱ"){ feats['賦術強化'] = 2; }
      else if(feat === "頑強")  { feats['頑強'] = (feats['頑強']||0) +15; }
      else if(feat === "超頑強"){ feats['頑強'] = (feats['頑強']||0) +15; }
      else if(feat === "キャパシティ"){ feats['キャパシティ'] = 15; }
      else if(feat === "射手の体術"){ feats['射手の体術'] = 1; }
      else if(feat.match(weaponsRegex)){
        feats['武器習熟／'+RegExp.$2] ||= 0;
        if     (RegExp.$1 === 'Ａ'){ feats['武器習熟／'+RegExp.$2] += 1; }
        else if(RegExp.$1 === 'Ｓ'){ feats['武器習熟／'+RegExp.$2] += 2; }
      }
      else if(feat.match(/防具習熟(Ａ|Ｓ)／(金属鎧|非金属鎧|盾)/)){
        feats['防具習熟／'+RegExp.$2] ||= 0;
        if     (RegExp.$1 === 'Ａ'){ feats['防具習熟／'+RegExp.$2] += 1; }
        else if(RegExp.$1 === 'Ｓ'){ feats['防具習熟／'+RegExp.$2] += 2; }
      }
      else if(feat === "魔器習熟Ａ"){ feats['魔器習熟'] = 1; }
      else if(feat === "魔器習熟Ｓ"){ feats['魔器習熟'] = 1; }
      else if(feat === "魔器の達人"){ feats['魔器習熟'] = 1; }
      else if(feat === "スローイングⅠ"){ feats['スローイング'] = 1; }
      else if(feat === "スローイングⅡ"){ feats['スローイング'] = 2; }
      else if(feat === "呪歌追加Ⅰ"){ feats['呪歌追加'] = 1; }
      else if(feat === "呪歌追加Ⅱ"){ feats['呪歌追加'] = 2; }
      else if(feat === "呪歌追加Ⅲ"){ feats['呪歌追加'] = 3; }
      else if(feat === "鼓咆陣率追加Ⅰ"){ feats['鼓咆陣率追加'] = 1; }
      else if(feat === "鼓咆陣率追加Ⅱ"){ feats['鼓咆陣率追加'] = 2; }
      else if(feat === "鼓咆陣率追加Ⅲ"){ feats['鼓咆陣率追加'] = 3; }
      else if(feat === "抵抗強化Ⅰ"){ feats['抵抗強化'] = 1; }
      else if(feat === "抵抗強化Ⅱ"){ feats['抵抗強化'] = 2; }
      
      cL.remove("fail","hidden");
    }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden") };
    }
  }
  
  calcSubStt();
  calcMobility();
  calcMagic();
  calcAttack();
  calcDefense();
  checkCraft();
}

// 技芸 ----------------------------------------
function checkCraft() {
  for(const key in SET.class){
    const cId  = SET.class[key].id;
    const cLv = lv[cId];
    if (SET.class[key].craft?.data){
      const eName = SET.class[key].craft.eName;
      document.getElementById("craft-"+eName).style.display = cLv ? "block" : "none";
      const cMax = (cId.match(/Bar|War/)) ? 20 : (cId === 'Art') ? 19 : 17;
      const rows = cLv + (
            (cId === 'Bar') ? (feats['呪歌追加'] || 0)
          : (cId === 'War') ? (feats['鼓咆陣率追加'] || 0)
          : (cId === 'Art' && lv.Art === 16) ? 1
          : (cId === 'Art' && lv.Art === 17) ? 2
          : 0
        );
      for (let i = 1; i <= cMax; i++) {
        let objCL = document.getElementById("craft-"+eName+i).classList;
        if (i <= rows){
          objCL.remove("fail","hidden");
        }
        else {
          objCL.add("fail");
          objCL.toggle("hidden", !form.failView.checked);
        }
      }
    }
    else if (SET.class[key].magic?.data){
      const eName = SET.class[key].magic.eName;
      document.getElementById("magic-"+eName).style.display = cLv ? "block" : "none";
      const cMax = 17;
      for (let i = 1; i <= cMax; i++) {
        let objCL = document.getElementById("magic-"+eName+i).classList;
        if(i <= cLv){
          objCL.remove("fail","hidden");
        }
        else {
          objCL.add("fail");
          objCL.toggle("hidden", !form.failView.checked);
        }
      }
    }
  }
}

// ＨＰＭＰ抵抗力計算 ----------------------------------------
function calcSubStt() {
  const seekerHpMpAdd = (lvSeeker && checkSeekerAbility('ＨＰ、ＭＰ上昇')) ? 10 : 0;
  const seekerResistAdd = (lvSeeker && checkSeekerAbility('抵抗力上昇')) ? 3 : 0;
  
  const vitResistBase = level + bonus.Vit;
  const mndResistBase = level + bonus.Mnd;
  const vitResistAutoAdd = 0 + (feats['抵抗強化'] || 0) + seekerResistAdd;
  const mndResistAutoAdd = raceAbilityMndResist + (feats['抵抗強化'] || 0) + seekerResistAdd;
  document.getElementById("vit-resist-base").textContent = vitResistBase;
  document.getElementById("mnd-resist-base").textContent = mndResistBase;
  document.getElementById("vit-resist-auto-add").textContent = vitResistAutoAdd;
  document.getElementById("mnd-resist-auto-add").textContent = mndResistAutoAdd;
  document.getElementById("vit-resist-total").textContent = vitResistBase + Number(form.vitResistAdd.value) + vitResistAutoAdd;
  document.getElementById("mnd-resist-total").textContent = mndResistBase + Number(form.mndResistAdd.value) + mndResistAutoAdd;
  
  let hpAccessory = 0;
  let mpAccessory = 0;
  for (let type of ["Head", "Face",  "Ear", "Neck", "Back", "HandR", "HandL", "Waist", "Leg", "Other", "Other2", "Other3", "Other4"]){
    for (let add of ['','_','__']){
      const name = type + add;
      if(form["accessory"+name+"Own"].options[form["accessory"+name+"Own"].selectedIndex].value === "HP"){ hpAccessory = 2 }
      if(form["accessory"+name+"Own"].options[form["accessory"+name+"Own"].selectedIndex].value === "MP"){ mpAccessory = 2 }
    }
  }
  
  const hpBase = level * 3 + stt.Vit + stt.addD;
  const mpBase = 
    (raceAbilities.includes('溢れるマナ')) ? (level * 3 + stt.Mnd + stt.addF)
    : ( levelCasters.reduce((a,x) => a+x,0) * 3 + stt.Mnd + stt.addF );
  const hpAutoAdd = (feats['頑強'] || 0) + hpAccessory + (lv['Fig'] >= 7 ? 15 : 0) + seekerHpMpAdd;
  const mpAutoAdd = (feats['キャパシティ'] || 0) + raceAbilityMp + mpAccessory + seekerHpMpAdd;
  document.getElementById("hp-base").textContent = hpBase;
  document.getElementById("mp-base").textContent = raceAbilities.includes('マナ不干渉') ? '0' : mpBase;
  document.getElementById("hp-auto-add").textContent = hpAutoAdd;
  document.getElementById("mp-auto-add").textContent = mpAutoAdd;
  document.getElementById("hp-total").textContent = hpBase + Number(form.hpAdd.value) + hpAutoAdd;
  document.getElementById("mp-total").textContent = raceAbilities.includes('マナ不干渉') ? 'なし' : (mpBase + Number(form.mpAdd.value) + mpAutoAdd);
}

// 移動力計算 ----------------------------------------
function calcMobility() {
  const agi = stt.Agi + stt.addB;
  const mobilityBase = (raceAbilities.includes('半馬半人') ? (agi * 2) : agi);
  let mobilityOwn = 0;
  for (let num = 1; num <= form.armourNum.value; num++){
    if(form[`armour${num}Category`].value.match(/鎧/) && form[`armour${num}Own`].checked){
      mobilityOwn = 2;
      break;
    }
  }
  const mobility = mobilityBase + Number(form.mobilityAdd.value) + mobilityOwn;
  document.getElementById("mobility-limited").textContent = feats['足さばき'] ? 10 : 3;
  document.getElementById("mobility-base").textContent = mobilityBase + mobilityOwn;
  document.getElementById("mobility-total").textContent = mobility;
  document.getElementById("mobility-full").textContent = mobility * 3;
}

// パッケージ計算 ----------------------------------------
function calcPackage() {
  const alphabetToStt = {
    A: 'Dex',
    B: 'Agi',
    C: 'Str',
    D: 'Vit',
    E: 'Int',
    F: 'Mnd',
  };
  let lore = [];
  let init = [];
  for(const key in SET.class){
    if(SET.class[key]['package']){
      const eName = SET.class[key].eName;
      const cId   = SET.class[key].id
      const pData = SET.class[key].package;
      const cLv = lv[cId];

      document.getElementById(`package-${eName}`).style.display = cLv > 0 ? "" :"none";
      
      for(const pId in pData){
        let autoBonus = 0;
        if(cId === 'War' && pId === 'Int'){
          let hit = 0;
          for(let i = 1; i <= lv.War+(feats['鼓咆陣率追加']||0); i++){
            if(form[`craftCommand${i}`].value.match(/軍師の知略$/)){ hit = 1; autoBonus += form[`craftCommand${i}`].value.match(/^陣率/) ? 1 : 0; break; }
          }
          if(!hit){
            document.getElementById(`package-${eName}-${pId.toLowerCase()}`).textContent = '―';
            break;
          }
        }
        
        let value = cLv + bonus[alphabetToStt[pData[pId].stt]] + Number(form[`pack${cId}${pId}Add`].value) + autoBonus;
        document.getElementById(`package-${eName}-${pId.toLowerCase()}-auto`).textContent = autoBonus ? '+'+autoBonus : '';
        document.getElementById(`package-${eName}-${pId.toLowerCase()}`).textContent = value;

        if(pData[pId].monsterLore){ lore.push(cLv > 0 ? value : 0); }
        if(pData[pId].initiative ){ init.push(cLv > 0 ? value : 0); }
      }
    }
  }

  
  document.getElementById("monster-lore-value").textContent = (Math.max(...lore) || 0) + Number(form.monsterLoreAdd.value);
  document.getElementById("initiative-value"  ).textContent = (Math.max(...init) || 0) + Number(form.initiativeAdd.value);
}

// 魔力計算 ----------------------------------------
let magicPowers = {};
function calcMagic() {
  const addPower = Number(form.magicPowerAdd.value) + (feats['魔力強化'] || 0);
  document.getElementById("magic-power-magicenhance-value").textContent = feats['魔力強化'] || 0;
  const addCast = Number(form.magicCastAdd.value);
  const addDamage = Number(form.magicDamageAdd.value);
  
  let openMagic = 0;
  let openCraft = 0;
  for(const key in SET.class){
    const id = SET.class[key].id
    const cLv = lv[id];
    const eName = SET.class[key].eName;
    // 魔法
    if(SET.class[key].magic){
      document.getElementById("magic-power-"+eName).style.display = cLv ? '' : 'none';
      if(cLv){ openMagic++; }
      
      const seekerMagicAdd = (lvSeeker && checkSeekerAbility('魔力上昇') && cLv >= 15) ? 3 : 0;
      let power = cLv + parseInt((stt.Int + stt.addE + (form["magicPowerOwn"+id].checked ? 2 : 0)) / 6) + Number(form["magicPowerAdd"+id].value) + addPower + seekerMagicAdd + raceAbilityMagicPower;
      if(id === 'Pri' && (
           raceAbilities.includes('神の御名と共に')
        || raceAbilities.includes('神への礼賛')
        || raceAbilities.includes('神への祈り')
      )){
        power += (level >= 11) ? 2 : (level >= 6) ? 1 : 0;
      }
      document.getElementById("magic-power-"+eName+"-value").textContent  = power;
      document.getElementById("magic-cast-"+eName+"-value").textContent   = power + Number(form["magicCastAdd"+id].value) + addCast;
      document.getElementById("magic-damage-"+eName+"-value").textContent = Number(form["magicDamageAdd"+id].value) + addDamage;
      magicPowers[id] = cLv ? power : 0;
    }
    // 呪歌など
    else if(SET.class[key].craft?.stt){
      document.getElementById("magic-power-"+eName).style.display = cLv ? '' : 'none';
      if(cLv){ openCraft++; }
      
      let power = cLv;
      if     (SET.class[key].craft.stt === '知力')  {
        power += parseInt((stt.Int + stt.addE + (form["magicPowerOwn"+id].checked ? 2 : 0)) / 6);
      }
      else if(SET.class[key].craft.stt === '精神力'){
        power += parseInt((stt.Mnd + stt.addF + (form["magicPowerOwn"+id].checked ? 2 : 0)) / 6);
      }
      if(SET.class[key].craft.power){
        power += Number(form["magicPowerAdd"+id].value);
        document.getElementById("magic-power-"+eName+"-value").textContent  = power;
        document.getElementById("magic-damage-"+eName+"-value").textContent = Number(form["magicDamageAdd"+id].value);
      }
      
      if(id === 'Alc'){ power += feats['賦術強化'] || 0 }
      document.getElementById("magic-cast-"+eName+"-value").textContent = power + Number(form["magicCastAdd"+id].value);
    }
  }
  // 全体／その他の開閉
  document.getElementById("magic-power").style.display = (openMagic || openCraft) ? '' : 'none';

  document.getElementById("magic-power-raceability" ).style.display
    = raceAbilities.includes('魔法の申し子') ? ''
    : raceAbilities.includes('神の御名と共に') && level >= 6 ? ''
    : raceAbilities.includes('神への礼賛') && level >= 6 ? ''
    : raceAbilities.includes('神への祈り') && level >= 6 ? ''
    : 'none';
  document.getElementById("magic-power-magicenhance").style.display = feats['魔力強化']      ? '' : 'none';
  document.getElementById("magic-power-common"      ).style.display = openMagic              ? '' : 'none';
  document.getElementById("magic-power-hr"          ).style.display = openMagic && openCraft ? '' : 'none';
}

// 妖精魔法ランク計算 ----------------------------------------
function calcFairy() {
  const rank = {
      4 : ['×','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15'],
      3 : ['×','×','×','4','5','6','8','9','10','12','13','14','15','15','15','15'],
      6 : ['×','×','×','2&1','3&1','4&1','4&2','5&2','6&2','6&3','7&3','8&3','8&4','9&4','10&4','10&5'],
  };
  let i = 0;
  Array('Earth','Water','Fire','Wind','Light','Dark').forEach((s) => {
    if(form[`fairyContract${s}`].checked){ i++ }
  });
  let result = '×';
  if(rank[i]){ result = rank[i][lv['Fai']] || '×'; }
  else { result = '×'; }
  document.getElementById('fairy-rank').textContent = result;
}

// 攻撃計算 ----------------------------------------
function calcAttack() {
  for(const name in SET.class){
    if(SET.class[name].type !== 'weapon-user'){ continue; }
    const id    = SET.class[name].id;
    const eName = SET.class[name].eName;
    document.getElementById(`attack-${eName}`).style.display = lv[id] > 0 ? "" :"none";
    document.getElementById(`attack-${eName}-str`).textContent = id == 'Fen' ? reqdStrHalf : reqdStr;
    document.getElementById(`attack-${eName}-acc`).textContent = lv[id] + bonus.Dex;
    document.getElementById(`attack-${eName}-dmg`).textContent = lv[id] + bonus.Str;
  }
  document.getElementById("attack-enhancer"  ).style.display = lv['Enh'] >= 10 ? "" :"none";
  document.getElementById("attack-enhancer-str").textContent   = reqdStr;
  document.getElementById("attack-enhancer-acc"  ).textContent = lv['Enh'] + bonus.Dex;
  document.getElementById("attack-enhancer-dmg"  ).textContent = lv['Enh'] + bonus.Str;

  document.getElementById("attack-demonruler").style.display = lv['Dem'] >= 10 ? "" : modeZero && lv['Dem'] > 0 ? "" :"none";
  document.getElementById("attack-demonruler-str").textContent = reqdStr;
  document.getElementById("attack-demonruler-acc").textContent = lv['Dem'] + bonus.Dex;
  document.getElementById("attack-demonruler-dmg").textContent = modeZero ? lv['Dem'] + bonus.Str : '―';

  for(let i = 0; i < SET.weapons.length; i++){
    document.getElementById(`attack-${SET.weapons[i][1]}-mastery`).style.display = feats['武器習熟／'+SET.weapons[i][0]] ? '' : 'none';
    document.getElementById(`attack-${SET.weapons[i][1]}-mastery-dmg`).textContent = feats['武器習熟／'+SET.weapons[i][0]] || 0;
  }
  document.getElementById("attack-artisan-mastery").style.display  = feats['魔器習熟'] ? '' : 'none';
  document.getElementById("attack-artisan-mastery-dmg").textContent  = feats['魔器習熟'] || 0 ;
  document.getElementById("artisan-annotate").style.display        = feats['魔器習熟'] ? '' : 'none'; 
  document.getElementById("accuracy-enhance").style.display        = feats['命中強化'] ? '' : 'none';
  document.getElementById("accuracy-enhance-acc").textContent        = feats['命中強化'] || 0;
  document.getElementById("throwing").style.display                = feats['スローイング'] ? '' : 'none';

  calcWeapon();
}
function calcWeapon() {
  for (let i = 1; i <= form.weaponNum.value; i++){
    const className = form["weapon"+i+"Class"].value;
    const category = form["weapon"+i+"Category"].value;
    const ownDex = form["weapon"+i+"Own"].checked ? 2 : 0;
    const note = form["weapon"+i+"Note"].value;
    const weaponReqd = safeEval(form["weapon"+i+"Reqd"].value) || 0;
    let attackClass = 0;
    let accBase = 0;
    let dmgBase = 0;
    let maxReqd = reqdStr;
    accBase += feats['命中強化'] || 0; //命中強化
    // 使用技能
    if(SET.class[className]?.type == 'weapon-user'){
      attackClass = lv[ SET.class[className].id ];
      if(className === "フェンサー"){ maxReqd = reqdStrHalf; }
    }
    else if(className === "エンハンサー")     { attackClass = lv['Enh']; }
    else if(className === "デーモンルーラー") { attackClass = lv['Dem']; }
    // 必筋チェック
    form["weapon"+i+"Reqd"].classList.toggle('error', weaponReqd > maxReqd);
    // 武器カテゴリ
    if(attackClass) {
      // 基礎命中
      accBase += attackClass + parseInt((stt.Dex + stt.addA + ownDex) / 6);
    }
    // 基礎ダメージ
    if     (category === 'クロスボウ')                  { dmgBase = attackClass; }
    else if(category === 'ガン')                        { dmgBase = magicPowers['Mag']; }
    else if(!modeZero && className === "デーモンルーラー"){ dmgBase = magicPowers['Dem']; }
    else if(attackClass)                                { dmgBase = attackClass + bonus.Str; }
    form["weapon"+i+"Category"].classList.remove('fail');

    // 習熟
    if(category === 'ガン（物理）') { dmgBase += feats['武器習熟／ガン'] || 0; }
    else if(category) { dmgBase += feats['武器習熟／'+category] || 0; }

    if(category === '投擲') { accBase += feats['スローイング'] ? 1 : 0; }
    if(note.match(/〈魔器〉/)){ dmgBase += feats['魔器習熟'] || 0; }
    // 命中追加D出力
    if(className === "自動計算しない"){
      document.getElementById("weapon"+i+"-acc-total").textContent = Number(form["weapon"+i+"Acc"].value);
      document.getElementById("weapon"+i+"-dmg-total").textContent = Number(form["weapon"+i+"Dmg"].value);
    }
    else {
      document.getElementById("weapon"+i+"-acc-total").textContent = accBase + Number(form["weapon"+i+"Acc"].value);
      document.getElementById("weapon"+i+"-dmg-total").textContent = dmgBase + Number(form["weapon"+i+"Dmg"].value);
    }
  }
}

// 防御計算 ----------------------------------------
function calcDefense() {
  const className = form.evasionClass.options[form.evasionClass.selectedIndex].value;
  let evaClassLv = 0;
  let evaBase = 0;
  let evaAdd = 0;
  let defBase = 0;
  if(SET.class[className]?.type == 'weapon-user'){
    evaClassLv = lv[ SET.class[className].id ];
  }
  else if(className === "デーモンルーラー"){ evaClassLv = lv['Dem']; }
  else { evaClassLv = 0; }
  evaBase = evaClassLv || 0;
  
  const maxReqd = (className === "フェンサー") ? reqdStrHalf : reqdStr;
  document.getElementById("evasion-str").textContent = maxReqd;
  document.getElementById("evasion-eva").textContent = evaClassLv ? (evaClassLv + bonus.Agi) : 0;
  
  // 技能選択のエラー表示
  let cL = document.getElementById("evasion-classes").classList;
  if(className === "シューター" && !feats['射手の体術'] || className === "デーモンルーラー" && lv['Dem'] < 2){ 
    cL.add('error');
  }
  else { cL.remove('error'); }
  
  // 種族特徴
  defBase += raceAbilityDef;
  document.getElementById("race-ability-def").style.display = raceAbilityDef > 0 ? "" :"none";
  document.getElementById("race-ability-def-value").textContent  = raceAbilityDef;
  // 求道者
  if(form.lvSeeker){
    const seekerDefense = lvSeeker >= 18 ? 10
                        : lvSeeker >= 14 ?  8
                        : lvSeeker >= 10 ?  6
                        : lvSeeker >=  6 ?  4
                        : lvSeeker >=  2 ?  2
                        : 0;
    defBase += seekerDefense;
    document.getElementById('seeker-defense-value').textContent = seekerDefense;
  }
  // 習熟
  document.getElementById("mastery-metalarmour").style.display    = feats['防具習熟／金属鎧']   > 0 ? "" :"none";
  document.getElementById("mastery-nonmetalarmour").style.display = feats['防具習熟／非金属鎧'] > 0 ? "" :"none";
  document.getElementById("mastery-shield").style.display         = feats['防具習熟／盾']       > 0 ? "" :"none";
  document.getElementById("mastery-artisan-def").style.display    = feats['魔器習熟']           > 0 ? "" :"none";
  document.getElementById("mastery-metalarmour-value").textContent    = feats['防具習熟／金属鎧']   || 0;
  document.getElementById("mastery-nonmetalarmour-value").textContent = feats['防具習熟／非金属鎧'] || 0;
  document.getElementById("mastery-shield-value").textContent         = feats['防具習熟／盾']       || 0;
  document.getElementById("mastery-artisan-def-value").textContent    = feats['魔器習熟']           || 0;
  // 回避行動
  evaAdd += feats['回避行動'] || 0;
  document.getElementById("evasive-maneuver").style.display = feats['回避行動'] > 0 ? "" :"none";
  document.getElementById("evasive-maneuver-value").textContent = feats['回避行動'] || 0;
  // 心眼
  evaAdd += feats['心眼'] || 0;
  document.getElementById("minds-eye").style.display = feats['心眼'] > 0 ? "" :"none";
  document.getElementById("minds-eye-value").textContent = feats['心眼'] || 0;
  
  calcArmour(evaBase,evaAdd,defBase,maxReqd);
}
function calcArmour(evaBase,evaAdd,defBase,maxReqd) {
  let count = { 鎧:0, 盾:0, 他:0 };
  let checkedCount = { 鎧:{}, 盾:{}, 他:{} };

  for (let num = 1; num <= form.armourNum.value; num++){
    const category = form[`armour${num}Category`].value;
    let type = category.match(/鎧|盾|他/) ? category.match(/鎧|盾|他/)[0] : '';
    if(num == 1 && !type){ type = '鎧' }
    if(type){ count[type]++ }

    form[`armour${num}Reqd`].classList.toggle('error', (safeEval(form[`armour${num}Reqd`].value) || 0) > maxReqd);
    form[`armour${num}Own`].style.display = category.match(/鎧|盾/) ? '' : 'none';

    
    form[`armour${num}Name`].parentNode.parentNode.querySelector('.type').textContent
      = type ? type+count[type] : '';
    
    for (let i = 1; i <= 3; i++){
      document.querySelector(`input[name="defTotal${i}CheckArmour${num}"] + span`).textContent
        = form[`armour${num}Name`].value ? form[`armour${num}Name`].value
            .replace(/[|｜](.+?)《(.+?)》/g, "$1")
            .replace(/\[([^\[\]]+?)#[0-9a-zA-z\-]+\]/g, "$1")
        : type ? type+count[type]
        : '―';
      
      document.querySelector(`input[name="defTotal${i}CheckArmour${num}"]`).parentNode.style.display
        = (  !form[`armour${num}Name`].value
          && !form[`armour${num}Category`].value
          && !form[`armour${num}Eva`].value
          && !form[`armour${num}Def`].value
          && !form[`armour${num}Own`].checked
          && !type
        ) ? 'none' : '';

      if (type && form[`defTotal${i}CheckArmour${num}`].checked){
        checkedCount[type][i] ??= 0;
        checkedCount[type][i]++;
      }
    }
  }
  
  for (let i = 1; i <= 3; i++){
    let eva = evaAdd;
    let def = defBase;
    let ownAgi = 0;
    let artisanDef = 0;
    for (let num = 1; num <= form.armourNum.value; num++){
      const checkObj = form[`defTotal${i}CheckArmour${num}`];
      checkObj.parentNode.classList.remove('error')

      if(!checkObj.checked) continue;

      const category = form[`armour${num}Category`].value;
      eva += Number(form[`armour${num}Eva`].value);
      def += Number(form[`armour${num}Def`].value) + (feats['防具習熟／'+category] || 0);
      if(category == '盾' && form[`armour${num}Own`].checked){ ownAgi = 2 }
      if(form[`armour${num}Note`].value.match(/〈魔器〉/)){ artisanDef = feats['魔器習熟']; }
      
      let matches = category.match(/(鎧|盾)/);
      if (matches && checkedCount[matches[1]][i] > 1){
        checkObj.parentNode.classList.add('error')
      }
    }
    eva += ( evaBase ? evaBase + parseInt((stt.Agi + stt.addB + ownAgi) / 6) : 0 );
    def += artisanDef;
 
    document.getElementById(`defense-total${i}-eva`).textContent = eva;
    document.getElementById(`defense-total${i}-def`).textContent = def;
  }
  
}

// 経験点計算 ----------------------------------------
function calcExp(){
  expTotal = 0;
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    const obj = form['history'+i+'Exp'];
    let exp = safeEval(obj.value);
    if(isNaN(exp)){
      obj.classList.add('error');
    }
    else {
      expTotal += exp;
      obj.classList.remove('error');
    }
  }
  document.getElementById("exp-rest").textContent = commify(expTotal - expUse);
  document.getElementById("exp-total").textContent = commify(expTotal);
  document.getElementById("history-exp-total").textContent = commify(expTotal);
  
  // 最大成長回数
  let growMax = 0;
  if(SET.growType === 'A'){
    let count = 0;
    let exp = 3000;
    for(let i = 0; exp <= expTotal; i++){
      count = i;
      const next = 1000 + i * 10;
      exp += next;
    }
    growMax = count;
  }
  else if(SET.growType === 'O') {
    growMax = Math.floor((expTotal - 3000) / 1000);
  }
  else { return; }
  document.getElementById("stt-grow-max-value").textContent = ' / ' + growMax;
  document.getElementById("history-grow-max-value").textContent = '/' + growMax;
}


// 名誉点計算 ----------------------------------------
function calcHonor(){
  let pointTotal = 0;
  // 履歴
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    const obj = form['history'+i+'Honor'];
    let point = safeEval(obj.value);
    if(isNaN(point)){
      obj.classList.add('error');
    }
    else {
      pointTotal += point;
      obj.classList.remove('error');
    }
  }
  document.getElementById("history-honor-total").textContent = commify(pointTotal);
  // ランク
  const rank = form["rank"].options[form["rank"].selectedIndex].value;
  const topRank = rank.match(/★$/) ? 1 : 0;
  const rankStar = topRank ? Number(form.rankStar.value||1)-1 : 0;
  form.rankStar.style.display = topRank ? '' : 'none';
  
  const rankNum = (SET.aRank[rank]) ? SET.aRank[rank].num  + rankStar*500 : 0;
  const free    = (SET.aRank[rank]) ? SET.aRank[rank].free + rankStar*50  : 0;
  pointTotal -= rankNum;
  // 名誉アイテム
  const honorItemsNum = form.honorItemsNum.value;
  for (let i = 1; i <= honorItemsNum; i++){
    let point = safeEval(form['honorItem'+i+'Pt'].value) || 0;
    pointTotal -= point;
    
    form['honorItem'+i+'Pt'].classList.toggle('mark', (point && point <= free));
  }
  // 流派
  let mysticArtsPt = 0;
  for (let i = 1; i <= form.mysticArtsNum.value; i++){
    let point = safeEval(form['mysticArts'+i+'Pt'].value) || 0;
    mysticArtsPt += point;
    form['mysticArts'+i+'Pt'].classList.toggle('mark', (point && point <= free));
  }
  for (let i = 1; i <= form.mysticMagicNum.value; i++){
    let point = safeEval(form['mysticMagic'+i+'Pt'].value) || 0;
    mysticArtsPt += point;
    form['mysticMagic'+i+'Pt'].classList.toggle('mark', (point && point <= free));
  }
  pointTotal -= mysticArtsPt;
  //
  pointTotal -= Number(form.honorOffset.value);
  document.getElementById("honor-value"   ).textContent = pointTotal;
  document.getElementById("honor-value-MA").textContent = pointTotal;
  document.getElementById("rank-honor-value").textContent = rankNum;
  document.getElementById("mystic-arts-honor-value").textContent = mysticArtsPt;
  document.getElementById('honor-items-mystic-arts').style.display = mysticArtsPt ? '' : 'none';
}
// 不名誉点計算
function calcDishonor(){
  if(modeZero){ return; }
  let pointTotal = 0;
  const dishonorItemsNum = form.dishonorItemsNum.value;
  for (let i = 1; i <= dishonorItemsNum; i++){
    let point = safeEval(form['dishonorItem'+i+'Pt'].value) || 0;
    pointTotal += point;
  }
  pointTotal -= Number(form.honorOffset.value);
  document.getElementById("dishonor-value").textContent = pointTotal;
  for(const key in SET.nRank){
    if(pointTotal >= SET.nRank[key].num) { document.getElementById("notoriety").textContent = key; }
  }
}

// 収支履歴計算 ----------------------------------------
function calcCash(){
  let cash = 0;
  let deposit = 0;
  let debt = 0;
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    const obj = form['history'+i+'Money'];
    let hCash = safeEval(obj.value);
    if(isNaN(hCash)){
      obj.classList.add('error');
    }
    else {
      cash += hCash;
      obj.classList.remove('error');
    }
    if(isNaN(hCash)){
      obj
    }
  }
  document.getElementById("history-money-total").textContent = commify(cash);
  let s = form.cashbook.value;
  s.replace(
    /::([\+\-\*\/]?[0-9,]+)+/g,
    function (num, idx, old) {
      cash += safeEval(num.slice(2)) || 0;
    }
  );
  s.replace(
    /:>([\+\-\*\/]?[0-9,]+)+/g,
    function (num, idx, old) {
      deposit += safeEval(num.slice(2)) || 0;
    }
  );
  s.replace(
    /:<([\+\-\*\/]?[0-9,]+)+/g,
    function (num, idx, old) {
      debt += safeEval(num.slice(2)) || 0;
    }
  );
  cash = cash - deposit + debt;
  document.getElementById('cashbook-total-value').textContent = commify(cash);
  document.getElementById('cashbook-deposit-value').textContent = commify(deposit);
  document.getElementById('cashbook-debt-value').textContent = commify(debt);
}

// 装飾品欄 ----------------------------------------
function addAccessory(check,name){
  if(check.checked) {
    document.querySelector(`#accessories [data-type="${name}_"]`).style.display = '';
  }
  else {
    document.querySelector(`#accessories [data-type="${name}_"]`).style.display = 'none';
  }
}
// ソート
let accesorySortable = Sortable.create(document.getElementById('accessories-table'), {
  group: "accessories",
  animation: 200,
  handle: 'th',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  swap: true,
  onUpdate: function(evt){
    let beforeId   = evt.item.id;
    let afterId    = evt.swapItem.id;
    let beforeType = evt.item.dataset.type;
    let afterType  = evt.swapItem.dataset.type;
    evt.item.dataset.type     = afterType;
    evt.swapItem.dataset.type = beforeType;
    
    const beforeTitle = document.querySelector(`#${beforeId} th`).textContent;
    document.querySelector(`#${beforeId} th`).textContent = document.querySelector(`#${afterId} th`).textContent;
    document.querySelector(`#${afterId} th`).textContent = beforeTitle;
    
    const beforeCheck = document.querySelector(`#${beforeId} [name$="Add"]`) ? document.querySelector(`#${beforeId} [name$="Add"]`).checked : false;
    const AfterCheck = document.querySelector(`#${afterId} [name$="Add"]`) ? document.querySelector(`#${afterId} [name$="Add"]`).checked : false;
    const beforeCheckBox = document.querySelector(`#${beforeId} td:first-child`).innerHTML;
    document.querySelector(`#${beforeId} td:first-child`).innerHTML = document.querySelector(`#${afterId} td:first-child`).innerHTML;
    document.querySelector(`#${afterId} td:first-child`).innerHTML = beforeCheckBox;
    if(document.querySelector(`#${beforeId} [name$="Add"]`)){ document.querySelector(`#${beforeId} [name$="Add"]`).checked = AfterCheck; }
    if(document.querySelector(`#${afterId} [name$="Add"]`)){ document.querySelector(`#${afterId} [name$="Add"]`).checked = beforeCheck; }
    
    document.querySelector(`#${beforeId} [name$="Name"]`).setAttribute('name',`accessory${afterType}Name`);
    document.querySelector(`#${beforeId} [name$="Own"]` ).setAttribute('name',`accessory${afterType}Own`);
    document.querySelector(`#${beforeId} [name$="Note"]`).setAttribute('name',`accessory${afterType}Note`);
    document.querySelector(`#${afterId} [name$="Name"]`).setAttribute('name',`accessory${beforeType}Name`);
    document.querySelector(`#${afterId} [name$="Own"]` ).setAttribute('name',`accessory${beforeType}Own`);
    document.querySelector(`#${afterId} [name$="Note"]`).setAttribute('name',`accessory${beforeType}Note`);
  }
});

// 秘伝欄 ----------------------------------------
// 追加
function addMysticArts(){
  let num = Number(form.mysticArtsNum.value) + 1;

  let row = document.querySelector('#mystic-arts-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('mystic-arts-item');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#mystic-arts-list").append(row);

  form.mysticArtsNum.value = num;
}
// 削除
function delMysticArts(){
  let num = Number(form.mysticArtsNum.value);
  if(num > 0){
    if(form[`mysticArts${num}`].value || form[`mysticArts${num}Pt`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#mystic-arts-list li:last-of-type").remove();
    num--;
    form.mysticArtsNum.value = num;
  }
  calcHonor();
}
// ソート
let mysticArtsSortable = Sortable.create(document.querySelector('#mystic-arts-list'), {
  group: "mysticarts",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = mysticArtsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`li#${id}`)){
        document.querySelector(`#${id} input:first-of-type`).setAttribute('name',`mysticArts${num}`);
        document.querySelector(`#${id} [name$="Pt"]`).setAttribute('name',`mysticArts${num}Pt`);
        if(modeZero){ document.querySelector(`#${id} [name$="PtType"]`).setAttribute('name',`mysticArts${num}PtType`); }
        num++;
      }
    }
  }
});
// 秘伝魔法欄 ----------------------------------------
// 追加
function addMysticMagic(){
  let num = Number(form.mysticMagicNum.value) + 1;

  let row = document.querySelector('#mystic-magic-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('mystic-magic-item');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#mystic-magic-list").append(row);
  
  form.mysticMagicNum.value = num;
}
// 削除
function delMysticMagic(){
  let num = Number(form.mysticMagicNum.value);
  if(num > 0){
    if(form[`mysticMagic${num}`].value || form[`mysticMagic${num}Pt`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#mystic-magic-list li:last-of-type").remove();
    num--;
    form.mysticMagicNum.value = num;
  }
  calcHonor();
}
// ソート
let mysticMagicSortable = Sortable.create(document.querySelector('#mystic-magic-list'), {
  group: "mysticmagic",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = mysticMagicSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`li#${id}`)){
        document.querySelector(`#${id} input:first-of-type`).setAttribute('name',`mysticMagic${num}`);
        document.querySelector(`#${id} [name$="Pt"]`).setAttribute('name',`mysticMagic${num}Pt`);
        num++;
      }
    }
  }
});

// 言語欄 ----------------------------------------
function checkLanguage(){
  let count = {}; let acqT = {}; let acqR = {};
  if(SET.races[race]?.language){
    for(let data of SET.races[race].language){ acqT[data[0]] = data[1]; acqR[data[0]] = data[2]; }
  }
  for (let i = 1; i <= form.languageNum.value; i++){
    let name = form[`language${i}`];
    let talk = form[`language${i}Talk`];
    let read = form[`language${i}Read`];
    
    acqT[name.value.trim()] = talk.dataset.type = talk.value;
    acqR[name.value.trim()] = read.dataset.type = read.value;
    count[talk.value] ||= 0; count[talk.value]++;
    count[read.value] ||= 0; count[read.value]++;
  }
  let notice = '';
  for (let key in SET.class){
    if(!SET.class[key].language){ continue; }
    const className = key;
    const classId = SET.class[key].id;
    const classLv = lv[ classId ];
    for (let langName in SET.class[key].language){
      const data = SET.class[key].language[langName];
      const notT = (data.talk && !acqT[langName]) ? true : false;
      const notR = (data.read && !acqR[langName]) ? true : false;
      if(langName === 'any'){
        const v = classLv - (count[classId] || 0);
        if     (v > 0){ notice += `${className}技能であと「${v}」習得できます<br>`; }
        else if(v < 0){ notice += `${className}技能での習得が「${v*-1}」過剰です<br>`; }
      }
      else if(classLv && (notT || notR)) {
        notice += `${langName}の`;
        if(notT){ acqT[langName] = true; notice += `会話`+(notR ? '/' : '');  }
        if(notR){ acqR[langName] = true; notice += `読文`;  }
        notice += `が習得できます<br>`;
      }
    }
  }
  document.getElementById('language-notice').innerHTML = notice;
}
// 追加
function addLanguage(){
  let num = Number(form.languageNum.value) + 1;

  let row = document.querySelector('#language-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('language-item');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#language-table tbody").append(row);

  form.languageNum.value = num;
}
// 削除
function delLanguage(){
  let num = Number(form.languageNum.value);
  if(num > 1){
    if(form[`language${num}`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#language-table tbody tr:last-of-type").remove();
    num--;
    form.languageNum.value = num;
  }
}
// ソート
let languageSortable = Sortable.create(document.querySelector('#language-table tbody'), {
  group: "language",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = languageSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} input:first-child`).setAttribute('name',`language${num}`);
        document.querySelector(`#${id} [name$="Talk"]`).setAttribute('name',`language${num}Talk`);
        document.querySelector(`#${id} [name$="Read"]`).setAttribute('name',`language${num}Read`);
        num++;
      }
    }
  }
});


// 武器欄 ----------------------------------------
// 追加
function addWeapons(copy){
  let num = Number(form.weaponNum.value) + 1;

  let row = document.querySelector('#weapon-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('weapons-row');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#weapons-table").append(row);

  if(copy){
    form[`weapon${num}Name`    ].value   = form[`weapon${copy}Name`    ].value;
    form[`weapon${num}Usage`   ].value   = form[`weapon${copy}Usage`   ].value;
    form[`weapon${num}Reqd`    ].value   = form[`weapon${copy}Reqd`    ].value;
    form[`weapon${num}Acc`     ].value   = form[`weapon${copy}Acc`     ].value;
    form[`weapon${num}Rate`    ].value   = form[`weapon${copy}Rate`    ].value;
    form[`weapon${num}Crit`    ].value   = form[`weapon${copy}Crit`    ].value;
    form[`weapon${num}Dmg`     ].value   = form[`weapon${copy}Dmg`     ].value;
    form[`weapon${num}Own`     ].checked = form[`weapon${copy}Own`     ].checked;
    form[`weapon${num}Category`].value   = form[`weapon${copy}Category`].value;
    form[`weapon${num}Class`   ].value   = form[`weapon${copy}Class`   ].value;
    form[`weapon${num}Note`    ].value   = form[`weapon${copy}Note`    ].value;
  }
  
  form.weaponNum.value = num;
}
// 削除
function delWeapons(){
  let num = Number(form.weaponNum.value);
  if(num > 1){
    if(form[`weapon${num}Name`].value || form[`weapon${num}Usage`].value || form[`weapon${num}Reqd`].value || form[`weapon${num}Acc`].value || form[`weapon${num}Rate`].value || form[`weapon${num}Crit`].value || form[`weapon${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#weapons-table tbody:last-of-type").remove();
    num--;
    form.weaponNum.value = num;
  }
}
// ソート
let weaponsSortable = Sortable.create(document.getElementById('weapons-table'), {
  group: "weapons",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = weaponsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tbody#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`weapon${num}Name`);
        document.querySelector(`#${id} [name$="Usage"]`   ).setAttribute('name',`weapon${num}Usage`);
        document.querySelector(`#${id} [name$="Reqd"]`    ).setAttribute('name',`weapon${num}Reqd`);
        document.querySelector(`#${id} [name$="Acc"]`     ).setAttribute('name',`weapon${num}Acc`);
        document.querySelector(`#${id} b[id$=acc-total]`).id = `weapon${num}-acc-total`;
        document.querySelector(`#${id} [name$="Rate"]`    ).setAttribute('name',`weapon${num}Rate`);
        document.querySelector(`#${id} [name$="Crit"]`    ).setAttribute('name',`weapon${num}Crit`);
        document.querySelector(`#${id} [name$="Dmg"]`     ).setAttribute('name',`weapon${num}Dmg`);
        document.querySelector(`#${id} b[id$=dmg-total]`).id = `weapon${num}-dmg-total`;
        document.querySelector(`#${id} [name$="Own"]`     ).setAttribute('name',`weapon${num}Own`);
        document.querySelector(`#${id} [name$="Category"]`).setAttribute('name',`weapon${num}Category`);
        document.querySelector(`#${id} [name$="Class"]`   ).setAttribute('name',`weapon${num}Class`);
        document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`weapon${num}Note`);
        document.querySelector(`#${id} span[onclick]`     ).setAttribute('onclick',`addWeapons(${num})`);
        num++;
      }
    }
  }
});

// 防具欄 ----------------------------------------
// 追加
function addArmour(){
  let num = Number(form.armourNum.value) + 1;

  const id = idNumSet('armour')
  let row = document.querySelector('#armour-template').content.firstElementChild.cloneNode(true);
  row.id = id;
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#armours tbody").append(row);

  let i = 1;
  document.querySelectorAll(".defense-total-checklist").forEach(obj => {
    let checkbox = document.createElement('label')
    checkbox.classList.add('check-button')
    checkbox.innerHTML = `<input type="checkbox" name="defTotal${i}CheckArmour${num}" value="1" oninput="calcDefense()" data-id="${id}"><span></span>`;
    obj.append(checkbox);
    i++;
  });

  form.armourNum.value = num;
}
// 削除
function delArmour(){
  let num = Number(form.armourNum.value);
  if(num > 1){
    if ( form[`armour${num}Name`].value 
      || form[`armour${num}Reqd`].value
      || form[`armour${num}Eva`].value
      || form[`armour${num}Def`].value
      || form[`armour${num}Note`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#armours tbody tr:last-of-type").remove();
    
    document.querySelectorAll(".defense-total-checklist label:last-of-type").forEach(obj => {
      obj.remove();
    });
    num--;
    form.armourNum.value = num;
  }
  calcHonor();
}
// ソート
let armoursSortable = Sortable.create(document.querySelector('#armours table tbody'), {
  group: "armours",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = armoursSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`armour${num}Name`);
        document.querySelector(`#${id} [name$="Category"]`).setAttribute('name',`armour${num}Category`);
        document.querySelector(`#${id} [name$="Reqd"]`    ).setAttribute('name',`armour${num}Reqd`);
        document.querySelector(`#${id} [name$="Eva"]`     ).setAttribute('name',`armour${num}Eva`);
        document.querySelector(`#${id} [name$="Def"]`     ).setAttribute('name',`armour${num}Def`);
        document.querySelector(`#${id} [name$="Own"]`     ).setAttribute('name',`armour${num}Own`);
        document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`armour${num}Note`);
        
        let i = 1;
        document.querySelectorAll(".defense-total-checklist").forEach(row => {
          row.querySelector(`[data-id=${id}]`).setAttribute('name',`defTotal${i}CheckArmour${num}`);
          i++;
        });

        num++;
      }
    }
    calcDefense()
  }
});

// 名誉アイテム欄 ----------------------------------------
// 追加
function addHonorItems(){
  let num = Number(form.honorItemsNum.value) + 1;

  let row = document.querySelector('#honor-item-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('honor-item');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#honor-items-table").append(row);

  form.honorItemsNum.value = num;
}
// 削除
function delHonorItems(){
  let num = Number(form.honorItemsNum.value);
  if(num > 1){
    if(form[`honorItem${num}`].value || form[`honorItem${num}Pt`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#honor-items-table tr:last-of-type").remove();
    num--;
    form.honorItemsNum.value = num;
  }
  calcHonor();
}
// ソート
let honorSortable = Sortable.create(document.querySelector('#honor-items-table'), {
  group: "honor",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = honorSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [type="text"]`  ).setAttribute('name',`honorItem${num}`);
        document.querySelector(`#${id} [type="number"]`).setAttribute('name',`honorItem${num}Pt`);
        if(modeZero){ document.querySelector(`#${id} select`).setAttribute('name',`honorItem${num}PtType`); }
        num++;
      }
    }
  }
});
// 不名誉欄 ----------------------------------------
// 追加
function addDishonorItems(){
  let num = Number(form.dishonorItemsNum.value) + 1;

  let row = document.querySelector('#dishonor-item-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('dishonor-item');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#dishonor-items-table").append(row);

  form.dishonorItemsNum.value = num;
}
// 削除
function delDishonorItems(){
  let num = Number(form.dishonorItemsNum.value);
  if(num > 1){
    if(form[`dishonorItem${num}`].value || form[`dishonorItem${num}Pt`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#dishonor-items-table tr:last-of-type").remove();
    num--;
    form.dishonorItemsNum.value = num;
  }
  calcDishonor();
}
// ソート
let dishonorSortable = Sortable.create(document.querySelector('#dishonor-items-table'), {
  group: "dishonor",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = dishonorSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [type="text"]`  ).setAttribute('name',`dishonorItem${num}`);
        document.querySelector(`#${id} [type="number"]`).setAttribute('name',`dishonorItem${num}Pt`);
        if(modeZero){ document.querySelector(`#${id} select`).setAttribute('name',`dishonorItem${num}PtType`); }
        num++;
      }
    }
  }
});

// 一般技能 ----------------------------------------
// ソート
let commonClassSortable = Sortable.create(document.querySelector('#common-classes-table tbody'), {
  group: "honor",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = commonClassSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [type="text"]`  ).setAttribute('name',`commonClass${num}`);
        document.querySelector(`#${id} [type="number"]`).setAttribute('name',`lvCommon${num}`);
        num++;
      }
    }
  }
});

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  let num = Number(form.historyNum.value) + 1;

  let row = document.querySelector('#history-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('history');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#history-table tbody:last-of-type").after(row);
  
  form.historyNum.value = num;
}
// 削除
function delHistory(){
  let num = Number(form.historyNum.value);
  if(num > 1){
    if(form[`history${num}Date`].value || form[`history${num}Title`].value || form[`history${num}Exp`].value || form[`history${num}Honor`].value || form[`history${num}Money`].value || form[`history${num}Grow`].value || form[`history${num}Gm`].value || form[`history${num}Member`].value || form[`history${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#history-table tbody:last-of-type").remove();
    num--;
    form.historyNum.value = num;
    calcExp(); calcHonor(); calcCash(); calcStt();
  }
}
// ソート
let historySortable = Sortable.create(document.getElementById('history-table'), {
  group: "history",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  scroll: true,
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = historySortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tbody#${id}`)){
        document.querySelector(`#${id} [name$="Date"]`  ).setAttribute('name',`history${num}Date`);
        document.querySelector(`#${id} [name$="Title"]` ).setAttribute('name',`history${num}Title`);
        document.querySelector(`#${id} [name$="Exp"]`   ).setAttribute('name',`history${num}Exp`);
        document.querySelector(`#${id} [name$="Honor"]` ).setAttribute('name',`history${num}Honor`);
        document.querySelector(`#${id} [name$="Money"]` ).setAttribute('name',`history${num}Money`);
        document.querySelector(`#${id} [name$="Grow"]`  ).setAttribute('name',`history${num}Grow`);
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
        if(modeZero){ 
          document.querySelector(`#${id} [name$="HonorType"]`).setAttribute('name',`history${num}HonorType`); }
        num++;
      }
    }
  }
});

// 戦闘用アイテム欄 ----------------------------------------
// ソート
let battleItemsSortable = Sortable.create(document.querySelector('#battle-items-list'), {
  group: "battleitems",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = battleItemsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} input:first-of-type`).setAttribute('name',`battleItem${num}`);
        num++;
      }
    }
  }
});

// 割り振り計算 ----------------------------------------
function calcPointBuy() {
  const type = String(form.pointbuyType.value || '2.5');
  
  let points = 0;
  let errorFlag = 0;
  ['A','B','C','D','E','F'].forEach((i) => { form[`sttBase${i}`].classList.remove('error') });
  if(SET.races[race]?.dice){
    ['A','B','C','D','E','F'].forEach((i) => {
      const dice = String(SET.races[race].dice[i]);
      let num  = Number(form[`sttBase${i}`].value);
      if(SET.races[race].dice[`${i}+`]){ num -= SET.races[race].dice[`${i}+`]; }
      if(pointBuyList[type] && pointBuyList[type][dice] && pointBuyList[type][dice][num] != null){
        points += pointBuyList[type][dice][num];
      }
      else {
        errorFlag = 1;
        if(form[`sttBase${i}`].value !== ''){ form[`sttBase${i}`].classList.add('error') }
      }
    });
  }
  else {
    errorFlag = 1;
  }
  document.getElementById("stt-pointbuy-AtoF-value").textContent = errorFlag ? '×' : points;

  if(form.birth.value === '冒険者'){
    points = 0;
    errorFlag = 0;
    ['Tec','Phy','Spi'].forEach((i) => {
      const num  = Number(form[`sttBase${i}`].value)
      if(pointBuyList[type] && pointBuyList[type]['tps'][num] != null){
        points += pointBuyList[type]['tps'][num];
      }
      else {
        errorFlag = 1;
      }
    });
    document.getElementById("stt-pointbuy-TPS-value").textContent = errorFlag ? '×' : points;
  }
  else {
    document.getElementById("stt-pointbuy-TPS-value").textContent = '―';
  }
}
const pointBuyList = {
  '2.0': {
    '1' : {
      1 : -15,
      2 : -10,
      3 :  -5,
      4 :   0,
      5 :  10,
      6 :  20,
    },
    '2' : {
       2 : -30,
       3 : -25,
       4 : -20,
       5 : -15,
       6 : -10,
       7 :  -5,
       8 :   0,
       9 :  10,
      10 :  20,
      11 :  40,
      12 :  70,
    },
    'tps' : {
       2 : -100,
       3 :  -80,
       4 :  -60,
       5 :  -40,
       6 :  -20,
       7 :    0,
       8 :   20,
       9 :   40,
      10 :   60,
      11 :  100,
      12 :  160,
    },
  },
  '2.5': {
    '1' : {
      1 : -15,
      2 : -10,
      3 :  -5,
      4 :   5,
      5 :  10,
      6 :  20,
    },
    '2' : {
       2 : -25,
       3 : -20,
       4 : -15,
       5 : -10,
       6 :  -5,
       7 :   0,
       8 :   5,
       9 :  10,
      10 :  20,
      11 :  40,
      12 :  70,
    },
    'tps' : {
       2 : -100,
       3 :  -80,
       4 :  -60,
       5 :  -40,
       6 :  -20,
       7 :    0,
       8 :   20,
       9 :   40,
      10 :   70,
      11 :  110,
      12 :  160,
    },
  }
}
