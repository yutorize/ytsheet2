"use strict";
const gameSystem = 'ms';

// ----------------------------------------
window.onload = function() {
  
  setName();
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
  document.getElementById('status').querySelector('.status .annotate').textContent
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
  document.getElementById('status').querySelector('.attribute .annotate').textContent
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
  document.getElementById('magi').querySelector('.annotate').textContent
    = (count < 1) ? 'マギを1つ記入してください' : '';
}

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  document.querySelector("#history-table tfoot").before(createRow('history','historyNum'));
}
// 削除
function delHistory(){
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcLevel();
  }
}
// ソート
setSortable('history','#history-table','tbody');
