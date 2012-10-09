The concept for Woodentrack is a javascript library for designing and testing toy train track layouts.  It's an 
exercise in getting to grips with SVG, that also allows me to the play with the idea of:

1.  creating a single track with a set number of pieces that an electric train can fully traverse
2.  automatically designing aesthetically pleasing tracks that satisfy req 1

The current repository is the result of one evening's work.  A demo for laying out a basic track is available.  
The demo uses a DSL to generate a track.   Examples include:
* A basic ring : "2S4R2S4R"
* A crude figure of eight : "2R8L6R"

TODO (in no particular order):
* Automatically size track and scale / center it
* Add new track pieces
* Detect and avoid track collisions
* Provide parsing feedback
* Allow ultiple sections in a track
* Set an automatic train around the track - does it traverse every piece?
* provide some kind of the fitness function for a track
* run a genetic algorithm over track design
