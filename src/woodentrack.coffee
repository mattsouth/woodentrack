# TODO: allow options to be passed in constructor
# a track is an observable / drawable collection of sections / pieces
class Track
	constructor: ->
		@gridSize=100
		@trackGap=1
		@sections=[]

	createSection: ->
		section = new Section(this)
		@sections.push section
		return section

	connections: ->
		result = []
		@sections.forEach (x) ->
			result.concat x.connections()
		result

# a section is an observable / drawable unbroken run of pieces
class Section
	constructor: (@track) ->
		@pieces = []
		@transform = new Transform 0, 0, 0 # starting coords, relative to track origin

	add: (piece) ->
		piece.section = this
		@pieces.push piece
		return piece

	# connections = connection 0.A + all other free connections
	connections: -> 
		if @pieces.length>0
			# TODO:take into account pieces with more than one connection
			# TODO:take into account loops
			[@pieces[0]['A'],@pieces[@pieces.length-1]['B']]
		else
			[]

# a transform is used to move/rotate coordinate axes
class Transform
	constructor: (@translateX, @translateY, @rotateDegs) ->
		@rotateRads = @rotateDegs*Math.PI/180

	# return compounded transform
	compound: (transform) ->
		new Transform @translateX + Math.cos(@rotateRads)*transform.translateX-Math.sin(@rotateRads)*transform.translateY, 
			@translateY + Math.sin(@rotateRads)*transform.translateX+Math.cos(@rotateRads)*transform.translateY, 
			(300+this.rotateDegs+transform.rotateDegs)%360

# abstract track piece
# @connections define the transforms associated with each connection on the piece
class Piece
	constructor: (@section) ->
		@size = 2/3
		@angle = Math.PI/4
		@radius = 1
		@exit = 'B'
		@flip = 1
		@connections = { 'A' : new Transform(0, 0, -180) }

class Straight extends Piece
	constructor: (@section) ->
		super @section
		@connections['B'] = new Transform(@size*@section.track.gridSize, 0, 0)

class Bend extends Piece
	constructor: (@section) ->
		super @section
		@connections['B'] = new Transform(@size*@section.track.gridSize, 0, 0)

# export classes for use elsewhere, see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
root = exports ? window  
root.Track = Track  
root.Section = Section
root.Transform = Transform
root.Straight = Straight
root.Bend = Bend