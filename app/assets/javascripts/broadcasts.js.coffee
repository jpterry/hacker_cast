# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

#= require web_rtc_polyfill

#Using google's ICE server.
PEER_CONNECTION_CONF = {"iceServers": [{"url": "stun:stun.l.google.com:19302"}]}

SDP_CONSTRAINTS = {'mandatory': {'OfferToReceiveAudio':true, 'OfferToReceiveVideo':true}}


class Caller
  constructor: ->
    @client_id = window.HC.client_id
    @socket = new WebSocket("ws://localhost:8080/tx/#{window.HC.room_id}/#{@client_id}")
    @socket.onopen = ->
      console.log('websocket open')
    @socket.onmessage = (msg) =>
      data = JSON.parse(msg.data)
      console.log("GOT DATA:#{msg.data}")
      switch data.type
        when 'ice'
          @peer_connection.addIceCandidate(new RTCIceCandidate(data.candidate)) if @peer_connection
        when 'client_waiting'
          @to_client_id = data.client_id
          @send_video()
        when 'answer'
          console.log(data)
          console.log(@peer_connection.locaStreams)
          @peer_connection.setRemoteDescription(new RTCSessionDescription(data), ((success_callback)=> console.log(@peer_connection.localStreams[0])), ((err_msg)-> console.log("error setting remote sdp for caller: #{err_msg}")))


  attach_stream_to_view: (stream) ->
    video_out = document.querySelector('#outbound')
    console.log(stream)
    video_out.src = window.URL.createObjectURL(stream)

  got_user_media: (stream) =>
    @media_stream = stream
    @attach_stream_to_view(stream)

  setup_video: ->
    getUserMedia({audio: true, video: true}, @got_user_media)

  initiate_broadcast: =>
    @peer_connection = new RTCPeerConnection(PEER_CONNECTION_CONF)
    @peer_connection.onicecandidate = @ice_callback
    @peer_connection.addStream(@media_stream)
    @peer_connection.createOffer(@got_description)

  ice_callback: (event) =>
    if event.candidate
      console.log('found caller ice candidate')
      console.log(event)
      ice_msg = 
        type: 'ice'
        candidate: event.candidate
      console.log(JSON.stringify(ice_msg))
      @socket.send(JSON.stringify(ice_msg))

  got_description: (desc) =>
    @peer_connection.setLocalDescription(desc)
    offer =
      type: 'offer'
      sdp: desc.sdp
      room: @room_id
      from: @client_id
    @socket.send(JSON.stringify(offer))

  send_video: ->
    getUserMedia({audio: true, video: true}, ((stream) =>
      @media_stream = stream
      @peer_connection.addStream(stream)
      @attach_stream_to_view(stream)
      @peer_connection.createOffer(((sdp) =>
        console.log("Generated sdp: #{sdp.sdp}")
        @peer_connection.setLocalDescription(sdp)
        sdp.to = @to_client_id
        sdp.from = @client_id
        @socket.send(JSON.stringify(sdp))
      ), ((failure_msg) ->
        console.log("Failed to setLocalDescription: #{failure_msg}")
      ))), (failure_msg) ->
        console.log("Failed to getUserMedia: #{failure_msg}"))

class Callee
  constructor: ->
    @client_id = window.HC.client_id
    @socket = new WebSocket("ws://localhost:8080/tx/#{window.HC.room_id}/#{@client_id}")
    @socket.onopen = ->
      console.log("Callee connected to signal socket")
    @socket.onmessage = (msg) =>
      console.log(msg)
      parsed = JSON.parse(msg.data)
      console.log(parsed)
      switch parsed.type
        when 'offer'
          @handle_offer(parsed)
        when 'ice'
          @peer_connection.addIceCandidate(new RTCIceCandidate(parsed.candidate)) if @peer_connection
        else
          console.log("trashing msg:")
          console.log(parsed)

  ice_callback: (event) =>
    console.log 'callee ice callback'
    console.log event
    if event.candidate
      @socket.send(JSON.stringify({candidate: event.candidate, type: 'ice'}))

  handle_offer: (offer)=>
    @peer_connection = new RTCPeerConnection(PEER_CONNECTION_CONF)
    @peer_connection.onicecandidate = @ice_callback
    @peer_connection.onaddstream = @got_remote_stream
    @peer_connection.setRemoteDescription(new RTCSessionDescription(offer))
    create_answer_success = (answer_sdp) =>
      @peer_connection.setLocalDescription(answer_sdp)
      @socket.send(JSON.stringify(answer_sdp))

      @peer_connection.createAnswer(create_answer_success, null, SDP_CONSTRAINTS)

  got_remote_stream: (stream) =>
    @media_stream = stream.stream
    console.log('got remote stream')
    console.log(stream)
    document.querySelector('#inbound').src = webkitURL.createObjectURL(stream.stream)


  recv_remote_sdp: (signal) =>
    @peer_connection.setRemoteDescription(new RTCSessionDescription(signal), (event) =>
      create_answer_success = (answer_sdp) =>
        answer_sdp.from = @client_id
        answer_sdp.to   = @to_client_id
        @peer_connection.setLocalDescription(answer_sdp)
        myjson = JSON.stringify(answer_sdp)
        console.log("answering with: #{myjson}")
        @socket.send(myjson)

      create_answer_failure = (failure) =>
        console.log("Setting Local SDP from remote failed: #{failure}")

      
      @peer_connection.createAnswer(create_answer_success, create_answer_failure, SDP_CONSTRAINTS)
    )

class HackerCast
  init: ->
    @room_id = $('meta[name=room_id]').attr('content')
    @client_id = $('meta[name=client_id]').attr('content')

  init_caller: ->
    window.Caller = new Caller
    window.Caller.setup_video()

  init_callee: ->
    window.Callee = new Callee


$ ->
  window.HC = new HackerCast
  window.HC.init()
