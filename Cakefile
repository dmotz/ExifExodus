{exec, spawn} = require 'child_process'

print = (fn) ->
  (err, stdout, stderr) ->
    throw err if err
    console.log stdout, stderr
    fn?()


startWatcher = (bin, args) ->
  watcher = spawn bin, args?.split ' '
  watcher.stdout.pipe process.stdout
  watcher.stderr.pipe process.stderr


task 'watch', 'compile continuously', ->
  startWatcher.apply @, pair for pair in [
    ['coffee', '-mwc exifexodus.coffee']
    ['stylus', '-u nib -w assets/css/exifexodus.styl']
  ]

