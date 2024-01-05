"use strict";
const form = document.sheet;

const delConfirmText = '項目に値が入っています。本当に削除しますか？';

const saveState = document.getElementById('save-state');
const saveButton = document.querySelector('#header-menu .submit');
// 内容変更チェック ----------------------------------------
let formChangeCount = 0;
form.addEventListener('change', () => {
  formChangeCount++;
  saveInfo('unsaved');
});
window.addEventListener('beforeunload', function(e) {
  if(formChangeCount) {
    e.preventDefault();
    e.returnValue = '他のページに移動しますか？';
  }
});

// 送信 ----------------------------------------
let saving = 0;
function formSubmit() {
  if(saving){ return; }
  if(!formCheck()){ return false; }
  const formData = new FormData(form);
  const action = form.getAttribute("action");
  if(base64Mode){
    for(let item of formData){
      if(item[0] === 'mode'){ continue; }
      if(typeof item[1] === 'string' || typeof item[1] === 'number'){
        formData.set(item[0], btoa(unescape(encodeURIComponent(item[1]))) );
      }
    }
    formData.set('base64mode', 1);
  }
  const options = {
    method: 'POST',
    body: formData,
  }
  saveInfo('saving','保存中...');
  saving = 1;
  const sendCount = formChangeCount;
  formChangeCount = 0;
  fetch(action, options)
    .then(response => {
      if(response.status === 200) {
        return response.json()
      }
      throw Error(response.statusText);
    })
    .then(data => {
      if     (data.result === 'make' ){ window.location.href = './?id='+data.message; }
      else if(data.result === 'ok'   ){ saveInfo('saved'); console.log(data.message); form.protectOld.value = form.protect.value; }
      else{
        throw Error(data.result === 'error' ? data.message : "保存できませんでした。");
      }
    })
    .catch(error => {
      if(!formChangeCount){ formChangeCount = sendCount; }
      saveInfo('error');
      alert(error);
    })
}
function formCheck(){
  if(form.characterName.value === ''){
    alert('キャラクター名を入力してください。');
    form.characterName.focus();
    return false;
  }
  if(form.protect.value === 'password' && form.pass.value === ''){
    alert('パスワードが入力されていません。');
    form.pass.focus();
    return false;
  }
  return true;
}
function saveInfo(type,message){
  if     (type === 'unsaved'){
    message ||= `未保存`;
  }
  else if(type === 'saving'){
    saveButton.classList.add('dimmed');
  }
  else if(type === 'saved'){
    if(formChangeCount){ message ||= `未保存`; type = 'unsaved'; }
    else               { message ||= `保存完了`; }
    saveButton.classList.remove('dimmed');
    saving = 0;
  }
  else if(type === 'error'){
    if(formChangeCount){ message ||= `未保存`; type = 'unsaved'; }
    saveButton.classList.remove('dimmed');
    saving = 0;
  }
  saveState.classList.remove(...saveState.classList);
  if(type){
    saveState.classList.add(type);
    saveState.innerHTML = message || '';
  }
}
// ショートカット
document.addEventListener('keydown', e => {
  if (e.ctrlKey && (e.key === 's' || e.key === 'S')) {
    e.preventDefault();
    const nowFocus = document.activeElement;
    document.activeElement.blur();
    nowFocus.focus();
    formSubmit();
  }
});

// 名前 ----------------------------------------
function nameSet(id){
  id = id ? id : 'characterName';
  let name = vCheck(id+'Ruby') ? `<ruby>${form[id].value}<rp>(</rp><rt>${vCheck(id+'Ruby')}</rt><rp>)</rp></ruby>` : ruby(form[id].value);
  let aka = (form.aka && form.aka.value) ? '<span class="aka">“'+(vCheck('akaRuby') ? `<ruby>${form.aka.value}<rp>(</rp><rt>${vCheck('akaRuby')}</rt><rp>)</rp></ruby>` : `${ruby(form.aka.value)}`)+'”</span>' : '';
  document.querySelector('#header-menu > h2 > span').innerHTML = (aka + name) || '(名称未入力)';

  function vCheck(id){
    if(form[id]){ return form[id].value; }
    else { return '' }
  }
}
// ルビ置換 ----------------------------------------
function ruby(text){
  return text.replace(/[|｜](.+?)《(.+?)》/g, "<ruby>$1<rp>(</rp><rt>$2</rt><rp>)</rp></ruby>");
}

