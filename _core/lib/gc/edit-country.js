"use strict";
const gameSystem = 'vc';

window.onload = function() {
  setName();

  calcCounts();
  calcResources();

  changeColor();
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.countryName.value === ''){
    alert('クラン名を入力してください。');
    form.countryName.focus();
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
  let c = ruby(form.countryName.value);
  document.querySelector('#header-menu > h2 > span').innerHTML = c ?? '(名称未入力)';

  function vCheck(id){
    if(form[id]){ return form[id].value; }
    else { return '' }
  }
}

// 爵位 ----------------------------------------
function changePeerage(){
  calcCounts();
}
function calcCounts(){
  let countsTotal = 0;
  const peerage = form.makePeerage.value || '騎士';
  countsTotal += SET.peerageRank?.[peerage].counts || 0;
  
  for (let i = 1; i <= form.historyNum.value; i++){
    const obj = form['history'+i+'Counts'];
    let counts = safeEval(obj.value);
    if(isNaN(counts)){
      obj.classList.add('error');
    }
    else {
      countsTotal += counts;
      obj.classList.remove('error');
    }
  }
  let newPeerage = '';
  let newPeerageSortRank = 0;
  for (let [key, value] of Object.entries(SET.peerageRank)){
    if(countsTotal >= value.counts && value.lv >= newPeerageSortRank){
      newPeerage = key;
      newPeerageSortRank = value.lv;
    }
  }
  let countsAS = 0;
  for (let i = 1; i <= form.academySupportNum.value; i++){
    countsAS += Number(form['academySupport'+i+'Cost'].value || 0);
  }
  let countsArtifact = 0;
  for (let i = 1; i <= form.artifactNum.value; i++){
    countsArtifact += Number(form['artifact'+i+'Cost'].value || 0) * Number(form['artifact'+i+'Quantity'].value || 0);
  }
  const countsUsed = countsAS + countsArtifact;
  const level = parseInt(countsTotal / 1000);
  document.querySelector("#level dd").textContent = level;
  document.querySelector("#counts dd").textContent = commify(countsTotal - countsUsed);
  document.querySelector("#peerage dd").textContent = newPeerage;
  document.getElementById(`grow-max`).textContent = level - 1;
  document.querySelector("#exp-footer .counts-total").textContent = commify(countsTotal);
  document.querySelector("#exp-footer .counts-used-as").textContent = commify(countsAS);
  document.querySelector("#exp-footer .counts-used-artifact").textContent = commify(countsArtifact);
  document.querySelector("#exp-footer .counts-rest").textContent = commify(countsTotal - countsUsed);
}
// 資源 ----------------------------------------
function calcResources(){
  let growTotal = 0;
  for (let type of ['Food','Tech','Horse','Mineral','Forest','Funds']){
    let resource = 1;
    for (let i = 1; i <= form.characteristicNum.value; i++){
      resource += Number(form[`characteristic${i}${type}`].value || 0)
    }
    const grow = Number(form[`grow${type}`].value || 0);
    resource  += grow;
    growTotal += grow;
    document.querySelector(`#resources .${type}.total`).textContent = resource;
    
    let used = 0;
    for (let i = 1; i <= form.forceNum.value; i++){
      used += Number(form[`force${i}Cost${type}`].value || 0)
    }
    document.querySelector(`#resources .${type}.used`).textContent = used;
    document.getElementById(`grow-total`).textContent = growTotal;
  }
}
// メンバー ----------------------------------------
// 追加
function addMember(){
  document.querySelector("#members table tbody").append(createRow('member','memberNum'));
}
// 削除
function delMember(){
  delRow('memberNum', '#members table tbody tr:last-of-type');
}
// ソート
setSortable('member','#members table tbody','tr');

// URLから自動セット
async function setMemberData(obj){
  const url = obj.value;
  if(!url) return;
  const data = await getYtsheetJSON(url);
  if(!data) return;
  const row = obj.parentNode.parentNode;
  row.querySelector('[name$=Name]').value = data.characterName;
  row.querySelector('[name$=Class]').value = data.class;
  row.querySelector('[name$=Style]').value = data.style;
}
// アカデミーサポート ----------------------------------------
// 追加
function addAcademySupport(){
  document.querySelector("#academy-supports table tbody").append(createRow('academy-support','academySupportNum'));
}
// 削除
function delAcademySupport(){
  delRow('academySupportNum', '#academy-supports table tbody tr:last-of-type');
}
// ソート
setSortable('academySupport','#academy-supports table tbody','tr');

// アーティファクト ----------------------------------------
// 追加
function addArtifact(){
  document.querySelector("#artifacts table tbody").append(createRow('artifact','artifactNum'));
}
// 削除
function delArtifact(){
  delRow('artifactNum', '#artifacts table tbody tr:last-of-type');
}
// ソート
setSortable('artifact','#artifacts table tbody','tr');

// 国特徴 ----------------------------------------
// 追加
function addCharacteristic(){
  document.querySelector("#characteristics table tbody").append(createRow('characteristic','characteristicNum'));
}
// 削除
function delCharacteristic(){
  delRow('characteristicNum', '#characteristics table tbody tr:last-of-type');
}
// ソート
setSortable('characteristic','#characteristics table tbody','tr');

// 部隊 ----------------------------------------
// 追加
function addForce(copyBaseNum){
  const row = createRow('force','forceNum');
  const num = form.forceNum.value;
  document.querySelector(`#forces table tbody tr:nth-of-type(${copyBaseNum||num-1})`).after(row);
  
  if(copyBaseNum){
    row.querySelectorAll('[name]').forEach(node => {
      const copyBaseName = node.getAttribute('name').replace(/^(force)\d+(.+)$/, `$1${copyBaseNum}$2`)
      if(node.type === 'checkbox'){
        node.checked = form[copyBaseName].checked;
      }
      else { node.value = form[copyBaseName].value; }
    });
    calcResources();

    let i = 1;
    document.querySelectorAll(`#forces table tbody tr`).forEach(obj => {
      replaceSortedNames(obj,i,/^(force)[0-9]+(.*)$/);
      replaceSortedNames(obj,i,/^(addForce\()[0-9]+(\))$/,'onclick');
      i++;
    })
  }
}
// 削除
function delForce(){
  if(delRow('forceNum', '#forces table tbody tr:last-of-type')){
    calcResources();
  }
}
// ソート
setSortable('force', '#forces table tbody', 'tr', (row, num) => {
  replaceSortedNames(row,num,/^(addForce\()[0-9]+(\))$/,'onclick');
})

// セッション履歴 ----------------------------------------
// 追加
function addHistory(){
  document.querySelector("#history-table tfoot").before(createRow('history','historyNum'));
}
// 削除
function delHistory(){
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcExp();
  }
}
// ソート
setSortable('history','#history-table','tbody');
