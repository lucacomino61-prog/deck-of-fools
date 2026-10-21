class_name ContentPacks
extends RefCounted
## Registers every approved card batch, always in this order. Shop pools follow
## registration order, so changing the order changes what a seed produces:
## add new packs at the end.


static func register_all() -> void:
	ContentDB.reset()
	SignCards.register()       # batch 1
	ZanniBatch01.register()    # batch 1
	DeckMods.register()        # batch 2
	TarocchiCards.register()   # batch 2
	ZanniBatch03.register()    # batch 3
	ZanniBatch04.register()    # batch 4
	ZanniBatch05.register()    # batch 5
	ZanniBatch06.register()    # batch 6
	ZanniBatch07.register()    # batch 7
	ZanniBatch08.register()    # batch 8
	OmenCards.register()       # batch 9
	WarrantCards.register()    # batch 9
	PackDefs.register()        # batch 9
	PatronCards.register()     # batch 10
	FavorCards.register()      # batch 10
	DeckCards.register()       # batch 11
	StakeCards.register()      # batch 11
	ChallengeCards.register()  # batch 11
