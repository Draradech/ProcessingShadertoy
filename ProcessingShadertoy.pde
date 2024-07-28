void setup() {
  size(800, 450, P2D);
  //fullScreen(P2D);
  
  setupImageShader("tubes_i.glsl");
  setupBufferShader("tubes_ba.glsl", 0, LINEAR);

  /*
  setupImageShader("XcSyWz_i.glsl");
  setupBufferShader("XcSyWz_ba.glsl", 0, LINEAR);
  setupBufferShader("XcSyWz_bb.glsl", 1, LINEAR);
  setupBufferShader("XcSyWz_bc.glsl", 2, LINEAR);
  */
  
  frameRate(45);
  background(0);
}

void draw() {
  runShader();
  text(nf(iTime,0,2) + "     " + nf(frameRate,0,1) + " fps     " + width + " x " + height, 5, height - 5);
}
