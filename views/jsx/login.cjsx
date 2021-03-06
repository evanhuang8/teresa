@Teresa.login = 

  init: () ->
    $('form[name=login]').submit (event) ->
      event.preventDefault()
      return
    $('input[name=password]').keyup (event) ->
      if event.which is 13
        $('.js-login').click()
      return
    $('.js-login').click () ->
      params = $('form[name=login]').serializeObject()
      Teresa.postJSON '/user/auth/', params, (response) ->
        if response.status is 'OK'
          window.location.href = '/'
          return
        Teresa.alert 'Error', response.message
        return
      return
    return