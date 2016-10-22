module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-bower-concat'
  grunt.loadNpmTasks 'grunt-coffee-react'
  grunt.loadNpmTasks 'grunt-concurrent'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
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
        GOOGLE_API_KEY: credentials.GOOGLE_API_KEY
        WIT_AI_ID: credentials.WIT_AI_ID
        WIT_AI_TOKEN: credentials.WIT_AI_TOKEN
      dev:
        T_TEST: 0
      test:
        T_TEST: 1
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
    shell:
      options:
        execOptions:
          maxBuffer: 20000 * 1024
      server:
        options:
          stdout: true
          stderr: true
        command: 'nodemon --watch src src/runner.coffee'
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
        tasks: ['newer:cjsx:compile']
      components:
        options:
          nospawn: true
        files: [
          'views/jsx/components/**/*.cpt'
        ]
        tasks: ['cjsx:components']
    concurrent:
      dev:
        tasks: [
          'shell:server'
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
          'tests/**/*.coffee'
        ]

  grunt.registerTask 'compile', ['bower_concat', 'cjsx']
  grunt.registerTask 'dev', ['compile', 'env:dev', 'concurrent:dev']
  grunt.registerTask 'test', ['env:test', 'mochaTest']

  return