// 最新のデータを取得 ----------------------------------------
let newestData = {};
async function getNewestData(){
  const queries = new URLSearchParams(window.location.search);
  const id = queries.get('id');
  
  const action = form.getAttribute("action")
  const options = {
    method: 'POST',
    body: new URLSearchParams({'id':id, 'mode':'json'}),
  }
  await fetch(action, options)
    .then(response => response.json())
    .then(data => {
      newestData = data;
    })
}
async function setNewestSingleData(name){
  await getNewestData();
  setNewestValue(name)
}
async function setNewestHistoryData(){
  await getNewestData();
  while(newestData['historyNum'] > Number(form.historyNum.value)){
    addHistory();
  }
  const formData = new FormData(form);
  for (let name of formData.keys()) {
    if(name.match(/^history[1-9][0-9]*?/)){
      setNewestValue(name)
    }
  }
}
async function setNewestValue(name){
  form[name].value = newestData[name]
                   ? newestData[name]
                      .replace(/&amp;/g,'&')
                      .replace(/&lt;/g,'<')
                      .replace(/&gt;/g,'>')
                      .replace(/<br>/g,'\n')
                   : '';
}

// チャットパレット ----------------------------------------
function setChatPalette(){
  const formData = new FormData(form)
  formData.set("mode", "palette");
  formData.set("editingMode", "1");
  formData.delete("password");
  formData.delete("imageFile");
  formData.delete("imageCompressed");
  const action = form.getAttribute("action")
  const options = {
    method: 'POST',
    body: formData,
  }
  fetch(action, options)
    .then(response => response.json())
    .then(data => {
      document.getElementById('paletteDefaultProperties').value = data['properties'] || '';
      document.getElementById('palettePreset').value = data['preset'] || '';
    })
}

