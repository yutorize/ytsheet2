"use strict";
const form = document.sheet;

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
  ]
};

let race = form.race.value;
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

const delConfirmText = '項目に値が入っています。本当に削除しますか？';

window.onload = function() {
  checkRace();
  calcExp();
  calcLv();
  calcStt();
  calcCash();
  calcHonor();
  imagePosition();
  changeColor();
};

function changeRegu(){
  document.getElementById("history0-exp").innerHTML = form.history0Exp.value;
  document.getElementById("history0-honor").innerHTML = form.history0Honor.value;
  document.getElementById("history0-money").innerHTML = form.history0Money.value;
  
  calcExp();
  calcLv();
  calcCash();
}

function changeFaith(Faith) {
  if(Faith.options[Faith.selectedIndex].value === 'その他の信仰'){
    form.faithOther.style.display = '';
  } else {
    form.faithOther.style.display = 'none';
  }
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
function calcLv(){
  expUse = 0;
  let allClassLv = [];
  levelCasters = [];
  Object.keys(classes).forEach(function(key) {
    lv[key] = Number(form['lv'+key].value);
    if(classes[key]['2.0'] && !AllClassOn){ lv[key] = 0; }
    
    expUse += expTable[ classes[key]['expTable'] ][ lv[key] ];
    
    allClassLv.push(lv[key]);
    if(classes[key]['magic']){ levelCasters.push(lv[key]); }
  });
  
  document.getElementById("exp-use").innerHTML = expUse;
  document.getElementById("exp-rest").innerHTML = expTotal - expUse;
  
  level = Math.max.apply(null, Object.values(lv));
  document.getElementById("level-value").innerHTML = level;
  
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
}

// 種族変更 ----------------------------------------
function changeRace(){
  race = form.race.value;
  document.getElementById("race-ability-value").innerHTML = raceAbility[race];
  if (!form.languageAutoOff.checked) { document.getElementById("language-default").innerHTML = raceLanguage[race] ? raceLanguage[race] : '<dt>初期習得言語</dt><dd>○</dd><dd>○</dd>'; }
  else { document.getElementById("language-default").innerHTML = ''; }
  
  checkRace();
  calcStt();
}

// 種族チェック ----------------------------------------
function checkRace(){
  raceAbilityDef = 0;
  raceAbilityMndResist = 0;
  raceAbilityMp = 0;
  
  document.getElementById("classFig").classList.remove('fail');
  document.getElementById("classGra").classList.remove('fail');
  document.getElementById("classFen").classList.remove('fail');
  document.getElementById("classSho").classList.remove('fail');
  document.getElementById("classSor").classList.remove('fail');
  document.getElementById("classCon").classList.remove('fail');
  document.getElementById("classPri").classList.remove('fail');
  document.getElementById("classFai").classList.remove('fail');
  document.getElementById("classMag").classList.remove('fail');
  document.getElementById("classSco").classList.remove('fail');
  document.getElementById("classRan").classList.remove('fail');
  document.getElementById("classSag").classList.remove('fail');
  document.getElementById("classEnh").classList.remove('fail');
  document.getElementById("classBar").classList.remove('fail');
  document.getElementById("classRid").classList.remove('fail');
  document.getElementById("classAlc").classList.remove('fail');
  if(AllClassOn) document.getElementById("classWar").classList.remove('fail');
  if(AllClassOn) document.getElementById("classMys").classList.remove('fail');
  if(AllClassOn) document.getElementById("classDem").classList.remove('fail');
  if(AllClassOn) document.getElementById("classPhy").classList.remove('fail');
  if(AllClassOn) document.getElementById("classGri").classList.remove('fail');
  if(AllClassOn) document.getElementById("classArt").classList.remove('fail');
  if(AllClassOn) document.getElementById("classAri").classList.remove('fail');
  
  if(race === 'ルーンフォーク'){
    document.getElementById("classPri").classList.add('fail');
    document.getElementById("classFai").classList.add('fail');
    document.getElementById("classDru").classList.add('fail');
  }
  else if(race === 'タビット'){
    document.getElementById("classPri").classList.add('fail');
  }
  else if(race === 'リルドラケン'){
    raceAbilityDef = 1;
    document.getElementById("race-ability-def-name").innerHTML = '鱗の皮膚';
  }
  else if(race === 'シャドウ'){
    raceAbilityMndResist = 4;
  }
  else if(race === 'フロウライト'){
    raceAbilityDef = 2;
    raceAbilityMp = 15;
    document.getElementById("race-ability-def-name").innerHTML = '晶石の身体';
  }
  else if(race === 'フィー'){
    document.getElementById("classPri").classList.add('fail');
    document.getElementById("classMag").classList.add('fail');
  }
  else if(race === 'マナフレア'){
    document.getElementById("classSor").classList.add('fail');
    document.getElementById("classCon").classList.add('fail');
    document.getElementById("classPri").classList.add('fail');
    document.getElementById("classFai").classList.add('fail');
    document.getElementById("classMag").classList.add('fail');
    if(AllClassOn) document.getElementById("classDem").classList.add('fail');
    if(AllClassOn) document.getElementById("classGri").classList.add('fail');
  }
  else if(race === 'ダークトロール'){
    raceAbilityDef = 1;
    document.getElementById("race-ability-def-name").innerHTML = 'トロールの体躯';
  }
  else if(race === 'ケンタウロス'){
    document.getElementById("classGra").classList.add('fail');
  }
  else if(race === 'バルカン'){
    document.getElementById("classPri").classList.add('fail');
  }
  
  if(race !== 'ドレイク（ナイト）' && race !== 'バジリスク'){
    if(AllClassOn) document.getElementById("classPhy").classList.add('fail');
  }
}

// ステータス計算 ----------------------------------------
let reqdStr = 0;
let reqdStrHalf = 0;
function calcStt() {
  let growDex = 0;
  let growAgi = 0;
  let growStr = 0;
  let growVit = 0;
  let growInt = 0;
  let growMnd = 0;
  /* // 履歴から成長カウント（未実装）
  const historyNum = form.historyNum.value;
  for (let i = 1; i < historyNum; i++){
    const grow = form["history" + i + "Grow"].value;
  }
  document.getElementById("stt-grow-A-value").innerHTML = growDex;
  document.getElementById("stt-grow-B-value").innerHTML = growAgi;
  document.getElementById("stt-grow-C-value").innerHTML = growStr;
  document.getElementById("stt-grow-D-value").innerHTML = growVit;
  document.getElementById("stt-grow-E-value").innerHTML = growInt;
  document.getElementById("stt-grow-F-value").innerHTML = growMnd;
  */
  growDex = Number(form.sttPreGrowA.value) + sttHistGrowA;
  growAgi = Number(form.sttPreGrowB.value) + sttHistGrowB;
  growStr = Number(form.sttPreGrowC.value) + sttHistGrowC;
  growVit = Number(form.sttPreGrowD.value) + sttHistGrowD;
  growInt = Number(form.sttPreGrowE.value) + sttHistGrowE;
  growMnd = Number(form.sttPreGrowF.value) + sttHistGrowF;
  
  document.getElementById("stt-grow-A-value").innerHTML = growDex;
  document.getElementById("stt-grow-B-value").innerHTML = growAgi;
  document.getElementById("stt-grow-C-value").innerHTML = growStr;
  document.getElementById("stt-grow-D-value").innerHTML = growVit;
  document.getElementById("stt-grow-E-value").innerHTML = growInt;
  document.getElementById("stt-grow-F-value").innerHTML = growMnd;
  document.getElementById("stt-grow-total-value").innerHTML = growDex + growAgi + growStr + growVit + growInt + growMnd;
  
  sttDex = Number(form.sttBaseTec.value) + Number(form.sttBaseA.value) + growDex;
  sttAgi = Number(form.sttBaseTec.value) + Number(form.sttBaseB.value) + growAgi;
  sttStr = Number(form.sttBasePhy.value) + Number(form.sttBaseC.value) + growStr;
  sttVit = Number(form.sttBasePhy.value) + Number(form.sttBaseD.value) + growVit;
  sttInt = Number(form.sttBaseSpi.value) + Number(form.sttBaseE.value) + growInt;
  sttMnd = Number(form.sttBaseSpi.value) + Number(form.sttBaseF.value) + growMnd;
  
  if      (race === 'ウィークリング（ガルーダ）')     sttAgi += 3;
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
function checkFeats(){
  const array = featsLv;
  footwork = 0;
  accuracyEnhance = 0;
  evasiveManeuver = 0;
  magicPowerEnhance = 0;
  alchemyEnhance = 0;
  shootersMartialArts = 0;
  tenacity = 0;
  capacity = 0;
  masteryMetalArmour = 0;
  masteryNonMetalArmour = 0;
  masteryShield = 0;
  masterySword = 0;
  masteryAxe = 0;
  masterySpear = 0;
  masteryMace = 0;
  masteryStaff = 0;
  masteryFlail = 0;
  masteryHammer = 0;
  masteryEntangle = 0;
  masteryGrapple = 0;
  masteryThrow = 0;
  masteryBow = 0;
  masteryCrossbow = 0;
  masteryBlowgun = 0;
  masteryGun = 0;
  masteryArtisan = 0;
  throwing = 0;
  songAddition = 0;
  
  let acquire = '';
  for (let i = 0; i < array.length; i++) {
    let cL = document.getElementById("combat-feats-lv"+array[i]).classList;
    cL.remove("evo","error");
    if(level >= Number( array[i].replace(/[^0-9]/g, '') )){
      const f2 = (level >= Number( array[i+1].replace(/[^0-9]/g, '') )) ? 1 : 0; //次枠の開放状況
      const f3 = (level >= Number( array[i+2].replace(/[^0-9]/g, '') )) ? 1 : 0; //次々枠の開放状況
      const box = form["combatFeatsLv"+array[i]];
      const auto = form.featsAutoOn.checked;
      let feat = box.options[box.selectedIndex].value;
      acquire += feat + ',';
      
      if (feat.match(/足さばき/)){
        if(level < 9){ cL.add("error"); }
      }
      else if (feat.match(/ガーディアン/)){
        if(level < 5 || !acquire.match('かばう')){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 9) { (auto) ? box.value = "ガーディアンⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 9) { (auto) ? box.value = "ガーディアンⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/回避行動/)){
        if(level < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Fen'] >= 9) { (auto) ? box.value = "回避行動Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Fen'] < 9) { (auto) ? box.value = "回避行動Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/^頑強/)){
        if(lv['Fig'] < 5 && lv['Gra'] < 5 && lv['Fen'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/キャパシティ/)){
        if(level < 11){ cL.add("error"); }
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
          if     (f3 && lv['Bar'] >= 13) { (auto) ? box.value = "呪歌追加Ⅲ" : cL.add("evo") }
          else if(f2 && lv['Bar'] >=  7) { (auto) ? box.value = "呪歌追加Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Bar'] >= 13) { (auto) ? box.value = "呪歌追加Ⅲ" : cL.add("evo") }
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
      else if (feat.match(/鷹の目/)){
        if(!acquire.match('ターゲッティング')){ cL.add("error"); }
      }
      else if (feat.match(/スローイング/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 5) { (auto) ? box.value = "スローイングⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 5) { (auto) ? box.value = "スローイングⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/超頑強/)){
        if((lv['Fig'] < 7 && lv['Gra'] < 7)|| !acquire.match('頑強')){ cL.add("error"); }
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
          if (f2 && lv['Gra'] >= 9) { (auto) ? box.value = "投げ強化Ⅱ" : cL.add("evo") }
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
          if (f2 && lv['Alc'] >= 9) { (auto) ? box.value = "賦術強化Ⅱ" : cL.add("evo") }
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
        if(lv['Gra'] < 5 && lv['Fen'] < 5){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Gra'] >= 13 || lv['Fen'] >= 13)) { (auto) ? box.value = "変幻自在Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Gra'] < 13 && lv['Fen'] < 13)) { (auto) ? box.value = "変幻自在Ⅰ" : cL.add("error") }
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
          if (f2 && level >= 11 && levelCasters[1] >= 10) { (auto) ? box.value = "魔力強化Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 11 || levelCasters[1] < 10) { (auto) ? box.value = "魔力強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/命中強化/)){
        if(level < 7){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 13) { (auto) ? box.value = "命中強化Ⅱ" : cL.add("evo") }
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
          if (f2 && lv['Gra'] >= 9) { (auto) ? box.value = "インファイトⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Gra'] < 9) { (auto) ? box.value = "インファイトⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/囮攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 9) { (auto) ? box.value = "囮攻撃Ⅱ" : cL.add("evo") }
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
          if (f2 && level >= 7) { (auto) ? box.value = "かばうⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 7) { (auto) ? box.value = "かばうⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/影矢/)){
        if(lv['Sho'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/牙折り/)){
        if(lv['Gra'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/斬り返し/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fig'] >= 7 || lv['Fen'] >= 7)) { (auto) ? box.value = "斬り返しⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fig'] < 7 && lv['Fen'] < 7)) { (auto) ? box.value = "斬り返しⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/クリティカルキャスト/)){
        if(level < 7){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 11) { (auto) ? box.value = "クリティカルキャストⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 11) { (auto) ? box.value = "クリティカルキャストⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/牽制攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && level >= 11) { (auto) ? box.value = "牽制攻撃Ⅲ" : cL.add("evo") }
          else if(f2 && level >=  7) { (auto) ? box.value = "牽制攻撃Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && level >= 11) { (auto) ? box.value = "牽制攻撃Ⅲ" : cL.add("evo") }
          else if(!f2 || level <  7) { (auto) ? box.value = "牽制攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level <  7) { (auto) ? box.value = "牽制攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || level < 11) { (auto) ? box.value = "牽制攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/シェアパフォーマー/)){
        if(lv['Bar'] < 3){ cL.add("error"); }
      }
      else if (feat.match(/スキルフルプレイ/)){
        if(lv['Bar'] < 7){ cL.add("error"); }
      }
      else if (feat.match(/全力攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lv['Fig'] >= 15)               { (auto) ? box.value = "全力攻撃Ⅲ" : cL.add("evo") }
          else if(f2 && (lv['Fig'] >= 9 || lv['Gra'] >= 9)){ (auto) ? box.value = "全力攻撃Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Fig'] >= 15)               { (auto) ? box.value = "全力攻撃Ⅲ" : cL.add("evo") }
          else if(!f2 || (lv['Fig'] < 9 && lv['Gra'] < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || (lv['Fig'] < 9 && lv['Gra'] < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || lv['Fig'] < 15)               { (auto) ? box.value = "全力攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/ダブルキャスト/)){
        if(levelCasters[0] < 9){ cL.add("error"); }
      }
      else if (feat.match(/挑発攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Fen'] >= 7) { (auto) ? box.value = "挑発攻撃Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 ||  lv['Fen'] < 7) { (auto) ? box.value = "挑発攻撃Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/テイルスイング/)){
        if(level < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 9) { (auto) ? box.value = "テイルスイングⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 9) { (auto) ? box.value = "テイルスイングⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/薙ぎ払い/)){
        if(level < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Fig'] >= 9) { (auto) ? box.value = "薙ぎ払いⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Fig'] < 9) { (auto) ? box.value = "薙ぎ払いⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/バイオレントキャスト/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 13) { (auto) ? box.value = "バイオレントキャストⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 13) { (auto) ? box.value = "バイオレントキャストⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/必殺攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lv['Fen'] >= 11) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("evo") }
          else if(f2 && level >=  7) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Fen'] >= 11) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("evo") }
          else if(!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || lv['Fen'] < 11) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/マルチアクション/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/鎧貫き/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lv['Gra'] >= 15) { (auto) ? box.value = "鎧貫きⅢ" : cL.add("evo") }
          else if(f2 && lv['Gra'] >=  9) { (auto) ? box.value = "鎧貫きⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Gra'] >= 15) { (auto) ? box.value = "鎧貫きⅢ" : cL.add("evo") }
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
      feat = box.options[box.selectedIndex].value;
      
      if     (feat === "足さばき"){ footwork = 1; }
      else if(feat === "回避行動Ⅰ"){ evasiveManeuver = 1; }
      else if(feat === "回避行動Ⅱ"){ evasiveManeuver = 2; }
      else if(feat === "命中強化Ⅰ"){ accuracyEnhance = 1; }
      else if(feat === "命中強化Ⅱ"){ accuracyEnhance = 2; }
      else if(feat === "魔力強化Ⅰ"){ magicPowerEnhance = 1; }
      else if(feat === "魔力強化Ⅱ"){ magicPowerEnhance = 2; }
      else if(feat === "賦術強化Ⅰ"){ alchemyEnhance = 1; }
      else if(feat === "賦術強化Ⅱ"){ alchemyEnhance = 2; }
      else if(feat === "頑強"){ tenacity += 15; }
      else if(feat === "超頑強"){ tenacity += 15; }
      else if(feat === "キャパシティ"){ capacity += 15; }
      else if(feat === "射手の体術"){ shootersMartialArts = 1; }
      else if(feat === "武器習熟Ａ／ソード"){ masterySword += 1; }
      else if(feat === "武器習熟Ａ／アックス"){ masteryAxe += 1; }
      else if(feat === "武器習熟Ａ／スピア"){ masterySpear += 1; }
      else if(feat === "武器習熟Ａ／メイス"){ masteryMace += 1; }
      else if(feat === "武器習熟Ａ／スタッフ"){ masteryStaff += 1; }
      else if(feat === "武器習熟Ａ／フレイル"){ masteryFlail += 1; }
      else if(feat === "武器習熟Ａ／ウォーハンマー"){ masteryHammer += 1; }
      else if(feat === "武器習熟Ａ／絡み"){ masteryEntangle += 1; }
      else if(feat === "武器習熟Ａ／格闘"){ masteryGrapple += 1; }
      else if(feat === "武器習熟Ａ／投擲"){ masteryThrow += 1; }
      else if(feat === "武器習熟Ａ／ボウ"){ masteryBow += 1; }
      else if(feat === "武器習熟Ａ／クロスボウ"){ masteryCrossbow += 1; }
      else if(feat === "武器習熟Ａ／ブロウガン"){ masteryBlowgun += 1; }
      else if(feat === "武器習熟Ａ／ガン"){ masteryGun += 1; }
      else if(feat === "武器習熟Ｓ／ソード"){ masterySword += 2; }
      else if(feat === "武器習熟Ｓ／アックス"){ masteryAxe += 2; }
      else if(feat === "武器習熟Ｓ／スピア"){ masterySpear += 2; }
      else if(feat === "武器習熟Ｓ／メイス"){ masteryMace += 2; }
      else if(feat === "武器習熟Ｓ／スタッフ"){ masteryStaff += 2; }
      else if(feat === "武器習熟Ｓ／フレイル"){ masteryFlail += 2; }
      else if(feat === "武器習熟Ｓ／ウォーハンマー"){ masteryHammer += 2; }
      else if(feat === "武器習熟Ｓ／絡み"){ masteryEntangle += 2; }
      else if(feat === "武器習熟Ｓ／格闘"){ masteryGrapple += 2; }
      else if(feat === "武器習熟Ｓ／投擲"){ masteryThrow += 2; }
      else if(feat === "武器習熟Ｓ／ボウ"){ masteryBow += 2; }
      else if(feat === "武器習熟Ｓ／クロスボウ"){ masteryCrossbow += 2; }
      else if(feat === "武器習熟Ｓ／ブロウガン"){ masteryBlowgun += 2; }
      else if(feat === "武器習熟Ｓ／ガン"){ masteryGun += 2; }
      else if(feat === "防具習熟Ａ／金属鎧"){ masteryMetalArmour += 1; }
      else if(feat === "防具習熟Ａ／非金属鎧"){ masteryNonMetalArmour += 1; }
      else if(feat === "防具習熟Ａ／盾"){ masteryShield += 1; }
      else if(feat === "防具習熟Ｓ／金属鎧"){ masteryMetalArmour += 2; }
      else if(feat === "防具習熟Ｓ／非金属鎧"){ masteryNonMetalArmour += 2; }
      else if(feat === "防具習熟Ｓ／盾"){ masteryShield += 2; }
      else if(feat === "魔器習熟Ａ"){ masteryArtisan += 1; }
      else if(feat === "魔器習熟Ｓ"){ masteryArtisan += 1; }
      else if(feat === "魔器の達人"){ masteryArtisan += 1; }
      else if(feat === "スローイングⅠ"){ throwing = 1; }
      else if(feat === "スローイングⅡ"){ throwing = 2; }
      else if(feat === "呪歌追加Ⅰ"){ songAddition = 1; }
      else if(feat === "呪歌追加Ⅱ"){ songAddition = 2; }
      else if(feat === "呪歌追加Ⅲ"){ songAddition = 3; }
      
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
    if (classes[key]['craftData']){
      const eName = classes[key]['craft'];
      document.getElementById("craft-"+eName).style.display = lv[key] ? "block" : "none";
      const cMax = (key === 'Bar') ? 20 : 17;
      for (let i = 1; i <= cMax; i++) {
        let cL = document.getElementById("craft-"+eName+i).classList;
        if ( (i <= lv[key])
          || (i <= lv[key]+songAddition && key === 'Bar')
        ){
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
  const vitResistBase = level + bonusVit;
  const mndResistBase = level + bonusMnd;
  const vitResistAutoAdd = 0;
  const mndResistAutoAdd = raceAbilityMndResist;
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
  const hpAutoAdd = tenacity + hpAccessory + (lv['Fig'] >= 7 ? 15 : 0);
  const mpAutoAdd = capacity + raceAbilityMp + mpAccessory;
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
  const mobilityBase = ((race === 'ケンタウロス') ? (agi * 2) : agi) + (form["armourOwn"].checked ? 2 : 0);
  const mobility = mobilityBase + Number(form.mobilityAdd.value);
  document.getElementById("mobility-limited").innerHTML = footwork ? 10 : 3;
  document.getElementById("mobility-base").innerHTML = mobilityBase;
  document.getElementById("mobility-total").innerHTML = mobility;
  document.getElementById("mobility-full").innerHTML = mobility * 3;
}

// パッケージ計算 ----------------------------------------
function calcPackage() {
  document.getElementById("package-scout"    ).style.display = lv['Sco'] > 0 ? "" :"none";
  document.getElementById("package-ranger"   ).style.display = lv['Ran'] > 0 ? "" :"none";
  document.getElementById("package-sage"     ).style.display = lv['Sag'] > 0 ? "" :"none";
  document.getElementById("package-rider"    ).style.display = lv['Rid'] > 0 ? "" :"none";
  document.getElementById("package-alchemist").style.display = lv['Alc'] > 0 ? "" :"none";
  document.getElementById("material-cards"   ).style.display = lv['Alc'] > 0 ? "" :"none";
  
  document.getElementById("package-scout-tec"    ).innerHTML = lv['Sco'] + bonusDex + Number(form.packScoTecAdd.value);
  document.getElementById("package-scout-agi"    ).innerHTML = lv['Sco'] + bonusAgi + Number(form.packScoAgiAdd.value);
  document.getElementById("package-scout-obs"    ).innerHTML = lv['Sco'] + bonusInt + Number(form.packScoObsAdd.value);
  document.getElementById("package-ranger-tec"   ).innerHTML = lv['Ran'] + bonusDex + Number(form.packRanTecAdd.value);
  document.getElementById("package-ranger-agi"   ).innerHTML = lv['Ran'] + bonusAgi + Number(form.packRanAgiAdd.value);
  document.getElementById("package-ranger-obs"   ).innerHTML = lv['Ran'] + bonusInt + Number(form.packRanObsAdd.value);
  document.getElementById("package-sage-kno"     ).innerHTML = lv['Sag'] + bonusInt + Number(form.packSagKnoAdd.value);
  document.getElementById("package-rider-agi"    ).innerHTML = lv['Rid'] + bonusAgi + Number(form.packRidAgiAdd.value);
  document.getElementById("package-rider-kno"    ).innerHTML = lv['Rid'] + bonusInt + Number(form.packRidKnoAdd.value);
  document.getElementById("package-rider-obs"    ).innerHTML = lv['Rid'] + bonusInt + Number(form.packRidObsAdd.value);
  document.getElementById("package-alchemist-kno").innerHTML = lv['Alc'] + bonusInt + Number(form.packAlcKnoAdd.value);
  
  const loreSag = lv['Sag'] + bonusInt + Number(form.packSagKnoAdd.value);
  const loreRid = lv['Rid'] + bonusInt + Number(form.packRidKnoAdd.value);
  let lore = loreRid > loreSag ? loreRid : loreSag;
      lore += Number(form.monsterLoreAdd.value);
  document.getElementById("monster-lore-value").innerHTML = (lv['Sag'] || lv['Rid']) ? lore : 0;
  
  const initSco = lv['Sco'] + bonusAgi + Number(form.packScoAgiAdd.value);
  const initWar = lv['War'] + bonusAgi;
  let init = initWar > initSco ? initWar : initSco;
      init += Number(form.initiativeAdd.value);
  document.getElementById("initiative-value").innerHTML   = (lv['Sco'] || lv['War'])  > 0 ? init : 0;
}

// 魔力計算 ----------------------------------------
function calcMagic() {
  const addPower = Number(form.magicPowerAdd.value) + magicPowerEnhance;
  document.getElementById("magic-power-magicenhance-value").innerHTML = magicPowerEnhance;
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
      
      const power = lv[key] + parseInt((sttInt + sttAddE + (form["magicPowerOwn"+key].checked ? 2 : 0)) / 6) + Number(form["magicPowerAdd"+key].value) + addPower;
      document.getElementById("magic-power-"+eName+"-value").innerHTML  = power;
      document.getElementById("magic-cast-"+eName+"-value").innerHTML   = power + Number(form["magicCastAdd"+key].value) + addCast;
      document.getElementById("magic-damage-"+eName+"-value").innerHTML = Number(form["magicDamageAdd"+key].value) + addDamage;
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
      
      if(key === 'Alc'){ power += alchemyEnhance }
      document.getElementById("magic-cast-"+eName+"-value").innerHTML   = power + Number(form["magicCastAdd"+key].value);
    }
  });
  // 全体／その他の開閉
  document.getElementById("magic-power").style.display = (openMagic || openCraft) ? '' : 'none';
  
  document.getElementById("magic-power-magicenhance").style.display = magicPowerEnhance      ? '' : 'none';
  document.getElementById("magic-power-common"      ).style.display = openMagic              ? '' : 'none';
  document.getElementById("magic-power-hr"          ).style.display = openMagic && openCraft ? '' : 'none';
}

// 攻撃計算 ----------------------------------------
function calcAttack() {
  document.getElementById("attack-fighter"   ).style.display = lv['Fig'] >   0 ? "" :"none";
  document.getElementById("attack-grappler"  ).style.display = lv['Gra'] >   0 ? "" :"none";
  document.getElementById("attack-fencer"    ).style.display = lv['Fen'] >   0 ? "" :"none";
  document.getElementById("attack-shooter"   ).style.display = lv['Sho'] >   0 ? "" :"none";
  document.getElementById("attack-enhancer"  ).style.display = lv['Enh'] >= 10 ? "" :"none";
  document.getElementById("attack-demonruler").style.display = lv['Dem'] >   0 ? "" :"none";

  document.getElementById("attack-fighter-str"   ).innerHTML = reqdStr;
  document.getElementById("attack-grappler-str"  ).innerHTML = reqdStr;
  document.getElementById("attack-fencer-str"    ).innerHTML = reqdStrHalf;
  document.getElementById("attack-shooter-str"   ).innerHTML = reqdStr;
  document.getElementById("attack-enhancer-str"  ).innerHTML = reqdStr;
  document.getElementById("attack-demonruler-str").innerHTML = reqdStr;

  document.getElementById("attack-fighter-acc"   ).innerHTML = lv['Fig'] + bonusDex;
  document.getElementById("attack-grappler-acc"  ).innerHTML = lv['Gra'] + bonusDex;
  document.getElementById("attack-fencer-acc"    ).innerHTML = lv['Fen'] + bonusDex;
  document.getElementById("attack-shooter-acc"   ).innerHTML = lv['Sho'] + bonusDex;
  document.getElementById("attack-enhancer-acc"  ).innerHTML = lv['Enh'] + bonusDex;
  document.getElementById("attack-demonruler-acc").innerHTML = lv['Dem'] + bonusDex;

  document.getElementById("attack-fighter-dmg"   ).innerHTML = lv['Fig'] + bonusStr;
  document.getElementById("attack-grappler-dmg"  ).innerHTML = lv['Gra'] + bonusStr;
  document.getElementById("attack-fencer-dmg"    ).innerHTML = lv['Fen'] + bonusStr;
  document.getElementById("attack-shooter-dmg"   ).innerHTML = lv['Sho'] + bonusStr;
  document.getElementById("attack-enhancer-dmg"  ).innerHTML = lv['Enh'] + bonusStr;
  document.getElementById("attack-demonruler-dmg").innerHTML = lv['Dem'] + bonusStr;

  calcWeapon();
}
function calcWeapon() {
  const weaponNum = form.weaponNum.value;
  for (let i = 1; i <= weaponNum; i++){
    const classes = form["weapon"+i+"Class"].value;
    const category = form["weapon"+i+"Category"].value;
    const ownDex = form["weapon"+i+"Own"].checked ? 2 : 0;
    const note = form["weapon"+i+"Note"].value;
    const weaponReqd = Number(safeEval(form["weapon"+i+"Reqd"].value));
    let attackClass;
    let accBase = 0;
    let dmgBase = 0;
    let maxReqd = reqdStr;
    accBase += accuracyEnhance; //命中強化
    // 使用技能
         if(classes === "ファイター")       { attackClass = lv['Fig']; }
    else if(classes === "グラップラー")     { attackClass = lv['Gra']; }
    else if(classes === "フェンサー")       { attackClass = lv['Fen']; maxReqd = reqdStrHalf; }
    else if(classes === "シューター")       { attackClass = lv['Sho']; }
    else if(classes === "エンハンサー")     { attackClass = lv['Enh']; }
    else if(classes === "デーモンルーラー") { attackClass = lv['Dem']; }
    // 必筋チェック
    form["weapon"+i+"Reqd"].classList.toggle('error', weaponReqd > maxReqd);
    // 武器カテゴリ
    if(attackClass) {
      accBase += attackClass + parseInt((sttDex + sttAddA + ownDex) / 6);
      if     (category === 'クロスボウ') { dmgBase += attackClass; }
      else if(category === 'ガン')       { dmgBase += 0; }
      else { dmgBase += attackClass + bonusStr; }
    }
    if     (category === 'ソード')         { dmgBase += masterySword; }
    else if(category === 'アックス')       { dmgBase += masteryAxe; }
    else if(category === 'スピア')         { dmgBase += masterySpear; }
    else if(category === 'メイス')         { dmgBase += masteryMace; }
    else if(category === 'スタッフ')       { dmgBase += masteryStaff; }
    else if(category === 'フレイル')       { dmgBase += masteryFlail; }
    else if(category === 'ウォーハンマー') { dmgBase += masteryHammer; }
    else if(category === '絡み')           { dmgBase += masteryEntangle; }
    else if(category === '格闘')           { dmgBase += masteryGrapple; }
    else if(category === '投擲')           { dmgBase += masteryThrow; accBase += throwing ? 1 : 0; }
    else if(category === 'ボウ')           { dmgBase += masteryBow; }
    else if(category === 'ブロウガン')     { dmgBase += masteryBlowgun; }
    else if(category === 'クロスボウ')     { dmgBase += masteryCrossbow; }
    else if(category === 'ガン') {
      const magicPower = lv['Mag'] ? Number(document.getElementById('magic-power-magitech-value').innerHTML) : 0;
      dmgBase = magicPower + masteryGun;
    }
    else if(category === 'ガン（物理）')   { dmgBase += masteryGun; }
    if(note.match(/〈魔器〉/)){ dmgBase += masteryArtisan; }
    // 命中追加D出力
    if(classes === "自動計算しない"){
      document.getElementById("weapon"+i+"-acc-total").innerHTML = Number(form["weapon"+i+"Acc"].value);
      document.getElementById("weapon"+i+"-dmg-total").innerHTML = Number(form["weapon"+i+"Dmg"].value);
    }
    else {
      document.getElementById("weapon"+i+"-acc-total").innerHTML = accBase + Number(form["weapon"+i+"Acc"].value);
      document.getElementById("weapon"+i+"-dmg-total").innerHTML = dmgBase + Number(form["weapon"+i+"Dmg"].value);
    }
  }
  document.getElementById("attack-sword-mastery").style.display    = masterySword     ? '' : 'none';   document.getElementById("attack-sword-mastery-dmg").innerHTML    = masterySword   ;
  document.getElementById("attack-axe-mastery").style.display      = masteryAxe       ? '' : 'none';   document.getElementById("attack-axe-mastery-dmg").innerHTML      = masteryAxe     ;
  document.getElementById("attack-spear-mastery").style.display    = masterySpear     ? '' : 'none';   document.getElementById("attack-spear-mastery-dmg").innerHTML    = masterySpear   ;
  document.getElementById("attack-mace-mastery").style.display     = masteryMace      ? '' : 'none';   document.getElementById("attack-mace-mastery-dmg").innerHTML     = masteryMace    ;
  document.getElementById("attack-staff-mastery").style.display    = masteryStaff     ? '' : 'none';   document.getElementById("attack-staff-mastery-dmg").innerHTML    = masteryStaff   ;
  document.getElementById("attack-flail-mastery").style.display    = masteryFlail     ? '' : 'none';   document.getElementById("attack-flail-mastery-dmg").innerHTML    = masteryFlail   ;
  document.getElementById("attack-hammer-mastery").style.display   = masteryHammer    ? '' : 'none';   document.getElementById("attack-hammer-mastery-dmg").innerHTML   = masteryHammer  ;
  document.getElementById("attack-entangle-mastery").style.display = masteryEntangle  ? '' : 'none';   document.getElementById("attack-entangle-mastery-dmg").innerHTML = masteryEntangle;
  document.getElementById("attack-grapple-mastery").style.display  = masteryGrapple   ? '' : 'none';   document.getElementById("attack-grapple-mastery-dmg").innerHTML  = masteryGrapple ;
  document.getElementById("attack-throw-mastery").style.display    = masteryThrow     ? '' : 'none';   document.getElementById("attack-throw-mastery-dmg").innerHTML    = masteryThrow   ;
  document.getElementById("attack-bow-mastery").style.display      = masteryBow       ? '' : 'none';   document.getElementById("attack-bow-mastery-dmg").innerHTML      = masteryBow     ;
  document.getElementById("attack-crossbow-mastery").style.display = masteryCrossbow  ? '' : 'none';   document.getElementById("attack-crossbow-mastery-dmg").innerHTML = masteryCrossbow;
  document.getElementById("attack-blowgun-mastery").style.display  = masteryBlowgun   ? '' : 'none';   document.getElementById("attack-blowgun-mastery-dmg").innerHTML  = masteryBlowgun ;
  document.getElementById("attack-gun-mastery").style.display      = masteryGun       ? '' : 'none';   document.getElementById("attack-gun-mastery-dmg").innerHTML      = masteryGun     ;
  document.getElementById("attack-artisan-mastery").style.display  = masteryArtisan   ? '' : 'none';   document.getElementById("attack-artisan-mastery-dmg").innerHTML  = masteryArtisan ;
  document.getElementById("accuracy-enhance").style.display        = accuracyEnhance  ? '' : 'none';   document.getElementById("accuracy-enhance-acc").innerHTML        = accuracyEnhance;
  document.getElementById("throwing").style.display                = throwing         ? '' : 'none';
  
  document.getElementById("artisan-annotate").style.display = masteryArtisan ? '' : 'none'; 
}

// 防御計算 ----------------------------------------
function calcDefense() {
  const classes = form.evasionClass.options[form.evasionClass.selectedIndex].value;
  const ownAgi = form["shieldOwn"].checked ? 2 : 0;
  let evaClassLv = 0;
  let evaBase = 0;
  let defBase = 0;
       if(classes === "ファイター")      { evaClassLv = lv['Fig']; }
  else if(classes === "グラップラー")    { evaClassLv = lv['Gra']; }
  else if(classes === "フェンサー")      { evaClassLv = lv['Fen']; }
  else if(classes === "シューター")      { evaClassLv = lv['Sho']; }
  else if(classes === "デーモンルーラー"){ evaClassLv = lv['Dem']; }
  else { evaClassLv = 0; }
  evaBase = evaClassLv ? (evaClassLv + parseInt((sttAgi + sttAddB + ownAgi) / 6)) : 0;
  
  const maxReqd = (classes === "フェンサー") ? reqdStrHalf : reqdStr;
  document.getElementById("evasion-str").innerHTML = maxReqd;
  document.getElementById("evasion-eva").innerHTML = evaClassLv ? (evaClassLv + bonusAgi) : 0;
  
  // 技能選択のエラー表示
  let cL = document.getElementById("evasion-classes").classList;
  if(classes === "シューター" && !shootersMartialArts || classes === "デーモンルーラー" && lv['Dem'] < 2){ 
    cL.add('error');
  }
  else { cL.remove('error'); }
  
  // 種族特徴
  defBase += raceAbilityDef;
  document.getElementById("race-ability-def").style.display = raceAbilityDef > 0 ? "" :"none";
  document.getElementById("race-ability-def-value").innerHTML  = raceAbilityDef;
  // 習熟
  document.getElementById("mastery-metalarmour").style.display    = masteryMetalArmour    > 0 ? "" :"none";
  document.getElementById("mastery-nonmetalarmour").style.display = masteryNonMetalArmour > 0 ? "" :"none";
  document.getElementById("mastery-shield").style.display         = masteryShield         > 0 ? "" :"none";
  document.getElementById("mastery-artisan-def").style.display    = masteryArtisan        > 0 ? "" :"none";
  document.getElementById("mastery-metalarmour-value").innerHTML    = masteryMetalArmour;
  document.getElementById("mastery-nonmetalarmour-value").innerHTML = masteryNonMetalArmour;
  document.getElementById("mastery-shield-value").innerHTML         = masteryShield;
  document.getElementById("mastery-artisan-def-value").innerHTML    = masteryArtisan;
  // 回避行動
  evaBase += evasiveManeuver;
  document.getElementById("evasive-maneuver").style.display = evasiveManeuver > 0 ? "" :"none";
  document.getElementById("evasive-maneuver-value").innerHTML = evasiveManeuver;
  
  calcArmour(evaBase,defBase,maxReqd);
}
function calcArmour(evaBase,defBase,maxReqd) {
  const armourEva   = Number(form.armourEva.value);
  const armourDef   = Number(form.armourDef.value) + Math.max(masteryMetalArmour,masteryNonMetalArmour);
  const shieldEva   = Number(form.shieldEva.value);
  const shieldDef   = Number(form.shieldDef.value) + masteryShield;
  const otherEva    = Number(form.defOtherEva.value);
  const otherDef    = Number(form.defOtherDef.value);
  
  if(form.armourNote.value.match(/〈魔器〉/) || form.shieldNote.value.match(/〈魔器〉/)){ defBase += masteryArtisan; }
  
  document.getElementById("defense-total-all-eva").innerHTML = evaBase + armourEva + shieldEva + otherEva;
  document.getElementById("defense-total-all-def").innerHTML = defBase + armourDef + shieldDef + otherDef;
  
  const armourReqd = Number(safeEval(form.armourReqd.value));
  const shieldReqd = Number(safeEval(form.shieldReqd.value));
  const otherReqd  = Number(safeEval(form.defOtherReqd.value));
  form.armourReqd.classList.toggle('error', armourReqd > maxReqd);
  form.shieldReqd.classList.toggle('error', shieldReqd > maxReqd);
  form.defOtherReqd.classList.toggle('error', otherReqd > maxReqd);
}

// 経験点計算 ----------------------------------------
function calcExp(){
  expTotal = 0;
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    let exp = Number(safeEval(form['history'+i+'Exp'].value));
    if(isNaN(exp)){ exp = 0; }
    expTotal += exp;
    form['history'+i+'Exp'].style.textDecoration = !exp ? 'underline red' : 'none';
  }
  document.getElementById("exp-rest").innerHTML = expTotal - expUse;
  document.getElementById("exp-total").innerHTML = expTotal;
  
  // 最大成長回数
  if(growType === 'A'){
    let count = 0;
    let exp = 3000;
    for(let i = 0; exp <= expTotal; i++){
      count = i;
      const next = 1000 + i * 10;
      exp += next;
    }
    document.getElementById("stt-grow-max-value").innerHTML = ' / ' + count;
  }
  else if(growType === 'O') {
    document.getElementById("stt-grow-max-value").innerHTML = ' / ' + Math.floor((expTotal - 3000) / 1000);
  }
}


// 名誉点計算 ----------------------------------------
function calcHonor(){
  let pointTotal = 0;
  let mysticArtsPt = 0;
  const rank = form["rank"].options[form["rank"].selectedIndex].value;
  const rankNum = (adventurerRank[rank]["num"] === undefined) ? 0 : adventurerRank[rank]["num"];
  const free = (adventurerRank[rank]["free"] === undefined) ? 0 : adventurerRank[rank]["free"];
  const historyNum = form.historyNum.value;
  pointTotal -= rankNum;
  for (let i = 0; i <= historyNum; i++){
    let point = Number(safeEval(form['history'+i+'Honor'].value));
    if(isNaN(point)){ point = 0; }
    pointTotal += point;
    form['history'+i+'Honor'].style.textDecoration = !point ? 'underline red' : 'none';
  }
  const honorItemsNum = form.honorItemsNum.value;
  for (let i = 1; i <= honorItemsNum; i++){
    let point = Number(safeEval(form['honorItem'+i+'Pt'].value));
    if(isNaN(point)){ point = 0; }
    pointTotal -= point;
    
    let cL = form['honorItem'+i+'Pt'].classList;
    if(point && point <= free) { cL.add("free"); }
    else { cL.remove("free"); }
  }
  const mysticArtsNum = form.mysticArtsNum.value;
  for (let i = 1; i <= mysticArtsNum; i++){
    let point = Number(safeEval(form['mysticArts'+i+'Pt'].value));
    if(isNaN(point)){ point = 0; }
    mysticArtsPt += point;
  }
  pointTotal -= mysticArtsPt;
  document.getElementById("honor-value"   ).innerHTML = pointTotal;
  document.getElementById("honor-value-MA").innerHTML = pointTotal;
  document.getElementById("rank-honor-value").innerHTML = rankNum;
  document.getElementById("mystic-arts-honor-value").innerHTML = mysticArtsPt;
}
function calcDishonor(){
  let pointTotal = 0;
  const dishonorItemsNum = form.dishonorItemsNum.value;
  for (let i = 1; i <= dishonorItemsNum; i++){
    let point = Number(safeEval(form['dishonorItem'+i+'Pt'].value));
    if(isNaN(point)){ point = 0; }
    pointTotal += point;
  }
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
    let hCash = Number(safeEval(form['history'+i+'Money'].value))
    if(isNaN(hCash)){ hCash = 0; }
    cash += hCash;
    form['history'+i+'Money'].style.textDecoration = !hCash ? 'underline red' : 'none';
  }
  let s = form.cashbook.value;
  s.replace(
    /::([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      cash += Number(safeEval(num.slice(2)));
    }
  );
  s.replace(
    /:>([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      deposit += Number(safeEval(num.slice(2)));
    }
  );
  s.replace(
    /:<([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      debt += Number(safeEval(num.slice(2)));
    }
  );
  cash = cash - deposit + debt;
  document.getElementById('cashbook-total-value').innerHTML = cash;
  document.getElementById('cashbook-deposit-value').innerHTML = deposit;
  document.getElementById('cashbook-debt-value').innerHTML = debt;
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

// 言語欄 ----------------------------------------
// 追加
function addLanguage(){
  let num = Number(form.languageNum.value) + 1;
  let tbody = document.createElement('tr');
  tbody.setAttribute('id',idNumSet('language-item'));
  tbody.innerHTML = `
    <td class="handle"></td>
    <td><input name="language${num}" type="text"></td>
    <td><input name="language${num}Talk" type="checkbox" value="1"></td>
    <td><input name="language${num}Read" type="checkbox" value="1"></td>
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
function addWeapons(){
  let num = Number(form.weaponNum.value) + 1;
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id',idNumSet('weapon-row'));
  tbody.innerHTML = `<tr>
    <td rowspan="2"><input name="weapon${num}Name"  type="text"><span class="handle"></span></td>
    <td rowspan="2"><input name="weapon${num}Usage" type="text"></td>
    <td rowspan="2"><input name="weapon${num}Reqd"  type="text"></td>
    <td rowspan="2">+<input name="weapon${num}Acc" type="number" oninput="calcWeapon()"><b id="weapon${num}-acc-total">0</b></td>
    <td rowspan="2"><input name="weapon${num}Rate" type="text"></td>
    <td rowspan="2"><input name="weapon${num}Crit" type="text"></td>
    <td rowspan="2">+<input name="weapon${num}Dmg" type="number" oninput="calcWeapon()"><b id="weapon${num}-dmg-total">0</b></td>
    <td><input name="weapon${num}Own" type="checkbox" oninput="calcWeapon()"></td>
    <td><select name="weapon${num}Category" oninput="calcWeapon()"><option></select></td>
    <td><select name="weapon${num}Class" oninput="calcWeapon()"><option><option>ファイター<option>グラップラー<option>フェンサー<option>シューター<option>エンハンサー<option>デーモンルーラー<option>自動計算しない</select></td>
  </tr>
  <tr><td colspan="3"><input name="weapon${num}Note" type="text" oninput="calcWeapon()"></td></tr>`;
  const target = document.querySelector("#weapons-table");
  target.appendChild(tbody, target);
  
  for(let i = 0; i < weapons.length; i++){
    let op = document.createElement("option");
    op.text = weapons[i];
    form["weapon"+num+"Category"].appendChild(op);
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
  const target = document.querySelector("#honor-items-table tbody");
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
    const target = document.querySelector("#honor-items-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.honorItemsNum.value = num;
  }
}
// ソート
let honorSortable = Sortable.create(document.querySelector('#honor-items-table tbody'), {
  group: "honor",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot',
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
    <td><input name="history${num}Honor"  type="text" oninput="calcHonor()"></td>
    <td><input name="history${num}Money"  type="text" oninput="calcCash()"></td>
    <td><input name="history${num}Grow"   type="text" list="list-grow"></td>
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
function point1(dice){
  const type = form.pointbuyType.options[form.pointbuyType.selectedIndex].value;
  let point;
  if(type === '2.0'){
         if(dice == 1){ point = -15; }
    else if(dice == 2){ point = -10; }
    else if(dice == 3){ point = -5; }
    else if(dice == 4){ point = 0; }
    else if(dice == 5){ point = 10; }
    else if(dice == 6){ point = 20; }
  } else {
         if(dice == 1){ point = -15; }
    else if(dice == 2){ point = -10; }
    else if(dice == 3){ point = -5; }
    else if(dice == 4){ point = 5; }
    else if(dice == 5){ point = 10; }
    else if(dice == 6){ point = 20; }
  }
  return(point);
}
function point2(dice){
  const type = form.pointbuyType.options[form.pointbuyType.selectedIndex].value;
  let point;
  if(type === '2.0'){
         if(dice == 2){ point = -30; }
    else if(dice == 3){ point = -25; }
    else if(dice == 4){ point = -20; }
    else if(dice == 5){ point = -15; }
    else if(dice == 6){ point = -10; }
    else if(dice == 7){ point = -5; }
    else if(dice == 8){ point = 0; }
    else if(dice == 9){ point = 10; }
    else if(dice == 10){ point = 20; }
    else if(dice == 11){ point = 40; }
    else if(dice == 12){ point = 70; }
  } else {
         if(dice == 2){ point = -25; }
    else if(dice == 3){ point = -20; }
    else if(dice == 4){ point = -15; }
    else if(dice == 5){ point = -10; }
    else if(dice == 6){ point = -5; }
    else if(dice == 7){ point = 0; }
    else if(dice == 8){ point = 5; }
    else if(dice == 9){ point = 10; }
    else if(dice == 10){ point = 20; }
    else if(dice == 11){ point = 40; }
    else if(dice == 12){ point = 70; }
  }
  return(point);
}
function pointx(dice){
  const type = form.pointbuyType.options[form.pointbuyType.selectedIndex].value;
  let point;
  if(type === '2.0'){
       if(dice == 2) { point = -100; }
  else if(dice == 3) { point =  -80; }
  else if(dice == 4) { point =  -60; }
  else if(dice == 5) { point =  -40; }
  else if(dice == 6) { point =  -20; }
  else if(dice == 7) { point =    0; }
  else if(dice == 8) { point =   20; }
  else if(dice == 9) { point =   40; }
  else if(dice == 10){ point =   60; }
  else if(dice == 11){ point =  100; }
  else if(dice == 12){ point =  160; }
  } else {
       if(dice == 2) { point = -100; }
  else if(dice == 3) { point =  -80; }
  else if(dice == 4) { point =  -60; }
  else if(dice == 5) { point =  -40; }
  else if(dice == 6) { point =  -20; }
  else if(dice == 7) { point =    0; }
  else if(dice == 8) { point =   20; }
  else if(dice == 9) { point =   40; }
  else if(dice == 10){ point =   70; }
  else if(dice == 11){ point =  110; }
  else if(dice == 12){ point =  160; }
  }
  return(point);
}

// チャットパレット ----------------------------------------
palettePresetChange();
function palettePresetChange (){
  const tool = form.paletteTool.value;
  document.getElementById('palettePreset').value = 
    form.paletteUseVar.checked ? (tool == 'bcdice' ? palettePresetText : palettePresetTextBcd)
                               : (tool == 'bcdice' ? palettePresetTextBcdRaw : palettePresetTextRaw);
}

// 画像配置 ----------------------------------------
function imagePreView(file){
  const blobUrl = window.URL.createObjectURL(file);
  document.getElementById('image').style.backgroundImage = 'url("'+blobUrl+'")';
  document.querySelectorAll(".image-custom-view").forEach((el) => {
    el.style.backgroundImage = 'url("'+blobUrl+'")';
  });
  console.log(blobUrl)
}
function imagePositionView(){
  document.getElementById('image-custom').style.display = 'grid';
}
function imagePositionClose(){
  document.getElementById('image-custom').style.display = 'none';
}
function imagePercentBarChange(per){
  form.imagePercent.value = per;
  imagePosition();
}
function imagePosition(){
  const bgSize = form.imageFit.options[form.imageFit.selectedIndex].value;
  if(bgSize === 'percentX'){
    document.getElementById("image-percent-config").style.visibility = 'visible';
    document.getElementById("image").style.backgroundSize = form.imagePercent.value + '%';
    document.querySelectorAll(".image-custom-view").forEach((el) => {
      el.style.backgroundSize = form.imagePercent.value + '%';
    });
  }
  else if(bgSize === 'percentY'){
    document.getElementById("image-percent-config").style.visibility = 'visible';
    document.getElementById("image").style.backgroundSize = 'auto ' + form.imagePercent.value + '%';
    document.querySelectorAll(".image-custom-view").forEach((el) => {
      el.style.backgroundSize = 'auto ' + form.imagePercent.value + '%';
    });
  }
  else {
    document.getElementById("image-percent-config").style.visibility = 'hidden';
    document.getElementById("image").style.backgroundSize = bgSize;
    document.querySelectorAll(".image-custom-view").forEach((el) => {
      el.style.backgroundSize = bgSize;
    });
  }
  document.getElementById("image-positionX-view").innerHTML = form.imagePositionX.value + '%';
  document.getElementById("image-positionY-view").innerHTML = form.imagePositionY.value + '%';
  document.getElementById("image").style.backgroundPositionX = form.imagePositionX.value + '%';
  document.getElementById("image").style.backgroundPositionY = form.imagePositionY.value + '%';
  document.querySelectorAll(".image-custom-view").forEach((el) => {
    el.style.backgroundPositionX = form.imagePositionX.value + '%';
    el.style.backgroundPositionY = form.imagePositionY.value + '%';
  });
  
  document.getElementById("image-percent-bar").value = form.imagePercent.value;
}

// 表示／非表示 ----------------------------------------
function view(viewId){
  let value = document.getElementById(viewId).style.display;
  document.getElementById(viewId).style.display = (value === 'none') ? '' : 'none';
}

// カラーカスタム ----------------------------------------
function changeColor(){
  const customOn = form.colorCustom.checked ? 1 : 0;
  let hH = Number(form.colorHeadBgH.value);
  let hS = Number(form.colorHeadBgS.value);
  let hL = Number(form.colorHeadBgL.value);
  //const hA = Number(form.colorHeadBgA.value);
  let bH = Number(form.colorBaseBgH.value);
  let bS = Number(form.colorBaseBgS.value);
  //let bL = Number(form.colorBaseBgL.value);
  //const bA = Number(form.colorBaseBgA.value);
  document.getElementById('colorHeadBgHValue').innerHTML = hH;
  document.getElementById('colorHeadBgSValue').innerHTML = hS;
  document.getElementById('colorHeadBgLValue').innerHTML = hL;
  //document.getElementById('colorHeadBgAValue').innerHTML = hA;
  document.getElementById('colorBaseBgHValue').innerHTML = bH;
  document.getElementById('colorBaseBgSValue').innerHTML = bS;
  //document.getElementById('colorBaseBgLValue').innerHTML = bL;
  //document.getElementById('colorBaseBgAValue').innerHTML = bA;
  
  const boxes = document.querySelectorAll('.box');
  document.documentElement.style.setProperty('--box-head-bg-color-h', customOn ? hH     : '');
  document.documentElement.style.setProperty('--box-head-bg-color-s', customOn ? hS+'%' : '');
  document.documentElement.style.setProperty('--box-head-bg-color-l', customOn ? hL+'%' : '');
  document.documentElement.style.setProperty('--box-base-bg-color-h', customOn ? bH     : '');
  document.documentElement.style.setProperty('--box-base-bg-color-s', customOn ? (bS*0.7)+'%' : '');
  document.documentElement.style.setProperty('--box-base-bg-color-l', customOn ? (100-bS/6)+'%' : '');
  document.documentElement.style.setProperty('--box-base-bg-color-d', customOn ? 15+'%' : '');
}

// セクション選択 ----------------------------------------
function sectionSelect(id){
  const sections = ['common','fellow','palette','color'];
  sections.forEach( (value) => {
    document.getElementById('section-'+value).style.display = 'none';
  });
  document.getElementById('section-'+id).style.display = 'block';
}

// 連番ID生成 ----------------------------------------
function idNumSet (id){
  let num = 1;
  while(document.getElementById(id+num)){
    num++;
  }
  return id+num;
}

// 安全なeval ----------------------------------------
function safeEval(text){
  if     (text === '') { return 0; }
  else if(text.match(/[^0-9\+\-\*\/\(\) ]/)){ return 0; }
  
  try { return Function('"use strict";return (' + text + ')')(); } 
  catch (e) { return 0; }
}


