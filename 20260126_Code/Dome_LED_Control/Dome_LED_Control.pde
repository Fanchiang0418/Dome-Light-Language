import peasy.*;
import java.util.*;

// ===================== Camera / Model =====================
PeasyCam cam;
PShape model;

// 模型定位（你原本用的）
PVector modelPos = new PVector(0, 120, -400);
float modelRotX = PI;
float modelScale = 1.0;

// ===================== LED Matrix =====================
// ✅ 這裡視為 allEdges 的 id（你點邊印出來的那個編碼）
int[] ledEdgeIdx = {
1140, 4211, 5362,  3202,  3451, 4290, 5447, 969, 688, 157,//第一行槓
1082, 4898, 2489, 2196, 2929, 3564, 4730, 862, 4669, 4840 ,3921, 1346, 3396,  3701, 2071, 2837 , 4571,  3100,  84, 2526 ,1262, 5029,  490, 1903, 2025,  //第一層
//2416, 1329, 5490, 1720, 47, 3173, 4394, 4049, 1940, 5273, 3280, 2254, 2309, 1445, 4107,  //第二行槓
//2135, 5322,   636,   1497,  2889, 4800,   221,   398,  1775, 2593, 3063,   725,   325,  2370, 3536, //第二層(右)
//566, 1520,  1827,   1204,  3625, 3356,  3799,   804,   282, 5188, 3979, 3724, 4336, 905, 1656,//第二層(左)
//5160, 4942, 432, 3008, 3881, 1039, 4455, 2660, 2779, 5998, 7988, 2721, 5093,7800, 4519, 4171,//第三行槓
//8019,   8165, 12863,  6410, 11151, 6077, 13413, 12735, 14918, 12967, 9118,  9408, 10427, 10195, 14893,//第三層(右)
//10626, 13892, 11993, 14069,  9539, 7274, 10299, 14808,  6874, 8733, 14197, 11917,  7900,  8092,  7222,//第三層(左)
//9954, 13938, 13205, 12454, 14118, 13782, 6117, 10470, 12018, 7045, 13144, 9896, 10018, 8382, 13327,//第四行槓
//10519, 6624, 5827, 9490, 11209, 9194, 14454, 6291, 8266, 10107, 13596, 5726, 5928, 8611, 9777,//第四層(右)
//11682, 12906, 6816, 8428, 6245, 8321, 8654, 7399, 11355, 10986, 11813, 6709, 5772, 14222, 12213,//第四層(左)
//10864, 9316, 9368, 8196, 12335, 9585, 7561, 14710, 8483, 5543, 10757, 13022, 12271, 8956, 14350,//第五行槓
//5595, 7451, 6172, 9020, 13703, 9243, 11279, 6752, 13651, 7683, 11529, 10046, 10693,//第五層(右)
//9707, 13831, 8846, 7149, 9655, 10351, 13541, 13492, 12082, 11041, 9090, 13254,//第五層(左)
//6975, 6468, 5638, 7332, 12482, 14518, 10824, 11111, 12680, 14646,//第六行槓
//8901, 7521, 11450, 12631, 7857, 10925, 6938,//第六層(右)
//8794, 14600, 9829, 11630, 15003, 15052, 14777,//第六層(左)
//14295, 6532, 14396, 11569, 13361,//第七行槓
//6596, 7109, 11737,//第七層(右)
//13071, 10574,//第七層(左)
};
int numLights = ledEdgeIdx.length;   // columns
int numSegments = 20;                // rows
float[][] brightness = new float[numLights][numSegments];

// ===================== Edge lists =====================
ArrayList<Edge> allEdges = new ArrayList<>();
ArrayList<Edge> bottomDiagonals = new ArrayList<>();

// 抓底部 高度帶寬（越小越嚴格）
float bottomBand  = 8;
// 斜桿至少要有多少高度差（避免抓到水平邊）
float minDiagRise = 15;

// LED 像素大小
float dotRadius = 3.0;

// ===================== Labels / Picking =====================
boolean showEdgeLabels = true;
boolean labelAllEdges = false; // 按 A 切換
int labelStep = 1;
float pickThresh = 18;
PFont font;

// ===================== Animation =====================
float t = 0;

