"use strict";
const gameSystem = 'ar2e';

window.onload = function() {
  setName();

  checkEnemyType();
  calcStatus();

  changeColor();
  deleteLoadingArea();
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.enemyName.value === ''){
    alert('エネミー名を入力してください。');
    form.enemyName.focus();
    return false;
  }
  if(!formPasswordCheck()){
    return false;
  }
  return true;
}

// エネミー種別 ----------------------------------------
function checkEnemyType(){
  const isMob = form.isMob.checked;
  document.getElementById('status-mob').style.display  = isMob ? '' : 'none';
  document.getElementById('status-solo').style.display = isMob ? 'none' : '';
  document.querySelector(`dl:has(> dd > input[name="mp"])`).style.visibility = isMob ? 'hidden' : '';

  form.initiativeAuto.parentElement.style.display = isMob ? 'none' : '';
  form.mobilityAuto.parentElement.style.display   = isMob ? 'none' : '';

  calcStatus();
}

// 能力値 ----------------------------------------
function calcStatus(){
  for (const key of ['Str', 'Dex', 'Agi', 'Int', 'Sen', 'Mnd', 'Luk']) {
    form[`stt${key}`].value = Math.floor(form[`stt${key}Base`].value / 3);
  }

  const isMob = form.isMob.checked;
  // 行動値
  if(!isMob && form.initiativeAuto.checked){
    form.initiative.readOnly = true;
    form.initiative.value = toNumber(form.sttAgi.value) + toNumber(form.sttSen.value);
  }
  else {
    form.initiative.readOnly = false;
  }
  // 移動力
  if(!isMob && form.mobilityAuto.checked){
    form.mobility.readOnly = true;
    form.mobility.value = toNumber(form.sttStr.value) + 5;
  }
  else {
    form.mobility.readOnly = false;
  }
}

// 攻撃 ----------------------------------------
// 追加
function addAttack(){
  document.querySelector("#attack table tbody").append(createRow('attack','attackNum'));
}
// 削除
function delAttack(){
  delRow('attackNum', '#attack table tbody tr:last-of-type');
}
// ソート
setSortable('attack','#attack table tbody','tr');

// 戦利品欄 ----------------------------------------
// 追加
function addLoot(){
  let num = Number(form.lootNum.value) + 1;
  let liNum = document.createElement('li');
  let liItem = document.createElement('li');
  liNum.id= idNumSet("loot-num");
  liItem.id= idNumSet("loot-item");
  liNum.innerHTML = '<span class="handle"></span><input type="text" name="loot'+num+'Num">';
  liItem.innerHTML = '<span class="handle"></span><input type="text" name="loot'+num+'Item">';
  document.getElementById("loot-num").appendChild(liNum);
  document.getElementById("loot-item").appendChild(liItem);
  
  form.lootNum.value = num;
  form.dispatchEvent(new Event('change'));
}
// 削除
function delLoot(){
  let num = Number(form.lootNum.value);
  if(num > 1){
    if(form[`loot${num}Num`].value || form[`loot${num}Item`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const listNum  = document.getElementById("loot-num");
    const listItem = document.getElementById("loot-item");
    listNum.lastElementChild.remove();
    listItem.lastElementChild.remove();
    num--;
    form.lootNum.value = num;
    form.dispatchEvent(new Event('change'));
  }
}
// ソート
setSortable('loot','#loot-num');
setSortable('loot','#loot-item');
