loaded_project = null
map = null
is_set_map_center = false
upload = null;
uploadIsRunning = false;

initMap = ->
  mapOptions =
    zoom: 19
    center: new (google.maps.LatLng)(0, 0)
  map = new (google.maps.Map)(document.getElementById('mapping_container'), mapOptions)
  if loaded_project.overlays.length > 0
    $.each loaded_project.overlays, (index, overlay) ->
      load_overlay(overlay)

load_overlay = (prj_overlay) ->
  swBound = new (google.maps.LatLng)(prj_overlay.sw_bounds.lat, prj_overlay.sw_bounds.lng)
  neBound = new (google.maps.LatLng)(prj_overlay.ne_bounds.lat, prj_overlay.ne_bounds.lng)
  bounds = new (google.maps.LatLngBounds)(swBound, neBound)
  map.setCenter(swBound)

  srcImage = prj_overlay.path
  overlay = new USGSOverlay(prj_overlay.id, bounds, srcImage, map)
  overlay = overlay.l

  markerA = new (google.maps.Marker)(
    position: swBound
    icon: 'https://maps.google.com/mapfiles/kml/pal4/icon57.png'
    flat: true
    map: map
    draggable: true
    raiseOnDrag: false)

  markerB = new (google.maps.Marker)(
    position: neBound
    icon: 'https://maps.google.com/mapfiles/kml/pal4/icon57.png'
    map: map
    flat: true
    draggable: true
    raiseOnDrag: false)

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
    update_overlay(overlay.overlay_id, newPointA, newPointB)

  google.maps.event.addListener markerB, 'dragend', ->
    newPointA = markerA.getPosition()
    newPointB = markerB.getPosition()
    update_overlay(overlay.overlay_id, newPointA, newPointB)

addCamera = (camera) ->
  destinations = []
  markers = []
  o_lat = 0

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

  point1 = new (google.maps.LatLng)(add_subtract(camera.location.lat, 0.000100), add_subtract(camera.location.lng, 0.000500))
  point2 = new (google.maps.LatLng)(camera.location.lat - 0.000060, add_subtract(camera.location.lng, 0.000500))
  point = new (google.maps.LatLng)(camera.location.lat, camera.location.lng)

  destinations.push point
  destinations.push point1
  destinations.push point2
  if is_set_map_center is false
    map.setCenter(point)

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
  # if camera.location.lat is object_location_lat
  o_lat = point1.lat() - object_diff
  o_lng = point1.lng()
  # else
    # o_lat = object_location_lat
    # o_lng = object_location_lng
  marker_options.position = new (google.maps.LatLng)(o_lat, o_lng)
  marker_options.draggable = true
  marker_options.icon = "https://maps.google.com/mapfiles/ms/micons/man.png"
  object = new (google.maps.Marker)(marker_options)
  google.maps.event.addListener(object, 'drag', bind_rotate_event(polygon, 0.5));

add_subtract = (value, value2) ->
  return value + value2

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

bind_projects = ->
  $.each Evercam.Projects, (index, project) ->
    create_project_table_row(index, project)

create_project_table_row = (index, project)->
  row = $("<tr>")
  cell = $("<td>", {class: "col-md-5"})
  a = $("<a>")
  a.attr("href", "javascript:;")
  a.addClass("load_project")
  a.attr("data-val", index)
  a.append(document.createTextNode("#{project.name}"))
  cell.append(a)
  row.append(cell)

  cell = $("<td>", {class: "col-md-2"})
  cell.append(document.createTextNode(project.camera_ids.length))
  row.append(cell)

  cell = $("<td>", {class: "col-md-3"})
  cell.append(document.createTextNode(moment(project.created_at).format("YYYY/MM/DD")))
  row.append(cell)

  cell = $("<td>", {class: "col-md-1"})
  i = $("<i>", {class: "fas"})
  i.addClass("fa-trash-alt delete-project")
  cell.append(i)
  row.append(cell)

  $(".projects_table > tbody:last-child").append(row)

load_project = ->
  $(".projects_table").on "click", ".load_project", ->
    if $(this).hasClass("disabled-link")
      $('#projects-list-modal').modal('hide')
    else
      index = parseInt($(this).attr("data-val"))
      loaded_project = Evercam.Projects[index]
      $("#lnkProject").text("Projects - #{loaded_project.name}")
      initMap()
      load_cameras()
      $('#projects-list-modal').modal('hide')
      $(".load_project").removeClass("disabled-link")
      $(this).addClass("disabled-link")

load_cameras = ->
  $.each loaded_project.camera_ids, (index, camera) ->
    addCamera(camera)

