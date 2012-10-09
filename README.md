The concept for Woodentrack is a javascript library for designing and testing toy train track layouts.  It's an 
exercise in getting to grips with SVG, that also allows me to the play with the idea of:

1.  creating a single track with a set number of pieces that an electric train can fully traverse
2.  automatically designing aesthetically pleasing tracks that satisfy req 1

The current repository is the result of one evening's work and represents getting the feel for the 
basic building blocks.  A demo for laying out a basic track is available.  For the moment you'll have to 
download the two files and run demo.html in your browser until I've got my head around publishing the demo
page on github pages.  The demo uses a DSL to generate a particular track design.   Examples include:
* A basic ring : "2S4R2S4R"
* A crude figure of eight : "2R8L6R"
The concept is that for tracks with multiple sections, you would start a second section on a new line and
indicate it's starting position with an index that refers to the pieces defined on the lines above
but I'm not 100% sure if this will work yet - sidings and crossover pieces seem tricky.

TODO (in no particular order):
* Automatically size track and scale / center it
* Add new track pieces - sidings, crossovers, different length straights 
* Detect and avoid track collisions
* Provide parsing feedback
* Allow multiple sections in a track
* Set an automatic train around the track - does it traverse every piece?
* provide some kind of the fitness function for a track
* run a genetic algorithm over track design
