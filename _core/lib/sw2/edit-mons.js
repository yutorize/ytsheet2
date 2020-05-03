"use strict";
const form = document.sheet;

const delConfirmText = '項目に値が入っています。本当に削除しますか？';

// //
function calcVit(){
  const val = form.vitResist.value;
  form.vitResistFix.value = (val == '') ? '' : Number(val) + 7;
}
function calcVitF(){
  const val = form.vitResistFix.value;
  form.vitResist.value    = (val == '') ? '' : Number(val) + 7;
}
function calcMnd(){
  const val = form.mndResist.value;
  form.mndResistFix.value = (val == '') ? '' : Number(val) + 7;
}
function calcMndF(){
  const val = form.mndResistFix.value;
  form.mndResist.value    = (val == '') ? '' : Number(val) + 7;
}
function calcAcc(Num){
  const val = form['status'+Num+'Accuracy'].value;
  form['status'+Num+'AccuracyFix'].value = (val == '') ? '' : Number(val) + 7;
}
function calcAccF(Num){
  const val = form['status'+Num+'AccuracyFix'].value;
  form['status'+Num+'Accuracy'].value    = (val == '') ? '' : Number(val) + 7;
}
function calcEva(Num){
  const val = form['status'+Num+'Evasion'].value;
  form['status'+Num+'EvasionFix'].value  = (val == '') ? '' : Number(val) + 7;
}
function calcEvaF(Num){
  const val = form['status'+Num+'EvasionFix'].value;
  form['status'+Num+'Evasion'].value     = (val == '') ? '' : Number(val) + 7;
}


// ステータス欄 ----------------------------------------
// 追加
function addStatus(){
  let num = Number(form.statusNum.value) + 1;
  let tbody = document.createElement('tr');
  tbody.setAttribute('id',idNumSet('status-row'));
  tbody.innerHTML = `
    <td class="handle"></td>
    <td><input name="status${num}Style" type="text"></td>
    <td>
      <input name="status${num}Accuracy" type="number" oninput="calcAcc(${num})"><br>
      (<input name="status${num}AccuracyFix" type="number" oninput="calcAccF(${num})">)
    </td>
    <td><input name="status${num}Damage" type="text" value="2d6+"></td>
    <td>
      <input name="status${num}Evasion" type="number" oninput="calcEva(${num})"><br>
      (<input name="status${num}EvasionFix" type="number" oninput="calcEvaF(${num})">)
    </td>
    <td><input name="status${num}Defense" type="text"></td>
    <td><input name="status${num}Hp" type="text"></td>
    <td><input name="status${num}Mp" type="text"></td>
  `;
  const target = document.querySelector("#status-table tbody");
  target.appendChild(tbody, target);
  form.statusNum.value = num;
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
        num++;
      }
    }
  }
});

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

// セクション選択 ----------------------------------------
function sectionSelect(id){
  const sections = ['common','palette'];
  sections.forEach( (value) => {
    document.getElementById('section-'+value).style.display = 'none';
  });
  document.getElementById('section-'+id).style.display = 'block';
}

// 連番ID生成 ----------------------------------------
function idNumSet (id){
  let num = 1;
  while(document.getElementById(id+num)){
    num++;
  }
  return id+num;
}



