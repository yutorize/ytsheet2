"use strict";
const gameSystem = 'sw2';

window.onload = function() {
  checkCategory();
  setSchoolItemList();
  checkMagicClass();
  changeColor();
}

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.category.value === ''){
    alert('カテゴリを選択してください。');
    form.category.focus();
    return false;
  }
  else if(form.category.value === 'magic' && form.magicName.value === ''){
    alert('名称を入力してください。');
    form.magicName.focus();
    return false;
  }
  else if(form.category.value === 'god' && form.godName.value === ''){
    alert('名称を入力してください。');
    form.godName.focus();
    return false;
  }
  else if(form.category.value === 'school' && form.schoolName.value === ''){
    alert('名称を入力してください。');
    form.schoolName.focus();
    return false;
  }
  if(form.protect.value === 'password' && form.pass.value === ''){
    alert('パスワードが入力されていません。');
    form.pass.focus();
    return false;
  }
  return true;
}

// 名前 ----------------------------------------
function setName(){
  const category = form.category.value;
  let name;
  if(category == 'magic'){
    name = '【'+ruby(form.magicName.value)+'】';
  }
  else if(category == 'god'){
    name = (form.godAka.value ? `“${ruby(form.godAka.value)}”` : '') + ruby(form.godName.value);
  }
  else if(category == 'school'){
    name = '【'+ruby(form.schoolName.value)+'】';
  }
  document.querySelector('#header-menu > h2 > span').innerHTML = name || '(名称未入力)';

}

// カテゴリ ----------------------------------------
function checkCategory(){
  const category = form.category.value;
  document.querySelectorAll('article > form .data-area').forEach( obj => {
    obj.style.display = 'none';
  });
  if(category){
    document.getElementById('data-'+category).style.display = 'block';
    setName();
  }
  else { document.getElementById('data-none').style.display = 'block'; }

  let sheetKind;
  switch (category) {
    case 'magic':
      sheetKind = "魔法";
      break;
    case 'god':
      sheetKind = '神格';
      break;
    case 'school':
      sheetKind = '流派';
      break;
  }
  document.querySelector('#header-menu .menu-items > .sheet-main .sheet-kind').textContent = sheetKind ?? '';
}

