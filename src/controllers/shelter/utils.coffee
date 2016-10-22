sequelize = require 'sequelize'

db = require '../../db'
client = db.client

module.exports = 

  nearestShelters: (opts) ->
    lat = opts.lat
    lng = opts.lng
    query = "
      SELECT 
      `ShelterServices`.*, `lat`, `lng`, 
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
    result = yield client.query query, 
      type: sequelize.QueryTypes.SELECT
    return result