#!/usr/bin/ruby

require 'hiera'
require 'puppet'
require 'json'
require 'sinatra'
require 'time'

hiera = Hiera.new
Hiera.logger='noop'
Puppet.features.add(:root) { true }
Puppet.initialize_settings
# this can be :rest to use inventory service instead
Puppet::Node::Facts.indirection.terminus_class = :puppetdb
cache = {}
cache_time = 1800

get '/hiera/:_host/:_key/?:_resolution_type?' do
  scope = Puppet::Node::Facts.indirection.find(params[:_host])
  scope = scope.values if scope.is_a?(Puppet::Node::Facts)
  next [404, 'Host not found'] if scope == nil
  params.reject { |key, value| key.start_with? '_' }.each { |key, value| scope[key] = value }
  scope['environment'] ||= 'production'
  res = hiera.lookup(params[:_key], nil, scope, nil, params[:_resolution_type] ? params[:_resolution_type].to_sym : :priority)
  next [404, 'Key not found'] if res == nil
  out = res.to_json
  $? == 0 ? out : [500, out]
end

# This does a reverse lookup to see which node has a certain value
# it is quite slow but caches each value for cache_time seconds
get '/hiera_reverse/:key/:value/?:_resolution_type?' do |key,value,resolution_type|
  res = []
  Puppet::Node::Facts.indirection.search('').each do |node|
    cache[key] = {} unless cache.include? key
    unless cache[key].include? node and cache[key][node][:time] > Time.now.to_i - cache_time
      scope = Puppet::Node::Facts.indirection.find(node)
    scope = scope.values if scope.is_a?(Puppet::Node::Facts)
      next if scope == nil
      cache[key][node] = {
        :value => hiera.lookup(key, [], scope, nil, resolution_type ? resolution_type.to_sym : :priority),
        :time  => Time.now.to_i,
      }
    end
    res << node if cache[key][node][:value].include? value
  end
  JSON.generate(res)
end
