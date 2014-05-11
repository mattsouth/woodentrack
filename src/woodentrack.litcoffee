!(/etc/crossover.svg)

	class Crossover extends Piece
		setSection: (section) =>
			@connections.B =
				transform: =>
					new Transform Math.sin(@angle)*section.track.gridSize,
						@flip*(1-Math.cos(@angle))*section.track.gridSize,
						@flip*@angle*180/Math.PI
			@connections.C =
				transform: =>
					new Transform 2*section.track.gridSize*Math.sin(@angle/2),
						@flip*2*section.track.gridSize*(1-Math.cos(@angle/2)),
						0
			@connections.D =
				transform: =>
					new Transform section.track.gridSize*(2*Math.sin(@angle/2)-Math.sin(@angle)),
						@flip*section.track.gridSize*(1-(2*Math.cos(@angle/2))+Math.cos(@angle)),
						@flip*((@angle*180/Math.PI)-180)
			super

		draw: (painter, start) ->
			painter.drawBend start, start.compound(@exitTransform()), @flip
			painter.drawBend start.compound(@connections.C.transform()),
				start.compound(@connections.D.transform()), @flip
			painter.drawBendRails start, start.compound(@exitTransform()), @flip
			painter.drawBendRails start.compound(@connections.C.transform()).compound(new Transform(0,0,180)),
				start.compound(@connections.D.transform()), @flip
			super painter, start

		clone: (newsection) ->
			result = new Crossover(@)
			result.setSection newsection
			result
