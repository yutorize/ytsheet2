"use strict";
const gameSystem = 'sw2';
const itemForms = document.getElementById('item-forms');
const itemOrderList = document.getElementById('item-order-list');

window.onload = function() {
  Array.from(itemForms.children).forEach(setupItemForm);
  syncItemOrder();
  Sortable.create(itemOrderList, {
    handle: '.handle',
    animation: 150,
    onUpdate: changeItemOrder,
  });
  itemOrderList.addEventListener('click', moveItem);
  
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
  const row = document.getElementById('item-order-row-template').content.firstElementChild.cloneNode(true);
  const itemName = item.querySelector('.item-form-name input');
  const link = row.querySelector('.item-order-name');
  row.dataset.itemNumber = item.dataset.itemNumber;
  link.href = `#${item.id}`;
  function updateLabel() {
    link.textContent = itemName.value.trim() || `アイテム ${row.dataset.itemNumber}`;
  }
  updateLabel();
  itemName.addEventListener('input', () => {
    updateLabel();
    if(itemName.id === 'main-name'){ setName(); }
  });
  itemOrderList.append(row);
}

function addItem() {
  const number = Number(form.itemLastNumber.value) + 1;
  if(!Number.isSafeInteger(number)){ return; }
  const item = document.getElementById('item-template').content.firstElementChild.cloneNode(true);
  item.id = `item-row${number}`;
  item.dataset.itemNumber = number;
  item.innerHTML = item.innerHTML.replaceAll('ITEMNUM', number);
  form.itemLastNumber.value = number;
  itemForms.append(item);
  setupItemForm(item);
  changeItemOrder();
  item.querySelector('.item-form-name input').focus();
}

function delItem() {
  if(itemForms.children.length <= 1 || !delRowNode('#item-forms > .item-form:last-child')){ return; }
  itemOrderList.lastElementChild.remove();
  changeItemOrder();
}

function moveItem(event) {
  const button = event.target.closest('button[data-direction]');
  if(!button){ return; }
  const row = button.closest('li');
  if(button.dataset.direction === '-1'){
    if(!row.previousElementSibling){ return; }
    row.previousElementSibling.before(row);
  }
  else {
    if(!row.nextElementSibling){ return; }
    row.nextElementSibling.after(row);
  }
  changeItemOrder();
  (button.disabled ? row.querySelector('.item-order-name') : button).focus();
}

function changeItemOrder() {
  syncItemOrder();
  form.itemFormOrder.dispatchEvent(new Event('change', { bubbles: true }));
}

function syncItemOrder() {
  const rows = Array.from(itemOrderList.children);
  rows.forEach((row, index) => {
    const item = document.getElementById(`item-row${row.dataset.itemNumber}`);
    if(item !== itemForms.children[index]){ itemForms.insertBefore(item, itemForms.children[index]); }
    row.querySelector('[data-direction="-1"]').disabled = index === 0;
    row.querySelector('[data-direction="1"]').disabled = index === rows.length - 1;
  });
  form.itemFormOrder.value = rows.map(row => row.dataset.itemNumber).join(',');
  form.itemNum.value = rows.length;
  const multipleItems = rows.length > 1;
  document.getElementById('item-order').hidden = !multipleItems;
  document.getElementById('item-page-title').hidden = !multipleItems;
  document.getElementById('delete-item').disabled = !multipleItems;
  form.pageTitle.disabled = !multipleItems;
  setItemName();
}

function setItemName() {
  const hasTitle = !form.pageTitle.disabled && form.pageTitle.value.trim() !== '';
  document.getElementById('main-name')?.removeAttribute('id');
  const nameInput = hasTitle ? form.pageTitle : itemForms.querySelector('.item-form-name input');
  nameInput.id = 'main-name';
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
