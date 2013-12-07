# a track is an observable / drawable model of a woooden train track comprising
# multiple pieces of different types connected together
# TODO: make observable
class Track
	constructor: (options={}) ->
		@gridSize = options.gridSize ? 100
		@trackGap = options.trackGap ? 1
		@sections = []

	connections: ->
		result = []
		@sections.forEach (section) ->
			result = result.concat section.connections()
		result

	pieces: ->
		result = []
		@sections.forEach (section) ->
			result = result.concat section.pieces
		result

	# Add piece to track.  Use start to specify starting transform,
	# else the last exit connection or default transform is used
    # for the first piece.
	# TODO?: return index
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

	connect: (piece, connection) ->
		# TODO reassign section.exit to the next available connection if used by this action

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
		[@sections.indexOf(section)...0].forEach (section) ->
			result+=section.pieces.length
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
			# TODO: check piece connections for collisions and bail if there are any
			piece.section = this
			# connect existing exit connection to new piece's connection A
			if @exit?
				piece.connections['A'].connected = @exit
				@track.connection(@exit).connected = (num_pieces+section_offset).toString() + ":A"
			# update section exit connection
			@exit = (num_pieces+section_offset).toString() + ":" + piece.exit
			@pieces.push piece
			return piece

		checkForLoops: (piece) ->
			# check for cycle from all new potential connections
			if @pieces.length>1
				for label, connection of piece.connections
					if label!='A'
						possible = @compoundTransform(@pieces.length-1, label)
						if transformsMeet possible, @pieces[0].connections.A
							@pieces[0].A.connection=num_pieces + ":" + label
							@pieces[num_pieces][label].connection="0:A"

		# remove idx piece and tie up loose connections
		remove: (idx) ->
			if typeof(idx)!="number"
				idx = @pieces.indexOf idx
			num_pieces = @pieces.length
			if idx>=0 and idx<num_pieces
				# deal with connections
				removee = @pieces[idx]
				if num_pieces>1
					if idx<(num_pieces-1)
						removee.connections[removee.exit].connected=null
						@pieces[idx+1].connections['A'].connected=null
					if idx>0
						removee.connections['A'].connected=null
						@pieces[idx-1].connections[@pieces[idx-1].exit].connected=null
				else
					@exit=null
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
			gap = new Transform(@track.trackGap,0,0)
			[0...(n-1)].forEach (pieceIndex) =>
				start = start.compound(@pieces[pieceIndex].exitTransform()).compound(gap)
			start.compound(@pieces[n].connections[connection]).compound(gap)

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

# abstract track piece
# @connections define the transforms associated with each connection on the piece
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
		super
		@connections['B'] = new Connection(@size*section.track.gridSize, 0, 0)
		section.checkForLoops this

class Bend extends Piece
	setSection: (section) ->
		super
		@connections['B'] = new Connection(Math.sin(@angle)*@section.track.gridSize, @flip*(1-Math.cos(@angle))*@section.track.gridSize, @angle*180/Math.PI)
		section.checkForLoops this

transformsMeet = (t1, t2) ->
	result = t1.translateX == t2.translateX and t1.translateY == t2.translateY and (t1.rotateDegs % 360 == (t2.rotateDegs+180) % 360)
	console.log "transformsMeet? " + t1.toString() + " :: " + t2.toString() + " " + result
	result

# export classes for use elsewhere, see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
root = exports ? window
root.Track = Track
root.Transform = Transform
root.Straight = Straight
root.Bend = Bend