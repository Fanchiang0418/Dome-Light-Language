// LED編號

import java.util.HashSet;

boolean showPixelLabels = true;   // 顯示/隱藏編號
float labelSize = 12;             // 文字大小（會受你 scale 影響）
float labelOffset = 6;            // 文字離點的距離（避免蓋住點）

HashSet<Integer> hiddenPixels = new HashSet<Integer>(); // 要隱藏的 pixel index
float pickRadius3D = 10;          // 3D 空間內點選容差（越大越好點）

// 在 ribbonPath 上畫 index（要放在「模型同一套 transform」裡呼叫）
void drawRibbonPixelLabels() {
  if (!showPixelLabels) return;
  if (ribbonPath == null || ribbonPath.size() == 0) return;

  ArrayList<float[]> labels = new ArrayList<float[]>(); // {sx, sy, idx}

  // 這個函式會在你已經套好模型 transform 的情況下被呼叫（你是在 pushMatrix..popMatrix 裡呼叫）
  // 所以這裡直接 screenX/screenY 就是正確的
  for (int i = 0; i < ribbonPath.size(); i++) {
    if (hiddenPixels.contains(i)) continue;

    PVector p = ribbonPath.get(i);
    float sx = screenX(p.x, p.y, p.z);
    float sy = screenY(p.x, p.y, p.z);

    // 視野外不畫（省效能）
    if (sx < -50 || sx > width + 50 || sy < -50 || sy > height + 50) continue;

    labels.add(new float[]{sx, sy, i});
  }

  // 用 HUD 在 2D 畫文字（永遠正向）
  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);

  pushStyle();
  textAlign(CENTER, CENTER);
  textSize(labelSize);
  fill(255, 70);
  noStroke();

  for (float[] lab : labels) {
    float sx = lab[0];
    float sy = lab[1] - labelOffset; // 往上偏移一點
    int idx  = int(lab[2]);
    text(idx, sx, sy);
  }

  popStyle();

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}

// 找離某個 3D 點最近的 pixel（回傳 index，找不到回 -1）
int findNearestRibbonPixel(PVector q, float radius) {
  int best = -1;
  float bestD2 = radius * radius;

  for (int i = 0; i < ribbonPath.size(); i++) {
    PVector p = ribbonPath.get(i);
    float d2 = sq(p.x - q.x) + sq(p.y - q.y) + sq(p.z - q.z);
    if (d2 < bestD2) {
      bestD2 = d2;
      best = i;
    }
  }
  return best;
}

// 節點編號
boolean showNodeLabels = true;
float nodeLabelSize = 12;
float nodeLabelOffset = 8;

void drawMeshNodeLabels() {
  if (!showNodeLabels) return;
  if (orderedMeshNodes == null || orderedMeshNodes.size() == 0) return;

  ArrayList<float[]> labels = new ArrayList<float[]>();

  for (int i = 0; i < orderedMeshNodes.size(); i++) {
    PVector p = orderedMeshNodes.get(i);

    float sx = screenX(p.x, p.y, p.z);
    float sy = screenY(p.x, p.y, p.z);

    if (sx < -50 || sx > width + 50 || sy < -50 || sy > height + 50) continue;

    labels.add(new float[]{sx, sy, i});
  }

  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);

  pushStyle();
  textAlign(CENTER, CENTER);
  textSize(nodeLabelSize);
  fill(255, 180);
  noStroke();

  for (float[] lab : labels) {
    float sx = lab[0];
    float sy = lab[1] - nodeLabelOffset;
    int idx = int(lab[2]);
    text(idx, sx, sy);
  }

  popStyle();

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}
