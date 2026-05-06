// 知道它的 allEdges id 是多少
void mousePressed() {
  int id = pickEdgeId(allEdges, mouseX, mouseY, pickThresh);
  if (id != -1) println("Picked ALL edge id =", id);
  else println("No edge picked.");
}

// 怎麼判斷你點到哪條邊
int pickEdgeId(ArrayList<Edge> edges, float mx, float my, float thresh) {
  if (edges == null || edges.size() == 0) return -1;

  int bestId = -1;
  float bestD = thresh;

  pushMatrix();
  translate(modelPos.x, modelPos.y, modelPos.z);
  rotateX(modelRotX);
  scale(modelScale);

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
