overlay = undefined
map = undefined
markers = []

initMap = ->
  console.log ("init mapping")
  mapOptions =
    zoom: 19
    center: new (google.maps.LatLng)(Evercam.Camera.location.lat, Evercam.Camera.location.lng)
  map = new (google.maps.Map)(document.getElementById('mapping_container'), mapOptions)
  addCamera()

load_overlay = ->
  swBound = new (google.maps.LatLng)(Evercam.Camera.location.lat - 0.0100000, Evercam.Camera.location.lng - 0.0100000)
  neBound = new (google.maps.LatLng)(Evercam.Camera.location.lat + 0.0100000, Evercam.Camera.location.lng + 0.0100000)
  bounds = new (google.maps.LatLngBounds)(swBound, neBound)

  srcImage = 'https://media.evercam.io/v1/cameras/evercam-office/archives/overl-zwqct/thumbnail?type=clip'
  overlay = new USGSOverlay(bounds, srcImage, map)

  markerA = new (google.maps.Marker)(
    position: swBound
    icon: 'https://maps.google.com/mapfiles/kml/pal4/icon57.png'
    map: map
    draggable: true)

  markerB = new (google.maps.Marker)(
    position: neBound
    icon: 'https://maps.google.com/mapfiles/kml/pal4/icon57.png'
    map: map
    draggable: true)

  overlay.bindTo 'sw', markerA, 'position', true
  overlay.bindTo 'ne', markerB, 'position', true

  google.maps.event.addListener markerA, 'drag', ->
    newPointA = markerA.getPosition()
    newPointB = markerB.getPosition()
    newBounds = new (google.maps.LatLngBounds)(newPointA, newPointB)
    overlay.updateBounds newBounds

  google.maps.event.addListener markerB, 'drag', ->
    newPointA = markerA.getPosition()
    newPointB = markerB.getPosition()
    newBounds = new (google.maps.LatLngBounds)(newPointA, newPointB)
    overlay.updateBounds newBounds

  google.maps.event.addListener markerA, 'dragend', ->
    newPointA = markerA.getPosition()
    newPointB = markerB.getPosition()
    console.log 'point1' + newPointA
    console.log 'point2' + newPointB

  google.maps.event.addListener markerB, 'dragend', ->
    newPointA = markerA.getPosition()
    newPointB = markerB.getPosition()
    console.log 'point1' + newPointA
    console.log 'point2' + newPointB

USGSOverlay = (bounds, image, map) ->
  @bounds_ = bounds
  @image_ = image
  @map_ = map
  @div_ = null
  @setMap map
  @set 'dragging', false
  @addListener 'dragging_changed', ->
    dragging = @get('dragging')
    map.setOptions 'draggable': !dragging
    return

USGSOverlay.prototype = new (google.maps.OverlayView)

USGSOverlay::onAdd = ->
  self = this
  panes = @getPanes()
  div = document.createElement('div')
  div.style.borderStyle = 'none'
  div.style.borderWidth = '0px'
  div.style.position = 'absolute'
  img = document.createElement('img')
  img.src = @image_
  img.style.width = '100%'
  img.style.height = '100%'
  img.style.position = 'absolute'
  div.appendChild img
  @div_ = div
  panes.overlayLayer.appendChild div
  mouseTarget = document.createElement('div')
  mouseTarget.style.borderStyle = 'none'
  mouseTarget.style.borderWidth = '0px'
  mouseTarget.style.position = 'absolute'
  mouseTarget.draggable = 'true'
  panes.overlayMouseTarget.appendChild mouseTarget
  @mouseTarget_ = mouseTarget
  google.maps.event.addDomListener mouseTarget, 'drag', (e) ->
    if !self.get('dragging') or e.clientX < 0 and e.clientY < 0
      return
    imgX = e.clientX - self.get('mouseX') + self.get('imgX')
    imgY = e.clientY - self.get('mouseY') + self.get('imgY')
    self.set 'dragImgX', imgX
    self.set 'dragImgY', imgY
    mouseTarget.style.left = imgX + 'px'
    mouseTarget.style.top = imgY + 'px'
    div.style.left = imgX + 'px'
    div.style.top = imgY + 'px'
    overlayProjection = self.getProjection()
    sw = overlayProjection.fromContainerPixelToLatLng(new (google.maps.Point)(imgX, imgY + img.offsetHeight))
    ne = overlayProjection.fromContainerPixelToLatLng(new (google.maps.Point)(imgX + img.offsetWidth, imgY))
    self.set 'sw', sw
    self.set 'ne', ne

  google.maps.event.addDomListener mouseTarget, 'mousedown', (e) ->
    # Cancel the mousedown event to prevent dragging the map.
    if e.stopPropagation
      e.stopPropagation()
    else if window.e
      window.e.cancelBubble = true
    self.set 'mouseX', e.clientX
    self.set 'mouseY', e.clientY

  google.maps.event.addDomListener mouseTarget, 'dragstart', (e) ->
    self.set 'dragging', true

  google.maps.event.addDomListener mouseTarget, 'dragleave', (e) ->
    self.set 'dragging', false
    self.updateBounds new (google.maps.LatLngBounds)(self.get('sw'), self.get('ne'))

