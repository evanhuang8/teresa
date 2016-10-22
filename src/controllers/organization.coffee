db = require '../db'
Community = db.model 'Community'
Organization = db.model 'Organization'

CURD = require '../utils/curd'

module.exports = 

  index: () ->
    yield
    return

  create: () ->
    params = @request.body
    community = yield Community.findById params.communityId
    if not community?
      @status = 400
      return
    organization = yield Organization.create
      name: params.name
      description: params.description
      address: params.address
      lat: params.lat
      lng: params.lng
      tz: params.tz
      communityId: community.id
    @status = 201
    @body = 
      status: 'OK'
      obj: organization
    yield
    return

  edit: () ->
    fields = ['name', 'description', 'address', 'lat', 'lng', 'tz']
    yield CURD.update.call this, Organization, fields
    return

  data: () ->
    yield CURD.pagination.call this, Organization
    return