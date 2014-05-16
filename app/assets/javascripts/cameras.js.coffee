$ ->
  $('img.live').on 'error', () ->
    console.log('Error loading camera image. Camera might be offline.')

  $('img.snap').each ->
    oldimg = $(this)
    $("<img />").attr('src', $(this).attr('data-proxy')).load () ->
      if not this.complete or this.naturalWidth is undefined or this.naturalWidth is 0
        console.log('broken image!')
      else
        oldimg.replaceWith($(this))
