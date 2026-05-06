// 子畫面*2

// ===================== 子畫面一 =====================
PGraphics flatView;
boolean showFlatView = true;
int flatW = 720;
int flatH = 560;
float flatDot = 4.0; // 平面視窗裡 LED 點大小

// 子畫面一 (文字設定)
boolean showFlatLabels = true; // 子畫面顯示編號
int flatLabelStep = 10;        // 每隔幾顆標一次（避免太擠，5~20 自己調）
float flatLabelSize = 14;      // 子畫面字體大小
float flatLabelBgA = 130;      // 文字背景透明度

// ===================== 子畫面二 =====================
PGraphics pixelMapView;
boolean showPixelMapView = true;
float pixelMapScale = 1.0; // 想放大幾倍就改這裡：1.2 / 1.5 / 2.0 / 3.0
float pixelMapYOffset = 280;   // 子視窗二往下移多少（ 0~400）
float pixelMapXOffset = -360;   // 往右移多少（自己調，負值=往左）
int pixelMapExtraW = 0;  // 讓背景左右更寬
int pixelMapExtraH = 0;   // 讓背景上下更高
int pixelMapHeaderH = 28;   // 上方黑色區域高度（想更長就加大：40~120）
int pixelMapExtraLeft = 100; // 左邊黑底要多長（像素），自己調 80~600
float pixelDotsXShift = -110;  // 綠點整體往右（像素），可調 20~400
int extraTop = 0;     // 上面多留多少
int extraBottom = 0;  // 下面多留多少
int pixelRowGap = 6;   // 行與行額外間距（像素），0~20 自己調

// 你指定的列範圍（包含頭尾）
int[] rowStart = { 0, 69, 138, 255, 371, 488, 604, 721 };
int[] rowEnd   = { 68, 137, 254, 370, 487, 603, 720, 764 };

// 視窗大小與格子設定
int pixCell = 12;      // 每顆 pixel 的格子間距（6~14 自己調）
int pixPad  = 16;     // 內邊界
int pixDot  = 6;      // 點大小（<= pixCell 比較好看）
boolean showPixelMapLabels = false; // 要不要在平面圖上畫 index（很擠，預設關）
int pixelMapLabelStep = 10;         // 每隔幾顆標一次

// 單行Pixel的位移
int firstRowShiftCols = 0;  // 第一行左移 44 顆（正值=左移）
int secondRowShiftCols = 0;  // 第二行左移 23 顆（正值=左移）
int lastRowShiftCols = 0;   // ✅ 最後一行左移 32 顆（正值=左移）

