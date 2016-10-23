module.exports = 

  index: () ->
    if not @passport.user?
      @redirect '/login'
      return
    @render 'index/index', 
      user: @passport.user
    yield return

  login: () ->
    if @passport.user?
      @redirect '/'
      return
    @render 'index/login'
    yield return