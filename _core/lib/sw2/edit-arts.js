"use strict";
const gameSystem = 'sw2';

window.onload = function() {
  checkCategory();
  setSchoolItemList();
  setupMagicDatalists();
  checkMagicClass();
  document.querySelectorAll('#school-magic-list .input-data').forEach(row => checkMagicClass(row));
  setupRangeField();

  changeColor();
  deleteLoadingArea();
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
  else if(form.category.value === 'skill' && form.skillName.value === ''){
    alert('名称を入力してください。');
    form.skillName.focus();
    return false;
  }
  if(!formPasswordCheck()){
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
  else if(category == 'skill'){
    name = '【'+ruby(form.skillName.value)+'】';
  }
  let output = name || '(名称未入力)';
  document.querySelector('#header-menu > h2 > span').innerHTML = output;
  document.querySelectorAll('.color-sample .name').forEach(div => {
    div.innerHTML = output;
  })

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
    case 'skill':
      sheetKind = '特殊能力';
  }
  document.querySelector('#header-menu .menu-items > .sheet-main .sheet-kind').textContent = sheetKind ?? '';

  if (category === 'skill') {
    checkRankMode();
  }
}

// 魔法系統 ----------------------------------------
function checkMagicClass(row = document.querySelector('#data-magic .input-data')){
  const classSelect = row.querySelector('dl.class select');
  const prefix = classSelect.name.replace(/Class(?:Select)?$/, '');
  const field = suffix => row.querySelector(`[name="${prefix}${suffix}"]`);
  const magic = classSelect.value === 'free' ? row.querySelector('dl.class input').value : classSelect.value;
  const cost = field('Cost');
  let items;
  let costList = 'list-cost';
  if(magic == '練技'){
    items = ['duration'];
  }
  else if(magic == '呪歌'){
    items = ['song','condition','resist','element'];
  }
  else if(magic == '終律'){
    items = ['cost','resist','element'];
    costList = 'list-cost-song';
  }
  else if(magic == '騎芸'){
    items = ['premise','rider','part'];
  }
  else if(magic == '賦術'){
    items = ['cost','target','range','duration','resist'];
    costList = 'list-cost-alchemy';
  }
  else if(magic == '相域'){
    items = ['cost','duration','element'];
    costList = 'list-cost-geomancy';
  }
  else if(magic == '鼓咆'){
    items = ['type','rank','command','commcost'];
  }
  else if(magic == '陣率'){
    items = ['premise','condition','commcost'];
  }
  else if(magic == '占瞳'){
    items = ['type','target','range','duration'];
  }
  else if(magic == '魔装'){
    items = ['premise','part','human-form'];
  }
  else if(magic == '操気'){
    items = field('ActionTypePassive').checked
      ? ['cost','premise'] : ['cost','premise','target','range','duration','resist'];
    costList = 'list-cost-psychokinesis';
  }
  else if(magic == '呪印'){
    items = ['type','premise'];
  }
  else if(magic == '貴格'){
    items = ['type','target','premise'];
  }
  else if(magic == '魔動機術'){
    items = ['cost','target','range','duration','resist','element','sphere'];
  }
  else {
    items = ['cost','target','range','duration','resist','element'];
  }
  viewMagicInputs(items, row);
  cost.setAttribute('list', costList);
  if(costList !== 'list-cost' && cost.value === 'MP'){ cost.value = ''; }
  // 系統未設定の既存秘伝魔法には、初期値を補わない。
  if(items.includes('cost') && costList === 'list-cost' &&
      (prefix === 'magic' || magic !== '') && cost.value === ''){ cost.value = 'MP'; }
  field('ActionTypePassive').parentNode.style.display = (magic.match(/^(騎芸|操気)$/)) ? '' : 'none';
  field('ActionTypeMajor').parentNode.style.display   = (magic.match(/^(騎芸|操気)$/)) ? '' : 'none';
  row.querySelector('dl.summary').style.display   = (magic == '呪印' || magic == '貴格') ? 'none' : '';
  row.querySelector('dl.level     dt').textContent = (magic.match(/(属性|特殊)妖精魔法|秘奥魔法/)) ? 'ランク' : '習得レベル';
  row.querySelector('dl.type      dt').textContent = (magic == '鼓咆') ? '鼓咆の系統' : (magic == '占瞳') ? 'タイプなど' : (magic == '貴格') ? '形態' : '対応';
  row.querySelector('dl.premise   dt').textContent = (magic == '呪印') ? '前提ＡＣ'   : '前提';
  row.querySelector('dl.condition dt').textContent = (magic == '呪歌') ? '効果発生条件' : (magic == '陣率') ? '使用条件' : '条件';

  const levelInput = row.querySelector('dl.level dd input');
  if (magic.length === 2) {
    // 練技、呪歌など
    levelInput.setAttribute('list', 'list-craft-required-level');
  } else {
    levelInput.removeAttribute('list');
  }
  field('Target').setAttribute('list', magic.length === 2 ? 'list-target-craft' : 'list-target');
  field('Range').setAttribute('list', magic.length === 2 ? 'list-range-craft' : 'list-range');
}
function viewMagicInputs(items, row){
  row.querySelectorAll('dl').forEach(obj => {
    obj.style.display = 'none';
  });
  for (const item of ['name','class','a-cost','level','summary','effect', ...items]) {
    row.querySelectorAll(`dl.${item}`).forEach(obj => {
      obj.style.display = '';
    });
  }
}
function setupMagicDatalists(){
  // 各秘伝魔法と特殊神聖魔法が、他の行の系統に影響されないようにする。
  for(const id of ['list-target','list-range']){
    const list = document.getElementById(id).cloneNode(true);
    list.id += '-craft';
    list.querySelector('option.self').value = '自身';
    document.body.append(list);
  }
}
// 流派アイテム欄 ----------------------------------------
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
        <td><a href="${url}" target="_blank">${ruby(data.itemName||'')}</a></td>
        <td>${data?.category.replace(/\s+/g, '<hr>') ?? ''}</td>
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
  document.querySelector("#arts-list").append(createRow('school-arts','schoolArtsNum'));
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
  const row = createRow('school-magic','schoolMagicNum');
  setupRangeField(row.querySelector('input[name$="Range"]'));
  document.querySelector("#school-magic-list").append(row);
  checkMagicClass(row);
}
// 削除
function delSchoolMagic(){
  delRow('schoolMagicNum', '#school-magic-list .input-data:last-child');
}
// 並べ替え
setSortable('schoolMagic','#school-magic-list','.input-data');

// 特殊能力 ----------------------------------------
function checkRankMode() {
  const details = document.querySelector('#data-skill > .details');
  let mode;
  switch (form['skillRankMode'].value ?? '') {
    case '0':
      mode = 'no-rank';
      break;
    case '1':
      mode = 'ranks';
      break;
  }

  if (mode != null) {
    details.dataset.mode = mode;
  } else {
    delete details.dataset.mode;
  }
}

function setupRangeField(rangeField = null) {
  const rangeFields =
    (rangeField != null)
      ? [rangeField]
      : [...document.querySelectorAll('[name="magicRange"], [name^="godMagic"][name$="Range"], [name^="schoolMagic"][name$="Range"]')];

  rangeFields.forEach(rangeField =>
    rangeField.addEventListener('input', () => {
      const formField = rangeField.parentNode.querySelector(`[name$="Form"]`);
      if ((rangeField.value === '術者' || rangeField.value === '接触') && (formField.value?.trim() ?? '') === '') {
        formField.value = '―';
      }
    })
  );
}
