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

// 武器データ欄 ----------------------------------------
// 追加
function addWeapon(){
  let num = Number(form.weaponNum.value) + 1;

  let row = document.getElementById('weapon-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('weapon');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#weapons-table tbody").append(row);

  form.weaponNum.value = num;
}
// 削除
function delWeapon(){
  let num = Number(form.weaponNum.value);
  if(num > 1){
    if ( form[`weapon${num}Usage`].value
      || form[`weapon${num}Reqd`].value
      || form[`weapon${num}Acc`].value
      || form[`weapon${num}Rate`].value
      || form[`weapon${num}Crit`].value
      || form[`weapon${num}Note`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#weapons-table tbody tr:last-of-type").remove();
    num--;
    form.weaponNum.value = num;
  }
}
// ソート
let weaponsSortable = Sortable.create(document.querySelector('#weapons-table tbody'), {
  group: "weapons",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = weaponsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Usage"]`   ).setAttribute('name',`weapon${num}Usage`);
        document.querySelector(`#${id} [name$="Reqd"]`    ).setAttribute('name',`weapon${num}Reqd`);
        document.querySelector(`#${id} [name$="Acc"]`     ).setAttribute('name',`weapon${num}Acc`);
        document.querySelector(`#${id} [name$="Rate"]`    ).setAttribute('name',`weapon${num}Rate`);
        document.querySelector(`#${id} [name$="Crit"]`    ).setAttribute('name',`weapon${num}Crit`);
        document.querySelector(`#${id} [name$="Dmg"]`     ).setAttribute('name',`weapon${num}Dmg`);
        document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`weapon${num}Note`);
        num++;
      }
    }
  }
});

// 防具データ欄 ----------------------------------------
// 追加
function addArmour(){
  let num = Number(form.armourNum.value) + 1;

  let row = document.getElementById('armour-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('armour');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#armours-table tbody").append(row);

  form.armourNum.value = num;
}
// 削除
function delArmour(){
  let num = Number(form.armourNum.value);
  if(num > 1){
    if ( form[`armour${num}Usage`].value
      || form[`armour${num}Reqd`].value
      || form[`armour${num}Eva`].value
      || form[`armour${num}Def`].value
      || form[`armour${num}Note`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#armours-table tbody tr:last-of-type").remove();
    num--;
    form.armourNum.value = num;
  }
}
// ソート
let armoursSortable = Sortable.create(document.querySelector('#armours-table tbody'), {
  group: "armours",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = armoursSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tr#${id}`)){
        document.querySelector(`#${id} [name$="Usage"]`   ).setAttribute('name',`armour${num}Usage`);
        document.querySelector(`#${id} [name$="Reqd"]`    ).setAttribute('name',`armour${num}Reqd`);
        document.querySelector(`#${id} [name$="Eva"]`     ).setAttribute('name',`armour${num}Eva`);
        document.querySelector(`#${id} [name$="Def"]`     ).setAttribute('name',`armour${num}Def`);
        document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`armour${num}Note`);
        num++;
      }
    }
  }
});