"use strict";
const gameSystem = 'sw2';

window.onload = function() {
  nameSet();

  changeColor();
}

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.monsterName.value === '' && form.characterName.value === ''){
    alert('名称か名前のいずれかを入力してください。');
    form.monsterName.focus();
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
  let m = ruby(form.monsterName.value);
  let c = ruby(form.characterName.value);
  document.querySelector('#header-menu > h2 > span').innerHTML = c && m ? `${c}<small>（${m}）</small>` : (c || m || '(名称未入力)');

  function vCheck(id){
    if(form[id]){ return form[id].value; }
    else { return '' }
  }
}
// 各ステータス計算 ----------------------------------------
function calcVit(){
  const val = form.vitResist.value;
  form.vitResistFix.value = (val == '') ? '' : Number(val) + 7;
}
function calcVitF(){
  const val = form.vitResistFix.value;
  form.vitResist.value    = (val == '') ? '' : Number(val) - 7;
}
function calcMnd(){
  const val = form.mndResist.value;
  form.mndResistFix.value = (val == '') ? '' : Number(val) + 7;
}
function calcMndF(){
  const val = form.mndResistFix.value;
  form.mndResist.value    = (val == '') ? '' : Number(val) - 7;
}
function calcAcc(Num){
  const val = form['status'+Num+'Accuracy'].value;
  form['status'+Num+'AccuracyFix'].value = (val == '') ? '' : Number(val) + 7;
}
function calcAccF(Num){
  const val = form['status'+Num+'AccuracyFix'].value;
  form['status'+Num+'Accuracy'].value    = (val == '') ? '' : Number(val) - 7;
}
function calcEva(Num){
  const val = form['status'+Num+'Evasion'].value;
  form['status'+Num+'EvasionFix'].value  = (val == '') ? '' : Number(val) + 7;
}
function calcEvaF(Num){
  const val = form['status'+Num+'EvasionFix'].value;
  form['status'+Num+'Evasion'].value     = (val == '') ? '' : Number(val) - 7;
}

