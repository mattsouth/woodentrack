// A javascript library for constructing toy wooden train track designs in SVG
// a track object consists of multiple track sections
// a track section is an unbroken run of track pieces
// there are different types of track pieces: Straight, Bend, Split, Crossover  
// depends on d3 v2 (see www.d3js.org)
// TODO: calculate the dimensions of a track / section


// objects
function Track() {
  this.gridSize = 100;
  this.trackWidth = 16;
  this.trackColor = "lightgrey";
  this.trackGap = 1;
  this.railColor = "white";
  this.railWidth = 2;
  this.railGauge = 9;
  this.sections = new Array();
}

Track.prototype.createSection = function() {
  var result = new Section(this);
  this.sections.push(result);
  return result;
}

Track.prototype.draw = function(svg) {
  this.sections.forEach( function(section) {
    section.draw(svg);
  });
  //this.annotate(svg);
}

Track.prototype.annotate = function(svg) {
  var idx=0;
  for (i=0; i<this.sections.length; i++) {
    section = this.sections[i];
    element=svg.append("g");
    element=section.transform.transform(element);
    for (j=0; j<section.pieces.length; j++) {
      var p = section.pieces[j];
      element.append("text").text(idx);
      element=element.append("g");
      var t = p.connections[p.exit](p);
      element=t.transform(element);
      idx++
    }
  }
}

Track.prototype.getPiece = function(idx) {
  var counter=0;
  for (i=0; i<this.sections.length; i++) {
    for (j=0; j<this.sections[i].pieces.length; j++) {
      if (counter==idx) return this.sections[i].pieces[j];
      else counter++;
    }  
  }
  return null;
}

Track.prototype.getCompoundTransform = function(idx) {
  var counter=idx;
  for (i=0; i<this.sections.length; i++) {
    if (this.sections[i].pieces.length<counter) {
      counter=counter-this.sections[i].pieces.length;
    } else {
      var result = this.sections[i].transform;
      var gapTransform = new Transform(this.sections[i].track.trackGap, 0, 0);
      for (j=0; j<this.sections[i].pieces.length; j++) {
        var piece = this.sections[i].pieces[j];
        if (counter>0) {
          result=result.compound(piece.connections[piece.exit](piece)).compound(gapTransform);
          counter--;
        }
      }
      return result;
    }
  }
  return null;
}

function Section(track) {
  this.track = track;
  this.pieces = new Array();
  this.transform = new Transform(0,0,0);  // starting position and orientation of first piece
}

Section.prototype.draw = function(svg) {
  if (this.pieces.length>0) {
    var svg = svg.append("g")
          .attr("fill", "none")
          .attr("stroke", this.track.railColor)
          .attr("stroke-width", this.track.railWidth);
    svg=this.transform.transform(svg);
    this.pieces.forEach( function(piece) {
      svg = piece.draw(svg);
    });
  }
}

function Transform(translateX, translateY, rotation) {
  this.translateX = translateX;
  this.translateY = translateY;
  this.rotation = rotation;
}

// only use for svg g elements
Transform.prototype.transform = function(svg) {
    if ((this.translateX>0 || this.translateY>0) && this.rotation>0) {
      svg.attr("transform", "translate(" + this.translateX + ", " + this.translateY + ") rotate(" + this.rotation + ")");
    } else if (this.translateX>0 || this.translateY>0) { 
      svg.attr("transform", "translate(" + this.translateX + ", " + this.translateY + ")");
    } else if (this.rotation!=0) {
      svg.attr("transform", "rotate(" + this.rotation + ")");  
    }
    return svg;
}

Transform.prototype.compound = function(transform) {
  var rads = this.rotation*Math.PI/180;
  return new Transform(
    this.translateX+Math.cos(rads)*transform.translateX-Math.sin(rads)*transform.translateY, 
    this.translateY+Math.sin(rads)*transform.translateX+Math.cos(rads)*transform.translateY, 
    (360+this.rotation+transform.rotation)%360
   );
}

function Piece(section) {
  this.section = section;
  this.size = 2/3; // for straights: multiple of gridSize, e.g. 2, 1, 2/3, 1/2, 1/3
  this.angle = Math.PI/4; // radians
  this.radius = 1; // for bends: multiple of gridSize
  this.exit='B';
  this.flip=1; // for pieces that can be symmetrically flipped, e.g. bends: {1 : "R", -1 : "L"}
  this.connections = new Object();
  this.connections['A'] = function(piece) {
    return new Transform(0,0,180);
  }
}

