// 保存系 ----------------------------------------
function getSheetDownloadUrl(mode, targetEnvironment = '') {
  const url = new URL(location.href);
  url.hash = '';
  // CGI が受け付ける区切りを URLSearchParams に合わせる。
  url.search = url.search.replaceAll(';', '&');
  url.searchParams.set('mode', mode);
  url.searchParams.delete('callback');
  if(targetEnvironment){ url.searchParams.set('target', targetEnvironment); }
  else { url.searchParams.delete('target'); }
  return url.href;
}

function getJsonData(targetEnvironment = '') {
  return new Promise((resolve, reject)=>{
    let xhr = new XMLHttpRequest();
    xhr.open('GET', getSheetDownloadUrl('json', targetEnvironment), true);
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
  const characterId = characterDataJson.name || '無題';
  const imageSuffix = characterDataJson.mainImage > 1 ? characterDataJson.mainImage : '';
  const image = await output.getPicture(characterDataJson['imageURL'+imageSuffix] || defaultImage, "image."+characterDataJson['image'+imageSuffix]);
  const udonariumXml = output.generateUdonariumXml(generateType, characterDataJson, location.href, image.hash);
  const udonariumUrl = await generateUdonariumZipFile(characterId, udonariumXml, image);
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
  downloadFile(name+'.html', getSheetDownloadUrl('download'));
}
async function downloadAsFullSet(){
  const name = document.title.replace(/ - .+?$/,'') || '無題';
  let zip = new JSZip();
  zip.file(name+'.html', await JSZipUtils.getBinaryContent(getSheetDownloadUrl('download')));
  zip.file(name+'.json', await JSZipUtils.getBinaryContent(getSheetDownloadUrl('json')));
  if(document.getElementById('chatPaletteBox')) zip.file(name+'_チャットパレット.txt', await JSZipUtils.getBinaryContent(getSheetDownloadUrl('palette')));
  
  // ユドナリウム
  if(document.getElementById('downloadlist-udonarium')){
    const characterDataJson = await getJsonData('udonarium');
    const imageSuffix = characterDataJson.mainImage > 1 ? characterDataJson.mainImage : '';
    const image = await output.getPicture(characterDataJson['imageURL'+imageSuffix] || defaultImage, "image."+characterDataJson['image'+imageSuffix]);
    const udonariumXml = output[`generateUdonariumXml`](generateType,characterDataJson, location.href, image.hash);
    const udonariumUrl = await generateUdonariumZipFile(characterDataJson.name, udonariumXml, image);
    zip.file(name+'_udonarium.zip', await JSZipUtils.getBinaryContent(udonariumUrl));
  }
  // ココフォリア
  if(document.getElementById('downloadlist-ccfolia')){
    zip.file(name+'_ccfolia.txt', await getCcfoliaJson());
  }

  // ダウンロード
  zip.generateAsync({type:"blob"})
    .then(content => downloadFile(name+'.zip', URL.createObjectURL(content)));
}
