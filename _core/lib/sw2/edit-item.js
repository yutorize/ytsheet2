"use strict";
const gameSystem = 'sw2';

window.onload = function() {
  nameSet('itemName');
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
