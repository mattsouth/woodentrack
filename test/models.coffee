# see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
chai = require 'chai'
chai.should()
{Track, Section, Transform, Straight, Bend} = require '../src/woodentrack'


describe 'Track', ->

	# next three functions used in previous version and may be useful later
	# i.e. when a getConnection('0.A') method is required
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
			track.sections.should.have.length 0
		it 'should have no pieces', ->
			track.pieces().should.have.length 0
		it 'should have no loose ends', ->
			track.connections().should.have.length 0
		it 'should have default gridSize', ->
			track.gridSize.should.equal 100
		it 'should have default trackGap', ->
			track.trackGap.should.equal 1

	describe 'track with straight piece', ->
		track = new Track
		track.add new Straight
		it 'should have 1 section', ->
			track.sections.should.have.length 1
		it 'should have 1 piece', ->
			track.pieces().should.have.length 1
		it 'should have two loose ends', ->
			track.connections().should.have.length 2
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 0:B', ->
			track.connections().should.include "0:B"

	describe 'track with removed straight piece', ->
		track = new Track
		track.add new Straight
		track.remove 0
		it 'should have 1 section', ->
			track.sections.should.have.length 1
		it 'should have no pieces', ->
			track.pieces().should.have.length 0
		it 'should have no loose', ->
			track.connections().should.have.length 0

	describe 'track with single piece used twice', ->
		track = new Track
		straight = new Straight
		track.add straight
		track.add straight  # this should remove and the re-add the piece
		it 'should have 1 section', ->
			track.sections.should.have.length 1
		it 'should have 1 piece', ->
			track.pieces().should.have.length 1
		it 'should have two loose ends', ->
			track.connections().should.have.length 2
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 0:B', ->
			track.connections().should.include "0:B"

	describe 'track with two straights', ->
		track = new Track
		[1..8].forEach -> track.add new Straight
		it 'should have two loose ends', ->
			track.connections().should.have.length 2
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 1:B', ->
			track.connections().should.include "1:B"

	describe 'track with eight bends', ->
		track = new Track
		[1..8].forEach -> track.add new Bend
		it 'should have 1 section', ->
			track.sections.should.have.length 1
		it 'should have 8 pieces', ->
			track.pieces().should.have.length 8
		it 'should have no loose ends', ->
			track.connections().should.have.length 0
		# TODO: should error on adding 9th bend
