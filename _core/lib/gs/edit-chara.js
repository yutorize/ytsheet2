"use strict";
const gameSystem = 'gb';

window.onload = function() {
  nameSet();
  race = form.race.value;
  originClass = form.careerOriginClass.value;
  coinsBefore = {
    silver: Number(form.money.value),
    gold  : Number(form.moneyGold.value),
    large : Number(form.moneyLargeGold.value),
  };
  calcLv();
  calcExp();
  checkRace();
  calcAbility();
  calcCash();
  calcAdvCompleted();
  openCoins();
  
  imagePosition();
  changeColor();
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.characterName.value === ''){
    alert('キャラクター名を入力してください。');
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
  console.log('changeRegu()');
  document.getElementById("history0-exp").textContent = form.history0Exp.value;
  
  calcExp();
  calcCash();
  calcAdvCompleted();
}

// 種族変更 ----------------------------------------
let race;
let raceV;
let raceB;
let raceBV;
function changeRace(){
  console.log('changeRace()');
  race = form.race.value;
  
  checkRace();
  calcLv();
  calcAbility();
}

// 種族チェック ----------------------------------------
function checkRace(){
  console.log('checkRace()');
  race = race.replace(/:(.+?)$/, (all, variant) => { raceV = variant; return '' })
  
  // 元種族
  if(races[race] && races[race].base){
    const selected = form.raceBase.value;
    form.raceBase.innerHTML = '<option value="">';
    for(const name of races[race].base){
      const newOpt = document.createElement('option');
      newOpt.value = name;
      newOpt.text = name;
      form.raceBase.append(newOpt);
    }
    form.raceBase.value = selected;
    document.getElementById('race-base').classList.remove('hide');
  }
  else {
    form.raceBase.innerHTML = '<option value="">';
    document.getElementById('race-base').classList.add('hide');
  }
  raceB = form.raceBase.value;
  raceB = raceB.replace(/:(.+?)$/, (all, variant) => { raceBV = variant; return '' });

  // 自由記入欄サジェスト
  for(let name of ['race','raceBase']){
    const value = form[name].value;
    const free  = form[name+'Free'];
    if     (value.match(/獣人/)  ){ free.setAttribute('list', 'list-race-padfoots'); }
    else if(value.match(/獣憑き/)){ free.setAttribute('list', 'list-race-beastbind'); }
    else { free.removeAttribute('list') }
  }
}

