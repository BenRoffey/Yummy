--[[
My first mod for Balatro!
Just getting the hang of card effects and the steamodded api.
Wish me luck!
]]

local food_jokers = {
    "j_gros_michel",
    "j_cavendish",
    "j_ramen",
    "j_seltzer",
    "j_diet_cola",
	"j_ice_cream",
	"j_egg",
	"j_turtle_bean",
	"j_popcorn",
	"j_yummy_chocolate",
	"j_yummy_pasta",
	"j_yummy_porridge",
	"j_yummy_curry",
	"j_yummy_pizza",
	"j_yummy_burrito",
	"j_yummy_soup"
}

local function food_lookup(key)
    for i, joker in ipairs(food_jokers) do
        if joker == key then
            return true
        end
    end
    return false
end

local function owns_joker(key)
    for _, j in ipairs(G.jokers.cards) do
        if j.config.center.key == key then
            return true
        end
    end
    return false
end

local function enhance(card, key)
	G.E_MANAGER:add_event(Event{
		trigger = "immediate",
		delay = initial,
		func = function()
			card:flip()
			return true
		end
	})
	G.E_MANAGER:add_event(Event{
		trigger = "after",
		delay = 0.1,
		func = function()
			card:set_ability(key)
			card:juice_up()
			card:flip()
			play_sound("tarot1")
			return true
		end
	})
end

--Atlases
SMODS.Atlas {
	key = "yummy",
	path = "yummy.png",
	px = 71,
    py = 95
}

SMODS.Atlas{
	key = "gordon",
	path = "gordon.png",
	px = 34,
	py = 34
}

SMODS.Joker {
	key = "chef",
	loc_txt = {
		name = "Chef",
		text = {
			"Creates a random {C:attention}food joker",
			"on round start"
		}
	},
	config = {},
	rarity = 2,
	discovered = true,
	atlas = "yummy",
	eternal_compat = true,
	pos = {x = 0, y = 0},
	cost = 3,
	calculate = function(self, card, context)
		if context.setting_blind and #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit then

			local attempts = #food_jokers
			local joker

			repeat
				joker = pseudorandom_element(food_jokers, "chef")
				attempts = attempts - 1
			until attempts <= 0 or not owns_joker(joker) or G.GAME.modifiers.showman


			G.E_MANAGER:add_event(Event({
                    func = function() 
                        local card = SMODS.add_card({set='Joker', area=G.jokers, key=joker})
                        return true
                    end}))   
		end
	end
}

SMODS.Joker {
	key = "chocolate",
	loc_txt = {
		name = "Chocolate",
		text = {
			"{X:mult,C:white}X#1#{} Mult",
			"Loses {X:mult,C:white}X#2#{} Mult per played hand"
		}
	},
	config = {extra = { mult = 6, loss = 1}},
	rarity = 1,
	discovered = true,
	atlas = "yummy",
	eternal_compat = false,
	pos = {x = 1, y = 0},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		return { vars = {card.ability.extra.mult, card.ability.extra.loss}}
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			local applied = card.ability.extra.mult

			if context.blueprint or context.other_joker or context.retrigger_joker then
				return {
					xmult = applied
				}
			end

			card.ability.extra.mult = card.ability.extra.mult - card.ability.extra.loss

			if card.ability.extra.mult <= 1 then
				SMODS.destroy_cards(card, nil, nil, true)
				return {
					xmult = applied,
					message = "Eaten!"
				}
			end
			
			return { 
				xmult = applied,
			}
		end
	end
}

SMODS.Joker {
	key = "pasta",
	loc_txt = {
		name = "Pasta",
		text = {
			"{X:mult,C:white}X#1#{} Mult",
			"Gains {X:mult,C:white}X#2#{} Mult per played hand",
			"Removed at the end of the round"
		}
	},
	config = {extra = { mult = 1, gain = 1}},
	rarity = 1,
	discovered = true,
	atlas = "yummy",
	eternal_compat = false,
	pos = {x = 2, y = 0},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		return { vars = {card.ability.extra.mult, card.ability.extra.gain}}
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			local applied = card.ability.extra.mult

			if context.blueprint or context.other_joker or context.retrigger_joker then
				return {
					xmult = applied
				}
			end

			card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.gain
			
			return { 
				xmult = applied,
			}
		end

		if context.end_of_round then
			if context.blueprint or context.other_joker or context.retrigger_joker then
				return {}
			end
			SMODS.destroy_cards(card, nil, nil, true)
			return {
				xmult = applied,
				delay = 0.2,
				message = "Eaten!"
			}
		end
	end
}

