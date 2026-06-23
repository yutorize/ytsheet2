const root = document.documentElement;
const rootClass = root.classList;
// ナイトモード
let nightMode = localStorage.getItem("nightMode");
if(nightMode == 1) { rootClass.add('night'); }
function nightModeChange() {
  if(nightMode != 1) { rootClass.add('night');nightMode = 1; }
  else { rootClass.remove('night'); nightMode = 0; }
  localStorage.setItem("nightMode", nightMode);
}
// カラーカスタムON/OFF
let colorlessMode = localStorage.getItem("colorlessMode");
if(colorlessMode == 1) { rootClass.add('colorless'); }
function changeColorlessMode(){
  if(colorlessMode != 1) { rootClass.add('colorless');    colorlessMode = 1; }
  else                   { rootClass.remove('colorless'); colorlessMode = 0; }
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
// スクロール位置検知
window.addEventListener('DOMContentLoaded', () => {
  if (!document.querySelector('header nav')) return;

  const sentinel = document.createElement('div');

  sentinel.setAttribute('aria-hidden', 'true');
  sentinel.style.cssText = `
    position: absolute;
    top: 0;
    left: 0;
    width: 1px;
    height: 1px;
    visibility: hidden;
    pointer-events: none;
  `;

  document.body.prepend(sentinel);

  const observer = new IntersectionObserver(([entry]) => {
    rootClass.toggle('is-scrolled', !entry.isIntersecting);
  }, {
    root: null,
    rootMargin: '40px 0px 0px 0px',
    threshold: 0
  });

  observer.observe(sentinel);

  window.addEventListener('pageshow', () => {
    rootClass.toggle('is-scrolled', window.scrollY > 40);
  });
});
