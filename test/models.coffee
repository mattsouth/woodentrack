# see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
chai = require 'chai'
chai.should()
{Track, Section, Transform, Straight, Bend} = require '../src/woodentrack'


describe 'Track', ->

	compareAngles = (a1, a2) ->
		Math.abs(a1) % 360 == Math.abs(a2) % 360

	compareTransforms = (t1, t2) ->
		(t1.translateX == t2.translateX) and (t1.translateY == t2.translateY) and compareAngles(t1.rotateDegs, t2.rotateDegs)

	testConnections = (conns, t) ->
		result = false
		conns.forEach (conn) ->
			result = true if compareTransforms(conn, t)
		if !result then console.log conns, t
		result

	describe 'empty track', ->
		track = new Track
		it 'should have no sections', ->
			track.sections.length.should.equal 0
		it 'should have no loose ends', ->
			track.connections().length.should.equal 0
		it 'should have a gridSize', ->
			track.gridSize.should.equal 100
		it 'should have a trackGap', ->
			track.trackGap.should.equal 1

	describe 'track with section', ->
		track = new Track
		section = track.createSection()
		it 'should have one section', ->
			track.sections.length.should.equal 1
		it 'section should reference track', ->
			track.sections[0].track.should.equal track
		it 'should have no loose ends', ->
			track.connections().length.should.equal 0

	describe 'track with straight piece', ->
		track = new Track
		section = track.createSection()
		section.add new Straight(section)
		it 'should have two loose ends', ->
			track.connections().length.should.equal 2
		it 'should have one available connection at 0A', ->
			check = testConnections(track.connections(), new Transform(0,0,-180))
			check.should.be.true
		it 'should have one available connection at 0B', ->
			testConnections(track.connections(), new Transform((2/3)*100,0,0)).should.be.true

	describe 'track with two straights', ->
		track = new Track
		section = track.createSection()
		section.add new Straight(section)
		section.add new Straight(section)
		it 'should have two loose ends', ->
			track.connections().length.should.equal 2
		it 'should have one available connection at 0A', ->
			testConnections(track.connections(), new Transform(0,0,-180)).should.be.true
		it 'should have one available connection at 1B', ->
			testConnections(track.connections(), new Transform((4/3)*100+1,0,0)).should.be.true
