// ナイトモード
let nightMode = localStorage.getItem("nightMode");
if(nightMode == 1) { document.getElementById("nightmode").href = './skin/css/night.css?201808161734'; }
function nightModeChange() {
  if(nightMode != 1) { document.getElementById("nightmode").href = './skin/css/night.css?201808161734'; nightMode = 1; }
  else { document.getElementById("nightmode").href = ''; nightMode = 0; }
  localStorage.setItem("nightMode", nightMode);
}