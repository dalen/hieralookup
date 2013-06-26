#!/usr/bin/ruby

require 'uri'
require 'hiera'
require 'puppet'
require 'puppet/util/puppetdb'
require 'puppet/network/http_pool'
require 'json'
require 'sinatra'
require 'time'

hiera = Hiera.new
Hiera.logger='noop'
Puppet.features.add(:root) { true }
Puppet.initialize_settings
# this can be :rest to use inventory service instead
Puppet::Node::Facts.indirection.terminus_class = :puppetdb

get '/hiera/:_host/:_key/?:_resolution_type?' do
  scope = Puppet::Node::Facts.indirection.find(params[:_host])
  scope = scope.values if scope.is_a?(Puppet::Node::Facts)
  next [404, 'Host not found'] if scope == nil
  params.reject { |key, value| key.start_with? '_' }.each { |key, value| scope[key] = value }
  scope['environment'] ||= 'production'
  res = hiera.lookup(params[:_key], nil, scope, nil, params[:_resolution_type] ? params[:_resolution_type].to_sym : :priority)
  next [404, 'Key not found'] if res == nil
  out = { 'value' => res }.to_json
  $? == 0 ? out : [500, out]
end

# Get all specified facts for all hosts
def fetchfacts (facts)
  factquery = facts.collect { |fact| "[\"=\", \"name\", \"#{fact}\"]" }.join ', '
  query = URI.escape("?query=[\"or\", #{factquery}]")
  conn = Puppet::Network::HttpPool.http_instance(Puppet::Util::Puppetdb.server, Puppet::Util::Puppetdb.port, use_ssl = true)
  response = conn.get("/v2/facts#{query}", { "Accept" => "application/json",})
  unless response.kind_of?(Net::HTTPSuccess)
    raise Puppet::ParseError, "PuppetDB query error: [#{response.code}] #{response.msg}: #{query}"
  end
  PSON.load(response.body)
end

# Get facts for a host and return it as a hash
def hostfacts(host, facts)
  ret = {}
  facts.select { |fact| fact['certname'] == 'host' }.each do
    ret[fact['name']] = fact['value']
  end
  ret
end

# Get a list of hosts from the fact query
def hostlist(facts)
  facts.collect { |fact| fact['certname'] }.uniq
end

# This does a reverse lookup to see which node has a certain value
# it is quite slow but caches each value for cache_time seconds
get '/hiera_reverse/:key/:value/?:_resolution_type?' do |key,value,resolution_type|
  facts = fetchfacts(['fqdn', 'service', 'spenvironment', 'service_pool', 'lsbdistcodename', 'domain', 'site', 'environment'])
  res = []

  hostlist(facts).each do |node|
    scope = hostfacts(node, facts)
    res << node if hiera.lookup(key, [], scope, nil, resolution_type ? resolution_type.to_sym : :priority).include? value
  end
  JSON.generate(res)
end
