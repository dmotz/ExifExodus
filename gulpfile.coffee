gulp    = require 'gulp'
gutil   = require 'gulp-util'
rename  = require 'gulp-rename'
srcMap  = require 'gulp-sourcemaps'
coffee  = require 'gulp-coffee'
stylus  = require 'gulp-stylus'
uglify  = require 'gulp-uglify'
lr      = require 'gulp-livereload'
nib     = require 'nib'
http    = require 'http'
connect = require 'connect'
staticS = require 'serve-static'
port    = 3333


gulp.task 'scripts', ->
  gulp.src 'exifexodus.coffee'
    .pipe srcMap.init()
    .pipe coffee().on 'error', gutil.log
    .pipe srcMap.write '.'
    .pipe gulp.dest '.'

  gulp.src 'exifexodus.coffee'
    .pipe coffee().on 'error', gutil.log
    .pipe uglify()
    .pipe rename 'exifexodus.min.js'
    .pipe gulp.dest 'assets/js/'

  gulp.src 'assets/src/site.coffee'
    .pipe srcMap.init()
    .pipe coffee().on 'error', gutil.log
    .pipe uglify()
    .pipe srcMap.write '.'
    .pipe gulp.dest 'assets/js/'


gulp.task 'styles', ->
  gulp.src 'assets/src/exifexodus.styl'
    .pipe stylus(use: nib(), compress: true).on 'error', gutil.log
    .pipe gulp.dest 'assets/css/'


gulp.task 'server', ->
  http.createServer(connect().use staticS '.').listen port
  console.log "\nserver on port #{ port }\n"


gulp.task 'watch', ['server'], ->
  lr.listen()
  gulp.watch 'exifexodus.coffee', ['scripts']
  gulp.watch 'assets/src/site.coffee', ['scripts']
  gulp.watch 'assets/src/exifexodus.styl', ['styles']
  for path in ['index.html', 'assets/js/*', 'assets/css/*']
    gulp.watch(path).on 'change', lr.changed


gulp.task 'default', ['scripts', 'styles']