// 経験点・レベル計算 ----------------------------------------
const adventurerExpTable = {
       0: { lv: 1, pt: 10 },
    4000: { lv: 2, pt: 15 },
    7000: { lv: 3, pt: 15 },
   11000: { lv: 4, pt: 20 },
   16000: { lv: 5, pt: 20 },
   23000: { lv: 6, pt: 25 },
   33000: { lv: 7, pt: 25 },
   47000: { lv: 8, pt: 30 },
   66000: { lv: 9, pt: 30 },
   91000: { lv:10, pt: 35 },
};
const classExpTable = [
      0,
   1000,
   2000,
   3500,
   5500,
   8000,
  11500,
  16500,
  23500,
  33000,
  45500,
];
let level = 0; //冒険者レベル
let expTotal = 0; //経験点
let expUsed = 0;
function calcExp(){
  console.log('calcExp()');
  //合計
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
  // 消費：職業
  expUsed = originClass ? -1000 : 0;
  for(let key in classes){
    expUsed += classExpTable[ Number( lv[ classes[key].id ] ) ];
  }
  // 消費：成長点
  expUsed += Number(form.adpFromExp.value) * 500;

  // 冒険者レベル
  for(let key of Object.keys(adventurerExpTable).sort((a, b) => a - b)){
    if(expTotal >= key) { level = adventurerExpTable[key].lv; }
    else { break; }
  }
  
  document.getElementById("exp-used").textContent = commify(expUsed);
  document.getElementById("exp-rest").textContent = commify(expTotal - expUsed);
  document.getElementById("exp-total").textContent = commify(expTotal);
  document.getElementById("history-exp-total").textContent = commify(expTotal);
  
  document.getElementById("level-value").textContent = level;

  calcAdp();
}
// 成長点計算 ----------------------------------------
const gradeToPtA = {
  '初歩': 5,
  '習熟': 15,
  '熟練': 30,
  '達人': 55,
  '伝説': 95,
};
const gradeToPtG = {
  '初歩':  1,
  '習熟':  6,
  '熟練': 21,
};
let adpTotal = 0; //成長点
function calcAdp(){
  console.log('calcAdp()');
  // 合計
  adpTotal = Number(form.adpFromExp.value);
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    const obj = form['history'+i+'Adp'];
    let adp = safeEval(obj.value);
    if(isNaN(adp)){
      obj.classList.add('error');
    }
    else {
      adpTotal += adp;
      obj.classList.remove('error');
    }
  }
  for(let key of Object.keys(adventurerExpTable).sort((a, b) => a - b)){
    if(expTotal >= key) { adpTotal += adventurerExpTable[key].pt; }
    else { break; }
  }

  // 消費
  let adpUsed = 0;
  for (let i = 1; i <= form.skillNum.value; i++){
    const grade = form[`skill${i}Grade`].value;
    let point = 0;
    if(grade){
      point = gradeToPtA[grade];
      if(form[`skill${i}Auto`].checked){ point -= 5 }
      adpUsed += point;
    }
    document.querySelector(`#skill${i} .adp`).textContent = point;
  }
  for (let i = 1; i <= form.generalSkillNum.value; i++){
    const grade = form[`generalSkill${i}Grade`].value;
    let point = 0;
    if(grade){
      point = gradeToPtG[grade];
      if(form[`generalSkill${i}Auto`].checked){ point -= 1 }
      adpUsed += point;
    }
    document.querySelector(`#general-skill${i} .adp`).textContent = point;
  }

  const adpRest = adpTotal - adpUsed;
  document.getElementById("adp-used" ).textContent = adpUsed;
  document.getElementById("adp-rest" ).textContent = adpRest;
  document.getElementById("adp-total").textContent = adpTotal;
  document.querySelector(`#skills .adp-rest`).textContent = adpRest;
  document.querySelector(`#general-skills .adp-rest`).textContent = adpRest;
}

// 職業レベル変更 ----------------------------------------
function changeLv() {
  console.log('changeLv()');
  calcLv();
  calcExp();
  calcAttack();
}

// 初期習得職業チェック ----------------------------------------
let originClass;
function changeOriginClass() {
  console.log('changeOriginClass()');
  originClass = form.careerOriginClass.value;
  if(originClass && expUsed <= 1000){
    for(let key in classes){
      form['lv'+classes[key].id].value = '';
    }
    form['lv'+classes[originClass].id].value = 1
  }
  
  calcLv();
}

// 職業レベル計算 ----------------------------------------
let lv = {};
function calcLv(){
  console.log('calcLv()');
  for(let key in classes){
    const id = classes[key].id;
    lv[id] = Number(form['lv'+id].value || 0);
    form['lv'+id].classList.remove('error');
  }
  
  if (originClass && !lv[classes[originClass].id]){
    form['lv'+classes[originClass].id].classList.add('error');
  }
  
  document.getElementById("level-value").textContent = level;
}

