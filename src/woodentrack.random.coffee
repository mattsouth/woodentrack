###
Ideas for random:
builder can randomly select next piece or what connection to add it to
constraints can be based on boundary, mix of pieces and number of allowed loose connections
1. completely random. unbounded
1a. completely random but with weights for occurance of pieces.
2. completely random. bounded by box. pieces cannot be added that break the boundary.  start in middle of box.
2a. completely random. bounded by box. pieces can break boundary but after each iteration remove section if boundary broken.
###

addRandom = (track, num) ->
	[1..num].forEach ->
		# which new piece
		type = Math.floor(Math.random()*6)
		# -1 or 1
		flip = 2*Math.round(Math.random())-1
		switch type
			when 0
				piece = new Straight
			when 1
				piece = new Bend { flip : flip }
			when 2
				piece = new Split { flip : flip }
			when 3
				piece = new Merge { flip : flip }
			when 4
				piece = new Join { flip : flip }
			when 5
				piece = new Crossover { flip : flip }
		# which connection
		connections = track.connections()
		if connections.length==0
			console.log 'random adding', piece
			track.add piece
		else
			connection = connections[Math.floor(Math.random()*connections.length)]
			console.log 'random connecting', piece, connection
			track.connect piece, connection

root = exports ? window
root.addRandom = addRandom
