# a track is an observable / drawable model of a woooden train track comprising
# multiple pieces of different types connected together
class Track
	constructor: (@start=new Transform(0,0,0), options={}) ->
		@gridSize = options.gridSize ? 100
		@trackWidth = options.trackWidth ? 16
		@trackGap = options.trackGap ? 1
		@_sections = []
		@_listeners = {}
		@_gapTransform = new Transform(@trackGap, 0, 0)
		@started = null # piece that uses start transform

	# Next three methods make class observable.  For template see
	# http://www.nczonline.net/blog/2010/03/09/custom-events-in-javascript/

	# attach listener to "add", "remove", "change" or "clear" types of event
	on: (types, listener) ->
		types.split(" ").forEach (type) =>
			if !@_listeners[type]? then @_listeners[type] = []
			@_listeners[type].push(listener)

	# remove listener from particular types of event
	off: (types, listener) ->
		types.split(" ").forEach (type) =>
			@_listeners[type].splice(idx, 1) for l, idx in @_listeners[type] when l==listener

	_fire: (event) ->
		if typeof event == "string" then event = { type: event }
		if !event.target then event.target = @
		if !event.type then throw new Error "Event missing 'type' property."
		if @_listeners[event.type] instanceof Array
			@_listeners[event.type].forEach (listener) -> listener.call(this, event)

	# update property and fire "change" event
	set: (property, value) ->
		if value!=@[property]
			@[property]=value
			switch property
				when 'trackGap'
					@_gapTransform = new Transform(value, 0, 0)
			@_fire { type: 'change', target: @ }

	clone: ->
		result = new Track @start, @
		result._sections.push section.clone(result) for section in @_sections
		result

	# available connection codes
	connections: ->
		result = []
		offset = 0
		@_sections.forEach (section) ->
			section.connections().forEach (code) ->
				[index, letter] = code.split ':'
				result.push (parseInt(index)+offset).toString()+":"+letter
			offset+=section._pieces.length
		result

	# all track pieces
	pieces: ->
		result = []
		@_sections.forEach (section) ->
			result = result.concat section._pieces
		result

	# Add piece to track at cursor.
	# If there are no pieces in track, the start transform is used in lieu of the cursor.
    # If there are pieces in the track but there's no cursor, you'll need to provide a transform in the second parameter to specify the position of the piece.
	# TODO: check piece connections for collisions and bail if there are any
	add: (piece, where) ->
		if piece instanceof Piece
			if where?
				if where instanceof Transform
					section = @_createSection -> where
					piece.setSection section
					@_firePieceAdded piece
				else
					throw new Error 'the second parameter should be a transform - perhaps you need to use the connect method?'
			else if @connections().length==0 and !@started?
				section = @_createSection => @start
				piece.setSection section
				@_firePieceAdded piece
				@started = piece
			else if @cursor()?
				@connect piece, @cursor()
			else
				throw new Error 'unable to add piece - try specifying the where parameter in the track.add method'
		else
			throw new Error 'the first parameter should be a piece'

	# connection (code) where the next piece will be added
	cursor: ->
		section = @_sections[@_sections.length-1]
		if section?
			piece = section._pieces[section._pieces.length-1]
		if piece?
			code = @_index(piece) + ":" + piece.exit
		conns = @connections()
		if code? and conns.indexOf(code)>-1
			code
		else
			# NB will return undefined if conns is empty
			conns.pop()

	# Connect piece to available connection identified from code, e.g. "10:C".
	# Throws Error if specified connection not available.
	connect: (piece, code) ->
		if piece instanceof Piece
			if @connections().indexOf(code)>-1
				# check through each of the section exits before creating a new section
				added = false
				@_sections.forEach (section) =>
					length = section._pieces.length
					last = section._pieces[length-1]
					lastExit = (@_sectionStartingIndex(section)+length-1)+":"+last.exit
					if lastExit == code
						added = true
						piece.setSection section
						@_firePieceAdded piece
				if !added
					[index, label] = code.split ':'
					[sectionIndex, sectionPieceIndex] = @_sectionAndPieceIndex index
					section = @_createSection => @_sections[sectionIndex].compoundTransform(sectionPieceIndex,label).compound(@_gapTransform)
					@_connection(code).connected = piece.connections['A']
					piece.connections['A'].connected = @_connection(code)
					piece.setSection section
					@_firePieceAdded piece
			else
				throw new Error(code + " is not an available connection")
		else
			throw new Error 'the first parameter should be a piece'
			
	# remove indexed piece from track
	remove: (index) ->
		[sectionIndex, pieceIndex] = @_sectionAndPieceIndex index
		@_sections[sectionIndex].remove(pieceIndex)
		@_fire { type: 'remove', target: @ }

	clear: ->
		# TODO: remove listeners / pieces?
		@_sections = []
		@_fire { type: 'clear', target: @ }
		@started = null

	# Each collision is represented by an array of piece indexes that collide.
	# very coarse algorithm currently used
	# TODO: look for three, four etc way collisions
	collisions: ->
		pieces = []
		@._sections.forEach (section) =>
			start = section.transform()
			section._pieces.forEach (piece) =>
				piece._setBBox start
				start = start.compound(piece.exitTransform()).compound(@._gapTransform)
				pieces.push piece
		result = []
		for source, idx in pieces
			for target, idx2 in pieces[idx+1..]
				if source._bbox.overlaps(target._bbox)
					result.push [idx, idx2+idx+1]
		result

	hasCollision: ->
		@collisions().length>0

	# returns true if piece a is connected to piece b
	connected: (a, b) ->
		for label, connection of a.connections
			if connection.connected==b
				return true
		return false

	_firePieceAdded: (piece) ->
		idx = @_index piece
		transform = @_transform(idx.toString() + ":A")
		@_fire { type: 'add', target: piece, start: transform.compound(new Transform(0,0,180)) }

	_sectionAndPieceIndex: (index) ->
		result = null
		sectionIdx=0
		@_sections.forEach (section) ->
			if index<section._pieces.length and !result?
				result = [sectionIdx, index]
			else
				index-=section._pieces.length
				sectionIdx++
		result

	_sectionStartingIndex: (section) ->
		result=0
		if @_sections.length>0
			for idx in [0...@_sections.indexOf(section)]
				do (idx) =>
					result+=@_sections[idx]._pieces.length
		result

	_index: (piece) ->
		result = -1
		for p, idx in @pieces()
			if piece == p then result = idx
		result

	_piece: (index) ->
		[sectionidx, pieceidx] = _sectionAndPieceIndex: (index)
		@_sections[sectionidx]._pieces[pieceidx]

	# get Connection transform/connected field from connection code, e.g. "0:A"
	_connection: (code) ->
		[index, letter] = code.split ':'
		[sectionIndex, sectionPieceIndex] = @_sectionAndPieceIndex parseInt(index)
		@_sections[sectionIndex]._pieces[sectionPieceIndex].connections[letter]

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
					@_connection(loose[idx1]).connected = @_connection(loose[idx2])
					@_connection(loose[idx2]).connected = @_connection(loose[idx1])
					@_closeLoops # recurse in case there are more to find

	# transform of connection wrt to track origin
	_transform: (code) ->
		[index, label] = code.split ':'
		[sectionIndex, sectionPieceIndex] = @_sectionAndPieceIndex index
		#console.log "track._transform", code, sectionIndex, sectionPieceIndex, label
		@_sections[sectionIndex].compoundTransform sectionPieceIndex, label

	# a section is an observable / drawable unbroken run of pieces used by a track
	# to help keep a record of loose connections and reduce the number of cached
	# transforms
	class Section
		constructor: (@track, @transform = -> new Transform(0,0,0)) ->
			@_pieces = []
			@exit = null

		clone: (newtrack) ->
			result = new Section(newtrack, @transform)
			piece.clone(result) for piece in @_pieces
			result

		add: (piece) ->
			if @_pieces.length>0 and @connections().length==0
				throw new Error("No available connections on this section")
			num_pieces = @_pieces.length # NB this is also the new index
			section_offset = @track._sectionStartingIndex this
			piece.section = this
			# connect existing exit connection to new piece's connection A
			if @exit?
				@exit.connected = piece
				piece.connections['A'].connected = @
			# update section exit connection
			@exit = piece.connections[piece.exit]
			@_pieces.push piece
			return piece

		# remove idx piece and tie up loose connections
		remove: (idx) ->
			if typeof(idx)!="number"
				idx = @_pieces.indexOf idx
			num_pieces = @_pieces.length
			if idx>=0 and idx<num_pieces
				if num_pieces is 1
					@exit=null
				else
					# deal with section connections
					removee = @_pieces[idx]
					if idx<(num_pieces-1) # if not last piece
						@_pieces[idx+1].connections['A'].connected=removee.connections['A'].connected
					else
						@exit = @_pieces[idx-1].connections[@_pieces[idx-1].exit]
					if idx>0 # if not first piece
						@_pieces[idx-1].connections[@_pieces[idx-1].exit].connected=removee.connections[removee.exit].connected
					removee.connections['A'].connected=null
					removee.connections[removee.exit].connected=null
					# TODO: deal with any other track connections attached to this one
				# set removee piece section to null
				@_pieces[idx].section=null
				# remove piece
				@_pieces.splice idx, 1
			else
				throw new Error("Cannot remove piece " + idx + " from section with " + @_pieces.length + " pieces")

		# all available (section scope) connection codes
		connections: ->
			result = []
			for piece, idx in @_pieces
				for label, connection of piece.connections
					result.push idx.toString() + ":" + label if !connection.connected
			result

		# return transform associated with the nth piece's connection
		compoundTransform: (n, connection) ->
			start = @transform()
			[0...n].forEach (pieceIndex) =>
				start = start.compound(@_pieces[pieceIndex].exitTransform()).compound(@track._gapTransform)
			start.compound(@_pieces[n].connections[connection].transform())

