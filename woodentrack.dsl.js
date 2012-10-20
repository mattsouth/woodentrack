/*
DSL - Domain Specific Language for woodentrack
Allows a user to describe a track in a few lines of text, see demo.html

Each line consists of an optional position instruction followed by a list of sequential pieces.
The optional position instruction takes the form of transform or connection instruction, e.g.
"t(100,100,45):" says translate x=100, y=100 pixels then rotate 45 degrees
"4C:" says connect to the C connection of the 4th piece.

pieces (using javascript regExp notation before hypen):
S(w|h|t)? - Straight (whole|half|third)
R - Right bend
L - Left Bend
J(L|R)(B|C) - Join (Bend) (Exit Connection)
Y(L|R)(B|C) - Split
M(L|R)(B|C) - Merge
X(L|R)(B|C|D) - Crossover
*/

// convert line of plan into array of tokens
function tokeniseSection(section) {
  return section.match(/\d*(R|L|S(w|h|t)?|(J|Y|M)(R|L)(B|C)|X(R|L)(B|C|D))/g);
}

// convert the plan into a track object
function parseTrack(plan) {
  var track = new Track();
  var lines = plan.split("\n");
  lines.forEach( function(line) {
    var section = track.createSection();
    var tokens;    
    if (line.indexOf(":")>-1) {
      parts = line.split(":");
      tokens=tokeniseSection(parts[1]);
      // process transform instruction
      if (parts[0].search(/t\(\d+,\d+,\d+\)/)>-1) {
        transformParts = parts[0].match(/\d+/g);
        section.transform = new Transform(parseInt(transformParts[0]), parseInt(transformParts[1]), parseInt(transformParts[2]));
      } else if (parts[0].search(/\d+\w/)>-1) {
        // process connection instruction
        var target = parseInt(parts[0].match(/\d+/)[0]);
        var piece = track.getPiece(target);
        if (piece!=null) {
          var transform = track.getCompoundTransform(target);
          var exit = parts[0].match(/\D/)[0];
          section.transform = transform.compound(piece.connections[exit](piece)).compound(new Transform(section.track.trackGap, 0, 0));
        }
      }
    } else {
      tokens = tokeniseSection(line);
    }
    if (tokens!=null) {
      for (i=0; i<tokens.length; i++) {
        var num=parseInt(tokens[i])||1;
        token=tokens[i].match(/(R|L|S(w|h|t)?|(J|Y|M)(R|L)(B|C)|X(R|L)(B|C|D))/g)[0];
        for (j=0;j<num;j++) {
          if (token.charAt(0)=="S") {
            var straight=new Straight(section);
            if (token.length==2) {
              if (token.charAt(1)=="w") straight.size=1;
              else if (token.charAt(1)=="h") straight.size=0.5;
              else if (token.charAt(1)=="t") straight.size=1/3;    
            } // NB defaults to 2/3
            section.pieces.push(straight);
          }
          else if (token=="R") section.pieces.push(new Bend(section, 1));
          else if (token=="L") section.pieces.push(new Bend(section, -1));
          else if (token.charAt(0)=="J"||token.charAt(0)=="Y"||token.charAt(0)=="X"||token.charAt(0)=="M") {
            var side = token.charAt(1)=="R"?1:-1;
            var exit = token.charAt(2);
            if (token.charAt(0)=="J") section.pieces.push(new Join(section, side, exit));
            else if (token.charAt(0)=="Y") section.pieces.push(new Split(section, side, exit));
            else if (token.charAt(0)=="M") section.pieces.push(new Merge(section, side, exit));
            else section.pieces.push(new Crossover(section, side, exit));
          }
        }
      }
    }
  });
  return track;
};