SMODS.Joker {
	key = "porridge",
	loc_txt = {
		name = "Porridge",
		text = {
			"{X:chips,C:white}X#1#{} Chips for each {C:attention}food joker{}",
			"{C:inactive}(Currently {X:chips,C:white}X#2#{C:inactive} Chips)"
		}
	},
	config = {extra = { perFoodJoker = 1, bonus = 0}},
	rarity = 1,
	discovered = true,
	atlas = "yummy",
	eternal_compat = false,
	pos = {x = 3, y = 0},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		if G.jokers then
			local x = 0
			for i = 1, #G.jokers.cards do
				if food_lookup(G.jokers.cards[i].config.center.key) then x = x + 1 end
			end
			card.ability.extra.bonus = x * card.ability.extra.perFoodJoker
		end
		return { vars = {card.ability.extra.perFoodJoker, card.ability.extra.bonus}}
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			local x = 0
			for i = 1, #G.jokers.cards do
				if food_lookup(G.jokers.cards[i].config.center.key) then x = x + 1 end
			end
			card.ability.extra.bonus = x * card.ability.extra.perFoodJoker
			return { 
				xchips = card.ability.extra.bonus,
			}
		end
	end
}

SMODS.Joker {
	key = "curry",
	loc_txt = {
		name = "Curry",
		text = {
			"{X:mult,C:white}X#1#{} Mult, loses {X:mult,C:white}X#2#{} Mult",
			"per {C:attention}card{} played"
		}
	},
	config = {extra = { xmult = 2, loss = 0.01}},
	rarity = 1,
	discovered = true,
	atlas = "yummy",
	eternal_compat = false,
	pos = {x = 4, y = 0},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		return { vars = {card.ability.extra.xmult, card.ability.extra.loss}}
	end,
	calculate = function(self, card, context)
		if context.individual and not context.blueprint then
			if (context.cardarea == G.play or context.cardarea == "unscored") then

				card.ability.extra.xmult = card.ability.extra.xmult - card.ability.extra.loss
				if card.ability.extra.xmult <= 1 then
					SMODS.destroy_cards(card, nil, nil, true)
					return {
						delay = 0.2,
						message = "Eaten!",
						message_card = card
					}
				end
				return{
				delay = 0.2,
				message = "-X0.01",
				colour = G.C.MULT,
				message_card = card
			}
			end
		end
		if context.joker_main then			
			return { 
				xmult = card.ability.extra.xmult,
			}
		end
	end
}

SMODS.Joker {
	key = "pizza",
	loc_txt = {
		name = "Pizza",
		text = {
			"Gives {C:mult}+#1#{} Mult for each",
			"owned {C:attention}consumable{}",
			"{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)"
		}
	},
	config = {extra = { mult = 12, current = 0}},
	rarity = 1,
	discovered = true,
	atlas = "yummy",
	eternal_compat = true,
	perishable_compat = true,
	pos = {x = 0, y = 1},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		local count = (G.consumeables and G.consumeables.cards and #G.consumeables.cards) or 0
		card.ability.extra.current = count * card.ability.extra.mult
		return { vars = {card.ability.extra.mult, card.ability.extra.current}}
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			local count = #G.consumeables.cards
			card.ability.extra.current = count * card.ability.extra.mult
			return {
				mult = count * card.ability.extra.mult
			}
		end
	end
}

SMODS.Joker {
	key = "burrito",
	loc_txt = {
		name = "Burrito",
		text = {
			"Each {C:attention}card held in",
			"{C:attention}hand{} gives {X:mult,C:white}X#1#{} Mult",
			"Reduced by {X:mult,C:white}X#2#{} each round"
		}
	},
	config = {extra = { xmult = 1.5, loss = 0.1}},
	rarity = 1,
	discovered = true,
	atlas = "yummy",
	eternal_compat = false,
	pos = {x = 1, y = 1},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult, card.ability.extra.loss}}
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.hand and not (context.cardarea == G.play or context.cardarea == "unscored") and not context.end_of_round then
			return {
				xmult = card.ability.extra.xmult
			}
		end
		if context.end_of_round and context.main_eval and not context.blueprint then
			card.ability.extra.xmult = card.ability.extra.xmult - card.ability.extra.loss
			if card.ability.extra.xmult <= 1 then
				SMODS.destroy_cards(card, nil, nil, true)
				return {
					delay = 0.2,
					message = "Eaten!",
					message_card = card
				}
			end
			return{
				delay = 0.2,
				message = "-X#2#",
				colour = G.C.MULT
			}
		end
	end
}

