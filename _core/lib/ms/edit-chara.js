"use strict";
const gameSystem = 'blp';

// ----------------------------------------
window.onload = function() {
  
  nameSet();
  calcLevel();
  checkStatus();
  checkAttribute();
  checkMagi();
  calcEndurance();
  
  imagePosition();
  changeColor();
};

function changeRegu(){
  calcLevel();
}
// 強度計算 ----------------------------------------
let level = 0;
function calcLevel(){
  level = 0;
  for (let num = 1; num <= Number(form.historyNum.value); num++){
    const obj = form['history'+num+'Level'];
    let lv = safeEval(obj.value);
    if(isNaN(lv)){
      obj.classList.add('error');
    }
    else {
      level += lv;
      obj.classList.remove('error');
    }
  }
  document.getElementById("level-value").textContent = level;
  document.getElementById("history-level-total").textContent = level;

  document.getElementById('status').querySelectorAll('.status .grow').forEach(obj => {
    obj.style.display = level >= 10 ? '' : 'none'
  });
}

// ステータス計算 ----------------------------------------
function checkStatus() {
  const phy = Number(form.statusPhysicalBase.value);
  const spe = Number(form.statusSpecialBase.value);
  const soc = Number(form.statusSocialBase.value);
  document.getElementById('status').querySelector('.status .error').textContent
    = (phy + spe + soc != 12 || phy == spe || spe == soc || soc == phy) ? '各能力値に6／4／2を割り振ってください' : '';
}
function calcEndurance() {
  document.getElementById("endurance-total").textContent
   = Number(form.enduranceMod.value || 0) + 20;
}

// 特性欄 ----------------------------------------
function checkAttribute() {
  let count = 0;
  for(let type of ['Physical','Special','Social']){
    for (let num = 1; num <= Number(form.attributeRow.value); num++){
      if(form['attribute'+type+num].value){ count++ }
    }
  }
  document.getElementById('status').querySelector('.attribute .error').textContent
    = (count < 4) ? '特性を4つ記入してください' : '';
}
// 追加
function addAttribute(){
  let num = Number(form.attributeRow.value) + 1;

  for(let type of ['Physical','Special','Social']){
    let li = document.createElement('li');
    li.id = idNumSet('attribute'+type);
    li.innerHTML = `《<input type="text" name="attribute${type}${num}" oninput="checkAttribute()">》`;
    document.getElementById('attribute-'+type.toLowerCase()).append(li);
  }
  form.attributeRow.value = num;
}
// 削除
function delAttribute(){
  let num = Number(form.attributeRow.value);
  if(num > 0){
    if( form[`attributePhysical${num}`].value
     || form[`attributeSpecial${num}`].value
     || form[`attributeSocial${num}`].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#attribute-physical li:last-child").remove();
    document.querySelector("#attribute-special  li:last-child").remove();
    document.querySelector("#attribute-social   li:last-child").remove();
    num--;
    form.attributeRow.value = num;
  }
}

// マギ欄 ----------------------------------------
function checkMagi() {
  let count = 0;
  for (let num = 1; num <= 4; num++){
    if(form['magi'+num+'Name'].value){ count++ }
  }
  document.getElementById('magi').querySelector('.error').textContent
    = (count < 1) ? 'マギを1つ記入してください' : '';
}

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  let num = Number(form.historyNum.value) + 1;

  let row = document.querySelector('#history-template').content.firstElementChild.cloneNode(true);
  row.id = idNumSet('history');
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#history-table tbody:last-of-type").after(row);
  
  form.historyNum.value = num;
}
// 削除
function delHistory(){
  let num = Number(form.historyNum.value);
  if(num > 1){
    if(form[`history${num}Date`].value || form[`history${num}Title`].value || form[`history${num}Grow`].value || form[`history${num}Gm`].value || form[`history${num}Member`].value || form[`history${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#history-table tbody:last-of-type").remove();
    num--;
    form.historyNum.value = num;
  }
}
// ソート
let historySortable = Sortable.create(document.getElementById('history-table'), {
  group: "history",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot,template',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = historySortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.querySelector(`tbody#${id}`)){
        document.querySelector(`#${id} [name$="Date"]`  ).setAttribute('name',`history${num}Date`);
        document.querySelector(`#${id} [name$="Title"]` ).setAttribute('name',`history${num}Title`);
        document.querySelector(`#${id} [name$="Grow"]`  ).setAttribute('name',`history${num}Grow`);
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
        num++;
      }
    }
  }
});
