"use strict";
const gameSystem = 'kiz';

// ----------------------------------------
window.onload = function() {
  
  setName();
  calcGrow();
  changeMakeType();
  changeType();
  checkNegai('Out',form.negaiOutside.value);
  checkNegai('In',form.negaiInside.value);
  
  togglePartner2();
  autoInputPartner(1);
  autoInputPartner(2);
  
  imagePosition();
  changeColor();
};

function changeRegu(){
  calcGrow();
}

// 作成タイプ変更 ----------------------------------------
function changeMakeType(){
  if(form.makeType.value === 'gospel') {
    document.body.classList.add('gospel-bullet');
    document.body.classList.remove('normal-bullet');
  }
  else {
    document.body.classList.add('normal-bullet');
    document.body.classList.remove('gospel-bullet');
  }
}

// 種別変更 ----------------------------------------
let pcClass = '';
function changeType(){
  pcClass = form.class.value;
  checkType();
}
function checkType(){
  if     (pcClass === 'ハウンド') {
    document.body.classList.add('class-hound');
    document.body.classList.remove('class-owner');
    form.enduranceType.value = 18;
    form.operationType.value = 1;
  }
  else if(pcClass === 'オーナー'){
    document.body.classList.add('class-owner');
    document.body.classList.remove('class-hound');
    form.enduranceType.value = 12;
    form.operationType.value = 4;
  }
  else {
    form.enduranceType.value = '';
    form.operationType.value = '';
  }
  calcStt();
}
// ネガイ変更 ----------------------------------------
function changeNegai(type,value){
  checkNegai(type,value);
  calcStt();
}
function checkNegai(type,negai){
  if(negai in negaiData){
    form[`endurance${type}side`].readOnly = true;
    form[`operation${type}side`].readOnly = true;
    form[`endurance${type}side`].value = negaiData[negai][type.toLowerCase()]['endurance'];
    form[`operation${type}side`].value = negaiData[negai][type.toLowerCase()]['operation'];
  }
  else if (negai == '') {
    form[`endurance${type}side`].readOnly = true;
    form[`operation${type}side`].readOnly = true;
    form[`endurance${type}side`].value = '';
    form[`operation${type}side`].value = '';
  }
  else {
    form[`endurance${type}side`].readOnly = false;
    form[`operation${type}side`].readOnly = false;
  }
}


// 成長計算 ----------------------------------------
let level = 1;
let enduranceGrow = 0;
let operationGrow = 0;
function calcGrow(){
  enduranceGrow = Number(form.endurancePreGrow.value );
  operationGrow = Number(form.operationPreGrow.value);
  level = 1 + (enduranceGrow / 5) + (operationGrow / 2);
  
  for (let num = 1; num <= Number(form.historyNum.value); num++){
    if     (form['history'+num+'Grow'].value === 'endurance'){ enduranceGrow += 2; level++; }
    else if(form['history'+num+'Grow'].value === 'operation'){ operationGrow += 1; level++; }
  }
  document.getElementById("endurance-grow").textContent = enduranceGrow;
  document.getElementById("operation-grow").textContent = operationGrow;
  
  calcStt();
}

// ステータス計算 ----------------------------------------
function calcStt() {
  let enduranceTotal = Number(form.enduranceType.value)
                     + Number(form.enduranceOutside.value)
                     + Number(form.enduranceInside.value)
                     + Number(form.enduranceAdd.value)
                     + enduranceGrow;
  let operationTotal = Number(form.operationType.value)
                     + Number(form.operationOutside.value)
                     + Number(form.operationInside.value)
                     + Number(form.operationAdd.value)
                     + operationGrow;

  document.getElementById("endurance-total").textContent = enduranceTotal;
  document.getElementById("operation-total").textContent = operationTotal;
}

