module.exports = 

  index: () ->
    if not @passport.user?
      @redirect '/login'
      return
    @render 'index/index'
    yield return

  login: () ->
    if @passport.user?
      @redirect '/'
      return
    @render 'index/login'
    yield return