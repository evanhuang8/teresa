if not @Teresa.client?
  @Teresa.client = {}

ClientList = React.createClass

  getInitialState: ->
    state =
      keyword: @props.keyword
      clients: null
    return state

  fetchClients: ->
    params =
      keyword: @state.keyword
    Teresa.postJSON '/client/fetch', params, (response) =>
      if response.status is 'OK'
        @setState
          clients: response.clients
      return
    return

  componentDidMount: ->
    @fetchClients()
    return

  render: ->
    <div>
      {
        if @state.clients? and @state.clients.length > 0
          @state.clients.map (client) ->
            <ClientListItem
              client={client}
            />
      }
    </div>

ClientListItem = React.createClass

  getInitialState: ->
    state = {}
    return state

  render: ->
    <div>
      <h1>All Clients</h1>
    </div>
    <ul className="list-group">
      <li className="list-group-item">
        <div className="row">
          <div className="col-md-6">
            {@props.client.firstName}
            {
              if @props.client.middleName?
                " #{@props.client.middleName}."
            }
            {" #{@props.client.lastName}"}
          </div>
          <div className="col-md-6 text-right">
            <a className="btn btn-sm btn-secondary" href="/client/?id=#{@props.client.id}">View Details</a>
            <a className="btn btn-sm btn-secondary" href="/client/update?id=#{@props.client.id}"> Edit</a>
            <a className="btn btn-sm btn-success" href="/referral/add?client=#{@props.client.id}"> Refer</a>
          </div>
        </div>
      </li>
    </ul>

@Teresa.client.list = 

  init: () ->
    props =
      keyword: if keyword? then keyword else null
    React.render(<ClientList {...props} />, $('div#client-list')[0])
    return