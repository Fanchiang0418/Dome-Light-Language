// 燈光效果
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

/*
// 螺旋版 updateClockwise
void updateClockwiseSpiral() {
  float speed = 0.4;
  float head = (frameCount * speed) % spiralCols;
  float beamWidth = 3.5;

  for (int i = 0; i < spiralCols; i++) {
    float diff = abs(i - head);
    float dist = min(diff, spiralCols - diff);

    for (int s = 0; s < spiralRows; s++) {
      float v = map(dist, 0, beamWidth, 100, 5);
      v = constrain(v, 5, 100);

      float heightFactor = map(s, 0, spiralRows - 1, 1.0, 0.6);
      spiralBri[i][s] = v * heightFactor;
    }
  }
}
*/
/*
void updateClockwiseAnyAxis() {
  float speed = 0.4;
  float beamWidth = 3.5;

  int cols = spiralCols;
  int rows = spiralRows;

  // primary head：跑在 col 或 row
  float headP = (frameCount * speed) % (primaryAxis == AXIS_COL ? cols : rows);

  // secondary head（可選）：用不同速度避免同步
  float headS = (frameCount * speed * 0.73) % (secondaryAxis == AXIS_COL ? cols : rows);

  for (int i = 0; i < cols; i++) {
    for (int s = 0; s < rows; s++) {

      // === primary 距離 ===
      float distP;
      float axisLenP = (primaryAxis == AXIS_COL) ? cols : rows;
      float coordP   = (primaryAxis == AXIS_COL) ? i    : s;

      // 你原本是環狀（順時針），所以用 circularDist
      distP = circularDist(coordP, headP, axisLenP);

      float vP = map(distP, 0, beamWidth, 100, 5);
      vP = constrain(vP, 5, 100);

      // === 原本的高度因子（你要保留上下暗化就留）===
      float heightFactor = map(s, 0, rows - 1, 1.0, 0.6);
      float out = vP * heightFactor;

      // === secondary 疊加（可選）===
      if (useSecondary) {
        float axisLenS = (secondaryAxis == AXIS_COL) ? cols : rows;
        float coordS   = (secondaryAxis == AXIS_COL) ? i    : s;

        float distS = circularDist(coordS, headS, axisLenS);
        float vS = map(distS, 0, beamWidth, 100, 5);
        vS = constrain(vS, 5, 100);

        // 疊加方式 1：相乘（交叉亮點更集中）
        out = out * (vS / 100.0);

        // 疊加方式 2：加法（更亮更滿）
        // out = constrain(out + 0.6 * vS, 0, 100);
      }

      spiralBri[i][s] = constrain(out, 0, 100);
    }
  }
}
*/
