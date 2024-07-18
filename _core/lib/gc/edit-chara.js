"use strict";
const gameSystem = 'vc';

window.onload = function() {
  setName();

  checkClass();
  checkStyle();
  checkWorks();

  if(level == 1){ toggleGrowRows() }
  for(let lv = 2; lv <= level; lv++){ checkGrow(lv) }
  
  checkLevel();
  calcExp();
  calcStatus();

  calcAbility('classAbility');
  calcAbility('worksAbility');
  calcAbility('magic');

  calcWeapons();
  calcArmors();
  calcItems();
  calcTotalWeight();
  
  imagePosition();
  changeColor();
};

// 送信前チェック ----------------------------------------
//function formCheck(){
//  if(form.characterName.value === '' && form.aka.value === ''){
//    alert('キャラクター名か二つ名のいずれかを入力してください。');
//    form.characterName.focus();
//    return false;
//  }
//  if(form.protect.value === 'password' && form.pass.value === ''){
//    alert('パスワードが入力されていません。');
//    form.pass.focus();
//    return false;
//  }
//  return true;
//}

// レギュレーション ----------------------------------------
function changeRegu(){
  if(level < form.makeLv.value){
    form.level.value = form.makeLv.value;
  }
  changeLevel();
}

// クラス ----------------------------------------
function checkClass(){
  const className = form.class.value;
  form.style.querySelectorAll(`option`).forEach(option => {
    const styleName = option.value;
    option.style.display = '';
    option.style.display = (SET.styleData[styleName] && SET.styleData[styleName].class !== className) ? 'none' : ''
  });
}
// スタイル ----------------------------------------
function changeStyle(){
  checkStyle();
  calcStatus();
}
function checkStyle(){
  const styleName = form.style.value;
  for(let id of ['Str','Ref','Per','Int','Mnd','Emp','Hp','Mp','HpGrow','MpGrow']){
    form[`stt${id}Style`].readOnly = false;
    if(SET.styleData[styleName]){
      form[`stt${id}Style`].value = SET.styleData[styleName].stt[id];
      form[`stt${id}Style`].readOnly = true;
    }
  }
}
// ワークス ----------------------------------------
function changeWorks(){
  checkWorks();
  calcStatus();
}
function checkWorks(){
  const worksName = form.works.value;
  for(let id of ['Str','Ref','Per','Int','Mnd','Emp','Hp','Mp']){
    form[`stt${id}Works`].readOnly = false;
    if(SET.worksData[worksName]){
      form[`stt${id}Works`].value = SET.worksData[worksName].stt[id];
      form[`stt${id}Works`].readOnly = true;
    }
  }
}

