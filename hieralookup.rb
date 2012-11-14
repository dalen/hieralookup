#!/usr/bin/ruby

require 'hiera'
require 'puppet'
require 'json'
require 'sinatra'

hiera = Hiera.new(:config => File.join(Hiera::Util.config_dir, 'hiera.yaml'))
Puppet.initialize_settings
Puppet::Node::Facts.indirection.terminus_class = :rest

get '/hiera/:_host/:_key/?:_resolution_type?' do
  scope = YAML.load(Puppet::Node::Facts.indirection.find(params[:_host]).to_yaml)
  scope = scope.values if scope.is_a?(Puppet::Node::Facts)
  next [404, 'Host not found'] if scope == nil
  params.reject { |key, value| key.start_with? '_' }.each { |key, value| scope[key] = value }
  res = hiera.lookup(params[:_key], nil, scope, nil, params[:_resolution_type] ? params[:_resolution_type].to_sym : :priority)
  next [404, 'Key not found'] if res == nil
  out = JSON.generate(res)
  $? == 0 ? out : [500, out]
end