// 能力値計算 ----------------------------------------
let abilityScore = {};
function calcAbility() {
  console.log('calcAbility()');
  for(const primary of ['Str','Psy','Tec','Int']){
    abilityScore[primary] =
    + Number(form[`ability1${primary}Base`].value || 0)
    + Number(form[`ability1${primary}Mod` ].value || 0)
    + (form.ability1Bonus.value == primary ? 1 : 0)
  }
  for(const secondary of ['Foc','Edu','Ref']){
    abilityScore[secondary] =
    + Number(form[`ability2${secondary}Base`].value || 0)
    + Number(form[`ability2${secondary}Mod` ].value || 0)

    for(const primary of ['Str','Psy','Tec','Int']){
      document.getElementById(`ability-value-${primary}${secondary}`).textContent
        = abilityScore[`${primary}${secondary}`]
        = abilityScore[primary] + abilityScore[secondary]
    }
  }
  calcStatus();
  calcAttack();
  calcDodge();
}
// 状態計算 ----------------------------------------
let statusScore = {};
function calcStatus() {
  console.log('calcStatus()');
  // 生命力
  statusScore.life = Number(form.statusLifeDice.value) + abilityScore.Str + abilityScore.Psy + abilityScore.Edu + Number(form.statusLifeMod.value);
  document.getElementById('status-life-str').textContent = abilityScore.Str;
  document.getElementById('status-life-psy').textContent = abilityScore.Psy;
  document.getElementById('status-life-edu').textContent = abilityScore.Edu;
  document.getElementById('status-life-total').textContent = statusScore.life;
  document.getElementById('status-life-twice').textContent = statusScore.life *2 ;

  // 移動力
  let moveModRace
    = (race && races[race].move == 'base' && raceB && races[raceB].move == 'variant') ? (raceBV ? races[raceB].variantData[raceBV].move : 0)
    : (race && races[race].move == 'base'   ) ? (raceB ? races[raceB].move : 0)
    : (race && races[race].move == 'variant') ? (raceV ? races[race].variantData[raceV].move : 0)
    : (race) ? races[race].move 
    : 0;
  statusScore.move = Number(form.statusMoveDice.value) * moveModRace + Number(form.statusMoveMod.value);
  document.getElementById('status-move-race').textContent = moveModRace;
  document.getElementById('status-move-total').textContent = statusScore.move;

  // 呪文使用回数
  let spellDice = Number(form.statusSpellDice.value);
  statusScore.spell = (spellDice >= 12) ? 3
                    : (spellDice >= 10) ? 2
                    : (spellDice >=  7) ? 1
                    : 0;
  statusScore.spell += Number(form.statusSpellMod.value);
  document.getElementById('status-spell-total').textContent = statusScore.spell;
  
  // 呪文抵抗基準値
  statusScore.resist = abilityScore.PsyRef + Number(form.statusResistMod.value) + level;
  document.getElementById('status-resist-psyref').textContent = abilityScore.PsyRef;
  document.getElementById('status-resist-level').textContent = level;
  document.getElementById('status-resist-total').textContent = statusScore.resist;
}

// 攻撃計算 ----------------------------------------
function calcAttack() {
  console.log('calcAttack()');
  let hasAttackClass = 0;
  for(const name in classes){
    if (!classes[name].type.match(/warrior/)){ continue }
    const level = lv[classes[name].id];
    if (level > 0) { hasAttackClass++; }
    const eName = classes[name].eName;
    document.getElementById(`attack-${eName}`).style.display = level > 0 ? "" :"none";
    document.getElementById(`attack-${eName}-level`).textContent = level
    
    for(const type of ['Melee','Throwing','Projectile']){
      document.getElementById(`attack-${eName}-${type.toLowerCase()}`).textContent
        = (classes[name].proper.hitscore.includes(type)) ? level + abilityScore.TecFoc + Number(form['hitScoreMod'+type].value)
        : '―'
    }
  }
  document.getElementById("attack-ability-value").textContent = abilityScore.TecFoc;
  document.getElementById("attack-class-head-row").style.display = hasAttackClass ? '' : 'none';
  calcWeapon();
}
function calcWeapon() {
  console.log('calcWeapon()');
  for (let num = 1; num <= form.weaponNum.value; num++){
    const category = form[`weapon${num}Type`].value;
    const weight   = form[`weapon${num}Weight`].value;
    const type     = weaponType[category];
    const className = form[`weapon${num}Class`].value;
    const classId = className ? classes[className].id : null;

    form[`weapon${num}Type`  ].classList.remove('error');
    form[`weapon${num}Weight`].classList.remove('error');
    form[`weapon${num}Class` ].classList.remove('error');

    // 種別
    if(classId && !classes[className].proper.weapon.includes(category)){
      form[`weapon${num}Type` ].classList.add('error');
      form[`weapon${num}Class`].classList.add('error');
    }
    if(classId && !classes[className].proper.weight.includes(weight)){
      form[`weapon${num}Weight`].classList.add('error');
      form[`weapon${num}Class` ].classList.add('error');
    }

    // 命中
    let hitScore = abilityScore.TecFoc || 0;
    if(category){ hitScore += Number(form['hitScoreMod'+type].value) }
    if(classId ){ hitScore += lv[classId] }
    hitScore += Number(form[`weapon${num}HitMod`].value);

    document.getElementById(`weapon${num}-hit-total`).textContent = hitScore;

    // 威力
    document.getElementById(`weapon${num}-power-lv`).textContent = classId ? lv[classId] : 0;
  }
}

