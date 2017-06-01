#!/usr/bin/env ruby

require 'aws-sdk'
require 'rubygems'
require 'eventmachine'
require 'faye/websocket'
require 'json'
require 'uri'

WEBSOCKET_URI = ARGV[0]
WEBSOCKET_HOSTNAME = URI.parse(WEBSOCKET_URI).host
STREAM_NAME = 'tootsearch'
client = Aws::Firehose::Client.new(region: 'us-west-2')

EM.run do
  conn = Faye::WebSocket::Client.new(WEBSOCKET_URI)
  total_messages = 0
  update_messages = 0

  conn.on :open do |e|
    puts "#{Time.now} WebSocket::open #{WEBSOCKET_URI}"
  end

  conn.on :error do |e|
    puts "#{Time.now} WebSocket::error #{WEBSOCKET_URI}"
  end

  conn.on :close do |e|
    puts "#{Time.now} WebSocket::close #{WEBSOCKET_URI}"
  end

  conn.on :message do |msg|
    msg_json = JSON::parse(msg.data.to_s)
    total_messages += 1

    case msg_json["event"]
    when "update" then
      payload = msg_json["payload"]
      client.put_record({ delivery_stream_name: STREAM_NAME, record: { data: payload } })

      update_messages += 1
    end
  end

  EM.add_periodic_timer(60) {
    puts "#{Time.now} #{WEBSOCKET_HOSTNAME} messages total:#{total_messages} update:#{update_messages}"
    STDOUT.flush
  }
end
