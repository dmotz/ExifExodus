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


for method in ['readAsDataURL', 'readAsArrayBuffer', 'readAsBinaryString', 'readAsText']
  do (method) ->
    frMethods[method] = FileReader::[method]
    FileReader::[method] = (file, enc) ->
      unless file[ns]
        return frMethods[method].call @, file

      fn = => frMethods[method].call @, cleaned[file[ns]].blob, enc

      if file[ns + 'ready']
        fn()
      else
        cleaned[file[ns]].queue.push fn


onChange = (e) ->
  input      = e.target
  formMarked = false

  return true if input.type isnt 'file'

  for file in input.files then do (file) ->
    return if file.type isnt jpgType
    nonce  = (Math.random() * 1e16).toString 36
    reader = new FileReader

    unless formMarked
      formMarked = true
      parent     = input.parentNode
      loop
        break unless parent
        if parent.tagName.toLowerCase() is 'form'
          parent.dataset[ns] = true
          break

        parent = parent.parentNode

    reader.addEventListener 'load', (e) ->
      img = new Image
      img.addEventListener 'load', ->
        {width, height}   = img
        canvas            = document.createElement 'canvas'
        canvas.width      = width
        canvas.height     = height
        input.dataset[ns] = nonce

        canvas.getContext('2d').drawImage img, 0, 0, width, height

        binary  = atob canvas.toDataURL(jpgType, jpgQual)[headerSize...]
        len     = binary.length
        view    = new Uint8Array new ArrayBuffer len
        view[i] = binary.charCodeAt i for i in [0...len]

        cleaned[nonce].blob = new Blob [view.buffer], type: jpgType
        file[ns + 'ready']  = true
        fn() for fn in cleaned[nonce].queue

      img.src = reader.result

    cleaned[nonce]     = queue: [], name: file.name
    file[ns]           = nonce
    file[ns + 'ready'] = false
    frMethods.readAsDataURL.call reader, file


onSubmit = (e) ->
  form = e.target
  return true unless form.dataset[ns]
  e.preventDefault()
  e.stopPropagation()

  if !form.action
    return reportErr 'Can\'t proceed, the upload form has no action URL.'

  formData = new FormData
  inputs   = form.querySelectorAll 'input'

  for input in inputs when input.value
    if input.dataset[ns]
      val      = cleaned[input.dataset[ns]].blob
      filename = cleaned[input.dataset[ns]].name
    else
      val = input.value

    formData.append input.name, val, filename

  xhr = new XMLHttpRequest
  xhr.onreadystatechange = (e) ->
    if xhr.readyState is 4
      if xhr.responseURL
        window.location = xhr.responseURL
      else
        document.write xhr.response

  xhr.onerror = ->
    reportErr 'Something went wrong submitting the upload form.'

  xhr.open form.method or 'GET', form.action
  xhr.send formData


reportErr = (msg) -> alert 'ExifExodus: ' + msg


init = ->
  addEventListener 'change', onChange, true
  addEventListener 'submit', onSubmit, true


if document.readyState is 'complete'
  init()
else
  document.addEventListener 'DOMContentLoaded', init

