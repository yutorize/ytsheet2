"use strict";
const gameSystem = 'sw2';
const itemForms = document.getElementById('item-forms');

window.onload = function() {
  new RecordListEditor(document.getElementById('item-records'), {
    setupRecord: setupItemForm,
    onChange: updateItemPageTitle,
  });

  changeColor();
  deleteLoadingArea();
}

// 送信前チェック ----------------------------------------
function formCheck(){
  const emptyName = [...form.querySelectorAll('.item-form-name input')].find(input => input.value === '');
  if(emptyName){
    alert('名称を入力してください。');
    emptyName.focus();
    return false;
  }
  if(!formPasswordCheck()){
    return false;
  }
  return true;
}

// アイテムデータ欄 ----------------------------------------
function setupItemForm(item) {
  checkCategory(item.querySelector('[list="list-category"]'));
  item.querySelectorAll('.input-arms-data').forEach(table => {
    setSortable(table.dataset.arms, `#${table.id} tbody`, 'tr');
  });
  item.querySelector('.item-form-name input').addEventListener('input', setItemName);
}

function updateItemPageTitle(count) {
  const multipleItems = count > 1;
  document.getElementById('item-page-title').hidden = !multipleItems;
  form.pageTitle.disabled = !multipleItems;
  setItemName();
}

function setItemName() {
  const hasTitle = !form.pageTitle.disabled && form.pageTitle.value.trim() !== '';
  const nameInput = hasTitle ? form.pageTitle : itemForms.querySelector('.item-form-name input');
  setName(nameInput.name);
}

function checkCategory(input) {
  input.closest('.item-form').classList.toggle('is-ranged-weapon', /投擲|ボウ|クロスボウ|ガン/.test(input.value));
}

// 武器・防具データ欄 ----------------------------------------
function addArms(name) {
  const numKey = `${name}Num`;
  document.getElementById(`${name}-table`).tBodies[0].append(createRow(name, numKey));
  form[numKey].dispatchEvent(new Event('change', { bubbles: true }));
}

function delArms(name) {
  delRow(`${name}Num`, `#${name}-table tbody tr:last-of-type`);
}
