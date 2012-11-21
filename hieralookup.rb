#!/usr/bin/ruby

require 'hiera'
require 'puppet'
require 'json'
require 'sinatra'

hiera = Hiera.new
Hiera.logger='noop'
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
  out = JSON.generate(res)
  $? == 0 ? out : [500, out]
end
