"use strict";
const gameSystem = 'blp';

// ----------------------------------------
window.onload = function() {
  
  nameSet();
  calcGrow();
  changeType();
  
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
  }
  else if(pcClass === 'オーナー'){
    document.body.classList.add('class-owner');
    document.body.classList.remove('class-hound');
  }
  calcStt();
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
  document.getElementById("endurance-grow").innerHTML = enduranceGrow;
  document.getElementById("operation-grow").innerHTML = operationGrow;
  
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

  document.getElementById("endurance-total").innerHTML = enduranceTotal;
  document.getElementById("operation-total").innerHTML = operationTotal;
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
  const obj = document.getElementById(`kizuna${num}`);
  obj.classList.remove('hibi', 'hibiware');
  if     (form[`kizuna${num}Ware`].checked){ obj.classList.add('hibiware') }
  else if(form[`kizuna${num}Hibi`].checked){ obj.classList.add('hibi') }
}
// 追加
function addKizuna(){
  let num = Number(form.kizunaNum.value) + 1;
  if(num > 13){ return; }
  let tbody = document.createElement('tr');
  tbody.setAttribute('id',idNumSet('kizuna'));
  tbody.innerHTML = `
    <td class="handle"></td>
    <td><input name="kizuna${num}Name" type="text"></td>
    <td><input name="kizuna${num}Note" type="text"</td>
    <td><input name="kizuna${num}Hibi" type="checkbox" value="1" onchange="checkHibi(${num})"></td>
    <td><input name="kizuna${num}Ware" type="checkbox" value="1" onchange="checkWare(${num})"></td>
  `;
  const target = document.querySelector("#kizuna-table tbody");
  target.appendChild(tbody, target);
  
  form.kizunaNum.value = num;
}
// 削除
function delKizuna(){
  let num = Number(form.kizunaNum.value);
  if(num > 0){
    if(form[`kizuna${num}Name`].value || form[`kizuna${num}Note`].value || form[`kizuna${num}Hibi`].checked || form[`kizuna${num}Ware`].checked
    ){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#kizuna-table tbody tr:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.kizunaNum.value = num;
  }
}
// ソート
let kizunaSortable = Sortable.create(document.querySelector('#kizuna-table tbody'), {
  group: "kizuna",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function(evt){
    const order = kizunaSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Name"]`).setAttribute('name',`kizuna${num}Name`);
        document.querySelector(`#${id} [name$="Note"]`).setAttribute('name',`kizuna${num}Note`);
        document.querySelector(`#${id} [name$="Hibi"]`).setAttribute('name',`kizuna${num}Hibi`);
        document.querySelector(`#${id} [name$="Ware"]`).setAttribute('name',`kizuna${num}Ware`);
        num++;
      }
    }
  }
});


// キズアト欄 ----------------------------------------
// 追加
function addKizuato(){
  let num = Number(form.kizuatoNum.value) + 1;
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id',idNumSet('kizuato'));
  tbody.innerHTML = `<tr>
      <td class="name" colspan="6">名称:《<input name="kizuato${num}Name" type="text">》</td>
    </tr>
    <tr>
      <th rowspan="2">ドラマ</th>
      <th>ヒトガラ</th>
      <th>タイミング</th>
      <th>対象</th>
      <th>制限</th>
      <th>解説</th>
    </tr>
    <tr>
      <td><input name="kizuato${num}DramaHitogara" type="text"></td>
      <td><input name="kizuato${num}DramaTiming" type="text" list="list-dtiming"></td>
      <td><input name="kizuato${num}DramaTarget" type="text" list="list-dtarget"></td>
      <td><input name="kizuato${num}DramaLimited" type="text" list="list-dlimited"></td>
      <td class="left"><input name="kizuato${num}DramaNote" type="text"></td>
    </tr>
    <tr>
      <th rowspan="2">決戦</th>
      <th>タイミング</th>
      <th>対象</th>
      <th>代償</th>
      <th>制限</th>
      <th>解説</th>
    </tr>
    <tr>
      <td><input name="kizuato${num}BattleTiming" type="text" list="list-btiming"></td>
      <td><input name="kizuato${num}BattleTarget" type="text" list="list-btarget"></td>
      <td><input name="kizuato${num}BattleCost" type="text" list="list-bcost"></td>
      <td><input name="kizuato${num}BattleLimited" type="text" list="list-blimited"></td>
      <td class="left"><input name="kizuato${num}BattleNote" type="text"></td>
  </tr>`;
  const target = document.querySelector("#kizuato-table");
  target.appendChild(tbody, target);
  
  form.kizuatoNum.value = num;
}
// 削除
function delKizuato(){
  let num = Number(form.kizuatoNum.value);
  if(num > 0){
    if(
      form[`kizuato${num}Name`].value ||
      form[`kizuato${num}DramaTiming`  ].value || form[`kizuato${num}BattleTiming` ].value || 
      form[`kizuato${num}DramaTarget`  ].value || form[`kizuato${num}BattleTarget` ].value || 
      form[`kizuato${num}DramaHitogara`].value || form[`kizuato${num}BattleCost`   ].value || 
      form[`kizuato${num}DramaLimited` ].value || form[`kizuato${num}BattleLimited`].value ||
      form[`kizuato${num}DramaNote`    ].value || form[`kizuato${num}BattleNote`   ].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    const target = document.querySelector("#kizuato-table tbody:last-of-type");
    target.parentNode.removeChild(target);
    num--;
    form.kizuatoNum.value = num;
  }
}
// ソート
let kizuatoSortable = Sortable.create(document.getElementById('kizuato-table'), {
  group: "kizuato",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function(evt){
    const order = kizuatoSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`kizuato${num}Name`);
        document.querySelector(`#${id} [name$="DramaHitogara"]`).setAttribute('name',`kizuato${num}DramaHitogara`);
        document.querySelector(`#${id} [name$="DramaTiming"]`  ).setAttribute('name',`kizuato${num}DramaTiming`);
        document.querySelector(`#${id} [name$="DramaTarget"]`  ).setAttribute('name',`kizuato${num}DramaTarget`);
        document.querySelector(`#${id} [name$="DramaLimited"]` ).setAttribute('name',`kizuato${num}DramaLimited`);
        document.querySelector(`#${id} [name$="DramaNote"]`    ).setAttribute('name',`kizuato${num}DramaNote`);
        document.querySelector(`#${id} [name$="BattleTiming"]` ).setAttribute('name',`kizuato${num}BattleTiming`);
        document.querySelector(`#${id} [name$="BattleTarget"]` ).setAttribute('name',`kizuato${num}BattleTarget`);
        document.querySelector(`#${id} [name$="BattleCost"]`   ).setAttribute('name',`kizuato${num}BattleCost`);
        document.querySelector(`#${id} [name$="BattleLimited"]`).setAttribute('name',`kizuato${num}BattleLimited`);
        document.querySelector(`#${id} [name$="BattleNote"]`   ).setAttribute('name',`kizuato${num}BattleNote`);
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
    <td><select name="history${num}Grow" oninput="calcGrow()"><option><option value="endurance">耐久値+5<option value="operation">先制値+2</select></td>
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
