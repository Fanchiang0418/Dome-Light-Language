// ===== 8 ===== 只保留球內螺旋 + 底部半徑擴張
// 參數：螺旋
float ribbonTurns   = 6.0;       // 環繞幾圈
float ribbonOutOff  = 22.0;      // 起點在球面外偏移
float ribbonInOff   = -58.0;     // 終點在球面內偏移(負=往內)
float ribbonY0      = 0.10;      // 螺旋開始高度(0..1)
float ribbonY1      = 0.85;      // 螺旋結束高度(0..1)
float entranceAng   = -PI*0.25;  // 螺旋入口角度

// 外圍刪掉
boolean addOuterRing = false;

// 底部半徑擴張（只影響螺旋最底層附近）
float bottomBoost = 1;   // 最底層額外加多少半徑（建議 30~120）
float bottomSpan  = 0.18; // 影響範圍(0..1)：越大越往上影響（0.12~0.30）
float bottomPow   = 2.6;  // 集中程度：越大越集中在最底（1.5~4）

// 工具：0..1 平滑
float smooth01(float x) {
  x = constrain(x, 0, 1);
  return x*x*(3-2*x);
}

// 從第幾個Pixel開始
int exitStartPixel = 4; // 第5個pixel

// 主：建立「球內螺旋」
void buildSpiralsOnSphere() {
  ribbonPath.clear();
  if (spiralPixels < 10) spiralPixels = 10;

  float yMin = lerp(bmin.y, bmax.y, ribbonY0);
  float yMax = lerp(bmin.y, bmax.y, ribbonY1);

  // 1) 球內螺旋
  for (int i = 0; i < spiralPixels; i++) {
    float u = (spiralPixels == 1) ? 0 : i / float(spiralPixels - 1);

    float y = lerp(yMin, yMax, u);
    float ang = entranceAng + TWO_PI * ribbonTurns * u;

    float dy = y - sphereC.y;
    float rY2 = sphereR * sphereR - dy * dy;
    float rY = (rY2 <= 0) ? 0 : sqrt(rY2);

    float k = smooth01(u);
    float off = lerp(ribbonOutOff, ribbonInOff, k);
    float rr = max(0, rY + off);

    // 底部半徑加大：只在 u 靠近 0 的區域加，往上快速衰減
    float w = 0;
    if (bottomSpan > 1e-6) {
      // u=0 ->1, u>=bottomSpan ->0
      w = 1.0 - constrain(u / bottomSpan, 0, 1);
      w = pow(w, bottomPow);
    }
    rr += bottomBoost * w;
    rr = max(0, rr);

    PVector p = new PVector(
      sphereC.x + rr * cos(ang),
      y,
      sphereC.z + rr * sin(ang)
      );

    ribbonPath.add(p);
  }

  // 螺旋算完後：隱藏前 4 顆
  int hideN = 4;
  hideN = min(hideN, ribbonPath.size());
  for (int k = 0; k < hideN; k++) ribbonPath.remove(0);

  // 出口線從「新的起點」接出去（=原本第5顆）
  if (ribbonPath.size() > 0) {
    prependExitLineFrom(ribbonPath.get(0));
  }
}

// S曲線
boolean addExitLine = true;
int   exitPixels    = 70;   // 總點數
float exitLen    = 520;   // 向外延伸距離
float exitDrop   = 30;   // 往下掉到地面的量
float exitAngOff = 0.0;   // 水平轉向（繞Y）

float sAmp   = 260;  // S 的左右擺幅（越大彎越誇張）
float sBias  = 0.55; // S 轉折位置(0..1) 0.5 附近最像 S
float sTight = 0.75; // 彎得多緊(0.3~1.2) 越大越集中在中段

// 圓角轉彎的「半徑」與「佔比」
float bendRadius    = 120;  // 圓角半徑（越大轉彎越柔）
float bendPortion   = 0.45; // 0..1：前段用來做圓角轉彎的比例