SMODS.Joker {
	key = "ego",
	loc_txt = {
		name = "Ego",
		text = {
			"Gains {C:money}$1{} for each",
			"{C:attention}food joker{} eaten",
			"{C:inactive}(Currently {C:money}$#1#{C:inactive})"
		}
	},
	config = {extra = { money = "$" , current = 0}},
	rarity = 1,
	discovered = true,
	atlas = "yummy",
	eternal_compat = false,
	pos = {x = 2, y = 1},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.current }}
	end,
	calc_dollar_bonus = function(self, card)
		if card.ability.extra.current > 0 then 
			return card.ability.extra.current
		end 
	end,
	calculate = function(self, card, context)
		if context.joker_type_destroyed then
			print("Card destroyed!")
			if context.cardarea == G.jokers then
				print(context.card.config.center.key)
				if food_lookup(context.card.config.center.key) then
					card.ability.extra.current = card.ability.extra.current + 1
					return{
						message = "Yum!",
						message_card = card
					}
				end
			end
		end
	end
}

SMODS.Joker {
	key = "soup",
	loc_txt = {
		name = "Soup",
		text = {
			"Every played {C:attention}card{} permanently gains",
			"{C:mult}+#1#{} Mult when scored",
			"{C:inactive}(Removed after {C:attention}#2#{C:inactive} cards)"
		}
	},
	config = {extra = { mult = 1, times = 25}},
	rarity = 1,
	discovered = true,
	atlas = "yummy",
	eternal_compat = false,
	pos = {x = 3, y = 1},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult, card.ability.extra.times}}
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.play then
			context.other_card.ability.perma_mult = context.other_card.ability.perma_mult or 0
			context.other_card.ability.perma_mult = context.other_card.ability.perma_mult + card.ability.extra.mult
			card.ability.extra.times = card.ability.extra.times - 1
			if card.ability.extra.times <= 0 then
				SMODS.destroy_cards(card, nil, nil, true)
				return {
					delay = 0.2,
					message = "Eaten!",
					message_card = card
				}
			 end
			return {
				message = localize('k_upgrade_ex'), 
				colour = G.C.MULT
			}
		end
	end
}

local function dump(o, indent, visited)
    indent = indent or ""
    visited = visited or {}

    if type(o) ~= "table" then
        print(indent .. tostring(o))
        return
    end

    if visited[o] then
        print(indent .. "<cycle>")
        return
    end
    visited[o] = true

    print(indent .. "{")
    for k, v in pairs(o) do
        local key = "[" .. tostring(k) .. "]"
        if type(v) == "table" then
            print(indent .. "  " .. key .. " = ")
            dump(v, indent .. "    ", visited)
        else
            print(indent .. "  " .. key .. " = " .. tostring(v))
        end
    end
    print(indent .. "}")
end


SMODS.Joker {
	key = "coffee",
	loc_txt = {
		name = "Coffee",
		text = {
			"{C:attention}Doubles{} base hand {C:Mult}Mult",
			"{C:money}-$#1#{} at the end of the round"
		}
	},
	config = {extra = { money = 3 }},
	rarity = 1,
	discovered = true,
	atlas = "yummy",
	eternal_compat = false,
	pos = {x = 4, y = 1},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.money }}
	end,
	calculate = function(self, card, context)
		if context.initial_scoring_step then

			local basemult = G.GAME.hands[context.scoring_name].mult

			if G.GAME.blind.loc_name == "The Flint" then
				return {
					mult = math.max(math.floor(basemult*0.5 + 0.5), 1)
				}
			end

			return{
				mult = basemult
			}
		end

		if context.end_of_round and context.main_eval and not context.blueprint then
			return {
				dollars = -card.ability.extra.money
			}
		end
	end
}


