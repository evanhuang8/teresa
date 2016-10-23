db = require '../../db'
Organization = db.model 'Organization'
Service = db.model 'Service'

CURD = require '../../utils/curd'

module.exports = 

  create: () ->
    params = @request.body
    organization = yield Organization.findById params.organizationId
    if not organization?
      @status = 400
      return
    service = yield Service.create
      type: params.type
      name: params.name
      description: params.description
      businessHours: params.businessHours
      maxCapacity: params.maxCapacity
      openCapacity: params.openCapacity
      organizationId: params.organizationId
    @status = 201
    @body = 
      status: 'OK'
      obj: service
    return

  edit: () ->
    fields = [
      'name'
      'description'
      'businessHours'
      'maxCapacity'
      'openCapacity'
    ]
    yield CURD.update.call this, Service, fields
    return