// 可選：讓它稍微像手繪那樣抖動（很小就好）
float orgAmpExit    = 0.0;  // 0=不抖；建議 2~8
float orgFreqExit   = 1.2;
float orgAnimExit   = 0.01;

//---
PVector rotYVec(PVector v, float a) {
  float ca = cos(a), sa = sin(a);
  return new PVector(
    v.x * ca - v.z * sa,
    v.y,
    v.x * sa + v.z * ca
    );
}

//---
float exitBendRoll = -HALF_PI; // 彎曲平面旋轉角（繞 fwd 軸）

PVector rotAroundAxis(PVector v, PVector axis, float a) {
  axis = axis.copy();
  axis.normalize();
  float ca = cos(a), sa = sin(a);

  // Rodrigues' rotation formula
  PVector term1 = PVector.mult(v, ca);
  PVector term2 = PVector.mult(axis.cross(v), sa);
  PVector term3 = PVector.mult(axis, axis.dot(v) * (1 - ca));
  return PVector.add(PVector.add(term1, term2), term3);
}

// ---
PVector bezier3(PVector p0, PVector p1, PVector p2, PVector p3, float t) {
  float u = 1.0 - t;
  float b0 = u*u*u;
  float b1 = 3*u*u*t;
  float b2 = 3*u*t*t;
  float b3 = t*t*t;
  return new PVector(
    p0.x*b0 + p1.x*b1 + p2.x*b2 + p3.x*b3,
    p0.y*b0 + p1.y*b1 + p2.y*b2 + p3.y*b3,
    p0.z*b0 + p1.z*b1 + p2.z*b2 + p3.z*b3
    );
}

// 等距重取樣
ArrayList<PVector> resampleEqualDistance(ArrayList<PVector> pts, int targetCount) {
  ArrayList<PVector> out = new ArrayList<PVector>();
  if (pts == null || pts.size() < 2 || targetCount <= 1) {
    if (pts != null && pts.size() > 0) out.add(pts.get(0).copy());
    return out;
  }

  // 累積長度
  int n = pts.size();
  float[] cum = new float[n];
  cum[0] = 0;
  for (int i = 1; i < n; i++) {
    cum[i] = cum[i-1] + PVector.dist(pts.get(i-1), pts.get(i));
  }
  float total = cum[n-1];
  if (total < 1e-6) {
    // 全部點幾乎同位置
    for (int k = 0; k < targetCount; k++) out.add(pts.get(0).copy());
    return out;
  }

  // 等距取樣
  for (int k = 0; k < targetCount; k++) {
    float d = total * (k / float(targetCount - 1)); // 0..total

    // 找到 cum[i-1] <= d <= cum[i]
    int i = 1;
    while (i < n && cum[i] < d) i++;

    if (i >= n) {
      out.add(pts.get(n-1).copy());
    } else {
      float d0 = cum[i-1], d1 = cum[i];
      float tt = (d1 - d0 < 1e-6) ? 0 : (d - d0) / (d1 - d0);
      PVector a = pts.get(i-1);
      PVector b = pts.get(i);
      out.add(PVector.lerp(a, b, tt));
    }
  }
  return out;
}

// 「最小間距」過濾(69_70顆)
ArrayList<PVector> removeTooClose(ArrayList<PVector> pts, float minDist) {
  ArrayList<PVector> out = new ArrayList<PVector>();
  if (pts == null || pts.size() == 0) return out;

  float md2 = minDist * minDist;
  out.add(pts.get(0).copy());

  for (int i = 1; i < pts.size(); i++) {
    PVector p = pts.get(i);
    PVector last = out.get(out.size() - 1);
    float d2 = sq(p.x - last.x) + sq(p.y - last.y) + sq(p.z - last.z);
    if (d2 >= md2) out.add(p.copy());
  }
  return out;
}

