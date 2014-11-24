
/*
 * ExifExodus
 * 0.0.0
 * Dan Motzenbecker
 * http://oxism.com
 */

(function() {
  var blobWorker, cleanImage, cleaned, cons, createBlob, fdAppend, formSubmit, frMethods, headerSize, init, jpgQual, jpgType, method, ns, onSubmit, reportErr, xhrOpen, xhrSend, _fn, _i, _j, _len, _len1, _ref, _ref1;

  _ref = ['HTMLCanvasElement', 'FileReader', 'FormData', 'Uint8Array', 'ArrayBuffer', 'Blob', 'URL', 'Worker'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    cons = _ref[_i];
    if (!(cons in window)) {
      reportErr("Your browser is too old to support ExifExodus. (Missing " + cons + " support)");
      return false;
    }
  }

  ns = 'exifexodus';

  jpgType = 'image/jpeg';

  jpgQual = 1;

  headerSize = 'data:image/jpeg;base64,'.length;

  cleaned = {};

  frMethods = {};

  xhrSend = XMLHttpRequest.prototype.send;

  xhrOpen = XMLHttpRequest.prototype.open;

  fdAppend = FormData.prototype.append;

  formSubmit = HTMLFormElement.prototype.submit;

  _ref1 = ['readAsDataURL', 'readAsArrayBuffer', 'readAsBinaryString', 'readAsText'];
  _fn = function(method) {
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
  for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
    method = _ref1[_j];
    _fn(method);
  }

  XMLHttpRequest.prototype.send = function(data) {
    var formData, jpg, jpgs, key, toClean, val, _fn1, _k, _len2, _ref2;
    if (data instanceof FormData && data[ns]) {
      jpgs = [];
      formData = new FormData;
      _ref2 = data[ns];
      for (key in _ref2) {
        val = _ref2[key];
        if (val.file && val.file instanceof File) {
          jpgs.push(val);
        } else {
          fdAppend.call(formData, key, val);
        }
      }
      if (jpgs.length) {
        toClean = jpgs.length;
        _fn1 = (function(_this) {
          return function(jpg) {
            return cleanImage(jpg.file, function(blob) {
              fdAppend.call(formData, jpg.name, blob, jpg.filename);
              if (!--toClean) {
                return xhrSend.call(_this, formData);
              }
            });
          };
        })(this);
        for (_k = 0, _len2 = jpgs.length; _k < _len2; _k++) {
          jpg = jpgs[_k];
          _fn1(jpg);
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
        var binary, i, len, view, _k;
        binary = e.data;
        len = binary.length;
        view = new Uint8Array(new ArrayBuffer(len));
        for (i = _k = 0; 0 <= len ? _k < len : _k > len; i = 0 <= len ? ++_k : --_k) {
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
        canvas.getContext('2d').fillStyle = 'rgb(255,0,255)';
        canvas.getContext('2d').fillRect(0, 0, width, height);
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
    var action, file, form, formData, input, inputs, isEvent, jpg, jpgs, toClean, _k, _l, _len2, _len3, _len4, _m, _ref2, _results;
    isEvent = e instanceof Event;
    form = isEvent ? e.target : this;
    inputs = form.querySelectorAll('input');
    jpgs = [];
    cleaned = [];
    formData = new FormData;
    for (_k = 0, _len2 = inputs.length; _k < _len2; _k++) {
      input = inputs[_k];
      if (input.value) {
        if (input.type === 'file') {
          _ref2 = input.files;
          for (_l = 0, _len3 = _ref2.length; _l < _len3; _l++) {
            file = _ref2[_l];
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
    _results = [];
    for (_m = 0, _len4 = jpgs.length; _m < _len4; _m++) {
      jpg = jpgs[_m];
      _results.push((function(jpg) {
        return cleanImage(jpg.file, function(blob) {
          var xhr;
          cleaned.push(blob);
          fdAppend.call(formData, jpg.name, blob, jpg.file.name);
          if (!--toClean) {
            xhr = new XMLHttpRequest;
            xhr.onreadystatechange = function() {
              var target, _ref3, _ref4;
              if (xhr.readyState === 4) {
                if (!((200 >= (_ref3 = xhr.status) && _ref3 < 300))) {
                  return reportErr("Attempted upload of EXIF-free images but received an error response from the server (code " + xhr.status + ").", cleaned);
                }
                if (xhr.responseType === 'document' || /<[\w\W]*>/.test(xhr.responseText)) {
                  if (target = form.getAttribute('target')) {
                    if (target !== '_blank' && target !== '_self' && target !== '_parent' && target !== '_top') {
                      return (_ref4 = document.getElementById(target)) != null ? _ref4.innerHTML = xhr.response : void 0;
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
      })(jpg));
    }
    return _results;
  };

  reportErr = function(msg, imgSet) {
    var blob, _k, _len2;
    if (imgSet) {
      if (confirm("ExifExodus: " + msg + " Click OK to open your EXIF-free images in new tabs.")) {
        for (_k = 0, _len2 = imgSet.length; _k < _len2; _k++) {
          blob = imgSet[_k];
          open(URL.createObjectURL(blob), '_blank');
        }
        return null;
      }
    } else {
      return alert('ExifExodus: ' + msg);
    }
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