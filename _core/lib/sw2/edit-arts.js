"use strict";
const gameSystem = 'sw2';
const magicForms = document.getElementById('magic-forms');
const sheetMagicClassSelect = document.querySelector('#magic-class select');

window.onload = function() {
  setupMagicDatalists();
  if(form.magicDataCustom.value === '1'){ restoreMagicClass(sheetMagicClassSelect); }
  new RecordListEditor(document.getElementById('magic-records'), {
    setupRecord: checkMagicClass,
    onChange: updateMagicPageTitle,
  });
  checkCategory();
  setSchoolItemList();
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
  else if(form.category.value === 'magic'){
    const names = Array.from(magicForms.children, row => form.elements[row.dataset.recordName]);
    const emptyName = names.find(input => input.value.trim() === '');
    if(emptyName){
      alert('名称を入力してください。');
      emptyName.focus();
      return false;
    }
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
    const pageTitle = !form.magicPageTitle.disabled && form.magicPageTitle.value.trim();
    const firstName = form.elements[magicForms.firstElementChild.dataset.recordName].value;
    name = pageTitle ? ruby(pageTitle) : '【'+ruby(firstName)+'】';
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

function updateMagicPageTitle(count){
  document.getElementById('magic-page-title').hidden = count <= 1;
  form.magicPageTitle.disabled = count <= 1;
  if(form.category.value === 'magic'){ setName(); }
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

// 魔法系統・可変項目 ----------------------------------------
const magicDataStates = new WeakMap();
function magicDataFieldId(label){
  return Object.hasOwn(ARTS_MAGIC_DATA.aliases,label) ? ARTS_MAGIC_DATA.aliases[label] : undefined;
}
function magicClassSelectFor(row){
  return row.dataset.recordName ? sheetMagicClassSelect : row.querySelector('dl.class select');
}
function magicDataPrefix(row){
  if(row.dataset.recordName){ return row.dataset.recordName.replace(/Name$/, ''); }
  return row.querySelector('dl.class select').name.replace(/Class(?:Select)?$/, '');
}
function restoreMagicClass(select){
  select.nextElementSibling.value = select.value;
  select.value = 'free';
  selectInputCheck(select);
}
function updateMagicClass(){
  form.magicDataCustom.value = sheetMagicClassSelect.value === 'free' ? '1' : '0';
  for(const row of magicForms.children){ checkMagicClass(row); }
}
function magicDataRows(row){
  return [...row.querySelectorAll('.magic-data-row')].map(item => ({
    label: item.querySelector('[name$="Label"]').value,
    value: item.querySelector('[name$="Value"]').value,
  }));
}
function rememberMagicData(row, state){
  const seen = new Set();
  for(const item of magicDataRows(row)){
    state.byLabel.set(item.label,item.value);
    const id = magicDataFieldId(item.label);
    if(id && !seen.has(id)){ state.byId.set(id,item.value); seen.add(id); }
  }
}
function createMagicDataRow(row, label = '', value = ''){
  const item = document.createElement('dl');
  item.className = 'magic-data-row';
  item.id = idNumSet('magic-data-row');
  const title = document.createElement('dt');
  const body = document.createElement('dd');
  const nameInput = document.createElement('input');
  nameInput.type = 'text';
  nameInput.setAttribute('aria-label','項目名');
  nameInput.setAttribute('list','list-magic-data-label');
  nameInput.value = label;
  const valueInput = document.createElement('input');
  valueInput.type = 'text';
  valueInput.setAttribute('aria-label','項目の値');
  valueInput.value = value;
  const handle = document.createElement('span');
  handle.className = 'magic-data-handle';
  handle.title = 'ドラッグして並べ替え';
  handle.textContent = '::';
  handle.hidden = true;
  const remove = document.createElement('button');
  remove.type = 'button';
  remove.className = 'magic-data-remove';
  remove.textContent = '削除';
  remove.addEventListener('click',()=>removeMagicData(remove));
  title.append(handle,nameInput);
  body.append(valueInput,remove);
  item.append(title,body);
  row.querySelector('.magic-data-list').append(item);
}
function renumberMagicData(row){
  const prefix = magicDataPrefix(row);
  const rows = row.querySelectorAll('.magic-data-row');
  rows.forEach((item,index)=>{
    item.querySelector('dt input').name = `${prefix}Data${index+1}Label`;
    item.querySelector('dd input').name = `${prefix}Data${index+1}Value`;
  });
  row.querySelector(`[name="${prefix}DataNum"]`).value = rows.length;
}
function refreshMagicDataHints(row){
  const select = magicClassSelectFor(row);
  const custom = select.value === 'free';
  const magic = custom ? select.nextElementSibling.value : select.value;
  row.querySelectorAll('.magic-data-row').forEach(item=>{
    const label = item.querySelector('dt input');
    const value = item.querySelector('dd input');
    value.setAttribute('aria-label',`${label.value || '項目'}の値`);
    label.readOnly = !custom;
    item.querySelector('.magic-data-handle').hidden = !custom;
    item.querySelector('.magic-data-remove').hidden = !custom;
    const id = magicDataFieldId(label.value);
    let list = ARTS_MAGIC_DATA.fields[id]?.list;
    if(id === 'Cost'){
      list = new Map([['終律','list-cost-song'],['賦術','list-cost-alchemy'],['相域','list-cost-geomancy'],['操気','list-cost-psychokinesis']]).get(magic) || 'list-cost';
    }
    if(magic.length === 2 && (id === 'Target' || id === 'Range')){ list += '-craft'; }
    if(id === 'Type' && magic === '騎芸'){ list = 'list-magic-mount'; }
    if(list){ value.setAttribute('list',list); }
    else { value.removeAttribute('list'); }
  });
  row.querySelector('.magic-data-controls').hidden = !custom;
}
function checkMagicClass(row){
  const select = magicClassSelectFor(row);
  const prefix = magicDataPrefix(row);
  const field = suffix=>row.querySelector(`[name="${prefix}${suffix}"]`);
  const customField = field('DataCustom');
  let state = magicDataStates.get(row);
  if(!state){
    // 自由記入で保存した系統は、再編集時にも自由記入モードに戻す。
    if(customField?.value === '1'){ restoreMagicClass(select); }
    const list = row.querySelector('.magic-data-list');
    list.id = idNumSet('magic-data-list');
    list.querySelectorAll('.magic-data-row').forEach(item=>{ item.id = idNumSet('magic-data-row'); });
    // 現在の接頭辞を保持して、魔法内の項目番号だけを振り直す。
    setSortable('(?:magic(?:[0-9]+_magic)?|schoolMagic[0-9]+)Data',`#${list.id}`,'.magic-data-row');
    const sortable = Sortable.get(list);
    // 秘伝魔法全体の .handle と区別し、内側の項目だけを並べ替える。
    sortable.option('handle','.magic-data-handle');
    state = { byLabel:new Map(), byId:new Map(), freeRows:null, mode:null, signature:null, sortable };
    magicDataStates.set(row,state);
    list.addEventListener('input',event=>{
      if(event.target.name.endsWith('Label')){ refreshMagicDataHints(row); }
    });
  }
  rememberMagicData(row,state);
  if(state.mode === 'free'){ state.freeRows = magicDataRows(row); }
  const custom = select.value === 'free';
  const magic = custom ? select.nextElementSibling.value : select.value;
  if(customField){ customField.value = custom ? '1' : '0'; }
  state.sortable.option('disabled',!custom);
  const passive = field('ActionTypePassive').checked;
  const signature = `${magic}|${passive}`;
  if(custom){
    if(state.mode === 'preset' && state.freeRows){
      row.querySelector('.magic-data-list').replaceChildren();
      state.freeRows.forEach(item=>createMagicDataRow(row,item.label,item.value));
    }
    state.signature = null;
  }
  else if(state.mode !== 'preset' || state.signature !== signature){
    const preset = Object.hasOwn(ARTS_MAGIC_DATA.presets,magic) ? ARTS_MAGIC_DATA.presets[magic] : ARTS_MAGIC_DATA.default;
    const ids = magic === '操気' && passive ? ['Cost','Premise'] : preset;
    row.querySelector('.magic-data-list').replaceChildren();
    ids.forEach(id=>{
      const overrides = Object.hasOwn(ARTS_MAGIC_DATA.labels,magic) ? ARTS_MAGIC_DATA.labels[magic] : {};
      const label = overrides[id] || ARTS_MAGIC_DATA.fields[id].label;
      let value = state.byId.get(id) ?? state.byLabel.get(label) ?? '';
      if(id === 'Cost'){
        if(['終律','賦術','相域','操気'].includes(magic)){
          if(value === 'MP'){ value = ''; }
        }
        else if((row.dataset.recordName || magic !== '') && value === ''){ value = 'MP'; }
      }
      createMagicDataRow(row,label,value);
    });
    state.signature = signature;
  }
  state.mode = custom ? 'free' : 'preset';
  renumberMagicData(row);
  refreshMagicDataHints(row);
  const actionDisplay = custom || /^(騎芸|操気)$/.test(magic) ? '' : 'none';
  field('ActionTypePassive').parentNode.style.display = actionDisplay;
  field('ActionTypeMajor').parentNode.style.display = actionDisplay;
  row.querySelector('dl.summary').style.display = /^(呪印|貴格|城識)$/.test(magic) ? 'none' : '';
  row.querySelector('dl.level dt').textContent = /(属性|特殊)妖精魔法|秘奥魔法/.test(magic) ? 'ランク' : '習得レベル';
  const level = row.querySelector('dl.level input');
  if(magic.length === 2){ level.setAttribute('list','list-craft-required-level'); }
  else { level.removeAttribute('list'); }
}
function addMagicData(row){
  if(magicClassSelectFor(row).value !== 'free'){ return; }
  createMagicDataRow(row);
  renumberMagicData(row);
  refreshMagicDataHints(row);
  row.querySelector('.magic-data-row:last-child dt input').focus();
  form.dispatchEvent(new Event('change'));
}
function removeMagicData(button){
  const row = button.closest('.input-data');
  if(magicClassSelectFor(row).value !== 'free'){ return; }
  const item = button.closest('.magic-data-row');
  if([...item.querySelectorAll('input')].some(input=>input.value !== '') && !confirm(delConfirmText)){ return; }
  item.remove();
  renumberMagicData(row);
  form.dispatchEvent(new Event('change'));
}
function setupMagicDatalists(){
  for(const id of ['list-target','list-magic-range-form']){
    const list = document.getElementById(id).cloneNode(true);
    list.id += '-craft';
    for(const option of list.querySelectorAll('option')){
      option.value = option.value.replace(/^術者/,'自身');
    }
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
function normalizeSchoolItemUrl(value) {
  if(!URL.canParse(value, document.baseURI)){ return null; }
  const url = new URL(value, document.baseURI);
  if(url.protocol !== 'https:' && url.protocol !== 'http:'){ return null; }
  url.search = url.search.replaceAll(';', '&');
  url.searchParams.delete('mode');
  return url;
}

async function addSchoolItem(){
  const urlForm = document.getElementById('schoolItemUrl');
  const value = urlForm.value.trim();
  if(!value){ return; }
  const url = normalizeSchoolItemUrl(value);
  if(!url){ alert('アイテムシートのURLを確認してください。'); return; }
  const href = url.href;
  if(schoolItems.some(item => normalizeSchoolItemUrl(item)?.href === href)){
    alert('そのデータは追加済みです');
    urlForm.value = '';
    return;
  }

  let data;
  try {
    url.hash = '';
    url.searchParams.set('mode', 'json');
    const response = await fetch(url);
    data = await response.json();
    if(!response.ok || data?.result !== 'OK'){
      throw new Error(data?.message || response.statusText);
    }
  }
  catch(error) {
    alert(`アイテムデータを取得できませんでした。\n${error.message}`);
    return;
  }
  if(data.type !== 'i' || data.itemName == null){ alert('アイテムデータではありません。'); return; }

  const tr = document.createElement('tr');
  tr.setAttribute('class', 'item-data');
  tr.innerHTML = `
    <td><a target="_blank">${ruby(data.itemName)}</a></td>
    <td>${data.category?.replace(/\s+/g, '<hr>') ?? ''}</td>
    <td>${data.summary || ''}</td>
    <td class="button">×</td>
  `;
  tr.querySelector('a').href = href;
  const remove = tr.querySelector('.button');
  remove.addEventListener('click', () => delSchoolItem(remove, href));
  document.querySelector('#school-item-list tbody').appendChild(tr);
  schoolItems.push(href);
  form.schoolItemList.value = schoolItems.join(',');
  urlForm.value = '';
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

function setupRangeField() {
  // 特殊神聖魔法は従来の射程・形状の入力欄を維持する。
  const rangeFields = document.querySelectorAll('[name^="godMagic"][name$="Range"]');
  rangeFields.forEach(rangeField =>
    rangeField.addEventListener('input', () => {
      const formField = rangeField.parentNode.querySelector(`[name$="Form"]`);
      if ((rangeField.value === '術者' || rangeField.value === '接触') && (formField.value?.trim() ?? '') === '') {
        formField.value = '―';
      }
    })
  );
}