// 魔法系統 ----------------------------------------
function checkMagicClass(){
  const magic = form.magicClass.value;
  if(magic == '練技'){
    viewMagicInputs(['duration']);
  }
  else if(magic == '呪歌'){
    viewMagicInputs(['song','condition','resist','element']);
  }
  else if(magic == '終律'){
    viewMagicInputs(['cost','resist','element']);
    if(form.magicCost.value == "MP"){ form.magicCost.value = '' }
    form.magicCost.setAttribute('list', 'list-cost-song');
  }
  else if(magic == '騎芸'){
    viewMagicInputs(['premise','rider','part']);
  }
  else if(magic == '賦術'){
    viewMagicInputs(['cost','target','range','duration','resist']);
    if(form.magicCost.value == "MP"){ form.magicCost.value = '' }
    form.magicCost.setAttribute('list', 'list-cost-alchemy');
  }
  else if(magic == '相域'){
    viewMagicInputs(['cost','duration','element']);
    if(form.magicCost.value == "MP"){ form.magicCost.value = '' }
    form.magicCost.setAttribute('list', 'list-cost-geomancy');
  }
  else if(magic == '鼓咆'){
    viewMagicInputs(['type','rank','command','commcost']);
  }
  else if(magic == '陣率'){
    viewMagicInputs(['premise','condition','commcost']);
  }
  else if(magic == '占瞳'){
    viewMagicInputs(['type','target','range','duration']);
  }
  else if(magic == '魔装'){
    viewMagicInputs(['premise','part','human-form']);
  }
  else if(magic == '操気'){
    viewMagicInputs(['cost','premise','target','range','duration','resist']);
  }
  else if(magic == '呪印'){
    viewMagicInputs(['type','premise']);
  }
  else if(magic == '貴格'){
    viewMagicInputs(['type','target','premise']);
  }
  else if(magic == '魔動機術'){
    viewMagicInputs(['cost','target','range','duration','resist','element','sphere']);
    if(form.magicCost.value == ''){ form.magicCost.value = 'MP' }
    form.magicCost.setAttribute('list', 'list-cost');
  }
  else {
    viewMagicInputs(['cost','target','range','duration','resist','element']);
    if(form.magicCost.value == ''){ form.magicCost.value = 'MP' }
    form.magicCost.setAttribute('list', 'list-cost');
  }
  form.magicActionTypePassive.parentNode.style.display = (magic.match(/^(騎芸|操気)$/)) ? '' : 'none';
  form.magicActionTypeMajor.parentNode.style.display   = (magic.match(/^(騎芸|操気)$/)) ? '' : 'none';
  document.querySelector('#data-magic dl.summary').style.display   = (magic == '呪印' || magic == '貴格') ? 'none' : '';
  document.querySelector('#data-magic dl.type      dt').textContent = (magic == '鼓咆') ? '鼓咆の系統' : (magic == '占瞳') ? 'タイプなど' : (magic == '貴格') ? '形態' : '対応';
  document.querySelector('#data-magic dl.premise   dt').textContent = (magic == '呪印') ? '前提ＡＣ'   : '前提';
  document.querySelector('#data-magic dl.condition dt').textContent = (magic == '呪歌') ? '効果発生条件' : (magic == '陣率') ? '使用条件' : '条件';

  const levelInput = document.querySelector('#data-magic dl.level dd input');
  if (magic.length === 2) {
    // 練技、呪歌など
    levelInput.setAttribute('list', 'list-craft-required-level');
  } else {
    levelInput.removeAttribute('list');
  }
}
function viewMagicInputs(items){
  document.querySelectorAll(`#data-magic dl`).forEach(obj => {
    obj.style.display = 'none';
  });
  items.unshift('name','class','level','summary','effect');
  for (const item of items) {
    document.querySelectorAll(`#data-magic dl.${item}`).forEach(obj => {
      obj.style.display = '';
    });
  }
}
// 流派装備欄 ----------------------------------------
// 追加
let schoolItems = [];
let errorGetItem
async function setSchoolItemList(){
  if(form.schoolItemList.value){
    schoolItems = Array.from(new Set(form.schoolItemList.value.split(',')));
  }
}
async function addSchoolItem(){
  const urlForm = document.getElementById('schoolItemUrl');
  const url = urlForm.value;
  if(!url){ return; }
  if(!schoolItems.includes(url)){
    const data = await getYtsheetJSON(url);
    if(data){
      if(data.itemName == null){ alert('アイテムデータではありません。'); return; }
      let tr = document.createElement('tr');
      tr.setAttribute('class','item-data');
      tr.innerHTML = `
        <td><a href="${url}">${ruby(data.itemName||'')}</a></td>
        <td>${data.category||''}</td>
        <td>${data.summary ||''}</td>
        <td class="button" onclick="delSchoolItem(this,'${url}')">×</td>
      `;
      document.querySelector("#school-item-list tbody").appendChild(tr);
      schoolItems.push(url);
      form.schoolItemList.value = schoolItems.join(',');
      urlForm.value = "";
    }
  }
  else {
    alert('そのデータは追加済みです');
    urlForm.value = "";
  }
}

// 削除
function delSchoolItem(obj, url){
  obj.parentNode.remove();
  schoolItems = schoolItems.filter(n => n != url);
  console.log(url,schoolItems);
  form.schoolItemList.value = schoolItems.join(',');
}
// 秘伝欄 ----------------------------------------
// 追加
function addSchoolArts(){
  document.querySelector("#arts-list").append(createRow('arts','schoolArtsNum'));
}
// 削除
function delSchoolArts(){
  delRow('schoolArtsNum', '#arts-list .input-data:last-child');
}
// 並べ替え
setSortable('schoolArts','#arts-list','.input-data');

// 秘伝魔法欄 ----------------------------------------
// 追加
function addSchoolMagic(){
  document.querySelector("#school-magic-list").append(createRow('school-magic','schoolMagicNum'));
}
// 削除
function delSchoolMagic(){
  delRow('schoolMagicNum', '#school-magic-list .input-data:last-child');
}
// 並べ替え
setSortable('schoolMagic','#school-magic-list','.input-data');
