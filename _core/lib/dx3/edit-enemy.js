"use strict";
const gameSystem = 'dx3';

let status = {};
let syndromes = [];
// ----------------------------------------
window.onload = function() {
  console.log('=====START=====');
  syndromes = [form.syndrome1.value, form.syndrome2.value, form.syndrome3.value];
  
  setName();
  checkStage();
  checkSyndrome();
  calcStt();
  checkEncroachBonus();
  calcEffect();
  
  changeColor();
  deleteLoadingArea();
  console.log('=====LOADED=====');
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.enemyName.value === ''){
    alert('エネミー名を入力してください。');
    form.enemyName.focus();
    return false;
  }
  if(form.enemyType.value === ''){
    alert('エネミーの種別を入力してください。');
    form.enemyType.focus();
    return false;
  }
  if(!formPasswordCheck()){
    return false;
  }
  return true;
}

// ステージチェック ----------------------------------------
function checkStage(){
  document.body.classList.toggle('mode-crc', form.stage.value.match('クロウリングケイオス'));
}

// シンドローム変更 ----------------------------------------
function changeSyndrome(num,syn){
  syndromes[num-1] = syn;
  checkSyndrome();
  calcStt();
}
function checkSyndrome(){
  const syn1 = syndromes[0];
  const syn2 = syndromes[1];
  const syn3 = syndromes[2];

  document.getElementById('breed-value').textContent = syn3 ? 'トライ' : syn2 ? 'クロス' : syn1 ? 'ピュア' : '';
  
  form.syndrome1.parentNode.classList.toggle('error', !syn1 && (syn2 || syn3));
  form.syndrome2.parentNode.classList.toggle('error', !syn2 && syn3);
  form.syndrome1.closest('tr').classList.toggle('pure', syn1 && !syn2);
}

