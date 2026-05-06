// 根據浮點座標 colF、rowF，從 spiralBri 亮度矩陣中取出平滑插值後的亮度值，讓 LED 亮度在欄與列之間過渡更自然，不會一格一格跳動
float sampleSpiralBri(float colF, float rowF) {
  // col: wrap
  int c0 = floor(colF);
  float tc = colF - c0;
  int c1 = c0 + 1;

  c0 = (c0 % spiralCols + spiralCols) % spiralCols;
  c1 = (c1 % spiralCols + spiralCols) % spiralCols;

  // row: clamp
  int r0 = floor(rowF);
  float tr = rowF - r0;
  r0 = constrain(r0, 0, spiralRows - 1);
  int r1 = constrain(r0 + 1, 0, spiralRows - 1);

  float b00 = spiralBri[c0][r0];
  float b10 = spiralBri[c1][r0];
  float b01 = spiralBri[c0][r1];
  float b11 = spiralBri[c1][r1];

  float b0 = lerp(b00, b10, tc);
  float b1 = lerp(b01, b11, tc);
  return lerp(b0, b1, tr); // 0~100
}

// 參數調整
int ribbonThicknessRows = 5;   // 5 列厚度
float ribbonRowSpacing = 6.0;  // 每列間距（依你模型尺度調：3~12）
boolean attachToSphere = true;     // 螺旋區域：像貼在球面上
float attachBlend = 0.85;           // 0=用原本bin(垂直厚度)；1=完全用球面貼附方向
float attachRadiusFactor = 1.25;   // 判定「在球上」的範圍：距離球心 < sphereR * 1.25

// 單圈Z軸調整 + Z軸-30度修正
boolean keepRibbonScreenWidth = true;  // 保持畫面上的厚度
float minRowStepPx = 2.2;              // 每列至少相差幾個螢幕像素
float maxRowSpacingComp = 2.8;         // 最多放大幾倍，避免爆開

// 把 ribbonPath / spiral 上的每個 LED 中心點，依照路徑方向與球面貼附方向展開成多列彩帶厚度，計算每顆點的亮度後轉成螢幕座標，最後存進 outDots 讓畫面可以畫出有寬度、貼合 Dome 表面的 LED 彩帶
void collectSpiralDotsByColumns(ArrayList<PVector> spiral, ArrayList<float[]> outDots) {
  int n = spiral.size();
  if (n == 0) return;

  int rows = max(1, ribbonThicknessRows);
  int half = rows / 2;

  for (int idx = 0; idx < n; idx++) {

    if (hiddenPixels.contains(idx)) continue;

    PVector p = spiral.get(idx);

    // 估算路徑切線（用前後點）
    PVector pPrev = spiral.get(max(0, idx - 1));
    PVector pNext = spiral.get(min(n - 1, idx + 1));
    PVector tan = PVector.sub(pNext, pPrev);
    if (tan.magSq() < 1e-6) tan = new PVector(1, 0, 0);
    tan.normalize();

    // world up
    PVector up = new PVector(0, 1, 0);

    // 左右方向：side = tan × up
    PVector side = tan.cross(up);
    if (side.magSq() < 1e-6) side = new PVector(1, 0, 0);
    side.normalize();

    // 垂直厚度方向：bin = side × tan
    PVector bin = side.cross(tan);
    if (bin.magSq() < 1e-6) bin = new PVector(0, 1, 0);
    bin.normalize();

    // 預設厚度方向
    PVector dir = bin.copy();

    // 這個一定要先宣告在外面
    float rowSpacingNow = ribbonRowSpacing;

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

    // 不管 onSphere 有沒有成立，都可以做畫面寬度補償
    if (keepRibbonScreenWidth) {
      float probeLen = 10.0;

      float sx0 = screenX(p.x, p.y, p.z);
      float sy0 = screenY(p.x, p.y, p.z);

      PVector pProbe = PVector.add(p, PVector.mult(dir, probeLen));
      float sx1 = screenX(pProbe.x, pProbe.y, pProbe.z);
      float sy1 = screenY(pProbe.x, pProbe.y, pProbe.z);

      float projPerWorld = dist(sx0, sy0, sx1, sy1) / probeLen;

      if (projPerWorld > 1e-5) {
        float neededWorldStep = minRowStepPx / projPerWorld;
        rowSpacingNow = max(ribbonRowSpacing, neededWorldStep);
        rowSpacingNow = min(rowSpacingNow, ribbonRowSpacing * maxRowSpacingComp);
      }
    }

    // 三個視窗燈光同步
    float v = evalPixelV(idx);

    // 多列：沿 dir 複製點
    if (rows % 2 == 1) {
      for (int r = -half; r <= half; r++) {
        float off = r * rowSpacingNow;
        PVector pp = PVector.add(p, PVector.mult(dir, off));

        float sx = screenX(pp.x, pp.y, pp.z);
        float sy = screenY(pp.x, pp.y, pp.z);
        float sz = screenZ(pp.x, pp.y, pp.z);

        outDots.add(new float[]{sx, sy, sz, v});
      }
    } else {
      for (int k = 0; k < rows; k++) {
        float r = (k - (rows - 1) * 0.5);
        float off = r * rowSpacingNow;
        PVector pp = PVector.add(p, PVector.mult(dir, off));

        float sx = screenX(pp.x, pp.y, pp.z);
        float sy = screenY(pp.x, pp.y, pp.z);
        float sz = screenZ(pp.x, pp.y, pp.z);

        outDots.add(new float[]{sx, sy, sz, v});
      }
    }
  }
}
