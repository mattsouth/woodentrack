# a track is an observable / drawable model of a woooden train track comprising
# multiple pieces of different types connected together
# see http://www.nczonline.net/blog/2010/03/09/custom-events-in-javascript/ for observable template
class Track
	constructor: (options={}) ->
		@gridSize = options.gridSize ? 100
		@trackWidth = options.trackWidth ? 16
		@trackGap = options.trackGap ? 1
		@_gapTransform = new Transform(@trackGap, 0, 0)
		@_sections = []
		@_listeners = {}

	# attach listener to particular type of event, e.g. "added", "removed", "moved" or "changed"
	on: (type, listener) ->
		if !@_listeners.type then @_listeners[type] = []
		@_listeners[type].push(listener)

	# unattach listener from particular type of event
	off: (type, listener) ->
		@_listeners[type].splice(idx, 1) for l, idx in @_listeners[type] when l==listener

	_fire: (event) ->
		if typeof event == "string" then event = { type: event }
		if !event.target then event.target = @
		if !event.type then throw new Error "Event missing 'type' property."
		if @._listeners[event.type] instanceof Array
			@._listeners[event.type].forEach (listener) -> listener.call(this, event)

	# available connection codes
	connections: ->
		result = []
		offset = 0
		@_sections.forEach (section) ->
			section.connections().forEach (code) ->
				[index, letter] = code.split ':'
				result.push (parseInt(index)+offset).toString()+":"+letter
			offset+=section.pieces.length
		result

	# all track pieces
	pieces: ->
		result = []
		@_sections.forEach (section) ->
			result = result.concat section.pieces
		result

	# draw track with painter
	draw: (painter) ->
		@_sections.forEach (section) ->
			section.draw painter
		if painter.showAnnotations
			@connections().forEach (code) =>
				painter.drawAnnotation @_transform(code), code

	# Add piece to track.
	# Use start transform to specify position/orientation of piece.
	# If no start provided, the last piece's exit connection will be used.
	# If no pieces in track, the default transform is used.
	# TODO: check piece connections for collisions and bail if there are any
	add: (piece, start = null) ->
		section =
			if start?
				@_createSection start
			else
				if @_sections.length>0
					@_sections[@_sections.length-1]
				else
					@_createSection()
		piece.setSection section
		@_firePieceAdded piece

	# Connect piece to available connection identified from code, e.g. "10:C".
	# Throws Error if specified connection not available.
	connect: (piece, code) ->
		if @connections().indexOf(code)>-1
			# check through each of the section exits before creating a new section
			added=false
			@_sections.forEach (section) =>
				last = section.pieces[section.pieces.length-1]
				lastExit = (@_sectionStartingIndex(section)+section.pieces.length-1)+":"+last.exit
				if lastExit == code
					added=true
					piece.setSection section
					@_firePieceAdded piece
			if !added
				section = @_createSection @_transform(code).compound(@_gapTransform)
				piece.setSection section
				@_connection(code).connected = piece.connections['A']
				piece.connections['A'].connected = @_connection(code)
				@_firePieceAdded piece
		else
			throw new Error(code + " is not an available connection")

	# remove indexed piece from track
	remove: (index) ->
		[sectionIndex, pieceIndex] = @_sectionAndPieceIndex index
		@_sections[sectionIndex].remove(pieceIndex)
		@_fire { type: 'removed', target: @ }	

	_firePieceAdded: (piece) ->
		idx = @_index piece
		transform = @_transform(idx.toString() + ":A")
		@_fire { type: 'added', target: piece, start: transform.compound(new Transform(0,0,180)) }		

	_sectionAndPieceIndex: (index) ->
		result = [-1,-1]
		sectionIdx=0
		@_sections.forEach (section) ->
			if index<section.pieces.length
				result = [sectionIdx, index]
			else
				index-=section.pieces.length
				sectionIdx++
		result

	_sectionStartingIndex: (section) ->
		result=0
		[@_sections.indexOf(section)...0].forEach (idx) =>
			result+=@_sections[idx].pieces.length
		result

	_index: (piece) ->
		result = -1
		for p, idx in @pieces()
			if piece == p then result = idx
		result

	# get Connection transform/connected field from connection code, e.g. "0:A"
	_connection: (code) ->
		[index, letter] = code.split ':'
		[sectionIndex, sectionPieceIndex] = @_sectionAndPieceIndex index
		@_sections[sectionIndex].pieces[sectionPieceIndex].connections[letter]

	_createSection: (transform = null) ->
		section = new Section(this, transform)
		@_sections.push section
		return section

	# find and seal any closable loops
	_closeLoops: ->
		loose = @connections()
		[0...loose.length].forEach (idx1) =>
			[(idx1+1)...loose.length].forEach (idx2) =>
				trans1 = @_transform(loose[idx1])
				trans2 = @_transform(loose[idx2]).compound(@_gapTransform)
				if transformsMeet trans1, trans2
					@_connection(loose[idx1]).connected = loose[idx2]
					@_connection(loose[idx2]).connected = loose[idx1]
					@_closeLoops # recurse in case there are more to find

	# transform of connection wrt to track origin
	_transform: (code) ->
		[index, label] = code.split ':'
		[sectionIndex, sectionPieceIndex] = @_sectionAndPieceIndex index
		@_sections[sectionIndex].compoundTransform sectionPieceIndex, label

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
			section_offset = @track._sectionStartingIndex this
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

		# all available (section scope) connection codes
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
				start = start.compound(@pieces[pieceIndex].exitTransform()).compound(@track._gapTransform)
			start.compound(@pieces[n].connections[connection])

		draw: (painter) ->
			start = @transform
			@pieces.forEach (piece) =>
				piece.draw painter, start
				start = start.compound(piece.exitTransform()).compound(@track._gapTransform)

