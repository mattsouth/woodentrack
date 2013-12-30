class RaphaelTrackPainter

	constructor: (track, id, options={}) ->
		@track = track
		@width = options.width ? 800
		@height = options.height ? 400
		@paper = Raphael(document.getElementById(id), @width, @height)
		@trackColor = options.trackColor ? "lightgrey"
		@railColor = options.railColor ? "white"
		@showConnections = options.showConnections ? true
		@railWidth = options.railWidth ? 2
		@railGauge = options.railGauge ? 9

	drawStraight: (start, size) ->
		# draw track
		path = "M"+start.translateX+","+start.translateY+
			"L"+(start.translateX+Math.cos(start.rotateRads)*size*@track.gridSize).toString()+","+
			(start.translateY+Math.sin(start.rotateRads)*size*@track.gridSize).toString()
		straight = @paper.path path
		straight.attr {
			'stroke-width' : @track.trackWidth
			'stroke' : @trackColor
		}
		# TODO: draw rails

	drawBend: (start, end, flip) ->
		orbit = if flip==1 then "1" else "0"
		path = "M"+start.translateX+","+start.translateY+
			" A " + @track.gridSize+"," +@track.gridSize+" 0 0 " + orbit + " " + end.translateX+","+end.translateY
		bend = @paper.path path
		bend.attr {
			'stroke-width' : @track.trackWidth
			'stroke' : @trackColor
		}

	drawText: (start, text) ->
		el = @paper.text(start.translateX, start.translateY, text)

root = exports ? window
root.RaphaelTrackPainter = RaphaelTrackPainter
