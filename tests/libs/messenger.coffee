chai = require 'chai'
chai.config.includeStack = true
should = chai.should()

_ = require 'lodash'
moment = require 'moment-timezone'
Q = require 'q'
supertest = require 'co-supertest'
request = supertest.agent
xml2js = require 'xml2js'
parseXML = Q.denodeify xml2js.parseString

db = require '../../src/db'

generator = () -> yield true

###
Example steps

steps = [
  input: 'yes' # what to send
  expect: 'What is your weight today?' # what to expect
  assert: # perform assertion
    session:
      values: # assert value
        better: true
      exists: ['respondedAt'] # assert existence
      tasks: ['call'] # assert existence of task
      voidedTasks: ['message'] # assert non-existence of task 
    schedule:
      values: # assert value
        daysWithoutSymptom: 1
      exists: ['respondedAt'] # assert existence
  test: () -> # custom tests
,
  input: '137'
  expect: 'Thanks, you have a good day!'
  assert:
    session:
      values:
        weight: 137
  alerts: [ # Check alert
    body: 'Patient has excessive weight of 137'
  ]
]
###

IGNORE_KEYS = [
  'updatedAt'
  'createdAt'
]

module.exports = class MessageTests

  # @property [koa] the server instance
  app: undefined
  # @property [String] default from number
  from: undefined
  # @property [String] default to number
  to: undefined
  # @proeprty [String] the message endpoint
  url: undefined
  # @property [String] the message provider, twilio if not provided
  provider: undefined
  # @property [String] the special provider phone number
  providerNumber: undefined

  # @property [Function] function to run before each step
  beforeEach: undefined
  # @property [Function] function to run after each step
  afterEach: undefined

  # @property [Object] data mapping for all assertions
  data: undefined

  # @property [Array<Object>] test steps
  steps: undefined

  # @property [Object] previous response object
  res: undefined

  # @property [Boolean] debug the flag for printing outputs
  debug: undefined

  constructor: (opts) ->
    @app = opts.app
    @from = opts.from
    @url = opts.url
    @provider = opts.provider
    @providerNumber = opts.providerNumber
    @beforeEach = opts.beforeEach
    @afterEach = opts.afterEach
    @data = {}
    for key in ['session', 'schedule']
      if opts[key]?
        @data[key] = @prepareData opts[key]
    if opts.assert?
      for key, object of opts.assert
        @data[key] = @prepareData object
    @steps = opts.steps
    @debug = opts.debug
    return

  prepareData: (object) ->
    mapping = 
      model: object.Model
      object: object
      data: {}
      tasks: {}
      voidedTasks: {}
    for key, val of object.dataValues
      if key not in IGNORE_KEYS
        mapping.data[key] = object[key]
    return mapping

  assert: (_key, assert) ->
    mapping = @data[_key]
    object = mapping.object
    data = mapping.data
    tasks = mapping.tasks
    voidedTasks = mapping.voidedTasks
    if assert.changed?
      for key in assert.changed
        try
          should.exist object[key]
          data[key].should.not.equal object[key]
        catch err
          err.message = "#{_key}.#{key} #{err.message}"
          throw err
        data[key] = object[key]
    if assert.exists?
      for key in assert.exists
        try
          should.exist object[key]
        catch err
          err.message = "#{_key}.#{key} #{err.message}"
          throw err
        data[key] = object[key]
    if assert.values?
      for key, val of assert.values
        data[key] = val
    for key, val of data
      if val?
        try
          if val instanceof Date
            val = moment(val).startOf('second').valueOf()
            _val = moment(object[key]).startOf('second').valueOf()
            try
              _val.should.equal val
            catch err
              # Tolerate tiny errors due to db conversions
              if Math.abs(val - _val) > 1000
                throw err
          else if 'object' is typeof val
            object[key].should.deep.equal val
          else
            object[key].should.equal val
        catch err
          err.message = "#{_key}.#{key} #{err.message}"
          throw err
      else
        try
          should.not.exist object[key]
        catch err
          err.message = "#{_key}.#{key} #{err.message}"
          throw err
    return

  run: ->
    for step, i in @steps
      # Construct request
      url = @url
      if step.url?
        url = step.url
      params = 
        From: step.from or @from
        Body: step.input
      if step.params
        params = _.merge params, step.params
      code = 200
      if step.code?
        code = step.code
      try
        res = yield request @app
          .post url
          .send params
          .expect code
          .end()
        @res = yield parseXML res.text
        if @debug
          console.log JSON.stringify @res
      catch err
        _err = new Error "Fatal error while running tests - step #{i}: #{err.message}"
        _err.step = step
        _err.stack = err.stack
        throw _err
      # Run before each function
      if @beforeEach?
        if @beforeEach.constructor is generator.constructor
          yield @beforeEach.call this
        else
          @beforeEach.call this
      # Fetch the data
      for key, mapping of @data
        mapping.object = yield mapping.model.findById mapping.object.id
      console.log 'sdfdsdsf'
      # Perform assertion
      should.exist @res.Response
      if step.expect?
        try
          if @debug
            if Array.isArray @res.Response.Message
              for segment in @res.Response.Message
                console.log segment
            else
              console.log @res.Response.Message
          should.exist @res.Response.Message
          if Array.isArray step.expect
            if step.expect.length isnt @res.Response.Message.length
              throw new Error "Expected: #{step.expect}\nActual: #{@res.Response.Message}"
            for j in [0...@res.Response.Message.length]
              if Array.isArray step.expect[j]
                (@res.Response.Message[j] in step.expect[j]).should.be.true
              else
                step.expect[j].should.equal @res.Response.Message[j]
          else
            step.expect.should.equal @res.Response.Message[0]
        catch err
          err.message = "Step #{i}: #{err.message}"
          throw err
      if step.assert?
        for key, assert of step.assert
          try
            yield @assert key, step.assert[key]
          catch err
            err.message = "Step #{i}: #{err.message}"
            throw err
      # Run custom tests
      if step.test?
        if step.test.constructor is generator.constructor
          yield step.test.call this
        else
          step.test.call this
      # Run after each function
      if @afterEach?
        if @afterEach.constructor is generator.constructor
          yield @afterEach.call this
        else
          @afterEach.call this
      # Override url if needed
      if step.overrideUrl
        @url = step.url
    return