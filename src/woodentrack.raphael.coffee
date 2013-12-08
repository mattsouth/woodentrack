class RaphaelTrackPainter

	constructor: (track, id, width=800, height=400) ->
		@track = track;
		@paper = Raphael(document.getElementById(id), width, height)

	drawStraight: (start, size) ->
		path = "M"+start.translateX+","+start.translateY+
			"L"+(start.translateX+Math.cos(start.rotateRads)*size*@track.gridSize).toString()+","+
			(start.translateY+Math.sin(start.rotateRads)*size*@track.gridSize).toString()
		@paper.path path

	drawBend: (start, end) ->
		path = "M"+start.translateX+","+start.translateY+" A " + @track.gridSize+"," +@track.gridSize+" 0 0 1 "+end.translateX+","+end.translateY
		@paper.path path

root = exports ? window
root.RaphaelTrackPainter = RaphaelTrackPainter
