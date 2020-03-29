"use strict";
const form = document.sheet;
let exps = {};
let status = {};

// //
window.onload = function() {
  calcStt();
  calcSkill();
  calcEffect();
  calcItem();
  calcMemory();
  calcEncroach();
  for(let i = 1; i <= 7; i++){ changeLoisColor(i); }
  imagePosition();
  changeColor();
};

function changeRegu(){
  document.getElementById("history0-exp").innerHTML = form.history0Exp.value;
}

// シンドローム変更 //
let syndromes = [form.syndrome1.value, form.syndrome2.value, form.syndrome3.value];
function changeSyndrome(num, syn){
  syndromes[num-1] = syn;
  calcStt();
}

// ステータス計算 //
function calcStt() {
  const syn1 = syndromes[0];
  const syn2 = syndromes[1];
  
  exps['status'] = 0;
  
  for (let stt of ['body','sense','mind','social']){
    const Stt = stt.slice(0,1).toUpperCase()+stt.slice(1);
    let base = 0;
    base += syn1 ? synStats[syn1][stt] : 0;
    base += syn2 ? synStats[syn2][stt] : syn1 ? synStats[syn1][stt] : 0;
    if(stt == form.sttWorks.value) { base += 1; }
    const grow = Number(form["sttGrow"+Stt].value);
    const add  = Number(form["sttAdd" +Stt].value);
    status[stt] = base + grow + add;
    
    document.getElementById('stt-syn1-'+stt).innerHTML = syn1 ? synStats[syn1][stt] + (syn2 ? '' : '×2') : '';
    document.getElementById('stt-syn2-'+stt).innerHTML = syn2 ? synStats[syn2][stt] : '';
    document.getElementById('stt-total-'+stt).innerHTML = status[stt];
    document.getElementById('skill-'+stt).innerHTML = status[stt];
    
    // 経験点
    for(let i = base; i < base+grow; i++){
      exps['status'] += (i > 20) ? 30 : (i > 10) ? 20 : 10;
    }
  }
  document.getElementById('exp-status').innerHTML = exps['status'];
  calcSubStt();
  calcExp();
}
// サブステータス
function calcSubStt() {
  calcMaxHp();
  calcInitiative();
  calcStock();
}
let maxHp = 0;
function calcMaxHp(){
  maxHp = status['body'] * 2 + status['mind'] + 20 + Number(form.maxHpAdd.value);
  document.getElementById('max-hp-total').innerHTML = maxHp;
}
let initiative = 0;
function calcInitiative(){
  initiative = status['sense'] * 2 + status['mind'] + Number(form.initiativeAdd.value);
  document.getElementById('initiative-total').innerHTML = initiative;
  calcMove();
}
let move = 0;
function calcMove(){
  move = initiative + 5 + Number(form.moveAdd.value);
  document.getElementById('move-total').innerHTML = move;
  document.getElementById('dash-total').innerHTML = move * 2;
}
let stock = 0;
let stockUsed = 0;
function calcStock(){
  stock = status['social'] * 2 + Number(form.skillProcure.value) * 2 + Number(form.stockAdd.value);
  document.getElementById('stock-total').innerHTML = stock;
  document.getElementById("item-max-stock").innerHTML = stock;
  calcSaving();
}
function calcSaving(){
  document.getElementById('saving-total').innerHTML = stock - stockUsed + Number(form.savingAdd.value);
}
// 技能
function calcSkill() {
  exps['skill'] = -9;
  for (let name of ['Melee','Ranged','RC','Negotiate','Dodge','Percept','Will','Procure']){
    const lv = Number(form['skill'+name].value);
    for(let i = 0; i < lv; i++){ exps['skill'] += (i > 20) ? 10 : (i > 10) ? 5 : (i > 5) ? 3 : 2; }
  }
  for (let name of ['Ride','Art','Know','Info']){
    for (let num = 1; num <= Number(form.skillNum.value); num++){
      const lv = Number(form['skill'+name+num].value);
      for(let i = 0; i < lv; i++){ exps['skill'] += (i > 20) ? 10 : (i > 10) ? 5 : (i > 5) ? 3 : 1; }
    }
  }
  document.getElementById('exp-skill').innerHTML = exps['skill'];
  calcExp();
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
        exps['effect'] += 2;
      }
      //通常
      else {
        exps['effect'] += lv * 5 + 10; //lv×5 + 新規取得の差分10
        if(type.match(/^(auto|dlois)$/i)){ exps['effect'] += -15; } //自動かDロイスは新規取得ぶん減らす
      }
    }
    exps['effect'] += Number(form['effect'+num+'Exp'].value)
  }
  document.getElementById('exp-effect').innerHTML = exps['effect'];
  calcExp();
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
  document.getElementById("item-total-stock").innerHTML = stockUsed;
  document.getElementById("item-total-exp").innerHTML = exps['item'];
  document.getElementById("exp-item").innerHTML = exps['item'];
  calcSaving();
  calcExp();
}
// メモリー
function calcMemory() {
  exps['memory'] = 0;
  for (let num = 1; num <= 3; num++){
    if(form['memory'+num+'Gain'].checked){ exps['memory'] += 15; }
  }
  document.getElementById('exp-memory').innerHTML = exps['memory'];
  calcExp();
}

