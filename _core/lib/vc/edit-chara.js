"use strict";
const gameSystem = 'ar2e';

window.onload = function() {
  nameSet();

  calcStatus();
  calcBattle();
  calcResultPoint();
  
  imagePosition();
  changeColor();
};

// 送信前チェック ----------------------------------------
//function formCheck(){
//  if(form.characterName.value === '' && form.aka.value === ''){
//    alert('キャラクター名か二つ名のいずれかを入力してください。');
//    form.characterName.focus();
//    return false;
//  }
//  if(form.protect.value === 'password' && form.pass.value === ''){
//    alert('パスワードが入力されていません。');
//    form.pass.focus();
//    return false;
//  }
//  return true;
//}

// レギュレーション ----------------------------------------
function changeRegu(){
}

// 能力値 ----------------------------------------
function calcStatus(){
  const stamina = Number(form.vitality.value) + Number(form.staminaAdd.value);
  document.getElementById('stamina-value').innerHTML = stamina;
  document.getElementById('stamina-half' ).innerHTML = parseInt(stamina / 2);
}

// 戦闘値 ----------------------------------------
function calcBattle(){
  for(const stt of ['Acc','Spl','Eva','Atk','Det','Def','Mdf','Ini','Str']){
    const subtotal = Number(form['battleBase'+stt].value) + Number(form['battleRace'+stt].value);
    let total = subtotal;
    for(const type of ['Weapon','Head','Body','Acc1','Acc2','Other']){
      total += Number(form['battle'+type+stt].value);
    }
    total += Number(form.level.value);
    document.getElementById('battle-level-value').innerHTML = Number(form.level.value);
    document.getElementById('battle-subtotal-'+stt.toLowerCase()).innerHTML = subtotal;
    document.getElementById('battle-total-'+stt.toLowerCase()).innerHTML = total;

    if(stt == 'Str'){
      document.getElementById('hp-value').innerHTML = total + Number(form.hpAdd.value);
    }
  }
}
// 戦闘値 ----------------------------------------
function calcResultPoint(){
  let total = Number(form.history0Result.value) || 0;
  let history = 0;
  let goods = 0;
  let items = 0;
  for (let num = 1; num <= Number(form.historyNum.value); num++) {
    history += safeEval(form[`history${num}Result`].value);
  }
  for (let num = 1; num <= Number(form.goodsNum.value); num++) {
    goods += Number(form[`goods${num}Cost`].value);
  }
  for (let num = 1; num <= Number(form.itemsNum.value); num++) {
    items += Number(form[`item${num}Cost`].value);
  }
  const cost = commify(goods + items);
  const rest = commify(total + history - cost);
  document.getElementById('history0-exp'        ).innerHTML = form.history0Result.value;
  document.getElementById('history-result-total').innerHTML = commify(history);
  document.getElementById('resultpoint-history' ).innerHTML = commify(history);
  document.getElementById('resultpoint-cost'    ).innerHTML = cost;
  document.getElementById('resultpoint-total'   ).innerHTML = rest;
  document.getElementById('result-total'     ).innerHTML = commify(total);
  document.getElementById('result-used-goods').innerHTML = goods;
  document.getElementById('result-used-items').innerHTML = items;
  document.getElementById('result-rest'      ).innerHTML = rest;
}

// グッズ欄 ----------------------------------------
// 追加
function addGoods(){
  let num = Number(form.goodsNum.value) + 1;
  let tr = document.createElement('tr');
  tr.setAttribute('id',idNumSet('goods'));
  tr.innerHTML = `
    <td class="handle"></td>
    <td><input name="goods${num}Name" type="text"></td>
    <td><input name="goods${num}Type" type="text" list="list-goods-type"></td>
    <td><input name="goods${num}Cost" type="number"></td>
    <td><input name="goods${num}Note" type="text"></td>
  `;
  document.querySelector("#goods-table tbody tr:last-of-type").after(tr);
  
  form.goodsNum.value = num;
}
// 削除
function delGoods(){
  let num = Number(form.goodsNum.value);
  if(num > 1){
    if(form[`goods${num}Name`].value || 
       form[`goods${num}Type`].value || 
       form[`goods${num}Cost`].value || 
       form[`goods${num}Note`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#goods-table tbody tr:last-of-type").remove();

    form.goodsNum.value = num - 1;
  }
}
// ソート
let goodsSortable = Sortable.create(document.querySelector("#goods-table tbody"), {
  group: "goods",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  scroll: true,
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = goodsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Name"]`  ).setAttribute('name',`goods${num}Name`);
        document.querySelector(`#${id} [name$="Type"]`  ).setAttribute('name',`goods${num}Type`);
        document.querySelector(`#${id} [name$="Cost"]`  ).setAttribute('name',`goods${num}Cost`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`goods${num}Note`);
        num++;
      }
    }
  }
});
//アイテム欄 ----------------------------------------
// 追加
function addItem(){
  let num = Number(form.itemsNum.value) + 1;
  let tr = document.createElement('tr');
  tr.setAttribute('id',idNumSet('item'));
  tr.innerHTML = `
    <td class="handle"></td>
    <td><input name="item${num}Name" type="text"></td>
    <td><input name="item${num}Type" type="text" list="list-item-type"></td>
    <td><input name="item${num}Lv"   type="number"></td>
    <td><input name="item${num}Cost" type="number"></td>
    <td><input name="item${num}Note" type="text"></td>
  `;
  document.querySelector("#items-table tbody tr:last-of-type").after(tr);
  
  form.itemsNum.value = num;
}
// 削除
function delItem(){
  let num = Number(form.itemsNum.value);
  if(num > 1){
    if(form[`item${num}Name`].value || 
       form[`item${num}Type`].value || 
       form[`item${num}Cost`].value || 
       form[`item${num}Note`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#items-table tbody tr:last-of-type").remove();

    form.itemsNum.value = num - 1;
  }
}
// ソート
let itemsSortable = Sortable.create(document.querySelector("#items-table tbody"), {
  group: "items",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  scroll: true,
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = itemsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Name"]`).setAttribute('name',`items${num}Name`);
        document.querySelector(`#${id} [name$="Type"]`).setAttribute('name',`items${num}Type`);
        document.querySelector(`#${id} [name$="Lv"]`  ).setAttribute('name',`items${num}Lv`);
        document.querySelector(`#${id} [name$="Cost"]`).setAttribute('name',`items${num}Cost`);
        document.querySelector(`#${id} [name$="Note"]`).setAttribute('name',`items${num}Note`);
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
    <td><input name="history${num}Result"  type="text" oninput="calcResult()"></td>
    <td><input name="history${num}Gm"      type="text"></td>
    <td><input name="history${num}Member"  type="text"></td>
  </tr>
  <tr><td colspan="5" class="left"><input name="history${num}Note" type="text"></td></tr>`;
  document.querySelector("#history-table tbody:last-of-type").after(tbody);
  
  form.historyNum.value = num;
}
// 削除
function delHistory(){
  let num = Number(form.historyNum.value);
  if(num > 1){
    if(form[`history${num}Date`  ].value || 
       form[`history${num}Title` ].value || 
       form[`history${num}Result`].value || 
       form[`history${num}Gm`    ].value || 
       form[`history${num}Member`].value || 
       form[`history${num}Note`  ].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#history-table tbody:last-of-type").remove();

    form.historyNum.value = num - 1;
    calcExp(); calcCash();
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
        document.querySelector(`#${id} [name$="Result"]`).setAttribute('name',`history${num}Result`);
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
        num++;
      }
    }
  }
});

