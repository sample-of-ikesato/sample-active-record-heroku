# -*- coding: utf-8 -*-
$LOAD_PATH << File.dirname(__FILE__)

require 'active_support/time'
require 'active_record'
require 'sinatra'
require 'sinatra/multi_route'
require 'eventmachine'
require 'pp'
require 'pg'
require 'open-uri'
require 'uri'
require 'json'

started_at = Time.now
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
class Counter < ActiveRecord::Base; end
counter = Counter.first
if counter.nil?
  counter = Counter.create(counter: 0)
end

def exit?
  sleep_time = [{start: "23:50", stop: "24:00"},
                {start: "00:00", stop: "06:30"}]
  Time.zone = "Asia/Tokyo"
  now = Time.now
  sleep_time.each do |sl|
    t1 = Time.parse(sl[:start])
    t2 = Time.parse(sl[:stop])
    if t1 <= now && now < t2
      return true
    end
  end
  false
end

EM::defer do
  loop do
    next if exit?

    sleep 3.minutes
    counter.counter += 1
    counter.save!

    # polling self to prevent sleep
    open("https://sample-active-record.herokuapp.com/heartbeat")
  end
end

get '/heartbeat' do
  "OK"
end

# For debug
get '/debug' do
  {counter: counter.counter, updated_at: counter.updated_at, stated_at: started_at}.to_json.to_s
end
