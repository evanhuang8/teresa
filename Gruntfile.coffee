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
  console.log credentials

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    env:
      options:
        GOOGLE_API_KEY: credentials.GOOGLE_API_KEY
        WIT_AI_ID: credentials.WIT_AI_ID
        WIT_AI_TOKEN: credentials.WIT_AI_TOKEN
    coffee:
      compile:
        files: [
          expand: true
          cwd: 'src'
          src: ['**/*.coffee']
          dest: '.app'
          ext: '.js'
        ]
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
    concurrent:
      dev:
        tasks: [
          'shell:server'
          #'watch'
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

  grunt.registerTask 'compile', ['cjsx']
  grunt.registerTask 'dev', ['compile', 'env', 'concurrent:dev']
  grunt.registerTask 'test', ['env', 'mochaTest']

  return