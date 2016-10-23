co = require 'co'
moment = require 'moment-timezone'
sequelize = require 'sequelize'
uid = require 'uid2'

db = require '../../db'
client = db.client
Service = db.model 'Service'
Intent = db.model 'Intent'

LocationUtils = require '../../utils/location'

module.exports = 

  nearestServices: (opts) ->
    type = opts.type
    lat = opts.lat
    lng = opts.lng
    query = "
      SELECT 
      `Services`.*, `lat`, `lng`, `tz`, 
      6371 * 2 * ASIN(SQRT(POWER(SIN((`lat` - ABS(#{lat})) * pi() / 180 / 2), 2) + COS(`lat` * pi() / 180 ) * COS(ABS(#{lat}) * pi() / 180) * POWER(SIN((`lng` - (#{lng})) * pi() / 180 / 2), 2))) AS distance 
      FROM `Services` 
      INNER JOIN `Organizations` 
      ON 
      `Services`.`organizationId` = `Organizations`.`id` 
      WHERE 
      `Services`.`type` = '#{type}' 
    "
    conditions = []
    if opts.isAvailable
      conditions.push '(
        `Services`.`openCapacity` > 0 OR 
        `Services`.`maxCapacity` = 0
      )'
    if conditions.length > 0
      query += ' AND ' + conditions.join ' AND '
    query += ' ' + '
      ORDER BY distance ASC 
      LIMIT 50
    '
    services = yield client.query query, 
      type: sequelize.QueryTypes.SELECT
    if opts.isOpen
      _services = []
      for service in services
        hours = JSON.parse service.businessHours
        if Service.isOpen hours, service.tz
          _services.push service
      services = _services
    return services

  reserve: (opts) ->
    client = opts.client
    service = opts.service
    if service.maxCapacity isnt 0 and service.openCapacity <= 0
      return
    origin = opts.origin
    destination = opts.destination
    intent = null
    yield db.client.transaction (t) =>
      return co () =>
        if service.maxCapacity > 0
          service = yield Service.findById service.id
          yield service.decrement 'openCapacity', 
            transaction: t
        expiresAt = moment().add 15, 'minutes'
        intent = yield Intent.create
          expiresAt: new Date expiresAt.valueOf()
          code: uid 6
          clientId: client.id
          serviceId: service.id
        , 
          transaction: t
        # FIXME: schedule auto expiration
        return
    return intent