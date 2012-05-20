require 'rubygems'

module WholeHistoryRating

  VERSION = "0.1.2"

  STDOUT.sync = true

  ROOT = File.expand_path(File.dirname(__FILE__))

  %w[ base
      player
      game
      player_day
  ].each do |lib|
    require File.join(ROOT, 'whole_history_rating', lib)
  end

end
