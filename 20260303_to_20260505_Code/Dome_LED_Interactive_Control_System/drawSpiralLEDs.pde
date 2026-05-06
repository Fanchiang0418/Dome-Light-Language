// 把彩帶/螺旋路徑（ribbonPath）依照 spiralBri 燈效亮度取樣後，轉成 2D HUD 圓點並畫出來

void drawSpiralLEDs() {
  if (ribbonPath.size() == 0) return;

  ArrayList<float[]> dots = new ArrayList<float[]>(); // {sx, sy, sz, v}
  collectSpiralDotsByColumns(ribbonPath, dots);

  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);
  noStroke();

  for (float[] d : dots) {
    float sx = d[0], sy = d[1], sz = d[2], v = d[3];

    float size = lerp(dotMax, dotMin, constrain(sz, 0, 1));
    float c = 255 * v;
    fill(c * ledR, c * ledG, c * ledB, 230);
    ellipse(sx, sy, size, size);
  }

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}
