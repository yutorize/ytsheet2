// クリップボードからインポート
window.addEventListener('load', () => {
  const button = document.getElementById('button-to-import-from-clipboard');

  if (button != null) {
    button.addEventListener('click', async () => {
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
    });

    button.disabled = false;
  }
});
