###
Task worker
###

co = require 'co'
Queue = require 'bull'
toureiro = require 'toureiro'
db = require '../db'

module.exports = class TaskWorker

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
  # @property [Express] Express server instance
  app: undefined
  # @property [Number] Kue monitor port
  port: undefined

  # @property [Boolean] Should start queue monitor
  watch: undefined
  # @property [Boolean] Should enable logging
  logging: undefined

  # @property [Array] Collection of processors
  processors: undefined

  # @property [Toureiro] Toureiro monitor
  monitor: undefined

  # Constructor
  constructor: (watch = true, logging = true) ->
    @redisHost = process.env.T_KUE_REDIS_HOST or '127.0.0.1'
    @redisPort = +process.env.T_KUE_REDIS_PORT or 6379
    @redisPass = process.env.T_KUE_REDIS_PASS or null
    @redisDBNumber = +process.env.T_KUE_REDIS_NUMBER or 1
    @port = +process.env.T_KUE_PORT or 3000
    @watch = watch
    @logging = logging
    # Processors
    @processors =
      general: require './general'
    return

  # Start worker
  start: () ->
    # Create queue
    params =
      host: @redisHost
      port: @redisPort
      DB: @redisDBNumber
    if @redisPass?
      params.opts =
        auth_pass: @redisPass
    @queue = new Queue 'epxq',
      redis: params
    @queue.on 'error', (err) ->
      logger.error
        category: 'queue'
        class: 'process'
        err: err
      return
    # Synchronize with database
    yield db.client.sync()
    # Setup task processors
    @setupProcessors()
    # Graceful shutdown
    process.on 'SIGTERM', (signal) =>
      try
        if @monitor?
          @monitor.close()
      catch err
        logger.error
          category: 'queue'
          class: 'process'
          err: err
        , 'Monitor cannot be closed!'
      @queue.close().then () ->
        logger.info
          category: 'queue'
          class: 'process'
        , 'Worker is terminated.'
        process.exit 0
        return
      .catch (err) ->
        logger.error
          category: 'queue'
          class: 'process'
          err: err
        , 'Worker cannot be terminated!'
        process.exit 1
        return
      return
    # Setup monitor
    if @watch
      @monitor = toureiro
        redis:
          host: @redisHost
          port: @redisPort
          db: @redisDBNumber
          auth_pass: @redisPass
      @monitor.listen @port, () =>
        logger.info
          category: 'queue'
          class: 'process'
        , 'Queue monitor is now up and running.'
        return
    return

  # Setup job processors
  setupProcessors: () ->
    @queue.process 5, (job, done) =>
      # Validate again job type and category
      processor = @processors[job.data._category]
      if not processor?
        err = new Error 'Invalid job category:', job.data._category
        if @logging
          console.log err.stack
        done err
        return
      if not processor[job.data.type]? or typeof processor[job.data.type] isnt 'function'
        err = new Error "Invalid job not processed: #{job.data.type}"
        if @logging
          console.log err.stack
        done err
        return
      # Setup hooks for detailed logging
      eta = job.timestamp
      if not isNaN(job.timestamp) and not isNaN(job.delay)
        eta = job.timestamp + job.delay
      co () =>
        # Execute job
        job.id = job.jobId
        result = yield processor[job.data.type] job.data, job
        # Mark as done
        done null, result
        return
      .catch (err) =>
        if @logging
          console.log err.stack
        return done err
      return
    return
