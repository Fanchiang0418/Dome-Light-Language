// 先根據模式（全亮 or 流動）把螺旋上每個點的螢幕座標與亮度算好（塞到 dots），再用 HUD 在畫面上把 dots 畫成一顆顆發光圓點。
/*
void drawSpiralLEDs() {
  if (spiral1.size() == 0) return;
  
  // 建立 dots 容器（等等要畫的所有點）
  ArrayList<float[]> dots = new ArrayList<float[]>(); // {sx, sy, sz, v}

  // ===== 單螺旋：全亮 or 流動 =====
  if (spiralSolidMode) {
    collectSpiralDotsSolid(spiral1, dots, spiralSolidBri);
  } else {
    float head1 = (frameCount * spiralSpeed) % spiral1.size();
    collectSpiralDots(spiral1, head1, dots);
  }

  // ===== HUD 畫法維持不變 =====
  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);
  noStroke();
  
  // 每個點：決定大小 + 亮度，再畫 ellipse
  for (float[] d : dots) {
    float sx = d[0], sy = d[1], sz = d[2], v = d[3];

    float size = lerp(dotMax, dotMin, constrain(sz, 0, 1));
    float c = 255 * v;
    fill(c, c, c, 230);
    ellipse(sx, sy, size, size);
  }

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}
*/

void drawSpiralLEDs() {
  if (spiral1.size() == 0) return;

  // 先更新「一根一根」順時針掃的效果
  //updateClockwiseSpiral();
  //updateClockwiseAnyAxis();

  ArrayList<float[]> dots = new ArrayList<float[]>(); // {sx, sy, sz, v}
  collectSpiralDotsByColumns(spiral1, dots);

  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);
  noStroke();

  for (float[] d : dots) {
    float sx = d[0], sy = d[1], sz = d[2], v = d[3];

    float size = lerp(dotMax, dotMin, constrain(sz, 0, 1));
    float c = 255 * v;
    //fill(c, c, c, 230); //原本單白色
    fill(c * ledR, c * ledG, c * ledB, 230);
    ellipse(sx, sy, size, size);
  }

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}
