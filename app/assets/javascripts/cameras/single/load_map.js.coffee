############################
###### Version Three #######
############################

# window.initMap = ->
#   map = new (L.Map)('map-info')
#   positron = L.tileLayer('http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', attribution: '').addTo(map)
#   point1 = L.latLng(Evercam.Camera.location.lat, Evercam.Camera.location.lng)
#   point2 = L.latLng(Evercam.Camera.location.lat - 0.0100000, Evercam.Camera.location.lng - 0.0100000)
#   point3 = L.latLng(Evercam.Camera.location.lat + 0.0100000, Evercam.Camera.location.lng + 0.0100000)
#   marker1 = L.marker(point1, draggable: true).addTo(map)
#   marker2 = L.marker(point2, draggable: true).addTo(map)
#   marker3 = L.marker(point3, draggable: true).addTo(map)
#   bounds = new (L.LatLngBounds)(point1, point2).extend(point3)

#   repositionImage = ->
#     overlay.reposition marker1.getLatLng(), marker2.getLatLng(), marker3.getLatLng()

#   setOverlayOpacity = (opacity) ->
#     overlay.setOpacity opacity

#   map.fitBounds bounds
#   overlay = L.imageOverlay.rotated('https://media.evercam.io/v1/cameras/evercam-office/archives/overl-zwqct/thumbnail?type=clip', point1, point2, point3,
#     opacity: 1
#     interactive: true
#     attribution: '')

#   marker1.on 'drag dragend', repositionImage
#   marker2.on 'drag dragend', repositionImage
#   marker3.on 'drag dragend', repositionImage
#   #     var c = overlay.getCanvas2DContext()
#   map.addLayer overlay

#   overlay.on 'dblclick', (e) ->
#     console.log 'Double click on image.'
#     e.stop()

#   overlay.on 'click', (e) ->
#     console.log 'Click on image.'


##########################
###### Version Two #######
##########################

overlay = undefined

window.initMap = ->
  mapOptions =
    zoom: 14
    center: new (google.maps.LatLng)(Evercam.Camera.location.lat, Evercam.Camera.location.lng)
  map = new (google.maps.Map)(document.getElementById('map-info'), mapOptions)

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
    return
  google.maps.event.addDomListener mouseTarget, 'mousedown', (e) ->
    # Cancel the mousedown event to prevent dragging the map.
    if e.stopPropagation
      e.stopPropagation()
    else if window.e
      window.e.cancelBubble = true
    self.set 'mouseX', e.clientX
    self.set 'mouseY', e.clientY
    return
  google.maps.event.addDomListener mouseTarget, 'dragstart', (e) ->
    self.set 'dragging', true
    return
  google.maps.event.addDomListener mouseTarget, 'dragleave', (e) ->
    self.set 'dragging', false
    self.updateBounds new (google.maps.LatLngBounds)(self.get('sw'), self.get('ne'))
    return
  return

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
  return

USGSOverlay::updateBounds = (bounds) ->
  @bounds_ = bounds
  @draw()
  return

USGSOverlay::onRemove = ->
  @div_.parentNode.removeChild @div_
  @div_ = null
  return


##########################
###### Version One #######
##########################

# overlay = undefined

# # Initialize the map and the custom overlay.
# window.initMap = ->
#   map = new (google.maps.Map)(document.getElementById('map-info'),
#     zoom: 14
#     center:
#       lat: Evercam.Camera.location.lat,
#       lng: Evercam.Camera.location.lng)

#   top_right = new (google.maps.LatLng)(Evercam.Camera.location.lat - 0.0100000, Evercam.Camera.location.lng - 0.0100000)
#   bottom_left = new (google.maps.LatLng)(Evercam.Camera.location.lat + 0.0100000, Evercam.Camera.location.lng + 0.0100000)
#   bounds = new (google.maps.LatLngBounds)(top_right, bottom_left)

#   srcImage = 'https://media.evercam.io/v1/cameras/evercam-office/archives/overl-zwqct/thumbnail?type=clip'
#   overlay = new USGSOverlay(bounds, srcImage, map)

#   markerA = new (google.maps.Marker)(
#     position: top_right
#     icon: "https://maps.google.com/mapfiles/kml/pal4/icon57.png"
#     map: map
#     draggable: true)

#   markerB = new (google.maps.Marker)(
#     position: bottom_left
#     icon: "https://maps.google.com/mapfiles/kml/pal4/icon57.png"
#     map: map
#     draggable: true)

#   overlay.bindTo 'sw', markerA, 'position', true
#   overlay.bindTo 'ne', markerB, 'position', true

#   google.maps.event.addListener markerA, 'drag', ->
#     newPointA = markerA.getPosition()
#     newPointB = markerB.getPosition()
#     newBounds = new (google.maps.LatLngBounds)(newPointA, newPointB)
#     overlay.updateBounds newBounds

