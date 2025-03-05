// 開閉系 ----------------------------------------
function popImage(id) {
  if(typeof images !== 'undefined'){
    id ||= 1;
    document.getElementById('image-box-image').src = images[id];
  }
  document.getElementById("image-box").style.bottom = 0;
  document.getElementById("image-box").style.opacity = 1;

}
function closeImage() {
  document.getElementById("image-box").style.opacity = 0;
  setTimeout(function(){
    document.getElementById("image-box").style.bottom = '-100vh';
  },200);
}
function closeTextareaForCopy() {
  document.getElementById('copyText-box').remove();
  document.getElementById('copyText-box-textarea').remove();
}
function popTextareaForCopy(text) {
  const div = document.createElement('div');
  div.id = 'copyText-box';
  div.onclick = closeTextareaForCopy;

  const textarea = document.createElement('textarea');
  textarea.id = 'copyText-box-textarea';
  textarea.value = text;

  document.getElementsByTagName('main')[0].appendChild(div);
  document.getElementsByTagName('main')[0].appendChild(textarea);

  textarea.focus();
  textarea.setSelectionRange(0, textarea.value.length);
}
function editOn() {
  document.querySelectorAll('.float-box:not(#login-form)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("login-form").classList.toggle('show');
}
function loglistOn() {
  document.querySelectorAll('.float-box:not(#loglist)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("loglist").classList.toggle('show');
}
function downloadListOn() {
  document.querySelectorAll('.float-box:not(#downloadlist)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("downloadlist").classList.toggle('show');
}
let cpOpenFirst = 0;
function chatPaletteOn() {
  document.querySelectorAll('.float-box:not(.chat-palette)').forEach(obj => { obj.classList.remove('show') });
  document.querySelector(".chat-palette").classList.toggle('show');
  if(!cpOpenFirst){ chatPaletteSelect(paletteTool); }
  cpOpenFirst++;
}
function chatPaletteSelect(tool) {
  const url = './?mode=palette&id='+sheetId+'&tool='+tool;
  fetch(url)
  .then(response => { return response.text(); })
  .then(text => { document.getElementById('chatPaletteBox').value = text; });
  document.querySelectorAll('.chat-palette-menu a').forEach(elm => {
    elm.classList.remove('check');
  });
  document.getElementById('cp-switch-'+(tool||'ytc')).classList.add('check');
}

// スクロール位置 ----------------------------------------
window.addEventListener('DOMContentLoaded', ()=>{
  document.querySelector('.header-back-name').addEventListener('click', ()=>{
    window.scroll({
      top: 0,
      behavior: "smooth",
    });
  })
});

// ルビ ----------------------------------------
window.addEventListener('load', ()=>{
  if (rubyCopyMode == 0){
    document.querySelectorAll('ruby:has(rp:nth-of-type(3):last-child)').forEach(ruby => {
      console.log(ruby)
      ruby.querySelector('ruby rp:nth-of-type(1)').textContent = '';
      ruby.querySelector('ruby rp:nth-of-type(2)').textContent = '(';
      ruby.querySelector('ruby rp:nth-of-type(3)').textContent = ')';
    });
  }
});

// 保存系 ----------------------------------------
function getJsonData(targetEnvironment = '') {
  const paramId = /id=[0-9a-zA-Z\-]+/.exec(location.href)[0];
  return new Promise((resolve, reject)=>{
    let xhr = new XMLHttpRequest();
    xhr.open('GET', `./?${paramId}&mode=json&target=${targetEnvironment}`, true);
    xhr.responseType = "json";
    xhr.onload = (e) => {
      resolve(e.currentTarget.response);
    };
    xhr.onerror = () => reject('error');
    xhr.onabort = () => reject('abort');
    xhr.ontimeout = () => reject('timeout');
    xhr.send();
  });
}

function generateUdonariumZipFile(title, data, image){
  return new Promise((resolve, dummy)=>{
    let zip = new JSZip();
    let folder = zip.folder(title);
    if(image.hash) {
      folder.file(image.fileName, image.data);
    }
    folder.file(`${title}.xml`, data, {binary: false});
    zip.generateAsync({ type: "blob" }).then(blob => {
      const dataUrl = URL.createObjectURL(blob);
      resolve(dataUrl);
    });
  });
}

function downloadFile(title, url) {
  const a = document.createElement("a");
  document.body.appendChild(a);
  a.download = title;
  a.href = url;
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

function copyToClipboard(text) {
  // navigator.clipboard.writeText(text); は許可されていなければ動作せず、
  // 非 SSL で繋いでいる場合は許可することすらできないので利用できない。
  const textarea = document.createElement('textarea');
  document.getElementById('downloadlist').appendChild(textarea);
  textarea.value = text;
  textarea.focus();
  textarea.setSelectionRange(0, textarea.value.length);
  const isCopied = document.execCommand('copy');
  textarea.remove();
  if (isCopied) {
    return;
  } else{
    throw 'クリップボードへのコピーに失敗しました';
  }
}

async function downloadAsUdonarium() {
  const characterDataJson = await getJsonData('udonarium');
  const characterId = characterDataJson.characterName || characterDataJson.monsterName || characterDataJson.aka || '無題';
  const image = await output.getPicture(characterDataJson.imageURL || defaultImage, "image."+characterDataJson.image);
  const udonariumXml = output.generateUdonariumXml(generateType, characterDataJson, location.href, image.hash);
  const udonariumUrl = await generateUdonariumZipFile((characterDataJson.characterName||characterDataJson.aka), udonariumXml, image);
  downloadFile(`udonarium_data_${characterId}.zip`, udonariumUrl);
}

function getCcfoliaJson() {
  return new Promise((resolve, reject)=>{
    getJsonData('ccfolia').then((characterDataJson)=>{
      output.generateCcfoliaJson(generateType,characterDataJson, location.href).then(resolve, reject);
    }, reject);
  });
}

function getClipboardItem() {
  try {
    return new ClipboardItem({
      'text/plain': getCcfoliaJson().then((json)=>{
        return new Promise(async (resolve)=>{
          resolve(new Blob([json]));
        });
      }, (err)=>{
        console.error(err);
        alert('キャラクターシートのデータ取得に失敗しました。通信状況等をご確認ください');
      })
    });
  } catch(e) { // FireFox は ClipboardItem が使えない（2022/07/16 v.102.0.1）
    return {
      getType: ()=>{
        return new Promise((resolve, reject)=>{
          getCcfoliaJson().then((json)=>{
            resolve(new Blob([json]));
          });
        }, (err)=>{
          console.error(err);
          alert('キャラクターシートのデータ取得に失敗しました。通信状況等をご確認ください');
        });
      }
    };
  }
}

function clipboardItemToTextareaClipboard(clipboardItem) {
  clipboardItem.getType('text/plain').then((blob)=>{
    blob.text().then((jsonText)=>{
      try {
        copyToClipboard(jsonText);
        alert('クリップボードにコピーしました。ココフォリアにペーストすることでデータを取り込めます');
      } catch (e) {
        popTextareaForCopy(jsonText);
      }
    });
  });
}

async function downloadAsCcfolia() {
  const clipboardItem = getClipboardItem();
  if(navigator.clipboard && navigator.clipboard.write) { // FireFox は navigator.clipboard.write が使えない（2022/07/16 v.102.0.1）
    navigator.clipboard.write([clipboardItem]).then((ok)=>{
      alert('クリップボードにコピーしました。ココフォリアにペーストすることでデータを取り込めます');
    }, (err)=>{
      clipboardItemToTextareaClipboard(clipboardItem);
    });
  } else {
    clipboardItemToTextareaClipboard(clipboardItem);
  }  
}

async function downloadAsText() {
  const characterDataJson = await getJsonData();
  const name = document.title.replace(/ - .+?$/,'') || '無題';
  const textData = output[`generateCharacterTextOf${generateType}`](characterDataJson);
  const textUrl = window.URL.createObjectURL(new Blob([ textData ], { "type" : 'text/plain;charset=utf-8;' }));
  downloadFile(`${name}.txt`, textUrl);
}

async function downloadAsJson() {
  const characterDataJson = await getJsonData();
  const name = document.title.replace(/ - .+?$/,'') || '無題';
  const jsonUrl = window.URL.createObjectURL(new Blob([ JSON.stringify(characterDataJson) ], { "type" : 'text/json;charset=utf-8;' }));
  downloadFile(`${name}.json`, jsonUrl);
}
async function downloadAsHtml(){
  const name = document.title.replace(/ - .+?$/,'') || '無題';
  const url = location.href.replace(/#(.+)$/,'').replace(/&mode=(.+?)(&|$)/,'')+'&mode=download';
  downloadFile(name+'.html', url);
}
async function downloadAsFullSet(){
  const name = document.title.replace(/ - .+?$/,'') || '無題';
  const url = location.href.replace(/#(.+)$/,'').replace(/&mode=(.+?)(&|$)/,'');
  let zip = new JSZip();
  zip.file(name+'.html', await JSZipUtils.getBinaryContent(url+'&mode=download'));
  zip.file(name+'.json', await JSZipUtils.getBinaryContent(url+'&mode=json'));
  if(document.getElementById('chatPaletteBox')) zip.file(name+'_チャットパレット.txt', await JSZipUtils.getBinaryContent(url+'&mode=palette'));
  
  // ユドナリウム
  if(document.getElementById('downloadlist-udonarium')){
    const characterDataJson = await getJsonData('udonarium');
    const image = await output.getPicture(characterDataJson.imageURL || defaultImage, "image."+characterDataJson.image);
    const udonariumXml = output[`generateUdonariumXml`](generateType,characterDataJson, location.href, image.hash);
    const udonariumUrl = await generateUdonariumZipFile((characterDataJson.characterName||characterDataJson.aka), udonariumXml, image);
    zip.file(name+'_udonarium.zip', await JSZipUtils.getBinaryContent(udonariumUrl));
  }
  // ココフォリア
  if(document.getElementById('downloadlist-ccfolia')){
    zip.file(name+'_ccfolia.txt', await getCcfoliaJson());
  }

  // ダウンロード
  zip.generateAsync({type:"blob"})
    .then(function(content) {
      const url = URL.createObjectURL(content);
      const a = document.createElement("a");
      document.body.appendChild(a);
      a.download = name+'.zip';
      a.href = url;
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    });
}
