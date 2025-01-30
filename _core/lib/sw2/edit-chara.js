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

  setName();
  race = form.race.value;
  
  setArmourType();
  checkLvCap();
  calcExp();
  calcLv();
  checkRace();
  checkEquipMod();
  calcStt();
  calcCash();
  calcHonor();
  calcDishonor();
  calcCommonClass();
  calcManaGems();
  checkEffectAll();
  setupBracketInputCompletion();
  
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

// 16レベル以上の解禁 ----------------------------------------
function checkLvCap() {
  const checkbox = form.unlockAbove16;
  const unlockedAbove16 = checkbox?.checked ?? true;

  document.querySelectorAll('#classes input[type="number"][name^="lv"][max]').forEach(
      input => {
        input.setAttribute('max', unlockedAbove16 ? '17' : '15');

        if (!unlockedAbove16 && input.value.match(/^1[67]$/)) {
          input.value = '15';
          input.dispatchEvent(new Event('input'));
        }
      }
  );
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
  console.log('calcLv()');
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
function changeRace(raceNew){
  const raceBefore = race;
  
  let inputtedSin = false;
  if((SET.races[raceBefore]?.sin||0) != form.sin.value && !form.sin.readOnly){
    inputtedSin = true;
  }
  let inputtedParts = false;
  for(const node of document.querySelectorAll(`#parts table :is([type=text],[type=number])`)){
    if(node.value){
      inputtedParts = true;
      break;
    }
  }
  if((inputtedSin || inputtedParts) && SET.races[raceNew]) {
    const confirmCheck = confirm(
      '種族を変更すると、'
      +(inputtedSin ? '“穢れ”の値の変更':'')
      +(inputtedSin && inputtedParts ? 'と':'')
      +(inputtedParts ? '「部位」欄の各入力値':'')
      +'がリセットされます。本当に変更しますか？'
    );
    if (!confirmCheck) {
      form.race.value = raceBefore;
      return;
    }
  }

  race = raceNew;
  
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
  form.sin.value = SET.races[race]?.sin || 0;
  if(form.sin.readOnly){ checkEffectAll(); }
  
  if(SET.races[race]?.parts){
    let num = 1;
    form.partNum.value = 0;
    document.querySelectorAll(`#parts table tbody > tr`).forEach(tr => tr.remove() )
    for(const name of SET.races[race].parts){
      addPart();
      form[`part${num}Name`].value = name;
      num++;
    }
    form.partCore.value = 1;
    document.getElementById('parts').open = true;
  }
  else if(SET.races[race]){
    form.partNum.value = 0;
    document.querySelectorAll(`#parts table tbody > tr`).forEach(tr => tr.remove() )
    document.getElementById('parts').open = false;
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
  console.log('checkRace()');
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

  const raceBase = race.replace(/（.+?）/, '');
  document.querySelectorAll('[data-race-only]').forEach(node => {
    if(!SET.races[race] || node.dataset.raceOnly == raceBase){ node.style.display = '' }
    else { node.style.display = 'none' }
  });

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
          while(SET.races[race]?.abilityReplace?.[ability]
            && level >= SET.races[race]?.abilityReplace[ability].lv
          ){
            if(SET.races[race]?.abilityReplace[ability].before == ability){ break; }
            ability = SET.races[race]?.abilityReplace[ability].before;
          }
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
  if(raceAbilities.includes('見えざる手')){
    document.getElementById("accessory-rowOther2").style.display = '';
    document.getElementById("accessory-rowOther3").style.display = (level >=  6) ? '' : 'none';
    document.getElementById("accessory-rowOther4").style.display = (level >= 16) ? '' : 'none';
    addAccessory('Other2');
    addAccessory('Other2_');
    addAccessory('Other3');
    addAccessory('Other3_');
    addAccessory('Other4');
    addAccessory('Other4_');
  }
  else {
    document.getElementById("accessory-rowOther2"  ).style.display = 
    document.getElementById("accessory-rowOther2_" ).style.display = 
    document.getElementById("accessory-rowOther2__").style.display = 
    document.getElementById("accessory-rowOther3"  ).style.display = 
    document.getElementById("accessory-rowOther3_" ).style.display = 
    document.getElementById("accessory-rowOther3__").style.display = 
    document.getElementById("accessory-rowOther4"  ).style.display = 
    document.getElementById("accessory-rowOther4_" ).style.display = 
    document.getElementById("accessory-rowOther4__").style.display = 'none';
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
let stt = {};
let bonus = {}
function calcStt() {
  console.log('calcStt()');
  stt = {
    Dex:0, addA:0, growDex:0,
    Agi:0, addB:0, growAgi:0,
    Str:0, addC:0, growStr:0,
    Vit:0, addD:0, growVit:0,
    Int:0, addE:0, growInt:0,
    Mnd:0, addF:0, growMnd:0,
  };
  bonus = {
    Dex:0,
    Agi:0,
    Str:0,
    Vit:0,
    Int:0,
    Mnd:0,
  }
  // 履歴から成長カウント
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
  let preGrowTotal = 0;
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
    const preGrow = Number(form['sttPreGrow'+i[0]].value);
    stt['grow'+i[1]] += preGrow + seekerGrow;
    preGrowTotal += preGrow;
    document.getElementById(`stt-grow-${i[0]}-value`).textContent = stt['grow'+i[1]];
    growTotal += stt['grow'+i[1]]; //成長回数合計

    // 種族特徴による修正
    const raceMod = SET.races[race]?.statusMod?.[i[1]] || 0;
    // 合計
    stt[i[1]] = base + Number(form['sttBase'+i[0]].value) + stt['grow'+i[1]] + raceMod;
    document.getElementById(`stt-${i[1].toLowerCase()}-value`).innerHTML = `<span>${modStatus(raceMod)}${stt[i[1]]}</span>`;

    // 増強
    stt['add'+i[0]] = Number(form['sttAdd'+i[0]].value);

    // 合計
    stt['total'+i[1]] = stt[i[1]] + stt['add'+i[0]] + (equipMod[i[0]] || 0);
    document.getElementById(`stt-equip-${i[0]}-value`).textContent = equipMod[i[0]];

    // ボーナス
    document.getElementById(`stt-bonus-${i[1].toLowerCase()}-value`).textContent
      = bonus[i[1]]
      = parseInt((stt['total'+i[1]]) / 6);
  }

  document.getElementById("stt-grow-total-value").textContent = growTotal;
  document.getElementById("history-grow-total-value").textContent = growTotal;
  document.querySelector('#regulation > dl:first-of-type dt.grow').dataset.total = preGrowTotal.toString();
  
  function modStatus(value){
    if(value > 0){ return `<span class="small">+${value}=</span>` }
    if(value < 0){ return `<span class="small">${value}=</span>` }
    return ''
  }
  
  reqdStr = stt.totalStr;
  reqdStrHalf = Math.ceil(reqdStr / 2);
  
  checkFeats();
  calcSubStt();
  calcMobility();
  calcPackage();
  calcMagic();
  calcParts();
  calcAttack();
  calcDefense();
  calcPointBuy();
}

// 戦闘特技チェック ----------------------------------------
let feats = {};
function checkFeats(){
  console.log('checkFeats()');
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
      else if (feat.match(/超頑強/)){
        if((lv['Fig'] < 7 && lv['Gra'] < 7)|| !acquire.match('頑強')){ cL.add("error"); }
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
      else if (feat.match(/カニングキャスト/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 13) { (auto) ? box.value = "カニングキャストⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 13) { (auto) ? box.value = "カニングキャストⅠ" : cL.add("error") }
        }
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
      else if (feat.match(/抵抗強化/)){
        if(level < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 11) { (auto) ? box.value = "抵抗強化Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 11) { (auto) ? box.value = "抵抗強化Ⅰ" : cL.add("error") }
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
      acquire += feat + ',';
      
      const weaponsRegex = new RegExp('武器習熟(Ａ|Ｓ)／(' + SET.weapons.map(d => d[0]).join('|') + ')');
      if     (feat === "回避行動Ⅰ"){ feats['回避行動'] = 1; }
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
      else { feats[feat] = true; }
      
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
  calcParts();
  calcAttack();
  calcDefense();
  checkCraft();
}

// 技芸 ----------------------------------------
let crafts = {};
function checkCraft() {
  crafts = {};
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
          const craftName = form["craft"+ucfirst(eName)+i].value;
          if(craftName){ crafts[craftName] = true }
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
let subStt = {};
function calcSubStt() {
  subStt = {};
  const seekerHpMpAdd = (lvSeeker && checkSeekerAbility('ＨＰ、ＭＰ上昇')) ? 10 : 0;
  const seekerResistAdd = (lvSeeker && checkSeekerAbility('抵抗力上昇')) ? 3 : 0;
  
  const vitResistBase = level + bonus.Vit;
  const mndResistBase = level + bonus.Mnd;
  const vitResistAutoAdd = (equipMod.VResist||0) + 0 + (feats['抵抗強化'] || 0) + seekerResistAdd;
  const mndResistAutoAdd = (equipMod.MResist||0) + raceAbilityMndResist + (feats['抵抗強化'] || 0) + seekerResistAdd;
  document.getElementById("vit-resist-base").textContent = vitResistBase;
  document.getElementById("mnd-resist-base").textContent = mndResistBase;
  document.getElementById("vit-resist-auto-add").textContent = vitResistAutoAdd;
  document.getElementById("mnd-resist-auto-add").textContent = mndResistAutoAdd;
  document.getElementById("vit-resist-total").textContent = vitResistBase + Number(form.vitResistAdd.value) + vitResistAutoAdd;
  document.getElementById("mnd-resist-total").textContent = mndResistBase + Number(form.mndResistAdd.value) + mndResistAutoAdd;
  
  subStt.hpBase = level * 3 + stt.totalVit;
  subStt.mpBase = 
    (raceAbilities.includes('溢れるマナ')) ? (level * 3 + stt.totalMnd)
    : ( levelCasters.reduce((a,x) => a+x,0) * 3 + stt.totalMnd );
  subStt.hpAutoAdd = (feats['頑強'] || 0) + (lv['Fig'] >= 7 ? 15 : 0) + seekerHpMpAdd;
  subStt.mpAutoAdd = (feats['キャパシティ'] || 0) + raceAbilityMp     + seekerHpMpAdd;
  subStt.hpAccessory = 0;
  subStt.mpAccessory = 0;
  for (let type of ["Head", "Face",  "Ear", "Neck", "Back", "HandR", "HandL", "Waist", "Leg", "Other", "Other2", "Other3", "Other4"]){
    for (let add of ['','_','__']){
      const name = type + add;
      if(form["accessory"+name+"Own"].value === "HP"){ subStt.hpAccessory = 2 }
      if(form["accessory"+name+"Own"].value === "MP"){ subStt.mpAccessory = 2 }
    }
  }
  subStt.hpTotal = subStt.hpBase + Number(form.hpAdd.value) + subStt.hpAutoAdd + subStt.hpAccessory;
  subStt.mpTotal = subStt.mpBase + Number(form.mpAdd.value) + subStt.mpAutoAdd + subStt.mpAccessory;
  document.getElementById("hp-base").textContent = subStt.hpBase;
  document.getElementById("mp-base").textContent = raceAbilities.includes('マナ不干渉') ? '0' : subStt.mpBase;
  document.getElementById("hp-auto-add").textContent = subStt.hpAutoAdd;
  document.getElementById("mp-auto-add").textContent = subStt.mpAutoAdd;
  document.getElementById("hp-total").textContent = subStt.hpTotal
  document.getElementById("mp-total").textContent = raceAbilities.includes('マナ不干渉') ? 'なし' : subStt.mpTotal;
}

// 移動力計算 ----------------------------------------
function calcMobility() {
  const agi = stt.totalAgi;
  const mobilityBase = (raceAbilities.includes('半馬半人') ? (agi * 2) : agi);
  let mobilityOwn = 0;
  for (let num = 1; num <= form.armourNum.value; num++){
    if(form[`armour${num}Category`].value.match(/鎧/) && form[`armour${num}Own`].checked){
      mobilityOwn = 2;
      break;
    }
  }
  const mobilityMod = Number(form.mobilityAdd.value) + (equipMod.Mobility||0) + mobilityOwn
  const mobility = mobilityBase + mobilityMod;
  document.getElementById("mobility-limited").textContent = Math.min(feats['足さばき'] ? 10 : 3, mobility);
  document.getElementById("mobility-base").textContent = mobilityBase + (mobilityMod?`+${mobilityMod}`:'');
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
      
      let rows = 0;
      for(const pId in pData){
        let autoBonus = 0;
        let disabled = false;
        if(pData[pId].unlockCraft && !crafts[pData[pId].unlockCraft]){
          disabled = true;
        }
        if(cId === 'War' && pId === 'Int' && crafts['陣率：軍師の知略']){
          autoBonus += 1;
        }
        if(!disabled){ rows++; }
        
        let value = disabled ? 0 : (cLv + bonus[alphabetToStt[pData[pId].stt]] + Number(form[`pack${cId}${pId}Add`].value) + autoBonus);
        document.getElementById(`package-${eName}-${pId.toLowerCase()}-auto`).textContent = autoBonus ? '+'+autoBonus : '';
        document.getElementById(`package-${eName}-${pId.toLowerCase()}`).textContent = value;
        document.getElementById(`package-${eName}-${pId.toLowerCase()}-row`).style.display = disabled ? 'none' : '';

        if(pData[pId].monsterLore){ lore.push(cLv > 0 ? value : 0); }
        if(pData[pId].initiative ){ init.push(cLv > 0 ? value : 0); }
      }
      document.getElementById(`package-${eName}`).style.display = cLv > 0 && rows ? '' : 'none';
    }
  }

  
  document.getElementById("monster-lore-value").textContent = (Math.max(...lore) || 0) + Number(form.monsterLoreAdd.value);
  document.getElementById("initiative-value"  ).textContent = (Math.max(...init) || 0) + Number(form.initiativeAdd.value);
}

// 魔力計算 ----------------------------------------
let magicPowers = {};
function calcMagic() {
  const addPower = Number(form.magicPowerAdd.value) + (feats['魔力強化']||0)+(equipMod.MagicPower||0);
  const addCast = Number(form.magicCastAdd.value)+(equipMod.MagicCast||0);
  const addDamage = Number(form.magicDamageAdd.value)+(equipMod.MagicDamage||0);

  document.getElementById("magic-power-equip-value" ).textContent = formatNumber(equipMod.MagicPower );
  document.getElementById("magic-cast-equip-value"  ).textContent = formatNumber(equipMod.MagicCast  );
  document.getElementById("magic-damage-equip-value").textContent = formatNumber(equipMod.MagicDamage);
  
  let openMagic = 0;
  let openCraft = 0;
  for(const key in SET.class){
    const id = SET.class[key].id
    const cLv = lv[id];
    const eName = SET.class[key].eName;
    // 魔法
    if(SET.class[key].magic){
      document.getElementById("magic-power-"+eName).style.display = cLv ? '' : 'none';
      for(let num = 1; num <= form.paletteMagicNum.value; num++){
        form[`paletteMagic${num}Check${id}`].disabled = cLv ? false : true;
      }
      if(cLv){ openMagic++; }
      
      const seekerMagicAdd = (lvSeeker && checkSeekerAbility('魔力上昇') && cLv >= 15) ? 3 : 0;
      let power = cLv + parseInt((stt.totalInt + (form["magicPowerOwn"+id].checked ? 2 : 0)) / 6) + Number(form["magicPowerAdd"+id].value) + addPower + seekerMagicAdd + raceAbilityMagicPower;
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
        power += parseInt((stt.totalInt + (form["magicPowerOwn"+id].checked ? 2 : 0)) / 6);
      }
      else if(SET.class[key].craft.stt === '精神力'){
        power += parseInt((stt.totalMnd + (form["magicPowerOwn"+id].checked ? 2 : 0)) / 6);
      }
      if(SET.class[key].craft.power){
        power += Number(form["magicPowerAdd"+id].value);
        document.getElementById("magic-power-"+eName+"-value").textContent  = power;
        document.getElementById("magic-damage-"+eName+"-value").textContent = Number(form["magicDamageAdd"+id].value);
      }
      
      if(id === 'Alc'){ power += feats['賦術強化'] || 0 }
      document.getElementById("magic-cast-"+eName+"-value").textContent = power + Number(form["magicCastAdd"+id].value);
      
      if(SET.class[key].craft?.power){
        magicPowers[id] = cLv ? power : 0;
      }
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

  stylizeVisibleRows(document.querySelectorAll('#magic-power > .edit-table > tbody > tr'))
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

// アイテム名称欄の入力補完時 ----------------------------------------
function setupBracketInputCompletion() {
  document.querySelectorAll('input[type="text"]:is([list="list-item-name"], [list="list-weapon-name"]):not(.support-bracket-input-completion)').forEach(
      input => {
        let lastValue = input.value ?? '';

        input.addEventListener(
            'input',
            e => {
              const newValue = input.value ?? '';

              if (
                  newValue.includes('〈〉') &&
                  (
                      lastValue === '' ||
                      newValue.includes(lastValue) // 部分的に入力されている状態から入力補完が選ばれたケース
                  ) &&
                  !lastValue.includes('〈〉') // 空の括弧がある状態から何かが入力されたときは動作させない（括弧内の前に `[魔]` などを入力するときを想定した措置）
              ) {
                if (input.selectionStart === input.selectionEnd) { // 範囲選択になっていないときのみ動作させる
                  const indexOfEmptyBracket = newValue.indexOf('〈〉');
                  input.selectionStart = input.selectionEnd = indexOfEmptyBracket + 1;
                }
              }

              lastValue = newValue;
            }
        );

        input.classList.add('support-bracket-input-completion');
      }
  );
}

// 部位データ計算 ----------------------------------------
let partStt = {};
function changeParts(){
  console.log('changeParts()');
  calcParts();
  calcAttack();
  calcDefense();
}
function calcParts(){
  console.log('calcParts()');
  let options = '<option value="">';
  for (let num = 1; num <= form.partNum.value; num++){
    const partName = form[`part${num}Name`].value;
    const partData = SET.partsData[ partName ] || {};

    if(partName){ options += `<option value="${num}">${partName}` }

    let def = (partData?.def?.[lv.Phy] || 0);
    let hp  = 0;
    let mp  = 0;
    let defMod = 0;
    let hpMod  = 0;
    let mpMod  = 0;

    if(raceAbilities.includes('蠍人の身体')){
      if(form.partCore.value == num){ def = 0; }
      form.sttPartA.value = Number(form.sttAddA.value||0) + (equipMod.A || 0);
      form.sttPartB.value = Number(form.sttAddB.value||0) + (equipMod.B || 0);
      form.sttPartC.value = Number(form.sttAddC.value||0) + (equipMod.C || 0);
      form.sttPartD.value = Number(form.sttAddD.value||0) + (equipMod.D || 0);
      form.sttPartE.value = Number(form.sttAddE.value||0) + (equipMod.E || 0);
      form.sttPartF.value = Number(form.sttAddF.value||0) + (equipMod.F || 0);
      document.getElementById('parts-stt-add').style.display = 'none';
    }
    else {
      document.getElementById('parts-stt-add').style.display = '';
    }
    // コア
    if(form.partCore.value == num){
      hp += subStt.hpBase + subStt.hpAutoAdd - stt.addD - equipMod.D + Number(form.sttPartD.value||0);
      mp += subStt.mpBase + subStt.mpAutoAdd - stt.addF - equipMod.F + Number(form.sttPartF.value||0);
      if(raceAbilities.includes('蠍人の身体')){
        def = 0;
        hp += subStt.hpAccessory;
        mp += subStt.mpAccessory;
      }
      else {
        let hpAccessory = 0;
        let mpAccessory = 0;
        for (let add of ['','_','__']){
          if(form["accessoryEar"+add+"Own"].value === "HP"){ hpAccessory = 2 }
          if(form["accessoryEar"+add+"Own"].value === "MP"){ mpAccessory = 2 }
        }
        hp += hpAccessory;
        mp += mpAccessory;
      }
      
      if(crafts['コア耐久増強'  ]){ defMod += 1; hpMod += 5; }
      if(crafts['コア耐久超増強']){ defMod += 1; hpMod += 5; }
      if(crafts['コア耐久極増強']){ defMod += 2; hpMod += 10; }
    }
    // その他
    else {
      hp += (partData?.hp?.[lv.Phy] || 0);
      mp += (partData?.mp?.[lv.Phy] || 0);
      if(crafts['部位耐久増強'  ]){ defMod += 1; hpMod += 5; }
      if(crafts['部位耐久超増強']){ defMod += 1; hpMod += 5; }
      if(crafts['部位耐久極増強']){ defMod += 2; hpMod += 10; }
    }
    //
    def += Number(form[`part${num}Def`].value || 0);
    hp  += Number(form[`part${num}Hp`].value || 0);
    mp  += Number(form[`part${num}Mp`].value || 0);

    partStt[num] = {};
    document.querySelector(`#part-row${num} .def .auto-mod`).textContent = defMod? `+${defMod}` : '';
    document.querySelector(`#part-row${num} .hp  .auto-mod`).textContent = hpMod ? `+${hpMod }` : '';
    document.querySelector(`#part-row${num} .mp  .auto-mod`).textContent = mpMod ? `+${mpMod }` : '';
    document.querySelector(`#part-row${num} .def b`).textContent = partStt[num].def = def + defMod;
    document.querySelector(`#part-row${num} .hp  b`).textContent = partStt[num].hp  = hp  + hpMod;
    document.querySelector(`#part-row${num} .mp  b`).textContent = partStt[num].mp  = mp  + mpMod;
  }

  document.querySelectorAll('.defense-total select[name^="evasionPart"],#weapons-table select[name$="Part"]').forEach(node => {
    const selected = node.value
    node.innerHTML = options;
    node.value = selected;
    node.disabled = SET.races[race]?.parts ? false : true;
    node.parentNode.parentNode.style.display = SET.races[race]?.parts ? '' : 'none';
  });
  document.getElementById('parts').style.display
    = SET.races[race]?.parts || !SET.races[race] ? '' : 'none';
}

// 攻撃計算 ----------------------------------------
let errorAccClass = {};
function calcAttack() {
  console.log('calcAttack()');
  errorAccClass = {};
  for(const name in SET.class){
    if(SET.class[name].type !== 'weapon-user' && !SET.class[name].accUnlock){ continue; }
    const id    = SET.class[name].id;
    const eName = SET.class[name].eName;
    const unlockLv = SET.class[name]?.accUnlock?.lv || 1;
    const unlockFeat = SET.class[name]?.accUnlock?.feat || '';
    const unlockCraft = SET.class[name]?.accUnlock?.craft || '';
    let display = '';
    if (lv[id] < unlockLv){ display = 'none' }
    if(unlockFeat){
      let isUnlock = false;
      for(const feat of unlockFeat.split('|')){
        if(feats[feat]){ isUnlock = true; break; }
      }
      if(!isUnlock){ display = 'none' }
    }
    if(unlockCraft){
      let isUnlock = false;
      for(const craft of unlockCraft.split('|')){
        if(crafts[craft]){ isUnlock = true; break; }
      }
      if(!isUnlock){ display = 'none' }
    }
    if(display == 'none'){ errorAccClass[name] = true; }
    document.getElementById(`attack-${eName}`).style.display = display;

    document.getElementById(`attack-${eName}-str`).textContent
      = (id == 'Fen' ? reqdStrHalf
      : SET.class[name]?.accUnlock?.reqd ? stt['total'+SET.class[name]?.accUnlock?.reqd]
      : reqdStr)
      + (equipMod.WeaponReqd ? `+${equipMod.WeaponReqd}` : '');
    
    document.getElementById(`attack-${eName}-acc`).textContent
      = SET.class[name]?.accUnlock?.acc === 'power' ? magicPowers[id]
      : lv[id] + bonus.Dex;
    
    document.getElementById(`attack-${eName}-dmg`).textContent
      = SET.class[name]?.accUnlock?.dmg === 'power' ? magicPowers[id]
      : lv[id] + bonus.Str;
  }

  for(let i = 0; i < SET.weapons.length; i++){
    document.getElementById(`attack-${SET.weapons[i][1]}-mastery`).style.display = feats['武器習熟／'+SET.weapons[i][0]] ? '' : 'none';
    document.getElementById(`attack-${SET.weapons[i][1]}-mastery-dmg`).textContent = feats['武器習熟／'+SET.weapons[i][0]] || 0;
  }
  document.getElementById("attack-artisan-mastery").style.display   = feats['魔器習熟'] ? '' : 'none';
  document.getElementById("attack-artisan-mastery-dmg").textContent = feats['魔器習熟'] || 0 ;
  document.getElementById("artisan-annotate").style.display         = feats['魔器習熟'] ? '' : 'none'; 
  document.getElementById("accuracy-enhance").style.display   = feats['命中強化'] ? '' : 'none';
  document.getElementById("accuracy-enhance-acc").textContent = feats['命中強化'] || 0;
  document.getElementById("throwing").style.display = feats['スローイング'] ? '' : 'none';
  document.getElementById("parts-enhance").style.display = crafts['部位極強化'] || crafts['部位超強化'] || crafts['部位即応＆強化'] ? '' : 'none';
  document.getElementById("parts-enhance-acc").textContent = (crafts['部位極強化']?1:0)+(crafts['部位超強化']?1:0)+(crafts['部位即応＆強化']?1:0);
  

  stylizeVisibleRows(document.querySelectorAll('#attack-classes > .edit-table > tbody > tr'))

  calcWeapon();
}
function calcWeapon() {
  console.log('calcWeapon()');
  for (let i = 1; i <= form.weaponNum.value; i++){
    const className = form["weapon"+i+"Class"].value;
    const partNum = form["weapon"+i+"Part"].value;
    const category = form["weapon"+i+"Category"].value;
    const ownDex = form["weapon"+i+"Own"].checked ? 2 : 0;
    const note = form["weapon"+i+"Note"].value;
    const weaponReqd = safeEval(form["weapon"+i+"Reqd"].value) || 0;
    const classLv = lv[ SET.class[className]?.id ] || 0;
    let dex = (partNum ? stt.Dex+Number(form.sttPartA.value || 0) : stt.totalDex);
    let str = (partNum ? stt.Str+Number(form.sttPartC.value || 0) : stt.totalStr);
    let accBase = 0;
    let dmgBase = 0;
    // 技能選択のエラーチェック
    form["weapon"+i+"Class"].classList.toggle('error', errorAccClass[className] == true); 
    // 必筋チェック
    const maxReqd
      = (className === "フェンサー") ? reqdStrHalf
      : SET.class[className]?.accUnlock?.reqd ? stt['total'+SET.class[className]?.accUnlock?.reqd]
      : reqdStr;
    form["weapon"+i+"Reqd"].classList.toggle('error', weaponReqd > maxReqd + (equipMod.WeaponReqd||0));
    // 基礎命中
    if(SET.class[className]?.accUnlock?.acc === 'power'){
      accBase = magicPowers[SET.class[className].id];
    }
    else if(classLv) {
      accBase += classLv + parseInt((dex + ownDex) / 6);
    }
    // 基礎ダメージ
    if     (category === 'クロスボウ'){ dmgBase = modeZero ? 0 : classLv; }
    else if(category === 'ガン')      { dmgBase = magicPowers['Mag']; }
    else if(SET.class[className]?.accUnlock?.dmg === 'power')
                                      { dmgBase = magicPowers[SET.class[className].id] }
    else if(classLv)                  { dmgBase = classLv + parseInt(str / 6); }

    // 戦闘特技
    if(!partNum || partNum == form.partCore.value) {
      accBase += feats['命中強化'] || 0;
      if(category === '投擲') { accBase += feats['スローイング'] ? 1 : 0; }

      if(category === 'ガン（物理）') { dmgBase += feats['武器習熟／ガン'] || 0; }
      else if(category) { dmgBase += feats['武器習熟／'+category] || 0; }
      if(note.match(/〈魔器〉/)){ dmgBase += feats['魔器習熟'] || 0; }
    }
    else {
      if(crafts['部位極強化'    ]){ accBase += 1; }
      if(crafts['部位超強化'    ]){ accBase += 1; }
      if(crafts['部位即応＆強化']){ accBase += 1; }

      if(category == '格闘') { dmgBase += feats['武器習熟／格闘'] || 0; }
      else if(category && race == 'ディアボロ' && level >= 6) { dmgBase += feats['武器習熟／'+category] || 0; }
    }
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
let errorEvaClass = {};
function calcDefense() {
  console.log('calcDefense()');
  let defBase = 0;
  let evaAdd = 0;
  errorEvaClass = {};
  // 技能
  for(const name in SET.class){
    if(SET.class[name].type !== 'weapon-user' && !SET.class[name].evaUnlock){ continue; }
    const id    = SET.class[name].id;
    const eName = SET.class[name].eName;
    const unlockLv = SET.class[name]?.evaUnlock?.lv || 1;
    const unlockFeat = SET.class[name]?.evaUnlock?.feat || '';
    const unlockCraft = SET.class[name]?.evaUnlock?.craft || '';
    let display = '';
    if (lv[id] < unlockLv){ display = 'none' }
    if(unlockFeat){
      let hasUnlockFeat = false;
      for(const feat of unlockFeat.split('|')){
        if(feats[feat]){ hasUnlockFeat = true; break; }
      }
      if(!hasUnlockFeat){ display = 'none' }
    }
    if(unlockCraft){
      let hasUnlockCraft = false;
      for(const craft of unlockCraft.split('|')){
        if(crafts[craft]){ hasUnlockCraft = true; break; }
      }
      if(!hasUnlockCraft){ display = 'none' }
    }
    if(display == 'none'){ errorEvaClass[name] = true; }
    document.getElementById(`evasion-${eName}`).style.display = display;
    document.getElementById(`evasion-${eName}-str`).textContent = id == 'Fen' ? reqdStrHalf : reqdStr;
    document.getElementById(`evasion-${eName}-eva`).textContent = lv[id] + bonus.Agi;
  }
  document.getElementById("evasion-demonruler").style.display = !modeZero && lv['Dem'] >= 2 ? "" : modeZero && lv['Dem'] > 7 ? "" :"none";
  document.getElementById("evasion-demonruler-str").textContent = reqdStr;
  document.getElementById("evasion-demonruler-eva").textContent = lv['Dem'] + bonus.Agi;
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
  // 部位即応
  document.getElementById("parts-enhance-def").style.display = crafts['部位極強化'] || crafts['部位超強化'] || crafts['部位即応＆強化'] ? '' : 'none';
  document.getElementById("parts-enhance-eva").textContent = (crafts['部位極強化']?1:0)+(crafts['部位超強化']?1:0)+(crafts['部位即応＆強化']?1:0);
  
  // 武器と装飾品
  document.getElementById('equip-mod-eva').textContent = equipMod.Eva;
  document.getElementById('equip-mod-def').textContent = equipMod.Def;
  evaAdd  += (equipMod.Eva||0);
  defBase += (equipMod.Def||0);

  stylizeVisibleRows(document.querySelectorAll('#evasion-classes > .edit-table > tbody > tr'));

  calcArmour(evaAdd,defBase);
}
// 防具合計計算
function calcArmour(evaAdd,defBase) {
  console.log(`calcArmour(${evaAdd},${defBase})`);
  let count = { 鎧:0, 盾:0, 他:0 };
  let checkedCount = { 鎧:{}, 盾:{}, 他:{} };

  for (let num = 1; num <= form.armourNum.value; num++){
    const category = form[`armour${num}Category`].value;
    let type = category.match(/鎧|盾|他/) ? category.match(/鎧|盾|他/)[0] : '';
    if(num == 1 && !type){ type = '鎧' }
    if(type){ count[type]++ }

    form[`armour${num}Own`].disabled = category.match(/鎧|盾/) ? false : true;

    form[`armour${num}Reqd`].classList.remove('error');
    
    for (let i = 1; i <= form.defenseNum.value; i++){
      if (type && form[`defTotal${i}CheckArmour${num}`].checked){
        checkedCount[type][i] ??= 0;
        checkedCount[type][i]++;
      }
    }
  }
  
  for (let i = 1; i <= form.defenseNum.value; i++){
    const className = form['evasionClass'+i].value;
    const partNum   = form['evasionPart'+i].value;
    const partName  = form[`part${partNum}Name`]?.value || '';
    
    // 技能選択のエラーチェック
    form['evasionClass'+i].classList.toggle('error', errorEvaClass[className] == true); 

    // 最大必筋
    const maxReqd = (className === "フェンサー") ? reqdStrHalf : reqdStr;

    // 計算
    const classLv = lv[SET.class[className]?.id] || 0;

    let eva = 0;
    let def = 0;
    let agi = (partNum ? stt.Agi+Number(form.sttPartB.value || 0) : stt.totalAgi);
    if(!partNum || partNum == form.partCore.value) {
      def += defBase;
      eva += evaAdd;
      if(feats['回避行動'] == 2 && className != 'フェンサー' && className != 'バトルダンサー'){ eva -= 1 }
      if(feats['心眼'] && className != 'フェンサー'){ eva -= feats['心眼'] }
    }
    if(partNum){
      def += partStt[partNum].def;
      if(partNum != form.partCore.value){
        if(crafts['部位極強化'    ]){ eva += 1; }
        if(crafts['部位超強化'    ]){ eva += 1; }
        if(crafts['部位即応＆強化']){ eva += 1; }
      }
      if(partName == '邪眼'){
        eva += 2;
      }
    }
    let ownAgi = 0;
    let artisanDef = 0;
    for (let num = 1; num <= form.armourNum.value; num++){
      const checkObj = form[`defTotal${i}CheckArmour${num}`];
      checkObj.parentNode.classList.remove('error')

      if(!checkObj.checked) continue;
      
      const category = form[`armour${num}Category`].value;

      let reqdMod = (category == '盾') ? (equipMod.WeaponReqd||0) : 0;
      if((safeEval(form[`armour${num}Reqd`].value) || 0) > maxReqd + reqdMod){
        form[`armour${num}Reqd`].classList.add('error');
      }

      eva += Number(form[`armour${num}Eva`].value);
      def += Number(form[`armour${num}Def`].value);
      if(!partNum || partNum == form.partCore.value){
        def += (feats['防具習熟／'+category] || 0);
        if(form[`armour${num}Note`].value.match(/〈魔器〉/)){ artisanDef = feats['魔器習熟']; }
      }
      if(category == '盾' && form[`armour${num}Own`].checked){ ownAgi = 2 }
      
      let matches = category.match(/(鎧|盾)/);
      if (matches && checkedCount[matches[1]][i] > 1){
        checkObj.parentNode.classList.add('error')
      }
    }
    eva += ( classLv ? classLv + parseInt((agi + ownAgi) / 6) : 0 );
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
  let free = 0;
  for(const type of ['','Barbaros']){
    const rank = form["rank"+type].value;
    const topRank = rank.match(/★$/) ? 1 : 0;
    const rankStar = topRank ? Number(form["rankStar"+type].value||1)-1 : 0;
    form["rankStar"+type].style.display = topRank ? '' : 'none';
    const rankData = type == 'Barbaros' ? SET.bRank[rank] : SET.aRank[rank];
    const rankNum  = (rankData) ? rankData.num  + rankStar*500 : 0;
    const rankFree = (rankData) ? rankData.free + rankStar*50  : 0;
    pointTotal -= rankNum;
    if(rankFree > free){ free = rankFree }
    document.getElementById(`rank${type}-honor-value`).textContent = rankNum;
  }
  
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
  pointTotal -= Number(form.honorOffset.value) + Number(form.honorOffsetBarbaros.value);
  document.getElementById("honor-value"   ).textContent = pointTotal;
  document.getElementById("honor-value-MA").textContent = pointTotal;
  document.getElementById("mystic-arts-honor-value").textContent = mysticArtsPt;
  document.getElementById('honor-items-mystic-arts').style.display = mysticArtsPt ? '' : 'none';
}
// 不名誉点計算
function calcDishonor(){
  if(modeZero){ return; }
  let pointTotal = { 'human':0, 'barbaros':0 };
  const dishonorItemsNum = form.dishonorItemsNum.value;
  for (let i = 1; i <= dishonorItemsNum; i++){
    let point = safeEval(form['dishonorItem'+i+'Pt'].value) || 0;
    let type  = form['dishonorItem'+i+'PtType'].value || 'human';
    form['dishonorItem'+i+'PtType'].dataset.type = type;
    if(type == 'both'){
      for(let t in pointTotal){ pointTotal[t] += point }
    }
    else {
      pointTotal[type] += point;
    }
  }
  pointTotal.human    -= Number(form.honorOffset.value);
  pointTotal.barbaros -= Number(form.honorOffsetBarbaros.value);
  let pointTotalText = pointTotal.human;
  if(pointTotal.barbaros){ pointTotalText += `／<small>蛮</small>${pointTotal.barbaros}`; }
  document.getElementById("dishonor-value").innerHTML = pointTotalText;

  let notoriety = '';
  for(const data of SET.nRank){
    if(pointTotal.human >= data[1]) { notoriety = `<span>“${data[0]}”</span>` }
  }
  let notorietyB = '';
  for(const data of SET.nBRank){
    if(pointTotal.barbaros >= data[1]) { notorietyB = `<span>“${data[0]}”</span>` }
  }
  document.getElementById("notoriety").innerHTML = notoriety+notorietyB || '―';
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
  
  if(form.moneyAuto.checked){
    form.money.value = commify(cash);
    form.money.readOnly = true;
  }
  else {
    form.money.readOnly = false;
  }

  if(form.depositAuto.checked){
    form.deposit.value = commify(deposit)+'／'+commify(debt);
    form.deposit.readOnly = true;
  }
  else { form.deposit.readOnly = false; }
}

// 穢れ・侵蝕の影響など ----------------------------------------
let beforeEffects = {};
function getBoxNum(box){
  return box.querySelector("input[type=hidden]").getAttribute("name").replace(/^effect([0-9]+)Num$/,'$1');
}
function checkEffectAll(){
  document.querySelectorAll("#area-effects .box h2 select").forEach(obj => {
    const box = obj.closest(".box");
    checkEffect(obj,box);
    calcEffect(obj);
    checkSin();
    beforeEffects[box.id] = obj.value;
  });
}
function checkEffect(obj,box){
  const name = box.querySelector('select').value;
  const eData = SET.effects?.[name] || {};
  box.querySelector("h2 .select-input").classList.toggle("free", name.match(/^自由記入/));
  box.querySelector(".effect-points dt ").textContent = eData?.pointName || '';
  box.querySelector("thead th.text     ").textContent = eData?.header?.[0] || '';
  box.querySelector("thead th.num1 span").textContent = eData?.header?.[1] || '';
  box.querySelector("thead th.num2 span").textContent = eData?.header?.[2] || '';
  box.querySelector("thead th.num1").classList.toggle("hidden", !eData?.header?.[1] && !eData?.type?.[1]);
  box.querySelector("thead th.num2").classList.toggle("hidden", !eData?.header?.[2] && !eData?.type?.[2]);
  [1,2].forEach(num => {
    box.querySelectorAll(`input[name$=Pt${num}]`).forEach(input => {
      input.type = SET.effects?.[name]?.type?.[num] || 'text';
      input.value = input.type == 'checkbox' || input.type == 'radio' ? 1 : input.value;
    });
  });
}
function changeEffect(obj){
  const name = obj.value;
  const box = obj.closest(".box");
  const num = getBoxNum(box);
  if(box.querySelector("input:read-only")){
    let hasValue = false;
    for (const node of box.querySelectorAll(`input:not([type=hidden])`)){
      if(node.readOnly){ continue; }
      if(node.name.match(/Free$/)){ continue; }
      if(node.type === 'checkbox' || node.type === 'radio'){
        if(node.checked) { hasValue = true; break; }
      }
      else {
        if(node.value !== ''){
          hasValue = true; break;
        }
      }
    }
    if(hasValue){
      if (!confirm('項目に値が入っています。本当に変更しますか？')){
        box.querySelector("select").value = beforeEffects[box.id];
        return false;
      }
    }
    if(name === "穢れ"){
      console.log(SET.races[race]?.sin||0)
      if(form.sin.value != (SET.races[form.race.value]?.sin||0)){
        if (!confirm('穢れ度の入力が自動計算になります（今の入力値は初期化されます）。よろしいですか？')){
          box.querySelector("select").value = beforeEffects[box.id];
          return false;
        }
      }
    }
  }
  beforeEffects[box.id] = name;

  if(SET.effects?.[name]?.fix){
    box.querySelectorAll("tbody tr").forEach(row => row.remove());
    form[`effect${num}Num`].value = 0;
    let i = 1;
    SET.effects?.[name]?.fix.forEach(text => {
      addEffect(obj);
      const input = box.querySelector(`input[name$="${num}-${i}"]`);
      input.value = text;
      input.readOnly = true;
      i++;
    })
  }
  else {
    if(box.querySelector("input:read-only")){
      box.querySelectorAll("tbody tr").forEach(row => row.remove());
      form[`effect${num}Num`].value = 0;
      addEffect(obj);
    }
  }
  checkEffect(obj,box);
  calcEffect(obj);
  setEffectNames();
  checkSin();
}
function setEffectNames(){
  let selecteds = []
  for(let num = 1; num <= form.effectBoxNum.value; num++){
    const name = form[`effect${num}Name`].value;
    if(name){ selecteds.push(name); }
  }
  for(let num = 1; num <= form.effectBoxNum.value; num++){
    const options = form[`effect${num}Name`].options || [];
    for (const option of options) {
      option.style.display = (
          form[`effect${num}Name`].value !== option.value && 
          !option.value.match(/^自由記入/) && 
          selecteds.includes(option.value)
        ) ? 'none' : '';
    }
  }
}
// 計算
function calcEffect(obj){
  const box = obj.closest(".box");
  const name = box.querySelector('select').value;
  let total = 0;
  if(SET.effects?.[name]?.calc?.includes(1)){
    box.querySelectorAll("input[name$=Pt1]").forEach(input => {
      total += Number(input.value || 0);
    });
  }
  if(SET.effects?.[name]?.calc?.includes(2)){
    box.querySelectorAll("input[name$=Pt2]").forEach(input => {
      total += Number(input.value || 0);
    });
  }
  if(name === '穢れ'){
    total += SET.races[race]?.sin || 0;
    form.sin.value = total;
  }
  box.querySelector(".effect-points dd").textContent = total;
}
function checkSin(){
  form.sin.readOnly = false;
  document.querySelectorAll("#area-effects .box h2 select").forEach(obj => {
    if(obj.value === "穢れ"){
      form.sin.readOnly = true;
      return;
    }
  });
}
// 追加
function addEffect(obj){
  const box = obj.closest(".box");
  const num = getBoxNum(box);
  box.querySelector(`table tbody`).append(createRow(`effect${num}`,`effect${num}Num`));
  checkEffect(obj,box);
}
// 削除
function delEffect(obj){
  const box = obj.closest(".box");
  const num = getBoxNum(box);
  if(delRow(`effect${num}Num`, `#effect-row${num} table tbody tr:last-of-type`)){
    //
  }
}
// ソート
(() => {
  for(let num = 1; num <= form.effectBoxNum.value; num++){
    setSortable(`effect${num}-`,`#effect-row${num} table tbody`,'tr');
  }
})();

// 追加
function addEffectBox(){
  document.querySelector('#area-effects').append(createRow('effect','effectBoxNum',null,'BOX'));
  const num = form.effectBoxNum.value;
  setSortable(`effect${num}-`,`#effect-row${num} table tbody`);
  setEffectNames();
}
// 削除
function delEffectBox(){
  if(delRow('effectBoxNum', '#area-effects > :is(div:last-child:not(.add-del-button),div:has(+ .add-del-button:last-child))',1)){
    setEffectNames();
  }
}
// ソート
setSortable('effect','#area-effects','div');

// 装飾品欄 ----------------------------------------
function addAccessory(name){
  if(form[`accessory${name}Add`].checked) {
    document.querySelector(`#accessories [data-type="${name}_"]`).style.display = '';
  }
  else {
    document.querySelector(`#accessories [data-type="${name}_"]`).style.display = 'none';
  }

  calcDefense(); // 装飾品由来の回避力・防護点の再計算
}
// ソート
(() => {
  let sortable = Sortable.create(document.getElementById('accessories-table'), {
    animation: 200,
    handle: 'th',
    filter: 'thead,tfoot',
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
})();

// 秘伝欄 ----------------------------------------
// 追加
function addMysticArts(){
  document.querySelector("#mystic-arts-list").append(createRow('mystic-arts','mysticArtsNum'));
}
// 削除
function delMysticArts(){
  if(delRow('mysticArtsNum', '#mystic-arts-list li:last-of-type')){
    calcHonor();
  }
}
// ソート
setSortable('mysticArts','#mystic-arts-list','li');

// 秘伝魔法欄 ----------------------------------------
// 追加
function addMysticMagic(){
  document.querySelector("#mystic-magic-list").append(createRow('mystic-magic','mysticMagicNum'));
}
// 削除
function delMysticMagic(){
  if(delRow('mysticMagicNum', '#mystic-magic-list li:last-of-type')){
    calcHonor();
  }
}
// ソート
setSortable('mysticMagic','#mystic-magic-list','li');

// 言語欄 ----------------------------------------
function checkLanguage(){
  const languageTable = document.getElementById('language-table');
  languageTable.classList.toggle('sag-available', parseInt(form['lvSag'].value) > 0);
  languageTable.classList.toggle('bar-available', parseInt(form['lvBar'].value) > 0);

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
  for (let key of SET.classNames){
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
        if     (v > 0){ notice += `<li class="under">${className}技能であと「${v}」習得できます`; }
        else if(v < 0){ notice += `<li class="over">${className}技能での習得が「${v*-1}」過剰です`; }
      }
      else if(classLv && (notT || notR)) {
        notice += `<li class="under">${langName}の`;
        if(notT){ acqT[langName] = true; notice += `会話`+(notR ? '/' : '');  }
        if(notR){ acqR[langName] = true; notice += `読文`;  }
        notice += `が習得できます`;
      }
    }
  }
  document.getElementById('language-notice').innerHTML = notice;
}
// 追加
function addLanguage(){
  document.querySelector("#language-table tbody").append(createRow('language','languageNum'));
}
// 削除
function delLanguage(){
  if(delRow('languageNum', '#language-table tbody tr:last-of-type')){
    checkLanguage();
  }
}
// ソート
setSortable('language','#language-table tbody','tr');

// 武器欄 ----------------------------------------
// 追加
function addWeapons(copyBaseNum){
  const row = createRow('weapon','weaponNum');
  document.querySelector("#weapons-table").append(row);
  
  if(copyBaseNum){
    row.querySelectorAll('[name]').forEach(node => {
      const copyBaseName = node.getAttribute('name').replace(/^(weapon)\d+(.+)$/, `$1${copyBaseNum}$2`)
      if(node.type === 'checkbox'){
        node.checked = form[copyBaseName].checked;
      }
      else { node.value = form[copyBaseName].value; }
    });
    calcWeapon();
  }
  calcParts();
  generatePaletteWeaponCheckbox();
}
// 削除
function delWeapons(){
  if(delRow('weaponNum', '#weapons-table tbody:last-of-type')){
    generatePaletteWeaponCheckbox();
  }
}
// ソート
setSortable('weapon', '#weapons-table', 'tbody',
  (row, num) => {
    row.querySelector(`span[onclick]`).setAttribute('onclick',`addWeapons(${num})`);
    row.querySelector(`b[id$=acc-total]`).id = `weapon${num}-acc-total`;
    row.querySelector(`b[id$=dmg-total]`).id = `weapon${num}-dmg-total`;
  },
  () => {
    generatePaletteWeaponCheckbox();
  }
);

function changeWeaponName (){
  let rowNum = 0;
  document.querySelectorAll(`#palette-attack .palette-attack-checklist`).forEach(row => {
    rowNum++;
    for(let num = 1; num <= form.weaponNum.value; num++){
      const name = (form[`weapon${num}Name`].value || form[`weapon${num-1}Name`]?.value || '')+form[`weapon${num}Usage`].value;
      form[`paletteAttack${rowNum}CheckWeapon${num}`].nextElementSibling.textContent = name;
    }
  });
}
function generatePaletteWeaponCheckbox (){
  let checkList = {};
  let rowNum = 0;
  const rows = document.querySelectorAll(`#palette-attack .palette-attack-checklist`);
  rows.forEach(row => {
    rowNum++;
    checkList[rowNum] = {};
    row.querySelectorAll(`label input`).forEach(checkbox => {
      const name = checkbox.nextElementSibling.textContent || '';
      checkList[rowNum][name] = checkbox.checked ? 'checked' : '';
    })
  });
  rowNum = 1;
  rows.forEach(row => {
    row.innerHTML = '';
    const added = {};
    for(let num = 1; num <= form.weaponNum.value; num++){
      const name = (form[`weapon${num}Name`].value || form[`weapon${num-1}Name`]?.value || '')+form[`weapon${num}Usage`].value;

      let checkbox = document.createElement('label');
      checkbox.classList.add('check-button');
      if(added[name] || !name){ checkbox.disabled = true; }
      checkbox.innerHTML = `<input type="checkbox" name="paletteAttack${rowNum}CheckWeapon${num}" value="1" oninput="setChatPalette()" ${checkList[rowNum][name]}><span>${name||'―'}</span>`;
      row.append(checkbox);

      added[name] = 1;
    }
    rowNum++;
  });
}

// 防具欄 ----------------------------------------
// 追加
function addArmour(){
  const row = createRow('armour','armourNum');
  document.querySelector("#armours tbody").append(row);

  const id = row.id;
  const num = form.armourNum.value;
  let i = 1;
  document.querySelectorAll(".defense-total-checklist").forEach(obj => {
    let checkbox = document.createElement('label')
    checkbox.classList.add('check-button')
    checkbox.innerHTML = `<input type="checkbox" name="defTotal${i}CheckArmour${num}" value="1" oninput="calcDefense()" data-id="${id}"><span></span>`;
    obj.append(checkbox);
    i++;
  });
  generateArmourCheckbox();
}
// 削除
function delArmour(){
  if(delRow('armourNum', '#armours tbody tr:last-of-type')){
    const deletedNum = Number(form.armourNum.value) +1;
    document.querySelectorAll(`.defense-total-checklist label:has([name$="Armour${deletedNum}"])`).forEach(obj => {
      obj.remove();
    });
    generateArmourCheckbox();
    calcDefense();
    calcHonor();
  }
}
// ソート
setSortable('armour', '#armours tbody', 'tr', '',
  () => { generateArmourCheckbox(); calcDefense(); }
);
// 見出し
function setArmourType (){
  let count = { 鎧:0, 盾:0, 他:0 };
  for (let num = 1; num <= form.armourNum.value; num++){
    const category = form[`armour${num}Category`].value;
    let type = category.match(/鎧|盾|他/) ? category.match(/鎧|盾|他/)[0] : '';
    if(num == 1 && !type){ type = '鎧' }
    if(type){ count[type]++ }
    form[`armour${num}Name`].parentNode.parentNode.querySelector('.type').textContent
      = type ? type+count[type] : '';
  }
}
// 名前変更
function changeArmourName(){
  generateArmourCheckbox('num')
}
// 合計欄チェックボックス
function generateArmourCheckbox(checkListType = 'name'){
  let checkList = {};
  let rowNum = 0;
  const rows = document.querySelectorAll(`#armours tfoot .defense-total-checklist`);
  rows.forEach(row => {
    rowNum++;
    checkList[rowNum] = {};
    let num = 0;
    row.querySelectorAll(`label input`).forEach(checkbox => {
      num++;
      const id = checkListType == 'num' ? num : (checkbox.nextElementSibling.textContent || '');
      checkList[rowNum][id] = checkbox.checked ? 'checked' : '';
    })
  });
  rowNum = 1;
  rows.forEach(row => {
    row.innerHTML = '';
    for(let num = 1; num <= form.armourNum.value; num++){
      let type = form[`armour${num}Name`].parentNode.parentNode.querySelector('.type').textContent || '';

      const name =
        form[`armour${num}Name`].value ? form[`armour${num}Name`].value
            .replace(/[|｜](.+?)《(.+?)》/g, "$1")
            .replace(/\[([^\[\]]+?)#[0-9a-zA-z\-]+\]/g, "$1")
        : type || '―';
      const id = checkListType == 'num' ? num : name;
      let checkbox = document.createElement('label');
      checkbox.classList.add('check-button');
      checkbox.innerHTML = `<input type="checkbox" name="defTotal${rowNum}CheckArmour${num}" value="1" oninput="calcDefense()" ${checkList[rowNum][id]}><span>${name||'―'}</span>`;
      row.append(checkbox);

      document.querySelector(`input[name="defTotal${rowNum}CheckArmour${num}"]`).parentNode.style.display
        = (  !form[`armour${num}Name`].value
          && !form[`armour${num}Category`].value
          && !form[`armour${num}Eva`].value
          && !form[`armour${num}Def`].value
          && !form[`armour${num}Own`].checked
          && !type
        ) ? 'none' : '';
    }
    rowNum++;
  });
}

// 回避・防護合計 ----------------------------------------
// 追加
function addDefense(){
  document.querySelector("#armours tfoot").append(createRow('defense-total','defenseNum'));
  generateArmourCheckbox();
  calcParts();
  calcDefense();
}
// 削除
function delDefense(){
  delRow('defenseNum', '#armours tfoot tr:last-of-type');
}

// 装備の備考欄の補正 ----------------------------------------
let equipMod = {};
function changeEquipMod (){
  if(checkEquipMod()){
    calcStt();
  }
}
function checkEquipMod (){
  console.log('checkEquipMod()');
  // 装飾品欄の補正
  const sttRegEx = [
    ['A:increment','器(?:用度?)?増強'],
    ['B:increment','敏(?:捷度?)?増強'],
    ['C:increment','筋(?:力)?増強'],
    ['D:increment','生(?:命力)?増強'],
    ['E:increment','知力?増強'],
    ['F:increment','精(?:神力?)?増強'],
    ['A','器(?:用度?)?'],
    ['B','敏(?:捷度?)?'],
    ['C','筋(?:力)?'],
    ['D','生(?:命力)?'],
    ['E','知力?'],
    ['F','精(?:神力?)?'],
    ['VResist','生命抵抗力?'],
    ['MResist','精神抵抗力?'],
    ['Eva','回避力?'],
    ['Def','防(?:護点?)?'],
    ['Mobility','移動力'],
    ['MagicPower', '魔力'],
    ['MagicCast', '(?:魔法)?行使(?:判定)?'],
    ['MagicDamage', '魔法のダメージ'],
    ['WeaponReqd','武器(?:必要筋力|必筋)上限'],
  ];
  let newMod = {};
  const statusIncrement = {};
  document.querySelectorAll(':is(#weapons-table, #armours-table, #accessories-table) input[name$="Note"]').forEach(
    input => {
      const note = input.value ?? '';
      if (input.getAttribute('name').includes('_')) {
        const nameToAdd = input.getAttribute('name').replace('_Note', 'Add');
        if (!document.getElementsByName(nameToAdd)[0].checked) {
          return;
        }
      }
      for(let i of sttRegEx){
        const m = note.match('[@＠]'+i[1]+'([＋+－-][0-9]+)');
        if (m != null) {
          console.log(m[0],m[1])
          const value = parseInt(m[1].replace(/[＋]/,"+").replace(/－/,"-") || 0);
          newMod[i[0]] ??= 0;
          newMod[i[0]] += value;

          if (i[0].endsWith(':increment')) {
            const key = i[0].replace(/:increment$/, '');
            statusIncrement[key] = Math.max(statusIncrement[key] ?? 0, value);
          }
        }
      }
    }
  );
  for (const [key, value] of Object.entries(statusIncrement)) {
    newMod[key] ??= 0;
    newMod[key] += value;
  }
  let hasChange;
  for(let i of sttRegEx){
    if(parseInt(newMod[i[0]]||0) !== parseInt(equipMod[i[0]]||0)){
      hasChange = true;
      equipMod = { ...newMod };
      break;
    }
  }
  console.log(equipMod)
  return hasChange;
}
// 部位 ----------------------------------------
// 追加
function addPart(){
  document.querySelector("#parts tbody").append(createRow('part','partNum'));
  calcParts();
}
// 削除
function delPart(){
  delRow('partNum', '#parts tbody tr:last-of-type');
  calcParts();
}
// 魔晶石 ----------------------------------------
function calcManaGems() {
  for (let point = 1; point <= 20; point++) {
    calcManaGem(point);
  }
}
/**
 * @param {int} point
 */
function calcManaGem(point) {
  const tr = document.querySelector(`#mana-gems table tr[data-point="${point}"]`);

  const quantity = parseInt(tr.querySelector('.quantity input').value);
  const offset = parseInt(tr.querySelector('.offset input').value);

  const total = (isNaN(quantity) ? 0 : quantity) + (isNaN(offset) ? 0 : offset);

  const valueElement = tr.querySelector('.total .value');
  valueElement.textContent = commify(total);
  valueElement.classList.toggle('zero', total === 0);
  valueElement.classList.toggle('minus', total < 0);

  switchManaGemClearingOffButton();
}
function switchManaGemClearingOffButton() {
  let hasOffset = false;

  for (let point = 1; point <= 20; point++) {
    const offset = parseInt(document.querySelector(`#mana-gems table tr[data-point="${point}"] .offset input`).value);

    if (!isNaN(offset) && offset !== 0) {
      hasOffset = true;
      break;
    }
  }

  document.getElementById('clearing-off-mana-gems-offset').disabled = !hasOffset;
}
function clearOffManaGemsOffset() {
  /** @var {Array<Function>} */
  const clearingFunctions = [];

  for (let point = 1; point <= 20; point++) {
    const tr = document.querySelector(`#mana-gems table tr[data-point="${point}"]`);

    const quantityInput = tr.querySelector('.quantity input');
    const offsetInput = tr.querySelector('.offset input');

    const offset = parseInt(offsetInput.value);

    if (isNaN(offset) || offset === 0) {
      continue;
    }

    const quantity = quantityInput.value !== '' ? parseInt(quantityInput.value) : 0;
    const clearedQuantity = quantity + offset;

    if (clearedQuantity < 0) {
      alert(`魔晶石（${point}点）の減少量が元の所持数より大きいため清算できません。`);
      return;
    }

    clearingFunctions.push(((quantityInput, offsetInput, clearedQuantity) => {
      return () => {
        quantityInput.value = clearedQuantity.toString();
        offsetInput.value = '';

        for (const input of [quantityInput, quantityInput]) {
          input.dispatchEvent(new Event('input'));
          input.dispatchEvent(new Event('change'));
        }
      };
    })(quantityInput, offsetInput, clearedQuantity));
  }

  clearingFunctions.forEach(x => x.call());

  switchManaGemClearingOffButton();
}
// 名誉アイテム欄 ----------------------------------------
// 追加
function addHonorItems(){
  document.querySelector("#honor-items-table").append(createRow('honor-item','honorItemsNum'));
}
// 削除
function delHonorItems(){
  if(delRow('honorItemsNum', '#honor-items-table tr:last-of-type')){
    calcHonor();
  }
}
// ソート
setSortable('honorItem','#honor-items-table','tr');
// 不名誉欄 ----------------------------------------
// 追加
function addDishonorItems(){
  document.querySelector("#dishonor-items-table").append(createRow('dishonor-item','dishonorItemsNum'));
}
// 削除
function delDishonorItems(){
  if(delRow('dishonorItemsNum', '#dishonor-items-table tr:last-of-type')){
    calcDishonor();
  }
}
// ソート
setSortable('dishonorItem','#dishonor-items-table','tr');

// 一般技能 ----------------------------------------
function calcCommonClass(){
  let totalLv = 0;
  for(let num = 1; num <= Number(form.commonClassNum.value); num++){
    totalLv += Number(form['lvCommon'+num].value||0);
    document.querySelector(`#palette-common-class-row${num} .name`).textContent = form['commonClass'+num].value.replace(/[(（].+?[）)]$/, '');
  }
  document.getElementById('cc-total-lv').textContent = totalLv;
}
// 追加
function addCommonClass(){
  document.querySelector("#common-classes-table tbody").append(createRow('common-class','commonClassNum'));
  
  let row = document.getElementById('palette-common-class-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('palette-common-class-row');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', form.commonClassNum.value);
  document.querySelector("#palette-common-classes table tbody").append(row);
}
// 削除
function delCommonClass(){
  if(delRow('commonClassNum', '#common-classes-table tbody tr:last-of-type')){
    calcCommonClass();
  }
}
// ソート
setSortable('commonClass|lvCommon','#common-classes-table tbody','tr','',()=>{
  let idArray = [];
  document.querySelectorAll(`#common-classes-table tbody tr`).forEach(row => {
    idArray.push('palette-'+row.id);
  });
  
  sortablePaletteCommonClass.sort(idArray);

  let num = 1;
  document.querySelectorAll(`#palette-common-classes tbody tr`).forEach(row => {
    replaceSortedNames(row,num,/^(paletteCommonClass)[0-9]+(.*)$/);
    num++;
  });
});

let sortablePaletteCommonClass = Sortable.create(document.querySelector('#palette-common-classes tbody'), {
  sort: false,
  dataIdAttr: 'id',
  animation: 150,
  handle: '.none',
  filter: 'template',
});

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  document.querySelector("#history-table tfoot").before(createRow('history','historyNum'));
}
// 削除
function delHistory(){
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcExp(); calcHonor(); calcCash(); calcStt();
  }
}
// ソート
setSortable('history','#history-table','tbody');

// 戦闘用アイテム欄 ----------------------------------------
// ソート
setSortable('battleItem','#battle-items-list');

// チャットパレット ----------------------------------------
// 武器攻撃
function addPaletteAttack(){
  document.querySelector("#palette-attack > table tbody").append(createRow('palette-attack','paletteAttackNum'));
  generatePaletteWeaponCheckbox();
}
function delPaletteAttack(){
  if(delRow('paletteAttackNum', '#palette-attack > table tbody tr:last-of-type')){
    setChatPalette();
  }
}
setSortable('paletteAttack','#palette-attack > table tbody','tr');
// 魔法
function addPaletteMagic(){
  document.querySelector("#palette-magic > table tbody").append(createRow('palette-magic','paletteMagicNum'));
}
function delPaletteMagic(){
  if(delRow('paletteMagicNum', '#palette-magic > table tbody tr:last-of-type')){
    setChatPalette();
  }
}
setSortable('paletteMagic','#palette-magic > table tbody','tr');

// 割り振り計算 ----------------------------------------
function calcPointBuy() {
  const type = String(form.pointbuyType.value || '2.5');
  
  let points = 0;
  let errorFlag = 0;
  ['A','B','C','D','E','F'].forEach((i) => {
    form[`sttBase${i}`].classList.remove('error');
    delete document.querySelector(`#stt-base-${i} > dt:first-child`).dataset['range'];
  });
  if(SET.races[race]?.dice){
    ['A','B','C','D','E','F'].forEach((i) => {
      const dice = String(SET.races[race].dice[i]);
      const min = Number(dice) + (SET.races[race].dice[`${i}+`] ?? 0);
      const max = min + Number(dice) * 5;
      document.querySelector(`#stt-base-${i} > dt:first-child`).dataset.range = `${min}～${max}`;
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
