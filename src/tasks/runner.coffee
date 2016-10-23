co = require 'co'
TaskWorker = require './worker'
queue = require './queue'
queue.init()

co ->
  worker = new TaskWorker()
  yield worker.start()
  console.log 'Queue worker is now up and running...'
.catch (err) ->
  console.log err.stack