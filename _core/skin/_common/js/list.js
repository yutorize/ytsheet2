document.forms.search.addEventListener('submit', clean_query);

function clean_query(e) {
  e.preventDefault();
  this.removeEventListener('submit', clean_query);
  var query = serialize(this);
  location.href = this.action + '?' + (function(){
    var arr = [];
    [].forEach.call(query.split('&'), function(item) {
      if (item.split('=')[1]) {
        arr.push(item);
      }
    });
    return arr.join('&');
  })();
}

function serialize(form) {
  var s = [];
  if (typeof form !== 'object' && form.nodeName.toUpperCase() !== 'FORM') {
    return s;
  }

  var length = form.elements.length;
  for (var i = 0; i < length; i++) {
    var field = form.elements[i];
    if (field.name && !field.disabled && field.type != 'file' && field.type != 'reset' && field.type != 'submit' && field.type != 'button') {
      if (field.type == 'select-multiple') {
        var l = form.elements[i].options.length;
        for (var j = 0; j < l; j++) {
          if (field.options[j].selected) {
            s[s.length] = encodeURIComponent(field.name) + '=' + encodeURIComponent(field.options[j].value);
          }
        }
      } else if ((field.type != 'checkbox' && field.type != 'radio') || field.checked) {
        s[s.length] = encodeURIComponent(field.name) + '=' + encodeURIComponent(field.value);
      }
    }
  }
  return s.join('&').replace(/%20/g, '+');
}
