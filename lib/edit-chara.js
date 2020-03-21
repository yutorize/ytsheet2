"use strict";
const form = document.sheet;

const expA = [
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
];

const expB = [
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
];

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
let lvFig = 0;
let lvGra = 0;
let lvFen = 0;
let lvSho = 0;
let lvSor = 0;
let lvCon = 0;
let lvPri = 0;
let lvFai = 0;
let lvMag = 0;
let lvSco = 0;
let lvRan = 0;
let lvSag = 0;
let lvEnh = 0;
let lvBar = 0;
let lvRid = 0;
let lvAlc = 0;
let lvWar = 0;
let lvMys = 0;
let lvDem = 0;
let lvPhy = 0;
let lvGri = 0;
let lvAri = 0;
let lvArt = 0;
let levelCasters;

window.onload = function() {
  checkRace();
  calcLv();
  calcExp();
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
  
  calcLv();
  calcExp();
  calcCash();
}

function changeFaith(Faith) {
  if(Faith.options[Faith.selectedIndex].value === 'その他の信仰'){
    form.faithOther.style.display = '';
  } else {
    form.faithOther.style.display = 'none';
  }
}

// レベル変更 //
function changeLv() {
  calcLv();
  
  checkRace();
  calcPackage();
  checkFeats();
}

// レベル計算 //
function calcLv(){
  lvFig = Number(form.lvFig.value);
  lvGra = Number(form.lvGra.value);
  lvFen = Number(form.lvFen.value);
  lvSho = Number(form.lvSho.value);
  lvSor = Number(form.lvSor.value);
  lvCon = Number(form.lvCon.value);
  lvPri = Number(form.lvPri.value);
  lvFai = Number(form.lvFai.value);
  lvMag = Number(form.lvMag.value);
  lvSco = Number(form.lvSco.value);
  lvRan = Number(form.lvRan.value);
  lvSag = Number(form.lvSag.value);
  lvEnh = Number(form.lvEnh.value);
  lvBar = Number(form.lvBar.value);
  lvRid = Number(form.lvRid.value);
  lvAlc = Number(form.lvAlc.value);
  lvWar = AllClassOn ? Number(form.lvWar.value) : 0;
  lvMys = AllClassOn ? Number(form.lvMys.value) : 0;
  lvDem = AllClassOn ? Number(form.lvDem.value) : 0;
  lvPhy = AllClassOn ? Number(form.lvPhy.value) : 0;
  lvGri = AllClassOn ? Number(form.lvGri.value) : 0;
  lvArt = AllClassOn ? Number(form.lvArt.value) : 0;
  lvAri = AllClassOn ? Number(form.lvAri.value) : 0;
  
  const expTotal = Number(document.getElementById("exp-total").innerHTML);
  let expUse = 0;
  expUse += expA[lvFig];
  expUse += expA[lvGra];
  expUse += expB[lvFen];
  expUse += expB[lvSho];
  expUse += expA[lvSor];
  expUse += expA[lvCon];
  expUse += expA[lvPri];
  expUse += expA[lvFai];
  expUse += expA[lvMag];
  expUse += expB[lvSco];
  expUse += expB[lvRan];
  expUse += expB[lvSag];
  expUse += expB[lvEnh];
  expUse += expB[lvBar];
  expUse += expB[lvRid];
  expUse += expB[lvAlc];
  expUse += expB[lvWar];
  expUse += expB[lvMys];
  expUse += expA[lvDem];
  expUse += expB[lvPhy];
  expUse += expA[lvGri];
  expUse += expB[lvArt];
  expUse += expB[lvAri];
  
  document.getElementById("exp-use").innerHTML = expUse;
  document.getElementById("exp-rest").innerHTML = expTotal - expUse;
  
  level = Math.max.apply(null, [
    lvFig, lvGra, lvFen, lvSho,
    lvSor, lvCon, lvPri, lvFai, lvMag,
    lvSco, lvRan, lvSag, lvEnh, lvBar,
    lvRid, lvAlc, lvWar, lvMys, lvDem,
    lvPhy, lvGri, lvArt, lvAri
  ]);
  document.getElementById("level-value").innerHTML = level;
  
  levelCasters = [lvSor, lvCon, lvPri, lvFai, lvMag, lvDem, lvGri];
  levelCasters.sort( function(a,b){ return (a < b ? 1 : -1); } );
  
  if(battleItemOn){
    const sLevel = Math.max.apply(null, [ lvSco, lvRan, lvSag ]);
    const maxBattleItems = 8 + Math.ceil(sLevel / 2);
    for (let i = 1; i <= 16; i++) {
      let cL = document.getElementById("battle-item"+i).classList;
      if(i <= maxBattleItems) { cL.remove("fail"); }
      else { cL.add("fail"); }
    }
  }
}

// 種族変更 //
function changeRace(){
  race = form.race.value;
  document.getElementById("race-ability-value").innerHTML = raceAbility[race];
  if (!form.languageAutoOff.checked) { document.getElementById("language-default").innerHTML = raceLanguage[race] ? raceLanguage[race] : '<dt>初期習得言語</dt><dd>○</dd><dd>○</dd>'; }
  else { document.getElementById("language-default").innerHTML = ''; }
  
  checkRace();
  calcStt();
}

// 種族チェック //
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

// ステータス計算 //
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
  
  checkFeats();
  calcSubStt();
  calcMobility();
  calcPackage();
  calcMagic();
  calcAttack();
  calcDefense();
  calcPointBuy();
}