// 経験点
function calcExp(){
  let total = 0;
  for (let num = 0; num <= Number(form.historyNum.value); num++){
    total += Number(eval(form['history'+num+'Exp'].value)) || 0;
  }
  let rest = total;
  for (let key in exps){
    rest -= exps[key];
  }
  document.getElementById("exp-total").innerHTML = total;
  document.getElementById("exp-used-status").innerHTML = exps['status'] || 0;
  document.getElementById("exp-used-skill" ).innerHTML = exps['skill']  || 0;
  document.getElementById("exp-used-effect").innerHTML = exps['effect'] || 0;
  document.getElementById("exp-used-item"  ).innerHTML = exps['item']   || 0;
  document.getElementById("exp-used-memory").innerHTML = exps['memory'] || 0;
  document.getElementById("exp-rest").innerHTML = rest;
}

// 侵蝕値 ----------------------------------------
function calcEncroach(){
  const awaken  = awakens[form.lifepathAwaken.value]   || 0;
  const impulse = impulses[form.lifepathImpulse.value] || 0;
  const other   = Number(form.lifepathOtherEncroach.value);
  document.getElementById('awaken-encroach' ).innerHTML = awaken;
  document.getElementById('impulse-encroach').innerHTML = impulse;
  document.getElementById('base-encroach').innerHTML = awaken + impulse + other;
}

// ロイス ----------------------------------------
function emoP(num){ form["lois"+num+"EmoNegaCheck"].checked = false; }
function emoN(num){ form["lois"+num+"EmoPosiCheck"].checked = false; }
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
        document.querySelector(`#${id} [name$="State"]`   ).setAttribute('name',`memory${num}State`);
        num++;
      }
    }
  }
});

