"use strict";
const gameSystem = 'dx3';

let exps = {};
let status = {};
let syndromes = [];
// ----------------------------------------
window.onload = function() {
  console.log('=====START=====');
  syndromes = [form.syndrome1.value, form.syndrome2.value, form.syndrome3.value];
  
  nameSet();
  checkStage();
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
function changeRegu(){
  document.getElementById("history0-exp").textContent = form.history0Exp.value;
  calcExp();
}

// ステージチェック ----------------------------------------
let ccOn = 0;
function checkStage(){
  document.body.classList.toggle('mode-crc', form.stage.value.match('クロウリングケイオス'));
  calcMagic();
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
  console.log(syndromes)
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
    
    document.getElementById('stt-total-'+stt).textContent = status[stt];
    document.getElementById('skill-'+stt).textContent = status[stt];
    
    // 経験点
    for(let i = base; i < base+grow; i++){
      exps['status'] += (i > 20) ? 30 : (i > 10) ? 20 : 10;
    }

    // 能力値0の場合のエラー
    document.getElementById('stt-total-'+stt).classList.toggle('error', syn1 && !status[stt]);
  }
  document.getElementById('exp-status').textContent = exps['status'];
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
  document.getElementById('exp-skill').textContent = exps['skill'];
  calcExp();
  calcComboAll();
}
// エフェクト
function calcEffect() {
  exps['effect'] = 0;
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
        if(type.match(/^(auto|dlois)$/i)){ exps['effect'] += -15; } //自動かDロイスは新規取得ぶん減らす
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
  document.getElementById('exp-effect').textContent = exps['effect'];
  calcExp();
}
// 術式
function calcMagic(){
  exps['magic'] = 0;
  if(ccOn){
    for (let num = 1; num <= Number(form.magicNum.value); num++){
      exps['magic'] += Number(form['magic'+num+'Exp'].value);
    }
    document.getElementById('exp-magic').textContent = exps['magic'];
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
  document.getElementById("item-total-stock").textContent = stockUsed;
  document.getElementById("item-total-exp").textContent = exps['item'];
  document.getElementById("exp-item").textContent = exps['item'];
  calcSaving();
  calcExp();
}
// メモリー
function calcMemory() {
  exps['memory'] = 0;
  for (let num = 1; num <= 3; num++){
    if ( form['memory'+num+'Relation'].value || form['memory'+num+'Name'].value){ exps['memory'] += 15; }
  }
  document.getElementById('exp-memory').textContent = exps['memory'];
  calcExp();
}

// 経験点
function calcExp(){
  let total = Number(form['history0Exp'].value);
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
  document.getElementById("exp-used-status").textContent = exps['status'] || 0;
  document.getElementById("exp-used-skill" ).textContent = exps['skill']  || 0;
  document.getElementById("exp-used-effect").textContent = exps['effect'] || 0;
  document.getElementById("exp-used-magic" ).textContent = exps['magic'] || 0;
  document.getElementById("exp-used-item"  ).textContent = exps['item']   || 0;
  document.getElementById("exp-used-memory").textContent = exps['memory'] || 0;
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
    console.log(i)
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
let loisSortable = Sortable.create(document.querySelector('#lois-table tbody'), {
  group: "lois",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = loisSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Relation"]`    ).setAttribute('name',`lois${num}Relation`);
        document.querySelector(`#${id} [name$="Name"]`        ).setAttribute('name',`lois${num}Name`);
        document.querySelector(`#${id} [name$="EmoPosiCheck"]`).setAttribute('name',`lois${num}EmoPosiCheck`);
        document.querySelector(`#${id} [name$="EmoNegaCheck"]`).setAttribute('name',`lois${num}EmoNegaCheck`);
        document.querySelector(`#${id} [name$="EmoPosi"]`     ).setAttribute('name',`lois${num}EmoPosi`);
        document.querySelector(`#${id} [name$="EmoNega"]`     ).setAttribute('name',`lois${num}EmoNega`);
        document.querySelector(`#${id} [name$="Color"]`       ).setAttribute('name',`lois${num}Color`);
        document.querySelector(`#${id} [name$="Note"]`        ).setAttribute('name',`lois${num}Note`);
        document.querySelector(`#${id} [name$="State"]`       ).setAttribute('name',`lois${num}State`);
        document.querySelector(`#${id} [name$="EmoPosiCheck"]`).setAttribute('oninput',`emoP(${num})`);
        document.querySelector(`#${id} [name$="EmoNegaCheck"]`).setAttribute('oninput',`emoN(${num})`);
        num++;
      }
    }
  }
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
let memorySortable = Sortable.create(document.querySelector('#memory-table tbody'), {
  group: "memory",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = memorySortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Relation"]`).setAttribute('name',`memory${num}Relation`);
        document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`memory${num}Name`);
        document.querySelector(`#${id} [name$="Emo"]`     ).setAttribute('name',`memory${num}Emo`);
        document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`memory${num}Note`);
        num++;
      }
    }
  }
});

