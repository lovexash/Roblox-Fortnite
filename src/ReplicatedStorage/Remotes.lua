-- Aura RNG | Remotes
-- Single source of truth for every remote's name and type. The server creates
-- them; the client looks them up. `true` means RemoteFunction, else RemoteEvent.

return {
	-- name              isFunction
	UpdateProfile      = false, -- server -> client: full profile snapshot
	Notify             = false, -- server -> client: toast message
	RollRequest        = false, -- client -> server: please roll
	RollResult         = false, -- server -> client: aura you got (+isNew)
	EquipAura          = false, -- client -> server: equip aura id
	DeleteAura         = false, -- client -> server: sell/delete aura id (qty)
	BuyPotion          = false, -- client -> server: buy potion id
	BuyCapsule         = false, -- client -> server: buy capsule id (coins path)
	PromptProduct      = false, -- client -> server: prompt a Robux purchase
	GlobalCounts       = true,  -- client -> server (RF): get "exists" counts
	-- Trading
	TradeRequest       = false, -- client -> server: invite userId to trade
	TradeInvite        = false, -- server -> client: incoming invite
	TradeRespond       = false, -- client -> server: accept/decline invite
	TradeUpdate        = false, -- server -> client: current trade window state
	TradeOffer         = false, -- client -> server: add/remove aura from offer
	TradeConfirm       = false, -- client -> server: toggle confirm
	TradeCancel        = false, -- client -> server: cancel trade
}
