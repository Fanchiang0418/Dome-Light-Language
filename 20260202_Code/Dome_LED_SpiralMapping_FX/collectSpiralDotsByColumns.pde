// 把螺旋點「對應到」(i,s)，並用 spiralBri 畫出來
/*
void collectSpiralDotsByColumns(ArrayList<PVector> spiral, ArrayList<float[]> outDots) {
 int n = spiral.size();
 if (n == 0) return;
 
 for (int idx = 0; idx < n; idx++) {
 PVector p = spiral.get(idx);
 
 // 把 idx(0..n-1) 均分成 spiralCols 根，每根再均分成 spiralRows 段
 float f = idx / float(n);              // 0..1
 float cf = f * spiralCols;             // 0..spiralCols
 int col = int(floor(cf));
 col = constrain(col, 0, spiralCols - 1);
 
 float withinCol = cf - col;            // 0..1
 int row = int(floor(withinCol * spiralRows));
 row = constrain(row, 0, spiralRows - 1);
 
 // 蛇形走線（更像你手繪那種來回）
 if (spiralSerpentine && (col % 2 == 1)) {
 row = (spiralRows - 1) - row;
 }
 
 float v = constrain(spiralBri[col][row] / 100.0, 0, 1);
 
 float sx = screenX(p.x, p.y, p.z);
 float sy = screenY(p.x, p.y, p.z);
 float sz = screenZ(p.x, p.y, p.z);
 
 outDots.add(new float[]{sx, sy, sz, v});
 }
 }
 */

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

void collectSpiralDotsByColumns(ArrayList<PVector> spiral, ArrayList<float[]> outDots) {
  int n = spiral.size();
  if (n == 0) return;

  for (int idx = 0; idx < n; idx++) {
    PVector p = spiral.get(idx);

    // col：角度 -> 0..spiralCols
    float ang = atan2(p.z - sphereC.z, p.x - sphereC.x);
    float a01 = (ang + PI) / TWO_PI;          // 0..1
    a01 = 1.0 - a01;                          // (可選) 反向，讓你順/逆時針符合 X 基準
    float colF = a01 * spiralCols;

    // row：高度 -> 0..spiralRows
    float y01 = (p.y - bmin.y) / max(1e-6, (bmax.y - bmin.y));
    float rowF = y01 * spiralRows;

    // ✅ 用取樣，不要硬切格
    float bri = sampleSpiralBri(colF, rowF);

    // ✅ 欄位加厚：同時取左右鄰居，讓一根「更像一根」
    float thick = 0.75; // 0~1 建議 0.6~0.9
    bri = max(bri, thick * sampleSpiralBri(colF + 0.6, rowF));
    bri = max(bri, thick * sampleSpiralBri(colF - 0.6, rowF));

    float v = constrain(bri / 100.0, 0, 1);

    float sx = screenX(p.x, p.y, p.z);
    float sy = screenY(p.x, p.y, p.z);
    float sz = screenZ(p.x, p.y, p.z);

    outDots.add(new float[]{sx, sy, sz, v});
  }
}
