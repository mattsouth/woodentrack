# Track Painter that uses D3 (http://www.d3js.org) to draw track
# requires an svg element in the document with the passed id
class D3TrackPainter extends TrackPainter
	constructor: (track, @selector, options={}) ->
		vis = d3.select('#'+@selector)
			.attr("pointer-events", "all")
			.call(d3.behavior.zoom().on("zoom", -> vis.attr("transform", "translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")")))
			.append("svg:g")
		@svg = d3.select('#' + @selector + ' g')
		super track, options
		track.on 'add remove clear change', @

	call: (track, event) ->
		switch event.type
			when "add"
				@svg.selectAll(".annotation").remove()
				@svg.selectAll(".cursor").remove()
				if @.showBBox then event.target._setBBox event.start 
				event.target.draw @, event.start
				if @showCursor and @track.cursor()?
					@drawCursor @track._transform(@track.cursor())
				if @showCodes
					@track.connections().forEach (code) =>
						@drawCode @track._transform(code).compound(@track._gapTransform), code
			when "remove", "change"
				@draw()
			when "clear"
				@_clear()

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

	drawCode: (start, text) ->
		@svg.append("text").text(text)
			.attr("x", start.translateX)
			.attr("y", start.translateY)
			.attr("class", "annotation")
			.attr("font-family", "sans-serif")
			.attr("font-size", @railGauge)
			.attr("fill", @trackColor)
			.attr("style", "font-weight:bold;")
			.attr("text-anchor", "middle")
			.attr("transform", "rotate(" + (start.rotateDegs+90).toString() + " " + (start.translateX).toFixed(2) + "," + start.translateY.toFixed(2) + ")")

	drawCursor: (start) ->
		offset = 2
		offset+=@railGauge-2 if @showCodes
		path = "M " + (offset + start.translateX) + " " + start.translateY +
			" L " + (offset + start.translateX) + " " + (start.translateY - (@track.trackWidth/2) + 3) +
			" L " + (start.translateX+@track.trackWidth+offset-7) + " " + start.translateY +
			" L " + (offset + start.translateX) + " " + (start.translateY + (@track.trackWidth/2) - 3)
		@svg.append("path")
			.attr("d", path)
			.attr("class", "cursor")
			.attr("fill", @trackColor)
			.attr("transform", "rotate(" + start.rotateDegs + " " + start.translateX.toFixed(2) + "," + start.translateY.toFixed(2) + ")")

	drawNobble: (start) ->
		@svg.append("circle")
			.attr("r", 2)
			.attr("stroke-width", 0)
			.attr("fill", "white")
			.attr("cx",start.translateX)
			.attr("cy",start.translateY)

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

	drawRectangle: (x, y, width, height) ->
		@svg.append("rect").attr("x", x).attr("y", y)
			.attr("width", width)
			.attr("height", height)
			.attr("fill", "none")
			.attr("stroke", "black")
			.attr("stroke-width", 1)

	_clear: ->
		@svg.selectAll("path").remove()
		@svg.selectAll("text").remove()
		@svg.selectAll("rect").remove()

root = exports ? window
root.D3TrackPainter = D3TrackPainter
