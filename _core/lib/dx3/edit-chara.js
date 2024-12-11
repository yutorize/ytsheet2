"use strict";
const gameSystem = 'dx3';

let exps = {};
let status = {};
let syndromes = [];
// ----------------------------------------
window.onload = function() {
  console.log('=====START=====');
  syndromes = [form.syndrome1.value, form.syndrome2.value, form.syndrome3.value];
  
  setName();
  checkCreateType();
  checkStage();
  checkWorks();
  checkSyndrome();
  calcStt();
  calcEffect();
  calcMagic();
  calcItem();
  calcMemory();
  refreshByImpulse();
  for(let i = 1; i <= 7; i++){ changeLoisColor(i); }
  imagePosition();
  changeColor();
  console.log('=====LOADED=====');
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.characterName.value === '' && form.aka.value === ''){
    alert('キャラクター名かコードネームのいずれかを入力してください。');
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
let createType = 'F';
function changeCreateType(){
  checkCreateType();
  if(createType === 'C'){
    if(!form['effect3Name']){
      addEffect();
    }
    if(!form['effect3Name'].value || form['effect3Name'].value.match(/^コンセントレイト/)){
      form['effect3Name'].value ||= 'コンセントレイト：'
      form['effect3Type'].value = 'auto';
      form['effect3Lv'].value = 2;
      form['effect3Timing'].value = 'メジャー';
      form['effect3Skill'].value = 'シンドローム';
      form['effect3Dfclty'].value = '―';
      form['effect3Range'].value = '―';
      form['effect3Target'].value = '―';
      form['effect3Encroach'].value = 2;
      form['effect3Restrict'].value = '―';
      form['effect3Note'].value ||= 'クリティカル値を-LV（下限値7）';
    }
  }
  else {
    if(form['effect3Name'].value.match(/^コンセントレイト/)){
      confirm('作成方法をフルスクラッチに切り替えます。\n入力済みの《コンセントレイト：～》が自動習得でなくなります。');
      form['effect3Type'].value = '';
    }
  }
  calcStt();
  calcEffect();
}
function checkCreateType(){
  document.body.dataset.createType = createType = form.createType.value;
}
function changeRegu(){
  document.getElementById("history0-exp").textContent = form.history0Exp.value;
  calcExp();
}

// ステージチェック ----------------------------------------
function checkStage(){
  document.body.classList.toggle('mode-crc', form.stage.value.match('クロウリングケイオス'));
  calcMagic();
}
// ワークス ----------------------------------------
function checkWorks() {
  document.getElementById('encounter-or-desire').textContent = /[FＦ][HＨ]/i.test(form.works.value) ? '欲望' : '邂逅';
}
// シンドローム変更 ----------------------------------------
function changeSyndrome(num,syn){
  syndromes[num-1] = syn;
  checkSyndrome();
  calcStt();
}
function checkSyndrome(){
  const syn1 = syndromes[0];
  const syn2 = syndromes[1];
  const syn3 = syndromes[2];

  document.getElementById('breed-value').textContent = syn3 ? 'トライ' : syn2 ? 'クロス' : syn1 ? 'ピュア' : '';
  
  form.syndrome1.parentNode.classList.toggle('error', !syn1 && (syn2 || syn3));
  form.syndrome2.parentNode.classList.toggle('error', !syn2 && syn3);
  form.syndrome1.closest('tr').classList.toggle('pure', syn1 && !syn2);
}

// ステータス計算 ----------------------------------------
function calcStt() {
  const syn1 = syndromes[0];
  const syn2 = syndromes[1];
  
  exps['status'] = 0;

  const isAuto1 = synStats[syn1] ? true : syn1 ? false : true;
  const isAuto2 = synStats[syn2] ? true : syn2 ? false : true;
  document.querySelector('.syndrome-rows tr:nth-child(1)').classList.toggle('auto', isAuto1);
  document.querySelector('.syndrome-rows tr:nth-child(2)').classList.toggle('auto', isAuto2);
  
  let free = 0;
  for (let stt of ['body','sense','mind','social']){
    const Stt = stt.slice(0,1).toUpperCase()+stt.slice(1);

    let base1; let base2;
    document.getElementById("stt-syn1-"+stt).innerHTML = base1 = isAuto1 ? synStats[syn1]?.[stt] ?? '' : Number(form['sttSyn1'+Stt].value);
    document.getElementById("stt-syn2-"+stt).innerHTML = base2 = isAuto2 ? synStats[syn2]?.[stt] ?? '' : Number(form['sttSyn2'+Stt].value);

    let base = 0;
    base += syn1 ? base1 : 0;
    base += syn2 ? base2 : syn1 ? base1 : 0;
    if(stt == form.sttWorks.value) { base += 1; }
    const grow = Number(form["sttGrow"+Stt].value);
    const add  = Number(form["sttAdd" +Stt].value);
    status[stt] = base + grow + add;
    free += grow;
    
    document.getElementById('stt-total-'+stt).textContent = status[stt];
    document.getElementById('skill-'+stt).textContent = status[stt];
    
    // 経験点
    for(let i = base; i < base+grow; i++){
      exps['status'] += (i > 20) ? 30 : (i > 10) ? 20 : 10;
    }

    // 能力値0の場合のエラー
    document.getElementById('stt-total-'+stt).classList.toggle('error', syn1 && !status[stt]);
  }

  if(createType === 'C'){
    if(exps['status'] <= 30) { exps['status'] = 0 }
    else { exps['status'] -= 30 }
  }
  document.getElementById('freepoint-status').textContent = (free > 3) ? 3 : free;
  document.getElementById('exp-status'      ).textContent = exps['status'];
  document.getElementById('exp-used-status' ).textContent = exps['status'];
  calcSubStt();
  calcSkill();
}
// サブステータス
function calcSubStt() {
  calcMaxHp();
  calcInitiative();
  calcStock();
  calcMagicDice();
}
let maxHp = 0;
function calcMaxHp(){
  maxHp = status['body'] * 2 + status['mind'] + 20 + Number(form.maxHpAdd.value);
  document.getElementById('max-hp-total').textContent = maxHp;
}
let initiative = 0;
function calcInitiative(){
  initiative = status['sense'] * 2 + status['mind'] + Number(form.initiativeAdd.value);
  document.getElementById('initiative-total').textContent = initiative;
  calcMove();
}
let move = 0;
function calcMove(){
  move = initiative + 5 + Number(form.moveAdd.value);
  document.getElementById('move-total').textContent = move;
  document.getElementById('dash-total').textContent = move * 2;
}
let stock = 0;
let stockUsed = 0;
function calcStock(){
  stock = status['social'] * 2 + (Number(form.skillProcure.value)+Number(form.skillAddProcure.value)) * 2 + Number(form.stockAdd.value);
  document.getElementById('stock-total').textContent = stock;
  document.getElementById("item-max-stock").textContent = stock;
  calcSaving();
}
function calcSaving(){
  document.getElementById('saving-total').textContent = stock - stockUsed + Number(form.savingAdd.value);
}
let magicDice = 0;
function calcMagicDice(){
  magicDice = Math.ceil(status['mind'] + Number(form.skillWill.value)+Number(form.skillAddWill.value) / 2) + Number(form.magicAdd.value);
  document.getElementById('magic-total').textContent = magicDice;
}
// 技能
const skillNameToId = {
  '白兵': 'Melee'    ,
  '射撃': 'Ranged'   ,
  'RC'  : 'RC'       ,  
  '交渉': 'Negotiate',
  '回避': 'Dodge'    ,
  '知覚': 'Percept'  ,
  '意志': 'Will'     ,
  '調達': 'Procure'  ,
}
let skillData = {};
function calcSkill() {
  exps['skill'] = -9;
  for (let name of ['Melee','Ranged','RC','Negotiate','Dodge','Percept','Will','Procure']){
    const lv = Number(form['skill'+name].value);
    for(let i = 0; i < lv; i++){ exps['skill'] += (i > 20) ? 10 : (i > 10) ? 5 : (i > 5) ? 3 : 2; }
  }
  for (let name of ['Ride','Art','Know','Info']){
    for (let num = 1; num <= Number(form[`skill${name}Num`].value); num++){
      const lv = Number(form['skill'+name+num].value);
      for(let i = 0; i < lv; i++){ exps['skill'] += (i > 20) ? 10 : (i > 10) ? 5 : (i > 5) ? 3 : 1; }
      skillNameToId[form['skill'+name+num+'Name'].value] = name+num;
    }
  }
  const free = exps['skill'] / 2;
  if(createType === 'C'){
    if(exps['skill']  <= 10) { exps['skill']  = 0 }
    else { exps['skill']  -= 10 }
  }
  document.getElementById('freepoint-skill').textContent = (free > 5) ? 5 : free;

  for(let name of ['exp-skill','exp-used-skill']){
    const elm = document.getElementById(name);
    elm.textContent = exps['skill'];
    elm.classList.toggle('minus', exps['skill'] < 0);
  }

  calcExp();
  calcComboAll();
}
// エフェクト
function calcEffect() {
  exps['effect'] = 0;
  let free = 0;

  for (let num = 1; num <= Number(form.effectNum.value); num++){
    const type = form['effect'+num+'Type'].value;
    const lv = Number(form['effect'+num+'Lv'].value);
    if(lv >= 1){
      //イージー
      if(type == 'easy'){
        exps['effect'] += lv * 2;
      }
      //通常
      else {
        exps['effect'] += lv * 5 + 10; //lv×5 + 新規取得の差分10

        //自動かDロイスは新規取得ぶん減らす
        if(type.match(/^(auto|dlois)$/i)){
          exps['effect'] += -15;
          //コンストラクションのコンセントレイトは2LVのぶんも減らす
          if(createType === 'C' && form['effect'+num+'Name'].value.match(/^コンセントレイト/) && lv >= 2){
            exps['effect'] += -5;
          }
        }
        else{
          free++; //任意習得エフェクトの数（コンストラクション用）
        }
        form['effect'+num+'Type'].style.backgroundColor = '';
      }
    }
    exps['effect'] += Number(form['effect'+num+'Exp'].value)
    const bg = form['effect'+num+'Name'].parentNode.parentNode.parentNode.style;
    if     (type == 'easy') { bg.backgroundImage = 'linear-gradient(to right,hsla(120,100%, 50%,0.2),transparent)'; }
    else if(type == 'auto') { bg.backgroundImage = 'linear-gradient(to right,hsla(200,100%, 50%,0.2),transparent)'; }
    else if(type == 'dlois'){ bg.backgroundImage = 'linear-gradient(to right,hsla(  0,100%, 50%,0.2),transparent)'; }
    else if(type == 'enemy'){ bg.backgroundImage = 'linear-gradient(to right,hsla(270,100%, 50%,0.2),transparent)'; }
    else { bg.backgroundImage = ''; }
  }

  const freelv = (exps['effect'] - free*15) / 5;
  if(createType === 'C'){
    if(exps['effect'] <= 60+10) { exps['effect'] = 0 } else { exps['effect'] -= 70 }
    //任意エフェクト1LV×4(60)、任意1Lvアップ×2(10)
  }
  document.getElementById('freepoint-effect').textContent = (free > 4) ? 4 : free;
  document.getElementById('freepoint-effectlv').textContent = (freelv > 2) ? 2 : (freelv < 0) ? 0 : freelv;
  document.getElementById('exp-effect').textContent = exps['effect'];
  document.getElementById("exp-used-effect").textContent = exps['effect'];
  calcExp();
}
// 術式
function calcMagic(){
  exps['magic'] = 0;
  if(document.body.classList.contains('mode-crc')){
    for (let num = 1; num <= Number(form.magicNum.value); num++){
      exps['magic'] += Number(form['magic'+num+'Exp'].value);
    }
    document.getElementById('exp-magic'     ).textContent = exps['magic'];
    document.getElementById('exp-used-magic').textContent = exps['magic'];
    calcExp();
  }
}
// アイテム
function calcItem(){
  stockUsed = 0;
  exps['item'] = 0;
  for (let num = 1; num <= Number(form.weaponNum.value); num++){
    stockUsed    += Number(form['weapon'+num+'Stock'].value);
    exps['item'] += Number(form['weapon'+num+'Exp'  ].value);
  }
  for (let num = 1; num <= Number(form.armorNum.value); num++){
    stockUsed    += Number(form['armor'+num+'Stock'].value);
    exps['item'] += Number(form['armor'+num+'Exp'  ].value);
  }
  for (let num = 1; num <= Number(form.vehicleNum.value); num++){
    stockUsed    += Number(form['vehicle'+num+'Stock'].value);
    exps['item'] += Number(form['vehicle'+num+'Exp'  ].value);
  }
  for (let num = 1; num <= Number(form.itemNum.value); num++){
    stockUsed    += Number(form['item'+num+'Stock'].value);
    exps['item'] += Number(form['item'+num+'Exp'  ].value);
  }
  document.getElementById('item-total-stock').textContent = stockUsed;
  document.getElementById('item-total-exp'  ).textContent = exps['item'];
  document.getElementById('exp-item'        ).textContent = exps['item'];
  document.getElementById('exp-used-item'   ).textContent = exps['item'];
  calcSaving();
  calcExp();
}
// メモリー
function calcMemory() {
  exps['memory'] = 0;
  for (let num = 1; num <= 3; num++){
    if ( form['memory'+num+'Relation'].value || form['memory'+num+'Name'].value){ exps['memory'] += 15; }
  }
  document.getElementById('exp-memory'     ).textContent = exps['memory'];
  document.getElementById("exp-used-memory").textContent = exps['memory'];
  calcExp();
}

// 経験点
function calcExp(){
  let total = makeExp + Number(form['history0Exp'].value);
  if(createType === 'C'){ total -= 130; }

  for (let num = 1; num <= Number(form.historyNum.value); num++){
    const obj = form['history'+num+'Exp'];
    if(form['history'+num+'ExpApply'].checked){
      let exp = safeEval(obj.value);
      if(isNaN(exp)){
        obj.classList.add('error');
      }
      else {
        total += exp;
        obj.classList.remove('error');
      }
    }
    else { obj.classList.remove('error'); }
  }
  let rest = total;
  for (let key in exps){
    rest -= exps[key];
  }
  document.getElementById("exp-total").textContent = total;
  document.getElementById("exp-rest").textContent = rest;
}

// 「衝動」由来の更新
function refreshByImpulse(){
  calcEncroach();

  const optionClass = 'restrict-option-for-impulse';

  const oldElement = document.querySelector(`#list-restrict .${optionClass}`);
  if (oldElement != null) {
    oldElement.parentNode.removeChild(oldElement);
  }

  const impulseName = document.querySelector('select[name="lifepathImpulse"]').value;

  if (impulseName == null || impulseName === '') {
    return;
  }

  const newElement = document.createElement('option');
  newElement.classList.add(optionClass);
  newElement.setAttribute('value', `${impulseName}、120%`);

  document.querySelector('#list-restrict .percent120').after(newElement);
}

// 侵蝕値 ----------------------------------------
function calcEncroach(){
  const awaken  = awakens[form.lifepathAwaken.value]   || 0;
  const impulse = impulses[form.lifepathImpulse.value] || 0;
  const other   = Number(form.lifepathOtherEncroach.value);
  const total   = awaken + impulse + other;
  document.getElementById('awaken-encroach' ).textContent = awaken;
  document.getElementById('impulse-encroach').textContent = impulse;
  document.getElementById('base-encroach').textContent = total;
  
  //form.currentEncroach.value = total;
  encroachBonusType();
}

let EA; let OR;
let array = [];
let lvbs  = {};
let edbs  = {};
function encroachBonusType(){
  EA = form.encroachEaOn.checked;
  OR = false;
  [...Array(7)].map((_, i) => i + 1).forEach((num)=>{
    if(form["lois"+num+"Name"].value.match(/起源種|オリジナルレネゲイド/)){ OR = true; return; }
  });

  array = OR && EA ? [200  ,150  ,100  ,80  ,0  ] : OR ? [150  ,100  ,80  ,0  ] : EA ? [300   ,260   ,220   ,190   ,160   ,130   ,100   ,80   ,60   ,0  ] : [300   ,240   ,200   ,160   ,130   ,100   ,80   ,60   ,0  ];
  edbs  = OR && EA ? {200:0,150:0,100:0,80:0,0:0} : OR ? {150:0,100:0,80:0,0:0} : EA ? {300:7 ,260:6 ,220:5 ,190:5 ,160:4 ,130:4 ,100:3 ,80:2 ,60:1 ,0:0} : {300:8 ,240:7 ,200:6 ,160:5 ,130:4 ,100:3 ,80:2 ,60:1 ,0:0};
  lvbs  = OR && EA ? {200:4,150:3,100:2,80:1,0:0} : OR ? {150:3,100:2,80:1,0:0} : EA ? {300:3 ,260:3 ,220:3 ,190:2 ,160:2 ,130:1 ,100:1 ,80:0 ,60:0 ,0:0} : {300:2 ,240:2 ,200:2 ,160:2 ,130:1 ,100:1 ,80:0 ,60:0 ,0:0};

  document.querySelectorAll('#enc-table colgroup, #enc-table tr').forEach((obj) => { obj.innerHTML = '' })
  
  for(let i = 0; i < array.length; i++){
    let col      = document.createElement("col"); col.id               = 'enc-col'+array[i];                                        document.querySelector('#enc-table colgroup').prepend(col);
    let cellHead = document.createElement("th" ); cellHead.textContent = (i == 0) ? `${array[i]}-` : `${array[i]}-${array[i-1]-1}`; document.getElementById('enc-table-head').prepend(cellHead);
    document.getElementById('enc-table-dices').insertCell(0).textContent = OR ? '―' : '+'+edbs[array[i]];
    document.getElementById('enc-table-level').insertCell(0).textContent = '+'+lvbs[array[i]];
  }
  document.querySelector('#enc-table colgroup').prepend(document.createElement("col"));
  let thHead  = document.createElement("th"); thHead.textContent  = ''       ; document.getElementById('enc-table-head' ).prepend(thHead);
  let thBonus = document.createElement("th"); thBonus.textContent = 'ダイス' ; document.getElementById('enc-table-dices').prepend(thBonus);
  let thLevel = document.createElement("th"); thLevel.textContent = 'Efct.Lv'; document.getElementById('enc-table-level').prepend(thLevel);

  document.getElementById('combo').classList.toggle('original-renegade-mode', OR); //コンボ欄5行目ON/OFF
  
  //encroachBonusSet(form.currentEncroach.value);
}
function encroachBonusSet(enc){
  for (let v of array){ document.getElementById('enc-col'+v).classList.remove('current'); }
  for (let v of array){
    if(enc >= v){
      document.getElementById('enc-col'+v).classList.add('current');
      document.querySelectorAll("[data-edb]").forEach(function(obj) {
        obj.dataset.edb = edbs[v];
      });
      break;
    }
  }
}

// ロイス ----------------------------------------
function emoP(num){ form["lois"+num+"EmoNegaCheck"].checked = false; }
function emoN(num){ form["lois"+num+"EmoPosiCheck"].checked = false; }
function sLois(num){
  for(let i = 1; i <= 7; i++){
    if(i == num) continue;
    form["lois"+i+"S"].checked = false;
  }
}
function changeLoisColor(num){
  const obj = form["lois"+num+"Color"];
  const color = obj.value;
  if (color.match(/^(BK|BLA|黒)/i)){ obj.style.backgroundColor = 'hsla(  0,  0%,  0%,0.2)'; }
  else if(color.match(/^(BL|青)/i)){ obj.style.backgroundColor = 'hsla(220,100%, 50%,0.2)'; }
  else if(color.match(/^(GR|緑)/i)){ obj.style.backgroundColor = 'hsla(120,100%, 50%,0.2)'; }
  else if(color.match(/^(OR|橙)/i)){ obj.style.backgroundColor = 'hsla( 30,100%, 50%,0.2)'; }
  else if(color.match(/^(PU|紫)/i)){ obj.style.backgroundColor = 'hsla(270,100%, 50%,0.2)'; }
  else if(color.match(/^(RE|赤)/i)){ obj.style.backgroundColor = 'hsla(  0,100%, 50%,0.2)'; }
  else if(color.match(/^(WH|白)/i)){ obj.style.backgroundColor = 'hsla(  0,  0%,100%,0.2)'; }
  else if(color.match(/^(YE|黄)/i)){ obj.style.backgroundColor = 'hsla( 60,100%, 50%,0.2)'; }
  else { obj.style.backgroundColor = ''; }
}
function changeLoisState(id){
  const obj = document.querySelector(`#${id} [name$="State"]`);
  let state = obj.value;
  state = (state == 'ロイス') ? 'タイタス' : (state == 'タイタス') ? '昇華' : 'ロイス';
  obj.value = state;
  document.getElementById(id+'-state').dataset.state = state;
}
// ソート
setSortable('lois','#lois-table tbody','tr', (row,num) => {
  row.querySelector(`[name$="EmoPosiCheck"]`).setAttribute('oninput',`emoP(${num})`);
  row.querySelector(`[name$="EmoNegaCheck"]`).setAttribute('oninput',`emoN(${num})`);
});
// リセット
function resetLois(num){
  form[`lois${num}Relation`].value = '';
  form[`lois${num}Name`    ].value = '';
  form[`lois${num}EmoPosiCheck` ].checked = false;
  form[`lois${num}EmoNegaCheck` ].checked = false;
  form[`lois${num}EmoPosi` ].value = '';
  form[`lois${num}EmoNega` ].value = '';
  form[`lois${num}Color`   ].value = '';
  form[`lois${num}Color`   ].style.backgroundColor = '';
  form[`lois${num}Note`    ].value = '';
  form[`lois${num}State`   ].value = 'ロイス';
  document.getElementById(`lois${num}-state`).dataset.state = 'ロイス';
}
function resetLoisAll(){
  if (!confirm('全てのロイスを削除します。よろしいですか？')) return false;
  for(let num = 1; num <= 7; num++){
    resetLois(num);
  }
}
function resetLoisAdd(){
  if (!confirm('4～7番目のロイスを削除します。よろしいですか？')) return false;
  for(let num = 4; num <= 7; num++){
    resetLois(num);
  }
}

// メモリー ----------------------------------------
// ソート
setSortable('memory','#memory-table tbody','tr');

// 技能欄 ----------------------------------------
// 追加
function addSkill(type){
  let num = Number(form[`skill${type}Num`].value) + 1;
  let dt = document.createElement('dt');
  let dd = document.createElement('dd');
  dt.innerHTML = `<input name="skill${type}${num}Name" type="text" list="list-${type.toLowerCase()}">`;
  dd.innerHTML = `<input name="skill${type}${num}" type="number" oninput="calcSkill()" min="0">+<input name="skillAdd${type}${num}" type="number" oninput="calcSkill()">`;
  const status = (
    type === 'Ride' ? 'body'   :
    type === 'Art'  ? 'sense'  :
    type === 'Know' ? 'mind'   :
    type === 'Info' ? 'social' :
    ''
  );
  const target = document.querySelector(`#skill-${status}-table`);
  target.appendChild(dt, target);
  target.appendChild(dd, target);
  
  form[`skill${type}Num`].value = num;
}
// 削除
function delSkill(type){
  let num = Number(form[`skill${type}Num`].value);
  if(num > 1){
    if(form[`skill${type}${num}Name`].value || form[`skill${type}${num}`].value || form[`skillAdd${type}${num}`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const status = (
      type === 'Ride' ? 'body'   :
      type === 'Art'  ? 'sense'  :
      type === 'Know' ? 'mind'   :
      type === 'Info' ? 'social' :
      ''
    );
    const target = document.querySelector(`#skill-${status}-table`);
    target.lastElementChild.remove();
    target.lastElementChild.remove();
    num--;
    form[`skill${type}Num`].value = num;
    calcSkill();
  }
}

// エフェクト欄 ----------------------------------------
// 追加
function addEffect(){
  document.querySelector("#effect-table").append(createRow('effect','effectNum'));
}
// 削除
function delEffect(){
  if(delRow('effectNum', '#effect-table tbody:last-of-type')){
    calcEffect();
  }
}
// ソート
(() => {
  let sortable = Sortable.create(document.getElementById('effect-table'), {
    group: "effect",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template',
    onSort: function(evt){ effectSortAfter(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      document.getElementById('effect-trash').style.display = 'block';
    },
    onEnd: function(evt){
      if(!effectTrashNum) { document.getElementById('effect-trash').style.display = 'none' }
    },
  });

  let trashtable = Sortable.create(document.getElementById('effect-trash-table'), {
    group: "effect",
    dataIdAttr: 'id',
    animation: 150,
    filter: 'thead,tfoot,template',
  });

  let effectTrashNum = 0;
  function effectSortAfter(){
    let num = 1;
    for(let id of sortable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      replaceSortedNames(row,num,/^(effect)(?:Trash)?[0-9]+(.+)$/);
      num++;
    }
    form.effectNum.value = num-1;
    let del = 0;
    for(let id of trashtable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      del++;
      replaceSortedNames(row,'Trash'+del,/^(effect)(?:Trash)?[0-9]+(.+)$/);
    }
    effectTrashNum = del;
    if(!del){ document.getElementById('effect-trash').style.display = 'none' }
    calcEffect();
  }
})();

// 術式欄 ----------------------------------------
// 追加
function addMagic(){
  document.querySelector("#magic-table").append(createRow('magic','magicNum'));
}
// 削除
function delMagic(){
  if(delRow('magicNum', '#magic-table tbody:last-of-type')){
    calcMagic();
  }
}
// ソート
(() => {
  let sortable = Sortable.create(document.getElementById('magic-table'), {
    group: "magic",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template',
    onSort: function(evt){ magicSortAfter(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      document.getElementById('magic-trash').style.display = 'block';
    },
    onEnd: function(evt){
      if(!magicTrashNum) { document.getElementById('magic-trash').style.display = 'none' }
    },
  });

  let trashtable = Sortable.create(document.getElementById('magic-trash-table'), {
    group: "magic",
    dataIdAttr: 'id',
    animation: 150,
    filter: 'thead,tfoot',
  });

  let magicTrashNum = 0;
  function magicSortAfter(){
    let num = 1;
    for(let id of sortable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      replaceSortedNames(row,num,/^(magic)(?:Trash)?[0-9]+(.+)$/);
      num++;
    }
    form.magicNum.value = num-1;
    let del = 0;
    for(let id of trashtable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      del++;
      replaceSortedNames(row,'Trash'+del,/^(magic)(?:Trash)?[0-9]+(.+)$/);
    }
    magicTrashNum = del;
    if(!del){ document.getElementById('magic-trash').style.display = 'none' }
    calcMagic();
  }
})();

// コンボ欄 ----------------------------------------
// 技能セット
function comboSkillSetAll(){
  for(let i = 1; i <= Number(form.comboNum.value); i++){
    comboSkillSet(i);
  }
}
function comboSkillSet(num){
  const select = form[`combo${num}Skill`];
  const nowSelect = select.value;
  while (0 < select.childNodes.length) {
    select.removeChild(select.childNodes[0]);
  }
  for(let i of ['','―','白兵','射撃','RC','交渉','回避','知覚','意志','調達']){
    let op = document.createElement("option");
    op.text = i;
    select.appendChild(op);
  }
  for (let name of ['Ride','Art','Know','Info']){
    for (let num = 1; num <= Number(form[`skill${name}Num`].value); num++){
      let op = document.createElement("option");
      const skillname = form['skill'+name+num+'Name'].value;
      if(skillname){
        op.text = skillname;
        select.appendChild(op);
      }
    }
  }
  let op = document.createElement("option");
  op.text = '解説参照';
  select.appendChild(op);
  
  select.value = nowSelect;
}
// 計算
function calcComboAll(){
  for(let i = 1; i <= Number(form.comboNum.value); i++){
    calcCombo(i);
  }
}
function calcCombo(num){
  const name = form[`combo${num}Skill`].value;
  
  const [lv, stt] = (() => {
    if(form[`combo${num}Manual`].checked){ return ['',''] }
    const id = skillNameToId[name];
    const sttname = form[`combo${num}Stt`].value
    let [lv, stt] = ['',''];
    if(id && name){
      lv = Number(form['skill'+id].value) + Number(form['skillAdd'+id].value);
      if     (id.match(/Melee|Dodge|Ride/))      { stt = status['body']   }
      else if(id.match(/Ranged|Percept|Art/))    { stt = status['sense']  }
      else if(id.match(/RC|Will|Know/))          { stt = status['mind']   }
      else if(id.match(/Negotiate|Procure|Info/)){ stt = status['social'] }
    }
    if(sttname){ 
      if     (sttname === '肉体'){ stt = status['body']   }
      else if(sttname === '感覚'){ stt = status['sense']  }
      else if(sttname === '精神'){ stt = status['mind']   }
      else if(sttname === '社会'){ stt = status['social'] }
      else { stt = 0; }
    }
    return [lv, stt];
  })();
  
  for (const i of [1,2,3,4,5]){
    document.getElementById(`combo${num}Stt${i}`).innerHTML = stt;
    document.getElementById(`combo${num}SkillLv${i}`).innerHTML = lv;
  }
}
// 追加
function addCombo(copyBaseNum){
  const row = createRow('combo','comboNum');
  const num = form.comboNum.value;
  document.querySelector(`#combo-list > div:nth-of-type(${copyBaseNum||num-1})`).after(row);

  if(copyBaseNum){
    row.querySelectorAll('[name]').forEach(node => {
      const copyBaseName = node.getAttribute('name').replace(/^(combo)\d+(.+)$/, `$1${copyBaseNum}$2`)
      if(node.type === 'checkbox'){
        node.checked = form[copyBaseName].checked;
      }
      else { node.value = form[copyBaseName].value; }
    });
    calcCombo(form.comboNum.value);
    row.classList.add('slide-once');

    let i = 1;
    document.querySelectorAll(`#combo-list > div`).forEach(obj => {
      replaceSortedNames(obj,i,/^(combo)[0-9]+(.*)$/);
      replaceSortedNames(obj,i,/^(combo)[0-9]+((?:Stt|SkillLv)[0-9])$/,'id');
      replaceSortedNames(obj,i,/^(calcCombo\()[0-9]+(\))$/,'oninput');
      replaceSortedNames(obj,i,/^(addCombo\()[0-9]+(\))$/,'onclick');
      i++;
    })
  }
  comboSkillSet(form.comboNum.value);
  makeComboConditionUtility(row);
}
// 削除
function delCombo(){
  delRow('comboNum', '#combo-list .combo-table:last-child');
}
// ソート
setSortable('combo', '#combo-list', 'div', (row, num) => {
  replaceSortedNames(row,num,/^(combo)[0-9]+((?:Stt|SkillLv)[0-9])$/,'id');
  replaceSortedNames(row,num,/^(calcCombo\()[0-9]+(\))$/,'oninput');
  replaceSortedNames(row,num,/^(addCombo\()[0-9]+(\))$/,'onclick');
})
// 条件
function makeComboConditionUtility(comboNode) {
  const utilityIcon = comboNode.querySelector('.combo-out .combo-cond .combo-condition-utility');
  if (utilityIcon == null) {
    return;
  }

  /** @return {Array.<{label: string, conditionTexts: [string, string, string, string, string]}>} */
  function makeMenuItems() {
    function makeConditionItem(label, text1 = '', text2 = '', text3 = '', text4 = '', text5 = '') {
      return {label: label, conditionTexts: [text1, text2, text3, text4, text5]};
    }

    let menuItems = [
      makeConditionItem("すべての条件を消去"),
      makeConditionItem("100%未満／100%以上", "100%未満", "100%以上"),
    ];

    menuItems = menuItems.concat(
        document.querySelector('#enc-table-dices td').textContent !== '―'
            ? [
              makeConditionItem("-99／100-", "～99%", "100%～"),
              makeConditionItem("-99／100-159／160-", "～99%", "100%～159%", "160%～"),
              makeConditionItem("-99／100-159／160-219／220-", "～99%", "100%～159%", "160%～220%", "220%～"),
              makeConditionItem("80-99／100-", "80%～99%", "100%～"),
              makeConditionItem("80-99／100-159／160-", "80%～99%", "100%～159%", "160%～"),
              makeConditionItem("80-99／100-159／160-219／220-", "80%～99%", "100%～159%", "160%～219%", "220%～"),
              makeConditionItem("100-", "100%～"),
              makeConditionItem("100-159／160-", "100%～159%", "160%～"),
              makeConditionItem("100-159／160-219／220-", "100%～159%", "160%～219%", "220%～"),
              makeConditionItem("120-", "120%～"),
              makeConditionItem("120-159／160-", "120%～159%", "160%～"),
              makeConditionItem("120-159／160-219／220-", "120%～159%", "160%～219%", "220%～"),
            ]
            : [
              makeConditionItem("-79／80-", "～79%", "80%～"),
              makeConditionItem("-79／80-99／100-", "～79%", "80%～99%", "100%～"),
              makeConditionItem("-79／80-99／100-149／150-", "～79%", "80%～99%", "100%～149%", "150%～"),
              makeConditionItem("-79／80-99／100-149／150-199／200-", "～79%", "80%～99%", "100%～149%", "150%～199%", "200%～"),
              makeConditionItem("80-99／100-", "80%～99%", "100%～"),
              makeConditionItem("80-99／100-149／150-", "80%～99%", "100%～149%", "150%～"),
              makeConditionItem("80-99／100-149／150-199／200-", "80%～99%", "100%～149%", "150%～199%", "200%～"),
              makeConditionItem("100-", "100%～"),
              makeConditionItem("100-149／150-", "100%～149%", "150%～"),
              makeConditionItem("100-149／150-199／200-", "100%～149%", "150%～199%", "200%～"),
              makeConditionItem("120-", "120%～"),
              makeConditionItem("120-149／150-", "120%～149%", "150%～"),
              makeConditionItem("120-149／150-199／200-", "120%～149%", "150%～199%", "200%～"),
            ]
    );

    if (!document.querySelector('[name="encroachEaOn"]').checked) {
      menuItems = menuItems.filter(x => !(x.label.includes('220') || x.label.includes('200')));
    }

    return menuItems;
  }

  utilityIcon.addEventListener(
      'click',
      () => {
        const oldMenu = document.querySelector('.combo-condition-utility-menu');
        if (oldMenu != null) {
          oldMenu.parentNode.removeChild(oldMenu);
          return;
        }

        const iconRect = utilityIcon.getBoundingClientRect();

        const menuNode = document.createElement('div');
        menuNode.classList.add('combo-condition-utility-menu');
        menuNode.style.left = `${window.pageXOffset + iconRect.left + iconRect.width / 2}px`;
        menuNode.style.top = `calc(${window.pageYOffset + iconRect.bottom}px - 0.35rem)`;

        makeMenuItems().forEach(
            itemSettings => {
              const menuItemNode = document.createElement('a');
              menuItemNode.classList.add('item');
              menuItemNode.textContent = itemSettings.label;
              menuNode.appendChild(menuItemNode);

              menuItemNode.addEventListener(
                  'click',
                  () =>
                      comboNode.querySelectorAll('.combo-out dd input[type="text"][name*="Condition"]').forEach(
                          (node, index) => node.value = itemSettings.conditionTexts[index] ?? ''
                      )
              );
            }
        );

        const body = document.querySelector('body');

        const menuRemover = event => {
          if (event != null) {
            function getNodePath(node) {
              const path = [];
              let current = node;
              while (current != null) {
                path.unshift(current);
                current = current.parentNode;
              }
              return path;
            }

            if (getNodePath(event.target).some(node => node === utilityIcon)) {
              return;
            }
          }

          if (menuNode.parentNode != null) {
            menuNode.parentNode.removeChild(menuNode);
          }

          body.removeEventListener('click', menuRemover);
        };

        body.addEventListener('click', menuRemover);
        body.appendChild(menuNode);
      }
  );
}
document.querySelectorAll('#combo .combo-table').forEach(node => makeComboConditionUtility(node));

// 武器欄 ----------------------------------------
// 追加
function addWeapon(){
  document.querySelector("#weapon-table tbody").append(createRow('weapon','weaponNum'));
}
// 削除
function delWeapon(){
  if(delRow('weaponNum', '#weapon-table tbody tr:last-of-type')){
    calcItem();
  }
}
// ソート
setSortable('weapon','#weapon-table tbody','tr');

// 防具欄 ----------------------------------------
// 追加
function addArmor(){
  document.querySelector("#armor-table tbody").append(createRow('armor','armorNum'));
}
// 削除
function delArmor(){
  if(delRow('armorNum', '#armor-table tbody tr:last-of-type')){
    calcItem();
  }
}
// ソート
setSortable('armor','#armor-table tbody','tr');

// ヴィークル欄 ----------------------------------------
// 追加
function addVehicle(){
  document.querySelector("#vehicle-table tbody").append(createRow('vehicle','vehicleNum'));
}
// 削除
function delVehicle(){
  if(delRow('vehicleNum', '#vehicle-table tbody tr:last-of-type')){
    calcItem();
  }
}
// ソート
setSortable('vehicle','#vehicle-table tbody','tr');

// アイテム欄 ----------------------------------------
// 追加
function addItem(){
  document.querySelector("#item-table tbody").append(createRow('item','itemNum'));
}
// 削除
function delItem(){
  if(delRow('itemNum', '#item-table tbody tr:last-of-type')){
    calcItem();
  }
}
// ソート
setSortable('item','#item-table tbody','tr');

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  document.querySelector("#history-table tfoot").before(createRow('history','historyNum'));
}
// 削除
function delHistory(){
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcExp();
  }
}
// ソート
setSortable('history','#history-table','tbody');
