if not @Teresa.client?
  @Teresa.client = {}

ClientList = React.createClass

  getInitialState: ->
    state =
      keyword: @props.keyword
      clients: null
      page: 0
      total: 0
    return state

  fetchClients: ->
    params =
      keyword: @state.keyword
      page: @state.page
    Teresa.postJSON '/client/fetch', params, (response) =>
      if response.status is 'OK'
        @setState
          clients: response.clients
          total: response.total
      return
    return

  handlePageChange: (page) ->
    @setState
      page: page
    , () =>
      @fetchClients()
      return
    return

  componentDidMount: ->
    @fetchClients()
    return

  render: ->
    <div className="container">
      {
        if @state.clients? and @state.clients.length > 0
          <div className="row">
            {
              @state.clients.map (client) ->
                <ClientListItem
                  client={client}
                />
            }
          </div>
      }
      <UIPagination total={@state.total} onPageChange={@handlePageChange} />
    </div>

ClientListItem = React.createClass

  getInitialState: ->
    state = {}
    return state

  render: ->
    <div className="col-md-6">
      <div className="card">
        <div className="card-block">
          <h4 className="card-title">
            {@props.client.firstName}
            {
              if @props.client.middleName?
                " #{@props.client.middleName}"
            }
            {" #{@props.client.lastName}"}
          </h4>
          <h5 className="text-muted">
            {@props.client.phone}
          </h5>
        </div>
        <div className="card-footer">
          <a className="card-link" href="/client/?id=#{@props.client.id}">View Details</a>
          <a className="card-link" href="/client/update?id=#{@props.client.id}"> Edit</a>
          <a className="btn btn-sm btn-primary pull-right" href="/referral/add?client=#{@props.client.id}">Refer <span className="fa fa-arrow-right"></span></a>
        </div>
      </div>
    </div>

@Teresa.client.list = 

  init: () ->
    props =
      keyword: if keyword? then keyword else null
    React.render(<ClientList {...props} />, $('div#client-list')[0])
    return