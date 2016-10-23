db = require '../db'
Client = db.model 'Client'

CURD = require '../utils/curd'

module.exports = 
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