// 技能欄 ----------------------------------------
// 追加
function addSkill(){
  let num = Number(form.skillNum.value) + 1;
  let tbody = document.createElement('tr');
  tbody.innerHTML = `
    <td class="left"><input name="skillRide${num}Name" type="text" list="list-ride"></td>
    <td class="right"><input name="skillRide${num}" type="number" oninput="calcSkill()"></td>
    <td class="left"><input name="skillArt${num}Name" type="text" list="list-art"></td>
    <td class="right"><input name="skillArt${num}" type="number" oninput="calcSkill()"></td>
    <td class="left"><input name="skillKnow${num}Name" type="text" list="list-know"></td>
    <td class="right"><input name="skillKnow${num}" type="number" oninput="calcSkill()"></td>
    <td class="left"><input name="skillInfo${num}Name" type="text" list="list-info"></td>
    <td class="right"><input name="skillInfo${num}" type="number" oninput="calcSkill()"></td>
  `;
  const target = document.querySelector("#skill-table tbody");
  target.appendChild(tbody, target);
  
  form.skillNum.value = num;
}
// 削除
function delSkill(){
  let num = Number(form.skillNum.value);
  if(num > 1){
    const target = document.querySelector("#skill-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.skillNum.value = num;
  }
}

// エフェクト欄 ----------------------------------------
// 追加
function addEffect(){
  let num = Number(form.effectNum.value) + 1;
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id','effect'+num);
  tbody.innerHTML = `<tr>
    <td rowspan="2" class="handle"></td>
    <td><input name="effect${num}Name"     type="text"   placeholder="名称"></td>
    <td><input name="effect${num}Lv"       type="number" placeholder="Lv" oninput="calcEffect()"></td>
    <td><input name="effect${num}Timing"   type="text"   placeholder="タイミング" list="list-timing"></td>
    <td><input name="effect${num}Skill"    type="text"   placeholder="技能"   list="list-effect-skill"></td>
    <td><input name="effect${num}Dfclty"   type="text"   placeholder="難易度" list="list-dfclty"></td>
    <td><input name="effect${num}Target"   type="text"   placeholder="対象"   list="list-target"></td>
    <td><input name="effect${num}Range"    type="text"   placeholder="射程"   list="list-range"></td>
    <td><input name="effect${num}Encroach" type="text"   placeholder="侵蝕値"></td>
    <td><input name="effect${num}Restrict" type="text"   placeholder="制限"   list="list-restrict"></td>
  </tr>
  <tr><td colspan="9"><div>
    <b>種別</b><select name="effect${num}Type" oninput="calcEffect()">
      <option value="">
      <option value="auto">自動
      <option value="dlois">Dロイス
      <option value="easy">イージー
      <option value="enemy">エネミー
    </select>
    <b class="small">経験点修正</b><input name="effect${num}Exp" type="number" oninput="calcEffect()">
    <b>効果</b><input name="effect${num}Note" type="text">
  </div></td></tr>`;
  const target = document.querySelector("#effect-table tfoot");
  target.parentNode.insertBefore(tbody, target);
  
  form.effectNum.value = num;
}
// 削除
function delEffect(){
  let num = Number(form.effectNum.value);
  if(num > 2){
    const target = document.querySelector("#effect-table tbody:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.effectNum.value = num;
  }
}
// ソート
let effectSortable = Sortable.create(document.getElementById('effect-table'), {
  group: "effect",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function(evt){
    const order = effectSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
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
        num++;
      }
    }
  }
});

