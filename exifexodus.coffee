# ExifExodus
# Dan Motzenbecker
# http://oxism.com


for cons in ['FileReader', 'FormData', 'Uint8Array', 'ArrayBuffer', 'Blob']
  unless cons of window
    reportErr "Your browser is too old to support ExifExodus. (Missing #{ cons } support)"
    return false


ns         = 'exifexodus'
jpgType    = 'image/jpeg'
jpgQual    = 1
headerSize = 'data:image/jpeg;base64,'.length
cleaned    = {}
frMethods  = {}
xhrSend    = XMLHttpRequest::send
fdAppend   = FormData::append


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



FormData::append = (key, val, filename) ->
  @[ns] or= {}
  @[ns][key] = if val instanceof File
    obj = {}
    obj[ns] = {name: key, file: val, filename}
  else
    val

  fdAppend.apply @, arguments


HTMLFormElement::submit = -> onSubmit target: @


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
      canvas.getContext('2d').fillStyle = 'rgb(255,0,255)'
      canvas.getContext('2d').fillRect 0, 0, width, height

      binary  = atob canvas.toDataURL(jpgType, jpgQual)[headerSize...]
      len     = binary.length
      view    = new Uint8Array new ArrayBuffer len
      view[i] = binary.charCodeAt i for i in [0...len]

      cb new Blob [view.buffer], type: jpgType

    img.src = reader.result

  frMethods.readAsDataURL.call reader, file


onSubmit = (e) ->
  form     = e.target
  inputs   = form.querySelectorAll 'input'
  jpgs     = []
  formData = new FormData

  for input in inputs when input.value
    if input.type is 'file'
      for file in input.files
        jpgs.push {file, name: input.name} if file.type is jpgType
    else
      fdAppend.call formData, input.name, input.value


  if jpgs.length and e instanceof Event
    e.preventDefault()
    e.stopImmediatePropagation()

  if !form.action
    return reportErr 'Can\'t proceed, the upload form has no action URL.'

  toClean = jpgs.length

  for jpg in jpgs then do (jpg) ->
    cleanImage jpg.file, (blob) ->
      fdAppend.call formData, jpg.name, blob, jpg.file.name
      unless --toClean
        xhr = new XMLHttpRequest

        xhr.onreadystatechange = ->
          document.write xhr.response if xhr.readyState is 4

        xhr.onerror = ->
          reportErr 'Something went wrong submitting the upload form.'

        xhr.open form.method or 'GET', form.action
        xhrSend.call xhr, formData


reportErr = (msg) -> alert 'ExifExodus: ' + msg


init = -> addEventListener 'submit', onSubmit, true


if document.readyState is 'complete'
  init()
else
  document.addEventListener 'DOMContentLoaded', init

