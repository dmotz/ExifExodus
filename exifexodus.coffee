###
# ExifExodus
# 0.0.1
# Dan Motzenbecker
# http://oxism.com
###


reportErr = (msg, imgSet) ->
  if imgSet
    if confirm "ExifExodus: #{ msg } Click OK to open your EXIF-free images in new tabs."
      open URL.createObjectURL(blob), '_blank' for blob in imgSet
      null
  else
    alert 'ExifExodus: ' + msg


for cons in ['HTMLCanvasElement', 'FileReader', 'FormData',
             'Uint8Array', 'ArrayBuffer', 'Blob', 'URL', 'Worker']
  unless cons of window
    reportErr "
      Your browser is too old to support ExifExodus. (Missing #{ cons } support).
      Try using a modern browser like Chrome, Firefox, or Safari."

    return false


ns         = 'exifexodus'
jpgType    = 'image/jpeg'
jpgQual    = 1
headerSize = 'data:image/jpeg;base64,'.length
cleaned    = {}
frMethods  = {}
xhrSend    = XMLHttpRequest::send
xhrOpen    = XMLHttpRequest::open
fdAppend   = FormData::append
formSubmit = HTMLFormElement::submit


for method in ['readAsDataURL', 'readAsArrayBuffer', 'readAsBinaryString', 'readAsText']
  do (method) ->
    frMethods[method] = FileReader::[method]
    FileReader::[method] = (file, enc) ->
      unless file.type is jpgType
        return frMethods[method].call @, file

      cleanImage file, (blob) => frMethods[method].call @, blob, enc


XMLHttpRequest::send = (data) ->
  if data instanceof FormData and data[ns]
    jpgs     = []
    formData = new FormData
    for key, val of data[ns]
      if val.file and val.file instanceof File
        jpgs.push val
      else
        fdAppend.call formData, key, val

    if jpgs.length
      toClean = jpgs.length
      for jpg in jpgs then do (jpg) =>
        cleanImage jpg.file, (blob) =>
          fdAppend.call formData, jpg.name, blob, jpg.filename
          unless --toClean
            xhrSend.call @, formData

      undefined

    else
      xhrSend.apply @, arguments

  else
    xhrSend.apply @, arguments


XMLHttpRequest::open = (method, url) ->
  xhrOpen.apply @, arguments unless url?[...5] is 'blob:'


FormData::append = (key, val, filename) ->
  @[ns] or= {}
  @[ns][key] = if val instanceof File
    obj = {}
    obj[ns] = {name: key, file: val, filename}
  else
    val

  fdAppend.apply @, arguments


HTMLFormElement::submit = -> onSubmit.call @


unless 'toBlob' of HTMLCanvasElement::
  createBlob = ->
    self.onmessage = (e) ->
      binary  = e.data
      len     = binary.length
      view    = new Uint8Array new ArrayBuffer len
      view[i] = binary.charCodeAt i for i in [0...len]
      self.postMessage new Blob [view.buffer], type: 'image/jpeg'
      self.close()


  blobWorker = URL.createObjectURL new Blob ["(#{ createBlob.toString() })()"],
    type: 'application/javascript'


cleanImage = (file, cb) ->
  reader = new FileReader
  reader.addEventListener 'load', ->
    img = new Image
    img.addEventListener 'load', ->
      {width, height} = img
      canvas          = document.createElement 'canvas'
      canvas.width    = width
      canvas.height   = height

      canvas.getContext('2d').drawImage img, 0, 0, width, height

      if canvas.toBlob
        canvas.toBlob cb, jpgType, jpgQual
      else
        worker = new Worker blobWorker
        worker.onmessage = (e) -> cb e.data
        worker.postMessage atob canvas.toDataURL(jpgType, jpgQual)[headerSize...]

    img.src = reader.result

  frMethods.readAsDataURL.call reader, file


onSubmit = (e) ->
  isEvent  = e instanceof Event
  form     = if isEvent then e.target else @
  inputs   = form.querySelectorAll 'input'
  jpgs     = []
  cleaned  = []
  formData = new FormData

  for input in inputs when input.value
    if input.type is 'file'
      for file in input.files
        jpgs.push {file, name: input.name} if file.type is jpgType
    else
      fdAppend.call formData, input.name, input.value

  unless jpgs.length
    formSubmit.call @ unless isEvent
    return

  if isEvent
    e.preventDefault()
    e.stopImmediatePropagation()

  unless action = form.getAttribute 'action'
    return reportErr 'Can\'t proceed, the upload form has no action URL.', cleaned

  toClean = jpgs.length

  for jpg in jpgs then do (jpg) ->
    cleanImage jpg.file, (blob) ->
      cleaned.push blob
      fdAppend.call formData, jpg.name, blob, jpg.file.name
      unless --toClean
        xhr = new XMLHttpRequest

        xhr.onreadystatechange = ->
          if xhr.readyState is 4
            unless 200 >= xhr.status < 300
              return reportErr "
                Attempted upload of EXIF-free images but received an error
                response from the server (code #{ xhr.status }).", cleaned

            if xhr.responseType is 'document' or /<[\w\W]*>/.test xhr.responseText
              if target = form.getAttribute 'target'
                unless target in ['_blank', '_self', '_parent', '_top']
                  return document.getElementById(target)?.innerHTML = xhr.response

              document.write xhr.response
            else
              reportErr 'Uploaded image but received ambiguous response from server.', cleaned


        xhr.onerror = ->
          reportErr 'Something went wrong submitting the upload form.', cleaned

        xhrOpen.call xhr, form.getAttribute('method') or 'GET', action
        xhrSend.call xhr, formData


init = -> addEventListener 'submit', onSubmit, true


if document.readyState is 'complete'
  init()
else
  document.addEventListener 'DOMContentLoaded', init

