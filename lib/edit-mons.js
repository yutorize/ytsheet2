const form = document.sheet;

function calcVit(){
  form.vitResistFix.value = Number(form.vitResist.value) + 7;
}
function calcVitF(){
  form.vitResist.value = Number(form.vitResistFix.value) - 7;
}
function calcMnd(){
  form.mndResistFix.value = Number(form.mndResist.value) + 7;
}
function calcMndF(){
  form.mndResist.value = Number(form.mndResistFix.value) - 7;
}
function calcAcc(Num){
  form['status'+Num+'AccuracyFix'].value = Number(form['status'+Num+'Accuracy'].value) + 7;
}
function calcAccF(Num){
  form['status'+Num+'Accuracy'].value = Number(form['status'+Num+'AccuracyFix'].value) - 7;
}
function calcEva(Num){
  form['status'+Num+'EvasionFix'].value = Number(form['status'+Num+'Evasion'].value) + 7;
}
function calcEvaF(Num){
  form['status'+Num+'Evasion'].value = Number(form['status'+Num+'EvasionFix'].value) - 7;
}


// ステータス欄追加 //
function addStatus(){
  let num = Number(form.statusNum.value) + 1;
  let table1 = document.getElementById("status-table");
  let row1 = table1.insertRow(-1);
  let cell0  = row1.insertCell(0);
  let cell1  = row1.insertCell(1);
  let cell2  = row1.insertCell(2);
  let cell3  = row1.insertCell(3);
  let cell4  = row1.insertCell(4);
  let cell5  = row1.insertCell(5);
  let cell6  = row1.insertCell(6);
  
  cell0.innerHTML  = '<input type="text" name="status' + num + 'Style">';
  cell1.innerHTML  = '<input type="number" name="status' + num + 'Accuracy" oninput="calcAcc(' + num + ')"><br>(<input type="number" name="status' + num + 'AccuracyFix" oninput="calcAccF(' + num + ')">)';
  cell2.innerHTML  = '<input type="text" name="status' + num + 'Damage" value="2d6+">';
  cell3.innerHTML  = '<input type="number" name="status' + num + 'Evasion" oninput="calcEva(' + num + ')"><br>(<input type="number" name="status' + num + 'EvasionFix" oninput="calcEvaF(' + num + ')">)';
  cell4.innerHTML  = '<input type="text" name="status' + num + 'Defense">';
  cell5.innerHTML  = '<input type="text" name="status' + num + 'Hp">';
  cell6.innerHTML  = '<input type="text" name="status' + num + 'Mp">';
  
  form.statusNum.value = num;
}
function delStatus(){
  let num = Number(form.statusNum.value);
  if(num > 1){
    let table1 = document.getElementById("status-table");
    table1.deleteRow(-1);
    num--;
    form.statusNum.value = num;
  }
}

// 戦利品欄追加 //
function addLoots(){
  let num = Number(form.lootsNum.value) + 1;
  let dt = document.createElement('dt');
  let dd = document.createElement('dd');
  dt.innerHTML = '<input type="text" name="loots'+num+'Num">';
  dd.innerHTML = '<input type="text" name="loots'+num+'Item">';
  document.getElementById("loots-list").appendChild(dt);
  document.getElementById("loots-list").appendChild(dd);
  
  form.lootsNum.value = num;
}
function delLoots(){
  let num = Number(form.lootsNum.value);
  if(num > 1){
    const lists = document.getElementById("loots-list");
    lists.removeChild(lists.lastElementChild);
    lists.removeChild(lists.lastElementChild);
    num--;
    form.lootsNum.value = num;
  }
}

// 表示／非表示 //
function view(viewId){
  let value = document.getElementById(viewId).style.display;
  document.getElementById(viewId).style.display = (value === 'none') ? '' : 'none';
}

// セクション選択 //
function sectionSelect(id){
  const sections = ['common','palette'];
  sections.forEach( (value) => {
    document.getElementById('section-'+value).style.display = 'none';
  });
  document.getElementById('section-'+id).style.display = 'block';
}