// ===================== 子畫面一 =====================
void renderFlatViewRibbon() {
  if (flatView == null) return;

  flatView.beginDraw();
  flatView.background(10);
  flatView.noStroke();

  // 畫邊框 / 網格（可選）
  flatView.noStroke();
  flatView.noFill();
  flatView.rect(0, 0, flatW-1, flatH-1);
  flatView.noStroke();

  // 把 ribbonPath 的每個「加厚點」也畫進來，重算「加厚後的 3D 點 pp」，並取樣亮度 bri，然後映射到平面
  int n = ribbonPath.size();
  if (n == 0) {
    flatView.endDraw();
    return;
  }

  int rows = max(1, ribbonThicknessRows);
  int half = rows / 2;

  for (int idx = 0; idx < n; idx++) {
    if (hiddenPixels.contains(idx)) continue; // 被隱藏的 index 直接跳過

    PVector p = ribbonPath.get(idx);

    // ===== collectSpiralDotsByColumns：算 dir（厚度方向）=====
    PVector pPrev = ribbonPath.get(max(0, idx - 1));
    PVector pNext = ribbonPath.get(min(n - 1, idx + 1));
    PVector tan = PVector.sub(pNext, pPrev);
    if (tan.magSq() < 1e-6) tan = new PVector(1, 0, 0);
    tan.normalize();

    PVector up = new PVector(0, 1, 0);
    PVector side = tan.cross(up);
    if (side.magSq() < 1e-6) side = new PVector(1, 0, 0);
    side.normalize();

    PVector bin = side.cross(tan);
    if (bin.magSq() < 1e-6) bin = new PVector(0, 1, 0);
    bin.normalize();

    PVector dir = bin;

    if (attachToSphere) {
      float dC = PVector.dist(p, sphereC);
      float distToSurface = abs(dC - sphereR);
      boolean onSphere = (distToSurface < sphereR * 0.25);

      if (onSphere) {
        PVector normal = PVector.sub(p, sphereC);
        if (normal.magSq() < 1e-6) normal = new PVector(0, 1, 0);
        normal.normalize();

        PVector surfUp = PVector.sub(up, PVector.mult(normal, up.dot(normal)));
        if (surfUp.magSq() < 1e-6) surfUp = bin.copy();
        surfUp.normalize();

        dir = PVector.lerp(bin, surfUp, attachBlend);
        if (dir.magSq() < 1e-6) dir = surfUp.copy();
        dir.normalize();
      }
    }

    // ===== 三個視窗燈光同步 ===== 
    float vBri = evalPixelV(idx);
    float c = 255 * vBri;

    // ===== 加厚：產生 pp，再映射到 2D（u,v）=====
    if (rows % 2 == 1) {
      for (int r = -half; r <= half; r++) {
        float off = r * ribbonRowSpacing;
        PVector pp = PVector.add(p, PVector.mult(dir, off));
        plotPointOnFlat(pp, c);
      }
    } else {
      for (int k = 0; k < rows; k++) {
        float r = (k - (rows - 1) * 0.5);
        float off = r * ribbonRowSpacing;
        PVector pp = PVector.add(p, PVector.mult(dir, off));
        plotPointOnFlat(pp, c);
      }
    }
  }

  // ===== 子畫面 LED 編號（只標中心點 idx，不標厚度列）=====
  if (showFlatLabels) {
    flatView.textAlign(CENTER, CENTER);
    flatView.textSize(flatLabelSize);

    for (int idx = 0; idx < ribbonPath.size(); idx += flatLabelStep) {
      if (hiddenPixels.contains(idx)) continue;

      PVector p = ribbonPath.get(idx);
      PVector xy = flatXY(p);

      // 小黑底讓字看得清楚
      String s = str(idx);
      float tw = flatView.textWidth(s) + 6;
      float th = flatLabelSize + 4;

      flatView.noStroke();
      flatView.fill(0, flatLabelBgA);
      flatView.rectMode(CENTER);
      flatView.rect(xy.x, xy.y, tw, th, 4);

      flatView.fill(255, 210);
      flatView.text(s, xy.x, xy.y);
    }
  }

  flatView.endDraw();
}

// ===================== 把 3D 點轉成平面座標並畫點 =====================
void plotPointOnFlat(PVector pp, float c) {
  // u: 經度
  float theta = atan2(pp.z - sphereC.z, pp.x - sphereC.x);
  float u = (theta + PI) / TWO_PI; // 0..1

  // v: 用高度（適合 dome）
  float v = (pp.y - bmin.y) / max(1e-6, (bmax.y - bmin.y));
  v = 1.0 - constrain(v, 0, 1);

  float x2 = u * (flatW - 1);
  float y2 = v * (flatH - 1);

  flatView.noStroke();
  flatView.fill(c * ledR, c * ledG, c * ledB, 220);
  flatView.ellipse(x2, y2, flatDot, flatDot);
}

// ===================== 3D點 → 子畫面2D座標(小工具) =====================
PVector flatXY(PVector p) {
  // u: 經度（左右）
  float theta = atan2(p.z - sphereC.z, p.x - sphereC.x);
  float u = (theta + PI) / TWO_PI; // 0..1

  // v: 用高度（上下，適合 dome）
  float v = (p.y - bmin.y) / max(1e-6, (bmax.y - bmin.y));
  v = 1.0 - constrain(v, 0, 1); // 上面在上

  float x2 = u * (flatW - 1);
  float y2 = v * (flatH - 1);
  return new PVector(x2, y2);
}

