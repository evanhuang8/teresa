module.exports = (Model, fields, updateOnly) ->

  obj = yield Model.findById @request.body.id
  if not obj?
    @status = 400
    return

  for field in fields
    if @request.body[field]?
      obj[field] = @request.body[field]
    else if @request.body[field] is null
      obj[field] = null

  yield obj.save()
  if not updateOnly
    @body = 
      status: 'OK'
      obj: obj

  return obj