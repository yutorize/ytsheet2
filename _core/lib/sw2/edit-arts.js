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
function nameSet(){
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
    nameSet();
  }
  else { document.getElementById('data-none').style.display = 'block'; }
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
    viewMagicInputs(['premise','part']);
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
  form.magicActionTypePassive.parentNode.style.display = (magic == '騎芸') ? '' : 'none';
  form.magicActionTypeMajor.parentNode.style.display   = (magic == '騎芸') ? '' : 'none';
  document.querySelector('#data-magic dl.summary').style.display   = (magic == '呪印' || magic == '貴格') ? 'none' : '';
  document.querySelector('#data-magic dl.type      dt').innerHTML = (magic == '鼓咆') ? '鼓咆の系統' : (magic == '占瞳') ? 'タイプなど' : (magic == '貴格') ? '形態' : '対応';
  document.querySelector('#data-magic dl.premise   dt').innerHTML = (magic == '呪印') ? '前提ＡＣ'   : '前提';
  document.querySelector('#data-magic dl.condition dt').innerHTML = (magic == '呪歌') ? '効果発生条件' : (magic == '陣率') ? '使用条件' : '条件';
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
async function addSchoolItem(){
  const urlForm = document.getElementById('schoolItemUrl');
  if(urlForm.value && !schoolItems.includes(urlForm.value)){
    const result = await setSchoolItem(urlForm.value);
    if(result){
      urlForm.value = "";
    }
  }
  else {
    alert('そのデータは追加済みです');
    urlForm.value = "";
  }
}
async function setSchoolItemList(){
  if(form.schoolItemList.value){
    let list = Array.from(new Set(form.schoolItemList.value.split(',')));
    for(const url of list){
      await setSchoolItem(url);
    }
  }
}
function setSchoolItem(url){
  return new Promise(resolve => {
    fetch(url+'&mode=json')
    .then(response => { return response.json(); })
    .then(data => {
      if(data[`result`] === 'OK'){
        let tr = document.createElement('tr');
        tr.setAttribute('class','item-data');
        tr.innerHTML = `
          <td><a href="${url}">${ruby(data['itemName'])}</a></td>
          <td>${data['category']}</td>
          <td>${data['summary']}</td>
          <td class="button" onclick="delSchoolItem(this,'${url}')">×</td>
        `;
        document.querySelector("#school-item-list tbody").appendChild(tr);
        schoolItems.push(url);
        form.schoolItemList.value = schoolItems.join(',');
        resolve('resolved');
      }
      else {

      }
    });
  });
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
  let num = Number(form.schoolArtsNum.value) + 1;
  let div = document.createElement('div');
  div.setAttribute('id',idNumSet('arts'));
  div.setAttribute('class','input-data');
  div.innerHTML = `
    <dl class="name    "><dt>名称      </dt><dd>《<input type="text" name="schoolArts${num}Name">》<br><label class="check-button"><input type="checkbox" name="schoolArts${num}ActionTypeSetup" value="1"><span>戦闘準備</span></label></dd></dl>
    <dl class="cost    "><dt>必要名誉点</dt><dd><input type="text" name="schoolArts${num}Cost"></dd></dl>
    <dl class="type    "><dt>タイプ    </dt><dd><input type="text" name="schoolArts${num}Type" list="list-arts-type"></dd></dl>
    <dl class="premise "><dt>前提      </dt><dd><input type="text" name="schoolArts${num}Premise"></dd></dl>
    <dl class="equip   "><dt>限定条件  </dt><dd><input type="text" name="schoolArts${num}Equip"></dd></dl>
    <dl class="use     "><dt>使用      </dt><dd><input type="text" name="schoolArts${num}Use"></dd></dl>
    <dl class="apply   "><dt>適用      </dt><dd><input type="text" name="schoolArts${num}Apply"></dd></dl>
    <dl class="risk    "><dt>リスク    </dt><dd><input type="text" name="schoolArts${num}Risk"></dd></dl>
    <dl class="summary "><dt>概要      </dt><dd><input type="text" name="schoolArts${num}Summary"></dd></dl>
    <dl class="effect  "><dt>効果      </dt><dd><textarea name="schoolArts${num}Effect"></textarea></dd></dl>
  `;
  document.querySelector("#arts-list").appendChild(div);
  form.schoolArtsNum.value = num;
}
// 削除
function delSchoolArts(){
  let num = Number(form.schoolArtsNum.value);
  if(num > 0){
    if(form[`schoolArts${num}Name`].value || form[`schoolArts${num}Cost`].value || form[`schoolArts${num}Type`].value || form[`schoolArts${num}Premise`].value || form[`schoolArts${num}Equip`].value || form[`schoolArts${num}Use`].value || form[`schoolArts${num}Apply`].value || form[`schoolArts${num}Risk`].value || form[`schoolArts${num}Summary`].value || form[`schoolArts${num}Effect`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#arts-list .input-data:last-child").remove();
    num--;
    form.schoolArtsNum.value = num;
  }
}
// 秘伝魔法欄 ----------------------------------------
// 追加
function addSchoolMagic(){
  let num = Number(form.schoolMagicNum.value) + 1;
  let div = document.createElement('div');
  div.setAttribute('id',idNumSet('school-magic'));
  div.setAttribute('class','input-data');
  div.innerHTML = `
  <dl class="name    "><dt>名称      </dt><dd>【<input type="text" name="schoolMagic${num}Name" value="">】<br><label class="check-button"><input type="checkbox" name="schoolMagic${num}ActionTypeMinor" value="1"><span>補助動作</span></label><label class="check-button"><input type="checkbox" name="schoolMagic${num}ActionTypeSetup" value="1"><span>戦闘準備</span></label></dd></dl>
  <dl class="cost    "><dt>必要名誉点</dt><dd><input type="text" name="schoolMagic${num}AcquireCost" value=""></dd></dl>
  <dl class="level    "><dt>習得レベル</dt><dd><input type="text" name="schoolMagic${num}Lv" value=""></dd></dl>
  <dl class="cost    "><dt>消費      </dt><dd><input type="text" name="schoolMagic${num}Cost" value=""></dd></dl>
  <dl class="target  "><dt>対象      </dt><dd><input type="text" name="schoolMagic${num}Target" value="" list="list-target"></dd></dl>
  <dl class="range   "><dt>射程／形状</dt><dd><input type="text" name="schoolMagic${num}Range" value="" list="list-range">／<input type="text" name="schoolMagic${num}Form" value="" list="list-form"></dd></dl>
  <dl class="duration"><dt>時間      </dt><dd><input type="text" name="schoolMagic${num}Duration" value="" list="list-duration"></dd></dl>
  <dl class="resist  "><dt>抵抗      </dt><dd><input type="text" name="schoolMagic${num}Resist" value="" list="list-resist"></dd></dl>
  <dl class="element "><dt>属性      </dt><dd><input type="text" name="schoolMagic${num}Element" value="" list="list-element"></dd></dl>
  <dl class="summary "><dt>概要      </dt><dd><input type="text" name="schoolMagic${num}Summary" value=""></dd></dl>
  <dl class="effect  "><dt>効果      </dt><dd><textarea name="schoolMagic${num}Effect"></textarea></dd></dl>
  `;
  document.querySelector("#school-magic-list").appendChild(div);
  form.schoolMagicNum.value = num;
}
// 削除
function delSchoolMagic(){
  let num = Number(form.schoolMagicNum.value);
  if(num > 0){
    if(form[`schoolMagic${num}Name`].value || form[`schoolMagic${num}Cost`].value || form[`schoolMagic${num}Target`].value || form[`schoolMagic${num}Range`].value || form[`schoolMagic${num}Form`].value || form[`schoolMagic${num}Duration`].value || form[`schoolMagic${num}Resist`].value || form[`schoolMagic${num}Element`].value || form[`schoolMagic${num}Summary`].value || form[`schoolMagic${num}Effect`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#school-magic-list .input-data:last-child").remove();
    num--;
    form.schoolMagicNum.value = num;
  }
}