--Enhancements
SMODS.Enhancement {
    key = 'preheating',
    loc_txt = {
        name = "Preheating",
        text = {
            "{C:chips}+#1#{} Chips",
            "Becomes {C:attention}Underdone{}",
			"after being scored"
        }
    },
    atlas = 'yummy',
    pos = { x = 0, y = 2 },
    config = { extra = { chips = 15 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
    if context.main_scoring and context.cardarea == G.play then
        return 
		{
            chips = card.ability.extra.chips,
            message = "Underdone!",
			func = function()
				enhance(card, "m_yummy_underdone")
			end
        }
    end
end
}

SMODS.Enhancement {
    key = 'underdone',
    loc_txt = {
        name = "Underdone",
        text = {
            "{C:mult}+#1#{} Mult",
            "Becomes {C:attention}Cooked{}",
			"after being scored"
        }
    },
    atlas = 'yummy',
    pos = { x = 1, y = 2 },
    config = { extra = { mult = 3 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
		if context.main_scoring and context.cardarea == G.play then
			return 
			{
				print(card.ability.extra.mult),
				mult = card.ability.extra.mult,
				message = "Cooked!",
				func = function()
					enhance(card, "m_yummy_cooked")
				end
			}
		end
    end
}

SMODS.Enhancement {
    key = 'cooked',
    loc_txt = {
        name = "Cooked",
        text = {
            "{X:mult,C:white}X#1#{} Mult",
            "{C:green}#2# in #3#{} chance to",
			"be {C:red,E:2}destroyed{} after",
			"being scored"
        }
    },
    atlas = 'yummy',
    pos = { x = 2, y = 2 },
    config = { extra = { xmult = 1.5, odds = 6} },
    loc_vars = function(self, info_queue, card)
		local numerator = G.GAME.probabilities.normal
        return { vars = { card.ability.extra.xmult, numerator, card.ability.extra.odds} }
    end,
    calculate = function(self, card, context)
		if context.main_scoring and context.cardarea == G.play then
			if SMODS.pseudorandom_probability(card, "cooked_destroy", 1, card.ability.extra.odds) then
				return {
					xmult = card.ability.extra.xmult,
					message = "Burnt!",
					func = function()
						SMODS.destroy_cards(card, nil, nil, true)
					end
				}
			else
				return {
					xmult = card.ability.extra.xmult
				}
			end
		end
    end
}

--Consumeables
SMODS.Consumable {
    key = 'bakingtray',
    loc_txt = {
        name = 'Baking Tray',
        text = {
            "Enhances {C:attention}3{} selected",
            "cards to {C:attention}Preheating",
        }
    },
    set = 'Tarot',
    atlas = 'yummy',
    pos = { x = 3, y = 2 },
    discovered = true,
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS["m_yummy_preheating"]
		return {card.ability.max_highlighted}
    end,
	can_use = function(self, card)
		return G.hand and #G.hand.highlighted > 0 and #G.hand.highlighted <= 3
    end,
	use = function(self, card, area, copier)
		for i = 1, #G.hand.highlighted do
			enhance(G.hand.highlighted[i], "m_yummy_preheating")
		end
    end
}

SMODS.Consumable{
	key = "service",
	loc_txt = {
		name = "Service",
		text = {
			"Add a {C:green}Yummy Seal",
			"to {C:attention}1{} selected card",
			"in your hand"
		}
	},
	set = "Spectral",
	atlas = "yummy",
	pos = {x=4, y=2},
	discovered = true,
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS["yummy_yummyseal"]
		return {}
	end,
	can_use = function(self, card)
		return G.hand and #G.hand.highlighted == 1
    end,
	use = function(self, card, area, copier)
		local conv_card = G.hand.highlighted[1]

        G.E_MANAGER:add_event(Event({func = function()
            play_sound('tarot1')
            conv_card:juice_up(0.3, 0.5)
            return true end }))
        
        G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
            conv_card:set_seal("yummy_yummyseal", nil, true)
            return true end }))
        
        delay(0.5)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2,func = function() G.hand:unhighlight_all(); return true end }))
    end
}

--Boosters

