# see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
chai = require 'chai'
chai.should()
{Track, Section, Transform, Straight, Bend, Split} = require '../src/woodentrack'

describe 'Track', ->

	describe 'which is empty', ->
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

	describe 'with straight piece', ->
		track = new Track
		straight = new Straight
		track.add straight
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
		it 'should return index 0 when tested against the piece', ->
			track.index(straight).should.equal 0

	describe 'with a single straight piece that is removed', ->
		track = new Track
		track.add new Straight
		track.remove 0
		it 'should have 1 (empty) section', ->
			# note this is needed so that the next test works
			track.sections.should.have.length 1
		it 'should have no pieces', ->
			track.pieces().should.have.length 0
		it 'should have no loose', ->
			track.connections().should.have.length 0

	# cant use the same piece twice. piece will be removed from previous position before being added again
	describe 'with a single piece that is added twice', ->
		track = new Track
		straight = new Straight
		track.add straight
		track.add straight
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

	describe 'with two straights', ->
		track = new Track
		[1..2].forEach -> track.add new Straight
		compound = track.transform '1:B'
		it 'should have two loose ends', ->
			track.connections().should.have.length 2
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 1:B', ->
			track.connections().should.include "1:B"
		it 'should calculate compound translateX correctly', ->
			compound.translateX.should.equal track.trackGap + track.gridSize*2*(new Straight).size
		it 'should calculate compound translateY correctly', ->
			compound.translateY.should.equal 0
		it 'should calculate compound rotateRads correctly', ->
			compound.rotateRads.should.equal 0

	describe 'with three straights', ->
		track = new Track
		[1..3].forEach -> track.add new Straight
		it 'should have two pieces', ->
			track.pieces().should.have.length 3
		it 'should have two available connections', ->
			track.connections().should.have.length 2
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 2:B', ->
			track.connections().should.include "2:B"

	describe 'with three straights which then has the first one removed', ->
		track = new Track
		[1..3].forEach -> track.add new Straight
		track.remove 0
		it 'should have two pieces', ->
			track.pieces().should.have.length 2
		it 'should have two available connections', ->
			track.connections().should.have.length 2
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 1:B', ->
			track.connections().should.include "1:B"

	describe 'with three straights which then has the middle one removed', ->
		track = new Track
		[1..3].forEach -> track.add new Straight
		track.remove 1
		it 'should have two pieces', ->
			track.pieces().should.have.length 2
		it 'should have two available connections', ->
			track.connections().should.have.length 2
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 1:B', ->
			track.connections().should.include "1:B"

	describe 'with three straights which then has the last one removed', ->
		track = new Track
		[1..3].forEach -> track.add new Straight
		track.remove 2
		it 'should have two pieces', ->
			track.pieces().should.have.length 2
		it 'should have two available connections', ->
			track.connections().should.have.length 2
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 1:B', ->
			track.connections().should.include "1:B"

	describe 'with two bends', ->
		track = new Track
		[1..2].forEach -> track.add new Bend
		compound = track.transform '1:B'
		it 'should calculate compound translateX correctly', ->
			Math.round(compound.translateX).should.equal Math.round(track.gridSize+track.trackGap*Math.sin(Math.PI/4))
		it 'should calculate compound translateY correctly', ->
			Math.round(compound.translateY).should.equal Math.round(track.gridSize+track.trackGap*Math.sin(Math.PI/4))
		it 'should calculate compound rotateDegs correctly', ->
			compound.rotateDegs.should.equal 90

	describe 'with eight bends', ->
		track = new Track
		[1..8].forEach -> track.add new Bend
		it 'should have 1 section', ->
			track.sections.should.have.length 1
		it 'should have 8 pieces', ->
			track.pieces().should.have.length 8
		it 'should have no loose ends', ->
			track.connections().should.have.length 0
		# TODO: should error on adding 9th bend

	describe 'with single split', ->
		track = new Track
		track.add new Split
		it 'should have three connections', ->
			track.connections().should.have.length 3
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 0:B', ->
			track.connections().should.include "0:B"
		it 'should have one available connection at 0:C', ->
			track.connections().should.include "0:C"

	describe 'with split and connected straight', ->
		track = new Track
		track.add new Split
		track.connect new Straight, "0:C"
		it 'should have three connections', ->
			track.connections().should.have.length 3
		it 'should have one available connection at 0:A', ->
			track.connections().should.include "0:A"
		it 'should have one available connection at 0:B', ->
			track.connections().should.include "0:B"
		it 'should have one available connection at 1:B', ->
			track.connections().should.include "1:B"
