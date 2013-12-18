# a track is an observable / drawable model of a woooden train track comprising
# multiple pieces of different types connected together
# TODO: make observable
class Track
	constructor: (options={}) ->
		@gridSize = options.gridSize ? 100
		@trackWidth = options.trackWidth ? 16
		@trackColor = options.trackColor ? "lightgrey"
		@trackGap = options.trackGap ? 1
		@gapTransform = new Transform(@trackGap, 0, 0)
		@railColor = options.railColor ? "white"
		@railWidth = options.railWidth ? 2
		@railGauge = options.railGauge ? 9
		@showConnections = options.showConnections ? false
		@sections = []

	draw: (painter) ->
		@sections.forEach (section) ->
			section.draw painter

	# available connection codes
	connections: ->
		result = []
		offset = 0
		@sections.forEach (section) ->
			section.connections().forEach (code) ->
				[index, letter] = code.split ':'
				result.push (parseInt(index)+offset).toString()+":"+letter
			offset+=section.pieces.length
		result

	# all pieces
	pieces: ->
		result = []
		@sections.forEach (section) ->
			result = result.concat section.pieces
		result

	# Add piece to track.  Use start to specify starting transform,
	# else the last exit connection or default transform is used
    # for the first piece.
	# TODO: check piece connections for collisions and bail if there are any
	add: (piece, start = null) ->
		section =
			if start?
				@createSection start
			else
				if @sections.length>0
					@sections[@sections.length-1]
				else
					@createSection()
		piece.setSection section

	# connect piece to available connection identified from code, e.g. "10:C"
	connect: (piece, code) ->
		if @connections().indexOf(code)>-1
			# check through each of the section exits before creating a new section
			added=false
			@sections.forEach (section) =>
				last = section.pieces[section.pieces.length-1]
				lastExit = (@sectionStartingIndex(section)+section.pieces.length-1)+":"+last.exit
				if lastExit == code
					added=true
					piece.setSection section
			if !added
				section = @createSection @connection(code)
				piece.setSection section
				@connection(code).connected = piece.connections['A']
				piece.connections['A'].connected = @connection(code)
		else
			throw new Error(code + " is not an available connection")

	# remove indexed piece from track
	remove: (index) ->
		[sectionIndex, pieceIndex] = @getSectionAndPieceIndex index
		@sections[sectionIndex].remove(pieceIndex)

	getSectionAndPieceIndex: (index) ->
		result = [-1,-1]
		sectionIdx=0
		@sections.forEach (section) ->
			if index<section.pieces.length
				result = [sectionIdx, index]
			else
				index-=section.pieces.length
				sectionIdx++
		result

	sectionStartingIndex: (section) ->
		result=0
		[@sections.indexOf(section)...0].forEach (idx) =>
			result+=@sections[idx].pieces.length
		result

	# get Connection transform/connected field from connection code, e.g. "0:A"
	connection: (code) ->
		[index, letter] = code.split ':'
		[sectionIndex, sectionPieceIndex] = @getSectionAndPieceIndex index
		@sections[sectionIndex].pieces[sectionPieceIndex].connections[letter]

	createSection: (transform = null) ->
		section = new Section(this, transform)
		@sections.push section
		return section

	# find and seal any closable loops
	closeLoops: ->
		loose = @connections()
		[0...loose.length].forEach (idx1) =>
			[(idx1+1)...loose.length].forEach (idx2) =>
				trans1 = @transform(loose[idx1])
				trans2 = @transform(loose[idx2]).compound(@gapTransform)
				if transformsMeet trans1, trans2
					@connection(loose[idx1]).connected = loose[idx2]
					@connection(loose[idx2]).connected = loose[idx1]
					@closeLoops # recurse in case there are more to find

	# transform of connection wrt to track origin
	transform: (code) ->
		[index, label] = code.split ':'
		[sectionIndex, sectionPieceIndex] = @getSectionAndPieceIndex index
		@sections[sectionIndex].compoundTransform sectionPieceIndex, label

	# a section is an observable / drawable unbroken run of pieces used by a track
	# to help keep a record of loose connections and reduce the number of cached
	# transforms
	class Section
		constructor: (@track, @transform = new Transform(0,0,0)) ->
			@pieces = []

		add: (piece) ->
			if @pieces.length>0 and @connections().length==0
				throw new Error("No available connections on this section")
			num_pieces = @pieces.length # NB this is also the new index
			section_offset = @track.sectionStartingIndex this
			piece.section = this
			# connect existing exit connection to new piece's connection A
			if @exit?
				@exit.connected = piece.connections['A']
				piece.connections['A'].connected = @exit
			# update section exit connection
			@exit = piece.connections[piece.exit]
			@pieces.push piece
			return piece

		# remove idx piece and tie up loose connections
		remove: (idx) ->
			if typeof(idx)!="number"
				idx = @pieces.indexOf idx
			num_pieces = @pieces.length
			if idx>=0 and idx<num_pieces
				# deal with section connections
				removee = @pieces[idx]
				if num_pieces>1
					if idx<(num_pieces-1)
						@pieces[idx+1].connections['A'].connected=removee.connections['A'].connected
					if idx>0
						@pieces[idx-1].connections[@pieces[idx-1].exit].connected=removee.connections[removee.exit].connected
					removee.connections['A'].connected=null
					removee.connections[removee.exit].connected=null
				else
					@exit=null
				# TODO: deal with any other track connections attached to this one
				# set removee piece section to null
				@pieces[idx].section=null
				# remove piece
				@pieces.splice idx, 1
			else
				throw new Error("Cannot remove piece " + idx + " from section with " + @pieces.length + " pieces")

		# all available (unconnected) connection codes
		connections: ->
			result = []
			start = @transform
			[0...@pieces.length].forEach (idx) =>
				for label, connection of @pieces[idx].connections
					result.push idx.toString() + ":" + label if !connection.connected
			result

		# return transform associated with the nth piece's connection
		compoundTransform: (n, connection) ->
			start = @transform
			[0...n].forEach (pieceIndex) =>
				start = start.compound(@pieces[pieceIndex].exitTransform()).compound(@track.gapTransform)
			start.compound(@pieces[n].connections[connection])

		draw: (painter) ->
			start = @transform
			@pieces.forEach (piece) =>
				piece.draw painter, start
				start = start.compound(piece.exitTransform()).compound(@track.gapTransform)