#   google.maps.event.addListener markerB, 'drag', ->
#     newPointA = markerA.getPosition()
#     newPointB = markerB.getPosition()
#     newBounds = new (google.maps.LatLngBounds)(newPointA, newPointB)
#     overlay.updateBounds newBounds

#   google.maps.event.addListener markerA, 'dragend', ->
#     newPointA = markerA.getPosition()
#     newPointB = markerB.getPosition()
#     console.log 'point1' + newPointA
#     console.log 'point2' + newPointB

#   google.maps.event.addListener markerB, 'dragend', ->
#     newPointA = markerA.getPosition()
#     newPointB = markerB.getPosition()
#     console.log 'point1' + newPointA
#     console.log 'point2' + newPointB


# USGSOverlay = (bounds, image, map) ->
#   @bounds_ = bounds
#   @image_ = image
#   @map_ = map
#   @div_ = null
#   @setMap map

#   @set 'dragging', false
#   @addListener 'dragging_changed', ->
#     dragging = @get('dragging')
#     map.setOptions 'draggable': !dragging

# USGSOverlay.prototype = new (google.maps.OverlayView)

# USGSOverlay::onAdd = ->
#   div = document.createElement('div')
#   div.style.borderStyle = 'none'
#   div.style.borderWidth = '0px'
#   div.style.position = 'absolute'
#   div.draggable = true

#   img = document.createElement('img')
#   img.src = @image_
#   img.style.width = '100%'
#   img.style.height = '100%'
#   img.style.position = 'absolute'
#   div.appendChild img
#   @div_ = div

#   panes = @getPanes()
#   panes.overlayLayer.appendChild div

#   mouseTarget = document.createElement('div')
#   mouseTarget.style.borderStyle = 'none'
#   mouseTarget.style.borderWidth = '0px'
#   mouseTarget.style.position = 'absolute'
#   mouseTarget.draggable = 'true'
#   panes.overlayMouseTarget.appendChild mouseTarget
#   @mouseTarget_ = mouseTarget

#   google.maps.event.addDomListener mouseTarget, 'drag', (e) ->
#     if !self.get('dragging') or e.clientX < 0 and e.clientY < 0
#       return
#     imgX = e.clientX - self.get('mouseX') + self.get('imgX')
#     imgY = e.clientY - self.get('mouseY') + self.get('imgY')
#     self.set 'dragImgX', imgX
#     self.set 'dragImgY', imgY
#     mouseTarget.style.left = imgX + 'px'
#     mouseTarget.style.top = imgY + 'px'
#     div.style.left = imgX + 'px'
#     div.style.top = imgY + 'px'
#     overlayProjection = self.getProjection()
#     sw = overlayProjection.fromContainerPixelToLatLng(new (google.maps.Point)(imgX, imgY + img.offsetHeight))
#     ne = overlayProjection.fromContainerPixelToLatLng(new (google.maps.Point)(imgX + img.offsetWidth, imgY))
#     self.set 'sw', sw
#     self.set 'ne', ne

#   google.maps.event.addDomListener mouseTarget, 'mousedown', (e) ->
#     # Cancel the mousedown event to prevent dragging the map.
#     if e.stopPropagation
#       e.stopPropagation()
#     else if window.e
#       window.e.cancelBubble = true
#     self.set 'mouseX', e.clientX
#     self.set 'mouseY', e.clientY

#   google.maps.event.addDomListener mouseTarget, 'dragstart', (e) ->
#     self.set 'dragging', true

#   google.maps.event.addDomListener mouseTarget, 'dragleave', (e) ->
#     self.set 'dragging', false
#     self.updateBounds new (google.maps.LatLngBounds)(self.get('sw'), self.get('ne'))

# USGSOverlay::draw = ->
#   overlayProjection = @getProjection()
#   sw = overlayProjection.fromLatLngToDivPixel(@bounds_.getSouthWest())
#   ne = overlayProjection.fromLatLngToDivPixel(@bounds_.getNorthEast())
#   div = @div_
#   @set 'imgX', sw.x
#   @set 'imgY', ne.y

#   div.style.left = sw.x + 'px'
#   div.style.top = ne.y + 'px'
#   div.style.width = ne.x - (sw.x) + 'px'
#   div.style.height = sw.y - (ne.y) + 'px'

#   @mouseTarget_.style.left = div.style.left
#   @mouseTarget_.style.top = div.style.top
#   @mouseTarget_.style.width = div.style.width
#   @mouseTarget_.style.height = div.style.height

# USGSOverlay::updateBounds = (bounds) ->
#   @bounds_ = bounds
#   @draw()

# USGSOverlay::onRemove = ->
#   @div_.parentNode.removeChild @div_
#   @div_ = null
