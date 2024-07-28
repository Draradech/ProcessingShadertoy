final int NEAREST = 2;
final int LINEAR = 4;

PGraphics[][] graphics = new PGraphics[5][2]; // 1 - 4 Buffer A - D
int lastRendered[] = {0, 0, 0, 0, 0};
PShader[] shaders = new PShader[5]; // 0 - Image, 1 - 4 Buffer A - D

void setupShader(String filename, int index) {
  String[] source = concat(header, loadStrings(filename));
  shaders[index] = new PShader(this, vertSource, source);
  shaders[index].set("iResolution", float(width), float(height), 1.0);
}

void setupImageShader(String filename) {
  setupShader(filename, 0);
}

void setupBufferShader(String filename, int index, int sampling) {
  setupShader(filename, index + 1);
  graphics[index + 1][0] = PGraphics32.newDataPG(this, width, height, sampling);
  graphics[index + 1][1] = PGraphics32.newDataPG(this, width, height, sampling);
}

int shaderFrame = 0;
int millisOffset = 0;
PVector shaderMousePos = new PVector(0,0);
PVector shaderMouseClick = new PVector(0,0);
float iTimeLast = 0;
float iTime = 0;

void updateShaders() {
  if (mousePressed) shaderMousePos = new PVector(mouseX, height - mouseY);
  iTime = (shaderFrame == 0) ? 0.0 : (float(millis() - millisOffset) / 1000.0);
  float iDate[] = {year(), month(), day(), ((hour() * 60) + minute()) * 60 + second()};
  for (int i = 0; i < 5; i++) {
    PShader s = shaders[i];
    if (s != null) {
        s.set("iTime", iTime);
        s.set("iTimeDelta", iTime - iTimeLast);
        s.set("iFrame", shaderFrame);
        s.set("iDate", iDate[0], iDate[1], iDate[2], iDate[3]); // s.set("iDate", iDate); works, but gives OpenGL error 1282
        s.set("iMouse", shaderMousePos.x, shaderMousePos.y, shaderMouseClick.x, shaderMouseClick.y);
    }
  }
  iTimeLast = iTime;
  if (shaderMouseClick.y > 0) shaderMouseClick.y = -shaderMouseClick.y; // iMouse.w is click event 
}

void drawShaders() {
  for (int i = 1; i < 5; i++) {
    PShader s = shaders[i];
    if (s != null) {
      if (graphics[1][0] != null) s.set("iChannel0", graphics[1][lastRendered[1]]);
      if (graphics[2][0] != null) s.set("iChannel1", graphics[2][lastRendered[2]]);
      if (graphics[3][0] != null) s.set("iChannel2", graphics[3][lastRendered[3]]);
      if (graphics[4][0] != null) s.set("iChannel3", graphics[4][lastRendered[4]]);
      
      int nowRendering = 1 - lastRendered[i];
      
      graphics[i][nowRendering].beginDraw();
      graphics[i][nowRendering].filter(s); 
      graphics[i][nowRendering].endDraw();
      
      lastRendered[i] = nowRendering;
    }
  }

  PShader s = shaders[0];
  if (graphics[1][0] != null) s.set("iChannel0", graphics[1][lastRendered[1]]);
  if (graphics[2][0] != null) s.set("iChannel1", graphics[2][lastRendered[2]]);
  if (graphics[3][0] != null) s.set("iChannel2", graphics[3][lastRendered[3]]);
  if (graphics[4][0] != null) s.set("iChannel3", graphics[4][lastRendered[4]]);
  filter(s);
}

void runShader() {
  updateShaders();
  drawShaders();
  if (shaderFrame == 0) millisOffset = millis();
  shaderFrame++;
}

void mousePressed() {
  shaderMouseClick = new PVector(mouseX, height - mouseY);
}

void mouseReleased() {
  shaderMouseClick = new PVector(-shaderMouseClick.x, shaderMouseClick.y);
}





String header[] = {"""
#version 330
uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
void mainImage(out vec4 fragColor, in vec2 fragCoord);
void main() {mainImage(gl_FragColor, gl_FragCoord.xy);}
"""};

String vertSource[] = {"""
uniform mat4 transformMatrix;
uniform mat4 texMatrix;
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;
varying vec4 vertColor;
varying vec4 vertTexCoord;
void main() {
gl_Position = transformMatrix * position;
vertColor = color;
vertTexCoord = texMatrix * vec4(texCoord, 1.0, 1.0);
}"""};
