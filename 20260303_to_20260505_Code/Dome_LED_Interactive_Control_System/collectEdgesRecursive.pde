// 把整個 PShape（含所有子物件）裡的「線段邊」全部抽出來，存成 Edge(a,b,id) 放進 out，並且給每一條邊一個固定的 id（就是 out.size() 當下的序號）。
// 提供了 模型 bounds → sphereC/sphereR，所以螺旋會「靠它算出來的球心半徑」來貼球面
void collectEdgesRecursive(PShape s, ArrayList<Edge> out) {
  int cc = s.getChildCount();
  if (cc > 0) {
    for (int i = 0; i < cc; i++) collectEdgesRecursive(s.getChild(i), out);
    return;
  }

  int vc = s.getVertexCount();
  if (vc < 2) return;

  int kind = s.getKind();

  if (kind == LINES) {
    for (int i = 0; i + 1 < vc; i += 2) {
      PVector a = s.getVertex(i).copy();
      PVector b = s.getVertex(i + 1).copy();
      out.add(new Edge(a, b, out.size()));
    }
  } else {
    for (int i = 0; i + 1 < vc; i++) {
      PVector a = s.getVertex(i).copy();
      PVector b = s.getVertex(i + 1).copy();
      out.add(new Edge(a, b, out.size()));
    }
  }
}
