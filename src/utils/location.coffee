request = require 'co-request'

GOOGLE_API_KEY = process.env.GOOGLE_API_KEY

module.exports = 

  geocode: (opts) ->
    url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?'
    url += 'key=' + GOOGLE_API_KEY
    url += '&query=' + encodeURIComponent opts.keyword
    if opts.near?
      url += "&location=#{opts.near.lat},#{opts.near.lng}"
      url += '&radius=50000'
    res = yield request url
    _res = JSON.parse res.body
    if _res.status isnt 'OK'
      console.log _res
      return [null, null]
    if _res.results.length is 0
      return [null, null]
    result =
      address: _res.results[0].formatted_address
      lat: _res.results[0].geometry.location.lat
      lng: _res.results[0].geometry.location.lng
    return result

  direction: (opts) ->
    origin = opts.origin
    destination = opts.destination
    url = 'https://maps.googleapis.com/maps/api/directions/json?'
    url += 'key=' + GOOGLE_API_KEY
    url += "&origin=#{origin.lat},#{origin.lng}"
    url += "&destination=#{destination.lat},#{destination.lng}"
    url += '&mode=walking'
    res = yield request url
    _res = JSON.parse res.body
    if _res.status isnt 'OK'
      console.log _res
      return
    if _res.routes.length is 0
      return
    route = _res.routes[0]
    return
