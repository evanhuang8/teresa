db = require '../../db'
Organization = db.model 'Organization'
Service = db.model 'Service'

CURD = require '../../utils/curd'

module.exports =

  add: () ->
    @render 'referral/add'
    yield return
    return

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

  fetch: () ->

    query = "
      SELECT `Services`.* FROM `Services` LEFT JOIN `Organizations`
      ON `Services`.`organizationId` = `Organizations`.`id`
    "
    if keyword? or category?
      query += ' WHERE '
    if keyword?
      query += "
        (`Clients`.`firstName` LIKE #{SqlString.escape('%' + keyword + '%')}
        OR `Clients`.`lastName` LIKE #{SqlString.escape('%' + keyword + '%')})
      "
    if keyword? and category?
      query += ' AND '
    keyword = @request.body.keyword
    clients = yield db.client.query query,
      type: sequelize.QueryTypes.SELECT
    @body =
      status: 'OK'
      clients: clients
    yield return