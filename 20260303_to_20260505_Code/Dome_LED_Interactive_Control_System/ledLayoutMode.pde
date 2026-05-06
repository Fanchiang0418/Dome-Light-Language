// LED 排列形式三種切換、在 OBJ 模型的頂點上作為節點式 LED 表現

// 模型 LED 形式切換
final int LAYOUT_EDGE   = 0;
final int LAYOUT_RIBBON = 1;
final int LAYOUT_VERTEX = 2;

int ledLayoutMode = LAYOUT_RIBBON;  // 預設你原本的螺旋模式
String[] layoutNames = {"EDGE", "RIBBON", "VERTEX"};

ArrayList<PVector> meshNodes = new ArrayList<PVector>(); // 儲存模型去重複後的頂點座標
float vertexMergeEps = 3.0;   // 去重複用，依模型尺度可調(兩點距離小於等於 0.01，就視為同一個 vertex)

// 直接抓 OBJ 的 vertex
void collectVerticesRecursive(PShape s, ArrayList<PVector> out, float eps) {
  int cc = s.getChildCount();
  if (cc > 0) {
    for (int i = 0; i < cc; i++) {
      collectVerticesRecursive(s.getChild(i), out, eps);
    }
    return;
  }

  int vc = s.getVertexCount();
  if (vc <= 0) return;

  for (int i = 0; i < vc; i++) {
    PVector p = s.getVertex(i).copy();
    addUniqueVertex(out, p, eps);
  }
}

// 把頂點加入清單，但如果和既有頂點太接近，就不重複加入
void addUniqueVertex(ArrayList<PVector> out, PVector p, float eps) {
  float eps2 = eps * eps;

  for (int i = 0; i < out.size(); i++) {
    PVector q = out.get(i);
    float d2 = sq(p.x - q.x) + sq(p.y - q.y) + sq(p.z - q.z);
    if (d2 <= eps2) return; // 視為同一點，不加入
  }

  out.add(p.copy());
}

float nodeDotScale = 1.6;   // 節點 pixel 放大倍率

// 把 meshNodes 裡的每個頂點，當成 LED 節點畫到畫面上 (節點 LED 樣式)
void drawMeshNodeLEDs() {
  if (orderedMeshNodes == null || orderedMeshNodes.size() == 0) return;

  ArrayList<float[]> dots = new ArrayList<float[]>();

  for (int i = 0; i < orderedMeshNodes.size(); i++) {
    PVector p = orderedMeshNodes.get(i);

    float v = evalVertexV(i); // 節點_序列模式

    float sx = screenX(p.x, p.y, p.z);
    float sy = screenY(p.x, p.y, p.z);
    float sz = screenZ(p.x, p.y, p.z);

    dots.add(new float[]{sx, sy, sz, v});
  }

  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);
  noStroke();

  for (float[] d : dots) {
    float sx = d[0], sy = d[1], sz = d[2], v = d[3];
    float size = lerp(dotMax, dotMin, constrain(sz, 0, 1)) * nodeDotScale;
    float c = 255 * v;
    fill(c * ledR, c * ledG, c * ledB, 230);
    ellipse(sx, sy, size, size);
  }

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}

ArrayList<PVector> orderedMeshNodes = new ArrayList<PVector>(); // 排序後的節點陣列

// 把原本散亂的 meshNodes 節點，依照高度先分層，再把每一層按照繞球心的角度排序，最後整理成有順序的 orderedMeshNodes
void buildOrderedMeshNodes() {
  orderedMeshNodes.clear();
  if (meshNodes == null || meshNodes.size() == 0) return;

  ArrayList<PVector> temp = new ArrayList<PVector>();
  for (PVector p : meshNodes) {
    temp.add(p.copy());
  }

  float minY = 1e9;
  float maxY = -1e9;
  for (PVector p : temp) {
    if (p.y < minY) minY = p.y;
    if (p.y > maxY) maxY = p.y;
  }

  int layerCount = 16;   // 先比 12 多一點，讓每層點數少一點
  float layerH = (maxY - minY) / max(1, layerCount);

  ArrayList<ArrayList<PVector>> layers = new ArrayList<ArrayList<PVector>>();
  for (int i = 0; i < layerCount; i++) {
    layers.add(new ArrayList<PVector>());
  }

  for (PVector p : temp) {
    int li = int((p.y - minY) / max(0.0001, layerH));
    li = constrain(li, 0, layerCount - 1);
    layers.get(li).add(p);
  }

  for (int li = 0; li < layerCount; li++) {
    ArrayList<PVector> layer = layers.get(li);

    Collections.sort(layer, new Comparator<PVector>() {
      public int compare(PVector p1, PVector p2) {
        float a1 = atan2(p1.z - sphereC.z, p1.x - sphereC.x);
        float a2 = atan2(p2.z - sphereC.z, p2.x - sphereC.x);
        return Float.compare(a1, a2);
      }
    });

    for (PVector p : layer) {
      orderedMeshNodes.add(p);
    }
  }

  println("orderedMeshNodes count = " + orderedMeshNodes.size());
}

// 手動交換 orderedMeshNodes 裡兩個節點的順序，用來修正節點排序不理想或燈效跑錯位置的情況
void swapOrderedNodes(int a, int b) {
  if (orderedMeshNodes == null) return;
  if (a < 0 || b < 0 || a >= orderedMeshNodes.size() || b >= orderedMeshNodes.size()) {
    println("[SWAP ERROR] index out of range: " + a + ", " + b);
    return;
  }

  PVector tmp = orderedMeshNodes.get(a);
  orderedMeshNodes.set(a, orderedMeshNodes.get(b));
  orderedMeshNodes.set(b, tmp);

  println("[SWAP OK] swapped " + a + " <-> " + b);
}

// 手動交換 orderedMeshNodes 裡兩個節點的順序，用來修正節點排序不理想或燈效跑錯位置的情況
void applyManualNodeSwaps() {
  swapOrderedNodes(9, 11);
  swapOrderedNodes(10, 11);
  swapOrderedNodes(57, 58);
  swapOrderedNodes(65, 66);
  swapOrderedNodes(67, 68);
  swapOrderedNodes(70, 71);
  swapOrderedNodes(72, 71);
}
