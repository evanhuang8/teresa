###
Queue scheduler
###

Queue = require 'bull'
moment = require 'moment-timezone'
Q = require 'q'
redis = require 'redis'

module.exports =

  # @property [String] Redis host
  redisHost: undefined
  # @property [Number] Redis port
  redisPort: undefined
  # @property [String] Redis password
  redisPass: undefined
  # @property [Number] Redis database number
  redisDBNumber: undefined
  # @property [Queue] Bull queue instance
  queue: undefined

  # Initialze scheduler
  init: () ->
    @redisHost = process.env.T_KUE_REDIS_HOST or '127.0.0.1'
    @redisPort = +process.env.T_KUE_REDIS_PORT or 6379
    @redisPass = process.env.T_KUE_REDIS_PASS or null
    @redisDBNumber = +process.env.T_KUE_REDIS_NUMBER or 1
    # Create queue
    params =
      host: @redisHost
      port: @redisPort
      DB: @redisDBNumber
    if @redisPass?
      params.opts = 
        auth_pass: @redisPass
    @queue = new Queue 'tsaq', 
      redis: params
    @queue.on 'error', (err) ->
      console.log err.stack
      return
    return

  # Schedule a task to queue
  #
  # @param [Object] opts task options
  # @option opts [String] type task type
  # @option opts [String] params task parameters
  # @option opts [moment] eta task ETA
  # @option opts [String] priority task priority
  # @option opts [Integer] attempts failure attempts
  # @option opts [Boolean, Object, Function] backoff failure attempt backoff
  #
  add: (opts) ->
    # Calculate eta
    if not opts.eta?
      throw new Error 'An eta for the task is required.'
    params = {}
    delay = opts.eta - moment.tz()
    if delay > 0
      params.delay = delay
    if opts.attempts? and opts.attempts > 1
      params.attempts = opts.attempts
    if opts.backoff?
      params.backoff = opts.backoff
    # Add default re-attempts and backoff for call and messages
    if opts.name in ['call', 'message']
      if (not opts.attempts? or opts.attempts < 1) and not opts.backoff?
        params.attempts = 3
        params.backoff = 
          delay: 60 * 1000 # milliseconds
          type: 'fixed'
    # Add to queue
    data = opts.params
    data._category = opts.name
    job = yield @queue.add data, params
    if job?
      job.id = job.jobId
    return job

  # Remove a task from queue
  #
  # @param [String] id task id
  #
  remove: (id) ->
    job = yield @queue.getJob id
    if job?
      yield job.remove()
    return

  # Fetch a task from queue
  #
  # @param [String] id task id
  #
  get: (id) ->
    job = yield @queue.getJob id
    if job?
      job.id = job.jobId
    return job