function calcDodge() {
  console.log('calcDodge()');
  document.getElementById('dodge-base-value').textContent = abilityScore.TecRef;
  document.getElementById('dodge-move-base-value').textContent = statusScore.move;

  const className = form.dodgeClass.value;
  const classId = className ? classes[className].id : null;
  document.getElementById('dodge-class-value').textContent = lv[classId] ?? '―';
  

  let dodgeScore = abilityScore.TecRef + Number(form.dodgeModValue.value);
  if(className){ dodgeScore += lv[classId] }
  let MoveScore = statusScore.move + Number(form.MoveModValue.value);

  form.dodgeClass.classList.remove('error');
  {
    const num = 1;
    // 種別
    const category = form[`armor${num}Type`].value;
    const weight   = form[`armor${num}Weight`].value;

    form[`armor${num}Type`  ].classList.remove('error');
    form[`armor${num}Weight`].classList.remove('error');

    if(classId && classes[className].type.includes('dodge')){
      if(classId && !classes[className].proper.armor.includes(category) && classes[className].proper.armor != 'すべて'){
        form[`armor${num}Type`].classList.add('error');
        form.dodgeClass.classList.add('error');
      }
      if(classId && !classes[className].proper.weight.includes(weight)){
        form[`armor${num}Weight`].classList.add('error');
        form.dodgeClass.classList.add('error');
      }
    }
    // 数値
    document.getElementById(`armor${num}-dodge-total`).textContent = dodgeScore + Number(form[`armor${num}DodgeMod`].value);
    document.getElementById(`armor${num}-move-total` ).textContent = MoveScore + Number(form[`armor${num}MoveMod`].value);
  }

  calcBlock();
}

function calcBlock() {
  console.log('calcBlock()');
  document.getElementById('block-base-value').textContent = abilityScore.TecRef;

  const className = form.blockClass.value;
  const classId = className ? classes[className].id : null;
  document.getElementById('block-class-value').textContent = lv[classId] ?? '―';
  
  let blockScore = abilityScore.TecRef + Number(form.dodgeModValue.value);
  if(className){ blockScore += lv[classId] }

  form.blockClass.classList.remove('error');
  {
    const num = 1;
    // 種別
    const category = form[`shield${num}Type`].value;
    const weight   = form[`shield${num}Weight`].value;

    form[`shield${num}Type`  ].classList.remove('error');
    form[`shield${num}Weight`].classList.remove('error');

    if(classId && classes[className].type.includes('block')){
      if(classId && !classes[className].proper.shield.includes(category) && classes[className].proper.shield != 'すべて'){
        form[`shield${num}Type`].classList.add('error');
        form.blockClass.classList.add('error');
      }
      if(classId && !classes[className].proper.weight.includes(weight)){
        form[`shield${num}Weight`].classList.add('error');
        form.blockClass.classList.add('error');
      }
    }
    // 数値
    document.getElementById(`shield${num}-block-total`).textContent = blockScore + Number(form[`shield${num}BlockMod`].value);

    let armorScore = Number(form.armor1Armor.value);
    document.getElementById(`shield${num}-armor-base`).textContent = armorScore;
    armorScore += Number(form[`shield${num}Armor`].value);
    document.getElementById(`shield${num}-armor-total`).textContent = armorScore;
  }
}

