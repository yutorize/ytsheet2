// 開閉系 ----------------------------------------
function popImage() {
  document.getElementById("image-box").style.bottom = 0;
  document.getElementById("image-box").style.opacity = 1;
}
function closeImage() {
  document.getElementById("image-box").style.opacity = 0;
  setTimeout(function(){
    document.getElementById("image-box").style.bottom = '-100vh';
  },200);
}
function editOn() {
  document.querySelectorAll('.float-box:not(#login-form)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("login-form").classList.toggle('show');
}
function backuplistOn() {
  document.querySelectorAll('.float-box:not(#backuplist)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("backuplist").classList.toggle('show');
}
function donwloadListOn() {
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
// 保存系 ----------------------------------------
function getJsonData() {
  return new Promise((resolve, reject)=>{
    let xhr = new XMLHttpRequest();
    xhr.open('GET', `${location.href}&mode=json`, true);
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

function generateCcfoliaZipFile(title, data){
  return new Promise((resolve, dummy)=>{
    let zip = new JSZip();
    zip.file("__data.json", data, {binary: false});
    zip.file(".token", `0.${io.github.shunshun94.trpg.ccfolia.generateRndStr()}`);
    zip.generateAsync({ type: "blob", compression: "DEFLATE", compressionOptions: {level: 9}}).then(blob => {
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

function getAbsoluteUrl(path) {
  const dummyLink = document.createElement('a');
  dummyLink.href = path;
  return dummyLink.href;
}

async function downloadAsUdonarium() {
  const characterDataJson = await getJsonData();
  const characterId = characterDataJson.birthTime;
  const image = await io.github.shunshun94.trpg.ytsheet.getPicture(characterDataJson.imageURL || defaultImage);
  const udonariumXml = io.github.shunshun94.trpg.udonarium[`generateCharacterXmlFromYtSheet2${generateType}`](characterDataJson, location.href, image.hash);
  const udonariumUrl = await generateUdonariumZipFile((characterDataJson.characterName||characterDataJson.aka), udonariumXml, image);
  downloadFile(`udonarium_data_${characterId}.zip`, udonariumUrl);
}

async function downloadAsCcfolia() {
  const characterDataJson = await getJsonData();
  const characterId = characterDataJson.birthTime;
  const json = io.github.shunshun94.trpg.ccfolia[`generateCharacterJsonFromYtSheet2${generateType}`](characterDataJson, location.href, getAbsoluteUrl(defaultImage));
  const ccfoliaUrl = await generateCcfoliaZipFile(characterId, json);
  downloadFile(`ccfolia_data_${characterId}.zip`, ccfoliaUrl);
}

async function donloadAsText() {
  const characterDataJson = await getJsonData();
  const characterId = characterDataJson.birthTime;
  const textData = io.github.shunshun94.trpg.ytsheet[`generateCharacterTextFromYtSheet2${generateType}`](characterDataJson);
  const textUrl = window.URL.createObjectURL(new Blob([ textData ], { "type" : 'text/plain;charset=utf-8;' }));
  downloadFile(`data_${characterId}.txt`, textUrl);
}

async function donloadAsJson() {
  const characterDataJson = await getJsonData();
  const characterId = characterDataJson.birthTime;
  const jsonUrl = window.URL.createObjectURL(new Blob([ JSON.stringify(characterDataJson) ], { "type" : 'text/json;charset=utf-8;' }));
  downloadFile(`data_${characterId}.json`, jsonUrl);
}
