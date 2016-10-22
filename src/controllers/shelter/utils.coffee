co = require 'co'
sequelize = require 'sequelize'

db = require '../../db'
client = db.client
ShelterService = db.model 'ShelterService'
ShelterIntent = db.model 'ShelterIntent'

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
      return
    origin = opts.origin
    destination = opts.destination
    intent = null
    yield db.client.transaction (t) =>
      return co () =>
        yield shelter.decrement 'openCapacity', 
          transaction: t
        expiresAt = moment().add 30, 'minutes'
        intent = yield ShelterIntent.create
          expiresAt: new Date expiresAt.valueOf()
        return
    return intent