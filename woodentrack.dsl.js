/*
DSL - Domain Specific Language for woodentrack
Allows a user to describe a track in a few lines of text

pieces:
S - Straight
R - Right bend
L - Left Bend
J - Junction
X - Crossover (bend)
*/

// convert the track plan into a track object
function parseTrack(plan) {
  var track = new Track();
  var section = track.createSection();
  section.transform = new Transform(300,200,0);
  tokens = plan.match(/\d*(R|L|S|J(R|L)(B|C)|X(R|L)(B|C|D))/g);
  for (i=0; i<tokens.length; i++) {
    var num=parseInt(tokens[i])||1;
    token=tokens[i].match(/(R|L|S|J(R|L)(B|C)|X(R|L)(B|C|D))/g)[0];
    for (j=0;j<num;j++) {
      if (token=="S") section.pieces.push(new Straight(section,2/3));
      else if (token=="R") section.pieces.push(new Bend(section, 1));
      else if (token=="L") section.pieces.push(new Bend(section, -1));
      else if (token.charAt(0)=="J") {
        var side = token.charAt(1);
        var exit = token.charAt(2);
        section.pieces.push(new Junction(section,(side=="R")?1:-1, exit));
      } else if (token.charAt(0)=="X") {
        var side = token.charAt(1);
        var exit = token.charAt(2);
        section.pieces.push(new Crossover(section,(side=="R")?1:-1, exit));
      }
    }
  }
  return track;
};

