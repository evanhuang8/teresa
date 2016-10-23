db = require '../db'
Client = db.model 'Client'

sequelize = require 'sequelize'
SqlString = require 'sequelize/lib/sql-string'

CURD = require '../utils/curd'

module.exports = 

  index: () ->
    @render 'client/index'
    yield return

  list: () ->
    @render 'client/list'
    yield return

  all: () ->
    @render 'client/all'
    yield return
    return

  add: () ->
    @render 'client/add'
    yield return
    return

  create: () ->
    params = @request.body
    fields = [
      'firstName'
      'middleName'
      'lastName'
      'phone'
      'dob'
      'ssn'
      'stage'
    ]
    client = Client.build()
    for field in fields
      client[field] = params[field]
    yield client.save()
    @status = 201
    @body = 
      status: 'OK'
      obj: client
    yield
    return

  edit: () ->
    fields = [
      'firstName'
      'middleName'
      'lastName'
      'phone'
      'dob'
      'ssn'
      'stage'
    ]
    yield CURD.update.call this, Client, fields
    return

  fetch: () ->
    keyword = @request.body.keyword
    query = "
      SELECT `Clients`.* FROM `Clients`
    "
    if keyword?
      query += "
        WHERE `Clients`.`firstName` LIKE #{SqlString.escape('%' + keyword + '%')}
        OR `Clients`.`lastName` LIKE #{SqlString.escape('%' + keyword + '%')}
      "
    clients = yield db.client.query query,
      type: sequelize.QueryTypes.SELECT
    @body =
      status: 'OK'
      clients: clients
    yield return
