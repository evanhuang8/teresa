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
          if response.status is 'OK'
            Teresa.alert 'Success', 'The referral has been created. It will be sent to the service provider.'
            window.location.href = "/client/?id=#{response.referral.clientId}"
          else
            console.log response
        return
    React.render(<ServicesList {...props} />, $('div#rct-referral-list')[0])
    React.render(<ClientSummary {...props} />, $('div#rct-client-summary')[0])
    return