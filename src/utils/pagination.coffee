module.exports = (Model, where, order, fetchOnly) ->

  limit = 30
  if @request.body.limit? and 100 >= parseInt @request.body.limit
    limit = parseInt @request.body.limit
  offset = 0
  if @request.body.page?
    offset = limit * parseInt @request.body.page

  params = 
    limit: limit
    offset: offset
  if where?
    params.where = where
  if order?
    params.order = order

  objs = yield Model.findAll params
  if not fetchOnly
    @request.body = 
      status: 'OK'
      objs: objs
  return objs