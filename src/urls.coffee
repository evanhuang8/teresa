###
Url routes
###

router = require 'koa-router'

module.exports = () ->

  urls = new router()

  controllers = 

    index: require './controllers/index'
    user: require './controllers/user'
    community: require './controllers/community'
    organization: require './controllers/organization'
    client: require './controllers/client'
    referral: require './controllers/referral'

  # Index
  urls.all '/', controllers.index.index

  # Index endpoint/Controller index
  urls.all '/:endpoint/', (next) ->
    if controllers.index[@params.endpoint]?
      yield controllers.index[@params.endpoint].apply this, [next]
      return
    else if controllers[@params.endpoint]? and controllers[@params.endpoint].index?
      yield controllers[@params.endpoint].index.apply this, [next]
      return
    yield next
    return

  # Controller endpoint
  urls.all '/:controller/:endpoint/', (next) ->
    if controllers[@params.controller]? and controllers[@params.controller][@params.endpoint]?
      yield controllers[@params.controller][@params.endpoint].apply this, [next]
      return
    yield next
    return

  return urls