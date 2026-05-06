// 從所有邊的端點 (a, b) 去算出整個模型在「模型座標系」下的包圍盒：bmin / bmax，再用這個包圍盒估算一個「球心 sphereC」跟「球半徑 sphereR」，給你後面做螺旋貼球面用。
void computeBoundsFromEdges(ArrayList<Edge> edges) {
  if (edges == null || edges.size() == 0) return;
  
  //  ===== 先找出模型的 bounding box：min/max  ===== 
  float minx =  1e9, miny =  1e9, minz =  1e9;
  float maxx = -1e9, maxy = -1e9, maxz = -1e9;

  for (Edge e : edges) {
    PVector[] ps = { e.a, e.b };
    for (PVector p : ps) {
      if (p.x < minx) minx = p.x;
      if (p.y < miny) miny = p.y;
      if (p.z < minz) minz = p.z;
      if (p.x > maxx) maxx = p.x;
      if (p.y > maxy) maxy = p.y;
      if (p.z > maxz) maxz = p.z;
    }
  }

  bmin.set(minx, miny, minz);
  bmax.set(maxx, maxy, maxz);

  //  ===== 用 bounding box 估球心 & 球半徑（給螺旋用） ===== 
  sphereC = PVector.add(bmin, bmax).mult(0.5);

  //  ===== 用 XZ 方向估半徑（比較像球的水平半徑） ===== 
  float rx = (bmax.x - bmin.x) * 0.5;
  float rz = (bmax.z - bmin.z) * 0.5;
  sphereR = max(rx, rz);

  println("Bounds min:", bmin, "max:", bmax, "sphereC:", sphereC, "sphereR:", sphereR);
}
