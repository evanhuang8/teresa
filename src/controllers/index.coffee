module.exports = 

  index: () ->
    if not @passport.user?
      @redirect '/login'
      return
    @render 'referral/all', 
      user: @passport.user
    yield return

  login: () ->
    if @passport.user?
      @redirect '/'
      return
    @render 'index/login'
    yield return

  logout: () ->
    @logout()
    @redirect '/login'
    yield return