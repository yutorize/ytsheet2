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
  document.querySelector("#weapons-table tbody").append(createRow('weapon','weaponNum'));
}
// 削除
function delWeapon(){
  delRow('weaponNum', '#weapons-table tbody tr:last-of-type');
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
  document.querySelector("#armours-table tbody").append(createRow('armour','armourNum'));
}
// 削除
function delArmour(){
  delRow('armourNum', '#armours-table tbody tr:last-of-type');
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