// 技能欄 ----------------------------------------
// 追加
function addSkill(type){
  let num = Number(form[`skill${type}Num`].value) + 1;
  let dt = document.createElement('dt');
  let dd = document.createElement('dd');
  dt.innerHTML = `<input name="skill${type}${num}Name" type="text" list="list-${type.toLowerCase()}">`;
  dd.innerHTML = `<input name="skill${type}${num}" type="number" oninput="calcSkill()">+<input name="skillAdd${type}${num}" type="number" oninput="calcSkill()">`;
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
  let num = Number(form.effectNum.value) + 1;

  let row = document.querySelector('#effect-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('effect');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#effect-table").append(row);
  
  form.effectNum.value = num;
}
// 削除
function delEffect(){
  let num = Number(form.effectNum.value);
  if(num > 2){
    if(form[`effect${num}Name`].value || form[`effect${num}Lv`].value || form[`effect${num}Timing`].value || form[`effect${num}Skill`].value || form[`effect${num}Dfclty`].value || form[`effect${num}Target`].value || form[`effect${num}Range`].value || form[`effect${num}Encroach`].value || form[`effect${num}Restrict`].value || form[`effect${num}Exp`].value || form[`effect${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#effect-table tbody:last-of-type").remove();
    num--;
    form.effectNum.value = num;
    calcEffect();
  }
}
// ソート
let effectSortable = Sortable.create(document.getElementById('effect-table'), {
  group: "effect",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onSort: function(evt){ effectSortAfter(); },
  onStart: function(evt){
    document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
    document.getElementById('effect-trash').style.display = 'block';
  },
  onEnd: function(evt){
    if(!effectTrashNum) { document.getElementById('effect-trash').style.display = 'none' }
  },
});
let effectSortableTrash = Sortable.create(document.getElementById('effect-trash-table'), {
  group: "effect",
  dataIdAttr: 'id',
  animation: 100,
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost'
});
let effectTrashNum = 0;
function effectSortAfter(){
  const order = effectSortable.toArray();
  let num = 1;
  for(let id of order) {
    if(document.querySelector(`tbody#${id}`)){
      document.querySelector(`#${id} [name$="Type"]`    ).setAttribute('name',`effect${num}Type`);
      document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`effect${num}Name`);
      document.querySelector(`#${id} [name$="Lv"]`      ).setAttribute('name',`effect${num}Lv`);
      document.querySelector(`#${id} [name$="Timing"]`  ).setAttribute('name',`effect${num}Timing`);
      document.querySelector(`#${id} [name$="Skill"]`   ).setAttribute('name',`effect${num}Skill`);
      document.querySelector(`#${id} [name$="Dfclty"]`  ).setAttribute('name',`effect${num}Dfclty`);
      document.querySelector(`#${id} [name$="Target"]`  ).setAttribute('name',`effect${num}Target`);
      document.querySelector(`#${id} [name$="Range"]`   ).setAttribute('name',`effect${num}Range`);
      document.querySelector(`#${id} [name$="Encroach"]`).setAttribute('name',`effect${num}Encroach`);
      document.querySelector(`#${id} [name$="Restrict"]`).setAttribute('name',`effect${num}Restrict`);
      document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`effect${num}Note`);
      document.querySelector(`#${id} [name$="Exp"]`     ).setAttribute('name',`effect${num}Exp`);
      num++;
    }
  }
  form.effectNum.value = num-1;
  let del = 0;
  const trashOrder = effectSortableTrash.toArray();
  for(let id of trashOrder) {
    if(document.querySelector(`tbody#${id}`)){
      del++;
      document.querySelector(`#${id} [name$="Type"]`    ).setAttribute('name',`effectD${del}Type`);
      document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`effectD${del}Name`);
      document.querySelector(`#${id} [name$="Lv"]`      ).setAttribute('name',`effectD${del}Lv`);
      document.querySelector(`#${id} [name$="Timing"]`  ).setAttribute('name',`effectD${del}Timing`);
      document.querySelector(`#${id} [name$="Skill"]`   ).setAttribute('name',`effectD${del}Skill`);
      document.querySelector(`#${id} [name$="Dfclty"]`  ).setAttribute('name',`effectD${del}Dfclty`);
      document.querySelector(`#${id} [name$="Target"]`  ).setAttribute('name',`effectD${del}Target`);
      document.querySelector(`#${id} [name$="Range"]`   ).setAttribute('name',`effectD${del}Range`);
      document.querySelector(`#${id} [name$="Encroach"]`).setAttribute('name',`effectD${del}Encroach`);
      document.querySelector(`#${id} [name$="Restrict"]`).setAttribute('name',`effectD${del}Restrict`);
      document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`effectD${del}Note`);
      document.querySelector(`#${id} [name$="Exp"]`     ).setAttribute('name',`effectD${del}Exp`);
    }
  }
  effectTrashNum = del;
  if(!del){ document.getElementById('effect-trash').style.display = 'none' }
  calcEffect();
}

