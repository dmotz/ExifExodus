jpgType      = 'image/jpeg'
jpgQual      = 1
headerSize   = 'data:image/jpeg;base64,'.length
outputHidden = true
missing      = do ->
  for cons in ['HTMLCanvasElement', 'FileReader', 'Uint8Array', 'ArrayBuffer',
               'Blob', 'URL', 'Worker']
    return cons unless cons of window


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
  if missing
    alert "Sorry, your browser is too old to support ExifExodus.
           (Missing #{ missing } support)"

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

  reader.readAsDataURL file


wWidth = wHeight = 1

setDimensions = ->
  wWidth  = window.innerWidth
  wHeight = window.innerHeight


document.addEventListener 'DOMContentLoaded', ->
  setDimensions()
  logo = document.getElementById 'logo-text'

  addEventListener 'mousemove', ({x, y}) ->
    logo.style.transform =
      "translate3d(#{ (x - (wWidth / 2)) / -100 }px, #{ (y - (wHeight / 2)) / -100 }px, 0)"


  addEventListener 'resize', setDimensions


  document.getElementById('bookmarklet-btn').addEventListener 'click', (e) ->
    e.preventDefault()
    alert 'Drag this button to your bookmarks bar!'


  photoDrop = document.getElementById 'photo-drop'
  output    = document.getElementById 'output'

  photoDrop.ondragenter = (e) ->
    e.preventDefault()
    @className = 'drag-hover'

  photoDrop.ondragover = (e) ->
    e.preventDefault()

  photoDrop.ondragleave = ->
    @className = ''

  photoDrop.ondrop = (e) ->
    e.preventDefault()
    @className = ''
    for file in e.dataTransfer.files then do (file) ->
      unless file.type is jpgType
        return alert 'Sorry, ExifExodus only works with JPG files.'

      cleanImage file, (blob) ->
        img     = document.createElement 'img'
        img.src = URL.createObjectURL blob
        output.appendChild img

        if outputHidden
          output.className = ''
          outputHidden     = false

