#!/usr/bin/ruby

# Geocode via Google API
# Add your API key to a .geokey file

require 'json'
require 'cgi'
require 'colorize'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '/tmp/open-uri'

key = File.read('.geokey') or die "Need a .geokey file"

address = ARGV.join(" ")
abort "Usage: #{$0} <address>" if address.empty?

def api_fetch (params)
  qs = params.map{|k,v| [CGI.escape(k.to_s), "=", CGI.escape(v.to_s)]}.map(&:join).join("&")
  url = "https://maps.googleapis.com/maps/api/geocode/json?#{qs}"
  JSON.parse(open(url).read)
end

response = api_fetch(:address => address, :key => key)
abort "Failed: #{response['status']}" unless response['status'] == 'OK'

# { "place": "Palo Alto, California", "region": "US-CA", "coordinates": { "lat": "37.429167", "lon": "-122.138056" } },
response['results'].each do |result|
  warn result['address_components'].select { |ac| ac['types'].include?('political') }.map { |ac| ac['short_name'] }.reverse.join(" → ").yellow

  region = %w(country administrative_area_level_1).map { |level|
    r = result['address_components'].find { |ac| ac['types'].include?(level) }
    r.nil? ? '' : r['short_name']
  }.join("-")
  geo = result['geometry']['location']
  puts %Q(  { "place": "#{address}", "region": "#{region}", "coordinates": { "lat": "#{geo['lat']}", "lon": "#{geo['lng']}" } },)
end

