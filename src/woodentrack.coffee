# a track is an observable / drawable collection of sections
# TODO: make observable
class Track
	constructor: (options={}) ->
		@gridSize = options.gridSize ? 100
		@trackGap = options.trackGap ? 1
		@sections = []

	createSection: ->
		section = new Section(this)
		@sections.push section
		return section

	connections: ->
		result = []
		@sections.forEach (section) ->
			result = result.concat section.connections()
		result

# a section is an observable / drawable unbroken run of pieces
# TODO: remove piece from section
class Section
	constructor: (@track) ->
		@pieces = []
		@transform = new Transform 0, 0, 0 # starting coords, relative to track origin

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

# an extened Transform with a connected attribute that refers to another connection
class Connection extends Transform
	constructor: (@translateX, @translateY, @rotateDegs) ->
		super @translateX, @translateY, @rotateDegs
		@connected = null

# abstract track piece
# @connections define the transforms associated with each connection on the piece
class Piece
	constructor: (@section, options={}) ->
		@size = options.size ? 2/3
		@angle = options.angle ? Math.PI/4
		@radius = options.radius ? 1
		@exit = options.exit ? 'B'
		@flip = options.flip ? 1
		@connections = { 'A' : new Connection(0, 0, -180) }

class Straight extends Piece
	constructor: (@section) ->
		super @section
		@connections['B'] = new Connection(@size*@section.track.gridSize, 0, 0)

class Bend extends Piece
	constructor: (@section) ->
		super @section
		@connections['B'] = new Connection(@size*@section.track.gridSize, 0, 0)

# export classes for use elsewhere, see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
root = exports ? window
root.Track = Track
root.Section = Section
root.Transform = Transform
root.Straight = Straight
root.Bend = Bend