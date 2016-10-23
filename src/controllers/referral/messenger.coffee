module.exports = 

  checkup: (firstName, displayName) ->
    insert = ''
    if firstName?
      insert = ' ' + firstName
    "Hi#{insert}, this is #{displayName} checking in on you. Are you:\n\n1: Doing OK\n\n2. Worried about losing your home\n\n3. Lost your home\n\n"

  well: () ->
    'Good to hear! If you need help regarding your home, you can always text this number for help.'

  parseErrorCheckup: () ->
    'Sorry we did not get that. Are you:\n\n1: Doing OK\n\n2. Worried about losing your home\n\n3. Lost your home\n\n'

  menu: () ->
    'Do you need help with anything today?\n\n1: Temporary shelter\n2: Health\n3: Housing\n4: Job\n5: Food\n6: Funds\n7: Talk to someone\n\nPlease reply 1-7'

  parseErrorMenu: () ->
    'Sorry we did not get that. The options are:\n\n1: Temporary shelter\n2: Health\n3: Housing\n4: Job\n5: Food\n6: Funds\n7: Talk to someone'

  connection: () ->
    'OK. You will receive a call in the next few seconds to connect you with the appropiate personnel. Thanks!'

  address: () ->
    'Where are you right now? Please reply with a street address or an intersection (ex: Main Street and North Ave)'

  parseErrorAddress: () ->
    'Sorry we did not get that. Please reply with a street address or an intersection (ex: Main Street and North Ave)'

  referral: (service, directions, willExpire) ->
    message = "#{service.name} is available"
    if directions?
      minutes = Math.round directions.duration / 60
      message += " (#{minutes}mins away)"
    message += ', would you want to reserve it?'
    if willExpire
      message += ' Please confirm in the next 15 minutes.'
    return message

  noReferrals: () ->
    'Sorry we cannot find an appropriate service near you. Would you want to talk to someone directly instead? Please reply yes or no.'

  parseErrorYesNo: () ->
    'Sorry, we didn\'t get that. Please reply yes or no.'

  cancel: () ->
    'OK. If you need help with anything else, just let us know. We are here for you.'

  pendingConfirmation: () ->
    'OK. Your request is submitted, once it\'s confirmed we will let you know!'

  confirmed: (code) ->
    segment = ''
    if code?
      segment = ", please present the code #{code} when you arrive"
    "OK. Your reservation is confirmed#{segment}. Do you need directions? Please reply yes or no"

  noDirection: () ->
    'Sorry, we do not have direction for you at this time.'

  end: () ->
    'OK. You can text `direction` later to get the direction.'

  restart: () ->
    'If you need other help, reply `restart` at any point.'