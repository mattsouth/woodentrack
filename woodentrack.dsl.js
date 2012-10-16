/*
DSL - Domain Specific Language for woodentrack
Allows a user to describe a track in a few lines of text, see demo.html

pieces:
S - Straight
R - Right bend
L - Left Bend
J(L|R)(B|C) - Join
Y(L|R)(B|C) - Split
X(L|R)(B|C|D) - Crossover
*/

// convert plan into array of tokens
function tokeniseSection(section) {
  return section.match(/\d*(R|L|S|(J|Y)(R|L)(B|C)|X(R|L)(B|C|D))/g);
}

// convert the track plan into a track object
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
        var target = parseInt(parts[0].match(/\d+/)[0]);
        var piece = track.getPiece(target);
        if (piece!=null) {
          var transform = track.getCompoundTransform(target);
          var exit = parts[0].match(/\D/)[0];
          section.transform = transform.compound(piece.connections[exit](piece));
        }
      }
    } else {
      tokens = tokeniseSection(line);
    }
    if (tokens!=null) {
      for (i=0; i<tokens.length; i++) {
        var num=parseInt(tokens[i])||1;
        token=tokens[i].match(/(R|L|S|(J|Y)(R|L)(B|C)|X(R|L)(B|C|D))/g)[0];
        for (j=0;j<num;j++) {
          if (token=="S") {
            var straight=new Straight(section);
            straight.size=1;
            section.pieces.push(straight);
          }
          else if (token=="R") section.pieces.push(new Bend(section, 1));
          else if (token=="L") section.pieces.push(new Bend(section, -1));
          else if (token.charAt(0)=="J"||token.charAt(0)=="Y"||token.charAt(0)=="X") {
            var side = token.charAt(1)=="R"?1:-1;
            var exit = token.charAt(2);
            if (token.charAt(0)=="J") section.pieces.push(new Join(section, side, exit));
            else if (token.charAt(0)=="Y") section.pieces.push(new Split(section, side, exit));
            else section.pieces.push(new Crossover(section, side, exit));
          }
        }
      }
    }
  });
  return track;
};

