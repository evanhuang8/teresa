db = require '../db'
Community = db.model 'Community'

CURD = require '../utils/curd'

module.exports = 

  index: () ->
    @render 'community/index'
    yield return
    return

  create: () ->
    params = @request.body
    community = yield Community.create
      name: params.name
      description: params.description
    @status = 201
    @body = 
      status: 'OK'
      obj: community
    yield
    return

  edit: () ->
    yield CURD.update.call this, Community, ['name', 'description']
    return

  data: () ->
    yield CURD.pagination.call this, Community
    return