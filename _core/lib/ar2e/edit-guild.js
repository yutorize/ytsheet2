"use strict";
const gameSystem = 'ar2e';

window.onload = function() {
  setName();

  calcExp();
  calcCash();

  changeColor();
  deleteLoadingArea();
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.guildName.value === ''){
    alert('ギルド名を入力してください。');
    form.guildName.focus();
    return false;
  }
  if(!formPasswordCheck()){
    return false;
  }
  return true;
}

// 成長点 ----------------------------------------
function calcExp(){
  let total = 0;
  for (let i = 1; i <= Number(form.historyNum.value); i++){
    const obj = form['history'+i+'Exp'];
    let exp = safeEval(obj.value);
    if(isNaN(exp)){
      obj.classList.add('error');
    }
    else {
      total += exp;
      obj.classList.remove('error');
    }
  }
  let makeLevel = Number(form.makeLv.value || 0);
  let level = Number(form.guildSupportNum.value || 0) - 1;
  const used = calcUsedExp(makeLevel, level);
  
  document.getElementById("exp-rest").textContent = total - used;
  document.getElementById("exp-used").textContent = used;
  document.getElementById("history-exp-total").textContent = total;
}
function calcUsedExp(initialLevel, currentLevel) {
  return (currentLevel - initialLevel) * (initialLevel + currentLevel - 1) / 2 * 10;
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
  const row = obj.closest('tr');
  const data = await getYtsheetJSON(url);
  if(!data) return;
  row.querySelector('[name$="Name"  ]').value = data.characterName;
  row.querySelector('[name$="CL"    ]').value = data.level;
  row.querySelector('[name$="Race"  ]').value = data.race;
  row.querySelector('[name$="MClass"]').value = data.classMain;
  row.querySelector('[name$="SClass"]').value = data.classSupport;
  row.querySelector('[name$="Player"]').value = data.playerName;
}
// アカデミーサポート ----------------------------------------
// 追加
function addGuildSupport(){
  document.querySelector("#guild-supports table tbody").append(createRow('guild-support','guildSupportNum'));
  calcExp();
}
// 削除
function delGuildSupport(){
  if(delRow('guildSupportNum', '#guild-supports table tbody tr:last-of-type')){
    calcExp();
  }
}
// ソート
setSortable('guildSupport','#guild-supports table tbody','tr');


// 収支履歴計算 ----------------------------------------
function calcCash(){
  let cash = 0;
  let s = form.cashbook.value;
  s.replace(
    /::([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      cash += safeEval(num.slice(2)) || 0;
    }
  );
  document.getElementById('cashbook-total-value').textContent = cash;
  if(form.moneyAuto.checked){
    form.money.value = commify(cash);
    form.money.readOnly = true;
  }
  else {
    form.money.readOnly = false;
  }
}

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
