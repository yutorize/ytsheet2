"use strict";
const gameSystem = 'sw2';
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
let sttDex = 0;
let sttAgi = 0;
let sttStr = 0;
let sttVit = 0;
let sttInt = 0;
let sttMnd = 0;
let sttAddA = 0;
let sttAddB = 0;
let sttAddC = 0;
let sttAddD = 0;
let sttAddE = 0;
let sttAddF = 0;
let bonusDex = 0;
let bonusAgi = 0;
let bonusStr = 0;
let bonusVit = 0;
let bonusInt = 0;
let bonusMnd = 0;
let level = 0;
let levelCasters = [];

window.onload = function() {
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
  document.getElementById("history0-exp").innerHTML = form.history0Exp.value;
  document.getElementById("history0-honor").innerHTML = form.history0Honor.value;
  document.getElementById("history0-money").innerHTML = form.history0Money.value;
  
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
  Object.keys(classes).forEach(function(key) {
    if(classes[key]['expTable']){
      lv[key] = Number(form['lv'+key].value);
      if(classes[key]['2.0'] && !allClassOn){ lv[key] = 0; }
      
      expUse += expTable[ classes[key]['expTable'] ][ lv[key] ];
      
      allClassLv.push(lv[key]);
      if(classes[key]['magic']){ levelCasters.push(lv[key]); }
    }
  });
  if(form.lvSeeker){
    lvSeeker = Number(form.lvSeeker.value);
    expUse += expTable['S'][ lvSeeker ];
  }
  
  document.getElementById("exp-use").innerHTML = commify(expUse);
  document.getElementById("exp-rest").innerHTML = commify(expTotal - expUse);
  
  level = Math.max.apply(null, Object.values(lv));
  document.getElementById("level-value").innerHTML = level;
  
  lv['Wiz'] = (lv['Sor'] && lv['Con']) ? Math.max(lv['Sor'],lv['Con']) : 0;
  levelCasters.sort( function(a,b){ return (a < b ? 1 : -1); } );
  if(battleItemOn){
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
function changeRace(){
  race = form.race.value;
  
  checkRace();
  calcStt();
}

// 種族チェック ----------------------------------------
let raceAbilityDef       = 0;
let raceAbilityMp        = 0;
let raceAbilityMndResist = 0;
let raceAbilityMagicPower= 0;
function checkRace(){
  raceAbilityDef       = 0;
  raceAbilityMp        = 0;
  raceAbilityMagicPower= 0;
  Object.keys(classes).forEach(id => {
    if(document.getElementById("class"+id)){
      document.getElementById("class"+id).classList.remove('fail');
      if(races[race]['restrictedClass'] && races[race]['restrictedClass'].includes(classes[id]['jName'])){
        document.getElementById("class"+id).classList.add('fail');
      }
      else if(classes[id]['onlyRace'] && !classes[id]['onlyRace'].includes(race)){
        document.getElementById("class"+id).classList.add('fail');
      }
    }
  });
  
  if(race === 'リルドラケン'){
    raceAbilityDef = 1;
    document.getElementById("race-ability-def-name").innerHTML = '鱗の皮膚';
  }
  else if(race === 'シャドウ'){
    raceAbilityMndResist = 4;
    if(level >= 11){
      raceAbilityMndResist += 2;
    }
  }
  else if(race === 'フロウライト'){
    raceAbilityDef = 2;
    raceAbilityMp = 15;
    if(level >= 6){
      raceAbilityDef += 1;
      raceAbilityMp += 15;
    }
    if(level >= 11){
      raceAbilityDef += 1;
      raceAbilityMp += 15;
    }
    if(level >= 16){
      raceAbilityDef += 2;
      raceAbilityMp += 30;
    }
    document.getElementById("race-ability-def-name").innerHTML = '晶石の身体';
  }
  else if(race === 'ハイマン'){
    raceAbilityMagicPower += (level >= 11) ? 2 : 1;
    document.getElementById("magic-power-raceability-value" ).innerHTML = raceAbilityMagicPower || 0;
    document.getElementById("magic-power-raceability-name").innerHTML = '魔法の申し子';
    document.getElementById("magic-power-raceability-type").innerHTML = '魔法全般';
  }
  else if(race.match(/^センティアン/)){
    document.getElementById("magic-power-raceability-value" ).innerHTML = (level >= 11) ? 2 : (level >= 6) ? 1 : 0;
    document.getElementById("magic-power-raceability-name").innerHTML = race.match('ルミエル') ? '神の御名と共に' : race.match('イグニス') ? '神への礼賛' : race.match('カルディア') ? '神への祈り' : '';
    document.getElementById("magic-power-raceability-type").innerHTML = '神聖魔法';
  }
  else if(race === 'ダークトロール'){
    raceAbilityDef = 1;
    if(level >= 16){
      raceAbilityDef += 2;
    }
    document.getElementById("race-ability-def-name").innerHTML = 'トロールの体躯';
  }
  
  let ability = '';
  if(races[race]['ability']){
    ability = races[race]['ability'] || '';
    if(level >= 6 && races[race]['abilityLv6']){
      if(Array.isArray(races[race]['abilityLv6'])){
        form.raceAbilityLv6.classList.remove('hidden');
      }
      else{
        ability += races[race]['abilityLv6'];
        form.raceAbilityLv6.classList.add('hidden');
      }
    }
    else {
      form.raceAbilityLv6.classList.add('hidden');
    }
    if(level >= 11 && races[race]['abilityLv11']){
      if(Array.isArray(races[race]['abilityLv11'])){
        form.raceAbilityLv11.classList.remove('hidden');
      }
      else{
        ability += races[race]['abilityLv11'];
        form.raceAbilityLv11.classList.add('hidden');
      }
    }
    else {
      form.raceAbilityLv11.classList.add('hidden');
    }
    if(level >= 16 && races[race]['abilityLv16']){
      if(Array.isArray(races[race]['abilityLv16'])){
        form.raceAbilityLv16.classList.remove('hidden');
      }
      else{
        ability += races[race]['abilityLv16'];
        form.raceAbilityLv16.classList.add('hidden');
      }
    }
    else {
      form.raceAbilityLv16.classList.add('hidden');
    }
  }
  document.getElementById("race-ability-value").innerHTML = ability;
  checkLanguage();
  setLanguageDefault();
}
function setLanguageDefault(){
  if (!form.languageAutoOff.checked) {
    let text = '';
    if(races[race]['language']){
      for(let data of races[race]['language']){
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
function calcStt() {
  let growDex = 0; let sttHistGrowA = 0;
  let growAgi = 0; let sttHistGrowB = 0;
  let growStr = 0; let sttHistGrowC = 0;
  let growVit = 0; let sttHistGrowD = 0;
  let growInt = 0; let sttHistGrowE = 0;
  let growMnd = 0; let sttHistGrowF = 0;
  // 履歴から成長カウント
  const historyNum = form.historyNum.value;
  for (let i = 1; i <= historyNum; i++){
    const grow = form["history" + i + "Grow"].value;
    grow.replace(/器(?:用度?)?(?:×|\*)?([0-9]{1,3})?/g, (all,n) => { sttHistGrowA += Number(n) || 1; });
    grow.replace(/敏(?:捷度?)?(?:×|\*)?([0-9]{1,3})?/g, (all,n) => { sttHistGrowB += Number(n) || 1; });
    grow.replace(/筋(?:力)?(?:×|\*)?([0-9]{1,3})?/g,    (all,n) => { sttHistGrowC += Number(n) || 1; });
    grow.replace(/生(?:命力?)?(?:×|\*)?([0-9]{1,3})?/g, (all,n) => { sttHistGrowD += Number(n) || 1; });
    grow.replace(/知(?:力)?(?:×|\*)?([0-9]{1,3})?/g,    (all,n) => { sttHistGrowE += Number(n) || 1; });
    grow.replace(/精(?:神力?)?(?:×|\*)?([0-9]{1,3})?/g, (all,n) => { sttHistGrowF += Number(n) || 1; });
  }
  const seekerGrow = lvSeeker >= 17 ? 30
                   : lvSeeker >= 13 ? 24
                   : lvSeeker >=  9 ? 18
                   : lvSeeker >=  5 ? 12
                   : lvSeeker >=  1 ?  6
                   : 0;
  growDex = Number(form.sttPreGrowA.value) + sttHistGrowA + seekerGrow;
  growAgi = Number(form.sttPreGrowB.value) + sttHistGrowB + seekerGrow;
  growStr = Number(form.sttPreGrowC.value) + sttHistGrowC + seekerGrow;
  growVit = Number(form.sttPreGrowD.value) + sttHistGrowD + seekerGrow;
  growInt = Number(form.sttPreGrowE.value) + sttHistGrowE + seekerGrow;
  growMnd = Number(form.sttPreGrowF.value) + sttHistGrowF + seekerGrow;
  
  document.getElementById("stt-grow-A-value").innerHTML = growDex;
  document.getElementById("stt-grow-B-value").innerHTML = growAgi;
  document.getElementById("stt-grow-C-value").innerHTML = growStr;
  document.getElementById("stt-grow-D-value").innerHTML = growVit;
  document.getElementById("stt-grow-E-value").innerHTML = growInt;
  document.getElementById("stt-grow-F-value").innerHTML = growMnd;

  const growTotal = growDex + growAgi + growStr + growVit + growInt + growMnd;
  document.getElementById("stt-grow-total-value").innerHTML = growTotal;
  document.getElementById("history-grow-total-value").innerHTML = growTotal;
  
  sttDex = Number(form.sttBaseTec.value) + Number(form.sttBaseA.value) + growDex;
  sttAgi = Number(form.sttBaseTec.value) + Number(form.sttBaseB.value) + growAgi;
  sttStr = Number(form.sttBasePhy.value) + Number(form.sttBaseC.value) + growStr;
  sttVit = Number(form.sttBasePhy.value) + Number(form.sttBaseD.value) + growVit;
  sttInt = Number(form.sttBaseSpi.value) + Number(form.sttBaseE.value) + growInt;
  sttMnd = Number(form.sttBaseSpi.value) + Number(form.sttBaseF.value) + growMnd;
  
  if      (race === 'ウィークリング（ガルーダ）')     sttAgi += 3;
  else if (race === 'ウィークリング（タンノズ）')     sttMnd += 3;
  else if (race === 'ウィークリング（ミノタウロス）') sttStr += 3;
  else if (race === 'ウィークリング（バジリスク）')   sttInt += 3;
  else if (race === 'ウィークリング（マーマン）')     sttMnd += 3;
  
  document.getElementById("stt-dex-value").innerHTML = sttDex;
  document.getElementById("stt-agi-value").innerHTML = sttAgi;
  document.getElementById("stt-str-value").innerHTML = sttStr;
  document.getElementById("stt-vit-value").innerHTML = sttVit;
  document.getElementById("stt-int-value").innerHTML = sttInt;
  document.getElementById("stt-mnd-value").innerHTML = sttMnd;
  
  sttAddA = Number(form.sttAddA.value);
  sttAddB = Number(form.sttAddB.value);
  sttAddC = Number(form.sttAddC.value);
  sttAddD = Number(form.sttAddD.value);
  sttAddE = Number(form.sttAddE.value);
  sttAddF = Number(form.sttAddF.value);
  
  bonusDex = parseInt((sttDex + sttAddA) / 6);
  bonusAgi = parseInt((sttAgi + sttAddB) / 6);
  bonusStr = parseInt((sttStr + sttAddC) / 6);
  bonusVit = parseInt((sttVit + sttAddD) / 6);
  bonusInt = parseInt((sttInt + sttAddE) / 6);
  bonusMnd = parseInt((sttMnd + sttAddF) / 6);
  
  document.getElementById("stt-bonus-dex-value").innerHTML = bonusDex;
  document.getElementById("stt-bonus-agi-value").innerHTML = bonusAgi;
  document.getElementById("stt-bonus-str-value").innerHTML = bonusStr;
  document.getElementById("stt-bonus-vit-value").innerHTML = bonusVit;
  document.getElementById("stt-bonus-int-value").innerHTML = bonusInt;
  document.getElementById("stt-bonus-mnd-value").innerHTML = bonusMnd;
  
  reqdStr = sttStr + sttAddC;
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
  
  const array = featsLv;
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
      
      const weaponsRegex = new RegExp('武器習熟(Ａ|Ｓ)／(' + weapons.join('|') + ')');
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
  Object.keys(classes).forEach(function(key) {
    let cLv = lv[key];
    if (classes[key]['craftData']){
      const eName = classes[key]['craft'];
      document.getElementById("craft-"+eName).style.display = cLv ? "block" : "none";
      const cMax = (key.match(/Bar|War/)) ? 20 : (key === 'Art') ? 19 : 17;
      cLv += (key === 'Bar') ? (feats['呪歌追加'] || 0) : (key === 'War') ? (feats['鼓咆陣率追加'] || 0) : (key === 'Art' && lv.Art === 16) ? 1 : (key === 'Art' && lv.Art === 17) ? 2 : 0;
      for (let i = 1; i <= cMax; i++) {
        let cL = document.getElementById("craft-"+eName+i).classList;
        if (i <= cLv){
          cL.remove("fail","hidden");
        }
        else {
          cL.add("fail");
          if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
        }
      }
    }
    else if (classes[key]['magicData']){
      const eName = classes[key]['magic'];
      document.getElementById("magic-"+eName).style.display = lv[key] ? "block" : "none";
      const cMax = 17;
      for (let i = 1; i <= cMax; i++) {
        let cL = document.getElementById("magic-"+eName+i).classList;
        if(i <= lv[key]){ cL.remove("fail","hidden"); }
        else {
          cL.add("fail");
          if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
        }
      }
    }
  });
}

// ＨＰＭＰ抵抗力計算 ----------------------------------------
function calcSubStt() {
  const seekerHpMpAdd = (lvSeeker && checkSeekerAbility('ＨＰ、ＭＰ上昇')) ? 10 : 0;
  const seekerResistAdd = (lvSeeker && checkSeekerAbility('抵抗力上昇')) ? 3 : 0;
  
  const vitResistBase = level + bonusVit;
  const mndResistBase = level + bonusMnd;
  const vitResistAutoAdd = 0 + (feats['抵抗強化'] || 0) + seekerResistAdd;
  const mndResistAutoAdd = raceAbilityMndResist + (feats['抵抗強化'] || 0) + seekerResistAdd;
  document.getElementById("vit-resist-base").innerHTML = vitResistBase;
  document.getElementById("mnd-resist-base").innerHTML = mndResistBase;
  document.getElementById("vit-resist-auto-add").innerHTML = vitResistAutoAdd;
  document.getElementById("mnd-resist-auto-add").innerHTML = mndResistAutoAdd;
  document.getElementById("vit-resist-total").innerHTML = vitResistBase + Number(form.vitResistAdd.value) + vitResistAutoAdd;
  document.getElementById("mnd-resist-total").innerHTML = mndResistBase + Number(form.mndResistAdd.value) + mndResistAutoAdd;
  
  const accessories = [
    "Head", "Head_", "Face", "Face_", "Ear", "Ear_", "Neck", "Neck_", "Back", "Back_", "HandR", "HandR_", "HandL", "HandL_", "Waist", "Waist_", "Leg", "Leg_", "Other", "Other_", "Other2", "Other2_", "Other3", "Other3_", "Other4", "Other4_"
  ]
  let hpAccessory = 0;
  let mpAccessory = 0;
  for (let i of accessories){
    if(form["accessory"+i+"Own"].options[form["accessory"+i+"Own"].selectedIndex].value === "HP"){ hpAccessory = 2 }
    if(form["accessory"+i+"Own"].options[form["accessory"+i+"Own"].selectedIndex].value === "MP"){ mpAccessory = 2 }
  }
  
  const hpBase = level * 3 + sttVit + sttAddD;
  const mpBase = 
    (race === 'マナフレア') ? (level * 3 + sttMnd + sttAddF)
    : ( levelCasters.reduce((a,x) => a+x,0) * 3 + sttMnd + sttAddF );
  const hpAutoAdd = (feats['頑強'] || 0) + hpAccessory + (lv['Fig'] >= 7 ? 15 : 0) + seekerHpMpAdd;
  const mpAutoAdd = (feats['キャパシティ'] || 0) + raceAbilityMp + mpAccessory + seekerHpMpAdd;
  document.getElementById("hp-base").innerHTML = hpBase;
  document.getElementById("mp-base").innerHTML = (race === 'グラスランナー') ? '0' : mpBase;
  document.getElementById("hp-auto-add").innerHTML = hpAutoAdd;
  document.getElementById("mp-auto-add").innerHTML = mpAutoAdd;
  document.getElementById("hp-total").innerHTML = hpBase + Number(form.hpAdd.value) + hpAutoAdd;
  document.getElementById("mp-total").innerHTML = (race === 'グラスランナー') ? 'なし' : (mpBase + Number(form.mpAdd.value) + mpAutoAdd);
}

// 移動力計算 ----------------------------------------
function calcMobility() {
  const agi = sttAgi + sttAddB;
  const mobilityBase = ((race === 'ケンタウロス') ? (agi * 2) : agi) + (form["armour1Own"].checked ? 2 : 0);
  const mobility = mobilityBase + Number(form.mobilityAdd.value);
  document.getElementById("mobility-limited").innerHTML = feats['足さばき'] ? 10 : 3;
  document.getElementById("mobility-base").innerHTML = mobilityBase;
  document.getElementById("mobility-total").innerHTML = mobility;
  document.getElementById("mobility-full").innerHTML = mobility * 3;
}

// パッケージ計算 ----------------------------------------
function calcPackage() {
  const bonus = {
    'A': bonusDex,
    'B': bonusAgi,
    'C': bonusStr,
    'D': bonusVit,
    'E': bonusInt,
    'F': bonusMnd,
  };
  let lore = [];
  let init = [];
  Object.keys(classes).forEach(function(cId) {
    if(classes[cId]['package']){
      const className = classes[cId]['eName'];
      const data = classes[cId]['package'];

      document.getElementById(`package-${className}`).style.display = lv[cId] > 0 ? "" :"none";

      Object.keys(data).forEach(function(pId) {
        if(cId === 'War' && pId === 'Int'){
          let hit = 0;
          for(let i = 1; i <= lv['War']+(feats['鼓咆陣率追加']||0); i++){
            if(form[`craftCommand${i}`].value.match(/軍師の知略$/)){ hit = 1; break; }
          }
          if(!hit){
            document.getElementById(`package-${className}-${pId.toLowerCase()}`).innerHTML = '―';
            return;
          }
        }
        
        let v = lv[cId] + bonus[data[pId]['stt']] + Number(form[`pack${cId}${pId}Add`].value);
        document.getElementById(`package-${className}-${pId.toLowerCase()}`).innerHTML = v;

        if(data[pId]['monsterLore']){ lore.push(lv[cId] > 0 ? v : 0); }
        if(data[pId]['initiative' ]){ init.push(lv[cId] > 0 ? v : 0); }
      });
    }
  });

  
  document.getElementById("monster-lore-value").innerHTML = (Math.max(...lore) || 0) + Number(form.monsterLoreAdd.value);
  document.getElementById("initiative-value"  ).innerHTML = (Math.max(...init) || 0) + Number(form.initiativeAdd.value);
}

// 魔力計算 ----------------------------------------
let magicPowers = {};
function calcMagic() {
  const addPower = Number(form.magicPowerAdd.value) + (feats['魔力強化'] || 0);
  document.getElementById("magic-power-magicenhance-value").innerHTML = feats['魔力強化'] || 0;
  const addCast = Number(form.magicCastAdd.value);
  const addDamage = Number(form.magicDamageAdd.value);
  
  let openMagic = 0;
  let openCraft = 0;
  Object.keys(classes).forEach(function(key) {
    // 魔法
    if(classes[key]['magic']){
      const eName = classes[key]['eName'];
      document.getElementById("magic-power-"+eName).style.display = lv[key] ? '' : 'none';
      if(lv[key]){ openMagic++; }
      
      const seekerMagicAdd = (lvSeeker && checkSeekerAbility('魔力上昇') && lv[key] >= 15) ? 3 : 0;
      let power = lv[key] + parseInt((sttInt + sttAddE + (form["magicPowerOwn"+key].checked ? 2 : 0)) / 6) + Number(form["magicPowerAdd"+key].value) + addPower + seekerMagicAdd + raceAbilityMagicPower;
      if(key === 'Pri' && race.match(/^センティアン/)){
        power += (level >= 11) ? 2 : (level >= 6) ? 1 : 0;
      }
      document.getElementById("magic-power-"+eName+"-value").innerHTML  = power;
      document.getElementById("magic-cast-"+eName+"-value").innerHTML   = power + Number(form["magicCastAdd"+key].value) + addCast;
      document.getElementById("magic-damage-"+eName+"-value").innerHTML = Number(form["magicDamageAdd"+key].value) + addDamage;
      magicPowers[key] = lv[key] ? power : 0;
    }
    // 呪歌など
    else if(classes[key]['craftStt']){
      const eName = classes[key]['eName'];
      document.getElementById("magic-power-"+eName).style.display = lv[key] ? '' : 'none';
      if(lv[key]){ openCraft++; }
      
      let power = lv[key];
      if     (classes[key]['craftStt'] === '知力')  {
        power += parseInt((sttInt + sttAddE + (form["magicPowerOwn"+key].checked ? 2 : 0)) / 6);
      }
      else if(classes[key]['craftStt'] === '精神力'){
        power += parseInt((sttMnd + sttAddF + (form["magicPowerOwn"+key].checked ? 2 : 0)) / 6);
      }
      if(classes[key]['craftPower']){
        power += Number(form["magicPowerAdd"+key].value);
        document.getElementById("magic-power-"+eName+"-value").innerHTML  = power;
        document.getElementById("magic-damage-"+eName+"-value").innerHTML = Number(form["magicDamageAdd"+key].value);
      }
      
      if(key === 'Alc'){ power += feats['賦術強化'] || 0 }
      document.getElementById("magic-cast-"+eName+"-value").innerHTML   = power + Number(form["magicCastAdd"+key].value);
    }
  });
  // 全体／その他の開閉
  document.getElementById("magic-power").style.display = (openMagic || openCraft) ? '' : 'none';

  document.getElementById("magic-power-raceability" ).style.display = race.match(/^ハイマン|^センティアン/)  ? '' : 'none';
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
  document.getElementById('fairy-rank').innerHTML = result;
}

// 攻撃計算 ----------------------------------------
function calcAttack() {
  for(const name of weaponsUsers){
    const id    = classNameToId[name];
    const eName = classes[id].eName;
    document.getElementById(`attack-${eName}`).style.display = lv[id] > 0 ? "" :"none";
    document.getElementById(`attack-${eName}-str`).innerHTML = id == 'Fen' ? reqdStrHalf : reqdStr;
    document.getElementById(`attack-${eName}-acc`).innerHTML = lv[id] + bonusDex;
    document.getElementById(`attack-${eName}-dmg`).innerHTML = lv[id] + bonusStr;
  }
  document.getElementById("attack-enhancer"  ).style.display = lv['Enh'] >= 10 ? "" :"none";
  document.getElementById("attack-enhancer-str").innerHTML   = reqdStr;
  document.getElementById("attack-enhancer-acc"  ).innerHTML = lv['Enh'] + bonusDex;
  document.getElementById("attack-enhancer-dmg"  ).innerHTML = lv['Enh'] + bonusStr;

  document.getElementById("attack-demonruler").style.display = lv['Dem'] >= 10 ? "" : modeZero && lv['Dem'] > 0 ? "" :"none";
  document.getElementById("attack-demonruler-str").innerHTML = reqdStr;
  document.getElementById("attack-demonruler-acc").innerHTML = lv['Dem'] + bonusDex;
  document.getElementById("attack-demonruler-dmg").innerHTML = modeZero ? lv['Dem'] + bonusStr : '―';

  calcWeapon();
}
function calcWeapon() {
  for (let i = 1; i <= form.weaponNum.value; i++){
    const className = form["weapon"+i+"Class"].value;
    const classId   = classNameToId[className];
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
    if(classId && classes[classId].type == 'weapon-user'){
      attackClass = lv[classId];
      if(className === "フェンサー"){ maxReqd = reqdStrHalf; }
    }
    else if(className === "エンハンサー")     { attackClass = lv['Enh']; }
    else if(className === "デーモンルーラー") { attackClass = lv['Dem']; }
    // 必筋チェック
    form["weapon"+i+"Reqd"].classList.toggle('error', weaponReqd > maxReqd);
    // 武器カテゴリ
    if(attackClass) {
      // 基礎命中
      accBase += attackClass + parseInt((sttDex + sttAddA + ownDex) / 6);
    }
    // 基礎ダメージ
    if     (category === 'クロスボウ')                  { dmgBase = attackClass; }
    else if(category === 'ガン')                        { dmgBase = magicPowers['Mag']; }
    else if(!modeZero && className === "デーモンルーラー"){ dmgBase = magicPowers['Dem']; }
    else if(attackClass)                                { dmgBase = attackClass + bonusStr; }
    form["weapon"+i+"Category"].classList.remove('fail');

    // 習熟
    if(category === 'ガン（物理）') { dmgBase += feats['武器習熟／ガン'] || 0; }
    else if(category) { dmgBase += feats['武器習熟／'+category] || 0; }

    if(category === '投擲') { accBase += feats['スローイング'] ? 1 : 0; }
    if(note.match(/〈魔器〉/)){ dmgBase += feats['魔器習熟'] || 0; }
    // 命中追加D出力
    if(className === "自動計算しない"){
      document.getElementById("weapon"+i+"-acc-total").innerHTML = Number(form["weapon"+i+"Acc"].value);
      document.getElementById("weapon"+i+"-dmg-total").innerHTML = Number(form["weapon"+i+"Dmg"].value);
    }
    else {
      document.getElementById("weapon"+i+"-acc-total").innerHTML = accBase + Number(form["weapon"+i+"Acc"].value);
      document.getElementById("weapon"+i+"-dmg-total").innerHTML = dmgBase + Number(form["weapon"+i+"Dmg"].value);
    }
  }
  
  for(let i = 0; i < weapons.length; i++){
    document.getElementById(`attack-${weaponsId[i]}-mastery`).style.display = feats['武器習熟／'+weapons[i]] ? '' : 'none';
    document.getElementById(`attack-${weaponsId[i]}-mastery-dmg`).innerHTML = feats['武器習熟／'+weapons[i]] || 0;
  }
  document.getElementById("attack-artisan-mastery").style.display  = feats['魔器習熟'] ? '' : 'none';
  document.getElementById("attack-artisan-mastery-dmg").innerHTML  = feats['魔器習熟'] || 0 ;
  document.getElementById("artisan-annotate").style.display        = feats['魔器習熟'] ? '' : 'none'; 
  document.getElementById("accuracy-enhance").style.display        = feats['命中強化'] ? '' : 'none';
  document.getElementById("accuracy-enhance-acc").innerHTML        = feats['命中強化'] || 0;
  document.getElementById("throwing").style.display                = feats['スローイング'] ? '' : 'none';
}

// 防御計算 ----------------------------------------
function calcDefense() {
  const className = form.evasionClass.options[form.evasionClass.selectedIndex].value;
  const classId   = classNameToId[className];
  let evaClassLv = 0;
  let evaBase = 0;
  let evaAdd = 0;
  let defBase = 0;
  if(classId && classes[classId].type == 'weapon-user'){
    evaClassLv = lv[classId];
  }
  else if(className === "デーモンルーラー"){ evaClassLv = lv['Dem']; }
  else { evaClassLv = 0; }
  evaBase = evaClassLv || 0;
  
  const maxReqd = (className === "フェンサー") ? reqdStrHalf : reqdStr;
  document.getElementById("evasion-str").innerHTML = maxReqd;
  document.getElementById("evasion-eva").innerHTML = evaClassLv ? (evaClassLv + bonusAgi) : 0;
  
  // 技能選択のエラー表示
  let cL = document.getElementById("evasion-classes").classList;
  if(className === "シューター" && !feats['射手の体術'] || className === "デーモンルーラー" && lv['Dem'] < 2){ 
    cL.add('error');
  }
  else { cL.remove('error'); }
  
  // 種族特徴
  defBase += raceAbilityDef;
  document.getElementById("race-ability-def").style.display = raceAbilityDef > 0 ? "" :"none";
  document.getElementById("race-ability-def-value").innerHTML  = raceAbilityDef;
  // 求道者
  if(form.lvSeeker){
    const seekerDefense = lvSeeker >= 18 ? 10
                        : lvSeeker >= 14 ?  8
                        : lvSeeker >= 10 ?  6
                        : lvSeeker >=  6 ?  4
                        : lvSeeker >=  2 ?  2
                        : 0;
    defBase += seekerDefense;
    document.getElementById('seeker-defense-value').innerHTML = seekerDefense;
  }
  // 習熟
  document.getElementById("mastery-metalarmour").style.display    = feats['防具習熟／金属鎧']   > 0 ? "" :"none";
  document.getElementById("mastery-nonmetalarmour").style.display = feats['防具習熟／非金属鎧'] > 0 ? "" :"none";
  document.getElementById("mastery-shield").style.display         = feats['防具習熟／盾']       > 0 ? "" :"none";
  document.getElementById("mastery-artisan-def").style.display    = feats['魔器習熟']           > 0 ? "" :"none";
  document.getElementById("mastery-metalarmour-value").innerHTML    = feats['防具習熟／金属鎧']   || 0;
  document.getElementById("mastery-nonmetalarmour-value").innerHTML = feats['防具習熟／非金属鎧'] || 0;
  document.getElementById("mastery-shield-value").innerHTML         = feats['防具習熟／盾']       || 0;
  document.getElementById("mastery-artisan-def-value").innerHTML    = feats['魔器習熟']           || 0;
  // 回避行動
  evaAdd += feats['回避行動'] || 0;
  document.getElementById("evasive-maneuver").style.display = feats['回避行動'] > 0 ? "" :"none";
  document.getElementById("evasive-maneuver-value").innerHTML = feats['回避行動'] || 0;
  // 心眼
  evaAdd += feats['心眼'] || 0;
  document.getElementById("minds-eye").style.display = feats['心眼'] > 0 ? "" :"none";
  document.getElementById("minds-eye-value").innerHTML = feats['心眼'] || 0;
  
  calcArmour(evaBase,evaAdd,defBase,maxReqd);
}
function calcArmour(evaBase,evaAdd,defBase,maxReqd) {
  const armour1Eva = Number(form.armour1Eva.value);
  const armour1Def = Number(form.armour1Def.value) + Math.max((feats['防具習熟／金属鎧'] || 0),(feats['防具習熟／非金属鎧'] || 0));
  const shield1Eva = Number(form.shield1Eva.value);
  const shield1Def = Number(form.shield1Def.value) + (feats['防具習熟／盾'] || 0);
  const other1Eva = Number(form.defOther1Eva.value);
  const other1Def = Number(form.defOther1Def.value);
  const other2Eva = Number(form.defOther2Eva.value);
  const other2Def = Number(form.defOther2Def.value);
  const other3Eva = Number(form.defOther3Eva.value);
  const other3Def = Number(form.defOther3Def.value);
  
  //document.getElementById("defense-total-all-eva").innerHTML = evaBase + armourEva + shieldEva + other1Eva + other2Eva + parseInt((sttAgi + sttAddB + ownAgi) / 6);
  //document.getElementById("defense-total-all-def").innerHTML = defBase + armourDef + shieldDef + other1Def + other2Def;
  
  for (let i = 1; i <= 3; i++){
    const ownAgi = form[`defTotal${i}CheckShield1`].checked && form.shield1Own.checked ? 2 : 0;
    let eva = ( evaBase ? evaBase + evaAdd + parseInt((sttAgi + sttAddB + ownAgi) / 6) : 0 );
    let def = defBase;
    if(form[`defTotal${i}CheckArmour1`].checked)  { eva += armour1Eva; def += armour1Def; }
    if(form[`defTotal${i}CheckShield1`].checked)  { eva += shield1Eva; def += shield1Def; }
    if(form[`defTotal${i}CheckDefOther1`].checked){ eva +=  other1Eva; def +=  other1Def; }
    if(form[`defTotal${i}CheckDefOther2`].checked){ eva +=  other2Eva; def +=  other2Def; }
    if(form[`defTotal${i}CheckDefOther3`].checked){ eva +=  other3Eva; def +=  other3Def; }
    if((form[`defTotal${i}CheckArmour1`].checked && form.armour1Note.value.match(/〈魔器〉/))
    || (form[`defTotal${i}CheckShield1`].checked && form.shield1Note.value.match(/〈魔器〉/))){
      def += feats['魔器習熟'] || 0;
    }
    
    document.getElementById(`defense-total${i}-eva`).innerHTML = eva;
    document.getElementById(`defense-total${i}-def`).innerHTML = def;
  }
  
  form.armour1Reqd.classList.toggle(  'error', (safeEval(form.armour1Reqd.value)   || 0) > maxReqd);
  form.shield1Reqd.classList.toggle(  'error', (safeEval(form.shield1Reqd.value)   || 0) > maxReqd);
  form.defOther1Reqd.classList.toggle('error', (safeEval(form.defOther1Reqd.value) || 0) > maxReqd);
  form.defOther2Reqd.classList.toggle('error', (safeEval(form.defOther2Reqd.value) || 0) > maxReqd);
  form.defOther3Reqd.classList.toggle('error', (safeEval(form.defOther3Reqd.value) || 0) > maxReqd);
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
  document.getElementById("exp-rest").innerHTML = commify(expTotal - expUse);
  document.getElementById("exp-total").innerHTML = commify(expTotal);
  document.getElementById("history-exp-total").innerHTML = commify(expTotal);
  
  // 最大成長回数
  let growMax = 0;
  if(growType === 'A'){
    let count = 0;
    let exp = 3000;
    for(let i = 0; exp <= expTotal; i++){
      count = i;
      const next = 1000 + i * 10;
      exp += next;
    }
    growMax = count;
  }
  else if(growType === 'O') {
    growMax = Math.floor((expTotal - 3000) / 1000);
  }
  else { return; }
  document.getElementById("stt-grow-max-value").innerHTML = ' / ' + growMax;
  document.getElementById("history-grow-max-value").innerHTML = '/' + growMax;
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
  document.getElementById("history-honor-total").innerHTML = commify(pointTotal);
  // ランク
  const rank = form["rank"].options[form["rank"].selectedIndex].value;
  const rankNum = (adventurerRank[rank]["num"] === undefined) ? 0 : adventurerRank[rank]["num"];
  const free = (adventurerRank[rank]["free"] === undefined) ? 0 : adventurerRank[rank]["free"];
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
  document.getElementById("honor-value"   ).innerHTML = pointTotal;
  document.getElementById("honor-value-MA").innerHTML = pointTotal;
  document.getElementById("rank-honor-value").innerHTML = rankNum;
  document.getElementById("mystic-arts-honor-value").innerHTML = mysticArtsPt;
  document.getElementById('honor-items-mystic-arts').style.display = mysticArtsPt ? '' : 'none';
}
// 不名誉点計算
function calcDishonor(){
  let pointTotal = 0;
  const dishonorItemsNum = form.dishonorItemsNum.value;
  for (let i = 1; i <= dishonorItemsNum; i++){
    let point = safeEval(form['dishonorItem'+i+'Pt'].value) || 0;
    pointTotal += point;
  }
  pointTotal -= Number(form.honorOffset.value);
  document.getElementById("dishonor-value").innerHTML = pointTotal;
  for(const key in notorietyRank){
    if(pointTotal >= notorietyRank[key]['num']) { document.getElementById("notoriety").innerHTML = key; }
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
  document.getElementById("history-money-total").innerHTML = commify(cash);
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
  document.getElementById('cashbook-total-value').innerHTML = commify(cash);
  document.getElementById('cashbook-deposit-value').innerHTML = commify(deposit);
  document.getElementById('cashbook-debt-value').innerHTML = commify(debt);
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
    //let beforeData = evt.item.innerHTML;
    //let afterData  = evt.swapItem.innerHTML;
    //evt.item.innerHTML     = afterData;
    //evt.swapItem.innerHTML = beforeData;
    //const name = form[`accessory${beforeId}Name`].value;
    //const own  = form[`accessory${beforeId}Own` ].value;
    //const note = form[`accessory${beforeId}Note`].value;
    //form[`accessory${beforeId}Name`].value = form[`accessory${afterId}Name`].value;
    //form[`accessory${beforeId}Own` ].value = form[`accessory${afterId}Own` ].value;
    //form[`accessory${beforeId}Note`].value = form[`accessory${afterId}Note`].value;
    //form[`accessory${afterId}Name`].value = name;
    //form[`accessory${afterId}Own` ].value = own ;
    //form[`accessory${afterId}Note`].value = note;
    
    const beforeTitle = document.querySelector(`#${beforeId} th`).innerHTML;
    document.querySelector(`#${beforeId} th`).innerHTML = document.querySelector(`#${afterId} th`).innerHTML;
    document.querySelector(`#${afterId} th`).innerHTML = beforeTitle;
    
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
  let tbody = document.createElement('li');
  tbody.setAttribute('id',idNumSet('mystic-arts'));
  tbody.innerHTML = `
    <span class="handle"></span>
    <input type="text" name="mysticArts${num}">
    <input type="number" name="mysticArts${num}Pt" oninput="calcHonor()">
  `;
  const target = document.querySelector("#mystic-arts-list");
  target.appendChild(tbody, target);
  form.mysticArtsNum.value = num;
}
// 削除
function delMysticArts(){
  let num = Number(form.mysticArtsNum.value);
  if(num > 0){
    if(form[`mysticArts${num}`].value || form[`mysticArts${num}Pt`].value){
      if (!confirm(delConfirmText)) return false;
    }
    let target = document.getElementById("mystic-arts-list");
    target.removeChild(target.lastElementChild);
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
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = mysticArtsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} input:first-of-type`).setAttribute('name',`mysticArts${num}`);
        document.querySelector(`#${id} [name$="Pt"]`).setAttribute('name',`mysticArts${num}Pt`);
        num++;
      }
    }
  }
});
// 秘伝魔法欄 ----------------------------------------
// 追加
function addMysticMagic(){
  let num = Number(form.mysticMagicNum.value) + 1;
  let tbody = document.createElement('li');
  tbody.setAttribute('id',idNumSet('mystic-magic'));
  tbody.innerHTML = `
    <span class="handle"></span>
    <input type="text" name="mysticMagic${num}">
    <input type="number" name="mysticMagic${num}Pt" oninput="calcHonor()">
  `;
  const target = document.querySelector("#mystic-magic-list");
  target.appendChild(tbody, target);
  form.mysticMagicNum.value = num;
}
// 削除
function delMysticMagic(){
  let num = Number(form.mysticMagicNum.value);
  if(num > 0){
    if(form[`mysticMagic${num}`].value || form[`mysticMagic${num}Pt`].value){
      if (!confirm(delConfirmText)) return false;
    }
    let target = document.getElementById("mystic-magic-list");
    target.removeChild(target.lastElementChild);
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
    const order = mysticArtsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
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
  if(races[race]['language']){ for(let data of races[race]['language']){ acqT[data[0]] = data[1]; acqR[data[0]] = data[2]; } }
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
  for (let key in classes){
    if(!classes[key]['language']){ continue; }
    for (let langName in classes[key]['language']){
      const data = classes[key]['language'][langName];
      const notT = (data.talk && !acqT[langName]) ? true : false;
      const notR = (data.read && !acqR[langName]) ? true : false;
      if(langName === 'any'){
        const v = lv[key] - (count[key] || 0);
        if     (v > 0){ notice += `${classes[key]['jName']}技能であと「${v}」習得できます<br>`; }
        else if(v < 0){ notice += `${classes[key]['jName']}技能での習得が「${v*-1}」過剰です<br>`; }
      }
      else if(lv[key] && (notT || notR)) {
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
  let tbody = document.createElement('tr');
  tbody.setAttribute('id',idNumSet('language-item'));
  tbody.innerHTML = `
    <td class="handle"></td>
    <td><input name="language${num}" type="text" oninput="checkLanguage()" list="list-language"></td>
    <td><select name="language${num}Talk" oninput="checkLanguage()">${langOptionT}</select><span class="lang-select-view"></span></td>
    <td><select name="language${num}Read" oninput="checkLanguage()">${langOptionR}</select><span class="lang-select-view"></span></td>
  `;
  const target = document.querySelector("#language-table tbody");
  target.appendChild(tbody, target);
  form.languageNum.value = num;
}
// 削除
function delLanguage(){
  let num = Number(form.languageNum.value);
  if(num > 1){
    if(form[`language${num}`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#language-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
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
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = languageSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
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
  const ini = {
    "name"    : copy ? form[`weapon${copy}Name`    ].value : '',
    "usage"   : copy ? form[`weapon${copy}Usage`   ].value : '',
    "reqd"    : copy ? form[`weapon${copy}Reqd`    ].value : '',
    "acc"     : copy ? form[`weapon${copy}Acc`     ].value : '',
    "rate"    : copy ? form[`weapon${copy}Rate`    ].value : '',
    "crit"    : copy ? form[`weapon${copy}Crit`    ].value : '',
    "dmg"     : copy ? form[`weapon${copy}Dmg`     ].value : '',
    "own"     : copy ? form[`weapon${copy}Own`     ].checked : false,
    "category": copy ? form[`weapon${copy}Category`].value : '',
    "class"   : copy ? form[`weapon${copy}Class`   ].value : '',
    "note"    : copy ? form[`weapon${copy}Note`    ].value : '',
  };
  let num = Number(form.weaponNum.value) + 1;
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id',idNumSet('weapon-row'));
  tbody.innerHTML = `<tr>
    <td rowspan="2"><input name="weapon${num}Name"  type="text" value="${ini.name}"><span class="handle"></span></td>
    <td rowspan="2"><input name="weapon${num}Usage" type="text" value="${ini.usage}" list="list-usage"></td>
    <td rowspan="2"><input name="weapon${num}Reqd"  type="text" value="${ini.reqd}"></td>
    <td rowspan="2">+<input name="weapon${num}Acc" type="number" value="${ini.acc}" oninput="calcWeapon()"><b id="weapon${num}-acc-total">0</b></td>
    <td rowspan="2"><input name="weapon${num}Rate" type="text" value="${ini.rate}"></td>
    <td rowspan="2"><input name="weapon${num}Crit" type="text" value="${ini.crit}"></td>
    <td rowspan="2">+<input name="weapon${num}Dmg" type="number" value="${ini.dmg}" oninput="calcWeapon()"><b id="weapon${num}-dmg-total">0</b></td>
    <td><input name="weapon${num}Own" type="checkbox" value="1" ${ini.own?'checked':''} oninput="calcWeapon()"></td>
    <td><select name="weapon${num}Category" oninput="calcWeapon()"><option></select></td>
    <td><select name="weapon${num}Class" oninput="calcWeapon()"><option></select></td>
    <td rowspan="2"><span class="button" onclick="addWeapons(${num});">複<br>製</span></td>
  </tr>
  <tr><td colspan="3"><input name="weapon${num}Note" type="text" value="${ini.note}" oninput="calcWeapon()"></td></tr>`;
  const target = document.querySelector("#weapons-table");
  target.appendChild(tbody, target);
  
  const categories = weapons.concat("ガン（物理）","盾");
  for(let i = 0; i < categories.length; i++){
    let op = document.createElement("option");
    op.text = categories[i];
    op.selected = categories[i] === ini.category ? true : false;
    form["weapon"+num+"Category"].appendChild(op);
  }
  const classes = weaponsUsers.concat('エンハンサー','デーモンルーラー','自動計算しない');
  for(let i = 0; i < classes.length; i++){
    let op = document.createElement("option");
    op.text = classes[i];
    op.selected = classes[i] === ini.class ? true : false;
    form["weapon"+num+"Class"].appendChild(op);
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
    const target = document.querySelector("#weapons-table tbody:last-of-type");
    target.parentNode.removeChild(target);
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
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = weaponsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
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

// 名誉アイテム欄 ----------------------------------------
// 追加
function addHonorItems(){
  let num = Number(form.honorItemsNum.value) + 1;
  let tbody = document.createElement('tr');
  tbody.setAttribute('id',idNumSet('honor-item'));
  tbody.innerHTML = `
    <td class="handle"></td>
    <td><input type="text" name="honorItem${num}"></td>
    <td><input type="number" name="honorItem${num}Pt" oninput="calcHonor()"></td>
  `;
  const target = document.querySelector("#honor-items-table");
  target.appendChild(tbody, target);
  form.honorItemsNum.value = num;
}
// 削除
function delHonorItems(){
  let num = Number(form.honorItemsNum.value);
  if(num > 1){
    if(form[`honorItem${num}`].value || form[`honorItem${num}Pt`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#honor-items-table tr:last-of-type");
    target.parentNode.removeChild(target);
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
  //filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = honorSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [type="text"]`  ).setAttribute('name',`honorItem${num}`);
        document.querySelector(`#${id} [type="number"]`).setAttribute('name',`honorItem${num}Pt`);
        num++;
      }
    }
  }
});
// 不名誉欄 ----------------------------------------
// 追加
function addDishonorItems(){
  let num = Number(form.dishonorItemsNum.value) + 1;
  let tbody = document.createElement('tr');
  tbody.setAttribute('id',idNumSet('dishonor-item'));
  tbody.innerHTML = `
    <td class="handle"></td>
    <td><input type="text" name="dishonorItem${num}"></td>
    <td><input type="number" name="dishonorItem${num}Pt" oninput="calcDishonor()"></td>
  `;
  const target = document.querySelector("#dishonor-items-table tbody");
  target.appendChild(tbody, target);
  form.dishonorItemsNum.value = num;
}
// 削除
function delDishonorItems(){
  let num = Number(form.dishonorItemsNum.value);
  if(num > 1){
    if(form[`dishonorItem${num}`].value || form[`dishonorItem${num}Pt`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#dishonor-items-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.dishonorItemsNum.value = num;
  }
  calcDishonor();
}
// ソート
let dishonorSortable = Sortable.create(document.querySelector('#dishonor-items-table tbody'), {
  group: "dishonor",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = dishonorSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [type="text"]`  ).setAttribute('name',`dishonorItem${num}`);
        document.querySelector(`#${id} [type="number"]`).setAttribute('name',`dishonorItem${num}Pt`);
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
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id',idNumSet('history'));
  tbody.innerHTML = `<tr>
    <td rowspan="2" class="handle"></td>
    <td rowspan="2"><input name="history${num}Date"   type="text"></td>
    <td rowspan="2"><input name="history${num}Title"  type="text"></td>
    <td><input name="history${num}Exp"    type="text" oninput="calcExp()"></td>
    <td><input name="history${num}Money"  type="text" oninput="calcCash()"></td>
    <td><input name="history${num}Honor"  type="text" oninput="calcHonor()"></td>
    <td><input name="history${num}Grow"   type="text" oninput="calcStt()" list="list-grow"></td>
    <td><input name="history${num}Gm"     type="text"></td>
    <td><input name="history${num}Member" type="text"></td>
  </tr>
  <tr><td colspan="6" class="left"><input name="history${num}Note" type="text"></td></tr>`;
  const target = document.querySelector("#history-table tfoot");
  target.parentNode.insertBefore(tbody, target);
  
  form.historyNum.value = num;
}
// 削除
function delHistory(){
  let num = Number(form.historyNum.value);
  if(num > 1){
    if(form[`history${num}Date`].value || form[`history${num}Title`].value || form[`history${num}Exp`].value || form[`history${num}Honor`].value || form[`history${num}Money`].value || form[`history${num}Grow`].value || form[`history${num}Gm`].value || form[`history${num}Member`].value || form[`history${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#history-table tbody:last-of-type");
    target.parentNode.removeChild(target);
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
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = historySortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Date"]`  ).setAttribute('name',`history${num}Date`);
        document.querySelector(`#${id} [name$="Title"]` ).setAttribute('name',`history${num}Title`);
        document.querySelector(`#${id} [name$="Exp"]`   ).setAttribute('name',`history${num}Exp`);
        document.querySelector(`#${id} [name$="Honor"]` ).setAttribute('name',`history${num}Honor`);
        document.querySelector(`#${id} [name$="Money"]` ).setAttribute('name',`history${num}Money`);
        document.querySelector(`#${id} [name$="Grow"]`  ).setAttribute('name',`history${num}Grow`);
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
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
  if(races[race] && races[race]['dice']){
    ['A','B','C','D','E','F'].forEach((i) => {
      const dice = String(races[race]['dice'][i]);
      let num  = Number(form[`sttBase${i}`].value);
      if(races[race]['dice'][`${i}+`]){ num -= races[race]['dice'][`${i}+`]; }
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
  document.getElementById("stt-pointbuy-AtoF-value").innerHTML = errorFlag ? '×' : points;

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
    document.getElementById("stt-pointbuy-TPS-value").innerHTML = errorFlag ? '×' : points;
  }
  else {
    document.getElementById("stt-pointbuy-TPS-value").innerHTML = '―';
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
