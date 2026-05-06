// 把螺旋上的每一個 3D 點都轉成螢幕座標 (sx, sy, sz)，並且依照它離「亮點頭 head」有多遠，算出一個帶高斯拖尾的亮度 v，最後把 (sx, sy, sz, v) 丟進 outDots 讓後面用 HUD 畫出發光點。
// 一條螺旋上有一個「亮點頭」在跑 (燈效)
void collectSpiralDots(ArrayList<PVector> spiral, float head, ArrayList<float[]> outDots) {
  int n = spiral.size();
  for (int i = 0; i < n; i++) {
    PVector p = spiral.get(i);

    // 環狀距離（讓亮點循環）
    float d = abs(i - head);
    d = min(d, n - d);

    // 高斯拖尾
    float glow = exp(-(d * d) / (2.0 * spiralSigma * spiralSigma));

    float bri = spiralBase + spiralPeak * glow;  // 0~100
    float v = constrain(bri / 100.0, 0, 1);
    
    // 3D 點投影到螢幕 (HUD 要用)
    float sx = screenX(p.x, p.y, p.z);
    float sy = screenY(p.x, p.y, p.z);
    float sz = screenZ(p.x, p.y, p.z);

    outDots.add(new float[]{sx, sy, sz, v});
  }
}
