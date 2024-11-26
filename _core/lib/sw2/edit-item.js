"use strict";
const gameSystem = 'sw2';

window.onload = function() {
  setName('itemName');
  checkCategory();
  changeColor();
}

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.itemName.value === ''){
    alert('名称を入力してください。');
    form.itemName.focus();
    return false;
  }
  if(form.protect.value === 'password' && form.pass.value === ''){
    alert('パスワードが入力されていません。');
    form.pass.focus();
    return false;
  }
  return true;
}

// 入力値による挙動の変化 ----------------------------------------
function checkCategory() {
  const category = document.querySelector('[name="category"]').value?.trim() ?? '';
  document.getElementById('section-common').classList.toggle(
      'is-ranged-weapon',
      /投擲|ボウ|クロスボウ|ガン/.test(category)
  );
}
// 武器データ欄 ----------------------------------------
// 追加
function addWeapon(){
  document.querySelector("#weapons-table tbody").append(createRow('weapon','weaponNum'));
}
// 削除
function delWeapon(){
  delRow('weaponNum', '#weapons-table tbody tr:last-of-type');
}
// ソート
setSortable('weapon','#weapons-table tbody','tr');

// 防具データ欄 ----------------------------------------
// 追加
function addArmour(){
  document.querySelector("#armours-table tbody").append(createRow('armour','armourNum'));
}
// 削除
function delArmour(){
  delRow('armourNum', '#armours-table tbody tr:last-of-type');
}
// ソート
setSortable('armour','#armours-table tbody','tr');
