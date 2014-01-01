# Track Painter that uses D3 (http://www.d3js.org) to draw track
# requires an svg node in the document with the passed id
class D3TrackPainter extends TrackPainter
	constructor: (track, id, options={}) ->
		super track, options
		@svg = d3.select('#'+id)

	drawStraight: (start, size) ->
		@drawStraightLine start, size*@track.gridSize, @track.trackWidth, @trackColor

	drawStraightRails: (start, size) ->
		@drawStraightLine start.compound(new Transform(0, @railGauge/2, 0)), 
			size*@track.gridSize, @railWidth, @railColor
		@drawStraightLine start.compound(new Transform(0, -@railGauge/2, 0)), 
			size*@track.gridSize, @railWidth, @railColor

	drawBend: (start, end, flip) ->
		@drawBendLine start, end, flip, @track.gridSize, @track.trackWidth, @trackColor

	drawBendRails: (start, end, flip) ->
		left = new Transform(0, @railGauge/2, 0)
		@drawBendLine start.compound(left), end.compound(left), flip, 
			@track.gridSize-(flip*@railGauge/2), @railWidth, @railColor
		right = new Transform(0, -@railGauge/2, 180)
		@drawBendLine start.compound(right), end.compound(right), flip, 
			@track.gridSize+(flip*@railGauge/2), @railWidth, @railColor

	drawText: (start, text) ->
		@svg.append("text").text(text).attr("x", start.translateX).attr("y", start.translateY)

	drawNobble: (start) ->
		@svg.append("circle").attr("r", 2).attr("stroke-width", 0).attr("fill", "white").attr("cx",start.translateX).attr("cy",start.translateY)

	drawBendLine: (start, end, flip, radius, width, color) ->
		orbit = if flip==1 then "1" else "0"
		path = "M" + start.translateX.toFixed(2) + "," + start.translateY.toFixed(2) +
			" A" + radius + "," + radius +
			" 0 0 " + orbit + " " + end.translateX.toFixed(2) + "," + end.translateY.toFixed(2)
		@svg.append("path").attr("fill", "none").attr("stroke-width", width).attr("stroke", color).attr("d", path)

	drawStraightLine: (start, length, width, color) ->
		path = "M " + start.translateX + " " + start.translateY + 
			" L " + (start.translateX + Math.cos(start.rotateRads)*length) + 
			" " + (start.translateY + Math.sin(start.rotateRads)*length)
		@svg.append("path").attr("stroke-width", width).attr("stroke", color).attr("d", path)

root = exports ? window
root.D3TrackPainter = D3TrackPainter
