require 'test/unit'
require 'whole_history_rating'

class WholeHistoryRatingTest < Test::Unit::TestCase
  
  def setup
    @whr = WholeHistoryRating::Base.new
  end
    
  def setup_game_with_elo(white_elo, black_elo, handicap)
    game = @whr.create_game("black", "white", "W", 1, handicap)
    game.black_player.days[0].elo = black_elo
    game.white_player.days[0].elo = white_elo
    game
  end
  
  def test_even_game_between_equal_strength_players_should_have_white_winrate_of_50_percent
    game = setup_game_with_elo(500, 500, 0)
    assert_in_delta 0.0001, 0.5, game.white_win_probability
  end

  def test_handicap_should_confer_advantage
    game = setup_game_with_elo(500, 500, 1)
    assert game.black_win_probability > 0.5
  end

  def test_higher_rank_should_confer_advantage
    game = setup_game_with_elo(600, 500, 0)
    assert game.white_win_probability > 0.5
  end
  
  def test_winrates_are_equal_for_same_elo_delta
    game = setup_game_with_elo(100, 200, 0)
    game2 = setup_game_with_elo(200, 300, 0)
    assert_in_delta 0.0001, game.white_win_probability, game2.white_win_probability
  end

  def test_winrates_for_twice_as_strong_player
    game = setup_game_with_elo(100, 200, 0)
    assert_in_delta 0.0001, 0.359935, game.white_win_probability
  end

  def test_winrates_should_be_inversely_proportional_with_unequal_ranks
    game = setup_game_with_elo(600, 500, 0)
    assert_in_delta 0.0001, game.white_win_probability, 1-game.black_win_probability
  end
  
  def test_winrates_should_be_inversely_proportional_with_handicap
    game = setup_game_with_elo(500, 500, 4)
    assert_in_delta 0.0001, game.white_win_probability, 1-game.black_win_probability
  end
    
  def test_output
    @whr.create_game("shusaku", "shusai", "B", 1, 0)
    @whr.create_game("shusaku", "shusai", "W", 2, 0)
    @whr.create_game("shusaku", "shusai", "W", 3, 0)
    @whr.create_game("shusaku", "shusai", "W", 4, 0)
    @whr.create_game("shusaku", "shusai", "W", 4, 0)
    @whr.iterate(50)
    assert_equal [[1, -92, 71], [2, -94, 71], [3, -95, 71], [4, -96, 72]], @whr.ratings_for_player("shusaku")
    assert_equal [[1, 92, 71], [2, 94, 71], [3, 95, 71], [4, 96, 72]], @whr.ratings_for_player("shusai")
  end
end

