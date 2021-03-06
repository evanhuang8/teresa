ngrok = require 'ngrok'

module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-bower-concat'
  grunt.loadNpmTasks 'grunt-coffee-react'
  grunt.loadNpmTasks 'grunt-concurrent'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-env'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-newer'
  grunt.loadNpmTasks 'grunt-shell'

  credentials = {}
  try
    credentials = grunt.file.readJSON 'credentials.json'
  catch err
    true

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    env:
      options:
        T_ROOT: 'http://www.cloverhims.com'
        GOOGLE_API_KEY: credentials.GOOGLE_API_KEY
        WIT_AI_ID: credentials.WIT_AI_ID
        WIT_AI_TOKEN: credentials.WIT_AI_TOKEN
      dev:
        T_TWILIO_SID: credentials.T_TWILIO_SID
        T_TWILIO_TOKEN: credentials.T_TWILIO_TOKEN
        T_FROM_NUMBER: '+13142070452'
        T_TEST: 0
      test:
        T_TEST: 1
        T_FROM_NUMBER: '+15555555555'
    coffee:
      compile:
        files: [
          expand: true
          cwd: 'src'
          src: ['**/*.coffee']
          dest: '.app'
          ext: '.js'
        ]
    bower_concat:
      libraries:
        dest: 'static/js/libraries.js'
    cjsx: 
      compile:
        files: [
          expand: true
          cwd: 'views/jsx'
          src: ['**/*.cjsx']
          dest: 'static/js'
          ext: '.js'
        ]
      components: 
        options: 
          bare: true
        files:
          'static/js/components.js': [
            'views/jsx/components/**/*.cpt'
          ]
    concat:
      js:
        src: [
          'static/js/teresa.js'
          'static/js/**/*.js'
          '!static/js/libraries.js'
          '!static/js/app.js'
        ]
        dest: 'static/js/app.js'
    sass:
      vendor:
        options:
          cacheLocation: '/tmp/.sass-cache'
          style: 'compressed'
          compass: true
        files:
          'static/css/vendor.css': 'views/css/vendor.scss'
      site:
        options:
          cacheLocation: '/tmp/.sass-cache'
          style: 'compressed'
          compass: true
        files:
          'static/css/teresa.css': 'views/css/teresa.scss'
    shell:
      options:
        execOptions:
          maxBuffer: 20000 * 1024
      server:
        options:
          stdout: true
          stderr: true
        command: 'nodemon --watch src src/runner.coffee'
      worker:
        options:
          stdout: true
          stderr: true
        command: 'nodemon --watch src src/tasks/runner.coffee'
    watch:
      reload:
        options:
          livereload: true
        files: [
          'views/templates/**/*'
          'views/jsx/**/*'
        ]
        tasks: []
      cjsx: 
        options:
          nospawn: true
        files: [
          'views/jsx/**/*.cjsx'
        ]
        tasks: ['newer:cjsx:compile', 'concat']
      components:
        options:
          nospawn: true
        files: [
          'views/jsx/components/**/*.cpt'
        ]
        tasks: ['cjsx:components', 'concat']
      sass_vendor:
        options:
          nospawn: true
        files: [
          'views/css/vendor.scss'
        ]
        tasks: ['sass:vendor']
      sass_site:
        options:
          nospawn: true
        files: ['views/css/**/*.scss', '!views/css/vendor.scss']
        tasks: ['sass:site']
    concurrent:
      dev:
        tasks: [
          'shell:server'
          'shell:worker'
          'watch'
        ]
        options:
          limit: 10
          logConcurrentOutput: true
    mochaTest:
      test:
        options:
          reporter: 'spec'
          require: [
            'coffee-script/register'
          ]
          bail: grunt.option('bail')?
        src: [
          'tests/*.coffee'
        ]

  grunt.registerTask 'compile', ['bower_concat', 'sass', 'cjsx', 'concat']
  grunt.registerTask 'dev', ['compile', 'env:dev', 'concurrent:dev']
  grunt.registerTask 'test', ['env:test', 'mochaTest']

  grunt.registerTask 'ngrok', () ->
    done = @async()
    params =
      port: 8080
    if credentials.NGROK_SUBDOMAIN?
      params.authtoken = credentials.NGROK_AUTH_TOKEN
      params.subdomain = credentials.NGROK_SUBDOMAIN
    ngrok.connect params, (err, url) ->
      return done err if err
      console.log "Ngrok tunnel established at: #{url}"
      grunt.config.set 'env.options.T_ROOT', url
      grunt.config.set 'env.options.T_STATIC_PREFIX', "#{url}/static/"
      done()
      return
    return
  grunt.registerTask 'dev-ng', ['ngrok', 'dev']

  return