// 画像配置 ----------------------------------------
// ビューを開く
function imagePositionView(){
  document.getElementById('image-custom').style.display = 'grid';
  imageDragPointSet();
}
function imagePositionClose(){
  document.getElementById('image-custom').style.display = 'none';
}
// プレビュー
function imagePreView(file, imageMaxSize){
  if(file.size > imageMaxSize){
    alert(`ファイルサイズが${ (imageMaxSize >= 1048576) ? (imageMaxSize / 1048576)+'MB' : (imageMaxSize / 1024)+'KB' }を超えているため、自動的に画像形式を変換・縮小されます。元画像が大きいと、変換・縮小処理に時間がかかることがあります。`);
    form.imageFile.value = '';
    imageCompressor(file, imageMaxSize);
  }
  else {
    imageBlobPreview(file)
  }
}
function imageBlobPreview(blob){
  const blobURL = window.URL.createObjectURL(blob);
  document.getElementById('image').style.backgroundImage = 'url("'+blobURL+'")';
  document.querySelectorAll(".image-custom-view").forEach((el) => {
    el.style.backgroundImage = 'url("'+blobURL+'")';
  });
  imgURL = blobURL;
  if(imageType == 'character'){ imageDragPointSet(); }
}
// 圧縮
let compressScale = 1;
function imageCompressor(data, imageMaxSize){
  let image = new Image();
  let blobURL = URL.createObjectURL(data);
  image.src = blobURL;
  image.onload = function () {
    new Compressor(data, {
      quality: 0.9,
      success(result) {
        if(result.size > imageMaxSize){
          compressScale -= 0.1;
          if(compressScale > 0){
            console.log(`画像縮小: ${ compressScale * 100 } %`);
            imageCompressor(result, imageMaxSize);
          }
          else { alert('画像サイズを既定まで下げることができませんでした。'); }
        }
        else {
          imageBlobPreview(result);
          let reader = new FileReader();
          reader.readAsDataURL(result);
          reader.onload = function() {
            form.imageCompressed.value = reader.result;
            form.imageCompressedType.value = result.type;
          }
        }
      },
      maxWidth : image.width * compressScale,
      mimeType: 'image/webp',
      error(err) {  },
    });
  }
}
// パーセンテージゲージ変更
function imagePercentBarChange(per){
  form.imagePercent.value = per;
  imagePosition();
}
// ポジション反映
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
  document.getElementById("image-positionX-view").textContent = form.imagePositionX.value + '%';
  document.getElementById("image-positionY-view").textContent = form.imagePositionY.value + '%';
  document.getElementById("image").style.backgroundPositionX = form.imagePositionX.value + '%';
  document.getElementById("image").style.backgroundPositionY = form.imagePositionY.value + '%';
  document.querySelectorAll(".image-custom-view").forEach((el) => {
    el.style.backgroundPositionX = form.imagePositionX.value + '%';
    el.style.backgroundPositionY = form.imagePositionY.value + '%';
  });
  
  document.getElementById("image-percent-bar").value = form.imagePercent.value;
}
// ドラッグ処理
let dragFlag = 0;
let dragPoint = {};
function imageDragStart(e){
  e.preventDefault();
  dragFlag = 1;
  dragPoint.x = e.x || e.changedTouches[0].pageX;
  dragPoint.y = e.y || e.changedTouches[0].pageY;
}
let baseDistance = 0;
function imageDragMove(e){
  e.preventDefault();
  const touches = e.changedTouches || 0;
  // スマホ拡大縮小
  if (touches.length > 1) {
		const x1 = touches[0].pageX;
		const y1 = touches[0].pageY;
		const x2 = touches[1].pageX;
		const y2 = touches[1].pageY;
    const distance = Math.sqrt( Math.pow( x2-x1, 2 ) + Math.pow( y2-y1, 2 ) );
    const obj = form.imagePercent;
    if(baseDistance){
      const gap = (distance - baseDistance);
      if     (gap > 0){ obj.value = Number(obj.value)+5; }
      else if(gap < 0){ obj.value = Number(obj.value)-5; }
      if(obj.value < 0){ obj.value = 0 }
    }
    else { baseDistance = distance; }
    imageDragPointSet();
    imagePosition();
  }
  // ドラッグ移動
  else {
    if(dragFlag){
      const objX = form.imagePositionX;
      const objY = form.imagePositionY;
      const objP = form.imagePercent;
      const x = e.x || e.changedTouches[0].pageX;
      const y = e.y || e.changedTouches[0].pageY;
      objX.value = Number(objX.value) + (dragPoint.x - x) * pointWidth;
      objY.value = Number(objY.value) + (dragPoint.y - y) * pointHeight;
      dragPoint.x = x;
      dragPoint.y = y;
      imagePosition();
    }
  }
}
function imageDragEnd(){
  dragFlag = 0;
  baseDistance = 0;
}
function imageDragPointSet(){
  let img = new Image();
  img.src = imgURL;
  img.onload = function() {
    const type = form.imageFit.value;
    const ratio = Number(form.imagePercent.value) / 100;
    const imgWidth  = img.width;
    const imgHeight = img.height;
    const boxWidth  = document.getElementById('image-custom-frame-M').offsetWidth  || 350;
    const boxHeight = document.getElementById('image-custom-frame-M').offsetHeight || 567;
    let viewWidth  = boxWidth;
    let viewHeight = boxHeight;
    if     (type === 'percentX'){
      viewWidth  = boxWidth * ratio;
      viewHeight = boxWidth * ratio * (imgHeight / imgWidth);
    }
    else if(type === 'percentY'){
      viewWidth  = boxHeight * ratio * (imgWidth / imgHeight);
      viewHeight = boxHeight * ratio;
    }
    else if(type === 'unset'){
      viewWidth  = imgWidth;
      viewHeight = imgHeight;
    }
    else if(type === 'cover'){
      if(boxWidth/boxHeight > imgWidth/imgHeight){
        viewWidth = boxWidth;
        viewHeight = boxWidth * (imgHeight / imgWidth);
      }
      else {
        viewWidth  = boxHeight * (imgWidth / imgHeight);
        viewHeight = boxHeight;
      }
    }
    else if(type === 'contain'){
      if(boxWidth/boxHeight < imgWidth/imgHeight){
        viewWidth = boxWidth;
        viewHeight = boxWidth * (imgHeight / imgWidth);
      }
      else {
        viewWidth  = boxHeight * (imgWidth / imgHeight);
        viewHeight = boxHeight;
      }
    }
    pointWidth  = 100 / (viewWidth  - boxWidth);
    pointHeight = 100 / (viewHeight - boxHeight);
  }
}
// セリフプレビュー
function wordsPreView(){
  let words = form.words.value;
  words = words.replace(/[|｜](.+?)《(.+?)》/g, '<ruby><rp>｜</rp>$1<rp>《</rp><rt>$2</rt><rp>》</rp></ruby>')
               .replace(/《《(.+?)》》/g, '<span class="text-em">$1</span>')
               .replace(/^([「『（])/gm, '<span class="brackets">$1</span>')
               .replace(/(.+?(?:[，、。？」]|$))/g, '<span>$1</span>')
               .replace(/\n<span>　/g, '\n<span>')
               .replace(/\n/g, '<br>');
  
  const wObj = document.getElementById('words-preview');
  wObj.innerHTML = words;
  
  wObj.style.left   = form.wordsX.value === '左' ? '0' : '';
  wObj.style.right  = form.wordsX.value === '右' || !form.wordsX.value ? '0' : '';
  wObj.style.top    = form.wordsY.value === '上' || !form.wordsY.value ? '0' : '';
  wObj.style.bottom = form.wordsY.value === '下' ? '0' : '';
  
  document.getElementById('image-copyright-preview').textContent = form.imageCopyright.value;
}

