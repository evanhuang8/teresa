if not @Teresa.client?
  @Teresa.client = {}

@Teresa.client.add = 

  init: () ->
    React.render(<ClientForm />, $('div#client-add')[0])
    return