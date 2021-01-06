"use strict";
const form = document.sheet;

const delConfirmText = '項目に値が入っています。本当に削除しますか？';

// チャットパレット ----------------------------------------
function palettePresetChange (){
  const tool = form.paletteTool.value || 'ytc';
  const type = form.paletteUseVar.checked ? 'full' : 'simple';
  let presetText = palettePresetText[tool][type];
  if(!form.paletteUseBuff.checked){
    let property = {};
    presetText.split("\n").forEach(text => {
      if(text.match(/^\/\/(.+?)=(.*?)$/)){ property[RegExp.$1] = RegExp.$2; }
    });
    let hit;
    for (let i=0; i<100; i++) {
      hit = 0;
      Object.keys(property).forEach(key => {
        presetText = presetText.replace(new RegExp('{'+key+'}',"g"), ()=>{
          hit = 1;
          return property[key];
        });
      });
      if(!hit) break;
    };
    if     (gameSystem == 'sw2'){
      presetText = presetText.replace(/^\/\/(.+?)=(.*?)(\n|$)/gm, '');
      presetText = presetText.replace(/\$\+0/g, '');
      presetText = presetText.replace(/\+0/g, '');
      presetText = presetText.replace(/\#0\$/g, '');
    }
    else if(gameSystem == 'dx3'){
      presetText = presetText.replace(/^\/\/(.+?)=(.*?)(\n|$)/gm, '');
      presetText = presetText.replace(/\+0/g, '');
      presetText = presetText.replace(/^### ■バフ・デバフ\n/g, '');
    }
  }
  document.getElementById('palettePreset').value = presetText;
}

// 画像配置 ----------------------------------------
function imagePreView(file){
  const blobUrl = window.URL.createObjectURL(file);
  document.getElementById('image').style.backgroundImage = 'url("'+blobUrl+'")';
  document.querySelectorAll(".image-custom-view").forEach((el) => {
    el.style.backgroundImage = 'url("'+blobUrl+'")';
  });
  console.log(blobUrl)
}
function imagePositionView(){
  document.getElementById('image-custom').style.display = 'grid';
}
function imagePositionClose(){
  document.getElementById('image-custom').style.display = 'none';
}
function imagePercentBarChange(per){
  form.imagePercent.value = per;
  imagePosition();
}
function imagePosition(){
  const bgSize = form.imageFit.options[form.imageFit.selectedIndex].value;
  if(bgSize === 'percentX'){
    document.getElementById("image-percent-config").style.visibility = 'visible';
    document.getElementById("image").style.backgroundSize = form.imagePercent.value + '%';
    document.querySelectorAll(".image-custom-view").forEach((el) => {
      el.style.backgroundSize = form.imagePercent.value + '%';
    });
  }
  else if(bgSize === 'percentY'){
    document.getElementById("image-percent-config").style.visibility = 'visible';
    document.getElementById("image").style.backgroundSize = 'auto ' + form.imagePercent.value + '%';
    document.querySelectorAll(".image-custom-view").forEach((el) => {
      el.style.backgroundSize = 'auto ' + form.imagePercent.value + '%';
    });
  }
  else {
    document.getElementById("image-percent-config").style.visibility = 'hidden';
    document.getElementById("image").style.backgroundSize = bgSize;
    document.querySelectorAll(".image-custom-view").forEach((el) => {
      el.style.backgroundSize = bgSize;
    });
  }
  document.getElementById("image-positionX-view").innerHTML = form.imagePositionX.value + '%';
  document.getElementById("image-positionY-view").innerHTML = form.imagePositionY.value + '%';
  document.getElementById("image").style.backgroundPositionX = form.imagePositionX.value + '%';
  document.getElementById("image").style.backgroundPositionY = form.imagePositionY.value + '%';
  document.querySelectorAll(".image-custom-view").forEach((el) => {
    el.style.backgroundPositionX = form.imagePositionX.value + '%';
    el.style.backgroundPositionY = form.imagePositionY.value + '%';
  });
  
  document.getElementById("image-percent-bar").value = form.imagePercent.value;
}

// カラーカスタム ----------------------------------------
function changeColor(){
  const customOn = form.colorCustom.checked ? 1 : 0;
  let hH = Number(form.colorHeadBgH.value);
  let hS = Number(form.colorHeadBgS.value);
  let hL = Number(form.colorHeadBgL.value);
  let bH = Number(form.colorBaseBgH.value);
  let bS = Number(form.colorBaseBgS.value);
  document.getElementById('colorHeadBgHValue').innerHTML = hH;
  document.getElementById('colorHeadBgSValue').innerHTML = hS;
  document.getElementById('colorHeadBgLValue').innerHTML = hL;
  document.getElementById('colorBaseBgHValue').innerHTML = bH;
  document.getElementById('colorBaseBgSValue').innerHTML = bS;
  
  const boxes = document.querySelectorAll('.box');
  document.documentElement.style.setProperty('--box-head-bg-color-h', customOn ? hH     : '');
  document.documentElement.style.setProperty('--box-head-bg-color-s', customOn ? hS+'%' : '');
  document.documentElement.style.setProperty('--box-head-bg-color-l', customOn ? hL+'%' : '');
  document.documentElement.style.setProperty('--box-base-bg-color-h', customOn ? bH     : '');
  document.documentElement.style.setProperty('--box-base-bg-color-s', customOn ? (bS*0.7)+'%' : '');
  document.documentElement.style.setProperty('--box-base-bg-color-l', customOn ? (100-bS/6)+'%' : '');
  document.documentElement.style.setProperty('--box-base-bg-color-d', customOn ? 15+'%' : '');
}

// セクション選択 ----------------------------------------
function sectionSelect(id){
  document.querySelectorAll('article > form > section[id^="section"]').forEach( obj => {
    obj.style.display = 'none';
  });
  document.getElementById('section-'+id).style.display = 'block';
}

// 表示／非表示 ----------------------------------------
function view(viewId){
  let value = document.getElementById(viewId).style.display;
  document.getElementById(viewId).style.display = (value === 'none') ? '' : 'none';
}

// 連番ID生成 ----------------------------------------
function idNumSet (id){
  let num = 1;
  while(document.getElementById(id+num)){
    num++;
  }
  return id+num;
}

// 安全なeval ----------------------------------------
function safeEval(text){
  if     (text === '') { return 0; }
  else if(text.match(/[^0-9\+\-\*\/\(\) ]/)){ return 0; }
  
  try { return Function('"use strict";return (' + text + ')')(); } 
  catch (e) { return 0; }
}

