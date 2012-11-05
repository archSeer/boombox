class window.Player
  constructor: ->
    @instance = new MediaElementPlayer('audio', {
      audioWidth: '100%',
      features: ['playpause','progress','current','duration','volume'],
      timeAndDurationSeparator: ' <span class="mejs-timeseparator"> / </span> ',
      success: (mediaElement, domObject) =>
        # keep track of the mediaElement object for additional callbacks
        @mediaElement = mediaElement

        # Setup basic event listeners
        @addEventListener('pause', (=> @nowPlaying.replaceClass('playing', 'paused')), false)
        @addEventListener('play', (=> @nowPlaying.replaceClass('paused', 'playing')), false)
        @addEventListener('ended', (=> @playNextSong() ), false)
    })

    @nowPlaying = undefined # Not sure how to track properly the nowPlaying row item, here?...
    # substitute @nowPlaying with $("#song-#{@songID}")
    @songID = undefined
    @tempEventListeners = []
    return true

  addEventListener: (type, listener, useCapture) ->
    @mediaElement.addEventListener type, listener, useCapture

  # Allows us to register a set of event listeners which we can then remove by calling unloadTempEventListeners()
  registerTempEventListener: (type, listener, useCapture) ->
    @tempEventListeners.push {type: type, listener: listener, useCapture: useCapture}
    @addEventListener(type, listener, useCapture)

  unloadTempEventListeners: ->
    $(@tempEventListeners).each (index, el) =>
      @mediaElement.removeEventListener(el.type, el.listener, el.useCapture)

  play: ->
    @instance.play()

  pause: ->
    @instance.pause()

  setSrc: (src) ->
    @instance.setSrc(src)

  isPlaying: ->
    !@mediaElement.paused

  playSong: (e) -> # e is a row in the list of songs
    $.post 'ajax/track', { track_id: $(e).attr('id') }, (data) => # => means this points to the previous value of this
      @pause()
      @setSrc(data.track)
      @play()
      @songID = $(e).attr 'id'
      @nowPlaying.removeClass('playing paused') if @nowPlaying
      @nowPlaying = e.addClass 'playing'

  playNextSong: ->
    @playSong @nowPlaying.next()