// 戦闘特技チェック //
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
          if (f2 && lvFen >= 9) { (auto) ? box.value = "回避行動Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lvFen < 9) { (auto) ? box.value = "回避行動Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/^頑強/)){
        if(lvFig < 5 && lvGra < 5 && lvFen < 5){ cL.add("error"); }
      }
      else if (feat.match(/キャパシティ/)){
        if(level < 11){ cL.add("error"); }
      }
      else if (feat.match(/射手の体術/)){
        if(lvSho < 7){ cL.add("error"); }
      }
      else if (feat.match(/終律増強/)){
        if(lvBar < 3){ cL.add("error"); }
      }
      else if (feat.match(/呪歌追加/)){
        if(lvBar < 1){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lvBar >= 13) { (auto) ? box.value = "呪歌追加Ⅲ" : cL.add("evo") }
          else if(f2 && lvBar >=  7) { (auto) ? box.value = "呪歌追加Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lvBar >= 13) { (auto) ? box.value = "呪歌追加Ⅲ" : cL.add("evo") }
          else if(!f2 || lvBar <  7) { (auto) ? box.value = "呪歌追加Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || lvBar <  7) { (auto) ? box.value = "呪歌追加Ⅰ" : cL.add("error") }
          else if(!f3 || lvBar < 13) { (auto) ? box.value = "呪歌追加Ⅱ" : cL.add("error") }
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
        if((lvFig < 7 && lvGra < 7)|| !acquire.match('頑強')){ cL.add("error"); }
      }
      else if (feat.match(/特殊楽器習熟/)){
        if(lvBar < 1){ cL.add("error"); }
      }
      else if (feat.match(/跳び蹴り/)){
        if(lvGra < 9){ cL.add("error"); }
      }
      else if (feat.match(/投げ強化/)){
        if(lvGra < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lvGra >= 9) { (auto) ? box.value = "投げ強化Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lvGra < 9) { (auto) ? box.value = "投げ強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/二刀無双/)){
        if(level < 11){ cL.add("error"); }
      }
      else if (feat.match(/二刀流/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/ハーモニー/)){
        if(lvBar < 5){ cL.add("error"); }
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
        if(lvAlc < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lvAlc >= 9) { (auto) ? box.value = "賦術強化Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lvAlc < 9) { (auto) ? box.value = "賦術強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/賦術全遠隔化/)){
        if(lvAlc < 5){ cL.add("error"); }
      }
      else if (feat.match(/踏みつけ/)){
        if(lvGra < 5){ cL.add("error"); }
      }
      else if (feat.match(/変幻自在/)){
        if(lvGra < 5 && lvFen < 5){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lvGra >= 13 || lvFen >= 13)) { (auto) ? box.value = "変幻自在Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lvGra < 13 && lvFen < 13)) { (auto) ? box.value = "変幻自在Ⅰ" : cL.add("error") }
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
        if(lvAlc < 5){ cL.add("error"); }
      }
      else if (feat.match(/練体の極意/)){
        if(lvEnh < 5){ cL.add("error"); }
      }
      else if (feat.match(/ＭＰ軽減/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/インファイト/)){
        if(lvGra < 5){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lvGra >= 9) { (auto) ? box.value = "インファイトⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lvGra < 9) { (auto) ? box.value = "インファイトⅠ" : cL.add("error") }
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
        if(lvAlc < 5){ cL.add("error"); }
      }
      else if (feat.match(/楽素転換/)){
        if(lvBar < 3){ cL.add("error"); }
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
        if(lvSho < 9){ cL.add("error"); }
      }
      else if (feat.match(/牙折り/)){
        if(lvGra < 9){ cL.add("error"); }
      }
      else if (feat.match(/斬り返し/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lvFig >= 7 || lvFen >= 7)) { (auto) ? box.value = "斬り返しⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lvFig < 7 && lvFen < 7)) { (auto) ? box.value = "斬り返しⅠ" : cL.add("error") }
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
        if(lvBar < 3){ cL.add("error"); }
      }
      else if (feat.match(/スキルフルプレイ/)){
        if(lvBar < 7){ cL.add("error"); }
      }
      else if (feat.match(/全力攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lvFig >= 15)               { (auto) ? box.value = "全力攻撃Ⅲ" : cL.add("evo") }
          else if(f2 && (lvFig >= 9 || lvGra >= 9)){ (auto) ? box.value = "全力攻撃Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lvFig >= 15)               { (auto) ? box.value = "全力攻撃Ⅲ" : cL.add("evo") }
          else if(!f2 || (lvFig < 9 && lvGra < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || (lvFig < 9 && lvGra < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || lvFig < 15)               { (auto) ? box.value = "全力攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/ダブルキャスト/)){
        if(levelCasters[0] < 9){ cL.add("error"); }
      }
      else if (feat.match(/挑発攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && lvFen >= 7) { (auto) ? box.value = "挑発攻撃Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 ||  lvFen < 7) { (auto) ? box.value = "挑発攻撃Ⅰ" : cL.add("error") }
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
          if (f2 && lvFig >= 9) { (auto) ? box.value = "薙ぎ払いⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lvFig < 9) { (auto) ? box.value = "薙ぎ払いⅠ" : cL.add("error") }
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
          if     (f3 && lvFen >= 11) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("evo") }
          else if(f2 && level >=  7) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lvFen >= 11) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("evo") }
          else if(!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || lvFen < 11) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/マルチアクション/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/鎧貫き/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lvGra >= 11) { (auto) ? box.value = "鎧貫きⅢ" : cL.add("evo") }
          else if(f2 && lvGra >=  9) { (auto) ? box.value = "鎧貫きⅡ" : cL.add("evo") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lvGra >= 11) { (auto) ? box.value = "鎧貫きⅢ" : cL.add("evo") }
          else if(!f2 || lvGra <  9) { (auto) ? box.value = "鎧貫きⅠ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || lvGra <  9) { (auto) ? box.value = "鎧貫きⅠ" : cL.add("error") }
          else if(!f3 || lvGra < 11) { (auto) ? box.value = "鎧貫きⅡ" : cL.add("error") }
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

function checkCraft() {
  // 練技 //
  document.getElementById("craft-enhance").style.display = lvEnh ? "block" : "none";
  for (let i = 1; i <= 17; i++) {
    let cL = document.getElementById("craft-enhance"+i).classList;
    if(i <= lvEnh){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
  // 呪歌 //
  document.getElementById("craft-song").style.display = lvBar ? "block" : "none";
  for (let i = 1; i <= 19; i++) {
    let cL = document.getElementById("craft-song"+i).classList;
    if(i <= lvBar + songAddition){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
  // 騎芸 //
  document.getElementById("craft-riding").style.display = lvRid ? "block" : "none";
  for (let i = 1; i <= 17; i++) {
    let cL = document.getElementById("craft-riding"+i).classList;
    if(i <= lvRid){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
  // 賦術 //
  document.getElementById("craft-alchemy").style.display = lvAlc ? "block" : "none";
  for (let i = 1; i <= 17; i++) {
    let cL = document.getElementById("craft-alchemy"+i).classList;
    if(i <= lvAlc){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
  // 鼓咆 //
  document.getElementById("craft-command").style.display = lvWar ? "block" : "none";
  for (let i = 1; i <= 17; i++) {
    let cL = document.getElementById("craft-command"+i).classList;
    if(i <= lvWar){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
  // 占瞳 //
  document.getElementById("craft-divination").style.display = lvMys ? "block" : "none";
  for (let i = 1; i <= 17; i++) {
    let cL = document.getElementById("craft-divination"+i).classList;
    if(i <= lvMys){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
  // 魔装 //
  document.getElementById("craft-potential").style.display = lvPhy ? "block" : "none";
  for (let i = 1; i <= 17; i++) {
    let cL = document.getElementById("craft-potential"+i).classList;
    if(i <= lvPhy){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
  // 呪印 //
  document.getElementById("craft-seal").style.display = lvArt ? "block" : "none";
  for (let i = 1; i <= 17; i++) {
    let cL = document.getElementById("craft-seal"+i).classList;
    if(i <= lvArt){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
  // 貴格 //
  document.getElementById("craft-dignity").style.display = lvAri ? "block" : "none";
  for (let i = 1; i <= 17; i++) {
    let cL = document.getElementById("craft-dignity"+i).classList;
    if(i <= lvAri){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
  // 秘奥魔法 //
  document.getElementById("magic-gramarye").style.display = lvGri ? "block" : "none";
  for (let i = 1; i <= 17; i++) {
    let cL = document.getElementById("magic-gramarye"+i).classList;
    if(i <= lvGri){ cL.remove("fail","hidden"); }
    else {
      cL.add("fail");
      if(form.failView.checked){ cL.remove("hidden") } else { cL.add("hidden"); };
    }
  }
}

// ＨＰＭＰ抵抗力計算 //
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
    "Head", "Head_", "Ear", "Ear_", "Face", "Face_", "Neck", "Neck_", "Back", "Back_", "HandR", "HandR_", "HandL", "HandL_", "Waist", "Waist_", "Leg", "Leg_", "Other", "Other_", "Other2", "Other2_", "Other3", "Other3_", "Other4", "Other4_"
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
    : ((lvSor + lvCon + lvPri + lvFai + lvMag) * 3 + sttMnd + sttAddF);
  const hpAutoAdd = tenacity + hpAccessory + (lvFig >= 7 ? 15 : 0);
  const mpAutoAdd = capacity + raceAbilityMp + mpAccessory;
  document.getElementById("hp-base").innerHTML = hpBase;
  document.getElementById("mp-base").innerHTML = (race === 'グラスランナー') ? '0' : mpBase;
  document.getElementById("hp-auto-add").innerHTML = hpAutoAdd;
  document.getElementById("mp-auto-add").innerHTML = mpAutoAdd;
  document.getElementById("hp-total").innerHTML = hpBase + Number(form.hpAdd.value) + hpAutoAdd;
  document.getElementById("mp-total").innerHTML = (race === 'グラスランナー') ? 'なし' : (mpBase + Number(form.mpAdd.value) + mpAutoAdd);
}

// 移動力計算 //
function calcMobility() {
  const mobilityBase = ((race === 'ケンタウロス') ? (sttAgi * 2) : sttAgi) + (form["armourOwn"].checked ? 2 : 0);
  const mobility = mobilityBase + Number(form.mobilityAdd.value);
  document.getElementById("mobility-limited").innerHTML = footwork ? 10 : 3;
  document.getElementById("mobility-base").innerHTML = mobilityBase;
  document.getElementById("mobility-total").innerHTML = mobility;
  document.getElementById("mobility-full").innerHTML = mobility * 3;
}

// パッケージ計算 //
function calcPackage() {
  document.getElementById("package-scout"    ).style.display = lvSco > 0 ? "" :"none";
  document.getElementById("package-ranger"   ).style.display = lvRan > 0 ? "" :"none";
  document.getElementById("package-sage"     ).style.display = lvSag > 0 ? "" :"none";
  document.getElementById("package-rider"    ).style.display = lvRid > 0 ? "" :"none";
  document.getElementById("package-alchemist").style.display = lvAlc > 0 ? "" :"none";
  document.getElementById("package-alchemist").style.display = lvAlc > 0 ? "" :"none";
  document.getElementById("material-cards"   ).style.display = lvAlc > 0 ? "" :"none";
  
  document.getElementById("package-scout-tec"    ).innerHTML = lvSco + bonusDex + Number(form.packScoTecAdd.value);
  document.getElementById("package-scout-agi"    ).innerHTML = lvSco + bonusAgi + Number(form.packScoAgiAdd.value);
  document.getElementById("package-scout-obs"    ).innerHTML = lvSco + bonusInt + Number(form.packScoObsAdd.value);
  document.getElementById("package-ranger-tec"   ).innerHTML = lvRan + bonusDex + Number(form.packRanTecAdd.value);
  document.getElementById("package-ranger-agi"   ).innerHTML = lvRan + bonusAgi + Number(form.packRanAgiAdd.value);
  document.getElementById("package-ranger-obs"   ).innerHTML = lvRan + bonusInt + Number(form.packRanObsAdd.value);
  document.getElementById("package-sage-kno"     ).innerHTML = lvSag + bonusInt + Number(form.packSagKnoAdd.value);
  document.getElementById("package-rider-agi"    ).innerHTML = lvRid + bonusAgi + Number(form.packRidAgiAdd.value);
  document.getElementById("package-rider-kno"    ).innerHTML = lvRid + bonusInt + Number(form.packRidKnoAdd.value);
  document.getElementById("package-rider-obs"    ).innerHTML = lvRid + bonusInt + Number(form.packRidObsAdd.value);
  document.getElementById("package-alchemist-kno").innerHTML = lvAlc + bonusInt + Number(form.packAlcKnoAdd.value);
  
  const loreSag = lvSag + bonusInt + Number(form.packSagKnoAdd.value);
  const loreRid = lvRid + bonusInt + Number(form.packRidKnoAdd.value);
  let lore = loreRid > loreSag ? loreRid : loreSag;
      lore += Number(form.monsterLoreAdd.value);
  document.getElementById("monster-lore-value").innerHTML = (lvSag || lvRid) ? lore : 0;
  
  const initSco = lvSco + bonusAgi + Number(form.packScoAgiAdd.value);
  const initWar = lvWar + bonusAgi;
  let init = initWar > initSco ? initWar : initSco;
      init += Number(form.initiativeAdd.value);
  document.getElementById("initiative-value").innerHTML   = (lvSco || lvWar)  > 0 ? init : 0;
}

// 魔力計算 //
function calcMagic() {
  const add = Number(form.magicPowerAdd.value) + magicPowerEnhance;
  const addSor = Number(form.magicPowerAddSor.value);
  const addCon = Number(form.magicPowerAddCon.value);
  const addPri = Number(form.magicPowerAddPri.value);
  const addFai = Number(form.magicPowerAddFai.value);
  const addMag = Number(form.magicPowerAddMag.value);
  const addDem = Number(form.magicPowerAddDem.value);
  const addGri = Number(form.magicPowerAddGri.value);
  const addBar = Number(form.magicPowerAddBar.value);
  const addAlc = Number(form.magicPowerAddAlc.value) + alchemyEnhance;
  const addMys = Number(form.magicPowerAddMys.value);
  document.getElementById("magic-power").style.display = (Math.max(lvSor,lvCon,lvPri,lvFai,lvMag,lvDem,lvGri,lvBar,lvAlc,lvMys) > 0) ? '' : 'none';
  document.getElementById("magic-power-sorcerer").style.display   = lvSor > 0 ? '' : 'none';
  document.getElementById("magic-power-conjurer").style.display   = lvCon > 0 ? '' : 'none';
  document.getElementById("magic-power-priest"  ).style.display   = lvPri > 0 ? '' : 'none';
  document.getElementById("magic-power-fairytamer").style.display = lvFai > 0 ? '' : 'none';
  document.getElementById("magic-power-magitech").style.display   = lvMag > 0 ? '' : 'none';
  document.getElementById("magic-power-demonruler").style.display = lvDem > 0 ? '' : 'none';
  document.getElementById("magic-power-grimoir").style.display    = lvGri > 0 ? '' : 'none';
  document.getElementById("magic-power-bard").style.display       = lvBar > 0 ? '' : 'none';
  document.getElementById("magic-power-alchemist").style.display  = lvAlc > 0 ? '' : 'none';
  document.getElementById("magic-power-mystic").style.display     = lvMys > 0 ? '' : 'none';
  document.getElementById("magic-power-sorcerer-value").innerHTML   = lvSor + parseInt((sttInt + sttAddE + (form.magicPowerOwnSor.checked ? 2 : 0)) / 6) + addSor + add;
  document.getElementById("magic-power-conjurer-value").innerHTML   = lvCon + parseInt((sttInt + sttAddE + (form.magicPowerOwnCon.checked ? 2 : 0)) / 6) + addCon + add;
  document.getElementById("magic-power-priest-value"  ).innerHTML   = lvPri + parseInt((sttInt + sttAddE + (form.magicPowerOwnPri.checked ? 2 : 0)) / 6) + addPri + add;
  document.getElementById("magic-power-fairytamer-value").innerHTML = lvFai + parseInt((sttInt + sttAddE + (form.magicPowerOwnFai.checked ? 2 : 0)) / 6) + addFai + add;
  document.getElementById("magic-power-magitech-value").innerHTML   = lvMag + parseInt((sttInt + sttAddE + (form.magicPowerOwnMag.checked ? 2 : 0)) / 6) + addMag + add;
  document.getElementById("magic-power-demonruler-value").innerHTML = lvDem + parseInt((sttInt + sttAddE + (form.magicPowerOwnDem.checked ? 2 : 0)) / 6) + addDem + add;
  document.getElementById("magic-power-grimoir-value").innerHTML    = lvGri + parseInt((sttInt + sttAddE + (form.magicPowerOwnGri.checked ? 2 : 0)) / 6) + addGri + add;
  document.getElementById("magic-power-bard-value").innerHTML       = lvBar + parseInt((sttMnd + sttAddF + (form.magicPowerOwnBar.checked ? 2 : 0)) / 6) + addBar;
  document.getElementById("magic-power-alchemist-value").innerHTML  = lvAlc + parseInt((sttInt + sttAddE + (form.magicPowerOwnAlc.checked ? 2 : 0)) / 6) + addAlc;
  document.getElementById("magic-power-mystic-value").innerHTML     = lvMys + parseInt((sttInt + sttAddE + (form.magicPowerOwnMys.checked ? 2 : 0)) / 6) + addMys;
}

// 攻撃計算 //
function calcAttack() {
  document.getElementById("attack-fighter"   ).style.display = lvFig >   0 ? "" :"none";
  document.getElementById("attack-grappler"  ).style.display = lvGra >   0 ? "" :"none";
  document.getElementById("attack-fencer"    ).style.display = lvFen >   0 ? "" :"none";
  document.getElementById("attack-shooter"   ).style.display = lvSho >   0 ? "" :"none";
  document.getElementById("attack-enhancer"  ).style.display = lvEnh >= 10 ? "" :"none";
  document.getElementById("attack-demonruler").style.display = lvDem >   0 ? "" :"none";

  const reqdStr = sttStr + sttAddC;
  document.getElementById("attack-fighter-str"   ).innerHTML = reqdStr;
  document.getElementById("attack-grappler-str"  ).innerHTML = reqdStr;
  document.getElementById("attack-fencer-str"    ).innerHTML = Math.ceil(reqdStr / 2);
  document.getElementById("attack-shooter-str"   ).innerHTML = reqdStr;
  document.getElementById("attack-enhancer-str"  ).innerHTML = reqdStr;
  document.getElementById("attack-demonruler-str").innerHTML = reqdStr;

  document.getElementById("attack-fighter-acc"   ).innerHTML = lvFig + bonusDex;
  document.getElementById("attack-grappler-acc"  ).innerHTML = lvGra + bonusDex;
  document.getElementById("attack-fencer-acc"    ).innerHTML = lvFen + bonusDex;
  document.getElementById("attack-shooter-acc"   ).innerHTML = lvSho + bonusDex;
  document.getElementById("attack-enhancer-acc"  ).innerHTML = lvEnh + bonusDex;
  document.getElementById("attack-demonruler-acc").innerHTML = lvDem + bonusDex;

  document.getElementById("attack-fighter-dmg"   ).innerHTML = lvFig + bonusStr;
  document.getElementById("attack-grappler-dmg"  ).innerHTML = lvGra + bonusStr;
  document.getElementById("attack-fencer-dmg"    ).innerHTML = lvFen + bonusStr;
  document.getElementById("attack-shooter-dmg"   ).innerHTML = lvSho + bonusStr;
  document.getElementById("attack-enhancer-dmg"  ).innerHTML = lvEnh + bonusStr;
  document.getElementById("attack-demonruler-dmg").innerHTML = lvDem + bonusStr;

  calcWeapon();
}
function calcWeapon() {
  const weaponNum = form.weaponNum.value;
  for (let i = 1; i <= weaponNum; i++){
    const classes = form["weapon"+i+"Class"].value;
    const category = form["weapon"+i+"Category"].value;
    const ownDex = form["weapon"+i+"Own"].checked ? 2 : 0;
    const note = form["weapon"+i+"Note"].value;
    let attackClass;
    let accBase = 0;
    let dmgBase = 0;
    accBase += accuracyEnhance; //命中強化
         if(classes === "ファイター")       { attackClass = lvFig; }
    else if(classes === "グラップラー")     { attackClass = lvGra; }
    else if(classes === "フェンサー")       { attackClass = lvFen; }
    else if(classes === "シューター")       { attackClass = lvSho; }
    else if(classes === "エンハンサー")     { attackClass = lvEnh; }
    else if(classes === "デーモンルーラー") { attackClass = lvDem; }
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
      const magicPower = lvMag ? Number(document.getElementById('magic-power-magitech-value').innerHTML) : 0;
      dmgBase = magicPower + masteryGun;
    }
    else if(category === 'ガン（物理）')   { dmgBase += masteryGun; }
    if(note.match(/〈魔器〉/)){ dmgBase += masteryArtisan; }
    
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

// 防御計算 //
function calcDefense() {
  const classes = form.evasionClass.options[form.evasionClass.selectedIndex].value;
  const ownAgi = form["shieldOwn"].checked ? 2 : 0;
  let evaClassLv = 0;
  let evaBase = 0;
  let defBase = 0;
       if(classes === "ファイター")      { evaClassLv = lvFig; }
  else if(classes === "グラップラー")    { evaClassLv = lvGra; }
  else if(classes === "フェンサー")      { evaClassLv = lvFen; }
  else if(classes === "シューター")      { evaClassLv = lvSho;  }
  else if(classes === "デーモンルーラー"){ evaClassLv = lvDem; }
  else { evaClassLv = 0; }
  evaBase = evaClassLv ? (evaClassLv + parseInt((sttAgi + sttAddB + ownAgi) / 6)) : 0;
  
  const reqdStr = sttStr + sttAddC;
  document.getElementById("evasion-str").innerHTML = (classes === "フェンサー") ? Math.ceil(reqdStr / 2) : reqdStr;
  document.getElementById("evasion-eva").innerHTML = evaClassLv ? (evaClassLv + bonusAgi) : 0;
  
  // 技能選択のエラー表示
  let cL = document.getElementById("evasion-classes").classList;
  if(classes === "シューター" && !shootersMartialArts || classes === "デーモンルーラー" && lvDem < 7){ 
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
  
  calcArmour(evaBase,defBase);
}
function calcArmour(evaBase,defBase) {
  const armourEva = Number(form.armourEva.value);
  const armourDef = Number(form.armourDef.value) + Math.max(masteryMetalArmour,masteryNonMetalArmour);
  const shieldEva = Number(form.shieldEva.value);
  const shieldDef = Number(form.shieldDef.value) + masteryShield;
  const otherEva  = Number(form.defOtherEva.value);
  const otherDef  = Number(form.defOtherDef.value);
  
  if(form.armourNote.value.match(/〈魔器〉/) || form.shieldNote.value.match(/〈魔器〉/)){ defBase += masteryArtisan; }
  
  document.getElementById("defense-total-all-eva").innerHTML = evaBase + armourEva + shieldEva + otherEva;
  document.getElementById("defense-total-all-def").innerHTML = defBase + armourDef + shieldDef + otherDef;
}

// 経験点計算 //
function calcExp(){
  let expTotal = 0;
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    let exp = Number(eval(form['history'+i+'Exp'].value));
    if(isNaN(exp)){ exp = 0; }
    expTotal += exp;
  }
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


// 名誉点計算 //
function calcHonor(){
  let pointTotal = 0;
  let mysticArtsPt = 0;
  const rank = form["rank"].options[form["rank"].selectedIndex].value;
  const rankNum = (adventurerRank[rank]["num"] === undefined) ? 0 : adventurerRank[rank]["num"];
  const free = (adventurerRank[rank]["free"] === undefined) ? 0 : adventurerRank[rank]["free"];
  const historyNum = form.historyNum.value;
  pointTotal -= rankNum;
  for (let i = 0; i <= historyNum; i++){
    let point = Number(eval(form['history'+i+'Honor'].value));
    if(isNaN(point)){ point = 0; }
    pointTotal += point;
  }
  const honorItemsNum = form.honorItemsNum.value;
  for (let i = 1; i <= honorItemsNum; i++){
    let point = Number(eval(form['honorItem'+i+'Pt'].value));
    if(isNaN(point)){ point = 0; }
    pointTotal -= point;
    
    let cL = form['honorItem'+i+'Pt'].classList;
    if(point && point <= free) { cL.add("free"); }
    else { cL.remove("free"); }
  }
  const mysticArtsNum = form.mysticArtsNum.value;
  for (let i = 1; i <= mysticArtsNum; i++){
    let point = Number(eval(form['mysticArts'+i+'Pt'].value));
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
    let point = Number(eval(form['dishonorItem'+i+'Pt'].value));
    if(isNaN(point)){ point = 0; }
    pointTotal += point;
  }
  document.getElementById("dishonor-value").innerHTML = pointTotal;
  for(const key in notorietyRank){
    if(pointTotal >= notorietyRank[key]['num']) { document.getElementById("notoriety").innerHTML = key; }
  }
}

// 収支履歴計算 //
function calcCash(){
  let cash = 0;
  let deposit = 0;
  let debt = 0;
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    let hCash = Number(eval(form['history'+i+'Money'].value))
    if(isNaN(hCash)){ hCash = 0; }
    cash += hCash;
  }
  let s = form.cashbook.value;
  s.replace(
    /::([\+\-\*]?[0-9]+)+/g,
    function (num, idx, old) {
      cash += Number(eval(num.slice(2)));
    }
  );
  s.replace(
    /:>([\+\-\*]?[0-9]+)+/g,
    function (num, idx, old) {
      deposit += Number(eval(num.slice(2)));
    }
  );
  s.replace(
    /:<([\+\-\*]?[0-9]+)+/g,
    function (num, idx, old) {
      debt += Number(eval(num.slice(2)));
    }
  );
  cash = cash - deposit + debt;
  document.getElementById('cashbook-total-value').innerHTML = cash;
  document.getElementById('cashbook-deposit-value').innerHTML = deposit;
  document.getElementById('cashbook-debt-value').innerHTML = debt;
}

// 装飾品欄追加枠 //
function addAccessory(check,name){
  if(check.checked) {
    document.getElementById("accessory-"+name+"_").style.display = '';
  }
  else {
    document.getElementById("accessory-"+name+"_").style.display = 'none';
  }
}

// 秘伝欄追加 //
function addMysticArts(){
  let num = Number(form.mysticArtsNum.value) + 1;
  let list1 = document.getElementById("mystic-arts-list");
  list1.insertAdjacentHTML('beforeend', '<dt><input type="text" name="mysticArts' + num + '"></dt><dd><input type="number" name="mysticArts' + num + 'Pt" oninput="calcHonor()"></dd>');
  form.mysticArtsNum.value = num;
}
function delMysticArts(){
  let num = Number(form.mysticArtsNum.value);
  if(num > 0){
    let list1 = document.getElementById("mystic-arts-list");
    list1.removeChild(list1.lastElementChild);
    list1.removeChild(list1.lastElementChild);
    num--;
    form.mysticArtsNum.value = num;
  }
}

// 言語欄追加 //
function addLanguage(){
  let num = Number(form.languageNum.value) + 1;
  let table1 = document.getElementById("language-table");
  let row1 = table1.insertRow(-1);
  let cell0 = row1.insertCell(0);
  let cell1 = row1.insertCell(1);
  let cell2 = row1.insertCell(2);
  cell0.innerHTML = '<input type="text" name="language' + num + '">';
  cell1.innerHTML = '<input type="checkbox" name="language' + num + 'Talk" value="○">';
  cell2.innerHTML = '<input type="checkbox" name="language' + num + 'Read" value="○">';
  form.languageNum.value = num;
}
function delLanguage(){
  let num = Number(form.languageNum.value);
  if(num > 1){
    let table1 = document.getElementById("language-table");
    table1.deleteRow(-1);
    num--;
    form.languageNum.value = num;
  }
}


// 武器欄追加 //
function addWeapons(){
  let num = Number(form.weaponNum.value) + 1;
  let table1 = document.getElementById("weapons-table");
  let row1 = table1.insertRow(-1);
  let cell0  = row1.insertCell( 0);
  let cell1  = row1.insertCell( 1);
  let cell2  = row1.insertCell( 2);
  let cell3  = row1.insertCell( 3);
  let cell4  = row1.insertCell( 4);
  let cell5  = row1.insertCell( 5);
  let cell6  = row1.insertCell( 6);
  let cell7  = row1.insertCell( 7);
  let cell8  = row1.insertCell( 8);
  let cell9  = row1.insertCell( 9);
  let cell10 = row1.insertCell(10);
  
  row1.dataset.sort = num;
  cell0.innerHTML  = '<input type="text" name="weapon' + num + 'Name">';
  cell1.innerHTML  = '<input type="text" name="weapon' + num + 'Usage">';
  cell2.innerHTML  = '<input type="text" name="weapon' + num + 'Reqd">';
  cell3.innerHTML  = '+<input type="number" name="weapon' + num + 'Acc" oninput="calcWeapon()">=<b id="weapon' + num + '-acc-total"></b>';
  cell4.innerHTML  = '<input type="text" name="weapon' + num + 'Rate">';
  cell5.innerHTML  = '<input type="text" name="weapon' + num + 'Crit">';
  cell6.innerHTML  = '+<input type="number" name="weapon' + num + 'Dmg" oninput="calcWeapon()">=<b id="weapon' + num + '-dmg-total"></b>';
  cell7.innerHTML  = '<input type="checkbox" name="weapon' + num + 'Own" oninput="calcWeapon()">';
  cell8.innerHTML  = '<select id="weapon' + num + '-category" name="weapon' + num + 'Category" oninput="calcWeapon()"><option></select>';
  cell9.innerHTML  = '<select id="weapon' + num + '-class" name="weapon' + num + 'Class" oninput="calcWeapon()"><option><option>ファイター<option>グラップラー<option>フェンサー<option>シューター<option>デーモンルーラー</select>';
  cell10.innerHTML = '<input type="text" name="weapon' + num + 'Note" oninput="calcWeapon()">';
  
  for(let i = 0; i < weapons.length; i++){
    let op = document.createElement("option");
    op.text = weapons[i];
    document.getElementById("weapon"+num+"-category").appendChild(op);
  }
  
  form.weaponNum.value = num;
}
function delWeapons(){
  let num = Number(form.weaponNum.value);
  if(num > 1){
    let table1 = document.getElementById("weapons-table");
    table1.deleteRow(-1);
    num--;
    form.weaponNum.value = num;
  }
}
function switchWeapon(num){
  const Name     = form['weapon' + num + 'Name'    ].value;
  const Usage    = form['weapon' + num + 'Usage'   ].value;
  const Reqd     = form['weapon' + num + 'Reqd'    ].value;
  const Acc      = form['weapon' + num + 'Acc'     ].value;
  const Rate     = form['weapon' + num + 'Rate'    ].value;
  const Crit     = form['weapon' + num + 'Crit'    ].value;
  const Dmg      = form['weapon' + num + 'Dmg'     ].value;
  const Own      = form['weapon' + num + 'Own'     ].checked;
  const Category = form['weapon' + num + 'Category'].value;
  const Class    = form['weapon' + num + 'Class'   ].value;
  const Note     = form['weapon' + num + 'Note'    ].value;
  
  form['weapon' + num + 'Name'    ].value  = form['weapon' + (num+1) + 'Name'    ].value;
  form['weapon' + num + 'Usage'   ].value  = form['weapon' + (num+1) + 'Usage'   ].value;
  form['weapon' + num + 'Reqd'    ].value  = form['weapon' + (num+1) + 'Reqd'    ].value;
  form['weapon' + num + 'Acc'     ].value  = form['weapon' + (num+1) + 'Acc'     ].value;
  form['weapon' + num + 'Rate'    ].value  = form['weapon' + (num+1) + 'Rate'    ].value;
  form['weapon' + num + 'Crit'    ].value  = form['weapon' + (num+1) + 'Crit'    ].value;
  form['weapon' + num + 'Dmg'     ].value  = form['weapon' + (num+1) + 'Dmg'     ].value;
  form['weapon' + num + 'Own'     ].checked= form['weapon' + (num+1) + 'Own'     ].checked;
  form['weapon' + num + 'Category'].value  = form['weapon' + (num+1) + 'Category'].value;
  form['weapon' + num + 'Class'   ].value  = form['weapon' + (num+1) + 'Class'   ].value;
  form['weapon' + num + 'Note'    ].value  = form['weapon' + (num+1) + 'Note'    ].value;
  
  form['weapon' + (num+1) + 'Name'    ].value  = Name    ;
  form['weapon' + (num+1) + 'Usage'   ].value  = Usage   ;
  form['weapon' + (num+1) + 'Reqd'    ].value  = Reqd    ;
  form['weapon' + (num+1) + 'Acc'     ].value  = Acc     ;
  form['weapon' + (num+1) + 'Rate'    ].value  = Rate    ;
  form['weapon' + (num+1) + 'Crit'    ].value  = Crit    ;
  form['weapon' + (num+1) + 'Dmg'     ].value  = Dmg     ;
  form['weapon' + (num+1) + 'Own'     ].checked= Own   ;
  form['weapon' + (num+1) + 'Category'].value  = Category;
  form['weapon' + (num+1) + 'Class'   ].value  = Class   ;
  form['weapon' + (num+1) + 'Note'    ].value  = Note    ;
  
  calcWeapon();
}

// 名誉アイテム欄追加 //
function addHonorItems(){
  let num = Number(form.honorItemsNum.value) + 1;
  let table1 = document.getElementById("honor-items-table");
  let row1 = table1.insertRow(-1);
  let cell0 = row1.insertCell(0);
  let cell1 = row1.insertCell(1);
  cell0.innerHTML = '<input type="text" name="honorItem' + num + '">';
  cell1.innerHTML = '<input type="number" name="honorItem' + num + 'Pt" oninput="calcHonor()">';
  form.honorItemsNum.value = num;
}
function delHonorItems(){
  let num = Number(form.honorItemsNum.value);
  if(num > 1){
    let table1 = document.getElementById("honor-items-table");
    table1.deleteRow(-1);
    num--;
    form.honorItemsNum.value = num;
  }
}
// 不名誉欄追加 //
function addDishonorItems(){
  let num = Number(form.dishonorItemsNum.value) + 1;
  let table1 = document.getElementById("dishonor-items-table");
  let row1 = table1.insertRow(-1);
  let cell0 = row1.insertCell(0);
  let cell1 = row1.insertCell(1);
  cell0.innerHTML = '<input type="text" name="dishonorItem' + num + '">';
  cell1.innerHTML = '<input type="number" name="dishonorItem' + num + 'Pt" oninput="calcDishonor()">';
  form.dishonorItemsNum.value = num;
}
function delDishonorItems(){
  let num = Number(form.dishonorItemsNum.value);
  if(num > 1){
    let table1 = document.getElementById("dishonor-items-table");
    table1.deleteRow(-1);
    num--;
    form.dishonorItemsNum.value = num;
  }
}

// 履歴欄追加 //
function addHistory(){
  let num = Number(form.historyNum.value) + 1;
  let table1 = document.getElementById("history-table");
  let row1 = table1.insertRow(-1);
  let cell0  = row1.insertCell(0);
  let cell1  = row1.insertCell(1);
  let cell2  = row1.insertCell(2);
  let cell3  = row1.insertCell(3);
  let cell4  = row1.insertCell(4);
  let cell5  = row1.insertCell(5);
  let cell6  = row1.insertCell(6);
  let cell7  = row1.insertCell(7);
  let cell8  = row1.insertCell(8);
  let cell9  = row1.insertCell(9);
  
  cell0.innerHTML  = num;
  cell1.innerHTML  = '<input type="text" name="history' + num + 'Date"><br><a class="switch-button" onclick="switchHistory(' + num + ')">⇕</a>';
  cell2.innerHTML  = '<input type="text" name="history' + num + 'Title">';
  cell3.innerHTML  = '<input type="text" name="history' + num + 'Exp" oninput="calcExp()">';
  cell4.innerHTML  = '<input type="text" name="history' + num + 'Honor" oninput="calcHonor()">';
  cell5.innerHTML  = '<input type="text" name="history' + num + 'Money" oninput="calcCash()">';
  cell6.innerHTML  = '<input type="text" name="history' + num + 'Grow" list="list-grow">';
  cell7.innerHTML  = '<input type="text" name="history' + num + 'Gm">';
  cell8.innerHTML  = '<input type="text" name="history' + num + 'Member">';
  cell9.innerHTML  = '<input type="text" name="history' + num + 'Note" placeholder="備考">';
  
  form.historyNum.value = num;
}
function delHistory(){
  let num = Number(form.historyNum.value);
  if(num > 1){
    let table1 = document.getElementById("history-table");
    table1.deleteRow(-1);
    num--;
    form.historyNum.value = num;
  }
}
function switchHistory(num){
  const Date  = form['history' + num + 'Date'  ].value;
  const Name  = form['history' + num + 'Title' ].value;
  const Exp   = form['history' + num + 'Exp'   ].value;
  const Money = form['history' + num + 'Honor' ].value;
  const Honor = form['history' + num + 'Money' ].value;
  const Grow  = form['history' + num + 'Grow'  ].value;
  const Gm    = form['history' + num + 'Gm'    ].value;
  const Member= form['history' + num + 'Member'].value;
  const Note  = form['history' + num + 'Note'  ].value;
  
  form['history' + num + 'Date'  ].value = form['history' + (num+1) + 'Date'  ].value;
  form['history' + num + 'Title' ].value = form['history' + (num+1) + 'Title' ].value;
  form['history' + num + 'Exp'   ].value = form['history' + (num+1) + 'Exp'   ].value;
  form['history' + num + 'Honor' ].value = form['history' + (num+1) + 'Honor' ].value;
  form['history' + num + 'Money' ].value = form['history' + (num+1) + 'Money' ].value;
  form['history' + num + 'Grow'  ].value = form['history' + (num+1) + 'Grow'  ].value;
  form['history' + num + 'Gm'    ].value = form['history' + (num+1) + 'Gm'    ].value;
  form['history' + num + 'Member'].value = form['history' + (num+1) + 'Member'].value;
  form['history' + num + 'Note'  ].value = form['history' + (num+1) + 'Note'  ].value;
  
  form['history' + (num+1) + 'Date'  ].value = Date  ;
  form['history' + (num+1) + 'Title' ].value = Name  ;
  form['history' + (num+1) + 'Exp'   ].value = Exp   ;
  form['history' + (num+1) + 'Honor' ].value = Money ;
  form['history' + (num+1) + 'Money' ].value = Honor ;
  form['history' + (num+1) + 'Grow'  ].value = Grow  ;
  form['history' + (num+1) + 'Gm'    ].value = Gm    ;
  form['history' + (num+1) + 'Member'].value = Member;
  form['history' + (num+1) + 'Note'  ].value = Note  ;
}

// 割り振り計算 //
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

// 画像配置 //
function imagePosition(){
  const bgSize = form.imageFit.options[form.imageFit.selectedIndex].value;
  document.getElementById("image").style.backgroundSize = bgSize;
  if(bgSize === 'percent'){
    document.getElementById("image").style.backgroundSize = form.imagePercent.value + '%';
    document.getElementById("image").style.backgroundPositionX = form.imagePositionX.value + '%';
    document.getElementById("image").style.backgroundPositionY = form.imagePositionY.value + '%';
  }
}

// 表示／非表示 //
function view(viewId){
  let value = document.getElementById(viewId).style.display;
  document.getElementById(viewId).style.display = (value === 'none') ? '' : 'none';
}

// カラーカスタム //
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

// セクション選択 //
function sectionSelect(id){
  const sections = ['common','fellow','palette','color'];
  sections.forEach( (value) => {
    document.getElementById('section-'+value).style.display = 'none';
  });
  document.getElementById('section-'+id).style.display = 'block';
}