// ===================== 子畫面二 =====================
void renderPixelMapView() {
  if (pixelMapView == null) return;

  pixelMapView.beginDraw();
  pixelMapView.background(10);

  // 外框
  pixelMapView.stroke(0);
  pixelMapView.noFill();
  pixelMapView.rect(0, 0, pixelMapView.width - 1, pixelMapView.height - 1);
  pixelMapView.noStroke();

  // 如果 ribbonPath 不夠長，至少不要爆掉
  int n = (ribbonPath == null) ? 0 : ribbonPath.size();
  if (n == 0) {
    pixelMapView.endDraw();
    return;
  }

  // 每列照你指定的 index 範圍畫
  for (int r = 0; r < rowStart.length; r++) {
    int a = rowStart[r];
    int b = rowEnd[r];

    for (int idx = a; idx <= b; idx++) {

      // 超出 ribbonPath 就跳過
      if (idx < 0 || idx >= n) continue;
      if (hiddenPixels.contains(idx)) continue;

      PVector p = ribbonPath.get(idx);

      // --- 三個視窗燈光同步 ---
      float v = evalPixelV(idx);
      float c = 255 * v;

      // ===== 完全平面座標：第 r 行、行內第 (idx-rowStart[r]) 欄 =====
      int col = idx - a;

      // ===== 每行置中：先算這行有幾顆 =====
      int colsInRow = (b - a + 1);

      // 左邊留一塊給 "0~70" 這種文字（你可調大/調小）
      float labelW = 90;

      // 可用寬度（扣掉左右 pad + 左側文字區）
      float innerW = pixelMapView.width - pixPad * 2 - labelW;

      // 這一行點的總寬度
      float rowW = colsInRow * pixCell;

      float x0 = pixPad + labelW + max(0, (innerW - rowW) * 0.5);

      // 左邊黑底單向變長：內容往右推回來
      x0 += pixelMapExtraLeft;

      // 只移第一行（0~68 那行）
      if (r == 0) {
        x0 -= firstRowShiftCols * pixCell;  // 左移 44 顆
      }
      // 只移第一行（0~68 那行）
      if (r == 1) {
        x0 -= secondRowShiftCols * pixCell;  // 左移 44 顆
      }

      // 最後一行（721~764）左移 32 顆
      if (r == rowStart.length - 1) {
        x0 -= lastRowShiftCols * pixCell;
      }

      // 綠點整體往右
      x0 += pixelDotsXShift;

      // 真正的點 X
      float x = x0 + col * pixCell + pixCell * 0.5;

      float rowStep = pixCell + pixelRowGap;
      float y = pixPad + pixelMapHeaderH + (rowStart.length - 1 - r) * rowStep + pixCell * 0.5;

      pixelMapView.fill(c * ledR, c * ledG, c * ledB, 230);
      pixelMapView.noStroke();
      pixelMapView.ellipse(x, y, pixDot, pixDot);

      // 可選：標 index（很擠，預設關）
      if (showPixelMapLabels && (idx % pixelMapLabelStep == 0)) {
        pixelMapView.textAlign(CENTER, CENTER);
        pixelMapView.textSize(10);
        pixelMapView.fill(0, 160);
        pixelMapView.rectMode(CENTER);
        pixelMapView.rect(x, y - 10, pixelMapView.textWidth(str(idx)) + 6, 12, 3);
        pixelMapView.fill(255, 220);
        pixelMapView.text(idx, x, y - 10);
      }
    }

    // 每行左側標示範圍（方便你對照）
    pixelMapView.fill(255, 160);
    pixelMapView.textAlign(LEFT, CENTER);
    pixelMapView.textSize(14);
    float rowStep = pixCell + pixelRowGap;
    pixelMapView.text(rowStart[r] + " ~ " + rowEnd[r],
      pixPad + 4,
      pixPad + pixelMapHeaderH + (rowStart.length - 1 - r) * rowStep + pixCell * 0.5);
  }

  pixelMapView.endDraw();
}