// 収支履歴計算 ----------------------------------------
let cash = 0;
function calcCash(){
  console.log('calcCash()');
  cash = 0;
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
    form.moneyGold.type = form.moneyLargeGold.type = 'number';
  }
  else {
    form.money.readOnly = false;
    form.moneyGold.type = form.moneyLargeGold.type = 'text'
  }

  if(form.depositAuto.checked){
    form.deposit.value = commify(deposit)+'／'+commify(debt);
    form.deposit.readOnly = true;
  }
  else { form.deposit.readOnly = false; }

  calcCoins();
}
function openCoins(){
  let isOpen = form.moneyAllCoins.checked;
  document.getElementById('money-coins').classList.toggle('full-open', isOpen);
  calcCoins();
}
let coinsBefore = {}
function calcCoins(){
  if(!form.moneyAuto.checked){ return }
  let gold   = Number(form.moneyGold.value);
  let large  = Number(form.moneyLargeGold.value);
  if(!form.moneyAllCoins.checked){ gold = large = 0; }

  if(cash - gold*10 - large*100 < 0){
    form.money.value          = coinsBefore.silver;
    form.moneyGold.value      = coinsBefore.gold;
    form.moneyLargeGold.value = coinsBefore.large;
  }
  else {
    coinsBefore.silver = cash - gold*10 - large*100;
    coinsBefore.gold   = gold;
    coinsBefore.large  = large;
    form.money.value = commify(coinsBefore.silver);
  }
}

// 冒険者技能計算 ----------------------------------------
function calcAdvCompleted(){
  console.log('calcAdvCompleted()');
  let adv  = Number(form.history0Adventures.value);
  let comp = Number(form.history0Completed.value );
  document.getElementById('history0-comp').textContent = `${adv}／${comp}`;
  for (let i = 1; i <= form.historyNum.value; i++){
    const value = Number(form[`history${i}Completed`].value);
    if     (value > 0){ adv++; comp++; }
    else if(value < 0){ adv++; }
  }
  document.getElementById('history-comp-total').textContent = `${adv}／${comp}`;
  document.getElementById('adventures-value').textContent = adv;
  document.getElementById('adventures-complete-value').textContent = comp;
}

// 武器欄 ----------------------------------------
// 追加
function addWeapons(copy){
  let num = Number(form.weaponNum.value) + 1;

  let row = document.querySelector('#weapon-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('weapons-row');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#weapons-table").append(row);
  
  if(copy){
    form[`weapon${num}Name`    ].value = form[`weapon${copy}Name`    ].value;
    form[`weapon${num}Type`    ].value = form[`weapon${copy}Type`    ].value;
    form[`weapon${num}Weight`  ].value = form[`weapon${copy}Weight`  ].value;
    form[`weapon${num}Usage`   ].value = form[`weapon${copy}Usage`   ].value;
    form[`weapon${num}Attr`    ].value = form[`weapon${copy}Attr`    ].value;
    form[`weapon${num}HitMod`  ].value = form[`weapon${copy}HitMod`  ].value;
    form[`weapon${num}Power`   ].value = form[`weapon${copy}Power`   ].value;
    form[`weapon${num}PowerMod`].value = form[`weapon${copy}PowerMod`].value;
    form[`weapon${num}Range`   ].value = form[`weapon${copy}Range`   ].value;
    form[`weapon${num}Class`   ].value = form[`weapon${copy}Class`   ].value;
    form[`weapon${num}Note`    ].value = form[`weapon${copy}Note`    ].value;
    calcWeapon();
  }
  
  form.weaponNum.value = num;
}
// 削除
function delWeapons(){
  let num = Number(form.weaponNum.value);
  if(num > 1){
    if ( form[`weapon${num}Name`    ].value
      || form[`weapon${num}Type`    ].value
      || form[`weapon${num}Weight`  ].value
      || form[`weapon${num}Usage`   ].value
      || form[`weapon${num}Attr`    ].value
      || form[`weapon${num}HitMod`  ].value
      || form[`weapon${num}Power`   ].value
      || form[`weapon${num}PowerMod`].value
      || form[`weapon${num}Range`   ].value
      || form[`weapon${num}Note`    ].value
    ){
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
        document.querySelector(`#${id} [name$="Type"]`    ).setAttribute('name',`weapon${num}Type`);
        document.querySelector(`#${id} [name$="Usage"]`   ).setAttribute('name',`weapon${num}Usage`);
        document.querySelector(`#${id} [name$="Weight"]`  ).setAttribute('name',`weapon${num}Weight`);
        document.querySelector(`#${id} [name$="Attr"]`    ).setAttribute('name',`weapon${num}Attr`);
        document.querySelector(`#${id} [name$="HitMod"]`  ).setAttribute('name',`weapon${num}HitMod`);
        document.querySelector(`#${id} [name$="Power"]`   ).setAttribute('name',`weapon${num}Power`);
        document.querySelector(`#${id} [name$="PowerMod"]`).setAttribute('name',`weapon${num}PowerMod`);
        document.querySelector(`#${id} [name$="Range"]`   ).setAttribute('name',`weapon${num}Range`);
        document.querySelector(`#${id} [name$="Class"]`   ).setAttribute('name',`weapon${num}Class`);
        document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`weapon${num}Note`);
        document.querySelector(`#${id} span[onclick]`     ).setAttribute('onclick',`addWeapons(${num})`);
        document.querySelector(`#${id} b[id$=hit-total]`).id = `weapon${num}-hit-total`;
        document.querySelector(`#${id} b[id$=power-lv]` ).id = `weapon${num}-power-lv`;
        num++;
      }
    }
  }
});


