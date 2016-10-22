db = require '../../db'
Organization = db.model 'Organization'
ShelterService = db.model 'ShelterService'

CURD = require '../utils/curd'

module.exports = 

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