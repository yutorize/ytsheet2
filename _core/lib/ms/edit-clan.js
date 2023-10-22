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
  let num = Number(form.memberNum.value) + 1;

  let row = document.querySelector('#member-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('member');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.getElementById('member-tbody').append(row);
  form.memberNum.value = num;
}
// 削除
function delMember(){
  let num = Number(form.memberNum.value);
  if(num > 0){
    if(form[`member${num}Name`].value || form[`member${num}URL`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#member-tbody tr:last-of-type").remove();
    num--;
    form.memberNum.value = num;
  }
  calcHonor();
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
// 追加
function addAttribute(){
  let num = Number(form.attributeNum.value) + 1;

  let li = document.createElement('li');
  li.id = idNumSet('attribute');
  li.innerHTML = `《<input type="text" name="attribute${num}">》`;
  document.querySelector("#attribute ul").append(li);
  form.attributeNum.value = num;
}
// 削除
function delAttribute(){
  let num = Number(form.attributeNum.value);
  if(num > 0){
    if( form[`attribute${num}`].value ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#attribute li:last-child").remove();
    num--;
    form.attributeNum.value = num;
  }
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
    if(form[`history${num}Date`].value || form[`history${num}Title`].value || form[`history${num}Grow`].value || form[`history${num}Gm`].value || form[`history${num}Member`].value || form[`history${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#history-table tbody:last-of-type").remove();
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
        document.querySelector(`#${id} [name$="Grow"]`  ).setAttribute('name',`history${num}Grow`);
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
        num++;
      }
    }
  }
});