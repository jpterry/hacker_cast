#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'eventmachine'
require 'em-websocket'
require 'json'

require 'securerandom'

module SignalDispatch
  class Client
    attr_reader :websocket, :pair
    def initialize(websocket)
      @websocket = websocket
      @queue = EM::Queue.new
    end

    def queue_message(msg)
      @queue.push(msg)
    end

    def forward_queue!
      @queue.pop do |msg|
        @pair.websocket.send(msg)
        forward_queue!
      end
    end

    def set_pair(other)
      @pair = other
      unless other.pair
        other.set_pair(self)
      end
      forward_queue!
      @pair
    end
  end

  class Signaller
    #singleton
    def self.instance
      @_instance ||= new
    end

    def self.start!
      EM.run do
        EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
          ws.onopen { |handshake| Signaller.instance.add_client(ws) }
          ws.onclose { Signaller.instance.remove_client(ws) }
          ws.onmessage { |msg| Signaller.instance.handle_message(ws, msg) }
        end
      end
    end

    def initialize
      @clients = {}
    end

    def add_client(ws)
      @clients[ws] = Client.new(ws)
      pair_if_possible(@clients[ws])
    end

    def remove_client(ws)
      @clients.delete(ws)
    end

    def handle_message(ws, msg)
      @clients[ws].queue_message(msg)
    end

    # PAIR EM UP
    def pair_if_possible(client)
      mate = @clients.reject { |k, v| v == client }.find { |k, v| v.pair.nil? }
      client.set_pair(mate[1]) if mate
    end
  end
end

SignalDispatch::Signaller.start!
