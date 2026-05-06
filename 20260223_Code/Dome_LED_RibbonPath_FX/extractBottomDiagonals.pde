// 從 allEdges 裡挑出「靠近模型最底部的一圈、而且是斜的（有高度差）」的邊，並依照它們繞圓周的角度排序，回傳成 bottomDiagonals。
ArrayList<Edge> extractBottomDiagonals(ArrayList<Edge> edges, float band, float minRise) {
  ArrayList<Edge> picked = new ArrayList<>();
  if (edges == null || edges.size() == 0) return picked;

  // 找全模型最低點
  float yMin = Float.MAX_VALUE;
  for (Edge e : edges) {
    yMin = min(yMin, min(e.a.y, e.b.y));
  }

  // 篩底部斜邊
  for (Edge e : edges) {
    float low  = min(e.a.y, e.b.y);
    float high = max(e.a.y, e.b.y);
    float rise = high - low;

    if (low <= yMin + band && rise >= minRise) {
      PVector m = e.mid();
      e.ang = atan2(m.z, m.x);
      picked.add(e);
    }
  }

  // 依角度排序：讓順序沿著圓周
  Collections.sort(picked, new Comparator<Edge>() {
    public int compare(Edge e1, Edge e2) {
      return Float.compare(e1.ang, e2.ang);
    }
  }
  );

  return picked;
}
