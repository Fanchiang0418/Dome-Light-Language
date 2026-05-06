// 用滑鼠位置 (mx,my) 去找「離滑鼠最近、而且距離小於 thresh」的那條邊，回傳它的 edge.id；如果沒有任何邊夠近就回傳 -1。
int findHoverEdgeId(ArrayList<Edge> edges, float mx, float my, float thresh) {
  if (edges == null || edges.size() == 0) return -1;

  int bestId = -1;
  float bestD = thresh;

  pushMatrix();
  translate(modelPos.x, modelPos.y, modelPos.z);
  rotateX(modelRotX);
  scale(modelScale);
  
  // 對每條邊：用「中點」當代表點，算它離滑鼠多遠
  for (int i = 0; i < edges.size(); i++) {
    Edge e = edges.get(i);
    PVector m = e.mid();
    float sx = screenX(m.x, m.y, m.z);
    float sy = screenY(m.x, m.y, m.z);

    float d = dist(mx, my, sx, sy);
    if (d < bestD) {
      bestD = d;
      bestId = e.id;
    }
  }

  popMatrix();
  return bestId;
}