USGSOverlay::draw = ->
  #debugger;
  overlayProjection = @getProjection()
  sw = overlayProjection.fromLatLngToDivPixel(@bounds_.getSouthWest())
  ne = overlayProjection.fromLatLngToDivPixel(@bounds_.getNorthEast())
  div = @div_
  @set 'imgX', sw.x
  @set 'imgY', ne.y
  div.style.left = sw.x + 'px'
  div.style.top = ne.y + 'px'
  div.style.width = ne.x - (sw.x) + 'px'
  div.style.height = sw.y - (ne.y) + 'px'
  @mouseTarget_.style.left = div.style.left
  @mouseTarget_.style.top = div.style.top
  @mouseTarget_.style.width = div.style.width
  @mouseTarget_.style.height = div.style.height

USGSOverlay::updateBounds = (bounds) ->
  @bounds_ = bounds
  @draw()

USGSOverlay::onRemove = ->
  @div_.parentNode.removeChild @div_
  @div_ = null

addCamera = ->
  destinations = []

  clouser_points = ->
    vertices = polygon.getPath()
    i = 0
    while i < vertices.getLength()
      xy = vertices.getAt(i)
      latlng = new (google.maps.LatLng)(xy.lat() - 0.00173, xy.lng())
      marker = markers[i]
      marker.setPosition latlng
      i++

  update_polygon_closure = (polygon, marker, i) ->
    (event) ->
      latlng = new (google.maps.LatLng)(event.latLng.lat().toFixed(7) - 0.000011373, event.latLng.lng())
      polygon.getPath().setAt i, latlng
      marker.setPosition latlng

  dragend_camera_focal = ->
    console.log 'hi'

  destinations.push new (google.maps.LatLng)(Evercam.Camera.location.lat, Evercam.Camera.location.lng)
  destinations.push new (google.maps.LatLng)(Evercam.Camera.location.lat + 0.010000, 73.079951)
  destinations.push new (google.maps.LatLng)(Evercam.Camera.location.lat + 0.010000, 73.100151)
  polygonOption =
    path: destinations
    strokeColor: '#009900'
    strokeOpacity: 0.8
    strokeWeight: 4
    fillColor: '#009900'
    fillOpacity: 0.35
    zIndex: 99901
  polygon = new (google.maps.Polygon)(polygonOption)
  polygon.setMap map
  marker_options =
    map: map
    icon: 'https://maps.google.com/mapfiles/kml/pal4/icon57.png'
    flat: true
    draggable: true
    raiseOnDrag: false
  i = 0
  while i < destinations.length
    latlng = destinations[i]
    marker_options.position = new (google.maps.LatLng)(latlng.lat() - 0.00173, latlng.lng())
    if i == 0
      rectangle = new (google.maps.Rectangle)(
        strokeColor: '#009900'
        strokeOpacity: 0.8
        strokeWeight: 4
        fillColor: '#009900'
        fillOpacity: 0.35
        editable: false
        map: map
        bounds:
          north: 53.355162
          south: 53.353162
          east: -6.2876390
          west: -6.2949890)
    else
      marker = new (google.maps.Marker)(marker_options)
      google.maps.event.addListener marker, 'drag', update_polygon_closure(polygon, marker, i)
      #google.maps.event.addListener(marker, "dragend", dragend_camera_focal());
      markers.push marker
    i++

window.initializeMappingTab = ->
  map_height = Metronic.getViewPort().height - $("#ul-nav-tab").height()
  $("#mapping_container").height(map_height - 5)
  initMap()
