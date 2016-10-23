@Teresa = 

  get: (url, params, cb) ->
    xhr = $.get url, params, (data) ->
      cb? data
      return
    xhr.fail (_xhr) ->
      res =
        status: 'FAIL'
        message: 'Oops, something is not right here!'
      cb? res
      return
    return

  post: (url, params, cb) ->
    xhr = $.post url, params, (data) ->
      cb? data
      return
    xhr.fail (_xhr) ->
      res =
        status: 'FAIL'
        message: 'Oops, something is not right here!'
      cb? res
      return
    return

  postJSON: (url, params, cb) ->
    xhr = $.ajax url,
      data: JSON.stringify params
      contentType: 'application/json'
      type: 'POST'
    xhr.done (data) ->
      cb? data
      return
    xhr.fail (_xhr) ->
      res =
        status: 'FAIL'
        message: 'Oops, something is not right here!'
      cb? res
      return
    return

  alert: (title, message) ->
    alert message
    return

  init: () ->
    return