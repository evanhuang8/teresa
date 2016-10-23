if not @Teresa.referral?
  @Teresa.referral = {}

ReferralList = React.createClass

  getInitialState: ->
    state =
      keyword: @props.keyword
      referrals: null
    return state

  fetchReferrals: ->
    params =
      keyword: @state.keyword
    Teresa.postJSON '/referral/fetch', params, (response) =>
      if response.status is 'OK'
        @setState
          referrals: response.referrals
      return
    return

  handleConfirmReferral: (referral) ->
    params =
      referral: referral.id
    Teresa.postJSON '/referral/confirm', params, (response) =>
      if response.status is 'OK'
        Teresa.alert 'Success', 'The referral has been confirmed!'
        @fetchReferrals()
      else
        console.log response
    return

  componentDidMount: ->
    @fetchReferrals()
    return

  render: ->
    <div className="row">
      {
        if @state.referrals? and @state.referrals.length > 0
          @state.referrals.map (referral) =>
            <ReferralListItem
              referral={referral}
              handleConfirmReferral={@handleConfirmReferral}
            />
      }      
    </div>

ReferralListItem = React.createClass

  getInitialState: ->
    state = {}
    return state

  render: ->
    referral = @props.referral
    <div className="col-md-4">
      <div className="card">
        <div className="card-block">
          {
            if referral.referer?
              <h6 className="card-subtitle pt-1" style={
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis'
                }>
                <span className="text-muted">Referral from</span> {referral.referer.name}
              </h6>
          }
        </div>
        {
          if referral.referer?
            <div className="list-group list-group-flush">
              <div className="list-group-item" style={height: '125px'}>
                <img src={referral.referer.image} style={
                    maxWidth: '75%',
                    maxHeight: '75%',
                    margin: '20px auto',
                    display: 'block'
                  }/>                  
              </div>
            </div>
        }
        <div className="card-block">
          <h4 className="card-title">{referral.client.firstName} {referral.client.lastName}</h4>
          <h6 className="card-subtitle"><span className="text-muted">for</span> {referral.service.name}</h6>
        </div>
        <div className="card-footer">
          {
            if not referral.isConfirmed
              <a className="btn btn-sm btn-success" href="javascript:;" onClick={@props.handleConfirmReferral.bind @, referral}>Confirm Referral</a>
          }
          {
            if referral.isConfirmed
              <small>
                {
                  if referral.isComplete
                    'Completed'
                  else
                    'Confirmed'

                }
              </small>
            else
              'Referred'
          }
          <small className="text-muted"> {moment.tz(referral.createdAt, 'US/Central').format('MM/DD, hh:mmA')}</small>
        </div>
      </div>
    </div>

@Teresa.referral.all = 

  referralList: undefined

  init: () ->

    @referralList = React.render(<ReferralList />, $('div#rct-referral-list')[0])

    Teresa.handleNewReferral = (referral) =>
      @referralList.fetchReferrals()
      return
  
    return