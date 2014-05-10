Woodentrack is a coffeescript library for designing and testing toy train track layouts.

It has as few dependencies, for running tests mainly, as shown in package.json.  run "npm install" to set them up.

## Notes

To use demos in /etc, try "python -m SimpleHTTPServer 8000".

The goals of this branch are to
 1. create a model that's independent of the painting toolkit (e.g. d3 or raphael)
 2. decent test coverage
 3. try out coffeescript
 4. all the goals of the master project

Demos:
 1. demo.html: simple page with empty canvas.  open console.  start building track.
 2. d3.html / raphael.html: random track builders

Potential demos
 1. take existing track and click button to morph track into another layout with the same pieces and the same number of loose ends
 2. easy to use track drawing application

### TODO:
 - try litcoffee extensions for better documention
 - try http://coffeedoc.info/
 - pan / zoom for painted tracks in raphael
 - removeAndJoin method (rename of existing remove method and a new remove added that doesnt change the rest of the track)
 - move method (move a section / part section / piece)
 - track composer demo (touch based?)
 - add directions (IN/OUT) on connections that need to be matched - i.e. IN+OUT makes a connection