# Abstract class for defining a painter see woodentrack.raphael.coffee and woodentrack.d3.coffee
class TrackPainter
	constructor: (track, options={}) ->
		@track = track
		@trackColor = options.trackColor ? "lightgrey"
		@railColor = options.railColor ? "white"
		@showAnnotations = options.showAnnotations ? true
		@railWidth = options.railWidth ? 2
		@railGauge = options.railGauge ? 9

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

# an extended Transform with a pointer to another connection
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
		# remove existing section if there is one
		if @section? then @section.remove this
		section.add this

	exitTransform: ->
		@connections[@exit]

	draw: (painter, start) ->
		conns = for label, conn of @connections
			painter.drawNobble start.compound(conn)

class Straight extends Piece
	setSection: (section) ->
		@connections.B = new Connection(@size*section.track.gridSize, 0, 0)
		super
		section.track._closeLoops this

	draw: (painter, start) ->
		painter.drawStraight start, @.size
		painter.drawStraightRails start, @.size
		super painter, start

class Bend extends Piece
	setSection: (section) ->
		@connections.B = new Connection(
			Math.sin(@angle)*section.track.gridSize,
			@flip*(1-Math.cos(@angle))*section.track.gridSize,
			@flip*@angle*180/Math.PI)
		super
		section.track._closeLoops this

	draw: (painter, start) ->
		painter.drawBend start, start.compound(@exitTransform()), @flip
		painter.drawBendRails start, start.compound(@exitTransform()), @flip
		super painter, start

class Split extends Piece
	setSection: (section) ->
		@connections.B = new Connection(@size*section.track.gridSize, 0, 0)
		@connections.C = new Connection(
			Math.sin(@angle)*section.track.gridSize,
			@flip*(1-Math.cos(@angle))*section.track.gridSize,
			@flip*@angle*180/Math.PI)
		super
		section.track._closeLoops this

	draw: (painter, start) ->
		painter.drawStraight start, @size
		painter.drawBend start, start.compound(@connections['C']), @flip
		painter.drawStraightRails start, @size
		painter.drawBendRails start, start.compound(@connections['C']), @flip
		super painter, start

class Join extends Piece
	setSection: (section) ->
		@connections.B = new Connection(@size*section.track.gridSize, 0, 0)
		@connections.C = new Connection(
			((2/3)-Math.sin(@angle))*section.track.gridSize,
			@flip*(1-Math.cos(@angle))*section.track.gridSize,
			@flip*@angle*3*180/Math.PI)
		super
		section.track._closeLoops this

	draw: (painter, start) ->
		painter.drawStraight start, @.size
		back = start.compound(@exitTransform()).compound(new Transform(0,0,180))
		painter.drawBend start.compound(@connections.C), back, @flip
		painter.drawStraightRails start, @.size
		back = start.compound(@exitTransform()).compound(new Transform(0,0,180))
		painter.drawBendRails start.compound(@connections.C), back, @flip
		super painter, start

class Merge extends Piece
	setSection: (section) ->
		@connections.B = new Connection(
			Math.sin(@angle)*section.track.gridSize,
			@flip*(1-Math.cos(@angle))*section.track.gridSize,
			@flip*@angle*180/Math.PI)
		@connections.C = new Connection(
			section.track.gridSize*(Math.sin(@angle)-(2*Math.cos(@angle)/3)),
			@flip*section.track.gridSize*(1-Math.cos(@angle)-(2*Math.sin(@angle)/3)),
			@flip*((@angle*180/Math.PI)-180))
		super
		section.track._closeLoops this

	draw: (painter, start) ->
		painter.drawBend start, start.compound(@exitTransform()), @flip
		painter.drawStraight start.compound(@connections.C).compound(new Transform(0,0,180)), @size
		painter.drawBendRails start, start.compound(@exitTransform()), @flip
		painter.drawStraightRails start.compound(@connections.C).compound(new Transform(0,0,180)), @size
		super painter, start

class Crossover extends Piece
	setSection: (section) ->
		@connections.B = new Connection(
			Math.sin(@angle)*section.track.gridSize,
			@flip*(1-Math.cos(@angle))*section.track.gridSize,
			@flip*@angle*180/Math.PI)
		@connections.C = new Connection(
			2*section.track.gridSize*Math.sin(@angle/2),
			@flip*2*section.track.gridSize*(1-Math.cos(@angle/2)),
			0)
		@connections.D = new Connection(
			section.track.gridSize*(2*Math.sin(@angle/2)-Math.sin(@angle)),
			@flip*section.track.gridSize*(1-(2*Math.cos(@angle/2))+Math.cos(@angle)),
			@flip*((@angle*180/Math.PI)-180))
		super
		section.track._closeLoops this

	draw: (painter, start) ->
		painter.drawBend start, start.compound(@exitTransform()), @flip
		painter.drawBend start.compound(@connections.C),
			start.compound(@connections.D), @flip
		painter.drawBendRails start, start.compound(@exitTransform()), @flip
		painter.drawBendRails start.compound(@connections.C).compound(new Transform(0,0,180)),
			start.compound(@connections.D), @flip
		super painter, start

transformsMeet = (t1, t2) ->
	(Math.round(t1.translateX) == Math.round(t2.translateX)) and
		(Math.round(t1.translateY) == Math.round(t2.translateY)) and
		(t1.rotateDegs % 360 == (t2.rotateDegs+180) % 360)

# export classes for use elsewhere,
# see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
root = exports ? window
root.Track = Track
root.TrackPainter = TrackPainter
root.Transform = Transform
root.Straight = Straight
root.Bend = Bend
root.Split = Split
root.Join = Join
root.Merge = Merge
root.Crossover = Crossover