// ステータス計算 ----------------------------------------
function calcStt() {
  const syn1 = syndromes[0];
  const syn2 = syndromes[1];

  const isAuto1 = synStats[syn1] ? true : syn1 ? false : true;
  const isAuto2 = synStats[syn2] ? true : syn2 ? false : true;
  document.querySelector('.syndrome-rows tr:nth-child(1)').classList.toggle('auto', isAuto1);
  document.querySelector('.syndrome-rows tr:nth-child(2)').classList.toggle('auto', isAuto2);
  
  let free = 0;
  for (let stt of ['body','sense','mind','social']){
    const Stt = stt.slice(0,1).toUpperCase()+stt.slice(1);

    let base1; let base2;
    base1 = isAuto1 ? synStats[syn1]?.[stt] ?? 0 : 0;
    base2 = isAuto2 ? synStats[syn2]?.[stt] ?? 0 : 0;

    let base = 0;
    base += syn1 ? base1 : 0;
    base += syn2 ? base2 : syn1 ? base1 : 0;
    status[stt] = base;

    form['stt'+Stt].placeholder = base;
    if(form['stt'+Stt].value !== ''){
      status[stt] = Number(form['stt'+Stt].value);
    }
  }

  calcSubStt();
  calcSkill();
}
// サブステータス
function calcSubStt() {
  calcMaxHp();
  calcInitiative();
}
let maxHp = 0;
function calcMaxHp(){
  maxHp = status.body * 2 + status.mind + 20;
  form.maxHp.placeholder = maxHp;
}
let initiative = 0;
function calcInitiative(){
  initiative = status.sense * 2 + status.mind;
  form.initiative.placeholder = initiative;
}
// 技能
const basicSkillNameToId = {
  '白兵': 'Melee'    ,
  '射撃': 'Ranged'   ,
  'RC'  : 'RC'       ,  
  '交渉': 'Negotiate',
  '回避': 'Dodge'    ,
  '知覚': 'Percept'  ,
  '意志': 'Will'     ,
  '調達': 'Procure'  ,
}
let skillNameToId = {...basicSkillNameToId};
function calcSkill() {
  skillNameToId = {...basicSkillNameToId};
  for (let name of ['Ride','Art','Know','Info']){
    for (let num = 1; num <= Number(form[`skill${name}Num`].value); num++){
      const skillName = form[`skill${name}${num}Name`].value;
      if(skillName){ skillNameToId[skillName] = name+num; }
    }
  }
  setSkillSelectAll();
  calcComboAll();
}
// エフェクト
function calcEffect() {
  for (let num = 1; num <= Number(form.effectNum.value); num++){
    const type = form['effect'+num+'Type'].value;
    const bg = form['effect'+num+'Name'].parentNode.parentNode.parentNode.style;
    if     (type == 'easy') { bg.backgroundImage = 'linear-gradient(to right,hsla(120,100%, 50%,0.2),transparent)'; }
    else if(type == 'auto') { bg.backgroundImage = 'linear-gradient(to right,hsla(200,100%, 50%,0.2),transparent)'; }
    else if(type == 'dlois'){ bg.backgroundImage = 'linear-gradient(to right,hsla(  0,100%, 50%,0.2),transparent)'; }
    else if(type == 'enemy'){ bg.backgroundImage = 'linear-gradient(to right,hsla(270,100%, 50%,0.2),transparent)'; }
    else if(type == 'elois'){ bg.backgroundImage = 'linear-gradient(to right,hsla(250,100%, 25%,0.3))'; }
    else if(type == 'perk') { bg.backgroundImage = 'linear-gradient(to right,hsla(180, 80%, 25%,0.2),transparent)'; }
    else { bg.backgroundImage = ''; }

    if(type == 'dlois'){
      form['effect'+num+'Lv'].disabled =
      form['effect'+num+'Timing'].disabled =
      form['effect'+num+'Skill'].disabled =
      form['effect'+num+'Dfclty'].disabled =
      form['effect'+num+'Target'].disabled =
      form['effect'+num+'Range'].disabled =
      form['effect'+num+'Encroach'].disabled =
      form['effect'+num+'Restrict'].disabled = true;
    }
    else if(type == 'elois'){
      form['effect'+num+'Lv'].disabled =
      form['effect'+num+'Encroach'].disabled = true;
      form['effect'+num+'Timing'].disabled =
      form['effect'+num+'Skill'].disabled =
      form['effect'+num+'Dfclty'].disabled =
      form['effect'+num+'Target'].disabled =
      form['effect'+num+'Range'].disabled =
      form['effect'+num+'Restrict'].disabled = false;
      form['effect'+num+'Restrict'].placeholder = '衝動';
      form['effect'+num+'Restrict'].setAttribute('list', 'list-impulse');
    }
    else if(type == 'perk'){
      form['effect'+num+'Encroach'].disabled =
      form['effect'+num+'Restrict'].disabled = true;
      form['effect'+num+'Lv'].disabled =
      form['effect'+num+'Timing'].disabled =
      form['effect'+num+'Skill'].disabled =
      form['effect'+num+'Dfclty'].disabled =
      form['effect'+num+'Target'].disabled =
      form['effect'+num+'Range'].disabled = false;
    }
    else {
      form['effect'+num+'Lv'].disabled =
      form['effect'+num+'Timing'].disabled =
      form['effect'+num+'Skill'].disabled =
      form['effect'+num+'Dfclty'].disabled =
      form['effect'+num+'Target'].disabled =
      form['effect'+num+'Range'].disabled =
      form['effect'+num+'Encroach'].disabled =
      form['effect'+num+'Restrict'].disabled = false;
      form['effect'+num+'Restrict'].placeholder = '制限';
      form['effect'+num+'Restrict'].setAttribute('list', 'list-restrict');
    }
  }
}

