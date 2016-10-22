db = require '../db'
Organization = db.model 'Organization'
ShelterService = db.model 'ShelterService'

CURD = require '../utils/curd'

module.exports = 

  create: () ->
    params = @request.body
    organization = yield Organization.findById params.organizationId
    if not organization?
      @status = 400
      return
    service = yield ShelterService.create
      name: params.name
      description: params.description
      businessHours: params.businessHours
      maxCapacity: params.maxCapacity
    return

  edit: () ->

    return