// ---
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

// ===== 1 =====
void collectSpiralDotsByColumns(ArrayList<PVector> spiral, ArrayList<float[]> outDots) {
  int n = spiral.size();
  if (n == 0) return;

  int rows = max(1, ribbonThicknessRows);
  int half = rows / 2; // rows=5 => half=2

  for (int idx = 0; idx < n; idx++) {

    // 隱藏：整個「那一顆」的多列都不畫
    if (hiddenPixels.contains(idx)) continue;

    PVector p = spiral.get(idx);

    // --- 估算路徑切線（用前後點）
    PVector pPrev = spiral.get(max(0, idx - 1));
    PVector pNext = spiral.get(min(n - 1, idx + 1));
    PVector tan = PVector.sub(pNext, pPrev);
    if (tan.magSq() < 1e-6) tan = new PVector(1, 0, 0);
    tan.normalize();

    // --- world up
    PVector up = new PVector(0, 1, 0);

    // --- 左右方向：side = tan × up
    PVector side = tan.cross(up);
    if (side.magSq() < 1e-6) side = new PVector(1, 0, 0);
    side.normalize();

    // 垂直厚度方向：bin = side × tan（大致朝上/下，且垂直於路徑）
    PVector bin = side.cross(tan);
    if (bin.magSq() < 1e-6) bin = new PVector(0, 1, 0);
    bin.normalize();

    // 把偏移方向改成「貼球方向」
    // 決定厚度偏移方向 dir
    PVector dir = bin; // 預設：你原本的「垂直厚度」

    if (attachToSphere) {
      // 判斷這個點是否在球附近（螺旋區）
      float dC = PVector.dist(p, sphereC);
      float distToSurface = abs(dC - sphereR);
      boolean onSphere = (distToSurface < sphereR * 0.25); // 0.15~0.35 之間試

      if (onSphere) {
        // 球面法向（從球心指向點）
        PVector normal = PVector.sub(p, sphereC);
        if (normal.magSq() < 1e-6) normal = new PVector(0, 1, 0);
        normal.normalize();

        // ✅ 把 worldUp 投影到球的切平面，得到「貼球向上」方向
        // surfUp = up - normal*(up·normal)
        PVector surfUp = PVector.sub(up, PVector.mult(normal, up.dot(normal)));
        if (surfUp.magSq() < 1e-6) surfUp = bin.copy();
        surfUp.normalize();

        // 在 bin 與 surfUp 之間做混合（你可用 attachBlend 控制斜度）
        dir = PVector.lerp(bin, surfUp, attachBlend);
        if (dir.magSq() < 1e-6) dir = surfUp.copy();
        dir.normalize();
      }
    }

    // --- 亮度計算（用中心點 p 取樣）
    float ang = atan2(p.z - sphereC.z, p.x - sphereC.x);
    float a01 = (ang + PI) / TWO_PI;      // 0..1
    a01 = 1.0 - a01;                      // (可選)反向
    float colF = a01 * spiralCols;

    float y01 = (p.y - bmin.y) / max(1e-6, (bmax.y - bmin.y));
    float rowF = y01 * spiralRows;

    float bri = sampleSpiralBri(colF, rowF);

    // 欄位加厚（你原本的）
    float thick = 0.75;
    bri = max(bri, thick * sampleSpiralBri(colF + 0.6, rowF));
    bri = max(bri, thick * sampleSpiralBri(colF - 0.6, rowF));

    float v = constrain(bri / 100.0, 0, 1);

    // --- 多列：沿「垂直方向 bin」複製點（你要的垂直厚度）
    if (rows % 2 == 1) {
      // 奇數列：-half..half（例如 5 列：-2,-1,0,1,2）
      for (int r = -half; r <= half; r++) {
        float off = r * ribbonRowSpacing;
        //PVector pp = PVector.add(p, PVector.mult(bin, off));
        PVector pp = PVector.add(p, PVector.mult(dir, off));

        float sx = screenX(pp.x, pp.y, pp.z);
        float sy = screenY(pp.x, pp.y, pp.z);
        float sz = screenZ(pp.x, pp.y, pp.z);

        outDots.add(new float[]{sx, sy, sz, v});
      }
    } else {
      // 偶數列：對稱、但不含 0（例如 4 列：-1.5,-0.5,0.5,1.5）
      for (int k = 0; k < rows; k++) {
        float r = (k - (rows - 1) * 0.5); // 例如 rows=4 => -1.5,-0.5,0.5,1.5
        float off = r * ribbonRowSpacing;

        //PVector pp = PVector.add(p, PVector.mult(bin, off));
        PVector pp = PVector.add(p, PVector.mult(dir, off));

        float sx = screenX(pp.x, pp.y, pp.z);
        float sy = screenY(pp.x, pp.y, pp.z);
        float sz = screenZ(pp.x, pp.y, pp.z);

        outDots.add(new float[]{sx, sy, sz, v});
      }
    }
  }
}
