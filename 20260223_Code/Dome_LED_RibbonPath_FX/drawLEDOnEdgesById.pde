// 依照 ledEdgeIdx[] 指定的邊 id（從 allEdges 找到那條邊），沿著每條邊切成 numSegments 段，讀取 brightness[k][s] 當亮度，把每段的 3D 點投影到螢幕座標，最後用 HUD 在畫面上畫一顆顆 2D 圓點，形成「沿著邊排列的 LED 像素」。
void drawLEDOnEdgesById(ArrayList<Edge> edges) {
  if (edges == null || edges.size() == 0) return;

  ArrayList<float[]> dots = new ArrayList<float[]>();
  // 注意：這裡「不再」做 translate/rotate/scale，因為你在 draw() 呼叫前已經套好模型 transform 了
  
  // 逐條 LED 邊：k 對應到 ledEdgeIdx[k]
  for (int k = 0; k < ledEdgeIdx.length; k++) {
    int targetId = ledEdgeIdx[k];
    if (targetId < 0 || targetId >= edges.size()) continue;

    Edge e = edges.get(targetId);
    
    // 把邊端點排序：確保 a 在下、b 在上
    PVector a = e.a.copy();
    PVector b = e.b.copy();
    if (a.y > b.y) {
      PVector tmp = a;
      a = b;
      b = tmp;
    }
    
    // 沿著每條邊切成 numSegments 個 LED 點
    for (int s = 0; s < numSegments; s++) {
      float u = (s + 0.5) / numSegments;
      PVector p = PVector.lerp(a, b, u);

      float bri = brightness[k][s];
      float v = constrain(bri / 100.0, 0, 1);

      float sx = screenX(p.x, p.y, p.z);
      float sy = screenY(p.x, p.y, p.z);
      float sz = screenZ(p.x, p.y, p.z);

      dots.add(new float[]{sx, sy, sz, v});
    }
  }

  // HUD 畫 2D 圓點
  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);
  noStroke();

  // 每個 dot 畫一個圓：遠小近大 + 亮度控制
  for (float[] d : dots) {
    float sx = d[0], sy = d[1], sz = d[2], v = d[3];

    float size = lerp(dotMax, dotMin, constrain(sz, 0, 1));
    float c = 255 * v;
    //fill(c, c, c, 220); //原本單白色
    fill(c * ledR, c * ledG, c * ledB, 220);
    ellipse(sx, sy, size, size);
  }

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}
