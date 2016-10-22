co = require 'co'
Teresa = require './teresa'
co ->
  teresa = new Teresa()
  yield teresa.init()
  console.log "Server running at :#{teresa.port}..."
  return
.catch (err) ->
  console.log err.stack