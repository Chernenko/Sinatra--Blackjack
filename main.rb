require 'rubygems'
require 'sinatra'


set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_HIT_MIN = 17

before do
  @show_hit_or_stay_buttons =true
  @dealer_turn = false
  @dealers_first_card = false
  @play_again =false
end

helpers do
  def calculate_total(cards)
    #calculate_total(session[:dealer_cards]) => number
    #calculate_total(session[:player_cards])
    arr = cards.map{|element|element[1]}
    total=0
    arr.each do|value|
      if value =="A"
        total+=11
      elsif value.to_i == 0 #face cards
        total += 10
      else
        total += value.to_i
      end
    end
    #correct for Aces
    arr.select{|val| val =="A"}.count.times do  #account for multiple aces
      total -=10 if total >21  #make ace worth 1 if total > 21

    end
    total
  end

  def card_image(card) #array like ['H','3']
    suit =  case card[0]
              when 'H' then 'hearts'
              when 'D' then 'diamonds'
              when 'C' then 'clubs'
              when 'S' then 'spades'
            end
    value = card[1]
    if ['J','Q','K','A'].include?(value)
      value = case card[1]
                when 'J' then 'jack'
                when 'K' then 'king'
                when 'Q' then 'queen'
                when 'A' then 'ace'
              end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'/>"
  end

  def calculate_for_player
    if calculate_total(session[:player_cards]) == BLACKJACK_AMOUNT
      @success = "#{session[:player_name]} got a BLACKJACK!!"
      @show_hit_or_stay_buttons =false
      @play_again =true
    elsif calculate_total(session[:player_cards]) > BLACKJACK_AMOUNT
      @error = " #{session[:player_name]} loses, it looks like #{session[:player_name]} busted at #{calculate_total(session[:player_cards])}."
      @show_hit_or_stay_buttons =false
      @play_again =true
    end
  end

  def calculate_for_dealer
    if calculate_total(session[:dealer_cards]) == BLACKJACK_AMOUNT
      @error ="#{session[:player_name]} loses, dealer got a BLACKJACK!"
      @dealer_turn=false
      @play_again =true
    elsif calculate_total(session[:dealer_cards]) > BLACKJACK_AMOUNT
      @success = "#{session[:player_name]} winn , dealer got busted at #{calculate_total(session[:dealer_cards])}."
      @dealer_turn=false
      @play_again =true
    elsif calculate_total(session[:dealer_cards]) >= DEALER_HIT_MIN
      redirect '/game/compare'
    end
  end

  def compare_hands
    if calculate_total(session[:dealer_cards])> calculate_total(session[:player_cards])
      @error = " #{session[:player_name]} loses, dealer win!  #{session[:player_name]} stayed at #{calculate_total(session[:player_cards])} and  the dealer stayed at #{calculate_total(session[:dealer_cards])}. "
      @play_again =true
    elsif calculate_total(session[:dealer_cards])<calculate_total(session[:player_cards])
      @success = " Congratulation,#{session[:player_name]}, Win! #{session[:player_name]} stayed at #{calculate_total(session[:player_cards])} and  the dealer stayed at #{calculate_total(session[:dealer_cards])}."
      @play_again =true
    elsif calculate_total(session[:dealer_cards])== calculate_total(session[:player_cards])
      @success = "It's a tie! Both #{session[:player_name]} the dealer stayed at calculate_total(session[:dealer_cards])."
      @play_again =true
    end
  end

end

get '/' do
  if session[:player_name]
    redirect'/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/set_name' do
  if  params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end
  session[:player_name]=params[:player_name]
  session[:dealer_name]= "Dealer"
  redirect '/game'
end

get'/game' do
  session[:values]= ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
  session[:suits]=['C','D','H','S']
  session[:deck]= session[:suits].product(session[:values])
  session[:deck].shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  calculate_for_player

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  calculate_for_player

  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons =false
  @dealer_turn = true
  @dealers_first_card = true
  calculate_for_dealer
  erb :game

end

post '/game/dealer/hit' do
  @show_hit_or_stay_buttons =false
  @dealer_turn = true
  @dealers_first_card = true
  session[:dealer_cards] << session[:deck].pop
  calculate_for_dealer
  erb :game
end

get '/game/compare' do
  @dealers_first_card = true
  @show_hit_or_stay_buttons = false
  @dealer_turn = false
  compare_hands
  erb :game
end

get'/game_over' do
  erb :game_over
end