// ------------------------------------------------------
void prependExitLineFrom(PVector start) {
  if (!addExitLine) return;
  if (exitPixels < 4) exitPixels = 4;

  // 出口方向：球心 -> start 的放射方向（投影到 XZ）
  PVector fwd = new PVector(start.x - sphereC.x, 0, start.z - sphereC.z);
  if (fwd.magSq() < 1e-6) fwd = new PVector(1, 0, 0);
  fwd.normalize();
  fwd = rotYVec(fwd, exitAngOff);

  // 左右方向（水平）
  PVector up = new PVector(0, 1, 0);
  PVector side = up.cross(fwd);
  if (side.magSq() < 1e-6) side = new PVector(0, 0, 1);
  side.normalize();
  side.mult(-1);

  // --- 端點 ---
  PVector p0 = start.copy();
  PVector p3 = start.copy();
  p3.add(PVector.mult(fwd, exitLen));
  p3.y -= exitDrop;

  // --- 控制點：做出 S ---
  // p1：先往外一點點 + 往下（讓它離開球後下降）
  PVector p1 = start.copy();
  p1.add(PVector.mult(fwd, exitLen * 0.22));
  p1.y -= exitDrop * 0.65;

  // p2：更往外 + 往下（接近地面），並在 side 方向給反向偏移
  // 這個偏移會和 p1 的偏移方向相反 => 形成 S
  float push = sAmp;
  PVector p2 = start.copy();
  p2.add(PVector.mult(fwd, exitLen * 0.72));
  p2.y -= exitDrop * 1.00;

  // 用一個集中在中段的權重，讓「側向推」主要發生在中間
  // u 越接近 sBias，權重越大
  float w = 1.0; // 這裡是控制點的固定推，不用逐點算

  // 先高密度取樣（越大越準）
  int denseN = max(exitPixels * 8, 600);
  ArrayList<PVector> dense = new ArrayList<PVector>();

  for (int i = 0; i < denseN; i++) {
    float t = (denseN == 1) ? 0 : i / float(denseN - 1);
    float t2 = 1.0 - t; // 外->內（保持你原本方向）
    PVector p = bezier3(p0, p1, p2, p3, t2);

    // S 擺動（同你原本）
    float u = t; // 0..1（由內到外）
    float denom = (u < sBias) ? max(1e-6, sBias) : max(1e-6, 1.0 - sBias);
    float ww = 1.0 - abs(u - sBias) / denom;
    ww = constrain(ww, 0, 1);
    ww = pow(ww, 1.0 / max(1e-6, sTight));
    float s = sin(TWO_PI * u);
    p.add(PVector.mult(side, sAmp * s * ww));

    dense.add(p);
  }

  // 等距重取樣成 exitPixels
  ArrayList<PVector> seg = resampleEqualDistance(dense, exitPixels);
  // 去掉太靠近的點（避免 69/70 重疊）
  seg = removeTooClose(seg, 1.5);  // 1.0~4.0 之間試，取決於你的模型尺度

  // 若過濾後數量變少，再補回 exitPixels（保持固定顆數）
  if (seg.size() >= 2 && seg.size() != exitPixels) {
    seg = resampleEqualDistance(seg, exitPixels);
  }

  // 可選：等距後再抖動（抖太大會破壞等距，建議 orgAmpExit <= 2）
  if (orgAmpExit > 0) {
    for (int i = 0; i < seg.size(); i++) {
      PVector p = seg.get(i);
      float time = frameCount * orgAnimExit;
      float nx = noise(i * 0.17 * orgFreqExit + 10, time) * 2 - 1;
      float ny = noise(i * 0.17 * orgFreqExit + 20, time) * 2 - 1;
      float nz = noise(i * 0.17 * orgFreqExit + 30, time) * 2 - 1;
      p.add(nx * orgAmpExit, ny * orgAmpExit * 0.25, nz * orgAmpExit);
    }
  }

  if (seg.size() > 0) seg.remove(seg.size() - 1); // 移除接點那顆，避免跟螺旋第一顆重疊
  
  ribbonPath.addAll(0, seg); // 插到 ribbonPath 前面
}
