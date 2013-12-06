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
			if start? then @createSection start
			else
				if @sections.length>0
					@sections[@sections.length-1]
				else
					@createSection()
		piece.setSection section

	connect: (piece, connection) ->
		# TODO

	remove: (index) ->
		# TODO

	createSection: (transform = null) ->
		section = new Section(this, transform)
		@sections.push section
		return section

	# a section is an observable / drawable unbroken run of pieces used by a track
	# to help keep a record of loose connections and reduce the number of cached
	# transforms
	# TODO: remove piece from section
	class Section
		constructor: (@track, @transform = new Transform(0,0,0)) ->
			@pieces = []

	 	# TODO: throw error if the exit connection is connected i.e. when section is a loop of simple pieces
		add: (piece) ->
			piece.section = this
			# connect existing exit connection to piece connection A
			if @exit?
				@exit.connected = piece.connections['A']
				piece.connections['A'].connected = @exit
			# update section exit connection
			@exit = piece.connections[piece.exit]
			@pieces.push piece
			return piece

		remove: (piece) ->
			# TODO: remove piece and connect up loose ends if necessary

		# all available (unconnected) connections
		connections: ->
			result = []
			start = @transform
			@pieces.forEach (piece) =>
				for label, connection of piece.connections
					result.push start.compound(connection) if !connection.connected
				start = start.compound(piece.connections[piece.exit]).compound(new Transform(@track.trackGap, 0, 0))
			result

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
			section.remove this
		section.add this

class Straight extends Piece
	setSection: (section) ->
		super
		@connections['B'] = new Connection(@size*section.track.gridSize, 0, 0)

class Bend extends Piece
	setSection: (section) ->
		super
		@connections['B'] = new Connection(@size*@section.track.gridSize, 0, 0)

# export classes for use elsewhere, see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
root = exports ? window
root.Track = Track
root.Transform = Transform
root.Straight = Straight
root.Bend = Bend