// レベル ----------------------------------------
let level = Number(form.level.value || 1);
function changeLevel(){
  const newLevel = Number(form.level.value || 1);
  if(newLevel <= 0){
    alert('レベルを0以下にはできません');
    form.level.value = level;
    return;
  }
  if(newLevel - level > 0){
    for(let i = level+1; i <= newLevel; i++){ addGrow(i); }
  }
  else if(newLevel - level < 0) {
    for(let i = level; i > newLevel; i--){
      if(!delGrow(i)){
        form.level.value = level = i;
        return;
      }
    }
  }
  level = newLevel;
  
  calcExp();
  checkLevel();
  calcStatus();
}
function checkLevel(){
  document.querySelector(`#exp-footer .max-works-ability`).textContent = level + 1;
}
// 追加
function addGrow(num){
  let row = document.getElementById('status-grow-template').content.firstElementChild.cloneNode(true);
  row.id = 'status-grow'+num;
  row.innerHTML = row.innerHTML.replaceAll('TMPL', num);
  document.querySelector("#status-table .status-other").before(row);
}
// 削除
function delGrow(num){
  const targetNode = document.getElementById(`status-grow${num}`);
  let hasChecked = false;
  for (const node of targetNode.querySelectorAll(`input[type="checkbox"]`)){
    if(node.checked) { hasChecked = true; break; }
  }
  if(hasChecked){
    if (!confirm(`記入済みの成長（${num}レベル）が削除されます。よろしいですか？`)){ return false; }
  }
  targetNode.remove();
  return true;
}
// 成長 ----------------------------------------
function changeGrow(lv){
  checkGrow(lv);
  calcStatus();
}
function checkGrow(lv){
  let count = 0;
  for(let id of ['Str','Ref','Per','Int','Mnd','Emp']){
    form[`stt${id}Grow${lv}`].parentNode.style.display = '';
    count += form[`stt${id}Grow${lv}`].checked ? 1 : 0;
  }
  if(count >= 3){
    for(let id of ['Str','Ref','Per','Int','Mnd','Emp']){
      if(!form[`stt${id}Grow${lv}`].checked){
        form[`stt${id}Grow${lv}`].parentNode.style.display = 'none'
      }
    }
  }
  document.getElementById('status-grow'+lv).dataset.checked = count;
}
let isOpenedGrow = false;
function toggleGrowRows(){
  isOpenedGrow = !isOpenedGrow;
  document.querySelectorAll('tr.status-grow').forEach(row=>{
    row.style.display = (isOpenedGrow || row.dataset.checked != 3) ? '' : 'none';
  })
  document.querySelector('#status .open-button').dataset.open = isOpenedGrow ? 'true' : '';
}
// 経験点 ----------------------------------------
function calcExp(){
  let total = 0;
  const historyNum = form.historyNum.value;
  for (let i = 1; i <= historyNum; i++){
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
  let used = 0;
  for(let i = 2; i <= level; i++){
    if(i > form.makeLv.value){
      used += i * 10;
    }
  }
  document.getElementById("exp-used").textContent = commify(used);
  document.getElementById("exp-rest").textContent = commify(total - used);
  document.getElementById("exp-total").textContent = commify(total);
  document.getElementById("history-exp-total").textContent = commify(total);

}
// 能力値 ----------------------------------------
function calcStatus(){
  let status = {};
  let makeTotal = 0;
  for(let id of ['Str','Ref','Per','Int','Mnd','Emp']){
    let total = Number(form[`stt${id}Works`].value || 0);

    let make = Number(form[`stt${id}Make` ].value || 0);
    total += make;
    makeTotal += make;
    form[`stt${id}Make`].classList.toggle('error', total > 15);
    
    total += Number(form[`stt${id}Mod`].value || 0);

    let grow = 0;
    for(let lv = 2; lv <= level; lv++){
      grow += form[`stt${id}Grow${lv}`].checked ? 1 : 0;
    }
    document.querySelector(`.status-grow-total .${id}`).textContent = grow;
    total += grow;

    document.querySelector(`.status-total .${id}`).textContent = total;
    status[id] = total;

    let check = parseInt(total / 3);
    document.querySelector(`.status-check-base .${id}`).textContent = check;

    check += Number(form[`stt${id}Style`].value || 0);
    document.querySelector(`.status-check-total .${id}`).textContent = check;
    document.querySelector(`#skill .${id}-value`).textContent = check;
  }

  document.getElementById("make-bonus-total").textContent = makeTotal;

  // HP
  const hpGrow = (level > 1) ? (level - 1) * Number(form[`sttHpGrowStyle`].value || 0) : 0;
  const hpBase = Number(form[`sttStrWorks`].value || 0) + Number(form[`sttStrMake`].value || 0);
  let hp = hpBase
    + Number(form[`sttHpWorks`].value || 0)
    + Number(form[`sttHpStyle`].value || 0)
    + Number(form[`sttHpMod`].value || 0)
    + hpGrow;
  document.querySelector(`.status-grow-total .Hp`).textContent = hpGrow;
  document.querySelector(`.status-base .Hp`).textContent = hpBase;
  document.querySelector(`.status-total .Hp`).textContent = hp;
  // MP
  const mpGrow = (level > 1) ? (level - 1) * Number(form[`sttMpGrowStyle`].value || 0) : 0;
  const mpBase = Number(form[`sttMndWorks`].value || 0) + Number(form[`sttMndMake`].value || 0);
  let mp = mpBase
    + Number(form[`sttMpWorks`].value || 0)
    + Number(form[`sttMpStyle`].value || 0)
    + Number(form[`sttMpMod`].value || 0)
    + mpGrow;
  document.querySelector(`.status-grow-total .Mp`).textContent = mpGrow;
  document.querySelector(`.status-base .Mp`).textContent = status.Mnd;
  document.querySelector(`.status-total .Mp`).textContent = mp;
  // 行動値
  const initEquip = getEquipTotal('weapon','Init') + getEquipTotal('armor','Init');
  const initVehicle = Number(form.vehicle1Init.value || 0);
  let init = parseInt((status.Per + status.Int) / 2) + initEquip;
  document.querySelector(`.status-base .Init`).textContent = init;
  document.querySelector(`.status-equip .Init`).textContent = initEquip;
  document.querySelector(`.status-vehicle .Init`).textContent = `(${initVehicle})`;
  init += Number(form[`sttInitMod`].value || 0);
  document.querySelector(`.status-total .Init`).innerHTML = `${init}<br>(${init+initVehicle})`;
  // 移動力
  const moveEquip = getEquipTotal('weapon','Move') + getEquipTotal('armor','Move');
  const moveVehicle = Number(form.vehicle1Move.value || 0);
  let move = status.Ref + Number(form[`sttMoveMod`].value || 0) + moveEquip;
  document.querySelector(`.status-base .Move`).textContent = status.Ref;
  document.querySelector(`.status-equip .Move`).textContent = moveEquip;
  document.querySelector(`.status-vehicle .Move`).textContent = `(${moveVehicle})`;
  document.querySelector(`.status-total .Move`).innerHTML = `${move}<br>(${move+moveVehicle})`;
  document.querySelector(`.status-total .MoveTotal`).innerHTML
    = `${parseInt(move / 5) + 1}<br>(${parseInt((move+moveVehicle) / 5) + 1})`;
  // 重量
  let weight = status.Str*2 + Number(form[`sttMaxWeightMod`].value || 0);
  document.querySelector(`.status-base .Weight`).textContent = status.Str;
  document.querySelector(`.status-total .Weight`).textContent = weight;
  document.querySelector(`#exp-footer .max-weight`).textContent = weight;
  // 天運
  let fate = 3 + Number(form[`sttFateMod`].value || 0);
  document.querySelector(`.status-total .Fate`).textContent = fate;
}
// 技能 ----------------------------------------
function changeSkillLv(id){
  document.getElementById(`skill${id}-text`).textContent
    = '●'.repeat(form[`skill${id}Lv`].value)
    + '○'.repeat(5 - form[`skill${id}Lv`].value)
}
// 装備 ----------------------------------------
function getEquipTotal(category, type) {
  let total = 0;
  for(let label of ['Main','Sub','Other']){
    total += Number(form[category+label+type].value || 0);
  }
  return total;
}
function calcTotalWeight(){
  const weapons = Number(document.querySelector(`#weapon-foot .weight`).textContent||0);
  const armors  = Number(document.querySelector(`#armor-foot  .weight`).textContent||0);
  const items   = Number(document.querySelector(`#items tfoot .weight`).textContent||0);
  document.querySelector(`#exp-footer .total-weight`).textContent = weapons + armors + items;
}
// 武器 ----------------------------------------
function changeWeapon(){
  calcWeapons();
  calcTotalWeight();
  calcStatus();
}
function calcWeapons(){
  const acc  = getEquipTotal('weapon','Acc');
  const init = getEquipTotal('weapon','Init');
  const move = getEquipTotal('weapon','Move');
  document.querySelector(`#weapon-foot .weight`).textContent = getEquipTotal('weapon','Weight');
  document.querySelector(`#weapon-foot .guard `).textContent = getEquipTotal('weapon','Guard');
  document.querySelector(`#weapon-foot .acc   `).textContent = acc;
  document.querySelector(`#weapon-foot .init  `).textContent = init;
  document.querySelector(`#weapon-foot .move  `).textContent = move;
  
  document.querySelector(`#vehicle-foot .acc`).textContent = acc + Number(form.vehicle1Acc.value || 0);
  document.querySelector(`#vehicle-foot .init`).textContent = init + Number(form.vehicle1Init.value || 0) + getEquipTotal('armor','Init');
  document.querySelector(`#vehicle-foot .move`).textContent = move + Number(form.vehicle1Move.value || 0) + getEquipTotal('armor','Move');
}
// 防具 ----------------------------------------
function changeArmor(){
  calcArmors();
  calcTotalWeight();
  calcStatus();
}
function calcArmors(){
  const eva  = getEquipTotal('armor','Eva');
  const defW = getEquipTotal('armor','DefWeapon');
  const defF = getEquipTotal('armor','DefFire');
  const defS = getEquipTotal('armor','DefShock');
  const defI = getEquipTotal('armor','DefInternal');
  const init = getEquipTotal('armor','Init');
  const move = getEquipTotal('armor','Move');

  document.querySelector(`#armor-foot .weight`).textContent = getEquipTotal('armor','Weight');
  document.querySelector(`#armor-foot .eva   `).textContent = eva;
  document.querySelector(`#armor-foot .def.weapon  `).textContent = defW;
  document.querySelector(`#armor-foot .def.fire    `).textContent = defF;
  document.querySelector(`#armor-foot .def.shock   `).textContent = defS;
  document.querySelector(`#armor-foot .def.internal`).textContent = defI;
  document.querySelector(`#armor-foot .init  `).textContent = init;
  document.querySelector(`#armor-foot .move  `).textContent = move;
  
  document.querySelector(`#vehicle-foot .eva`).textContent = eva  + Number(form.vehicle1Eva.value || 0);
  document.querySelector(`#vehicle-foot .def.weapon  `).textContent = defW + Number(form.vehicle1DefWeapon.value || 0);
  document.querySelector(`#vehicle-foot .def.fire    `).textContent = defF + Number(form.vehicle1DefFire.value || 0);
  document.querySelector(`#vehicle-foot .def.shock   `).textContent = defS + Number(form.vehicle1DefShock.value || 0);
  document.querySelector(`#vehicle-foot .def.internal`).textContent = defI + Number(form.vehicle1DefInternal.value || 0);
  document.querySelector(`#vehicle-foot .init`).textContent = init + Number(form.vehicle1Init.value || 0) + getEquipTotal('weapon','Init');
  document.querySelector(`#vehicle-foot .move`).textContent = move + Number(form.vehicle1Move.value || 0) + getEquipTotal('weapon','Move');
}
// 乗騎 ----------------------------------------
function changeVehicle(){

}
// アイテム ----------------------------------------
function changeItem(){
  calcItems();
  calcTotalWeight();
  calcStatus();
}
function calcItems(){
  let weightTotal = 0;
  for(let i = 1; i <= form.itemNum.value; i++){
    weightTotal += Number(form[`item${i}Weight`].value||0) * Number(form[`item${i}Quantity`].value||0)
  }
  document.querySelector(`#items table tfoot .weight`).textContent = weightTotal;
}
// 追加
function addItem(){
  document.querySelector("#items table tbody").append(createRow('item','itemNum'));
}
// 削除
function delItem(){
  if(delRow('itemNum', '#items table tbody tr:last-of-type')){
    calcStatus();
  }
}
// ソート
setSortable('item','#items table tbody','tr');
// クラス特技 ----------------------------------------
function calcAbility(type){
  let total = 0;
  for(let i = 1; i <= form[type+'Num'].value; i++){
    total += Number(form[type+i+'Lv'].value || 0);
  }
  document.querySelector(`#exp-footer .total-${toKebabCase(type)}`).textContent = total;
}
function toKebabCase(str) {
  return str.split(/(?=[A-Z])/).join('-').toLowerCase()
}
// クラス特技 ----------------------------------------
// 追加
function addClassAbility(){
  document.querySelector("#class-ability-table").append(createRow('class-ability','classAbilityNum'));
}
// 削除
function delClassAbility(){
  if(delRow('classAbilityNum', '#class-ability-table tbody:last-of-type')){
    calcAbility('classAbility');
  }
}
// ソート
(() => {
  let sortable = Sortable.create(document.getElementById('class-ability-table'), {
    group: "class-ability",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template',
    onSort: function(evt){ sortAfter(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      document.getElementById('class-ability-trash').style.display = 'block';
    },
    onEnd: function(evt){
      if(!trashNum) { document.getElementById('class-ability-trash').style.display = 'none' }
    },
  });

  let trashtable = Sortable.create(document.getElementById('class-ability-trash-table'), {
    group: "class-ability",
    dataIdAttr: 'id',
    animation: 150,
    filter: 'thead,tfoot,template',
  });

  let trashNum = 0;
  function sortAfter(){
    let num = 1;
    for(let id of sortable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      replaceSortedNames(row,num,/^(classAbility)(?:Trash)?[0-9]+(.+)$/);
      num++;
    }
    form.classAbilityNum.value = num-1;
    let del = 0;
    for(let id of trashtable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      del++;
      replaceSortedNames(row,'Trash'+del,/^(classAbility)(?:Trash)?[0-9]+(.+)$/);
    }
    trashNum = del;
    if(!del){ document.getElementById('class-ability-trash').style.display = 'none' }
    calcAbility('classAbility');
  }
})();
// ワークス特技 ----------------------------------------
// 追加
function addWorksAbility(){
  document.querySelector("#works-ability-table").append(createRow('works-ability','worksAbilityNum'));
}
// 削除
function delWorksAbility(){
  if(delRow('worksAbilityNum', '#works-ability-table tbody:last-of-type')){
    calcAbility('worksAbility');
  }
}
// ソート
(() => {
  let sortable = Sortable.create(document.getElementById('works-ability-table'), {
    group: "works-ability",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template',
    onSort: function(evt){ sortAfter(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      document.getElementById('works-ability-trash').style.display = 'block';
    },
    onEnd: function(evt){
      if(!trashNum) { document.getElementById('works-ability-trash').style.display = 'none' }
    },
  });

  let trashtable = Sortable.create(document.getElementById('works-ability-trash-table'), {
    group: "works-ability",
    dataIdAttr: 'id',
    animation: 150,
    filter: 'thead,tfoot,template',
  });

  let trashNum = 0;
  function sortAfter(){
    let num = 1;
    for(let id of sortable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      replaceSortedNames(row,num,/^(worksAbility)(?:Trash)?[0-9]+(.+)$/);
      num++;
    }
    form.worksAbilityNum.value = num-1;
    let del = 0;
    for(let id of trashtable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      del++;
      replaceSortedNames(row,'Trash'+del,/^(worksAbility)(?:Trash)?[0-9]+(.+)$/);
    }
    trashNum = del;
    if(!del){ document.getElementById('works-ability-trash').style.display = 'none' }
    calcAbility('worksAbility');
  }
})();
// 魔法 ----------------------------------------
// 追加
function addMagic(){
  document.querySelector("#magic-table").append(createRow('magic','magicNum'));
}
// 削除
function delMagic(){
  if(delRow('magicNum', '#magic-table tbody:last-of-type')){
    calcAbility('magic');
  }
}
// ソート
(() => {
  let sortable = Sortable.create(document.getElementById('magic-table'), {
    group: "magic",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template',
    onSort: function(evt){ sortAfter(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      document.getElementById('magic-trash').style.display = 'block';
    },
    onEnd: function(evt){
      if(!trashNum) { document.getElementById('magic-trash').style.display = 'none' }
    },
  });

  let trashtable = Sortable.create(document.getElementById('magic-trash-table'), {
    group: "magic",
    dataIdAttr: 'id',
    animation: 150,
    filter: 'thead,tfoot,template',
  });

  let trashNum = 0;
  function sortAfter(){
    let num = 1;
    for(let id of sortable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      replaceSortedNames(row,num,/^(magic)(?:Trash)?[0-9]+(.+)$/);
      num++;
    }
    form.magicNum.value = num-1;
    let del = 0;
    for(let id of trashtable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      del++;
      replaceSortedNames(row,'Trash'+del,/^(magic)(?:Trash)?[0-9]+(.+)$/);
    }
    trashNum = del;
    if(!del){ document.getElementById('magic-trash').style.display = 'none' }
    calcAbility('magic');
  }
})();
// アクションセット ----------------------------------------
// 追加
function addActionSet(copyBaseNum){
  const row = createRow('action-set','actionSetNum');
  const num = form.actionSetNum.value;
  document.querySelector(`#action-sets-list > fieldset:nth-of-type(${copyBaseNum||num-1})`).after(row);

  if(copyBaseNum){
    row.querySelectorAll('[name]').forEach(node => {
      const copyBaseName = node.getAttribute('name').replace(/^(actionSet)\d+(.+)$/, `$1${copyBaseNum}$2`)
      console.log(node, form[copyBaseName].value)
      node.value = form[copyBaseName].value;
    });
    row.classList.add('slide-once');

    let i = 1;
    document.querySelectorAll(`#action-sets-list > fieldset`).forEach(obj => {
      replaceSortedNames(obj,i,/^(actionSet)[0-9]+(.*)$/);
      replaceSortedNames(obj,i,/^(addActionSet\()[0-9]+(\))$/,'onclick');
      i++;
    })
  }
}
// 削除
function delActionSet(){
  delRow('actionSetNum', '#action-sets-list fieldset:last-of-type');
}
// ソート
setSortable('action-set', '#action-sets-list', 'fieldset', (row, num) => {
  replaceSortedNames(row,num,/^(addActionSet\()[0-9]+(\))$/,'onclick');
})
// リアクションセット ----------------------------------------
// 追加
function addReactionSet(copyBaseNum){
  const row = createRow('reaction-set','reactionSetNum');
  const num = form.reactionSetNum.value;
  document.querySelector(`#reaction-sets-list > fieldset:nth-of-type(${copyBaseNum||num-1})`).after(row);

  if(copyBaseNum){
    row.querySelectorAll('[name]').forEach(node => {
      const copyBaseName = node.getAttribute('name').replace(/^(reactionSet)\d+(.+)$/, `$1${copyBaseNum}$2`)
      node.value = form[copyBaseName].value;
    });
    row.classList.add('slide-once');

    let i = 1;
    document.querySelectorAll(`#reaction-sets-list > fieldset`).forEach(obj => {
      replaceSortedNames(obj,i,/^(reactionSet)[0-9]+(.*)$/);
      replaceSortedNames(obj,i,/^(addReactionSet\()[0-9]+(\))$/,'onclick');
      i++;
    })
  }
}
// 削除
function delReactionSet(){
  delRow('reactionSetNum', '#reaction-sets-list fieldset:last-of-type');
}
// ソート
setSortable('reaction-set', '#reaction-sets-list', 'fieldset', (row, num) => {
  replaceSortedNames(row,num,/^(addReactionSet\()[0-9]+(\))$/,'onclick');
})
// 部隊 ----------------------------------------
// 追加
function addForce(){
  document.querySelector("#force table").append(createRow('force','forceNum'));
}
// 削除
function delForce(){
  if(delRow('forceNum', '#force table tbody:last-of-type')){
  }
}
// ソート
setSortable('force', '#force table', 'tbody', (row, num) => {
  let i = 1;
  document.querySelectorAll(`#force [name="forceLead"]`).forEach(obj => {
    obj.value = i;
    i++;
  })
})
// 因縁欄 ----------------------------------------
// ソート
setSortable('bond','#bond table tbody');

// 履歴欄 ----------------------------------------
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
