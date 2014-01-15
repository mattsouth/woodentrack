# Track painter that uses raphael (http://www.raphaeljs.com) to draw track
# requires a div with the passed id to be present in the document
class RaphaelTrackPainter extends TrackPainter

	constructor: (track, id, options={}) ->
		super track, options
		@width = options.width ? 800
		@height = options.height ? 400
		@paper = Raphael(document.getElementById(id), @width, @height)
		track.on 'added', @
		track.on 'removed', @

	call: (track, event) -> 
		switch event.type
			when "added"
				@svg.selectAll(".annotation").remove()
				@svg.selectAll(".cursor").remove()
				event.target.draw @, event.start
				if @._showCursor then @drawCursor @track._transform(@track.cursor())
				if @._showAnnotations
					@track.connections().forEach (code) =>
						@drawAnnotation @track._transform(code).compound(@track._gapTransform), code
			when "removed"
				@_clear()
				@track.draw @

	drawStraight: (start, size) ->
		drawLine @paper, start.translateX, start.translateY, 
			(start.translateX+Math.cos(start.rotateRads)*size*@track.gridSize).toString(),
			(start.translateY+Math.sin(start.rotateRads)*size*@track.gridSize).toString(),
			@track.trackWidth, @trackColor

	drawStraightRails: (start, size) ->
		offsetX = Math.sin(start.rotateRads)*@railGauge/2
		offsetY = -1*Math.cos(start.rotateRads)*@railGauge/2
		drawLine @paper, (start.translateX+offsetX).toString(), (start.translateY+offsetY).toString(), 
			((start.translateX+Math.cos(start.rotateRads)*size*@track.gridSize)+offsetX).toString(),
			((start.translateY+Math.sin(start.rotateRads)*size*@track.gridSize)+offsetY).toString(),
			@railWidth, @railColor
		drawLine @paper, (start.translateX-offsetX).toString(), (start.translateY-offsetY).toString(), 
			((start.translateX+Math.cos(start.rotateRads)*size*@track.gridSize)-offsetX).toString(),
			((start.translateY+Math.sin(start.rotateRads)*size*@track.gridSize)-offsetY).toString(),
			@railWidth, @railColor

	drawBend: (start, end, flip) ->
		orbit = if flip==1 then "1" else "0"
		drawBend @paper, @track.gridSize, start.translateX, start.translateY, end.translateX, end.translateY, orbit, @track.trackWidth, @trackColor

	drawBendRails: (start, end, flip) ->
		orbit = if flip==1 then "1" else "0"
		startOffsetX = Math.sin(start.rotateRads)*@railGauge/2
		startOffsetY = -1*Math.cos(start.rotateRads)*@railGauge/2
		endOffsetX = Math.sin(end.rotateRads)*@railGauge/2
		endOffsetY = -1*Math.cos(end.rotateRads)*@railGauge/2
		drawBend @paper, (@track.gridSize-(flip*@railGauge/2)).toString(), (start.translateX+startOffsetX).toString(), 
			(start.translateY+startOffsetY).toString(), (end.translateX+endOffsetX).toString(), 
			(end.translateY+endOffsetY).toString(), orbit, @railWidth, @railColor
		drawBend @paper, (@track.gridSize+(flip*@railGauge/2)).toString(), (start.translateX-startOffsetX).toString(), 
			(start.translateY-startOffsetY).toString(), (end.translateX-endOffsetX).toString(), 
			(end.translateY-endOffsetY).toString(), orbit, @railWidth, @railColor

	drawAnnotation: (start, text) ->
		el = @paper.text(start.translateX, start.translateY, text)

	drawNobble: (start) ->
		el = @paper.circle(start.translateX, start.translateY, 2)
		el.attr {
			'fill' : 'white'
			'stroke' : 'none'
		}

	drawLine = (paper, startX, startY, endX, endY, width, color) ->
		path = "M"+startX+","+startY+"L"+endX+","+endY
		straight = paper.path path
		straight.attr {
			'stroke-width' : width
			'stroke' : color
		}
		
	drawBend = (paper, gridSize, startX, startY, endX, endY, orbit, width, color) ->
		path = "M" + startX + "," + startY + " A " + gridSize + "," + gridSize + " 0 0 " + orbit + " " + endX + "," + endY
		bend = paper.path path
		bend.attr {
			'stroke-width' : width
			'stroke' : color
		}

root = exports ? window
root.RaphaelTrackPainter = RaphaelTrackPainter
