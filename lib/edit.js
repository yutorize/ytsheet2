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
let lvMag = 0;
let lvSco = 0;
let lvRan = 0;
let lvSag = 0;

window.onload = function() {
  calcLv();
  calcStt();
  calcCash();
};

function changeRegu(){
  document.getElementById("history0-exp").innerHTML = form.history0Exp.value;
  document.getElementById("history0-honor").innerHTML = form.history0Honor.value;
  document.getElementById("history0-money").innerHTML = form.history0Money.value;
  
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

// レベル計算 //
function calcLv(){
  lvFig = Number(form.lvFig.value);
  lvGra = Number(form.lvGra.value);
  lvFen = Number(form.lvFen.value);
  lvSho = Number(form.lvSho.value);
  lvSor = Number(form.lvSor.value);
  lvCon = Number(form.lvCon.value);
  lvPri = Number(form.lvPri.value);
  lvMag = Number(form.lvMag.value);
  lvSco = Number(form.lvSco.value);
  lvRan = Number(form.lvRan.value);
  lvSag = Number(form.lvSag.value);
  
  const expTotal = Number(document.getElementById("exp-total").innerHTML);
  let expUse = 0;
  expUse += expA[lvFig];
  expUse += expA[lvGra];
  expUse += expB[lvFen];
  expUse += expB[lvSho];
  expUse += expA[lvSor];
  expUse += expA[lvCon];
  expUse += expA[lvPri];
  expUse += expA[lvMag];
  expUse += expB[lvSco];
  expUse += expB[lvRan];
  expUse += expB[lvSag];
  
  document.getElementById("exp-rest").innerHTML = expTotal - expUse;
  
  level = Math.max.apply(null, [
    lvFig, lvGra, lvFen, lvSho,
    lvSor, lvCon, lvPri, lvMag,
    lvSco, lvRan, lvSag
  ]);
  document.getElementById("level-value").innerHTML = level;
  
}

// レベル変更 //
function changeLv() {
  calcLv();
  
  checkRace();
  calcPackage();
  checkFeats();
}

// 種族変更 //
function changeRace(){
  race = form.race.value;
  document.getElementById("race-ability-value").innerHTML = raceAbility[race];
  document.getElementById("language-default").innerHTML = raceLanguage[race];
  
  checkRace();
  calcSubStt();
  calcMobility();
  calcDefense();
}

// 種族チェック //
function checkRace(){
  raceAbilityDef = 0;
  raceAbilityMndResist = 0;
  raceAbilityMp = 0;
  if(race === 'リルドラケン'){
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
  if(race === 'ダークトロール'){
    raceAbilityDef = 1;
    document.getElementById("race-ability-def-name").innerHTML = 'トロールの体躯';
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
  
  sttDex = Number(form.sttBaseTec.value) + Number(form.sttBaseA.value) + growDex;
  sttAgi = Number(form.sttBaseTec.value) + Number(form.sttBaseB.value) + growAgi;
  sttStr = Number(form.sttBasePhy.value) + Number(form.sttBaseC.value) + growStr;
  sttVit = Number(form.sttBasePhy.value) + Number(form.sttBaseD.value) + growVit;
  sttInt = Number(form.sttBaseSpi.value) + Number(form.sttBaseE.value) + growInt;
  sttMnd = Number(form.sttBaseSpi.value) + Number(form.sttBaseF.value) + growMnd;
  
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
}

// 戦闘特技チェック //
function checkFeats(){
  const array = [1,3,5,7,9,11,13,15,16,17];
  accuracyEnhance = 0;
  evasiveManeuver = 0;
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
  masteryBlowGun = 0;
  masteryGun = 0;
  for (let i = 0; i <= array.length; i++) {
    if(level >= array[i]){
      let feat = form["combatFeatsLv"+array[i]].options[form["combatFeatsLv"+array[i]].selectedIndex].value;
      if     (feat === "回避行動Ⅰ"){ evasiveManeuver += 1; }
      else if(feat === "頑強"){ tenacity += 15; }
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
    }
  }
  
  calcSubStt();
  calcMagic();
  calcAttack();
  calcDefense();
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
  
  const hpBase = level * 3 + sttVit + sttAddD;
  const mpBase = 
    (race === 'マナフレア') ? (level * 3 + sttMnd + sttAddF)
    : ((lvSor + lvCon + lvPri + lvMag) * 3 + sttMnd + sttAddF);
  const hpAutoAdd = tenacity;
  const mpAutoAdd = capacity + raceAbilityMp;
  document.getElementById("hp-base").innerHTML = hpBase;
  document.getElementById("mp-base").innerHTML = (race === 'グラスランナー') ? '0' : mpBase;
  document.getElementById("hp-auto-add").innerHTML = hpAutoAdd;
  document.getElementById("mp-auto-add").innerHTML = mpAutoAdd;
  document.getElementById("hp-total").innerHTML = hpBase + Number(form.hpAdd.value) + hpAutoAdd;
  document.getElementById("mp-total").innerHTML = (race === 'グラスランナー') ? 'なし' : (mpBase + Number(form.mpAdd.value) + mpAutoAdd);
}

// 移動力計算 //
function calcMobility() {
  const mobilityBase = (race === 'ケンタウロス') ? (sttAgi * 2) : sttAgi;
  const mobility = mobilityBase + Number(form.mobilityAdd.value);
  document.getElementById("mobility-limited").innerHTML = 3;
  document.getElementById("mobility-base").innerHTML = mobilityBase;
  document.getElementById("mobility-total").innerHTML = mobility;
  document.getElementById("mobility-full").innerHTML = mobility * 3;
}

// パッケージ計算 //
function calcPackage() {
  document.getElementById("package-scout" ).style.display = lvSco > 0 ? "" :"none";
  document.getElementById("package-ranger").style.display = lvRan > 0 ? "" :"none";
  document.getElementById("package-sage"  ).style.display = lvSag > 0 ? "" :"none";
  
  document.getElementById("package-scout-tec").innerHTML = lvSco + bonusDex;
  document.getElementById("package-scout-agi").innerHTML = lvSco + bonusAgi;
  document.getElementById("package-scout-int").innerHTML = lvSco + bonusInt;
  document.getElementById("package-ranger-tec").innerHTML = lvRan + bonusDex;
  document.getElementById("package-ranger-agi").innerHTML = lvRan + bonusAgi;
  document.getElementById("package-ranger-int").innerHTML = lvRan + bonusInt;
  document.getElementById("package-sage-int").innerHTML = lvSag + bonusInt;
  
  document.getElementById("monster-lore-value").innerHTML = lvSag > 0 ? lvSag + bonusInt : 0;
  document.getElementById("initiative-value").innerHTML   = lvSco > 0 ? lvSco + bonusAgi : 0;
}

// 魔力計算 //
function calcMagic() {
  const magicPowerAdd = Number(form.magicPowerAdd.value);
  document.getElementById("magic-power-sorcerer").style.display = lvSor > 0 ? '' : 'none';
  document.getElementById("magic-power-conjurer").style.display = lvCon > 0 ? '' : 'none';
  document.getElementById("magic-power-priest"  ).style.display = lvPri > 0 ? '' : 'none';
  document.getElementById("magic-power-magitech").style.display = lvMag > 0 ? '' : 'none';
  document.getElementById("magic-power-sorcerer-value").innerHTML = lvSor + bonusInt + magicPowerAdd;
  document.getElementById("magic-power-conjurer-value").innerHTML = lvCon + bonusInt + magicPowerAdd;
  document.getElementById("magic-power-priest-value"  ).innerHTML = lvPri + bonusInt + magicPowerAdd;
  document.getElementById("magic-power-magitech-value").innerHTML = lvMag + bonusInt + magicPowerAdd;
}

// 攻撃計算 //
function calcAttack() {
  document.getElementById("attack-fighter" ).style.display = lvFig > 0 ? "" :"none";
  document.getElementById("attack-grappler").style.display = lvGra > 0 ? "" :"none";
  document.getElementById("attack-fencer"  ).style.display = lvFen > 0 ? "" :"none";
  document.getElementById("attack-shooter" ).style.display = lvSho > 0 ? "" :"none";
  
  const reqdStr = sttStr + sttAddC;
  document.getElementById("attack-fighter-str" ).innerHTML = reqdStr;
  document.getElementById("attack-grappler-str").innerHTML = reqdStr;
  document.getElementById("attack-fencer-str"  ).innerHTML = Math.ceil(reqdStr / 2);
  document.getElementById("attack-shooter-str" ).innerHTML = reqdStr;
  
  document.getElementById("attack-fighter-acc" ).innerHTML = lvFig + bonusDex;
  document.getElementById("attack-grappler-acc").innerHTML = lvGra + bonusDex;
  document.getElementById("attack-fencer-acc"  ).innerHTML = lvFen + bonusDex;
  document.getElementById("attack-shooter-acc" ).innerHTML = lvSho + bonusDex;
  document.getElementById("attack-fighter-dmg" ).innerHTML = lvFig + bonusStr;
  document.getElementById("attack-grappler-dmg").innerHTML = lvGra + bonusStr;
  document.getElementById("attack-fencer-dmg"  ).innerHTML = lvFen + bonusStr;
  document.getElementById("attack-shooter-dmg" ).innerHTML = lvSho + bonusStr;
  
  calcWeapon();
}
function calcWeapon() {
  const weaponNum = form.weaponNum.value;
  for (let i = 1; i <= weaponNum; i++){
    const classes = form["weapon"+i+"Class"].value;
    const category = form["weapon"+i+"Category"].value;
    let attackClass;
    let accBase = 0;
    let dmgBase = 0;
         if(classes === "ファイター")   { attackClass = lvFig; }
    else if(classes === "グラップラー") { attackClass = lvGra; }
    else if(classes === "フェンサー")   { attackClass = lvFen; }
    else if(classes === "シューター")   { attackClass = lvSho; }
    if(attackClass) {
      accBase = attackClass + parseInt((sttDex + sttAddA) / 6);
      dmgBase = attackClass;
      if     (category === 'ソード')         { dmgBase += bonusStr + masterySword; }
      else if(category === 'アックス')       { dmgBase += bonusStr + masteryAxe; }
      else if(category === 'スピア')         { dmgBase += bonusStr + masterySpear; }
      else if(category === 'メイス')         { dmgBase += bonusStr + masteryMace; }
      else if(category === 'スタッフ')       { dmgBase += bonusStr + masteryStaff; }
      else if(category === 'フレイル')       { dmgBase += bonusStr + masteryFlail; }
      else if(category === 'ウォーハンマー') { dmgBase += bonusStr + masteryHammer; }
      else if(category === '絡み')           { dmgBase += bonusStr + masteryEntangle; }
      else if(category === '格闘')           { dmgBase += bonusStr + masteryGrapple; }
      else if(category === '投擲')           { dmgBase += bonusStr + masteryThrow; }
      else if(category === 'ボウ')           { dmgBase += bonusStr + masteryBow; }
      else if(category === 'クロスボウ')     { dmgBase += masteryCrossbow; }
      else if(category === 'ブロウガン')     { dmgBase += bonusStr + masteryBlowGun; }
      else if(category === 'ガン')           { dmgBase += lvMag + masteryGun; }
      else  { dmgBase += bonusStr; }
    }
    
    if(classes){
      document.getElementById("weapon"+i+"-acc-total").innerHTML = accBase + Number(form["weapon"+i+"Acc"].value);
      document.getElementById("weapon"+i+"-dmg-total").innerHTML = dmgBase + Number(form["weapon"+i+"Dmg"].value);
    }
    else {
      document.getElementById("weapon"+i+"-acc-total").innerHTML = Number(form["weapon"+i+"Acc"].value);
      document.getElementById("weapon"+i+"-dmg-total").innerHTML = Number(form["weapon"+i+"Dmg"].value);
    }
  }
  document.getElementById("attack-sword-mastery").style.display    = masterySword     ? '' : 'none';
  document.getElementById("attack-axe-mastery").style.display      = masteryAxe       ? '' : 'none';
  document.getElementById("attack-spear-mastery").style.display    = masterySpear     ? '' : 'none';
  document.getElementById("attack-mace-mastery").style.display     = masteryMace      ? '' : 'none';
  document.getElementById("attack-staff-mastery").style.display    = masteryStaff     ? '' : 'none';
  document.getElementById("attack-flail-mastery").style.display    = masteryFlail     ? '' : 'none';
  document.getElementById("attack-hammer-mastery").style.display   = masteryHammer    ? '' : 'none';
  document.getElementById("attack-entangle-mastery").style.display = masteryEntangle  ? '' : 'none';
  document.getElementById("attack-grapple-mastery").style.display  = masteryGrapple   ? '' : 'none';
  document.getElementById("attack-throw-mastery").style.display    = masteryThrow     ? '' : 'none';
  document.getElementById("attack-bow-mastery").style.display      = masteryBow       ? '' : 'none';
  document.getElementById("attack-crossbow-mastery").style.display = masteryCrossbow  ? '' : 'none';
  document.getElementById("attack-blowgun-mastery").style.display  = masteryBlowGun   ? '' : 'none';
  document.getElementById("attack-gun-mastery").style.display      = masteryGun       ? '' : 'none';
}

// 防御計算 //
function calcDefense() {
  let classes = form.evasionClass.options[form.evasionClass.selectedIndex].value;
  let evaClassLv = 0;
  let evaBase = 0;
  let defBase = 0;
       if(classes === "ファイター")   { evaClassLv = lvFig; }
  else if(classes === "グラップラー") { evaClassLv = lvGra; }
  else if(classes === "フェンサー")   { evaClassLv = lvFen; }
  else if(classes === "シューター" && shootersMartialArts)   { evaClassLv = lvSho; }
  else { evaClassLv = 0; }
  evaBase = evaClassLv ? (evaClassLv + bonusAgi) : 0;
  
  const reqdStr = sttStr + sttAddC;
  document.getElementById("evasion-str").innerHTML = (classes === "フェンサー") ? Math.ceil(reqdStr / 2) : reqdStr;
  document.getElementById("evasion-eva").innerHTML = evaBase;
  // 種族特徴
  defBase += raceAbilityDef;
  document.getElementById("race-ability-def").style.display = raceAbilityDef > 0 ? "" :"none";
  document.getElementById("race-ability-def-value").innerHTML  = raceAbilityDef;
  // 習熟
  document.getElementById("mastery-metalarmour").style.display    = masteryMetalArmour    > 0 ? "" :"none";
  document.getElementById("mastery-nonmetalarmour").style.display = masteryNonMetalArmour > 0 ? "" :"none";
  document.getElementById("mastery-shield").style.display         = masteryShield         > 0 ? "" :"none";
  document.getElementById("mastery-metalarmour-value").innerHTML    = masteryMetalArmour;
  document.getElementById("mastery-nonmetalarmour-value").innerHTML = masteryNonMetalArmour;
  document.getElementById("mastery-shield-value").innerHTML         = masteryShield;
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
  
  document.getElementById("defense-total-all-eva").innerHTML = evaBase + armourEva + shieldEva + otherEva;
  document.getElementById("defense-total-all-def").innerHTML = defBase + armourDef + shieldDef + otherDef;
}

// 経験値計算 //
function calcExp(){
  let expTotal = 0;
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    let exp = Number(eval(form['history'+i+'Exp'].value));
    if(isNaN(exp)){ exp = 0; }
    expTotal += exp;
  }
  document.getElementById("exp-total").innerHTML = expTotal;
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
  
  cell0.innerHTML  = '<input type="text" name="weapon' + num + 'Name">';
  cell1.innerHTML  = '<input type="text" name="weapon' + num + 'Usage">';
  cell2.innerHTML  = '<input type="text" name="weapon' + num + 'Reqd">';
  cell3.innerHTML  = '+<input type="text" name="weapon' + num + 'Acc" oninput="calcWeapon()">=<b id="weapons' + num + '-acc-total"></b>';
  cell4.innerHTML  = '<input type="text" name="weapon' + num + 'Rate">';
  cell5.innerHTML  = '<input type="text" name="weapon' + num + 'Crit">';
  cell6.innerHTML  = '+<input type="text" name="weapon' + num + 'Dmg" oninput="calcWeapon()">=<b id="weapons' + num + '-dmg-total"></b>';
  cell7.innerHTML  = '<input type="checkbox" name="weapon' + num + 'Own" oninput="calcWeapon()">';
  cell8.innerHTML  = '<select id="weapon' + num + '-category" name="weapon' + num + 'Category" oninput="calcWeapon()"><option></select>';
  cell9.innerHTML  = '<select id="weapon' + num + '-class" name="weapon' + num + 'Class" oninput="calcWeapon()"><option><option>ファイター<option>グラップラー<option>フェンサー<option>シューター</select>';
  cell10.innerHTML = '<input type="text" name="weapon' + num + 'Note">';
  
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
  
  cell0.innerHTML  = num;
  cell1.innerHTML  = '<input type="text" name="history' + num + 'Date">';
  cell2.innerHTML  = '<input type="text" name="history' + num + 'Title">';
  cell3.innerHTML  = '<input type="text" name="history' + num + 'Exp">';
  cell4.innerHTML  = '<input type="text" name="history' + num + 'Honor">';
  cell5.innerHTML  = '<input type="text" name="history' + num + 'Money">';
  cell6.innerHTML  = '<input type="text" name="history' + num + 'Grow" list="list-grow">';
  cell7.innerHTML  = '<input type="text" name="history' + num + 'Gm">';
  cell8.innerHTML  = '<input type="text" name="history' + num + 'Member">';
  
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

//  //
function view(viewId){
  let value = document.getElementById(viewId).style.display;
  document.getElementById(viewId).style.display = (value === 'none') ? '' : 'none';
}







