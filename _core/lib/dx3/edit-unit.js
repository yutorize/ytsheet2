"use strict";
const gameSystem = 'dx3';

window.onload = function() {
  console.log('=====START=====');
  setName();
  checkSheetType();
  calcCompany();
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
  if(!form.sheetSubType.value){
    alert('ユニットシートまたはカンパニーシートを選択してください。');
    form.sheetSubType[0].focus();
    return false;
  }
  return formPasswordCheck();
}

function markUnitChanged(){
  form.dispatchEvent(new Event('change'));
}

// 送信前チェック ----------------------------------------
function checkSheetType(){
  const type = form.sheetSubType.value || '';
  document.body.dataset.sheetSubType = type;
}

// メンバー ----------------------------------------
function addMember(){
  document.getElementById('member-tbody').append(createRow('member','memberNum'));
}
function delMember(){
  delRow('memberNum', '#member-tbody tr:last-of-type');
}
setSortable('member','#member-tbody','tr');

function checkMemberLeader(input){
  if(!input.checked){ return; }
  document.querySelectorAll('#member-tbody input[name$="Leader"]').forEach(checkbox => {
    if(checkbox !== input){ checkbox.checked = false; }
  });
}

// ユニットオーダー ----------------------------------------
function addOrder(){
  document.getElementById('order-tbody').append(createRow('order','orderNum'));
}
function delOrder(){
  delRow('orderNum', '#order-tbody tr:last-of-type');
}
setSortable('order','#order-tbody','tr');

// 追加施設 ----------------------------------------
function addFacility(){
  document.getElementById('facility-tbody').append(createRow('facility','facilityNum'));
}
function delFacility(){
  if(delRow('facilityNum', '#facility-tbody tr:last-of-type')){
    calcCompany();
  }
}
setSortable('facility','#facility-tbody','tr');

// カンパニー ----------------------------------------
function calcCompany(){
  const size = form.companySize.value;
  let slotMax = 0;
  let expUsed = 0;
  if(Object.hasOwn(SET.companySize, size)){
    slotMax = SET.companySize[size].slot;
    form.companySlot.value = slotMax;
    form.companySlot.readOnly = true;
    expUsed = SET.companySize[size].exp;
    form.companyExp.value = expUsed;
    form.companyExp.readOnly = true;
  }
  else {
    slotMax = toNumber(form.companySlot.value);
    form.companySlot.readOnly = false;
    expUsed = toNumber(form.companyExp.value);
    form.companyExp.readOnly = false;
  }

  expUsed += toNumber(form.exteriorExp.value);

  let slotUsed = 0;
  for (let num = 1; num <= Number(form.facilityNum.value); num++){
    slotUsed += toNumber(form[`facility${num}Slot`].value);
    expUsed  += toNumber(form[`facility${num}Exp`].value);
  }

  document.querySelector("#company-facility tfoot .exp").textContent = expUsed;
  document.querySelector("#company-facility tfoot .slot").textContent = slotUsed+'/'+slotMax;
}
