# see http://net.tutsplus.com/tutorials/javascript-ajax/better-coffeescript-testing-with-mocha/
chai = require 'chai'  
chai.should() 
{Track, Section, Transform, Straight, Bend} = require '../src/woodentrack'

describe 'Track', ->

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

	describe 'track with section and straight(s)', ->
		track = new Track
		section = track.createSection()
		section.add new Straight(section)
		it 'should have two loose ends', ->
			track.connections().length.should.equal 2
		section.add new Straight(section)
		it 'should have two loose ends (from two straights)', ->
			track.connections().length.should.equal 2

