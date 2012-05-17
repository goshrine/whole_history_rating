#!/usr/bin/env ruby
require 'date'

module WholeHistoryRating

  class Base
  
    class UnstableRatingException < RuntimeError; end
  
    attr_accessor :players, :games
    
    def initialize(config = {})
      @config = config
      @config[:w2] ||= 300.0  # elo^2
      @games = []
      @players = {}
      @start_date = nil
    end
  
    def print_ordered_ratings
      players = @players.values.select {|p| p.days.count > 0}
      players.sort_by { |p| p.days.last.gamma }.each_with_index do |p,idx|
        if p.days.count > 0
          puts "#{p.name} => #{p.days.map(&:elo)}"
        end
      end
    end
  
    def log_likelihood
      score = 0.0
      @players.values.each do |p|
        unless p.days.empty?
          score += p.log_likelihood
        end
      end
      score
    end
  
    def player_by_name(name)
      players[name] || players[name] = Player.new(name, @config)
    end
    
    def create_game(options)
      if options['finished_at'].nil?
        puts "Skipping (not finished) #{options.inspect}"
        return nil
      end
      
      game_date = Date.parse(options['finished_at'])
    
      @start_date ||= game_date
    
      # Avoid self-played games (no info)
      if options['w_name'] == options['b_name']
        puts "Skipping (black name == white name ?) #{options.inspect}"
        return nil
      end
    
      day_num = (game_date - @start_date).to_i
    
      #puts "day num = #{day_num}"
    
      white_player = player_by_name(options['w_name'])
      white_player.id = options['w_id']
      black_player = player_by_name(options['b_name'])
      black_player.id = options['b_id']
      game = Game.new(day_num, white_player, black_player, options['winner'], options['handicap'], options['extras'])
      game.date = game_date
      game
    end
  
    def add_game(game)
      game.white_player.add_game(game)
      game.black_player.add_game(game)
      if game.bpd.nil?
        puts "Bad game: #{options.inspect} -> #{game.inspect}"
      end
      @games << game
      game
    end
  
    def run_one_iteration
      players.each do |name,player|
        player.run_one_newton_iteration
      end
    end
  end
end
