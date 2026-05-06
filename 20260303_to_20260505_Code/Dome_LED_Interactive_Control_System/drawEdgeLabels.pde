// 一條邊長什麼樣子

class Edge {
  PVector a, b; // 兩個端點（3D 座標）
  float ang;
  int id; // allEdges 的固定編號

  Edge(PVector a, PVector b, int id) {
    this.a = a;
    this.b = b;
    this.id = id;
  }

  PVector mid() {
    return PVector.add(a, b).mult(0.5);
  }
}

// 把每條邊的 id 畫出來 (把每條邊的「中點」投影到螢幕座標，然後在那個位置畫一個小黑底框 + 白色數字（edge.id）)
void drawEdgeLabels(ArrayList<Edge> edges) {
  if (!showEdgeLabels || edges == null || edges.size() == 0) return;
  ArrayList<float[]> labels = new ArrayList<float[]>();

  //  ===== 算位置、收集資料  ===== 
  pushMatrix();
  translate(modelPos.x, modelPos.y, modelPos.z);
  rotateX(modelRotX);
  scale(modelScale);

  for (int i = 0; i < edges.size(); i += labelStep) {
    Edge e = edges.get(i);
    PVector m = e.mid();

    float sx = screenX(m.x, m.y, m.z);
    float sy = screenY(m.x, m.y, m.z);

    if (sx < 0 || sx > width || sy < 0 || sy > height) continue;
    labels.add(new float[]{sx, sy, e.id}); // 顯示 allEdges id
  }
  popMatrix();

  //  ===== 用 HUD 在 2D 畫上標籤（不被深度遮擋） ===== 
  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);

  textAlign(CENTER, CENTER);
  textSize(12);

  //  ===== 對每個 label 畫背景框 + id 數字  ===== 
  for (float[] lab : labels) {
    float sx = lab[0];
    float sy = lab[1];
    int id   = int(lab[2]);

    noStroke();
    fill(0, 170);
    rectMode(CENTER);
    rect(sx, sy, 34, 14, 3);

    fill(255);
    text(id, sx, sy);
  }

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}
