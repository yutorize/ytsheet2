"use strict";
const gameSystem = 'blp';

// ----------------------------------------
window.onload = function() {
  
  nameSet();
  calcGrow();
  changeFactor();
  scarCheck();

  togglePartner2();
  autoInputPartner(1);
  autoInputPartner(2);
  
  imagePosition();
  changeColor();
  
  palettePresetChange();
};

function changeRegu(){
  calcGrow();
}

// ファクター変更 ----------------------------------------
let factor = '';
function changeFactor(){
  factor = form.factor.value;
  checkFactor();
}
function checkFactor(){
  if     (factor === '人間') {
    document.body.classList.add('type-human');
    document.body.classList.remove('type-vampire');
    form.missing.setAttribute("list","list-loss");
    form.factorCore.setAttribute("list","list-belief");
    form.factorStyle.setAttribute("list","list-job");
  }
  else if(factor === '吸血鬼'){
    document.body.classList.add('type-vampire');
    document.body.classList.remove('type-human');
    form.missing.setAttribute("list","list-lack");
    form.factorCore.setAttribute("list","list-origin");
    form.factorStyle.setAttribute("list","list-style");
  }
  calcStt();
}

// 成長計算 ----------------------------------------
let level = 1;
let enduranceGrow  = 0;
let initiativeGrow = 0;
function calcGrow(){
  enduranceGrow  = Number(form.endurancePreGrow.value );
  initiativeGrow = Number(form.initiativePreGrow.value);
  level = 1 + (enduranceGrow / 5) + (initiativeGrow / 2);
  document.getElementById("level-pre-grow").innerHTML = level;
  
  for (let num = 1; num <= Number(form.historyNum.value); num++){
    if     (form['history'+num+'Grow'].value === 'endurance' ){ enduranceGrow  += 5; level++; }
    else if(form['history'+num+'Grow'].value === 'initiative'){ initiativeGrow += 2; level++; }
  }
  document.getElementById("level-value").innerHTML = level;
  
  calcStt();
}

// ステータス計算 ----------------------------------------
function calcStt() {
  let main1 = Number(form.statusMain1.value);
  let main2 = Number(form.statusMain2.value);
  let enduranceTotal  = Number(form.enduranceAdd.value) +enduranceGrow;
  let initiativeTotal = Number(form.initiativeAdd.value)+initiativeGrow;
  if     (factor === '人間') {
    enduranceTotal  += main1 * 2 + main2;
    initiativeTotal += main2 + 10;
    document.getElementById("endurance-base").innerHTML  = `[${main1}×2+${main2}]`+(enduranceGrow?`+${enduranceGrow}`:'');
    document.getElementById("initiative-base").innerHTML = `[${main2}+10]`+(initiativeGrow?`+${initiativeGrow}`:'');
    document.getElementById("partner1-factor-term").innerHTML = '起源／流儀';
    document.getElementById("partner1-missing-term").innerHTML = '欠落';
    document.getElementById("partner1-age-term").innerHTML = '外見年齢／実年齢';
  }
  else if(factor === '吸血鬼'){
    enduranceTotal  += main1 + 20;
    initiativeTotal += main2 + 4;
    document.getElementById("endurance-base").innerHTML  = `[${main1}+20]`+(enduranceGrow?`+${enduranceGrow}`:'');
    document.getElementById("initiative-base").innerHTML = `[${main2}+4]`+(initiativeGrow?`+${initiativeGrow}`:'');
    document.getElementById("partner1-factor-term").innerHTML = '信念／職能';
    document.getElementById("partner1-missing-term").innerHTML = '喪失';
    document.getElementById("partner1-age-term").innerHTML = '年齢';
  }
  document.getElementById("endurance-total").innerHTML  = enduranceTotal;
  document.getElementById("initiative-total").innerHTML = initiativeTotal;
}

// パートナー ----------------------------------------
function autoInputPartner(num){
  const on = form[`partner${num}Auto`].checked ? true : false;
  form[`partner${num}Name`].readOnly    = on;
  form[`partner${num}Factor`].readOnly  = on;
  form[`partner${num}Age`].readOnly     = on;
  form[`partner${num}Gender`].readOnly  = on;
  form[`partner${num}Missing`].readOnly = on;
  form[`fromPartner${num}SealPosition`].readOnly = on;
  form[`fromPartner${num}SealShape`].readOnly    = on;
  form[`fromPartner${num}Emotion1`].readOnly     = on;
  form[`fromPartner${num}Emotion2`].readOnly     = on;
  
  form[`partner${num}Url`].classList.remove('error');
  let url = form[`partner${num}Url`].value;
  let from = 0;
  if     (factor === '人間'){ from = 1; }
  else if(factor === '吸血鬼' && num === 1){ from = form.partnerOrder.value; }
  else if(factor === '吸血鬼' && num === 2){ from = 2; }
  if(on) {
    form[`partner${num}Name`].value    = '';
    form[`partner${num}Factor`].value  = '';
    form[`partner${num}Age`].value     = '';
    form[`partner${num}Gender`].value  = '';
    form[`partner${num}Missing`].value = '';
    
    if(url){
      //外部ならコンバート用URLへ変換
      if(!url.match(location.host)){
        url = './?mode=json&url='+url;
      }
      // データ取得
      fetch(url+'&mode=json')
      .then(response => { return response.json(); })
      .then(data => {
        if(data[`result`] === 'OK'){
          form[`partner${num}Name`].value    = data[`characterName`] || '';
          form[`partner${num}Factor`].value  = (data[`factorCore`] || '') + '／' + (data[`factorStyle`] || '');
          form[`partner${num}Age`].value     = (data[`factor`] === '吸血鬼' ? (data[`ageApp`] || '')+'／':'') + (data[`age`] || '');
          form[`partner${num}Gender`].value  = data[`gender`] || '';
          form[`partner${num}Missing`].value = data[`missing`] || '';
          if(data[`convertSource`] === 'キャラクターシート倉庫'){
            form[`fromPartner${num}SealPosition`].readOnly = false;
            form[`fromPartner${num}SealShape`].readOnly    = false;
            form[`fromPartner${num}Emotion1`].readOnly     = false;
            form[`fromPartner${num}Emotion2`].readOnly     = false;
          }
          else {
            form[`fromPartner${num}SealPosition`].value = data[`toPartner${from}SealPosition`] || '';
            form[`fromPartner${num}SealShape`].value    = data[`toPartner${from}SealShape`]    || '';
            form[`fromPartner${num}Emotion1`].value     = data[`toPartner${from}Emotion1`]     || '';
            form[`fromPartner${num}Emotion2`].value     = data[`toPartner${from}Emotion2`]     || '';
          }
        }
        else {
          form[`partner${num}Url`].classList.add('error');
          form[`fromPartner${num}SealPosition`].value = '';
          form[`fromPartner${num}SealShape`].value    = '';
          form[`fromPartner${num}Emotion1`].value     = '';
          form[`fromPartner${num}Emotion2`].value     = '';
        }
      });
    }
  }
}
function togglePartner2(){
  document.getElementById('partner2area').style.display = form.partner2On.checked ? '' : 'none';
}

