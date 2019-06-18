overlay = undefined
map = undefined
markers = []
object = undefined
point1 = undefined
point2 = undefined
camera_location_lat = 0
camera_location_lng = 0
object_location_lat = 0
object_location_lng = 0
object_diff = 0
o_lat = 0

initMap = ->
  mapOptions =
    zoom: 19
    center: new (google.maps.LatLng)(camera_location_lat, camera_location_lng)
  map = new (google.maps.Map)(document.getElementById('mapping_container'), mapOptions)
  addCamera()

load_overlay = ->
  swBound = new (google.maps.LatLng)(camera_location_lat - 0.0100000, camera_location_lng - 0.0100000)
  neBound = new (google.maps.LatLng)(camera_location_lat + 0.0100000, camera_location_lng + 0.0100000)
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
      latlng = new (google.maps.LatLng)(xy.lat(), xy.lng())
      if i == 0
        latlng = new (google.maps.LatLng)(xy.lat() - 0.000015, xy.lng().toFixed(7) - 0.000040)
      else
        latlng = new (google.maps.LatLng)(xy.lat() - 0.000019, xy.lng())
      marker = markers[i]
      marker.setPosition latlng
      if i == 1
        object.setPosition(new (google.maps.LatLng)(xy.lat() - object_diff, xy.lng()))
      i++

  update_polygon_closure = (polygon, marker, i) ->
    (event) ->
      latlng = new (google.maps.LatLng)(event.latLng.lat().toFixed(7) - 0.000011373, event.latLng.lng())
      polygon.getPath().setAt i, latlng
      marker.setPosition latlng

  bind_rotate_event = (polygon, degree) ->
    (event) ->
      if event.latLng.lat().toFixed(7) > o_lat
        rotatePolygon(polygon, -0.5)
      else
        rotatePolygon(polygon, 0.5)
      o_lat = event.latLng.lat().toFixed(7)

  point1 = new (google.maps.LatLng)(add_subtract(camera_location_lat, 0.000100), add_subtract(camera_location_lng, 0.000500))
  point2 = new (google.maps.LatLng)(camera_location_lat - 0.000060, add_subtract(camera_location_lng, 0.000500))
  destinations.push new (google.maps.LatLng)(camera_location_lat, camera_location_lng)
  destinations.push point1
  destinations.push point2

  polygonOption =
    path: destinations
    strokeColor: '#28E837'
    strokeOpacity: 0.8
    strokeWeight: 4
    fillColor: '#28E837'
    fillOpacity: 0.35
    zIndex: 99901,
    draggable: true

  polygon = new (google.maps.Polygon)(polygonOption)
  polygon.setMap map
  google.maps.event.addListener polygon, 'drag', clouser_points

  $("#btnRotate").on "click", ->
    rotatePolygon(polygon, 30)

  marker_options =
    map: map
    icon: 'https://maps.google.com/mapfiles/kml/pal4/icon57.png'
    flat: true
    raiseOnDrag: false

  i = 0
  while i < destinations.length
    latlng = destinations[i]
    if i == 0
      marker_options.position = new (google.maps.LatLng)(latlng.lat() - 0.000015, latlng.lng().toFixed(7) - 0.000040)
      marker_options.rotation = 10
      marker_options.icon = "https://s3-eu-west-1.amazonaws.com/evercam-public-assets/camera.png"
    else
      marker_options.position = new (google.maps.LatLng)(latlng.lat().toFixed(7) - 0.000019, latlng.lng())
      marker_options.icon = "https://maps.gstatic.com/mapfiles/transparent.png" # https://maps.google.com/mapfiles/kml/pal4/icon57.png"
    marker = new (google.maps.Marker)(marker_options)
    # google.maps.event.addListener marker, 'drag', update_polygon_closure(polygon, marker, i)
    #google.maps.event.addListener(marker, "dragend", dragend_camera_focal());
    markers.push marker
    i++

  object_diff = (point1.lat().toFixed(7) - point2.lat().toFixed(7)) / 2
  if camera_location_lat is object_location_lat
    o_lat = point1.lat() - object_diff
    o_lng = point1.lng()
  else
    o_lat = object_location_lat
    o_lng = object_location_lng
  marker_options.position = new (google.maps.LatLng)(o_lat, o_lng)
  marker_options.draggable = true
  marker_options.icon = "https://maps.google.com/mapfiles/ms/micons/man.png"
  object = new (google.maps.Marker)(marker_options)
  google.maps.event.addListener(object, 'drag', bind_rotate_event(polygon, 0.5));

add_subtract = (value, value2) ->
  return value + value2

getBearings = ->
  spherical = google.maps.geometry.spherical
  point1 = markers[0].getPosition()
  point2 = markers[1].getPosition()
  point3 = markers[2].getPosition()
  bearing1 = google.maps.geometry.spherical.computeHeading(point1, point2)
  bearing2 = google.maps.geometry.spherical.computeHeading(point2, point3)
  angle = getDifference(bearing1, bearing2)
  angle

getDifference = (a1, a2) ->
  al = if a1 > 0 then a1 else 360 + a1
  a2 = if a2 > 0 then a2 else 360 + a2
  angle = Math.abs(a1 - a2) + 180
  if angle > 180
    angle = 360 - angle
  Math.abs angle

rotatePolygon = (polygon, angle) ->
  map = polygon.getMap()
  prj = map.getProjection()
  origin = prj.fromLatLngToPoint(polygon.getPath().getAt(0))
  coords = polygon.getPath().getArray().map((latLng) ->

    point = prj.fromLatLngToPoint(latLng)
    rotatedLatLng = prj.fromPointToLatLng(rotatePoint(point, origin, angle))
    {
      lat: rotatedLatLng.lat()
      lng: rotatedLatLng.lng()
    }
  )
  polygon.setPath coords

rotatePoint = (point, origin, angle) ->
  angleRad = angle * Math.PI / 180.0
  {
    x: Math.cos(angleRad) * (point.x - (origin.x)) - (Math.sin(angleRad) * (point.y - (origin.y))) + origin.x
    y: Math.sin(angleRad) * (point.x - (origin.x)) + Math.cos(angleRad) * (point.y - (origin.y)) + origin.y
  }

handleTabOpen = ->
  $('.nav-tab-mapping').on 'shown.bs.tab', ->
    USGSOverlay.prototype = new (google.maps.OverlayView)
    initMap()

window.initializeMappingTab = ->
  map_height = Metronic.getViewPort().height - $("#ul-nav-tab").height()
  $("#mapping_container").height(map_height - 5)
  camera_location_lat = Evercam.Camera.location_detailed.lat
  camera_location_lng = Evercam.Camera.location_detailed.lng
  object_location_lat = Evercam.Camera.location_detailed.lat
  object_location_lng = Evercam.Camera.location_detailed.lng
  handleTabOpen()
