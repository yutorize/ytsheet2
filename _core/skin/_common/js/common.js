// ナイトモード
const htmlClass = document.getElementsByTagName('html')[0].classList;
let nightMode = localStorage.getItem("nightMode");
if(nightMode == 1) { htmlClass.add('night'); }
function nightModeChange() {
  if(nightMode != 1) { htmlClass.add('night');nightMode = 1; }
  else { htmlClass.remove('night'); nightMode = 0; }
  localStorage.setItem("nightMode", nightMode);
}
// カラーカスタムON/OFF
let colorlessMode = localStorage.getItem("colorlessMode");
if(colorlessMode == 1) { htmlClass.add('colorless'); }
function changeColorlessMode(){
  if(colorlessMode != 1) { htmlClass.add('colorless');    colorlessMode = 1; }
  else                   { htmlClass.remove('colorless'); colorlessMode = 0; }
  localStorage.setItem("colorlessMode", colorlessMode);
}
window.addEventListener("DOMContentLoaded", () => {
  console.log('colorlessMode:'+colorlessMode);
  const obj = document.querySelector('[onchange*=changeColorlessMode]') || '';
  if(obj && colorlessMode == 1){
    obj.checked = true;
  }
})
// ルビコピーON/OFF
let rubyCopyMode = localStorage.getItem("rubyCopyMode") ?? 1;
function changeRubyCopyMode(){
  if(rubyCopyMode != 1) { rubyCopyMode = 1; }
  else                  { rubyCopyMode = 0; }
  localStorage.setItem("rubyCopyMode", rubyCopyMode);
}
window.addEventListener("DOMContentLoaded", () => {
  console.log('rubyCopyMode:'+rubyCopyMode)
  const obj = document.querySelector('[onchange*=changeRubyCopyMode]') || ''
  if(obj && rubyCopyMode == 1){
    obj.checked = true;
  }
})
// 検索フォーム
function formSwitch(){
  const viewMode = document.getElementById("form-search-area").style.display == 'none' ? 0 : 1;
  document.getElementById("form-search-area").style.display = viewMode ? 'none' : '';
}

window.addEventListener(
    'load',
    () => {
        const button = document.getElementById('button-to-import-from-clipboard');

        if (button != null) {
            button.addEventListener(
                'click',
                async () => {
                    button.disabled = true;

                    let errorMessage;

                    try {
                        const text = await navigator.clipboard.readText();

                        if (URL.canParse(text)) {
                            const url = new URL(text);
                            if (url.protocol === 'http:' || url.protocol === 'https:') {
                                /** @var {HTMLFormElement} */
                                const form = document.getElementById('form-to-import-from-url');

                                form.querySelector('[name=url]').value = url.toString();
                                form.submit();
                            } else {
                                errorMessage = "無効な形式のURLです。";
                            }
                        } else {
                            let json;

                            try {
                                const data = JSON.parse(text);
                                json = JSON.stringify(data);
                            } catch {
                                errorMessage = "クリップボードの内容がURLでもJSONでもありません。";
                            }

                            if (errorMessage == null) {
                                /**
                                 * @param {string} name
                                 * @param {string} value
                                 * @return {HTMLInputElement}
                                 */
                                function createParameter(name, value) {
                                    const input = document.createElement('input');
                                    input.setAttribute('name', name);
                                    input.setAttribute('value', value);
                                    input.setAttribute('type', 'hidden');
                                    return input;
                                }

                                const form = document.createElement('form');
                                form.setAttribute('method', 'post');
                                form.setAttribute('action', './');
                                form.appendChild(createParameter('mode', 'convert'));
                                form.appendChild(createParameter('json', json));
                                form.style.display = 'none';

                                document.querySelector('body').appendChild(form);
                                form.submit();
                            }
                        }
                    } catch (error) {
                        if (error.name === 'NotAllowedError') {
                            errorMessage = "Read permission denied.";
                        } else {
                            throw error;
                        }
                    } finally {
                        if (errorMessage != null) {
                            alert(errorMessage);
                        }

                        button.disabled = false;
                    }
                }
            );

            button.disabled = false;
        }
    }
);
