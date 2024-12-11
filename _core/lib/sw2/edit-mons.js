"use strict";
const gameSystem = 'sw2';

window.onload = function() {
  setName();
  rewriteMountLevel();
  updatePartsAutomatically();
  updatePartList();
  selectInputCheck(form.taxa,'その他')
  checkMount();

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
function setName(){
  let m = ruby(form.monsterName.value);
  let c = ruby(form.characterName.value);
  document.querySelector('#header-menu > h2 > span').innerHTML = c && m ? `${c}<small>（${m}）</small>` : (c || m || '(名称未入力)');

  function vCheck(id){
    if(form[id]){ return form[id].value; }
    else { return '' }
  }
}
// 騎獣 ----------------------------------------
let mountFlag = 0;
function checkMount(){
  mountFlag = form.mount.checked ? 1 : 0;
  form.classList.toggle('mount', mountFlag);
}
function checkLevel(){
  if(mountFlag){
    checkMountLevel();
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
function checkMountLevel(){
  let min = Number(form.lvMin.value) || 0;
  let max = Number(form.lvMax.value) || 0;
  if(max < min){ form.lvMax.value = max = min }
  if(form.lv.value != ''){
    if(form.lv.value < min){ form.lv.value = min }
    if(form.lv.value > max){ form.lv.value = max }
  }
  let gap = max - min;
  gap = gap < 0 ? 0 : gap;
  if(gap > 0){
    for(let lv = 2; lv <= gap+1; lv++){
      if(!document.getElementById(`status-tbody${lv}`)){
        let tbody = document.createElement("tbody");
        tbody.classList.add('mount-only');
        tbody.id = `status-tbody${lv}`;
        tbody.dataset.lv = lv;
        document.getElementById('status-table').append(tbody);
        for(let num = 1; num <= form.statusNum.value; num++){
          addStatusInsert(tbody, num);
        }
      }
    }
  }
  for(let lv = gap+2; document.getElementById(`status-tbody${lv}`); lv++){
    document.getElementById(`status-tbody${lv}`).remove();
  }
  for(let num = 1; num <= form.statusNum.value; num++){ checkStyle(num); }
  rewriteMountLevel(min);
}
function rewriteMountLevel(level){
  level ||= form.lvMin.value;
  document.querySelectorAll("#status-table tbody tr th:first-child").forEach(obj => {
    obj.textContent = '';
  });
  document.querySelectorAll("#status-table tbody tr:first-child th:first-child").forEach(obj => {
    obj.textContent = level;
    obj.classList.toggle('current', level == form.lv.value);
    level++;
  });
}
// 攻撃方法
function checkStyle(num){
  document.querySelectorAll(`#status-table .name[data-style="${num}"]`).forEach(obj => {
    obj.textContent = form[`status${num}Style`].value;
  });
}
// 追加・複製
function addStatus(copy){
  let num = Number(form.statusNum.value) + 1;
  document.querySelectorAll("#status-table tbody").forEach(obj => {
    addStatusInsert(obj, num, copy);
  });
  form.statusNum.value = num;
  statusTextInputToggle();
  updatePartsAutomatically();
}
function addStatusInsert(target, num, copy){
  const lv = target.dataset.lv ? '-'+target.dataset.lv : '';
  const ini = {
    "style"      : copy && !lv ? form[`status${copy}${lv}Style`       ].value : '',
    "accuracy"   : copy        ? form[`status${copy}${lv}Accuracy`    ].value : '',
    "accuracyFix": copy && !lv ? form[`status${copy}${lv}AccuracyFix` ].value : '',
    "damage"     : copy        ? form[`status${copy}${lv}Damage`      ].value : '2d+',
    "evasion"    : copy        ? form[`status${copy}${lv}Evasion`     ].value : '',
    "evasionFix" : copy && !lv ? form[`status${copy}${lv}EvasionFix`  ].value : '',
    "defense"    : copy        ? form[`status${copy}${lv}Defense`     ].value : '',
    "hp"         : copy        ? form[`status${copy}${lv}Hp`          ].value : '',
    "mp"         : copy        ? form[`status${copy}${lv}Mp`          ].value : '',
    "vit"        : copy        ? form[`status${copy}${lv}Vit`         ].value : (num == 1 ? '' : '―'),
    "mnd"        : copy        ? form[`status${copy}${lv}Mnd`         ].value : (num == 1 ? '' : '―'),
  };
  let tr = document.createElement('tr');
  tr.setAttribute('id',idNumSet('status-row',lv));
  tr.innerHTML = `
    <th class="mount-only"></th>
    <td ${ lv ? '' : `class="handle"`}></td>
    <td ${ lv ? 'class="name"' : ``} data-style="${num}">${ lv ? form[`status${num}Style`].value : `<input name="status${num}${lv}Style" type="text" value="${ini.style}" oninput="checkStyle(${num}${lv}); updatePartsAutomatically();">` }</td>
    <td>
      <input name="status${num}${lv}Accuracy" type="text" oninput="calcAcc('${num}${lv}')" value="${ini.accuracy}"><span class="monster-only calc-only"><br>
      (<input name="status${num}${lv}AccuracyFix" type="text" oninput="calcAccF('${num}${lv}')" value="${ini.accuracyFix}">)</span>
    </td>
    <td><input name="status${num}${lv}Damage" type="text" value="${ini.damage}"></td>
    <td>
      <input name="status${num}${lv}Evasion" type="text" oninput="calcEva('${num}${lv}')" value="${ini.evasion}"><span class="monster-only calc-only"><br>
      (<input name="status${num}${lv}EvasionFix" type="text" oninput="calcEvaF('${num}${lv}')" value="${ini.evasionFix}">)</span>
    </td>
    <td><input name="status${num}${lv}Defense" type="text" value="${ini.defense}"></td>
    <td><input name="status${num}${lv}Hp" type="text" value="${ini.hp}"></td>
    <td><input name="status${num}${lv}Mp" type="text" value="${ini.mp}"></td>
    <td class="mount-only"><input name="status${num}${lv}Vit" type="text" value="${ini.vit}"></td>
    <td class="mount-only"><input name="status${num}${lv}Mnd" type="text" value="${ini.mnd}"></td>
    <td>${ lv ? '' : `<span class="button" onclick="addStatus('${num}${lv}');">複<br>製</span>` }</td>
  `;
  target.appendChild(tr, target);
}
// 削除
function delStatus(){
  let num = Number(form.statusNum.value);
  if(num > 1){
    let hasValue = false;
    for (const node of document.querySelectorAll(`#status-table tbody tr:last-child input`)){
      if(
        node.value !== '' &&
        !(/Damage$/.test(node.getAttribute('name')) && node.value === '2d+') &&
        !(/Vit$/.test(node.getAttribute('name')) && node.value === '―') &&
        !(/Mnd$/.test(node.getAttribute('name')) && node.value === '―')
      ){
        hasValue = true; break;
      }
    }
    if(hasValue){
      if (!confirm(delConfirmText)){ return false; }
    }
    document.querySelectorAll("#status-table tbody tr:last-child").forEach(target => {
      target.remove();
    });
    num--;
    form.statusNum.value = num;
  }
  updatePartsAutomatically();
}
// ソート
(() => {
  let sortable = Sortable.create(document.querySelector('#status-table tbody'), {
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot',
    onUpdate: function (evt) {
      const order = sortable.toArray();
      let num = 1;
      for(let id of order) {
        const row = document.querySelector(`tr#${id}`);
        if(!row) continue;
        row.querySelectorAll('[name]').forEach(inputField => {
          const beforeName = inputField.getAttribute('name');
          const afterName = beforeName.replace(/^(status)\d+(.+)$/, `$1${num}$2`);
          inputField.setAttribute('name', afterName)
        });
        row.querySelectorAll('[oninput]').forEach(inputField => {
          const beforeName = inputField.getAttribute('oninput');
          const afterName = beforeName.replace(/\(\d+\)/, `(${num})`);
          inputField.setAttribute('oninput', afterName)
        });
        row.querySelector(`span[onclick]`).setAttribute('onclick',`addStatus(${num})`);
        num++;
      }
      const moved  = evt.item.id;
      const before = evt.item.previousElementSibling ? evt.item.previousElementSibling.id : '';
      document.querySelectorAll("#status-table tbody").forEach(obj => {
        const lv = obj.dataset.lv;
        if(lv){
          if(before){
            document.getElementById(before+'-'+lv).after(document.getElementById(moved+'-'+lv));
          }
          else {
            document.getElementById(`status-tbody${lv}`).prepend(document.getElementById(moved+'-'+lv))
          }
          let num = 1;
          for(let id of order) {
            const row = document.querySelector(`tr#${id}-${lv}`);
            if(!row) continue;
            row.querySelectorAll('[name]').forEach(inputField => {
              const beforeName = inputField.getAttribute('name');
              const afterName = beforeName.replace(/^(status)\d+-(.+)$/, `$1${num}-$2`);
              inputField.setAttribute('name', afterName)
            });
            row.querySelector(`.name`).dataset.style = num;
            num++;
          }
        }
      });
      rewriteMountLevel();
      updatePartsAutomatically();
    }
  });
})();
//
function statusTextInputToggle(){
  const on = form.statusTextInput.checked ? 1 : form.mount.checked ? 1 : 0;
  form[`vitResist`].type    = on ? 'text'   : 'number';
  form[`mndResist`].type    = on ? 'text'   : 'number';
  for(let i = 1; i <= form.statusNum.value; i++){
    form[`status${i}Accuracy`].type    = on ? 'text'   : 'number';
    form[`status${i}Evasion`].type     = on ? 'text'   : 'number';
  }
  form.classList.toggle('not-calc', on)
}
// 部位数・内訳の自動入力
function updatePartsAutomatically() {
  const manualModeCheckbox = document.querySelector('input[type="checkbox"][name="partsManualInput"]');
  const partsNumInput = document.querySelector('.parts input[name="partsNum"]');
  const partsNamesInput = document.querySelector('.parts input[name="parts"]');

  if (manualModeCheckbox.checked) {
    partsNumInput.readOnly = false;
    partsNamesInput.readOnly = false;
    return;
  }

  let partCount = 0;
  const partNames = [];
  document.querySelectorAll('#status-tbody input[name$="Style"]').forEach(
      input => {
        partCount++;

        const style = input.value.trim();
        const m = style.match(/.*[(（](.+?)[）)]$/);
        if (m == null) {
          return;
        }
        partNames.push(m[1].trim());
      }
  );

  partsNumInput.readOnly = true;
  partsNumInput.value = partCount.toString();
  partsNumInput.dispatchEvent(new Event('input'));

  partsNamesInput.readOnly = true;
  partsNamesInput.value = partNames.length === 0 ? '' : partNames.reduce(
      (previous, currentPartName) => {
        const previousPartTexts = previous.split('／');
        const lastPartText = previousPartTexts[previousPartTexts.length - 1];
        const m = lastPartText.match(/^(.+?)(?:×(\d+))?$/);
        const lastPartName = m[1];
        const lastPartCount = m[2] ? parseInt(m[2]) : 1;
        return currentPartName === lastPartName
            ? `${previousPartTexts.length > 1 ? `${previousPartTexts.slice(0, -1).join('／')}／` : ''}${lastPartName}×${lastPartCount + 1}`
            : `${previous}／${currentPartName}`;
      }
  );
  partsNamesInput.dispatchEvent(new Event('input'));
}
function updatePartList() {
  const partsText = document.querySelector('input[name="parts"]').value.trim();

  const items =
      partsText
          .split(/[/／]/)
          .map(x => x.trim())
          .filter(x => x !== '')
          .map(part => part.replace(/[*×][\d０１２３４５６７８９]+$/, '（すべて）'));

  const datalist = document.getElementById('list-of-core-part');
  datalist.innerHTML = '';

  if (items.length === 0) {
    return;
  }

  items.unshift("なし");

  items.forEach(
      item => {
        const option = document.createElement('option');
        option.textContent = item;
        datalist.appendChild(option);
      }
  );
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
    listNum.lastElementChild.remove();
    listItem.lastElementChild.remove();
    num--;
    form.lootsNum.value = num;
  }
}
// ソート
setSortable('loots','#loots-num');
setSortable('loots','#loots-item');
