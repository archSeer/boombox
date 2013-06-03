class window.Player
  constructor: ->
    @instance = new MediaElementPlayer('audio', {
      width: '100%',
      features: ['playpause','progress','current','duration','volume'],
      timeAndDurationSeparator: ' <span class="mejs-timeseparator"> / </span> ',
      success: (mediaElement, domObject) =>
        # keep track of the mediaElement object for additional callbacks
        #@mediaElement = mediaElement

        # Speed Up: Make elements and add their class the right way, but ugly.
        $('.mejs-volume-button button').append('<i class="icon-volume-up"></i><i class="icon-volume-off"></i>')
        $('.mejs-playpause-button button').append('<i class="icon-play"></i><i class="icon-pause"></i>')
        $('.mejs-stop-button button').append('<i class="icon-stop"></i>')
        $('.mejs-fullscreen-button button').append('<i class="icon-fullscreen"></i>')
        $('.mejs-unfullscreen-button button').append('<i class="icon-resize-small"></i>')
        $('.mejs-loop-button button').append('<i class="icon-repeat"></i>')

        # Setup basic event listeners
        mediaElement.addEventListener('pause', (=> @nowPlaying.replaceClass('playing', 'paused')), false)
        mediaElement.addEventListener('play', (=> @nowPlaying.replaceClass('paused', 'playing')), false)
        mediaElement.addEventListener('ended', (=> @playNextSong() ), false)
    })

    @mediaElement = @instance.media # alias

    Player.triggerCallbacks()

    @nowPlaying = undefined # Not sure how to track properly the nowPlaying row item, here?...
    # substitute @nowPlaying with $("#song-#{@songID}")?
    @songID = undefined
    @tempEventListeners = []
    return true

  # This is ...weird
  @_callbacks = []
  @executeOnLoad: (func) ->
    if !Boombox?
      @_callbacks.push func
    else
      func.call(Boombox)

  @triggerCallbacks: ->
    while @_callbacks.length isnt 0
      @_callbacks.shift().call(Boombox)
  # weird END

  addEventListener: (type, listener, useCapture) ->
    @instance.media.addEventListener type, listener, useCapture

  # Allows us to register a set of event listeners which we can then remove by calling unloadTempEventListeners()
  registerTempEventListener: (type, listener, useCapture) ->
    @tempEventListeners.push {type: type, listener: listener, useCapture: useCapture}
    @addEventListener(type, listener, useCapture)

  unloadTempEventListeners: ->
    $(@tempEventListeners).each (index, el) =>
      @instance.media.removeEventListener(el.type, el.listener, el.useCapture)

  play: ->
    @instance.play()

  pause: ->
    @instance.pause()

  setSrc: (src) ->
    @instance.setSrc(src)

  setCurrentTime: (t) ->
    @instance.setCurrentTime(t)

  isPlaying: ->
    !@instance.media.paused

  playSong: (e) -> # e is a row in the list of songs
    $.get "api/track/#{$(e).attr('id')}", (data) =>
      @pause()
      @setSrc("/#{data.filename}")
      $("#player")[0].load()
      @play()
      @songID = $(e).attr 'id'
      @nowPlaying.removeClass('playing paused') if @nowPlaying
      @nowPlaying = e.addClass 'playing'
      $('#now-playing .cover img').attr 'src', data.cover

  playNextSong: ->
    @playSong @nowPlaying.next()


  registerHooks: ->
    icon = $('#player-buttons .playpause i')

    # addEventListener doesn't work for FF... WTF?
    @addEventListener('play', ->
      icon.removeClass('icon-play').addClass('icon-pause')
    , false)
    @addEventListener('playing', ->
      icon.removeClass('icon-play').addClass('icon-pause')
    , false)

    @addEventListener('pause', ->
      icon.removeClass('icon-pause').addClass('icon-play')
    , false)
    @addEventListener('paused', ->
      icon.removeClass('icon-pause').addClass('icon-play')
    , false)

    playButton = $('#player-buttons .playpause')

    playButton.click (e) =>
      e.preventDefault()

      if @isPlaying()
        @pause()
      else
        @play()
