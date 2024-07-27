void setup() {
  size(800, 450, P2D);
  //fullScreen(P2D);
  
  setupImageShader("Mf2yzw_i.glsl");
  setupBufferShader("Mf2yzw_ba.glsl", 0, 4);

  /*
  setupImageShader("XsG3z1_Image.glsl");
  setupBufferShader("XsG3z1_BufferA.glsl", 0, LINEAR);
  */
  
  /*
  setupImageShader("test_img.glsl");
  setupBufferShader("test_buf_a.glsl", 0, NEAREST);
  setupBufferShader("test_buf_b.glsl", 1, NEAREST);
  setupBufferShader("test_buf_c.glsl", 2, NEAREST);
  */

  /*
  setupImageShader("3dlyRN_i.glsl");
  setupBufferShader("3dlyRN_ba.glsl", 0, LINEAR);
  setupBufferShader("3dlyRN_bb.glsl", 1, LINEAR);
  setupBufferShader("3dlyRN_bc.glsl", 2, LINEAR);
  */
  
  frameRate(144);
  background(0);
}

void draw() {
  runShader();
  text(nf(iTime,0,2) + "     " + nf(frameRate,0,1) + " fps" , 5, height - 5);
}