// 傷号 ----------------------------------------
function scarCheck(){
  const name = form.scarName.value;
  document.getElementById('arts-scar').style.display = name ? '' : 'none';
  document.getElementById('arts-scar-head').style.display = name ? '' : 'none';
  document.getElementById('arts-scar-name').innerHTML = ruby(name);
}

// 特技欄 ----------------------------------------
// 追加
function addArts(){
  let num = Number(form.artsNum.value) + 1;
  let tr = document.createElement('tr');
  tr.setAttribute('id',idNumSet('arts'));
  tr.innerHTML = `
    <td class="handle"></td>
    <td><input name="arts${num}Name"    type="text"></td>
    <td><input name="arts${num}Timing"  type="text" list="list-timing"></td>
    <td><input name="arts${num}Target"  type="text" list="list-target"></td>
    <td><input name="arts${num}Cost"    type="text" list="list-cost"></td>
    <td><input name="arts${num}Limited" type="text" list="list-limited"></td>
    <td><input name="arts${num}Note"    type="text"></td>
  `;
  const target = document.querySelector("#arts-list");
  target.appendChild(tr, target);
  
  form.artsNum.value = num;
}
// 削除
function delArts(){
  let num = Number(form.artsNum.value);
  if(num > 0){
    if(form[`arts${num}Name`].value || form[`arts${num}Timing`].value || form[`arts${num}Target`].value || form[`arts${num}Cost`].value || form[`arts${num}Limited`].value || form[`arts${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#arts-list tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.artsNum.value = num;
  }
}
// ソート
let artsSortable = Sortable.create(document.getElementById('arts-list'), {
  group: "arts",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  ghostClass: 'sortable-ghost',
  onUpdate: function(evt){
    const order = artsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Name"]`   ).setAttribute('name',`arts${num}Name`);
        document.querySelector(`#${id} [name$="Timing"]` ).setAttribute('name',`arts${num}Timing`);
        document.querySelector(`#${id} [name$="Target"]` ).setAttribute('name',`arts${num}Target`);
        document.querySelector(`#${id} [name$="Cost"]`   ).setAttribute('name',`arts${num}Cost`);
        document.querySelector(`#${id} [name$="Limited"]`).setAttribute('name',`arts${num}Limited`);
        document.querySelector(`#${id} [name$="Note"]`   ).setAttribute('name',`arts${num}Note`);
        num++;
      }
    }
  }
});
// 血威ソート
let bloodartsSortable = Sortable.create(document.getElementById('bloodarts-list'), {
  group: "bloodarts",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  ghostClass: 'sortable-ghost',
  onUpdate: function(evt){
    const order = bloodartsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Name"]`   ).setAttribute('name',`bloodarts${num}Name`);
        document.querySelector(`#${id} [name$="Timing"]` ).setAttribute('name',`bloodarts${num}Timing`);
        document.querySelector(`#${id} [name$="Target"]` ).setAttribute('name',`bloodarts${num}Target`);
        document.querySelector(`#${id} [name$="Note"]`   ).setAttribute('name',`bloodarts${num}Note`);
        num++;
      }
    }
  }
});

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  let num = Number(form.historyNum.value) + 1;
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id',idNumSet('history'));
  tbody.innerHTML = `<tr>
    <td rowspan="2" class="handle"></td>
    <td rowspan="2"><input name="history${num}Date"   type="text"></td>
    <td rowspan="2"><input name="history${num}Title"  type="text"></td>
    <td><select name="history${num}Grow" oninput="calcGrow()"><option><option value="endurance">耐久値+5<option value="initiative">先制値+2</select></td>
    <td><input name="history${num}Gm"     type="text"></td>
    <td><input name="history${num}Member" type="text"></td>
  </tr>
  <tr><td colspan="5" class="left"><input name="history${num}Note" type="text"></td></tr>`;
  const target = document.querySelector("#history-table tfoot");
  target.parentNode.insertBefore(tbody, target);
  
  form.historyNum.value = num;
}
// 削除
function delHistory(){
  let num = Number(form.historyNum.value);
  if(num > 1){
    if(form[`history${num}Date`].value || form[`history${num}Title`].value || form[`history${num}Grow`].value || form[`history${num}Gm`].value || form[`history${num}Member`].value || form[`history${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#history-table tbody:last-of-type");
    target.parentNode.removeChild(target);
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
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = historySortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
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