// カラーカスタム ----------------------------------------
function changeColor(){
  let hH = Number(form.colorHeadBgH.value);
  let hS = Number(form.colorHeadBgS.value);
  let hL = Number(form.colorHeadBgL.value);
  let bH = Number(form.colorBaseBgH.value);
  let bS = Number(form.colorBaseBgS.value);
  document.getElementById('colorHeadBgHValue').textContent = hH;
  document.getElementById('colorHeadBgSValue').textContent = hS;
  document.getElementById('colorHeadBgLValue').textContent = hL;
  document.getElementById('colorBaseBgHValue').textContent = bH;
  document.getElementById('colorBaseBgSValue').textContent = bS;
  
  document.documentElement.style.setProperty('--box-head-bg-color-h', hH            );
  document.documentElement.style.setProperty('--box-head-bg-color-s', hS+'%'        );
  document.documentElement.style.setProperty('--box-head-bg-color-l', hL+'%'        );
  document.documentElement.style.setProperty('--box-base-bg-color-h', bH            );
  document.documentElement.style.setProperty('--box-base-bg-color-s', (bS*0.7)+'%'  );
  document.documentElement.style.setProperty('--box-base-bg-color-l', (100-bS/6)+'%');
  document.documentElement.style.setProperty('--box-base-bg-color-d', 15+'%'        );

  const colorSample = document.querySelector('#section-color');
  colorSample.style.setProperty('--box-head-bg-color-h', hH            );
  colorSample.style.setProperty('--box-head-bg-color-s', hS+'%'        );
  colorSample.style.setProperty('--box-head-bg-color-l', hL+'%'        );
  colorSample.style.setProperty('--box-base-bg-color-h', bH            );
  colorSample.style.setProperty('--box-base-bg-color-s', (bS*0.7)+'%'  );
  colorSample.style.setProperty('--box-base-bg-color-l', (100-bS/6)+'%');
  colorSample.style.setProperty('--box-base-bg-color-d', 15+'%'        );
}
function setDefaultColor(){
  form.colorHeadBgH.value = 225;
  form.colorHeadBgS.value =   9;
  form.colorHeadBgL.value =  65;
  form.colorBaseBgH.value = 235;
  form.colorBaseBgS.value =   0;
  changeColor();
}