# Abstract class for defining a painter see:
# - woodentrack.raphael.coffee
# - woodentrack.d3.coffee
# Implementations must include the following methods:
# - drawStraight
# - drawStraightRails
# - drawBend
# - drawbendRails
# - drawCode
# - drawCursor
# - _clear
class TrackPainter
	constructor: (track, options={}) ->
		@track = track
		@trackColor = options.trackColor ? "lightgrey"
		@railColor = options.railColor ? "white"
		@showCodes = options.showCodes ? true
		@showCursor = options.showCursor ? true
		@railWidth = options.railWidth ? 2
		@railGauge = options.railGauge ? 9
		@showBBox = options.showBBox ? false
		@draw()

	draw: ->
		@_clear()
		@track._sections.forEach (section) =>
			start = section.transform()
			section._pieces.forEach (piece) =>
				piece._setBBox if @showBBox
				piece.draw @, start
				start = start.compound(piece.exitTransform()).compound(@track._gapTransform)
		if @showCodes
			@track.connections().forEach (code) =>
				@drawCode @track._transform(code).compound(@track._gapTransform), code
		if @showCursor && @track.cursor() then @drawCursor @track._transform(@track.cursor())

	set: (property, value) ->
		if value!=@[property]
			@[property]=value
			@draw()

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

