co = require 'co'
moment = require 'moment-timezone'
sequelize = require 'sequelize'
uid = require 'uid2'

db = require '../../db'
client = db.client
ShelterService = db.model 'ShelterService'
ShelterIntent = db.model 'ShelterIntent'

LocationUtils = require '../../utils/location'

module.exports = 

  nearestShelters: (opts) ->
    lat = opts.lat
    lng = opts.lng
    query = "
      SELECT 
      `ShelterServices`.*, `lat`, `lng`, `tz`, 
      6371 * 2 * ASIN(SQRT(POWER(SIN((`lat` - ABS(#{lat})) * pi() / 180 / 2), 2) + COS(`lat` * pi() / 180 ) * COS(ABS(#{lat}) * pi() / 180) * POWER(SIN((`lng` - (#{lng})) * pi() / 180 / 2), 2))) AS distance 
      FROM `ShelterServices` 
      INNER JOIN `Organizations` 
      ON 
      `ShelterServices`.`organizationId` = `Organizations`.`id` 
    "
    
    conditions = []
    if opts.isAvailable
      conditions.push '`ShelterServices`.`openCapacity` > 0'
    if conditions.length > 0
      query += ' WHERE ' + conditions.join ' AND '
    query += ' ' + '
      ORDER BY distance ASC 
      LIMIT 50
    '
    shelters = yield client.query query, 
      type: sequelize.QueryTypes.SELECT
    if opts.isOpen
      _shelters = []
      for shelter in shelters
        hours = JSON.parse shelter.businessHours
        if ShelterService.isOpen hours, shelter.tz
          _shelters.push shelter
      shelters = _shelters
    return shelters

  reserve: (opts) ->
    shelter = opts.shelter
    if shelter.openCapacity <= 0
      return [null, null]
    origin = opts.origin
    destination = opts.destination
    intent = null
    directions = null
    yield db.client.transaction (t) =>
      return co () =>
        yield shelter.decrement 'openCapacity', 
          transaction: t
        directions = yield LocationUtils.directions
          origin: origin
          destination: destination
        expiresAt = moment().add 1, 'hour'
        if directions?
          expiresAt = moment().add directions.duration, 'seconds'
        intent = yield ShelterIntent.create
          expiresAt: new Date expiresAt.valueOf()
          code: uid 6
          clientId: opts.client.id
          shelterId: opts.shelter.id
        , 
          transaction: t
        return
    return [intent, directions]