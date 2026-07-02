"use strict";
const gameSystem = 'ms';

window.onload = function() {
  setName();
  calcLevel();
  checkAttribute();
  checkMagi();

  changeColor();
  deleteLoadingArea();
}

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.clanName.value === ''){
    alert('クラン名を入力してください。');
    form.clanName.focus();
    return false;
  }
  if(!formPasswordCheck()){
    return false;
  }
  return true;
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
setSortable('member','#member-tbody','tr');

// 特性欄 ----------------------------------------
function checkAttribute() {
  let count = 0;
  for (let num = 1; num <= 6; num++){
    if(form['attribute'+num].value){ count++ }
  }
  document.getElementById('attribute').querySelector('.annotate').textContent
    = (count < 3) ? '特性を3つ記入してください' : '';
}

// マギ欄 ----------------------------------------
function checkMagi() {
  let count = 0;
  for (let num = 1; num <= 5; num++){
    const magi = form[`magi${num}`].value;
    if(magi){
      count++;
    }
    const hasData = SET.clanMagiData.hasOwnProperty(magi) || null;
    for (let type of ['timing','target','cond','note']){
      document.querySelector(`#magi${num} .text-${type}`).textContent = hasData ? SET.clanMagiData[magi][type] : '';
      form[`magi${num}${ucfirst(type)}`].classList.toggle('hidden', hasData);
    }
    document.querySelector(`#magi${num} .changed-name`).classList.toggle('hidden', !form[`magi${num}NC`].checked);
  }
  document.getElementById('magi').querySelector('.annotate.caution').textContent
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
setSortable('history','#history-table','tbody');