# Bounding box
class BBox
	constructor: (@x1=null, @y1=null, @x2=null, @y2=null) ->

	addTransform: (t) ->
		@x1 = t.translateX if !@x1? or t.translateX<@x1
		@x2 = t.translateX if !@x2? or t.translateX>@x2
		@y1 = t.translateY if !@y1? or t.translateY<@y1
		@y2 = t.translateY if !@y2? or t.translateY>@y2

	overlaps: (bbox) ->
		if bbox.x2 < @x1 then return false
		if bbox.x1 > @x2 then return false
		if bbox.y2 < @y1 then return false
		if bbox.y1 > @y2 then return false
		true

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
		@connections =
			A :
				transform: -> new Transform(0, 0, -180)
		@section = null
		@_bbox = null

	setSection: (section) ->
		# remove existing section if there is already one set
		if @section? then @section.remove this
		section.add this
		section.track._closeLoops this

	exitTransform: ->
		@connections[@exit].transform()

	draw: (painter, start) ->
		for label, conn of @connections
			painter.drawNobble start.compound(conn.transform())
		if painter.showBBox
			painter.drawRectangle @_bbox.x1, @_bbox.y1, @_bbox.x2-@_bbox.x1, @_bbox.y2-@_bbox.y1

	set: (property, value) ->
		if value!=@[property]
			@[property]=value
			@section?.track?._fire { type: 'change', target: @ }

	hasCollision: ->
		idx = @section.track._index(@)
		@section.track.collisions().some (coll) ->
			coll.indexOf(idx)>-1

	_setBBox: (start) ->
		@_bbox = new BBox
		for label, conn of @connections
			@_bbox.addTransform start.compound(conn.transform())

class Straight extends Piece
	setSection: (section) ->
		@connections.B =
			transform: =>
				new Transform(@size*section.track.gridSize, 0, 0)
		super

	draw: (painter, start) ->
		painter.drawStraight start, @.size
		painter.drawStraightRails start, @.size
		super painter, start

	clone: (newsection) ->
		result = new Straight(@)
		result.setSection newsection
		result