local inpack = function(key, contents)
	for i = 1, #contents do
		if key == contents[i] then 
			return true 
		end
	end
	return false
end

SMODS.Booster{
	key = "appetizer",
	loc_txt = {
		name = "Appetizer Pack",
		text = {
			"Choose {C:attention}#1#{} of up to",
			"{C:attention}#2# Food Joker{} cards"
		},
		group_name = "Yummy!"
	},
	atlas = "yummy",
	pos = {x = 0, y = 3},
	discovered = true,
	config = { extra = 2, choose = 1, contents = {}},
	cost = 4,
	create_card = function(self, card, i)
		local attempts = #food_jokers
		local joker

		print("Joker", i)
		if i == 1 then
			repeat
				joker = pseudorandom_element(food_jokers, "appetizer")
				attempts = attempts - 1
			until attempts <= 0 or not owns_joker(joker) or G.GAME.modifiers.showman
			self.config.contents = {joker}
		else
			repeat
				joker = pseudorandom_element(food_jokers, "appetizer")
				attempts = attempts - 1
			until attempts <= 0 or (not owns_joker(joker) and not inpack(joker, self.config.contents)) or G.GAME.modifiers.showman
			self.config.contents[i] = joker
		end

		return {set = "Joker", area = G.pack_cards, key = joker, skip_materialize = true}
	end
}

SMODS.Booster{
	key = "alacarte",
	loc_txt = {
		name = "A la Carte Pack",
		text = {
			"Choose {C:attention}#1#{} of up to",
			"{C:attention}#2# Food Joker{} cards"
		},
		group_name = "Yummy!"
	},
	atlas = "yummy",
	pos = {x = 1, y = 3},
	discovered = true,
	config = { extra = 4, choose = 1, contents = {}},
	cost = 6,
	create_card = function(self, card, i)
		local attempts = #food_jokers
		local joker

		print("Joker", i)
		if i == 1 then
			repeat
				joker = pseudorandom_element(food_jokers, "alacarte")
				attempts = attempts - 1
			until attempts <= 0 or not owns_joker(joker) or G.GAME.modifiers.showman
			self.config.contents = {joker}
		else
			repeat
				joker = pseudorandom_element(food_jokers, "alacarte")
				attempts = attempts - 1
			until attempts <= 0 or (not owns_joker(joker) and not inpack(joker, self.config.contents)) or G.GAME.modifiers.showman
			self.config.contents[i] = joker
		end

		return {set = "Joker", area = G.pack_cards, key = joker, skip_materialize = true}
	end
}

SMODS.Booster{
	key = "2coursedeal",
	loc_txt = {
		name = "2 Course Deal Pack",
		text = {
			"Choose {C:attention}#1#{} of up to",
			"{C:attention}#2# Food Joker{} cards"
		},
		group_name = "Yummy!"
	},
	atlas = "yummy",
	pos = {x = 2, y = 3},
	discovered = true,
	config = { extra = 4, choose = 2, contents = {}},
	cost = 8,
	create_card = function(self, card, i)
		local attempts = #food_jokers
		local joker

		print("Joker", i)
		if i == 1 then
			repeat
				joker = pseudorandom_element(food_jokers, "2coursedeal")
				attempts = attempts - 1
			until attempts <= 0 or not owns_joker(joker) or G.GAME.modifiers.showman
			self.config.contents = {joker}
		else
			repeat
				joker = pseudorandom_element(food_jokers, "2coursedeal")
				attempts = attempts - 1
			until attempts <= 0 or (not owns_joker(joker) and not inpack(joker, self.config.contents)) or G.GAME.modifiers.showman
			self.config.contents[i] = joker
		end

		return {set = "Joker", area = G.pack_cards, key = joker, skip_materialize = true}
	end
}

--Blinds
local insults = {
	{"Where is the lamb sauce?!"},
	{"My gran can do better!","And she's dead!"},
	{"Why did the chicken","cross the road?","Because it wasn't","bloody cooked!"},
	{"This lamb is so undercooked,","it's following Mary to school!"},
	{"You Donkey!"}
}

