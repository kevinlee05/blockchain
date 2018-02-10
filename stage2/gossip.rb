require 'bundler/setup'
require 'sinatra'
require 'colorize'
require 'active_support/time'
require_relative 'client'
require_relative 'helpers'

PORT, PEER_PORT = ARGV.first(2)
set :port, PORT

STATE = ThreadSafe::Hash.new
update_state(PORT => nil)
update_state(PEER_PORT => nil)

MOVIES = File.readlines("movies.txt").map(&:chomp)
@favorite_movie = MOVIES.sample
@version_number = 0
puts "My favorite movie, now and forever, is #{@favorite_movie.green}!"

update_state(PORT => [@favorite_movie, @version_number])

every(8.seconds) do
    puts "screw #{@favorite_movie.red}, it's so cliche"
    @favorite_movie = MOVIES.sample
    @version_number += 1
    update_state(PORT => [@favorite_movie, @version_number])
    puts "My new favorite movie is #{@favorite_movie.green}"
end

ren

every(3.seconds) do
    STATE.dup.each_key do |peer_port|
        next if peer_port == PORT
        puts "Gossiping with #{peer_port}... blah blah"
        their_state = Client.gossip(peer_port, JSON.dump(STATE))
        update_state(JSON.parse(their_state))
    end
    render_state
end

# @param state
post '/gossip' do
    their_state = param['state']
    update_state(JSON.parse(their_state))
    JSON.dump(STATE)
end