// 術式欄 ----------------------------------------
// 追加
function addMagic(){
  let num = Number(form.magicNum.value) + 1;

  let row = document.querySelector('#magic-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('magic');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#magic-table").append(row);
  
  form.magicNum.value = num;
}
// 削除
function delMagic(){
  let num = Number(form.magicNum.value);
  if(num > 2){
    if(form[`magic${num}Name`].value || form[`magic${num}Type`].value || form[`magic${num}Exp`].value || form[`magic${num}Activate`].value || form[`magic${num}Encroach`].value || form[`magic${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#magic-table tbody:last-of-type").remove();
    num--;
    form.magicNum.value = num;
    calcMagic();
  }
}
// ソート
let magicSortable = Sortable.create(document.getElementById('magic-table'), {
  group: "magic",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onSort: function(evt){ magicSortAfter(); },
  onStart: function(evt){
    document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
    document.getElementById('magic-trash').style.display = 'block';
  },
  onEnd: function(evt){
    if(!magicTrashNum) { document.getElementById('magic-trash').style.display = 'none' }
  },
});
let magicSortableTrash = Sortable.create(document.getElementById('magic-trash-table'), {
  group: "magic",
  dataIdAttr: 'id',
  animation: 100,
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost'
});
let magicTrashNum = 0;
function magicSortAfter(){
  const order = magicSortable.toArray();
  let num = 1;
  for(let id of order) {
    if(document.querySelector(`tbody#${id}`)){
      document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`magic${num}Name`);
      document.querySelector(`#${id} [name$="Type"]`    ).setAttribute('name',`magic${num}Type`);
      document.querySelector(`#${id} [name$="Exp"]`     ).setAttribute('name',`magic${num}Exp`);
      document.querySelector(`#${id} [name$="Activate"]`).setAttribute('name',`magic${num}Activate`);
      document.querySelector(`#${id} [name$="Encroach"]`).setAttribute('name',`magic${num}Encroach`);
      document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`magic${num}Note`);
      num++;
    }
  }
  form.magicNum.value = num-1;
  let del = 0;
  const trashOrder = magicSortableTrash.toArray();
  for(let id of trashOrder) {
    if(document.querySelector(`tbody#${id}`)){
      del++;
      document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`magic${del}Name`);
      document.querySelector(`#${id} [name$="Type"]`    ).setAttribute('name',`magic${del}Type`);
      document.querySelector(`#${id} [name$="Exp"]`     ).setAttribute('name',`magic${del}Exp`);
      document.querySelector(`#${id} [name$="Activate"]`).setAttribute('name',`magic${del}Activate`);
      document.querySelector(`#${id} [name$="Encroach"]`).setAttribute('name',`magic${del}Encroach`);
      document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`magic${del}Note`);
    }
  }
  magicTrashNum = del;
  if(!del){ document.getElementById('magic-trash').style.display = 'none' }
  calcMagic();
}

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
    if(form['comboCalcOff'].checked){ return ['',''] }
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
function addCombo(){
  let num = Number(form.comboNum.value) + 1;

  let row = document.querySelector('#combo-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('combo');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#combo-list").append(row);

  comboSkillSet(num);
  makeComboConditionUtility(row);
  form.comboNum.value = num;
}
// 削除
function delCombo(){
  let num = Number(form.comboNum.value);
  if(num > 1){
    if(form[`combo${num}Name`].value || form[`combo${num}Combo`].value || form[`combo${num}Timing`].value || form[`combo${num}Skill`].value || form[`combo${num}Dfclty`].value || form[`combo${num}Target`].value || form[`combo${num}Range`].value || form[`combo${num}Encroach`].value || form[`combo${num}DiceAdd1`].value || form[`combo${num}Crit1`].value || form[`combo${num}Atk1`].value || form[`combo${num}FixedAdd1`].value || form[`combo${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#combo-list .combo-table:last-child");
    target.remove();
    num--;
    form.comboNum.value = num;
  }
}
// ソート
let comboSortable = Sortable.create(document.getElementById('combo-list'), {
  group: "combo",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = comboSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`div#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`combo${num}Name`);
        document.querySelector(`#${id} [name$="Combo"]`   ).setAttribute('name',`combo${num}Combo`);
        document.querySelector(`#${id} [name$="Timing"]`  ).setAttribute('name',`combo${num}Timing`);
        document.querySelector(`#${id} [name$="Skill"]`   ).setAttribute('name',`combo${num}Skill`);
        document.querySelector(`#${id} [name$="Stt"]`     ).setAttribute('name',`combo${num}Stt`);
        document.querySelector(`#${id} [name$="Dfclty"]`  ).setAttribute('name',`combo${num}Dfclty`);
        document.querySelector(`#${id} [name$="Target"]`  ).setAttribute('name',`combo${num}Target`);
        document.querySelector(`#${id} [name$="Range"]`   ).setAttribute('name',`combo${num}Range`);
        document.querySelector(`#${id} [name$="Encroach"]`).setAttribute('name',`combo${num}Encroach`);
        document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`combo${num}Note`);
        document.querySelector(`#${id} [name$="Condition1"]`).setAttribute('name',`combo${num}Condition1`);
        document.querySelector(`#${id} [name$="Condition2"]`).setAttribute('name',`combo${num}Condition2`);
        document.querySelector(`#${id} [name$="Condition3"]`).setAttribute('name',`combo${num}Condition3`);
        document.querySelector(`#${id} [name$="Condition4"]`).setAttribute('name',`combo${num}Condition4`);
        document.querySelector(`#${id} [name$="Condition5"]`).setAttribute('name',`combo${num}Condition5`);
        document.querySelector(`#${id} [name$="DiceAdd1"]`  ).setAttribute('name',`combo${num}DiceAdd1`);
        document.querySelector(`#${id} [name$="DiceAdd2"]`  ).setAttribute('name',`combo${num}DiceAdd2`);
        document.querySelector(`#${id} [name$="DiceAdd3"]`  ).setAttribute('name',`combo${num}DiceAdd3`);
        document.querySelector(`#${id} [name$="DiceAdd4"]`  ).setAttribute('name',`combo${num}DiceAdd4`);
        document.querySelector(`#${id} [name$="DiceAdd5"]`  ).setAttribute('name',`combo${num}DiceAdd5`);
        document.querySelector(`#${id} [name$="Crit1"]`     ).setAttribute('name',`combo${num}Crit1`);
        document.querySelector(`#${id} [name$="Crit2"]`     ).setAttribute('name',`combo${num}Crit2`);
        document.querySelector(`#${id} [name$="Crit3"]`     ).setAttribute('name',`combo${num}Crit3`);
        document.querySelector(`#${id} [name$="Crit4"]`     ).setAttribute('name',`combo${num}Crit4`);
        document.querySelector(`#${id} [name$="Crit5"]`     ).setAttribute('name',`combo${num}Crit5`);
        document.querySelector(`#${id} [name$="Atk1"]`      ).setAttribute('name',`combo${num}Atk1`);
        document.querySelector(`#${id} [name$="Atk2"]`      ).setAttribute('name',`combo${num}Atk2`);
        document.querySelector(`#${id} [name$="Atk3"]`      ).setAttribute('name',`combo${num}Atk3`);
        document.querySelector(`#${id} [name$="Atk4"]`      ).setAttribute('name',`combo${num}Atk4`);
        document.querySelector(`#${id} [name$="Atk5"]`      ).setAttribute('name',`combo${num}Atk5`);
        document.querySelector(`#${id} [name$="FixedAdd1"]` ).setAttribute('name',`combo${num}FixedAdd1`);
        document.querySelector(`#${id} [name$="FixedAdd2"]` ).setAttribute('name',`combo${num}FixedAdd2`);
        document.querySelector(`#${id} [name$="FixedAdd3"]` ).setAttribute('name',`combo${num}FixedAdd3`);
        document.querySelector(`#${id} [name$="FixedAdd4"]` ).setAttribute('name',`combo${num}FixedAdd4`);
        document.querySelector(`#${id} [name$="FixedAdd5"]` ).setAttribute('name',`combo${num}FixedAdd5`);
        document.querySelector(`#${id} [name$="Skill"]`   ).setAttribute('oninput',`calcCombo(${num})`);
        document.querySelector(`#${id} [name$="Stt"]`     ).setAttribute('oninput',`calcCombo(${num})`);
        document.querySelector(`#${id} [id$="Stt1"]`    ).setAttribute('id',`combo${num}Stt1`);
        document.querySelector(`#${id} [id$="Stt2"]`    ).setAttribute('id',`combo${num}Stt2`);
        document.querySelector(`#${id} [id$="Stt3"]`    ).setAttribute('id',`combo${num}Stt3`);
        document.querySelector(`#${id} [id$="Stt4"]`    ).setAttribute('id',`combo${num}Stt4`);
        document.querySelector(`#${id} [id$="Stt5"]`    ).setAttribute('id',`combo${num}Stt5`);
        document.querySelector(`#${id} [id$="SkillLv1"]`).setAttribute('id',`combo${num}SkillLv1`);
        document.querySelector(`#${id} [id$="SkillLv2"]`).setAttribute('id',`combo${num}SkillLv2`);
        document.querySelector(`#${id} [id$="SkillLv3"]`).setAttribute('id',`combo${num}SkillLv3`);
        document.querySelector(`#${id} [id$="SkillLv4"]`).setAttribute('id',`combo${num}SkillLv4`);
        document.querySelector(`#${id} [id$="SkillLv5"]`).setAttribute('id',`combo${num}SkillLv5`);
        num++;
      }
    }
  }
});
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
  let num = Number(form.weaponNum.value) + 1;

  let row = document.querySelector('#weapon-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('weapon');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#weapon-table tbody").append(row);
  
  form.weaponNum.value = num;
}
// 削除
function delWeapon(){
  let num = Number(form.weaponNum.value);
  if(num > 1){
    if(form[`weapon${num}Name`].value || form[`weapon${num}Stock`].value || form[`weapon${num}Exp`].value || form[`weapon${num}Type`].value || form[`weapon${num}Skill`].value || form[`weapon${num}Acc`].value || form[`weapon${num}Atk`].value || form[`weapon${num}Guard`].value || form[`weapon${num}Range`].value || form[`weapon${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#weapon-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.weaponNum.value = num;
    calcItem();
  }
}
// ソート
let weaponSortable = Sortable.create(document.querySelector('#weapon-table tbody'), {
  group: "weapon",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = weaponSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Name"]` ).setAttribute('name',`weapon${num}Name`);
        document.querySelector(`#${id} [name$="Stock"]`).setAttribute('name',`weapon${num}Stock`);
        document.querySelector(`#${id} [name$="Exp"]`  ).setAttribute('name',`weapon${num}Exp`);
        document.querySelector(`#${id} [name$="Type"]` ).setAttribute('name',`weapon${num}Type`);
        document.querySelector(`#${id} [name$="Skill"]`).setAttribute('name',`weapon${num}Skill`);
        document.querySelector(`#${id} [name$="Acc"]`  ).setAttribute('name',`weapon${num}Acc`);
        document.querySelector(`#${id} [name$="Atk"]`  ).setAttribute('name',`weapon${num}Atk`);
        document.querySelector(`#${id} [name$="Guard"]`).setAttribute('name',`weapon${num}Guard`);
        document.querySelector(`#${id} [name$="Range"]`).setAttribute('name',`weapon${num}Range`);
        document.querySelector(`#${id} [name$="Note"]` ).setAttribute('name',`weapon${num}Note`);
        num++;
      }
    }
  }
});
// 防具欄 ----------------------------------------
// 追加
function addArmor(){
  let num = Number(form.armorNum.value) + 1;

  let row = document.querySelector('#armor-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('armor');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#armor-table tbody").append(row);

  form.armorNum.value = num;
}
// 削除
function delArmor(){
  let num = Number(form.armorNum.value);
  if(num > 1){
    if(form[`armor${num}Name`].value || form[`armor${num}Stock`].value || form[`armor${num}Exp`].value || form[`armor${num}Initiative`].value || form[`armor${num}Dodge`].value || form[`armor${num}Armor`].value || form[`armor${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#armor-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.armorNum.value = num;
    calcItem();
  }
}
// ソート
let armorSortable = Sortable.create(document.querySelector('#armor-table tbody'), {
  group: "armor",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = armorSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`      ).setAttribute('name',`armor${num}Name`);
        document.querySelector(`#${id} [name$="Stock"]`     ).setAttribute('name',`armor${num}Stock`);
        document.querySelector(`#${id} [name$="Exp"]`       ).setAttribute('name',`armor${num}Exp`);
        document.querySelector(`#${id} [name$="Type"]`      ).setAttribute('name',`armor${num}Type`);
        document.querySelector(`#${id} [name$="Initiative"]`).setAttribute('name',`armor${num}Initiative`);
        document.querySelector(`#${id} [name$="Dodge"]`     ).setAttribute('name',`armor${num}Dodge`);
        document.querySelector(`#${id} [name$="Armor"]`     ).setAttribute('name',`armor${num}Armor`);
        document.querySelector(`#${id} [name$="Note"]`      ).setAttribute('name',`armor${num}Note`);
        num++;
      }
    }
  }
});
// ヴィークル欄 ----------------------------------------
// 追加
function addVehicle(){
  let num = Number(form.vehicleNum.value) + 1;

  let row = document.querySelector('#vehicle-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('vehicle');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#vehicle-table tbody").append(row);
  
  form.vehicleNum.value = num;
}
// 削除
function delVehicle(){
  let num = Number(form.vehicleNum.value);
  if(num > 0){
    if(form[`vehicle${num}Name`].value || form[`vehicle${num}Stock`].value || form[`vehicle${num}Exp`].value || form[`vehicle${num}Skill`].value || form[`vehicle${num}Initiative`].value || form[`vehicle${num}Atk`].value || form[`vehicle${num}Armor`].value || form[`vehicle${num}Dash`].value || form[`vehicle${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#vehicle-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.vehicleNum.value = num;
    calcItem();
  }
}
// ソート
let vehicleSortable = Sortable.create(document.querySelector('#vehicle-table tbody'), {
  group: "vehicle",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = vehicleSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`      ).setAttribute('name',`vehicle${num}Name`);
        document.querySelector(`#${id} [name$="Stock"]`     ).setAttribute('name',`vehicle${num}Stock`);
        document.querySelector(`#${id} [name$="Exp"]`       ).setAttribute('name',`vehicle${num}Exp`);
        document.querySelector(`#${id} [name$="Type"]`      ).setAttribute('name',`vehicle${num}Type`);
        document.querySelector(`#${id} [name$="Skill"]`     ).setAttribute('name',`vehicle${num}Skill`);
        document.querySelector(`#${id} [name$="Initiative"]`).setAttribute('name',`vehicle${num}Initiative`);
        document.querySelector(`#${id} [name$="Atk"]`       ).setAttribute('name',`vehicle${num}Atk`);
        document.querySelector(`#${id} [name$="Armor"]`     ).setAttribute('name',`vehicle${num}Armor`);
        document.querySelector(`#${id} [name$="Dash"]`      ).setAttribute('name',`vehicle${num}Dash`);
        document.querySelector(`#${id} [name$="Note"]`      ).setAttribute('name',`vehicle${num}Note`);
        num++;
      }
    }
  }
});