// 冒険者技能欄 ----------------------------------------
// 追加
function addSkill(){
  let num = Number(form.skillNum.value) + 1;

  let row = document.querySelector('#skill-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('skill');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#skills-table tbody").append(row);
  
  form.skillNum.value = num;
}
// 削除
function delSkill(){
  let num = Number(form.skillNum.value);
  if(num > 1){
    if ( form[`skill${num}Name`].value
      || form[`skill${num}Auto`].checked
      || form[`skill${num}Grade`].value
      || form[`skill${num}Note`].value
      || form[`skill${num}Page`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#skills-table tbody tr:last-of-type").remove();
    num--;
    form.skillNum.value = num;
  }
}
// ソート
let skillsSortable = Sortable.create(document.querySelector("#skills-table tbody"), {
  group: "skills",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = skillsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Auto"]` ).setAttribute('name',`skill${num}Auto`);
        document.querySelector(`#${id} [name$="Name"]` ).setAttribute('name',`skill${num}Name`);
        document.querySelector(`#${id} [name$="Grade"]`).setAttribute('name',`skill${num}Grade`);
        document.querySelector(`#${id} [name$="Note"]` ).setAttribute('name',`skill${num}Note`);
        document.querySelector(`#${id} [name$="Page"]` ).setAttribute('name',`skill${num}Page`);
        num++;
      }
    }
  }
});
// 一般技能欄 ----------------------------------------
// 追加
function addGeneralSkill(){
  let num = Number(form.generalSkillNum.value) + 1;

  let row = document.querySelector('#general-skill-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('general-skill');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#general-skills-table tbody").append(row);
  
  form.generalSkillNum.value = num;
}
// 削除
function delGeneralSkill(){
  let num = Number(form.generalSkillNum.value);
  if(num > 1){
    if ( form[`generalSkill${num}Name`].value
      || form[`generalSkill${num}Auto`].checked
      || form[`generalSkill${num}Grade`].value
      || form[`generalSkill${num}Note`].value
      || form[`generalSkill${num}Page`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#general-skills-table tbody tr:last-of-type").remove();
    num--;
    form.generalSkillNum.value = num;
  }
}
// ソート
let generalSkillsSortable = Sortable.create(document.querySelector("#general-skills-table tbody"), {
  group: "g-skills",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = generalSkillsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Auto"]` ).setAttribute('name',`generalSkill${num}Auto`);
        document.querySelector(`#${id} [name$="Name"]` ).setAttribute('name',`generalSkill${num}Name`);
        document.querySelector(`#${id} [name$="Grade"]`).setAttribute('name',`generalSkill${num}Grade`);
        document.querySelector(`#${id} [name$="Note"]` ).setAttribute('name',`generalSkill${num}Note`);
        document.querySelector(`#${id} [name$="Page"]` ).setAttribute('name',`generalSkill${num}Page`);
        num++;
      }
    }
  }
});


