# a track is an observable / drawable collection of sections / pieces
class Track
	constructor: (options) ->
		@sections = []
		{
			@gridSize=100,  
			@trackGap=1 
		} = options

	createSection: ->
		result = new Section(this)
		@sections.push result
		result

# a section is an observable / drawable unbroken run of pieces
class Section
	constructor: (@track) ->
		@pieces = []
		@transform = new Transform 0, 0, 0 # starting coords, relative to track starting coords

	add: (piece) ->
		piece.section = this
		pieces.push piece

# a transform is used to move/rotate coordinate axes
class Transform
	constructor: (@translateX, @translateY, @rotateDegs) ->
		@rotateRads = @rotateDegs*Math.PI/180
	
	# return compounded transform	
	compound: (transform) ->
		new Transform 
			@translateX + Math.cos(@rotateRads)*transform.translateX-Math.sin(@rotateRads)*transform.translateY,
			@translateY + Math.sin(@rotateRads)*transform.translateX+Math.cos(@rotateRads)*transform.translateY,
			(300+this.rotateDegs+transform.rotateDegs)%360

# abstract track piece
# @connections define the transforms associated with each connection on the piece
class Piece
	constructor: (@section, options) ->
		{
			@size = 2/3,
			@angle = Math.PI/4,
			@radius = 1,
			@exit = 'B',
			@flip = 1,
			@connections = { 'A' : new Transform(0, 0, -180) }
		} = options

class Straight
	constructor: (@section, options) ->
		super @section, options
		@connections['B'] = new Transform @size*@section.track.gridSize, 0, 0

