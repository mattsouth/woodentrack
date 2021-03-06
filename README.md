Woodentrack is a coffeescript library for designing and testing toy train track layouts.

It has a few dependencies for running tests, as shown in package.json.  run "npm install" to set them up.

## Notes

This project is an exercise in getting to grips with SVG that may also allow a developer to play with the idea of:

1.  creating a single track from a set number of pieces that a train can fully traverse
2.  automatically designing aesthetically pleasing tracks
3.  touch interfaces

woodentrack.coffee defines an API for building and manipulating the model of a track.  svg "painters" are defined that use both d3js and raphaeljs svg libraries.  woodentrack.random.coffee provides some functions for randomly generating a track.

### Demos

To see demos in /etc locally, use <a href="https://www.npmjs.com/package/superstatic">superstatic</a> or similar.

 1. <a href="http://mattsouth.github.io/woodentrack/demo.html">demo.html</a>: simple page with empty canvas.  open console.  start building track.
 2. <a href="http://mattsouth.github.io/woodentrack/d3.html">d3.html</a> / <a href="http://mattsouth.github.io/woodentrack/raphael.html">raphael.html</a>: random track builders

Potential demos

 1. easy to use track drawing application - use interact.js? 
 2. take existing track and click button to morph track into another layout with the same pieces and the same number of loose ends

### TODO:

 - documentation of trigonometry with litcoffee / coffeedoc.info
 - pan / zoom for raphael painter
 - make pan / zoom optional for d3 painter
 - optimisation for random demo that slows up as n increases
 - removeAndJoin method (rename of existing remove method and a new remove added that doesnt change the rest of the track)
 - move method (move a section / part section / piece)
 - add directions (IN/OUT) on connections that need to be matched - i.e. IN+OUT makes a connection