// コンボ欄 ----------------------------------------
// 追加
function addCombo(){
  let num = Number(form.comboNum.value) + 1;
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id','combo'+num);
  tbody.innerHTML = `<tr>
      <td class="handle" rowspan="7"></td>
      <th colspan="3">名称</th>
      <th colspan="8">組み合わせ</th>
    <tr>
      <td colspan="3" class="bold"><input name="combo${num}Name" type="text"></td>
      <td colspan="8"><input name="combo${num}Combo" type="text"></td>
    </tr>
    <tr><th>タイミング</th><th>技能</th><th>難易度</th><th>対象</th><th>射程</th><th>侵蝕値</th><th>条件</th><th>ダイス</th><th>Ｃ値</th><th>基準値</th><th>攻撃力</th></tr>
    <tr>
      <td><input name="combo${num}Timing"   type="text" list="list-timing"></td>
      <td><input name="combo${num}Skill"    type="text" list="list-effect-skill"></td>
      <td><input name="combo${num}Dfclty"   type="text" list="list-dfclty"></td>
      <td><input name="combo${num}Target"   type="text" list="list-target"></td>
      <td><input name="combo${num}Range"    type="text" list="list-range"></td>
      <td><input name="combo${num}Encroach" type="text"></td>
      <td><input name="combo${num}Condition1" type="text" value="100%未満"></td>
      <td><input name="combo${num}Dice1"      type="text"></td>
      <td><input name="combo${num}Crit1"      type="text"></td>
      <td><input name="combo${num}Atk1"       type="text"></td>
      <td><input name="combo${num}Fixed1"     type="text"></td>
    </tr>
    <tr>
      <td rowspan="3" colspan="6"><textarea name="combo${num}Note" rows="4" placeholder="解説"></textarea></td>
      <td><input name="combo${num}Condition2" type="text" value="100%以上"></td>
      <td><input name="combo${num}Dice2"      type="text"></td>
      <td><input name="combo${num}Crit2"      type="text"></td>
      <td><input name="combo${num}Atk2"       type="text"></td>
      <td><input name="combo${num}Fixed2"     type="text"></td>
    </tr>
    <tr>
      <td><input name="combo${num}Condition3" type="text"></td>
      <td><input name="combo${num}Dice3"      type="text"></td>
      <td><input name="combo${num}Crit3"      type="text"></td>
      <td><input name="combo${num}Atk3"       type="text"></td>
      <td><input name="combo${num}Fixed3"     type="text"></td>
    </tr>
    <tr>
      <td><input name="combo${num}Condition4" type="text"></td>
      <td><input name="combo${num}Dice4"      type="text"></td>
      <td><input name="combo${num}Crit4"      type="text"></td>
      <td><input name="combo${num}Atk4"       type="text"></td>
      <td><input name="combo${num}Fixed4"     type="text"></td>
    </tr>`;
  const target = document.querySelector("#combo-table");
  target.appendChild(tbody, target);
  
  form.comboNum.value = num;
}
// 削除
function delCombo(){
  let num = Number(form.comboNum.value);
  if(num > 1){
    const target = document.querySelector("#combo-table tbody:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.comboNum.value = num;
  }
}
// ソート
let comboSortable = Sortable.create(document.getElementById('combo-table'), {
  group: "combo",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = comboSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`combo${num}Name`);
        document.querySelector(`#${id} [name$="Combo"]`   ).setAttribute('name',`combo${num}Combo`);
        document.querySelector(`#${id} [name$="Timing"]`  ).setAttribute('name',`combo${num}Timing`);
        document.querySelector(`#${id} [name$="Skill"]`   ).setAttribute('name',`combo${num}Skill`);
        document.querySelector(`#${id} [name$="Dfclty"]`  ).setAttribute('name',`combo${num}Dfclty`);
        document.querySelector(`#${id} [name$="Target"]`  ).setAttribute('name',`combo${num}Target`);
        document.querySelector(`#${id} [name$="Range"]`   ).setAttribute('name',`combo${num}Range`);
        document.querySelector(`#${id} [name$="Encroach"]`).setAttribute('name',`combo${num}Encroach`);
        document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`combo${num}Note`);
        document.querySelector(`#${id} [name$="Condition1"]`).setAttribute('name',`combo${num}Condition1`);
        document.querySelector(`#${id} [name$="Dice1"]`     ).setAttribute('name',`combo${num}Dice1`);
        document.querySelector(`#${id} [name$="Crit1"]`     ).setAttribute('name',`combo${num}Crit1`);
        document.querySelector(`#${id} [name$="Atk1"]`      ).setAttribute('name',`combo${num}Atk1`);
        document.querySelector(`#${id} [name$="Fixed1"]`    ).setAttribute('name',`combo${num}Fixed1`);
        document.querySelector(`#${id} [name$="Condition2"]`).setAttribute('name',`combo${num}Condition2`);
        document.querySelector(`#${id} [name$="Dice2"]`     ).setAttribute('name',`combo${num}Dice2`);
        document.querySelector(`#${id} [name$="Crit2"]`     ).setAttribute('name',`combo${num}Crit2`);
        document.querySelector(`#${id} [name$="Atk2"]`      ).setAttribute('name',`combo${num}Atk2`);
        document.querySelector(`#${id} [name$="Fixed2"]`    ).setAttribute('name',`combo${num}Fixed2`);
        document.querySelector(`#${id} [name$="Condition3"]`).setAttribute('name',`combo${num}Condition3`);
        document.querySelector(`#${id} [name$="Dice3"]`     ).setAttribute('name',`combo${num}Dice3`);
        document.querySelector(`#${id} [name$="Crit3"]`     ).setAttribute('name',`combo${num}Crit3`);
        document.querySelector(`#${id} [name$="Atk3"]`      ).setAttribute('name',`combo${num}Atk3`);
        document.querySelector(`#${id} [name$="Fixed3"]`    ).setAttribute('name',`combo${num}Fixed3`);
        num++;
      }
    }
  }
});

