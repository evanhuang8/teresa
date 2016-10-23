if not @Teresa.referral?
  @Teresa.referral = {}

@Teresa.referral.add = 

  init: () ->
    props =
      clientId: if clientId? then clientId else null
      handleChooseService: (service, cb) ->
        params =
          service: service.id
          client: clientId
        Teresa.postJSON '/referral/create', params, (response) ->
          console.log response
        return
    React.render(<ServicesList {...props} />, $('div#rct-referral-list')[0])
    React.render(<ClientSummary {...props} />, $('div#rct-client-summary')[0])
    return