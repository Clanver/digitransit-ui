React                 = require 'react'
Relay                 = require 'react-relay'
queries               = require '../../queries'
ItinerarySummaryListContainer = require './itinerary-summary-list-container'
SearchTwoFieldsContainer      = require '../search/search-two-fields-container'
SummaryRow            = require './summary-row'
ItinerarySummary      = require '../itinerary/itinerary-summary'
ArrowLink             = require '../util/arrow-link'
Map                   = require '../map/map'
ItineraryLine         = require '../map/itinerary-line'
Icon                  = require '../icon/icon'
{supportsHistory}     = require 'history/lib/DOMUtils'
sortBy                = require 'lodash/sortBy'

class SummaryPlanContainer extends React.Component

  @contextTypes:
    getStore: React.PropTypes.func.isRequired
    executeAction: React.PropTypes.func.isRequired
    router: React.PropTypes.object.isRequired
    location: React.PropTypes.object.isRequired

  componentWillMount: ->
    #props = @context.getStore('ItinerarySearchStore').getOptions()

  componentDidMount: ->
    @context.getStore('ItinerarySearchStore').addChangeListener @onChange
    @context.getStore('TimeStore').addChangeListener @onTimeChange

  componentWillUnmount: ->
    @context.getStore('ItinerarySearchStore').removeChangeListener @onChange
    @context.getStore('TimeStore').removeChangeListener @onTimeChange

  onChange: =>
    @forceUpdate()

  onTimeChange: (e) =>
    if e.selectedTime
      console.log 'TODO change time'

  getActiveIndex: =>
    @context.location.state?.summaryPageSelected or @state?.summaryPageSelected or 0

  onSelectActive: (index) =>
    if @getActiveIndex() == index # second click navigates
      @context.router.push "#{@context.location.pathname}/#{index}"
    else if supportsHistory()
      @context.router.replace
        state: summaryPageSelected: index
        pathname: @context.location.pathname
    else
      @setState summaryPageSelected: index
      @forceReload()

  render: =>
    leafletObjs = []
    summaries = []
    plan = @props.plan.plan
    currentTime = @context.getStore('TimeStore').getCurrentTime().valueOf()
    summary = <ItinerarySummary className="itinerary-summary--summary-row itinerary-summary--onmap-black"
      itinerary={plan.itineraries[@getActiveIndex()]}
    />
    toItinerary = <ArrowLink to="#{@context.location.pathname}/#{@getActiveIndex()}"
      className="arrow-link--summary-row right-arrow-blue-background"
    />
    from = [@props.from.lat, @props.from.lon]
    to = [@props.to.lat, @props.to.lon]

    activeIndex = @getActiveIndex()

    for itinerary, i in plan.itineraries
      passive = i != activeIndex
      leafletObjs.push <ItineraryLine key={i}
        hash={i}
        legs={itinerary.legs}
        showFromToMarkers={i == 0}
        passive={passive}
      />

    leafletObjs = sortBy(leafletObjs, (i) => i.props.passive == false)

    <div className="summary">
      <Map ref="map"
        className="summaryMap"
        leafletObjs={leafletObjs}
        fitBounds={true}
        from={from}
        to={to}
        padding={[0, 110]}>
        <SearchTwoFieldsContainer/>
        {toItinerary}
        {summary}
      </Map>
      <ItinerarySummaryListContainer itineraries={plan.itineraries} currentTime={currentTime} onSelect={@onSelectActive} activeIndex={activeIndex} />
    </div>

module.exports = Relay.createContainer SummaryPlanContainer,
  fragments: queries.SummaryPlanContainerFragments
  initialVariables:
    from: null
    to: null
    numItineraries: 3
    walkReluctance: 2.0001
    walkBoardCost: 600
    minTransferTime: 180
    walkSpeed: 1.2
