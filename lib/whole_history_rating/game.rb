module WholeHistoryRating
  class Game
    attr_accessor :day, :white_player, :black_player, :handicap, :winner, :wpd, :bpd, :extras
  
    def initialize(black, white, winner, time_step, handicap, extras)
      @day = time_step
      @white_player = white
      @black_player = black
      @winner = winner
      @extras = extras
      @handicap = handicap || 0
      @handicap_proc = handicap.is_a?(Proc) ? handicap : nil
    end
  
    def opponents_adjusted_gamma(player)
      black_advantage = @handicap_proc ? @handicap_proc.call(self) : @handicap   
      #puts "black_advantage = #{black_advantage}"
      
      if player == white_player
        opponent_elo = bpd.elo + black_advantage
      elsif player == black_player
        opponent_elo = wpd.elo - black_advantage
      else
        raise "No opponent for #{player.inspect}, since they're not in this game: #{self.inspect}."
      end
      rval = 10**(opponent_elo/400.0)
      if rval == 0 || rval.infinite? || rval.nan?
        raise UnstableRatingException, "bad adjusted gamma: #{inspect}"
      end
      rval
    end
    
    def opponent(player)
      if player == white_player
        black_player
      elsif player == black_player
        white_player
      end
    end
  
    def prediction_score
      if white_win_probability == 0.5
        0.5
      else
        ((winner == "W" && white_win_probability > 0.5) || (winner == "B" && white_win_probability < 0.5)) ? 1.0 : 0.0
      end
    end
  
    def inspect
      "#{self}: W:#{white_player.name}(r=#{wpd ? wpd.r : '?'}) B:#{black_player.name}(r=#{bpd ? bpd.r : '?'}) winner = #{winner}, komi = #{@komi}, handicap = #{@handicap}"
    end
  
    #def likelihood
    #  winner == "W" ? white_win_probability : 1-white_win_probability
    #end
  
    # This is the Bradley-Terry Model
    def white_win_probability
      wpd.gamma/(wpd.gamma + opponents_adjusted_gamma(white_player))
    end
  
    def black_win_probability
      bpd.gamma/(bpd.gamma + opponents_adjusted_gamma(black_player))
    end
  
  end
end