class Bend extends Piece
	setSection: (section) ->
		@connections.B =
			transform: =>
				new Transform Math.sin(@angle)*section.track.gridSize,
					@flip*(1-Math.cos(@angle))*section.track.gridSize,
					@flip*@angle*180/Math.PI
		super

	draw: (painter, start) ->
		painter.drawBend start, start.compound(@exitTransform()), @flip
		painter.drawBendRails start, start.compound(@exitTransform()), @flip
		super painter, start

	clone: (newsection) ->
		result = new Bend(@)
		result.setSection newsection
		result

class Split extends Piece
	setSection: (section) ->
		@connections.B =
			transform: =>
				new Transform(@size*section.track.gridSize, 0, 0)
		@connections.C =
			transform: =>
				new Transform Math.sin(@angle)*section.track.gridSize,
					@flip*(1-Math.cos(@angle))*section.track.gridSize,
					@flip*@angle*180/Math.PI
		super

	draw: (painter, start) ->
		painter.drawStraight start, @size
		painter.drawBend start, start.compound(@connections.C.transform()), @flip
		painter.drawStraightRails start, @size
		painter.drawBendRails start, start.compound(@connections.C.transform()), @flip
		super painter, start

	clone: (newsection) ->
		result = new Split(@)
		result.setSection newsection
		result

class Join extends Piece
	setSection: (section) ->
		@connections.B =
			transform: =>
				new Transform(@size*section.track.gridSize, 0, 0)
		@connections.C =
			transform: =>
				new Transform ((2/3)-Math.sin(@angle))*section.track.gridSize,
					@flip*(1-Math.cos(@angle))*section.track.gridSize,
					@flip*@angle*3*180/Math.PI
		super

	draw: (painter, start) ->
		painter.drawStraight start, @.size
		back = start.compound(@exitTransform()).compound(new Transform(0,0,180))
		painter.drawBend start.compound(@connections.C.transform()), back, @flip
		painter.drawStraightRails start, @.size
		back = start.compound(@exitTransform()).compound(new Transform(0,0,180))
		painter.drawBendRails start.compound(@connections.C.transform()), back, @flip
		super painter, start

	clone: (newsection) ->
		result = new Join(@)
		result.setSection newsection
		result

class Merge extends Piece
	setSection: (section) ->
		@connections.B =
			transform: =>
				new Transform Math.sin(@angle)*section.track.gridSize,
					@flip*(1-Math.cos(@angle))*section.track.gridSize,
					@flip*@angle*180/Math.PI
		@connections.C =
			transform: =>
				new Transform section.track.gridSize*(Math.sin(@angle)-(2*Math.cos(@angle)/3)),
					@flip*section.track.gridSize*(1-Math.cos(@angle)-(2*Math.sin(@angle)/3)),
					@flip*((@angle*180/Math.PI)-180)
		super

	draw: (painter, start) ->
		painter.drawBend start, start.compound(@exitTransform()), @flip
		painter.drawStraight start.compound(@connections.C.transform()).compound(new Transform(0,0,180)), @size
		painter.drawBendRails start, start.compound(@exitTransform()), @flip
		painter.drawStraightRails start.compound(@connections.C.transform()).compound(new Transform(0,0,180)), @size
		super painter, start

	clone: (newsection) ->
		result = new Merge(@)
		result.setSection newsection
		result

class Crossover extends Piece
	setSection: (section) =>
		@connections.B =
			transform: =>
				new Transform Math.sin(@angle)*section.track.gridSize,
					@flip*(1-Math.cos(@angle))*section.track.gridSize,
					@flip*@angle*180/Math.PI
		@connections.C =
			transform: =>
				new Transform 2*section.track.gridSize*Math.sin(@angle/2),
					@flip*2*section.track.gridSize*(1-Math.cos(@angle/2)),
					0
		@connections.D =
			transform: =>
				new Transform section.track.gridSize*(2*Math.sin(@angle/2)-Math.sin(@angle)),
					@flip*section.track.gridSize*(1-(2*Math.cos(@angle/2))+Math.cos(@angle)),
					@flip*((@angle*180/Math.PI)-180)
		super

	draw: (painter, start) ->
		painter.drawBend start, start.compound(@exitTransform()), @flip
		painter.drawBend start.compound(@connections.C.transform()),
			start.compound(@connections.D.transform()), @flip
		painter.drawBendRails start, start.compound(@exitTransform()), @flip
		painter.drawBendRails start.compound(@connections.C.transform()).compound(new Transform(0,0,180)),
			start.compound(@connections.D.transform()), @flip
		super painter, start

	clone: (newsection) ->
		result = new Crossover(@)
		result.setSection newsection
		result

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
root.BBox = BBox