Piece.prototype.drawConnections = function(element) {
  for (var transform in this.connections) {
    if (this.connections.hasOwnProperty(transform)) {
      element.append("circle").attr("cx", this.connections[transform](this).translateX).attr("cy", this.connections[transform](this).translateY).attr("r", 2).attr("stroke-width", 0).attr("fill", "white");
    }
  }
}

/*
starting position facing along x axis...
side = {1,-1} - 1: bend right, -1: bend left
direction = {1, -1} - 1: forwards, -1: backwards
orbit = {1,0} - 1: clockwise, 0: anti-clockwise
radius = radius of curve (pixels)
angle = angle of curve (radians)
*/
function curvePath(side, direction, orbit, radius, angle) {
  return " a" + radius + ", " + radius + " 0 0, " + orbit + " " + direction*(Math.sin(angle)*radius) + ", " + (side*(1-Math.cos(angle))*radius)
}

Piece.prototype.drawStraightTrack = function(svg) {
  svg.append("path").attr("stroke-width", this.section.track.trackWidth).attr("stroke", this.section.track.trackColor).attr("d", "M 0 0 h " + this.size*this.section.track.gridSize);
}

Piece.prototype.drawStraightRails = function(svg) {
  svg.append("path").attr("d", "M 0 -" + this.section.track.railGauge/2 + " h " + this.size*this.section.track.gridSize + " m 0 " + this.section.track.railGauge + " h -" + this.size*this.section.track.gridSize);
}

Piece.prototype.drawBendTrack = function(svg) {
  svg.append("path").attr("stroke-width", this.section.track.trackWidth).attr("stroke", this.section.track.trackColor).attr("d", "M 0 0 " + curvePath(this.flip, 1, (this.flip==1?1:0), this.section.track.gridSize*this.radius, this.angle));
}

Piece.prototype.drawBendRails = function(svg) {
  svg.append("path").attr("d", "M 0 " + (-1*this.flip*this.section.track.railGauge/2) +
    curvePath(this.flip, 1, (this.flip==1?1:0), this.radius*this.section.track.gridSize+this.section.track.railGauge/2, this.angle) +
    " m -" + (Math.sin(this.angle)*this.section.track.railGauge) + " " + (this.flip*Math.cos(this.angle)*this.section.track.railGauge) +
    curvePath(this.flip*-1, -1, (this.flip==1?0:1), this.radius*this.section.track.gridSize-this.section.track.railGauge/2, this.angle));
}

Piece.prototype.draw = function(svg) {
  // draw piece
  this.drawTrack(svg);
  this.drawRails(svg);
  this.drawConnections(svg); // TODO: make this optional;
  // transform coordinates to exit connection
  svg=svg.append("g");
  var transformToExit=this.connections[this.exit];
  svg=transformToExit(this).transform(svg);
  // add gap between rails
  svg=svg.append("g");
  var gap=new Transform(this.section.track.trackGap,0,0);
  return gap.transform(svg);
}

// Track piece implementations ... 

function Straight(section) {
  Piece.call(this, section);
  this.connections['B'] = function(piece) {
    return new Transform(piece.size*piece.section.track.gridSize, 0, 0);
  };
}

Straight.prototype = new Piece();

Straight.prototype.drawTrack = function(svg) {
  this.drawStraightTrack(svg);
}

Straight.prototype.drawRails = function(svg) {
  this.drawStraightRails(svg);
}

function Bend(section, flip) {
  Piece.call(this, section);
  this.flip = flip; // 1 : "R", -1 : "L"
  this.connections['B'] = function(piece) {
    return new Transform(
      Math.sin(piece.angle)*piece.section.track.gridSize*piece.radius, 
      piece.flip*(1-Math.cos(piece.angle))*piece.section.track.gridSize*piece.radius,
      (360+piece.flip*piece.angle*180/Math.PI)%360
    );
  };
}

Bend.prototype = new Piece();

Bend.prototype.drawTrack = function(svg) {
  this.drawBendTrack(svg);
}

