###
Ideas for random:
builder can randomly select next piece or what connection to add it to
constraints can be based on boundary, mix of pieces and number of allowed loose connections
1. completely random. unbounded
2. completely random. bounded by box. pieces cannot be added that break the boundary.
todo: variation - completely random but with weights for occurance of pieces.
todo: variation - pieces can break boundary but after each iteration remove section if boundary broken.
###

addRandom = (track, num, bounds=null) ->

	# find connection idx that doesnt create collision
	getFreeConnection = (type, flip, connections) ->
		piece = createPiece type, flip
		if connections.length==0
			null
		else
			idx = Math.floor(Math.random()*connections.length)
			trackclone = track.clone()
			trackclone.connect piece, connections[idx]
			if !trackclone.hasCollision()
				if !bounds? or bounds?.overlaps(piece._bbox)
					return connections[idx]
				else
					connections.splice idx, 1
					getFreeConnection type, flip, connections
			else
				connections.splice idx, 1
				getFreeConnection type, flip, connections

	createPiece = (type, flip) ->
		switch type
			when 0,6,8,13,15,16
				new Straight
			when 1,7,9,14
				new Bend { flip : flip }
			when 2,10
				new Split { flip : flip }
			when 3,11
				new Merge { flip : flip }
			when 4,12
				new Join { flip : flip }
			when 5
				new Crossover { flip : flip }

	[1..num].forEach ->
		# which new piece
		type = Math.floor(Math.random()*17)
		# -1 or 1
		flip = 2*Math.round(Math.random())-1
		# which connection
		if track.pieces().length==0
			track.add createPiece(type, flip)
		else
			connection = getFreeConnection type, flip, track.connections()
			if connection?
				track.connect createPiece(type,flip), connection
				if track.hasCollision()
					@stopGenerator()

startGenerator = (track, bounds=null) ->
	@generator = setInterval ->
			addRandom(track, 1, bounds)
		, 100

stopGenerator = () ->
	clearInterval @generator

root = exports ? window
root.addRandom = addRandom
root.startGenerator = startGenerator
root.stopGenerator = stopGenerator