// 武器欄 ----------------------------------------
// 追加
function addWeapon(){
  let num = Number(form.weaponNum.value) + 1;
  let tbody = document.createElement('tr');
  tbody.setAttribute('id','weapon'+num);
  tbody.innerHTML = `
    <td><input name="weapon${num}Name"  type="text"></td>
    <td><input name="weapon${num}Stock" type="number" oninput="calcItem()"></td>
    <td><input name="weapon${num}Exp"   type="number" oninput="calcItem()"></td>
    <td><input name="weapon${num}Type"  type="text" list="list-weapon-type"></td>
    <td><input name="weapon${num}Skill" type="text" list="list-weapon-skill"></td>
    <td><input name="weapon${num}Acc"   type="text"></td>
    <td><input name="weapon${num}Atk" type="text"></td>
    <td><input name="weapon${num}Guard" type="text"></td>
    <td><input name="weapon${num}Range" type="text"></td>
    <td><textarea name="weapon${num}Note" rows="2"></textarea></td>
  `;
  const target = document.querySelector("#weapon-table tbody");
  target.appendChild(tbody, target);
  
  form.weaponNum.value = num;
}
// 削除
function delWeapon(){
  let num = Number(form.weaponNum.value);
  if(num > 1){
    const target = document.querySelector("#weapon-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.weaponNum.value = num;
  }
}
// ソート
let weaponSortable = Sortable.create(document.querySelector('#weapon-table tbody'), {
  group: "weapon",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = weaponSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
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
  let tbody = document.createElement('tr');
  tbody.setAttribute('id','armor'+num);
  tbody.innerHTML = `
    <td><input name="armor${num}Name"  type="text"></td>
    <td><input name="armor${num}Stock" type="number" oninput="calcItem()"></td>
    <td><input name="armor${num}Exp"   type="number" oninput="calcItem()"></td>
    <td><input name="armor${num}Type"  type="text" value="防具" list="list-armor-type"></td>
    <td></td>
    <td><input name="armor${num}Initiative" type="text"></td>
    <td><input name="armor${num}Dodge"      type="text"></td>
    <td><input name="armor${num}Armor"      type="text"></td>
    <td><textarea name="armor${num}Note" rows="2"></textarea></td>
  `;
  const target = document.querySelector("#armor-table tbody");
  target.appendChild(tbody, target);
  form.armorNum.value = num;
}
// 削除
function delArmor(){
  let num = Number(form.armorNum.value);
  if(num > 1){
    const target = document.querySelector("#armor-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.armorNum.value = num;
  }
}
// ソート
let armorSortable = Sortable.create(document.querySelector('#armor-table tbody'), {
  group: "armor",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = armorSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
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
  let tbody = document.createElement('tr');
  tbody.setAttribute('id','vehicle'+num);
  tbody.innerHTML = `
    <td><input name="vehicle${num}Name"  type="text"></td>
    <td><input name="vehicle${num}Stock" type="number" oninput="calcItem()"></td>
    <td><input name="vehicle${num}Exp"   type="number" oninput="calcItem()"></td>
    <td><input name="vehicle${num}Type"  type="text" value="ヴィークル"></td>
    <td><input name="vehicle${num}Skill" type="text" list="list-vehicle-skill"></td>
    <td><input name="vehicle${num}Initiative" type="text"></td>
    <td><input name="vehicle${num}Atk"        type="text"></td>
    <td><input name="vehicle${num}Armor"      type="text"></td>
    <td><input name="vehicle${num}Dash"       type="text"></td>
    <td><textarea name="vehicle${num}Note" rows="2"></textarea></td>
  `;
  const target = document.querySelector("#vehicle-table tbody");
  target.appendChild(tbody, target);
  form.vehicleNum.value = num;
}
// 削除
function delVehicle(){
  let num = Number(form.vehicleNum.value);
  if(num > 0){
    const target = document.querySelector("#vehicle-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.vehicleNum.value = num;
  }
}
// ソート
let vehicleSortable = Sortable.create(document.querySelector('#vehicle-table tbody'), {
  group: "armor",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = vehicleSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
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
  let tbody = document.createElement('tr');
  tbody.setAttribute('id','item'+num);
  tbody.innerHTML = `
    <td><input name="item${num}Name"  type="text"></td>
    <td><input name="item${num}Stock" type="number" oninput="calcItem()"></td>
    <td><input name="item${num}Exp"   type="number" oninput="calcItem()"></td>
    <td><input name="item${num}Type"  type="text" list="list-item-type"></td>
    <td><input name="item${num}Skill" type="text" list="list-item-skill"></td>
    <td><textarea name="item${num}Note" rows="2"></textarea></td>
  `;
  const target = document.querySelector("#item-table tbody");
  target.appendChild(tbody, target);
  
  form.itemNum.value = num;
}
// 削除
function delItem(){
  let num = Number(form.itemNum.value);
  if(num > 1){
    const target = document.querySelector("#item-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.itemNum.value = num;
  }
}
// ソート
let itemSortable = Sortable.create(document.querySelector('#item-table tbody'), {
  group: "armor",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = itemSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
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
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id','history'+num);
  tbody.innerHTML = `<tr>
    <td rowspan="2" class="handle"></td>
    <td rowspan="2"><input name="history${num}Date"   type="text"></td>
    <td rowspan="2"><input name="history${num}Title"  type="text"></td>
    <td><input name="history${num}Exp"    type="text" oninput="calcExp()"></td>
    <td><input name="history${num}Gm"     type="text"></td>
    <td><input name="history${num}Member" type="text"></td>
  </tr>
  <tr><td colspan="5" class="left"><input name="history${num}Note" type="text"></td></tr>`;
  const target = document.querySelector("#history-table tfoot");
  target.parentNode.insertBefore(tbody, target);
  
  form.historyNum.value = num;
}
// 削除
function delHistory(){
  let num = Number(form.historyNum.value);
  if(num > 1){
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
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
        num++;
      }
    }
  }
});


// 画像配置 ----------------------------------------
function imagePosition(){
  const bgSize = form.imageFit.options[form.imageFit.selectedIndex].value;
  document.getElementById("image").style.backgroundSize = bgSize;
  if(bgSize === 'percent'){
    document.getElementById("image").style.backgroundSize = form.imagePercent.value + '%';
    document.getElementById("image").style.backgroundPositionX = form.imagePositionX.value + '%';
    document.getElementById("image").style.backgroundPositionY = form.imagePositionY.value + '%';
  }
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

// セクション選択 //
function sectionSelect(id){
  const sections = ['common','palette','color'];
  sections.forEach( (value) => {
    document.getElementById('section-'+value).style.display = 'none';
  });
  document.getElementById('section-'+id).style.display = 'block';
}



