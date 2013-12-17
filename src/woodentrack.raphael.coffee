class RaphaelTrackPainter

	constructor: (track, id, width=800, height=400) ->
		@track = track;
		@paper = Raphael(document.getElementById(id), width, height)

	drawStraight: (start, size) ->
		path = "M"+start.translateX+","+start.translateY+
			"L"+(start.translateX+Math.cos(start.rotateRads)*size*@track.gridSize).toString()+","+
			(start.translateY+Math.sin(start.rotateRads)*size*@track.gridSize).toString()
		straight = @paper.path path
		straight.attr {
			'stroke-width' : @track.trackWidth
			'stroke' : @track.trackColor
		}

	drawBend: (start, end, flip) ->
		orbit = if flip==1 then "1" else "0"
		path = "M"+start.translateX+","+start.translateY+
			" A " + @track.gridSize+"," +@track.gridSize+" 0 0 " + orbit + " " + end.translateX+","+end.translateY
		bend = @paper.path path
		bend.attr {
			'stroke-width' : @track.trackWidth
			'stroke' : @track.trackColor
		}

root = exports ? window
root.RaphaelTrackPainter = RaphaelTrackPainter
