"use strict";
const gameSystem = 'dx3';

window.onload = function() {
  console.log('=====START=====');
  setName();
  changeColor();
  deleteLoadingArea();
  console.log('=====LOADED=====');
}

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.unitName.value === ''){
    alert('ユニット名を入力してください。');
    form.unitName.focus();
    return false;
  }
  return formPasswordCheck();
}

function markUnitChanged(){
  form.dispatchEvent(new Event('change'));
}

// メンバー ----------------------------------------
function addMember(){
  document.getElementById('member-table').append(createRow('member','memberNum'));
  markUnitChanged();
}
function delMember(){
  if(delRow('memberNum', '#member-table tbody:last-of-type')){
    markUnitChanged();
  }
}
setSortable('member','#member-table','tbody', null, markUnitChanged);

// ユニットオーダー ----------------------------------------
function addOrder(){
  document.getElementById('order-tbody').append(createRow('order','orderNum'));
  markUnitChanged();
}
function delOrder(){
  if(delRow('orderNum', '#order-tbody tr:last-of-type')){
    markUnitChanged();
  }
}
setSortable('order','#order-tbody','tr', null, markUnitChanged);