// 侵蝕値 ----------------------------------------
let EA; let OR;
let array = [];
let lvbs  = {};
let edbs  = {};
function checkEncroachBonus(){
  EA = form.encroachEaOn.checked;
  OR = form.encroachOrOn.checked;

  array = OR && EA ? [200  ,150  ,100  ,80  ,0  ] : OR ? [150  ,100  ,80  ,0  ] : EA ? [300   ,260   ,220   ,190   ,160   ,130   ,100   ,80   ,60   ,0  ] : [300   ,240   ,200   ,160   ,130   ,100   ,80   ,60   ,0  ];
  edbs  = OR && EA ? {200:0,150:0,100:0,80:0,0:0} : OR ? {150:0,100:0,80:0,0:0} : EA ? {300:7 ,260:6 ,220:5 ,190:5 ,160:4 ,130:4 ,100:3 ,80:2 ,60:1 ,0:0} : {300:8 ,240:7 ,200:6 ,160:5 ,130:4 ,100:3 ,80:2 ,60:1 ,0:0};
  lvbs  = OR && EA ? {200:4,150:3,100:2,80:1,0:0} : OR ? {150:3,100:2,80:1,0:0} : EA ? {300:3 ,260:3 ,220:3 ,190:2 ,160:2 ,130:1 ,100:1 ,80:0 ,60:0 ,0:0} : {300:2 ,240:2 ,200:2 ,160:2 ,130:1 ,100:1 ,80:0 ,60:0 ,0:0};

  document.querySelectorAll('#enc-table colgroup, #enc-table tr').forEach((obj) => { obj.innerHTML = '' })
  
  for(let i = 0; i < array.length; i++){
    let col      = document.createElement("col"); col.id               = 'enc-col'+array[i];                                        document.querySelector('#enc-table colgroup').prepend(col);
    let cellHead = document.createElement("th" ); cellHead.textContent = (i == 0) ? `${array[i]}-` : `${array[i]}-${array[i-1]-1}`; document.getElementById('enc-table-head').prepend(cellHead);
    document.getElementById('enc-table-dices').insertCell(0).textContent = OR ? '―' : '+'+edbs[array[i]];
    document.getElementById('enc-table-level').insertCell(0).textContent = '+'+lvbs[array[i]];
  }
  document.querySelector('#enc-table colgroup').prepend(document.createElement("col"));
  let thHead  = document.createElement("th"); thHead.textContent  = ''       ; document.getElementById('enc-table-head' ).prepend(thHead);
  let thBonus = document.createElement("th"); thBonus.textContent = 'ダイス' ; document.getElementById('enc-table-dices').prepend(thBonus);
  let thLevel = document.createElement("th"); thLevel.textContent = 'Efct.Lv'; document.getElementById('enc-table-level').prepend(thLevel);

  setEncroachBonus();
}
function setEncroachBonus(){
  const enc = form.encroach.value || 0;
  for (let v of array){ document.getElementById('enc-col'+v).classList.remove('current'); }
  for (let v of array){
    if(enc >= v){
      document.getElementById('enc-col'+v).classList.add('current');
      document.querySelectorAll("[data-edb]").forEach(function(obj) {
        obj.dataset.edb = edbs[v];
      });
      break;
    }
  }
}

// 技能欄 ----------------------------------------
// 追加
function addSkill(type){
  let num = Number(form[`skill${type}Num`].value) + 1;
  let dt = document.createElement('dt');
  let dd = document.createElement('dd');
  dt.innerHTML = `<input name="skill${type}${num}Name" type="text" oninput="calcSkill()" list="list-${type.toLowerCase()}">`;
  dd.innerHTML = `<input name="skill${type}${num}" type="number" oninput="calcSkill()" min="0">`;
  const status = (
    type === 'Ride' ? 'body'   :
    type === 'Art'  ? 'sense'  :
    type === 'Know' ? 'mind'   :
    type === 'Info' ? 'social' :
    ''
  );
  const target = document.querySelector(`#skill-${status}-table`);
  target.appendChild(dt, target);
  target.appendChild(dd, target);
  
  form[`skill${type}Num`].value = num;
}
// 削除
function delSkill(type){
  let num = Number(form[`skill${type}Num`].value);
  if(num > 1){
    if(form[`skill${type}${num}Name`].value || form[`skill${type}${num}`].value){
      if (!confirm(delConfirmText)) return false;
    }
    const status = (
      type === 'Ride' ? 'body'   :
      type === 'Art'  ? 'sense'  :
      type === 'Know' ? 'mind'   :
      type === 'Info' ? 'social' :
      ''
    );
    const target = document.querySelector(`#skill-${status}-table`);
    target.lastElementChild.remove();
    target.lastElementChild.remove();
    num--;
    form[`skill${type}Num`].value = num;
    calcSkill();
  }
}