// ステータス欄 ----------------------------------------
// 追加
function addStatus(copy){
  const ini = {
    "style"      : copy ? form[`status${copy}Style`       ].value : '',
    "accuracy"   : copy ? form[`status${copy}Accuracy`    ].value : '',
    "accuracyFix": copy ? form[`status${copy}AccuracyFix` ].value : '',
    "damage"     : copy ? form[`status${copy}Damage`      ].value : '2d6+',
    "evasion"    : copy ? form[`status${copy}Evasion`     ].value : '',
    "evasionFix" : copy ? form[`status${copy}EvasionFix`  ].value : '',
    "defense"    : copy ? form[`status${copy}Defense`     ].value : '',
    "hp"         : copy ? form[`status${copy}Hp`          ].value : '',
    "mp"         : copy ? form[`status${copy}Mp`          ].value : '',
  };
  let num = Number(form.statusNum.value) + 1;
  let tbody = document.createElement('tr');
  tbody.setAttribute('id',idNumSet('status-row'));
  tbody.innerHTML = `
    <td class="handle"></td>
    <td><input name="status${num}Style" type="text" value="${ini.style}"></td>
    <td>
      <input name="status${num}Accuracy" type="number" oninput="calcAcc(${num})" value="${ini.accuracy}"><br>
      (<input name="status${num}AccuracyFix" type="number" oninput="calcAccF(${num})" value="${ini.accuracyFix}">)
    </td>
    <td><input name="status${num}Damage" type="text" value="${ini.damage}"></td>
    <td>
      <input name="status${num}Evasion" type="number" oninput="calcEva(${num})" value="${ini.evasion}"><br>
      (<input name="status${num}EvasionFix" type="number" oninput="calcEvaF(${num})" value="${ini.evasionFix}">)
    </td>
    <td><input name="status${num}Defense" type="text" value="${ini.defense}"></td>
    <td><input name="status${num}Hp" type="text" value="${ini.hp}"></td>
    <td><input name="status${num}Mp" type="text" value="${ini.mp}"></td>
    <td><span class="button" onclick="addStatus(${num});">複<br>製</span></td>
  `;
  const target = document.querySelector("#status-table tbody");
  target.appendChild(tbody, target);
  form.statusNum.value = num;
  statusTextInputToggle();
}
// 複製
function copyStatus(num){
  addStatus();
  
}
// 削除
function delStatus(){
  let num = Number(form.statusNum.value);
  if(num > 1){
    if(form[`status${num}Style`].value || form[`status${num}Accuracy`].value || form[`status${num}AccuracyFix`].value || form[`status${num}Evasion`].value || form[`status${num}EvasionFix`].value || form[`status${num}Defense`].value || form[`status${num}Hp`].value || form[`status${num}Mp`].value){
      if (!confirm(delConfirmText)) return false;
    }
    let table = document.getElementById("status-table");
    table.deleteRow(-1);
    num--;
    form.statusNum.value = num;
  }
}
// ソート
let statusSortable = Sortable.create(document.querySelector('#status-table tbody'), {
  group: "status",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = statusSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Style"]`      ).setAttribute('name',`status${num}Style`);
        document.querySelector(`#${id} [name$="Accuracy"]`   ).setAttribute('name',`status${num}Accuracy`);
        document.querySelector(`#${id} [name$="AccuracyFix"]`).setAttribute('name',`status${num}AccuracyFix`);
        document.querySelector(`#${id} [name$="Damage"]`     ).setAttribute('name',`status${num}Damage`);
        document.querySelector(`#${id} [name$="Evasion"]`    ).setAttribute('name',`status${num}Evasion`);
        document.querySelector(`#${id} [name$="EvasionFix"]` ).setAttribute('name',`status${num}EvasionFix`);
        document.querySelector(`#${id} [name$="Defense"]`    ).setAttribute('name',`status${num}Defense`);
        document.querySelector(`#${id} [name$="Hp"]`         ).setAttribute('name',`status${num}Hp`);
        document.querySelector(`#${id} [name$="Mp"]`         ).setAttribute('name',`status${num}Mp`);
        document.querySelector(`#${id} [name$="Accuracy"]`   ).setAttribute('oninput',`calcAcc(${num})`);
        document.querySelector(`#${id} [name$="AccuracyFix"]`).setAttribute('oninput',`calcAccF(${num})`);
        document.querySelector(`#${id} [name$="Evasion"]`    ).setAttribute('oninput',`calcEva(${num})`);
        document.querySelector(`#${id} [name$="EvasionFix"]` ).setAttribute('oninput',`calcEvaF(${num})`);
        document.querySelector(`#${id} span[onclick]`        ).setAttribute('onclick',`addStatus(${num})`);
        num++;
      }
    }
  }
});
//
function statusTextInputToggle(){
  const on = form.statusTextInput.checked ? 1 : 0;
  form[`vitResist`].type    = on ? 'text'   : 'number';
  form[`vitResistFix`].type = on ? 'hidden' : 'number';
  form[`mndResist`].type    = on ? 'text'   : 'number';
  form[`mndResistFix`].type = on ? 'hidden' : 'number';
  for(let i = 1; i <= form.statusNum.value; i++){
    form[`status${i}Accuracy`].type    = on ? 'text'   : 'number';
    form[`status${i}AccuracyFix`].type = on ? 'hidden' : 'number';
    form[`status${i}Evasion`].type     = on ? 'text'   : 'number';
    form[`status${i}EvasionFix`].type  = on ? 'hidden' : 'number';
  }
}

// 戦利品欄 ----------------------------------------
// 追加
function addLoots(){
  let num = Number(form.lootsNum.value) + 1;
  let liNum = document.createElement('li');
  let liItem = document.createElement('li');
  liNum.id= idNumSet("loots-num");
  liItem.id= idNumSet("loots-item");
  liNum.innerHTML = '<span class="handle"></span><input type="text" name="loots'+num+'Num">';
  liItem.innerHTML = '<span class="handle"></span><input type="text" name="loots'+num+'Item">';
  document.getElementById("loots-num").appendChild(liNum);
  document.getElementById("loots-item").appendChild(liItem);
  
  form.lootsNum.value = num;
}
// 削除
function delLoots(){
  let num = Number(form.lootsNum.value);
  if(num > 1){
    if(form[`loots${num}Num`].value || form[`loots${num}Item`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const listNum  = document.getElementById("loots-num");
    const listItem = document.getElementById("loots-item");
    listNum.removeChild(listNum.lastElementChild);
    listItem.removeChild(listItem.lastElementChild);
    num--;
    form.lootsNum.value = num;
  }
}
// ソート
let lootsNumSortable = Sortable.create(document.querySelector('#loots-num'), {
  group: "loots",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = lootsNumSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} input`).setAttribute('name',`loots${num}Num`);
        num++;
      }
    }
  }
});
let lootsItemSortable = Sortable.create(document.querySelector('#loots-item'), {
  group: "loots",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = lootsItemSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} input`).setAttribute('name',`loots${num}Item`);
        num++;
      }
    }
  }
});
