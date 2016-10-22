module.exports = 

  index: () ->
    @render 'index/index.jade'
    yield
    return