function RawTextBox(text) 
	for k, v in ipairs(text) do
		print(k, v)
	end

	local row = {}
	for _, v in ipairs(text) do
		row[#row+1] = 
		{
			n=G.UIT.R, 
			config={align = "cm"}, 
			nodes = {
                {
                    n = G.UIT.T,
                    config = {
                        text = v,
                        colour = G.C.BLACK,
                        scale = 0.3
                    }
                }
            }
		}
	end
	local t = {n=G.UIT.ROOT, config = {align = "cm", minh = 1,r = 0.3, padding = 0.07, minw = 1, colour = G.C.JOKER_GREY, shadow = true}, nodes={
				{n=G.UIT.C, config={align = "cm", minh = 1,r = 0.2, padding = 0.1, minw = 1, colour = G.C.WHITE}, nodes={
					{n=G.UIT.C, config={align = "cm", minh = 1,r = 0.2, padding = 0.03, minw = 1, colour = G.C.WHITE}, nodes=row}
				}}
			}}
	return t
end

function PlaySpeech(n, last_said)
	if n <= 0 then 
		return 
	end

	local new_said = math.random(1, 11)
	while new_said == last_said do 
		new_said = math.random(1, 11)
	end
	play_sound('voice'..new_said, G.SPEEDFACTOR*(math.random()*0.2+1), 0.5)
	SMODS.juice_up_blind()
	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		blockable = false, blocking = false,
		delay = 0.13,
		func = function()
			PlaySpeech(n-1, new_said)
			return true
		end
	}))
end

function GordonSays(text, align)
	local ui_elem = G.GAME.blind

    if ui_elem.children.speech_bubble then 
		ui_elem.children.speech_bubble:remove() 
	end
	
    local speech_bubble_align = {align=align or 'bm', offset = {x=0,y=0},parent = ui_elem}
    ui_elem.children.speech_bubble = 
    UIBox{
        definition = RawTextBox(text),
        config = speech_bubble_align
    }
    ui_elem.children.speech_bubble:set_role{
        role_type = 'Minor',
        xy_bond = 'Weak',
        r_bond = 'Strong',
        major = ui_elem,
    }
    ui_elem.children.speech_bubble.states.visible = true
	PlaySpeech(5, 0)
end

SMODS.Blind{
	key = "gordon",
	loc_txt = {
		name = "Gordon",
		text = {
			"Insults you"
		}
	},
	atlas = "gordon",
	pos = {x = 0, y = 0},
	discovered = true,
	boss = {min = 1},
	dollars = 5,
    mult = 2,
	boss_colour = HEX("c3c3c3"),
	last_insult = {},
	second_last_insult = {},
	calculate = function(self, blind, context)
		if context.end_of_round and context.main_eval then
			GordonSays({"Finally!"}, "bm")

			local ui_elem = G.GAME.blind
			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				blockable = false, blocking = false,
				delay = 1,
				func = function()
					ui_elem.children.speech_bubble.states.visible = false
					return true
				end
			}))
		end
		if context.after then
			local insult
			
			repeat
				insult = pseudorandom_element(insults, "gordon")
			until insult ~= self.last_insult and insult ~= self.second_last_insult

			self.second_last_insult = self.last_insult
			self.last_insult = insult
			
			GordonSays(insult, "bm")

		end
		if context.drawing_cards then
			local ui_elem = G.GAME.blind
			if ui_elem.children.speech_bubble then ui_elem.children.speech_bubble.states.visible = false end
		end
	end
}

--Seals
SMODS.Seal{
	key = "yummyseal",
	loc_txt = {
		name = "Yummy Seal",
		text = {
			"{C:mult}+#1#{} Mult when",
			"{C:attention}held in hand",
			"Then, {C:red,E:2}destroyed{}"
		},
		label = "Yummy Seal"
	},
	atlas = "yummy",
	pos = {x = 4, y = 3},
	discovered = true,
	badge_colour = G.C.GREEN,
	config = {extra = {mult = 10}},
	loc_vars = function(self, info_queue, card)
		print(self.key)
        return { vars = { card.ability.seal.extra.mult } }
    end,
	sound = { sound = 'gold_seal', per = 1.2, vol = 0.4 },
	calculate = function(self, card, context)
		if context.main_scoring and context.cardarea == G.hand then
			return {
				mult = card.ability.seal.extra.mult,
				message = "Eaten!",
				func = function()
					SMODS.destroy_cards(card, nil, nil, true)
				end
			}
		end
	end
}
