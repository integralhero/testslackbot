require 'rubygems'
require 'sinatra'

get '/test' do
	"Hello World"
end

get '/activate-lorax' do
	puts "is this showing up?"
	require "loraxbot"
end