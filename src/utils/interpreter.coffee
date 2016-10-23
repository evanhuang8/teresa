wit = require '../witai'

module.exports = 
  
  ###
  Take in a message body and attempt to parse:
  1. Intent - 'shelter, housing, job, etc.'
  2. Location
  ###
  interpret: (body) ->
    intent = null
    location = null
    interpretation = yield wit.message body
    if interpretation.entities?
      if interpretation.entities.intent?
        for _intent in interpretation.entities.intent
          intent = _intent.value
      if interpretation.entities.location?
        for _location in interpretation.entities.location
          location = _location.value
    result =
      intent: intent
      location: location
    return result