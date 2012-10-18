The concept for Woodentrack is a javascript library for designing and testing toy train track layouts.  It's an exercise in getting to grips with SVG, that also allows me to the play with the idea of:

1.  creating a single track from a set number of pieces that an electric train can fully traverse
2.  automatically designing aesthetically pleasing tracks that satisfy req 1

It may also be that this project could provide a way to explore html5/svg touch interfaces.

A demo for laying out a basic track is available (for the moment you'll have to 
download the two files and run demo.html in your browser until I've got my head around publishing the demo
page on github pages).  The demo uses a simple domain specific language to generate a particular track design.  Examples include:
* A basic ring : "2S4R2S4R" - i.e. two straight pieces then four right turn pieces, repeated
* A crude figure of eight : "2R8L6R"

The idea is that for tracks with multiple sections, you would start a second section on a new line and
indicate it's starting position with an index that refers to the pieces defined on the lines above
but I'm not 100% sure if this will work yet - sidings and crossover pieces seem tricky.

TODO (in no particular order):
* Automatically size track and scale / center it
* Annotating free ends with their piece index and connection 
* Allow parser to specify straight length
* explore using css to control colours
* Detect and avoid track collisions
* Check for complete tracks, or count the number of loose ends
* Provide parsing feedback
* Update demo to manipulate gridsize and trackwidth and annotate track pieces with their index / connection points
* Set an automatic train around the track - does it traverse every piece?
* provide some kind of fitness function for a track
* run a genetic algorithm over track design
