"use strict";
const gameSystem = 'blp';

let factor = '';
let subFactor = {'Core':'', 'Style':''};
// ----------------------------------------
window.onload = function() {
  factor = form.factor.value;
  checkSubFactor('Core' , form.factorCore.value);
  checkSubFactor('Style', form.factorStyle.value);
  
  setName();
  calcGrow();
  checkFactor();
  scarCheck();

  togglePartner2();
  autoInputPartner(1);
  autoInputPartner(2);

  toggleServant();
  
  imagePosition();
  changeColor();
};

function changeRegu(){
  calcGrow();
}

// ファクター変更 ----------------------------------------
function changeFactor(){
  if(form.factorCore.value || form.factorStyle.value){
    if (!confirm('関連項目が入力済みです。本当にファクターを変更しますか？')) return false;
  }
  factor = form.factor.value;
  changeSubFactorList('Core');
  changeSubFactorList('Style');
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
function changeSubFactorList(type){
  const select = document.querySelector(`select[name^="factor${type}"]`);
  const selected = select.value;
  document.querySelectorAll(`select[name^="factor${type}"] option`).forEach(opt => {
    const name = opt.value;
    if(name != 'free' && factorData[name] || !name){
      opt.remove();
    }
  });
  if(factor){
    Array.from(new Set(factorList[factor][type.toLowerCase()])).reverse().forEach(name => {
      const option = document.createElement('option');
      option.value = name;
      option.text = name;
      select.prepend(option);
    });
  }
  const option = document.createElement('option');
  select.prepend(option);
  select.value = selected;
  
  checkSubFactor(type, selected in factorData ? '' : selected);
}
function checkSubFactor(type,selected){
  subFactor[type] = selected;

  if(subFactor[type] in factorData){
    form['statusMain1'+type].readOnly = true;
    form['statusMain2'+type].readOnly = true;
    form['statusMain1'+type].value = factorData[selected]['stt1'];
    form['statusMain2'+type].value = factorData[selected]['stt2'];
  }
  else if (subFactor[type] == '') {
    form['statusMain1'+type].readOnly = true;
    form['statusMain2'+type].readOnly = true;
    form['statusMain1'+type].value = '';
    form['statusMain2'+type].value = '';
  }
  else {
    form['statusMain1'+type].readOnly = false;
    form['statusMain2'+type].readOnly = false;
  }
}

// 成長計算 ----------------------------------------
let level = 1;
let enduranceGrow  = 0;
let initiativeGrow = 0;
function calcGrow(){
  enduranceGrow  = Number(form.endurancePreGrow.value );
  initiativeGrow = Number(form.initiativePreGrow.value);
  level = 1 + (enduranceGrow / 5) + (initiativeGrow / 2);
  document.getElementById("level-pre-grow").textContent = level;
  
  for (let num = 1; num <= Number(form.historyNum.value); num++){
    if     (form['history'+num+'Grow'].value === 'endurance' ){ enduranceGrow  += 5; level++; }
    else if(form['history'+num+'Grow'].value === 'initiative'){ initiativeGrow += 2; level++; }
  }
  document.getElementById("level-value").textContent = level;
  
  calcStt();
}

// ステータス計算 ----------------------------------------
function calcStt() {
  let main1 = Number(form.statusMain1Core.value)+Number(form.statusMain1Style.value);
  let main2 = Number(form.statusMain2Core.value)+Number(form.statusMain2Style.value);
  let enduranceTotal  = Number(form.enduranceAdd.value) +enduranceGrow;
  let initiativeTotal = Number(form.initiativeAdd.value)+initiativeGrow;
  if     (factor === '人間') {
    enduranceTotal  += main1 * 2 + main2;
    initiativeTotal += main2 + 10;
    document.getElementById("endurance-base").textContent  = '【技】×2+【情】';
    document.getElementById("initiative-base").textContent = '【情】+10';
    document.getElementById("partner1-factor-term").textContent = '起源／流儀';
    document.getElementById("partner1-missing-term").textContent = '欠落';
    document.getElementById("partner1-age-term").textContent = '外見年齢／実年齢';
  }
  else if(factor === '吸血鬼'){
    enduranceTotal  += main1 + 20;
    initiativeTotal += main2 + 4;
    document.getElementById("endurance-base").textContent  = '【血】+20';
    document.getElementById("initiative-base").textContent = '【想】+4';
    document.getElementById("partner1-factor-term").textContent = '信念／職能';
    document.getElementById("partner1-missing-term").textContent = '喪失';
    document.getElementById("partner1-age-term").textContent = '年齢';
  }
  document.getElementById("main1-total").textContent = main1;
  document.getElementById("main2-total").textContent = main2;
  document.getElementById("endurance-grow").textContent  = enduranceGrow;
  document.getElementById("initiative-grow").textContent = initiativeGrow;
  document.getElementById("endurance-total").textContent  = enduranceTotal;
  document.getElementById("initiative-total").textContent = initiativeTotal;
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
// 血僕 ----------------------------------------
function toggleServant(){
  document.getElementById('servant').style.display = form.servantOn.checked ? '' : 'none';
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
  document.querySelector("#arts-list").append(createRow('arts','artsNum'));
}
// 削除
function delArts(){
  delRow('artsNum', '#arts-list tr:last-of-type');
}
// ソート
setSortable('arts','#arts-list','tr');
// 血威ソート
setSortable('bloodarts','#bloodarts-list','tr');

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  document.querySelector("#history-table tfoot").before(createRow('history','historyNum'));
}
// 削除
function delHistory(){
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcGrow();
  }
}
// ソート
setSortable('history','#history-table','tbody');
