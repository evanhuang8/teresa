db = require '../../db'
Organization = db.model 'Organization'
Service = db.model 'Service'
Client = db.model 'Client'

sequelize = require 'sequelize'
SqlString = require 'sequelize/lib/sql-string'

CURD = require '../../utils/curd'

module.exports =

  all: () ->
    if not @passport.user?
      @status = 403
      return
    services = yield Service.findAll
      where:
        organizationId: @passport.user.organizationId
    @render 'service/all',
      user: @passport.user
      services: services
    yield return

  add: () ->
    id = @request.query.id
    client = yield Client.findById id
    @render 'service/add',
      client: client,
      user: @passport.user
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
    keyword = @request.body.keyword
    type = @request.body.type
    query = "
      SELECT `Services`.* FROM `Services`
    "
    if keyword? or type?
      query += ' WHERE '
    if keyword?
      query += "
        (`Services`.`name` LIKE #{SqlString.escape('%' + keyword + '%')}
        OR `Services`.`description` LIKE #{SqlString.escape('%' + keyword + '%')})
      "
    if keyword? and type?
      query += ' AND '
    if type?
      query += "
        `Services`.`type` LIKE #{SqlString.escape('%' + type + '%')}
      "
    services = yield db.client.query query,
      type: sequelize.QueryTypes.SELECT
    @body =
      status: 'OK'
      services: services
    yield return