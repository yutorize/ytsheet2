"use strict";
const gameSystem = 'sw2';

window.onload = function() {
  document.querySelectorAll('#item-forms > .item-form').forEach(setupItemForm);
  updateItemPageTitle();
  
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
    const name = table.dataset.arms;
    setSortable(name, `#${table.id} tbody`, 'tr', undefined, () => {
      form[`${name}Num`].dispatchEvent(new Event('change', { bubbles: true }));
    });
  });
}

function addItem() {
  const item = createRow('item', 'itemNum', null, 'ITEMNUM');
  document.getElementById('item-forms').append(item);
  setupItemForm(item);
  updateItemPageTitle();
  item.querySelector('.item-form-name input').focus();
  form.itemNum.dispatchEvent(new Event('change', { bubbles: true }));
}

function delItem() {
  if(delRow('itemNum', '#item-forms > .item-form:last-child', 1)){
    updateItemPageTitle();
    form.itemNum.dispatchEvent(new Event('change', { bubbles: true }));
  }
}

function updateItemPageTitle() {
  const multipleItems = Number(form.itemNum.value) > 1;
  document.getElementById('item-page-title').hidden = !multipleItems;
  document.getElementById('delete-item').disabled = !multipleItems;
  form.pageTitle.disabled = !multipleItems;
  setItemName();
}

function setItemName() {
  const hasTitle = !form.pageTitle.disabled && form.pageTitle.value.trim() !== '';
  form.pageTitle.id = hasTitle ? 'main-name' : '';
  form.itemName.id = hasTitle ? '' : 'main-name';
  setName();
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
  const numKey = `${name}Num`;
  if(delRow(numKey, `#${name}-table tbody tr:last-of-type`)){
    form[numKey].dispatchEvent(new Event('change', { bubbles: true }));
  }
}
