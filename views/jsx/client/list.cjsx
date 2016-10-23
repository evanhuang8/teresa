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
    <div className="row">
      <div className="col-md-6">
        {@props.client.firstName}
        {
          if @props.client.middleName?
            " #{@props.client.middleName}"
        }
        {" #{@props.client.lastName}"}
      </div>
      <div className="col-md-6 text-right">
        <a href="javascript:;">View Details</a>
        <a href="javascript:;"> Edit</a>
        <a href="/referral/add?client=#{@props.client.id}"> Refer</a>
      </div>
    </div>

@Teresa.client.list = 

  init: () ->
    props =
      keyword: if keyword? then keyword else null
    React.render(<ClientList {...props} />, $('div#client-list')[0])
    return