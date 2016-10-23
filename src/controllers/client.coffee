moment = require 'moment-timezone'
db = require '../db'
Client = db.model 'Client'
Checkup = db.model 'Checkup'
Referral = db.model 'Referral'
Service = db.model 'Service'
Organization = db.model 'Organization'

sequelize = require 'sequelize'
SqlString = require 'sequelize/lib/sql-string'

queue = require '../tasks/queue'

CURD = require '../utils/curd'

module.exports = 

  index: () ->
    id =  @request.query.id
    client = yield Client.findById id
    if client?
      referrals = yield Referral.findAll
        include: [
          model: Service
          as: 'service'
        ,
          model: Organization
          as: 'referee'
        ,
          model: Organization
          as: 'referer'
        ]
        where:
          clientId: client.id
        order: [
          ['createdAt', 'DESC']
        ]
      @render 'client/index', 
        user: @passport.user
        client: client
        referrals: referrals
    else
      @render 'client/list', 
        user: @passport.user
    yield return

  list: () ->
    @render 'client/list', 
      user: @passport.user
    yield return

  add: () ->
    @render 'client/add', 
      user: @passport.user
    yield return

  update: () ->
    id = @request.query.id
    client = yield Client.findById id
    if not client?
      @status = 404
      return
    @render 'client/edit',
      client: client,
      user: @passport.user
    yield return

  create: () ->
    if not @passport.user?
      @status = 403
      return
    user = @passport.user
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
    if params.checkupAt?
      start = moment.tz params.checkupAt, 'US/Central'
      checkup = yield Checkup.create
        start: new Date start.valueOf()
        clientId: client.id
        organizationId: user.organizationId
      task = yield queue.add
        name: 'general'
        params:
          type: 'scheduleCheckup'
          id: checkup.id
        eta: start.clone()
      checkup.task = task.id
      yield checkup.save()
    @body = 
      status: 'OK'
      obj: client
    yield return

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
    page = 0
    if @request.body.page?
      page = parseInt @request.body.page
      if not (page > 0)
        page = 0
    limit = 20
    offset = limit * page
    query = "
      SELECT `Clients`.* FROM `Clients`
    "
    if keyword?
      query += "
        WHERE `Clients`.`firstName` LIKE #{SqlString.escape('%' + keyword + '%')}
        OR `Clients`.`lastName` LIKE #{SqlString.escape('%' + keyword + '%')}
      "
    query += "
      ORDER BY `Clients`.`lastName` ASC
    "
    totalQuery = "SELECT Count(*) AS total FROM (#{query}) AS tq"
    totalResults = yield db.client.query totalQuery,
      type: sequelize.QueryTypes.SELECT
    query += ' '
    query += "
      LIMIT #{limit}
      OFFSET #{offset}
    "
    clients = yield db.client.query query,
      type: sequelize.QueryTypes.SELECT
    @body =
      status: 'OK'
      clients: clients
    yield return

  fetch_single: () ->
    id = @request.body.id
    client = yield Client.findById id
    if not client?
      @body =
        status: 'FAIL'
        message: 'The client does not exist'
      return
    @body =
      status: 'OK'
      client: client
    yield return
