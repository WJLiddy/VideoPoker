require 'ruby-poker'

def deck_inst()
	cards = []
	["2","3","4","5","6","7","8","9","T","J","Q","K","A"].each do |r|
		["H","S","C","D"].each do |s|
			cards << r+s
		end
	end
	return cards.shuffle
end

def is_hi?(card)
	["J","Q","K","A"].each do |d|
		return true if card.include?(d)
	end
	return false
end

def rank_only(hand)
	return hand.map{|h| h[0]}
end

def suit_only(hand)
	return hand.map {|h| h[1]}
end

def pair_jacks?(hand)
	["J","Q","K","A"].each do |r|
		count = 0
		hand.each do |c|
			count += 1 if c.include?(r)
			return true if count == 2
		end
	end
	return false
end

def evaluate_hand(hand)
	r = PokerHand.new(hand).rank
	rank = r.inspect.to_str.gsub("\"","") # what a mess
	return 250 if rank == "Royal Flush"
	return 50 if rank == "Straight Flush"
	return 25 if rank == "Four of a kind"
	return 9 if rank == "Full house"
	return 6 if rank == "Flush"
	return 4 if rank == "Straight"
	return 3 if rank == "Three of a kind"
	return 2 if rank == "Two pair"
	return 1 if rank == "Pair" && pair_jacks?(hand)
	return 0 if rank == "Pair"
	return 0 if rank == "Highest Card"
	return nil
end

def flush_finish(hand)
	hs = suit_only(hand)
	hs.each_with_index do |card,index|
		return [index] if (hs.count(card) == 1)
	end
	throw RuntimeError
end

def try_flush_finish(hand)
	hs = suit_only(hand)
	hs.each_with_index do |card,index|
		return flush_finish(hand) if (hs.count(card) == 4)
	end
	return nil
end

def keep_lp(hand)
	rank = PokerHand.new(hand).rank
	discard = []
	handrank = rank_only(hand)
	if rank == "Pair" 
		handrank.each_with_index do |h, i|
			discard << i if (handrank.count(h) == 1)
		end
	end
	return discard == [] ? nil : discard
end


# Pass - a winning hand (pairs or better)
# Returns - which cards you should exchange to keep the winning hand. 
def exhange_worthless(hand)
	r = PokerHand.new(hand).rank
	rank = r.inspect.to_str.gsub("\"","") # what a mess
	return [] if rank == "Royal Flush"
	return [] if rank == "Straight Flush"
	return [] if rank == "Four of a kind"
	return [] if rank == "Full house"
	return [] if rank == "Flush"
	return [] if rank == "Straight"

	discard = []
	handrank = rank_only(hand)

	if rank == "Three of a kind"
		handrank.each_with_index do |h, i|
			discard << i if (handrank.count(h) < 3)
		end
	end

	if rank == "Two pair"
		handrank.each_with_index do |h, i|
			discard << i if (handrank.count(h) == 1)
		end
	end

	if rank == "Pair" 
		handrank.each_with_index do |h, i|
			discard << i if (handrank.count(h) == 1)
		end
	end
	return discard
end

# 30%
def strategy_trashall(hand)
	return [0,1,2,3,4]
end

# 60%
def strategy_keepwin(hand)
	return [] if evaluate_hand(hand) > 0
	return [0,1,2,3,4]
end

# Exchange worthless cards in winning hands, and keep hi on failure. 80%
def strategy_ew(hand)
	# Keep good hand with exchanges
	if (evaluate_hand(hand) > 1)
		return exhange_worthless(hand)
	end

	discard = []
	# Keep high cards
	5.times do |d|
		discard << d if !is_hi?(hand[d])
	end
	return discard
end

# Same as above, but try to finish flushes and straights. Also, keep low pairs over high cards.
# 95%.
def strategy_fslp(hand)
	# Keep good hand with exchanges
	if (evaluate_hand(hand) > 1)
		return exhange_worthless(hand)
	end

	# Attempt to finish flushes
	ff = try_flush_finish(hand)
	return ff if !ff.nil?

	# Keep low pairs.
	lp = keep_lp(hand)
	return lp if !lp.nil?

	# Attempt to finish outside straights.

	discard = []
	# Keep high cards
	5.times do |d|
		discard << d if !is_hi?(hand[d])
	end
	return discard
end


def sim_hand()
	# New deck, New hand
	deck = deck_inst()
	hand = []
	5.times{hand << deck.pop}
	# Check what to discard.
	discards = strategy_fslp(hand)
	# Discard them, deal new cards.
	hand.size
	discards.each{|d| hand[d] = nil}
	# Remove all the nils.
	# filter not working, or remove_if????
	new_hand = []
	hand.map{|d| new_hand << d if !d.nil?}
	#get payout
	while new_hand.size < 5 do 
		new_hand << deck.pop
	end
	return evaluate_hand(new_hand)
end


def sim(trials)
	total = 0
	trials.times {total += (sim_hand() - 1.0)}
	return 1 + (total / trials)  
end


puts(sim(100000))


# trashall ~ 30%
# keep win ~ 60%
# keep win. If no win, keep hi ~ 70%