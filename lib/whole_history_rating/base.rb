#!/usr/bin/env ruby

module WholeHistoryRating

  class UnstableRatingException < RuntimeError; end

  class Base
  
    attr_accessor :players, :games
    
    def initialize(config = {})
      @config = config
      @config[:w2] ||= 300.0  # elo^2
      @games = []
      @players = {}
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
    
    def ratings_for_player(name)
      player = player_by_name(name)
      player.days.map {|d| [d.day, d.elo.round, (d.uncertainty*100).round]}
    end
    
    def setup_game(black, white, winner, time_step, handicap, extras = {})
          
      # Avoid self-played games (no info)
      if black == white
        raise "Invalid game (black player == white player)"
        return nil
      end
    
      white_player = player_by_name(white)
      black_player = player_by_name(black)
      game = Game.new(black_player, white_player, winner, time_step, handicap, extras)
      game
    end
    
    def create_game(black, white, winner, time_step, handicap, extras = {})
      game = setup_game(black, white, winner, time_step, handicap, extras)
      add_game(game)
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
    
    def iterate(count)
      count.times { run_one_iteration }
      players.each do |name,player|
        player.update_uncertainty
      end 
      nil    
    end
  
    def run_one_iteration
      players.each do |name,player|
        player.run_one_newton_iteration
      end
    end
  end
end