Bend.prototype.drawRails = function(svg) {
  this.drawBendRails(svg);
}

function Split(section, flip, exit) {
  Piece.call(this, section);
  this.flip = flip; // 1 : "R", -1: "L"
  this.exit = exit; // "B" | "C"
  this.connections['B'] = function(piece) {
    return new Transform(piece.size*piece.section.track.gridSize, 0, 0);
  }
  this.connections['C'] = function(piece) {
    return new Transform(
      (Math.sin(piece.angle)*piece.section.track.gridSize*piece.radius), 
      piece.flip*(1-Math.cos(piece.angle))*piece.section.track.gridSize*piece.radius, 
      (360+piece.flip*piece.angle*180/Math.PI)%360
    );
  }
}

Split.prototype = new Piece();

Split.prototype.drawTrack = function(svg) {
  this.drawStraightTrack(svg);
  this.drawBendTrack(svg);
}

Split.prototype.drawRails = function(svg) {
  this.drawStraightRails(svg);
  this.drawBendRails(svg);
}

function Join(section, flip, exit) {
  Piece.call(this, section);
  this.flip = flip; // 1 : "R", -1: "L"
  this.exit = exit; // "B" | "C"
  this.connections['B'] = function(piece) {
    return new Transform(piece.size*piece.section.track.gridSize, 0, 0);
  }
  this.connections['C'] = function(piece) {
    return new Transform(
      (piece.size-Math.sin(piece.angle))*piece.section.track.gridSize*piece.radius, 
      piece.flip*(1-Math.cos(piece.angle))*piece.section.track.gridSize*piece.radius, 
      180-piece.flip*piece.angle*180/Math.PI
    );
  }
}

Join.prototype = new Piece();

Join.prototype.drawTrack = function(svg) {
  this.drawStraightTrack(svg);
  svg=svg.append("g");
  var conB = this.connections['B'](this).compound(new Transform(0,0,180));
  svg = conB.transform(svg);
  this.flip=this.flip*-1;
  this.drawBendTrack(svg);
  this.flip=this.flip*-1;
}

Join.prototype.drawRails = function(svg) {
  this.drawStraightRails(svg);
  svg=svg.append("g");
  var conB = this.connections['B'](this).compound(new Transform(0,0,180));
  svg = conB.transform(svg);
  this.flip=this.flip*-1;
  this.drawBendRails(svg);
  this.flip=this.flip*-1;
}

function Crossover(section, flip, exit) {
  Piece.call(this, section);
  this.flip = flip; // 1 : "R", -1: "L"
  this.exit = exit; // "B" | "C" | "D"
  this.connections['B'] = function(piece) {
    return new Transform(
      (Math.sin(piece.angle)*piece.section.track.gridSize*piece.radius), 
      piece.flip*(1-Math.cos(piece.angle))*piece.section.track.gridSize*piece.radius, 
      piece.flip*piece.angle*180/Math.PI
    );
  };
  this.connections['C'] = function(piece) {
    return new Transform(
      2*piece.section.track.gridSize*piece.radius*Math.sin(piece.angle/2), 
      2*piece.flip*piece.section.track.gridSize*piece.radius*(1-Math.cos(piece.angle/2)), 
      0
    );
  };
  this.connections['D'] = function (piece) {
    var h = piece.radius*piece.section.track.gridSize*((1/Math.cos(piece.angle/2))-1);
    return new Transform(
      h*Math.sin(piece.angle), 
      -1*piece.flip*h*(1+Math.cos(piece.angle)), 
      180+(piece.flip*45)   
    );
  }
}

Crossover.prototype = new Piece();

Crossover.prototype.drawTrack = function(svg) {
  this.drawBendTrack(svg);
  svg=svg.append("g");
  var conD = this.connections['D'](this).compound(new Transform(0,0,180));
  svg = conD.transform(svg);
  this.flip=this.flip*-1;
  this.drawBendTrack(svg);
  this.flip=this.flip*-1;
}

Crossover.prototype.drawRails = function(svg) {
  this.drawBendRails(svg);
  svg=svg.append("g");
  var conD = this.connections['D'](this).compound(new Transform(0,0,180));
  svg = conD.transform(svg);
  this.flip=this.flip*-1;
  this.drawBendRails(svg);
  this.flip=this.flip*-1;
}

