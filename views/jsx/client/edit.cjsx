if not @Teresa.client?
  @Teresa.client = {}

@Teresa.client.edit = 

  init: () ->
    params =
      clientId: clientId
      editing: true
    React.render(<ClientForm {...params} />, $('div#client-edit')[0])
    return