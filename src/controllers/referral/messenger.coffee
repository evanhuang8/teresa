module.exports = 

  menu: () ->
    'Do you need help with anything today?\n\n1: Temporary shelter\n2: Health\n3: Housing\n4: Job\n5: Food\n6: Funds\n7: Talk to someone\nPlease reply 1-7'

  parseErrorMenu: () ->
    'Sorry we did not get that. The options are:\n\n1: Temporary shelter\n2: Health\n3: Housing\n4: Job\n5: Food\n6: Funds\n7: Talk to someone'

  address: () ->
    'Where are you right now? Please reply with a street address or an intersection (ex: Main Street and North Ave)'

  parseErrorAddress: () ->
    'Sorry we did not get that. Please reply with a street address or an intersection (ex: Main Street and North Ave)'

  referral: (service, directions, willExpire) ->
    message = "#{service.name} is available"
    if directions?
      minutes = Math.round directions.duration / 60
      message = " (#{minutes}mins away)"
    message = ', would you want to reserve it?'
    if willExpire
      message += ' Available for the next 15 minutes.'
    return message

  noReferrals: () ->
    'Sorry we cannot find an appropriate service near you. Would you want to talk to someone directly instead? Please reply yes or no.'

  parseErrorYesNo: () ->
    'Sorry, we didn\'t get that. Please reply yes to reserve or no to not reserve.'

  cancel: () ->
    'OK. If you need help with anything else, just let us know. We are here for you.'

  pendingConfirmation: () ->
    'OK. Your request is submitted, once it\'s confirmed we will let you know!'

  confirmed: (code) ->
    "OK. Your reservation is confirmed, please present the code #{code} when you arrive. Do you need directions? Please reply yes or no"