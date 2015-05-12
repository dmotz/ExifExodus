
/*
 * ExifExodus
 * 0.0.2
 * Dan Motzenbecker
 * http://oxism.com
 */

(function() {
  var blobWorker, cleanImage, cons, createBlob, fdAppend, fn, formSubmit, frMethods, headerSize, init, j, jpgQual, jpgType, k, len1, len2, method, ns, onSubmit, ref, ref1, reportErr, xhrOpen, xhrSend,
    hasProp = {}.hasOwnProperty;

  reportErr = function(msg, imgSet) {
    var blob, j, len1;
    if (imgSet) {
      if (confirm("ExifExodus: " + msg + " Click OK to open your EXIF-free images in new tabs.")) {
        for (j = 0, len1 = imgSet.length; j < len1; j++) {
          blob = imgSet[j];
          open(URL.createObjectURL(blob), '_blank');
        }
        return null;
      }
    } else {
      return alert('ExifExodus: ' + msg);
    }
  };

  ref = ['HTMLCanvasElement', 'FileReader', 'FormData', 'Uint8Array', 'ArrayBuffer', 'Blob', 'URL', 'Worker'];
  for (j = 0, len1 = ref.length; j < len1; j++) {
    cons = ref[j];
    if (!(cons in window)) {
      reportErr("Your browser is too old to support ExifExodus. (Missing " + cons + " support). Try using a modern browser like Chrome, Firefox, or Safari.");
      return false;
    }
  }

  ns = 'exifexodus';

  jpgType = 'image/jpeg';

  jpgQual = 1;

  headerSize = 'data:image/jpeg;base64,'.length;

  frMethods = {};

  xhrSend = XMLHttpRequest.prototype.send;

  xhrOpen = XMLHttpRequest.prototype.open;

  fdAppend = FormData.prototype.append;

  formSubmit = HTMLFormElement.prototype.submit;

  ref1 = ['readAsDataURL', 'readAsArrayBuffer', 'readAsBinaryString', 'readAsText'];
  fn = function(method) {
    frMethods[method] = FileReader.prototype[method];
    return FileReader.prototype[method] = function(file, enc) {
      if (file.type !== jpgType) {
        return frMethods[method].call(this, file);
      }
      return cleanImage(file, (function(_this) {
        return function(blob) {
          return frMethods[method].call(_this, blob, enc);
        };
      })(this));
    };
  };
  for (k = 0, len2 = ref1.length; k < len2; k++) {
    method = ref1[k];
    fn(method);
  }

  XMLHttpRequest.prototype.send = function(data) {
    var fn1, formData, jpg, jpgs, key, l, len3, ref2, toClean, val;
    if (data instanceof FormData && data[ns]) {
      jpgs = [];
      formData = new FormData;
      ref2 = data[ns];
      for (key in ref2) {
        if (!hasProp.call(ref2, key)) continue;
        val = ref2[key];
        if (val.file && val.file instanceof File) {
          jpgs.push(val);
        } else {
          fdAppend.call(formData, key, val);
        }
      }
      if (jpgs.length) {
        toClean = jpgs.length;
        fn1 = (function(_this) {
          return function(jpg) {
            return cleanImage(jpg.file, function(blob) {
              fdAppend.call(formData, jpg.name, blob, jpg.filename);
              if (!--toClean) {
                return xhrSend.call(_this, formData);
              }
            });
          };
        })(this);
        for (l = 0, len3 = jpgs.length; l < len3; l++) {
          jpg = jpgs[l];
          fn1(jpg);
        }
        return void 0;
      } else {
        return xhrSend.apply(this, arguments);
      }
    } else {
      return xhrSend.apply(this, arguments);
    }
  };

  XMLHttpRequest.prototype.open = function(method, url) {
    if ((url != null ? url.slice(0, 5) : void 0) !== 'blob:') {
      return xhrOpen.apply(this, arguments);
    }
  };

  FormData.prototype.append = function(key, val, filename) {
    var obj;
    this[ns] || (this[ns] = {});
    this[ns][key] = val instanceof File ? (obj = {}, obj[ns] = {
      name: key,
      file: val,
      filename: filename
    }) : val;
    return fdAppend.apply(this, arguments);
  };

  HTMLFormElement.prototype.submit = function() {
    return onSubmit.call(this);
  };

  if (!('toBlob' in HTMLCanvasElement.prototype)) {
    createBlob = function() {
      return self.onmessage = function(e) {
        var binary, i, l, len, ref2, view;
        binary = e.data;
        len = binary.length;
        view = new Uint8Array(new ArrayBuffer(len));
        for (i = l = 0, ref2 = len; 0 <= ref2 ? l < ref2 : l > ref2; i = 0 <= ref2 ? ++l : --l) {
          view[i] = binary.charCodeAt(i);
        }
        self.postMessage(new Blob([view.buffer], {
          type: 'image/jpeg'
        }));
        return self.close();
      };
    };
    blobWorker = URL.createObjectURL(new Blob(["(" + (createBlob.toString()) + ")()"], {
      type: 'application/javascript'
    }));
  }

  cleanImage = function(file, cb) {
    var reader;
    reader = new FileReader;
    reader.addEventListener('load', function() {
      var img;
      img = new Image;
      img.addEventListener('load', function() {
        var canvas, height, width, worker;
        width = img.width, height = img.height;
        canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        canvas.getContext('2d').drawImage(img, 0, 0, width, height);
        if (canvas.toBlob) {
          return canvas.toBlob(cb, jpgType, jpgQual);
        } else {
          worker = new Worker(blobWorker);
          worker.onmessage = function(e) {
            return cb(e.data);
          };
          return worker.postMessage(atob(canvas.toDataURL(jpgType, jpgQual).slice(headerSize)));
        }
      });
      return img.src = reader.result;
    });
    return frMethods.readAsDataURL.call(reader, file);
  };

  onSubmit = function(e) {
    var action, cleaned, file, fn1, form, formData, input, inputs, isEvent, jpg, jpgs, l, len3, len4, len5, m, n, ref2, toClean;
    isEvent = e instanceof Event;
    form = isEvent ? e.target : this;
    inputs = form.querySelectorAll('input');
    jpgs = [];
    cleaned = [];
    formData = new FormData;
    for (l = 0, len3 = inputs.length; l < len3; l++) {
      input = inputs[l];
      if (input.value) {
        if (input.type === 'file') {
          ref2 = input.files;
          for (m = 0, len4 = ref2.length; m < len4; m++) {
            file = ref2[m];
            if (file.type === jpgType) {
              jpgs.push({
                file: file,
                name: input.name
              });
            }
          }
        } else {
          fdAppend.call(formData, input.name, input.value);
        }
      }
    }
    if (!jpgs.length) {
      if (!isEvent) {
        formSubmit.call(this);
      }
      return;
    }
    if (isEvent) {
      e.preventDefault();
      e.stopImmediatePropagation();
    }
    if (!(action = form.getAttribute('action'))) {
      return reportErr('Can\'t proceed, the upload form has no action URL.', cleaned);
    }
    toClean = jpgs.length;
    fn1 = function(jpg) {
      return cleanImage(jpg.file, function(blob) {
        var xhr;
        cleaned.push(blob);
        fdAppend.call(formData, jpg.name, blob, jpg.file.name);
        if (!--toClean) {
          xhr = new XMLHttpRequest;
          xhr.onreadystatechange = function() {
            var ref3, ref4, target;
            if (xhr.readyState === 4) {
              if (!((200 >= (ref3 = xhr.status) && ref3 < 300))) {
                return reportErr("Attempted upload of EXIF-free images but received an error response from the server (code " + xhr.status + ").", cleaned);
              }
              if (xhr.responseType === 'document' || /<[\w\W]*>/.test(xhr.responseText)) {
                if (target = form.getAttribute('target')) {
                  if (target !== '_blank' && target !== '_self' && target !== '_parent' && target !== '_top') {
                    return (ref4 = document.getElementById(target)) != null ? ref4.innerHTML = xhr.response : void 0;
                  }
                }
                return document.write(xhr.response);
              } else {
                return reportErr('Uploaded image but received ambiguous response from server.', cleaned);
              }
            }
          };
          xhr.onerror = function() {
            return reportErr('Something went wrong submitting the upload form.', cleaned);
          };
          xhrOpen.call(xhr, form.getAttribute('method') || 'GET', action);
          return xhrSend.call(xhr, formData);
        }
      });
    };
    for (n = 0, len5 = jpgs.length; n < len5; n++) {
      jpg = jpgs[n];
      fn1(jpg);
    }
    return null;
  };

  init = function() {
    return addEventListener('submit', onSubmit, true);
  };

  if (document.readyState === 'complete') {
    init();
  } else {
    document.addEventListener('DOMContentLoaded', init);
  }

}).call(this);

//# sourceMappingURL=exifexodus.js.map