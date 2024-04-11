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
  const stamina = 5 + Number(form.vitality.value) + Number(form.staminaAdd.value);
  document.getElementById('stamina-value').textContent = stamina;
  document.getElementById('stamina-half' ).textContent = parseInt(stamina / 2);
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
    document.getElementById('battle-level-value').textContent = Number(form.level.value);
    document.getElementById('battle-subtotal-'+stt.toLowerCase()).textContent = subtotal;
    document.getElementById('battle-total-'+stt.toLowerCase()).textContent = total;

    if(stt == 'Str'){
      document.getElementById('hp-value').textContent = total + Number(form.hpAdd.value);
    }
  }
}
// 戦闘値 ----------------------------------------
function calcResultPoint(){
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
  const total = Number(form.history0Result.value || 0) + history;
  const cost = commify(goods + items);
  const rest = commify(total - cost);
  document.getElementById('history0-exp'        ).textContent = form.history0Result.value;
  document.getElementById('history-result-total').textContent = commify(history);
  document.getElementById('resultpoint-history' ).textContent = commify(history);
  document.getElementById('resultpoint-cost'    ).textContent = cost;
  document.getElementById('resultpoint-total'   ).textContent = rest;
  document.getElementById('result-total'     ).textContent = commify(total);
  document.getElementById('result-used-goods').textContent = goods;
  document.getElementById('result-used-items').textContent = items;
  document.getElementById('result-rest'      ).textContent = rest;
}

// グッズ欄 ----------------------------------------
// 追加
function addGoods(){
  let num = Number(form.goodsNum.value) + 1;

  let row = document.querySelector('#goods-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('goods');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#goods-table tbody").append(row);
  
  form.goodsNum.value = num;
}
// 削除
function delGoods(){
  let num = Number(form.goodsNum.value);
  if(num > 1){
    if ( form[`goods${num}Name`].value
      || form[`goods${num}Type`].value
      || form[`goods${num}Cost`].value
      || form[`goods${num}Note`].value
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
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = goodsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
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

  let row = document.querySelector('#item-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('item');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#items-table tbody").append(row);
  
  form.itemsNum.value = num;
}
// 削除
function delItem(){
  let num = Number(form.itemsNum.value);
  if(num > 1){
    if ( form[`item${num}Name`].value
      || form[`item${num}Type`].value
      || form[`item${num}Cost`].value
      || form[`item${num}Note`].value
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
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = itemsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`).setAttribute('name',`item${num}Name`);
        document.querySelector(`#${id} [name$="Type"]`).setAttribute('name',`item${num}Type`);
        document.querySelector(`#${id} [name$="Lv"]`  ).setAttribute('name',`item${num}Lv`);
        document.querySelector(`#${id} [name$="Cost"]`).setAttribute('name',`item${num}Cost`);
        document.querySelector(`#${id} [name$="Note"]`).setAttribute('name',`item${num}Note`);
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
    if ( form[`history${num}Date`  ].value
      || form[`history${num}Title` ].value
      || form[`history${num}Result`].value
      || form[`history${num}Gm`    ].value
      || form[`history${num}Member`].value
      || form[`history${num}Note`  ].value
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
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = historySortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tbody#${id}`)){
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