// アイテム欄 ----------------------------------------
// 追加
function addItem(){
  let num = Number(form.itemNum.value) + 1;

  let row = document.querySelector('#item-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('item');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#item-table tbody").append(row);
  
  form.itemNum.value = num;
}
// 削除
function delItem(){
  let num = Number(form.itemNum.value);
  if(num > 1){
    if(form[`item${num}Name`].value || form[`item${num}Stock`].value || form[`item${num}Exp`].value || form[`item${num}Type`].value || form[`item${num}Skill`].value || form[`item${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#item-table tbody tr:last-of-type").remove();
    num--;
    form.itemNum.value = num;
    calcItem();
  }
}
// ソート
let itemSortable = Sortable.create(document.querySelector('#item-table tbody'), {
  group: "item",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = itemSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`      ).setAttribute('name',`item${num}Name`);
        document.querySelector(`#${id} [name$="Stock"]`     ).setAttribute('name',`item${num}Stock`);
        document.querySelector(`#${id} [name$="Exp"]`       ).setAttribute('name',`item${num}Exp`);
        document.querySelector(`#${id} [name$="Type"]`      ).setAttribute('name',`item${num}Type`);
        document.querySelector(`#${id} [name$="Skill"]`     ).setAttribute('name',`item${num}Skill`);
        document.querySelector(`#${id} [name$="Note"]`      ).setAttribute('name',`item${num}Note`);
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
    if(form[`history${num}Date`].value || form[`history${num}Title`].value || form[`history${num}Exp`].value || form[`history${num}Gm`].value || form[`history${num}Member`].value || form[`history${num}Note`].value){
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
  animation: 100,
  handle: '.handle',
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
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
        num++;
      }
    }
  }
});