// JSON出力 ----------------------------------------
function exportAsJson() {
  const formData = new FormData(form);
  const o = Object.fromEntries(formData.entries());
  delete o['_token'];
  delete o['id'];
  delete o['pass'];
  const json = JSON.stringify(o);

  const jsonUrl = window.URL.createObjectURL(new Blob([json], {type: 'text/json;charset=utf-8;'}));

  function downloadFile(title, url) {
    const a = document.createElement('a');
    document.body.appendChild(a);
    a.download = title;
    a.href = url;
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  downloadFile('data.json', jsonUrl);
}

// セクション選択 ----------------------------------------
function sectionSelect(id){
  document.querySelectorAll('article > form > section[id^="section"]').forEach( obj => {
    obj.style.display = 'none';
  });
  document.getElementById('section-'+id).style.display = 'block';
  if(id === 'palette'){ setChatPalette() }
}

// セレクトorインプット ----------------------------------------
function selectInputCheck(name,obj,keyword = 'free'){
  obj.parentNode.classList.toggle('free', obj.value === keyword);
  if(obj.value === keyword){
    if(document.querySelector(`input[name="${name}Free"]`)) document.querySelector(`input[name="${name}Free"]`).setAttribute('name', name);
    if(document.querySelector(`select[name="${name}"]`   )) document.querySelector(`select[name="${name}"]`   ).setAttribute('name', name+'Select');
  }
  else {
    if(document.querySelector(`select[name="${name}Select"]`)) document.querySelector(`select[name="${name}Select"]`).setAttribute('name', name);
    if(document.querySelector(`input[name="${name}"]`       )) document.querySelector(`input[name="${name}"]`       ).setAttribute('name', name+'Free');
  }
}

// 表示／非表示 ----------------------------------------
function view(viewId){
  let value = document.getElementById(viewId).style.display;
  document.getElementById(viewId).style.display = (value === 'none') ? '' : 'none';
}

// ラジオボタン解除 ----------------------------------------
document.querySelectorAll('input[type="radio"]:not([name="protect"])').forEach(radioButton => {
  let label = document.querySelector(`label[for="${radioButton.id}"]`)

  radioButton.addEventListener("mouseup", ()=>{
    if(radioButton.checked){
      clearRadioButton(radioButton)
    }
  });

  if(label){
    label.addEventListener("mouseup", ()=>{
      if(radioButton.checked){
        clearRadioButton(radioButton)
      }
    });
  }
});
function clearRadioButton(radioButton) {
  setTimeout(()=>{
    radioButton.checked = false;
    radioButton.dispatchEvent(new Event('input'));
  },100)
}

// 連番ID生成 ----------------------------------------
function idNumSet (id,after){
  let num = 1;
  after ||= '';
  while(document.getElementById(id+num+after)){
    num++;
  }
  return id+num+after;
}


// 数値3桁区切り ----------------------------------------
function commify(num) {
  return String(num).replace(/([0-9]{1,3})(?=(?:[0-9]{3})+(?![0-9]))/g, "$1,");;
}

// 安全なeval ----------------------------------------
function safeEval(text){
  if     (text === '') { return 0; }
  else if(text.match(/[^0-9,\+\-\*\/\(\) ]/)){ return NaN; }
  
  text = text.replace(/,([0-9]{3}(?![0-9]))/g, "$1");

  try { return Number( Function('"use strict";return (' + text + ')')() ); } 
  catch (e) { return NaN; }
}