# a transform is used to move/rotate coordinate axes
class Transform
	constructor: (@translateX, @translateY, @rotateDegs) ->
		@rotateRads = @rotateDegs*Math.PI/180

	# return compounded transform
	compound: (transform) ->
		new Transform @translateX + Math.cos(@rotateRads)*transform.translateX-Math.sin(@rotateRads)*transform.translateY,
			@translateY + Math.sin(@rotateRads)*transform.translateX+Math.cos(@rotateRads)*transform.translateY,
			(360+@rotateDegs+transform.rotateDegs)%360

	toString: ->
		return "("+@translateX+", "+@translateY+", "+@rotateDegs+")"

# an extended Transform with a connected attribute that refers to another connection
class Connection extends Transform
	constructor: (@translateX, @translateY, @rotateDegs) ->
		super @translateX, @translateY, @rotateDegs
		@connected = null

# Abstract track piece
# @connections define the transforms associated with each connection on the piece
# They each have an alphabetic label and by convention, label 'A' is always the first to be attached
# and is the origin to which the other connection transforms refer to.
class Piece
	constructor: (options={}) ->
		@size = options.size ? 2/3
		@angle = options.angle ? Math.PI/4
		@radius = options.radius ? 1
		@exit = options.exit ? 'B'
		@flip = options.flip ? 1
		@connections = { 'A' : new Connection(0, 0, -180) }
		@section = null

	setSection: (section) ->
		if @section?
			@section.remove this
		section.add this

	exitTransform: ->
		@connections[@exit]

class Straight extends Piece
	setSection: (section) ->
		@connections['B'] = new Connection(@size*section.track.gridSize, 0, 0)
		super
		section.track.closeLoops this

	draw: (painter, start) ->
		painter.drawStraight start, @.size

class Bend extends Piece
	setSection: (section) ->
		@connections['B'] = new Connection(Math.sin(@angle)*section.track.gridSize, @flip*(1-Math.cos(@angle))*section.track.gridSize, @flip*@angle*180/Math.PI)
		super
		section.track.closeLoops this

	draw: (painter, start) ->
		painter.drawBend start, start.compound(@exitTransform()), @flip

class Split extends Piece
	setSection: (section) ->
		@connections['B'] = new Connection(@size*section.track.gridSize, 0, 0)
		@connections['C'] = new Connection(Math.sin(@angle)*section.track.gridSize, @flip*(1-Math.cos(@angle))*section.track.gridSize, @flip*@angle*180/Math.PI)
		super
		section.track.closeLoops this

	draw: (painter, start) ->
		painter.drawStraight start, @.size
		painter.drawBend start, start.compound(@connections['C']), @flip

transformsMeet = (t1, t2) ->
	(Math.round(t1.translateX) == Math.round(t2.translateX)) and
		(Math.round(t1.translateY) == Math.round(t2.translateY)) and
		(t1.rotateDegs % 360 == (t2.rotateDegs+180) % 360)

# export classes for use elsewhere, see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
root = exports ? window
root.Track = Track
root.Transform = Transform
root.Straight = Straight
root.Bend = Bend
root.Split = Split