// 呪文 ----------------------------------------
// 追加
function addSpell(){
  let num = Number(form.spellNum.value) + 1;

  let row = document.querySelector('#spell-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('spell');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#spells-table tbody").append(row);
  
  for(const name in classes){
    if (!classes[name].magic){ continue }
    let op = document.createElement("option");
    op.text = classes[name].magic;
    form["spell"+num+"System"].appendChild(op);
  }
  form.spellNum.value = num;
}
// 削除
function delSpell(){
  let num = Number(form.spellNum.value);
  if(num > 1){
    if ( form[`spell${num}Name`].value
      || form[`spell${num}System`].value
      || form[`spell${num}Type`].value
      || form[`spell${num}Attr`].value
      || form[`spell${num}Dfclt`].value
      || form[`spell${num}Note`].value
      || form[`spell${num}Ref`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#spells-table tbody tr:last-of-type").remove();
    num--;
    form.spellNum.value = num;
  }
}
// ソート
let spellsSortable = Sortable.create(document.querySelector("#spells-table tbody"), {
  group: "spells",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = spellsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`  ).setAttribute('name',`spell${num}Name`);
        document.querySelector(`#${id} [name$="System"]`).setAttribute('name',`spell${num}System`);
        document.querySelector(`#${id} [name$="Type"]`  ).setAttribute('name',`spell${num}Type`);
        document.querySelector(`#${id} [name$="Attr"]`  ).setAttribute('name',`spell${num}Attr`);
        document.querySelector(`#${id} [name$="Dfclt"]` ).setAttribute('name',`spell${num}Dfclt`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`spell${num}Note`);
        document.querySelector(`#${id} [name$="Page"]`  ).setAttribute('name',`spell${num}Page`);
        num++;
      }
    }
  }
});


// 武技 ----------------------------------------
// 追加
function addArts(){
  let num = Number(form.artsNum.value) + 1;

  let row = document.querySelector('#arts-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('arts');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#arts-table").append(row);

  form.artsNum.value = num;
}
// 削除
function delArts(){
  let num = Number(form.artsNum.value);
  if(num > 1){
    if ( form[`arts${num}Name`].value
      || form[`arts${num}Weapon`].value
      || form[`arts${num}Skill`].value
      || form[`arts${num}Cost`].value
      || form[`arts${num}Terms`].value
      || form[`arts${num}Ref`].value
      || form[`arts${num}Note`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#arts-table tbody:last-of-type").remove();
    num--;
    form.artsNum.value = num;
  }
}
// ソート
let artsSortable = Sortable.create(document.querySelector("#arts-table"), {
  group: "spells",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = artsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tbody#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`  ).setAttribute('name',`arts${num}Name`);
        document.querySelector(`#${id} [name$="Weapon"]`).setAttribute('name',`arts${num}Weapon`);
        document.querySelector(`#${id} [name$="Skill"]` ).setAttribute('name',`arts${num}Skill`);
        document.querySelector(`#${id} [name$="Cost"]`  ).setAttribute('name',`arts${num}Cost`);
        document.querySelector(`#${id} [name$="Terms"]` ).setAttribute('name',`arts${num}Terms`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`arts${num}Note`);
        document.querySelector(`#${id} [name$="Page"]`  ).setAttribute('name',`arts${num}Page`);
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
  document.querySelector("#history-table").append(row);

  document.querySelector("#history-table tbody:last-of-type").after(row);
  
  form.historyNum.value = num;
}
// 削除
function delHistory(){
  let num = Number(form.historyNum.value);
  if(num > 1){
    if ( form[`history${num}Date`].value
      || form[`history${num}Title`].value
      || form[`history${num}Exp`].value
      || form[`history${num}Money`].value
      || form[`history${num}Gm`].value
      || form[`history${num}Member`].value
      || form[`history${num}Note`].value
    ){
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
        document.querySelector(`#${id} [name$="Money"]` ).setAttribute('name',`history${num}Money`);
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
        num++;
      }
    }
  }
});
