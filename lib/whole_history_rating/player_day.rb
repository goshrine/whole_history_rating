
module WholeHistoryRating
  class PlayerDay
    attr_accessor :won_games, :lost_games, :name, :day, :player, :r, :is_first_day, :uncertainty
    def initialize(player, day)
      @day = day
      @player = player
      @is_first_day = false
      @won_games = []
      @lost_games = []
    end
  
    def gamma=(gamma)
      @r = Math.log(gamma)
    end
  
    def gamma
      Math.exp(@r)
    end
  
    def elo=(elo)
      @r = elo * (Math.log(10)/400.0)
    end
  
    def elo
      (@r * 400.0)/(Math.log(10))
    end
  
    def clear_game_terms_cache
      @won_game_terms = nil
      @lost_game_terms = nil
    end
  
    def won_game_terms
      if @won_game_terms.nil?
        @won_game_terms = @won_games.map do |g|
          other_gamma = g.opponents_adjusted_gamma(player)
          if other_gamma == 0 || other_gamma.nan? || other_gamma.infinite?
            puts "other_gamma (#{g.opponent(player).inspect}) = #{other_gamma}"
          end
          [1.0,0.0,1.0,other_gamma]
        end
        if is_first_day
          @won_game_terms << [1.0,0.0,1.0,1.0]  # win against virtual player ranked with gamma = 1.0
        end
      end
      @won_game_terms
    end
  
    def lost_game_terms
      if @lost_game_terms.nil?
        @lost_game_terms = @lost_games.map do |g|
          other_gamma = g.opponents_adjusted_gamma(player)
          if other_gamma == 0 || other_gamma.nan? || other_gamma.infinite?
            puts "other_gamma (#{g.opponent(player).inspect}) = #{other_gamma}"
          end
          [0.0,other_gamma,1.0,other_gamma]
        end
        if is_first_day
          @lost_game_terms << [0.0,1.0,1.0,1.0]  # loss against virtual player ranked with gamma = 1.0
        end
      end
      @lost_game_terms
    end    
  
    def log_likelihood_second_derivative
      sum = 0.0
      (won_game_terms + lost_game_terms).each do |a,b,c,d|
        sum += (c*d) / ((c*gamma + d)**2.0)
      end 
      if gamma.nan? || sum.nan?
        puts "won_game_terms = #{won_game_terms}"
        puts "lost_game_terms = #{lost_game_terms}"
      end
      -1 * gamma * sum
    end

    def log_likelihood_derivative    
      tally = 0.0
      (won_game_terms + lost_game_terms).each do |a,b,c,d|
        tally += c/(c*gamma + d)
      end 
      won_game_terms.count - gamma * tally
    end
  
    def log_likelihood
      tally = 0.0
      won_game_terms.each do |a,b,c,d|
        tally += Math.log(a*gamma)
        tally -= Math.log(c*gamma + d)
      end
      lost_game_terms.each do |a,b,c,d|
        tally += Math.log(b)
        tally -= Math.log(c*gamma + d)
      end
      tally
    end
  
    def add_game(game)
      if (game.winner == "W" && game.white_player == @player) ||
         (game.winner == "B" && game.black_player == @player)
        @won_games << game
      else
        @lost_games << game
      end
    end

    def update_by_1d_newtons_method
      dlogp = log_likelihood_derivative
      d2logp = log_likelihood_second_derivative
      dr = (log_likelihood_derivative / log_likelihood_second_derivative)
      new_r = @r - dr
      #new_r = [0, @r - dr].max
      #puts "(#{player.name}) #{new_r} = #{@r} - (#{log_likelihood_derivative}/#{log_likelihood_second_derivative})"
      @r = new_r
    end
  
  end
end