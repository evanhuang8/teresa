if not @Teresa.referral?
  @Teresa.referral = {}

@Teresa.referral.add = 

  init: () ->
    props =
      clientId: if clientId? then clientId else null
      keyword: if keyword? then keyword else null
      type: if type? then type else null
      handleChooseService: (service) ->
        console.log service
        console.log clientId
        return
    React.render(<ServicesList {...props} />, $('div#referral-list')[0])
    return