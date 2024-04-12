"use strict";
const gameSystem = 'ms';

window.onload = function() {
  nameSet();
  calcLevel();
  checkAttribute();
  checkMagi();

  changeColor();
}

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.clanName.value === ''){
    alert('クラン名を入力してください。');
    form.clanName.focus();
    return false;
  }
  if(form.protect.value === 'password' && form.pass.value === ''){
    alert('パスワードが入力されていません。');
    form.pass.focus();
    return false;
  }
  return true;
}

// 名前 ----------------------------------------
function nameSet(){
  let c = ruby(form.clanName.value);
  document.querySelector('#header-menu > h2 > span').innerHTML = c ?? '(名称未入力)';

  function vCheck(id){
    if(form[id]){ return form[id].value; }
    else { return '' }
  }
}

// 強度計算 ----------------------------------------
let level = 0;
function calcLevel(){
  level = 0;
  for (let num = 1; num <= Number(form.historyNum.value); num++){
    const obj = form['history'+num+'Level'];
    let lv = safeEval(obj.value);
    if(isNaN(lv)){
      obj.classList.add('error');
    }
    else {
      level += lv;
      obj.classList.remove('error');
    }
  }
  document.getElementById("level-value").textContent = level;
  document.getElementById("history-level-total").textContent = level;
}

// メンバー欄 ----------------------------------------
// 追加
function addMember(){
  document.getElementById('member-tbody').append(createRow('member','memberNum'));
}
// 削除
function delMember(){
  delRow('memberNum', '#member-tbody tr:last-of-type');
}
// ソート
let memberSortable = Sortable.create(document.querySelector('#member-tbody'), {
  group: "member",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = memberSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Name"]`).setAttribute('name',`member${num}Name`);
        document.querySelector(`#${id} [name$="URL"]`).setAttribute('name',`member${num}URL`);
        num++;
      }
    }
  }
});
// 特性欄 ----------------------------------------
function checkAttribute() {
  let count = 0;
  for (let num = 1; num <= 6; num++){
    if(form['attribute'+num].value){ count++ }
  }
  document.getElementById('attribute').querySelector('.error').textContent
    = (count < 3) ? '特性を3つ記入してください' : '';
}

// マギ欄 ----------------------------------------
function checkMagi() {
  let count = 0;
  for (let num = 1; num <= 4; num++){
    if(form['magi'+num+'Name'].value){ count++ }
  }
  document.getElementById('magi').querySelector('.error').textContent
    = (count < 2) ? 'マギを《スクランブル！》と合わせて2つ取得してください' : '';
}

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  document.querySelector("#history-table tfoot").before(createRow('history','historyNum'));
}
// 削除
function delHistory(){
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcLevel();
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
        document.querySelector(`#${id} [name$="Grow"]`  ).setAttribute('name',`history${num}Grow`);
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
        num++;
      }
    }
  }
});