// パートナー ----------------------------------------
function autoInputPartner(num){
  const on = form[`partner${num}Auto`].checked ? true : false;
  form[`partner${num}Name`  ].readOnly = on;
  form[`partner${num}Age`   ].readOnly = on;
  form[`partner${num}Gender`].readOnly = on;
  form[`partner${num}NegaiOutside`].readOnly = on;
  form[`partner${num}NegaiInside` ].readOnly = on;
  form[`fromPartner${num}MarkerPosition`].readOnly = on;
  form[`fromPartner${num}MarkerColor`   ].readOnly = on;
  form[`fromPartner${num}Emotion1`      ].readOnly = on;
  form[`fromPartner${num}Emotion2`      ].readOnly = on;
  
  form[`partner${num}Url`].classList.remove('error');
  let url = form[`partner${num}Url`].value;
  let from = 0;
  if     (pcClass === 'オーナー'){ from = 1; }
  else if(pcClass === 'ハウンド' && num === 1){ from = form.partnerOrder.value; }
  else if(pcClass === 'ハウンド' && num === 2){ from = 2; }
  if(on) {
    form[`partner${num}Name`  ].value = '';
    form[`partner${num}Age`   ].value = '';
    form[`partner${num}Gender`].value = '';
    form[`partner${num}NegaiOutside`].value = '';
    form[`partner${num}NegaiInside` ].value = '';
    
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
          form[`partner${num}Name`  ].value = data[`characterName`] || '';
          form[`partner${num}Age`   ].value = data[`age`] || '';
          form[`partner${num}Gender`].value = data[`gender`] || '';
          form[`partner${num}NegaiOutside`].value = data[`negaiOutside`] || '';
          form[`partner${num}NegaiInside` ].value = data[`negaiInside` ] || '';
          if(data[`convertSource`] === 'キャラクターシート倉庫'){
            form[`fromPartner${num}MarkerPosition`].readOnly = false;
            form[`fromPartner${num}MarkerColor`   ].readOnly = false;
            form[`fromPartner${num}Emotion1`].readOnly = false;
            form[`fromPartner${num}Emotion2`].readOnly = false;  
          }
          else {
            form[`fromPartner${num}MarkerPosition`].value = data[`toPartner${from}MarkerPosition`] || '';
            form[`fromPartner${num}MarkerColor`   ].value = data[`toPartner${from}MarkerColor`   ] || '';
            form[`fromPartner${num}Emotion1`].value = data[`toPartner${from}Emotion1`] || '';
            form[`fromPartner${num}Emotion2`].value = data[`toPartner${from}Emotion2`] || '';
          }
        }
        else {
          form[`partner${num}Url`].classList.add('error');
          form[`fromPartner${num}MarkerPosition`].value = '';
          form[`fromPartner${num}MarkerColor`   ].value = '';
          form[`fromPartner${num}Emotion1`].value = '';
          form[`fromPartner${num}Emotion2`].value = '';
        }
      });
    }
  }
}
function togglePartner2(){
  document.getElementById('partner2area').style.display = form.partner2On.checked ? '' : 'none';
}

// キズナ欄 ----------------------------------------
// ヒビワレ
function checkHibi(num){
  if(!form[`kizuna${num}Hibi`].checked){ form[`kizuna${num}Ware`].checked = false }
  checkHibiWare(num);
}
function checkWare(num){
  if(form[`kizuna${num}Ware`].checked){ form[`kizuna${num}Hibi`].checked = true }
  checkHibiWare(num);
}
function checkHibiWare(num){
  const obj = document.getElementById(`kizuna-row${num}`);
  obj.classList.remove('hibi', 'hibiware');
  if     (form[`kizuna${num}Ware`].checked){ obj.classList.add('hibiware') }
  else if(form[`kizuna${num}Hibi`].checked){ obj.classList.add('hibi') }
}
// 追加
function addKizuna(){
  document.querySelector("#kizuna-table tbody").append(createRow('kizuna','kizunaNum',13));
}
// 削除
function delKizuna(){
  delRow('kizunaNum', '#kizuna-table tbody tr:last-of-type');
}
// ソート
setSortable('kizuna','#kizuna-table tbody','tr');

// キズアト欄 ----------------------------------------
// 追加
function addKizuato(){
  document.querySelector("#kizuato-table").append(createRow('kizuato','kizuatoNum'));
}
// 削除
function delKizuato(){
  delRow('kizuatoNum', '#kizuato-table tbody:last-of-type');
}
// ソート
setSortable('kizuato','#kizuato-table','tbody');

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