// エフェクト欄 ----------------------------------------
// 追加
function addEffect(){
  document.querySelector("#effect-table").append(createRow('effect','effectNum'));
}
// 削除
function delEffect(){
  if(delRow('effectNum', '#effect-table tbody:last-of-type')){
    calcEffect();
  }
}
// ソート
(() => {
  let sortable = Sortable.create(document.getElementById('effect-table'), {
    group: "effect",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template',
    onSort: function(evt){ effectSortAfter(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      document.getElementById('effect-trash').style.display = 'block';
    },
    onEnd: function(evt){
      if(!effectTrashNum) { document.getElementById('effect-trash').style.display = 'none' }
    },
  });

  let trashtable = Sortable.create(document.getElementById('effect-trash-table'), {
    group: "effect",
    dataIdAttr: 'id',
    animation: 150,
    filter: 'thead,tfoot,template',
  });

  let effectTrashNum = 0;
  function effectSortAfter(){
    let num = 1;
    for(let id of sortable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      replaceSortedNames(row,num,/^(effect)(?:Trash)?[0-9]+(.+)$/);
      num++;
    }
    form.effectNum.value = num-1;
    let del = 0;
    for(let id of trashtable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      del++;
      replaceSortedNames(row,'Trash'+del,/^(effect)(?:Trash)?[0-9]+(.+)$/);
    }
    effectTrashNum = del;
    if(!del){ document.getElementById('effect-trash').style.display = 'none' }
    calcEffect();
  }
})();

// コンボ欄 ----------------------------------------
// 技能セット
function setSkillSelectAll(){
  for(let i = 1; i <= Number(form.comboNum.value); i++){
    setComboSkill(i);
  }
  for(let i = 1; i <= Number(form.weaponNum.value); i++){
    setWeaponSkill(i);
  }
  for(let i = 1; i <= Number(form.vehicleNum.value); i++){
    setVehicleSkill(i);
  }
  for(let i = 1; i <= Number(form.itemNum.value); i++){
    setItemSkill(i);
  }
}
function setComboSkill(num){
  setSkillOptions(form[`combo${num}Skill`]);
}
function setWeaponSkill(num){
  setSkillOptions(form[`weapon${num}Skill`]);
}
function setVehicleSkill(num){
  setSkillOptions(form[`vehicle${num}Skill`]);
}
function setItemSkill(num){
  setSkillOptions(form[`item${num}Skill`]);
}
function setSkillOptions(select){
  const nowSelect = select.value;
  const names = ['','―', ...Object.keys(basicSkillNameToId)];
  for (let name of ['Ride','Art','Know','Info']){
    for (let num = 1; num <= Number(form[`skill${name}Num`].value); num++){
      const skillname = form['skill'+name+num+'Name'].value;
      if(skillname){ names.push(skillname); }
    }
  }
  names.push('解説参照');
  select.replaceChildren(...[...new Set(names)].map(name => new Option(name, name)));
  select.value = names.includes(nowSelect) ? nowSelect : '';
}
// 計算
function calcComboAll(){
  for(let i = 1; i <= Number(form.comboNum.value); i++){
    calcCombo(i);
  }
}
function calcCombo(num){
  const name = form[`combo${num}Skill`].value;
  
  const [lv, stt] = (() => {
    if(form[`combo${num}Manual`].checked){ return ['',''] }
    const id = skillNameToId[name];
    const sttname = form[`combo${num}Stt`].value
    let [lv, stt] = ['',''];
    if(id && name){
      lv = Number(form['skill'+id].value);
      if     (id.match(/Melee|Dodge|Ride/))      { stt = status['body']   }
      else if(id.match(/Ranged|Percept|Art/))    { stt = status['sense']  }
      else if(id.match(/RC|Will|Know/))          { stt = status['mind']   }
      else if(id.match(/Negotiate|Procure|Info/)){ stt = status['social'] }
    }
    if(sttname){ 
      if     (sttname === '肉体'){ stt = status['body']   }
      else if(sttname === '感覚'){ stt = status['sense']  }
      else if(sttname === '精神'){ stt = status['mind']   }
      else if(sttname === '社会'){ stt = status['social'] }
      else { stt = 0; }
    }
    return [lv, stt];
  })();
  
  for (const i of [1,2,3,4,5]){
    document.getElementById(`combo${num}Stt${i}`).innerHTML = stt;
    document.getElementById(`combo${num}SkillLv${i}`).innerHTML = lv;
  }
}
// 追加
function addCombo(copyBaseNum){
  const row = createRow('combo','comboNum');
  const num = form.comboNum.value;
  document.querySelector(`#combo-list`).appendChild(row);
  setComboSkill(num);
  if(copyBaseNum){
    row.querySelectorAll('[name]').forEach(node => {
      const copyBaseName = node.getAttribute('name').replace(/^(combo)\d+(.+)$/, `$1${copyBaseNum}$2`)
      if(node.type === 'checkbox'){
        node.checked = form[copyBaseName].checked;
      }
      else { node.value = form[copyBaseName].value; }
    });
    calcCombo(form.comboNum.value);
    row.classList.add('slide-once');

    let i = 1;
    document.querySelectorAll(`#combo-list > div`).forEach(obj => {
      replaceSortedNames(obj,i,/^(combo)[0-9]+(.*)$/);
      replaceSortedNames(obj,i,/^(combo)[0-9]+((?:Stt|SkillLv)[0-9])$/,'id');
      replaceSortedNames(obj,i,/^(calcCombo\()[0-9]+(\))$/,'oninput');
      replaceSortedNames(obj,i,/^(addCombo\()[0-9]+(\))$/,'onclick');
      i++;
    })
  }

  makeComboConditionUtility(row);
}
// 削除
function delCombo(){
  delRow('comboNum', '#combo-list .combo-table:last-child');
}
// ソート
setSortable('combo', '#combo-list', 'div', (row, num) => {
  replaceSortedNames(row,num,/^(combo)[0-9]+((?:Stt|SkillLv)[0-9])$/,'id');
  replaceSortedNames(row,num,/^(calcCombo\()[0-9]+(\))$/,'oninput');
  replaceSortedNames(row,num,/^(addCombo\()[0-9]+(\))$/,'onclick');
})
// 条件
function makeComboConditionUtility(comboNode) {
  const utilityIcon = comboNode.querySelector('.combo-out .combo-cond .combo-condition-utility');
  if (utilityIcon == null) {
    return;
  }

  /** @return {Array.<{label: string, conditionTexts: [string, string, string, string, string]}>} */
  function makeMenuItems() {
    function makeConditionItem(label, text1 = '', text2 = '', text3 = '', text4 = '', text5 = '') {
      return {label: label, conditionTexts: [text1, text2, text3, text4, text5]};
    }

    let menuItems = [
      makeConditionItem("すべての条件を消去"),
      makeConditionItem("100%未満／100%以上", "100%未満", "100%以上"),
    ];

    menuItems = menuItems.concat(
        document.querySelector('#enc-table-dices td').textContent !== '―'
            ? [
              makeConditionItem("-99／100-", "～99%", "100%～"),
              makeConditionItem("-99／100-159／160-", "～99%", "100%～159%", "160%～"),
              makeConditionItem("-99／100-159／160-219／220-", "～99%", "100%～159%", "160%～220%", "220%～"),
              makeConditionItem("80-99／100-", "80%～99%", "100%～"),
              makeConditionItem("80-99／100-159／160-", "80%～99%", "100%～159%", "160%～"),
              makeConditionItem("80-99／100-159／160-219／220-", "80%～99%", "100%～159%", "160%～219%", "220%～"),
              makeConditionItem("100-", "100%～"),
              makeConditionItem("100-159／160-", "100%～159%", "160%～"),
              makeConditionItem("100-159／160-219／220-", "100%～159%", "160%～219%", "220%～"),
              makeConditionItem("120-", "120%～"),
              makeConditionItem("120-159／160-", "120%～159%", "160%～"),
              makeConditionItem("120-159／160-219／220-", "120%～159%", "160%～219%", "220%～"),
            ]
            : [
              makeConditionItem("-79／80-", "～79%", "80%～"),
              makeConditionItem("-79／80-99／100-", "～79%", "80%～99%", "100%～"),
              makeConditionItem("-79／80-99／100-149／150-", "～79%", "80%～99%", "100%～149%", "150%～"),
              makeConditionItem("-79／80-99／100-149／150-199／200-", "～79%", "80%～99%", "100%～149%", "150%～199%", "200%～"),
              makeConditionItem("80-99／100-", "80%～99%", "100%～"),
              makeConditionItem("80-99／100-149／150-", "80%～99%", "100%～149%", "150%～"),
              makeConditionItem("80-99／100-149／150-199／200-", "80%～99%", "100%～149%", "150%～199%", "200%～"),
              makeConditionItem("100-", "100%～"),
              makeConditionItem("100-149／150-", "100%～149%", "150%～"),
              makeConditionItem("100-149／150-199／200-", "100%～149%", "150%～199%", "200%～"),
              makeConditionItem("120-", "120%～"),
              makeConditionItem("120-149／150-", "120%～149%", "150%～"),
              makeConditionItem("120-149／150-199／200-", "120%～149%", "150%～199%", "200%～"),
            ]
    );

    if (!document.querySelector('[name="encroachEaOn"]').checked) {
      menuItems = menuItems.filter(x => !(x.label.includes('220') || x.label.includes('200')));
    }

    return menuItems;
  }

  utilityIcon.addEventListener(
      'click',
      () => {
        const oldMenu = document.querySelector('.combo-condition-utility-menu');
        if (oldMenu != null) {
          oldMenu.parentNode.removeChild(oldMenu);
          return;
        }

        const iconRect = utilityIcon.getBoundingClientRect();

        const menuNode = document.createElement('div');
        menuNode.classList.add('combo-condition-utility-menu');
        menuNode.style.left = `${window.pageXOffset + iconRect.left + iconRect.width / 2}px`;
        menuNode.style.top = `calc(${window.pageYOffset + iconRect.bottom}px - 0.35rem)`;

        makeMenuItems().forEach(
            itemSettings => {
              const menuItemNode = document.createElement('a');
              menuItemNode.classList.add('item');
              menuItemNode.textContent = itemSettings.label;
              menuNode.appendChild(menuItemNode);

              menuItemNode.addEventListener(
                  'click',
                  () =>
                      comboNode.querySelectorAll('.combo-out dd input[type="text"][name*="Condition"]').forEach(
                          (node, index) => node.value = itemSettings.conditionTexts[index] ?? ''
                      )
              );
            }
        );

        const body = document.querySelector('body');

        const menuRemover = event => {
          if (event != null) {
            function getNodePath(node) {
              const path = [];
              let current = node;
              while (current != null) {
                path.unshift(current);
                current = current.parentNode;
              }
              return path;
            }

            if (getNodePath(event.target).some(node => node === utilityIcon)) {
              return;
            }
          }

          if (menuNode.parentNode != null) {
            menuNode.parentNode.removeChild(menuNode);
          }

          body.removeEventListener('click', menuRemover);
        };

        body.addEventListener('click', menuRemover);
        body.appendChild(menuNode);
      }
  );
}
document.querySelectorAll('#combo .combo-table').forEach(node => makeComboConditionUtility(node));

// 攻撃欄 ----------------------------------------
// 追加
function addAttack(){
  document.querySelector("#attack-table tbody").append(createRow('attack','attackNum'));
}
// 削除
function delAttack(){
  delRow('attackNum', '#attack-table tbody tr:last-of-type');
}
// ソート
setSortable('attack','#attack-table tbody','tr');

// 武器欄 ----------------------------------------
// 追加
function addWeapon(){
  document.querySelector("#weapon-table tbody").append(createRow('weapon','weaponNum'));
  setWeaponSkill(form.weaponNum.value);
}
// 削除
function delWeapon(){
  delRow('weaponNum', '#weapon-table tbody tr:last-of-type');
}
// ソート
setSortable('weapon','#weapon-table tbody','tr');


// 防具欄 ----------------------------------------
// 追加
function addArmor(){
  document.querySelector("#armor-table tbody").append(createRow('armor','armorNum'));
}
// 削除
function delArmor(){
  delRow('armorNum', '#armor-table tbody tr:last-of-type')
}
// ソート
setSortable('armor','#armor-table tbody','tr');

// ヴィークル欄 ----------------------------------------
// 追加
function addVehicle(){
  document.querySelector("#vehicle-table tbody").append(createRow('vehicle','vehicleNum'));
  setVehicleSkill(form.vehicleNum.value);
}
// 削除
function delVehicle(){
  delRow('vehicleNum', '#vehicle-table tbody tr:last-of-type')
}
// ソート
setSortable('vehicle','#vehicle-table tbody','tr');

// アイテム欄 ----------------------------------------
// 追加
function addItem(){
  document.querySelector("#item-table tbody").append(createRow('item','itemNum'));
  setItemSkill(form.itemNum.value);
}
// 削除
function delItem(){
  delRow('itemNum', '#item-table tbody tr:last-of-type')
}
// ソート
setSortable('item','#item-table tbody','tr');

