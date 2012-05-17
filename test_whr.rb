#!/usr/bin/env ruby

require 'whr'

input = <<RESULTS
"pedro" - "goldie" - 0 6.5 W 2010-11-06
"pedro" - "goldie" - 0 6.5 W 2010-11-06
"pedro" - "goldie" - 0 6.5 W 2010-11-06
"goldie" - "tom" - 0 6.5 W 2010-11-06
"goldie" - "tom" - 9 6.5 W 2010-11-06
"goldie" - "tom" - 0 6.5 W 2010-11-06
"goldie" - "tom" - 0 6.5 W 2010-11-06
"tom" - "pedro" - 0 6.5 W 2010-11-06
"tom" - "pedro" - 0 6.5 W 2010-11-06
"tom" - "pedro" - 0 6.5 W 2010-11-06
RESULTS

whr = WHR.new({:w2 => 12, :h => 25, :debug => false})
whr.read_games(input)

pday = whr.players["pedro"].days[0]
gday = whr.players["goldie"].days[0]

#def gamma_to_elo(gamma)
#  (Math.log(gamma) * 400.0)/(Math.log(10))
#end

#whr.games.each do |g|
#  g.wpd.elo = 25
#  puts "game = #{g.inspect}: wwp = #{g.white_win_probability} bwp = #{g.black_win_probability}"
#end

#(0..250).each do |r|
#  pday.gamma = Math.exp(r/10.0)
#  puts "#{r/10.0} #{pday.log_likelihood} #{pday.log_likelihood_derivative} #{pday.log_likelihood_second_derivative}"
#end
#pday.gamma = Math.exp(0)


5.times do 
  puts "log_likelihood = #{whr.log_likelihood}"
  whr.run_one_iteration
  $stdout.flush
end

whr.print_ordered_ratings