onFileSelect = ->
  $('input[type="file"]').change (e) ->
    if e.target.files.length > 0
      fileName = e.target.files[0].name
      fileType = e.target.files[0].type
      $('#btn_file_upload').removeAttr("disabled")
    else
      $('#btn_file_upload').attr("disabled", "disabled")

  $("#btn_file_upload").on "click", ->
    input = document.querySelector("#file-upload")
    if upload
      if uploadIsRunning
        upload.abort()
        $("#btn_file_upload").html("Upload")
        uploadIsRunning = false
      else
        upload.start()
        $("#btn_file_upload").html('<i class="fas fa-sync fa-spin"></i>')
        uploadIsRunning = true
    else
      startUpload()

startUpload = ->
  file = document.querySelector('input[type="file"]').files[0]
  if !file
    return

  $("#btn_file_upload").html('<i class="fas fa-sync fa-spin"></i>')

  options =
    endpoint: Evercam.TUS_URL
    resume: true
    chunkSize: Infinity
    retryDelays: [0, 1000, 3000, 5000]
    onError: (error) ->
      console.log error
      # Notification.error("Failed because: #{error}")
      reset()
    onProgress: (bytesUploaded, bytesTotal) ->
      percentage = (bytesUploaded / bytesTotal * 100).toFixed(2)
    onSuccess: ->
      save_overlay(upload.url, upload.file.name, file.type)
      reset()

  upload = new tus.Upload(file, options)
  upload.start()
  uploadIsRunning = true

reset = ->
  $("#btn_file_upload").html("Upload")
  upload = null
  uploadIsRunning = false

save_overlay = (file_url, filename, fileType) ->
  image_name = file_url.slice (file_url.lastIndexOf('/') - 1 >>> 0) + 2
  lnglat = map.getCenter()

  data =
    image_name: image_name
    sw_lat: lnglat.lat() - 0.0005000
    sw_lng: lnglat.lng() - 0.0005000
    ne_lat: lnglat.lat() + 0.0005000
    ne_lng: lnglat.lng() + 0.0005000
    file_url: file_url
    fileType: fileType
    file_extension: filename.slice (filename.lastIndexOf('.') - 1 >>> 0) + 2
    api_id: Evercam.User.api_id
    api_key: Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    if jqXHR.status is 500
      Notification.error("Internal Server Error. Please contact to admin.")
    else
      Notification.error(jqXHR.responseJSON.message)

  onSuccess = (data, status, jqXHR) ->
    reset()
    $("#add-floorplan-modal").modal('hide')
    $("#file-upload").val("")
    load_overlay(data)

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'POST'
    url: "#{Evercam.API_URL}projects/#{loaded_project.id}/overlay"
  $.ajax(settings)

update_overlay = (overlay_id, sw_lnglat, ne_lnglat) ->
  data =
    sw_lat: sw_lnglat.lat()
    sw_lng: sw_lnglat.lng()
    ne_lat: ne_lnglat.lat()
    ne_lng: ne_lnglat.lng()
    api_id: Evercam.User.api_id
    api_key: Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    if jqXHR.status is 500
      Notification.error("Internal Server Error. Please contact to admin.")
    else
      Notification.error(jqXHR.responseJSON.message)

  onSuccess = (data, status, jqXHR) ->
    true

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'PATCH'
    url: "#{Evercam.API_URL}projects/#{loaded_project.id}/overlay/#{overlay_id}"
  $.ajax(settings)

create_project = ->
  $(".create-project").on "click", ->
    data =
      name: "New Project"
      api_id: Evercam.User.api_id
      api_key: Evercam.User.api_key

    onError = (jqXHR, status, error) ->
      if jqXHR.status is 500
        Notification.error("Internal Server Error. Please contact to admin.")
      else
        Notification.error(jqXHR.responseJSON.message)

    onSuccess = (data, status, jqXHR) ->
      project = data.projects[0]
      Evercam.Projects.push(project)
      create_project_table_row(Evercam.Projects.length, project)

      loaded_project = project
      $("#lnkProject").text("Projects - #{loaded_project.name}")
      initMap()
      load_cameras()
      $('#projects-list-modal').modal('hide')
      $(".load_project").removeClass("disabled-link")
      # $(this).addClass("disabled-link")

    settings =
      cache: false
      data: data
      dataType: 'json'
      error: onError
      success: onSuccess
      type: 'POST'
      url: "#{Evercam.API_URL}projects"
    $.ajax(settings)

window.initializeProjects = ->
  Notification.init(".bb-alert")
  bind_projects()
  load_project()
  map_height = Metronic.getViewPort().height - $(".nav-tabs").height()
  $("#mapping_container").height(map_height - 16)
  onFileSelect()
  loaded_project = Evercam.Projects[0]
  $("#lnkProject").text("Projects - #{loaded_project.name}")
  initMap()
  load_cameras()
  create_project()

USGSOverlay = (overlay_id, bounds, image, map) ->
  @overlay_id = overlay_id
  @bounds_ = bounds
  @image_ = image
  @map_ = map
  @div_ = null
  @setMap map
  @set 'dragging', true
  @addListener 'dragging_changed', ->
    dragging = @get('dragging')
    map.setOptions 'draggable': !dragging

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