// ===================== Edge data structure =====================
class Edge {
  PVector a, b;
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

int hoverEdgeId = -1;
float hoverThresh = 16;   // hover 感應距離（像素），可調 12~25

float dotMin = 2;     // 最遠最小（像素）
float dotMax = 14;    // 最近最大（像素）

void setup() {
  size(1000, 700, P3D);
  smooth(8);

  cam = new PeasyCam(this, 600);
  cam.setMinimumDistance(200);
  cam.setMaximumDistance(3000);

  model = loadShape("dome2.obj");
  model.disableStyle();

  // 1) 建 allEdges（每條邊都有固定 id）
  allEdges.clear();
  collectEdgesRecursive(model, allEdges);
  println("allEdges =", allEdges.size());

  // 2) 從 allEdges 篩 bottomDiagonals（底部斜桿）
  bottomDiagonals = extractBottomDiagonals(allEdges, bottomBand, minDiagRise);
  println("bottomDiagonals =", bottomDiagonals.size());

  // 初始亮度
  for (int i = 0; i < numLights; i++) {
    for (int s = 0; s < numSegments; s++) brightness[i][s] = 10;
  }

  font = createFont("Arial", 12, true);
  textFont(font);
}

void draw() {
  background(15);

  // ===== 地板 =====
  pushMatrix();
  translate(0, 200, 0);
  rotateX(HALF_PI);
  noStroke();
  fill(40);
  rectMode(CENTER);
  rect(0, 0, 1600, 1600);
  popMatrix();

  // ===== 光源 =====
  lights();
  ambientLight(30, 30, 30);
  directionalLight(220, 220, 220, -0.4, -1.0, -0.2);

  // ===== 模型 + LED（同一套 transform）=====
  pushMatrix();
  translate(modelPos.x, modelPos.y, modelPos.z);
  rotateX(modelRotX);
  scale(modelScale);

  // 模型線框
  stroke(50);
  strokeWeight(1.2);
  noFill();
  shape(model);

  // LED：用 allEdges 的 id 去找邊
  drawLEDOnEdgesById(allEdges);

  popMatrix();

  hoverEdgeId = findHoverEdgeId(allEdges, mouseX, mouseY, hoverThresh);

  // Labels：按 A 切換顯示 allEdges / bottomDiagonals（顯示的永遠是 edge.id）
  drawEdgeLabels(labelAllEdges ? allEdges : bottomDiagonals);

  updateCalm();
  t += 0.02;

  drawHoverTooltip();
}

// =======================================================
// LED drawing: 依照 ledEdgeIdx（allEdges id）去找邊
// =======================================================
void drawLEDOnEdgesById(ArrayList<Edge> edges) {
  if (edges == null || edges.size() == 0) return;

  ArrayList<float[]> dots = new ArrayList<float[]>(); 
  // {sx, sy, sz, v}

  // ✅ 注意：這裡「不再」做 translate/rotate/scale
  // 因為你在 draw() 呼叫前已經套好模型 transform 了

  for (int k = 0; k < ledEdgeIdx.length; k++) {
    int targetId = ledEdgeIdx[k];
    if (targetId < 0 || targetId >= edges.size()) continue;

    Edge e = edges.get(targetId);

    PVector a = e.a.copy();
    PVector b = e.b.copy();
    if (a.y > b.y) { PVector tmp = a; a = b; b = tmp; }

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

  for (float[] d : dots) {
    float sx = d[0], sy = d[1], sz = d[2], v = d[3];

    float size = lerp(dotMax, dotMin, constrain(sz, 0, 1));
    float c = 255 * v;
    fill(c, c, c, 220);
    ellipse(sx, sy, size, size);
  }

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}

// =======================================================
// Extract bottom diagonals from "given edges list"
// =======================================================
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

// =======================================================
// Collect edges recursively (assign id == out.size())
// =======================================================
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

// =======================================================
// Labels (always show e.id, not list index)
// =======================================================
void drawEdgeLabels(ArrayList<Edge> edges) {
  if (!showEdgeLabels || edges == null || edges.size() == 0) return;

  ArrayList<float[]> labels = new ArrayList<float[]>();

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
    labels.add(new float[]{sx, sy, e.id}); // ✅ 顯示 allEdges id
  }
  popMatrix();

  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);

  textAlign(CENTER, CENTER);
  textSize(12);

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

void drawHoverTooltip() {
  if (hoverEdgeId == -1) return;

  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);

  String msg = "edge id: " + hoverEdgeId;

  textAlign(LEFT, TOP);
  textSize(13);

  float pad = 6;
  float tw = textWidth(msg);
  float x = mouseX + 12;
  float y = mouseY + 12;

  // 避免跑出畫面外
  if (x + tw + pad * 2 > width)  x = width - (tw + pad * 2) - 6;
  if (y + 18 + pad * 2 > height) y = height - (18 + pad * 2) - 6;

  noStroke();
  fill(0, 200);
  rectMode(CORNER);
  rect(x, y, tw + pad * 2, 18 + pad * 2, 6);

  fill(255);
  text(msg, x + pad, y + pad);

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}


// =======================================================
// Picking (return allEdges id)
// =======================================================
void mousePressed() {
  int id = pickEdgeId(allEdges, mouseX, mouseY, pickThresh);
  if (id != -1) println("Picked ALL edge id =", id);
  else println("No edge picked.");
}

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

// =======================================================
// Animation
// =======================================================
void updateLookUp() {
  float speed = 0.12;
  float level = (frameCount * speed) % (numSegments + 1);

  for (int i = 0; i < numLights; i++) {
    for (int s = 0; s < numSegments; s++) {
      float bri;
      if (s <= level) {
        float edge = abs(s - level);
        bri = map(edge, 0, 1.5, 100, 70);
      } else {
        bri = 5;
      }
      brightness[i][s] = constrain(bri, 0, 100);
    }
  }
}

// =======================================================
// Keys
// =======================================================
void keyPressed() {
  if (key == 'a' || key == 'A') labelAllEdges = !labelAllEdges;
  if (key == 'l' || key == 'L') showEdgeLabels = !showEdgeLabels;
  if (key == '-') labelStep++;
  if (key == '+' || key == '=') labelStep = max(1, labelStep - 1);

  println("labelAllEdges =", labelAllEdges,
    "labelStep =", labelStep,
    "showEdgeLabels =", showEdgeLabels);
}

int findHoverEdgeId(ArrayList<Edge> edges, float mx, float my, float thresh) {
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

void updateCalm() {
  float t = frameCount * 0.02;
  float base = map(sin(t), -1, 1, 30, 80);  // 整體亮度

  for (int i = 0; i < numLights; i++) {
    for (int s = 0; s < numSegments; s++) {
      float offset = (i + s) * 0.1;
      brightness[i][s] = constrain(base + 5 * sin(t + offset), 0, 100);
    }
  }
}
