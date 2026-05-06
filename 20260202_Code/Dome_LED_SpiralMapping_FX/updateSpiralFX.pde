void updateSpiralFX() {
  // 保險：避免 fxMode 超出範圍
  fxMode = ((fxMode % fxNames.length) + fxNames.length) % fxNames.length;

  if (fxMode == 0) updateClockwiseAnyAxis();
  else if (fxMode == 1) updateClockwiseAnyAxisCCW();
  else if (fxMode == 2) updateCalmSpiral();
  else if (fxMode == 3) updateSparkleSpiral();
  else if (fxMode == 4) updateWaveSpiral();
  else if (fxMode == 5) updateLookUpSpiral();
  else if (fxMode == 6) updateBrokenSpiral();
  else if (fxMode == 7) updateWakeSpiral(); 
  else if (fxMode == 8) updateJoySpiral();
  else if (fxMode == 9) updateExpandSpiral();
  else if (fxMode == 10) updateFullOnSpiral();
}

// 順時針
void updateClockwiseAnyAxis() {
  float speed = 0.4;
  float beamWidth = 3.5;

  int cols = spiralCols;
  int rows = spiralRows;

  // primary head：跑在 col 或 row
  float headP = (frameCount * speed) % ((primaryAxis == AXIS_COL) ? cols : rows);

  // secondary head（可選）：用不同速度避免同步
  float headS = (frameCount * speed * 0.73) % ((secondaryAxis == AXIS_COL) ? cols : rows);

  for (int i = 0; i < cols; i++) {
    for (int s = 0; s < rows; s++) {

      // === primary 座標與軸長（先算好）===
      float axisLenP = (primaryAxis == AXIS_COL) ? cols : rows;
      float coordP   = (primaryAxis == AXIS_COL) ? i    : s;

      // === primary 距離：COL 用環狀、ROW 用線性（避免兩圈）===
      float distP;
      if (primaryAxis == AXIS_COL) distP = circularDist(coordP, headP, axisLenP);
      else                         distP = linearDist(coordP, headP);

      float vP = map(distP, 0, beamWidth, 100, 5);
      vP = constrain(vP, 5, 100);

      // === 以 X 為基準：高度衰減建議只在 X(左右) 才用（可選）===
      float out = vP;
      if (primaryAxis == AXIS_COL) {
        float heightFactor = map(s, 0, rows - 1, 1.0, 0.6);
        out *= heightFactor;
      }

      // === secondary 疊加（可選）===
      if (useSecondary) {
        float axisLenS = (secondaryAxis == AXIS_COL) ? cols : rows;
        float coordS   = (secondaryAxis == AXIS_COL) ? i    : s;

        float distS;
        if (secondaryAxis == AXIS_COL) distS = circularDist(coordS, headS, axisLenS);
        else                           distS = linearDist(coordS, headS);

        float vS = map(distS, 0, beamWidth, 100, 5);
        vS = constrain(vS, 5, 100);

        // 疊加方式：相乘（交叉更集中）
        out = out * (vS / 100.0);
      }

      spiralBri[i][s] = constrain(out, 0, 100);
    }
  }
}

// 逆時針
void updateClockwiseAnyAxisCCW() {
  float speed = 0.4;
  float beamWidth = 3.5;

  int cols = spiralCols;
  int rows = spiralRows;

  // ✅ 逆向：用 (axisLen - head) 讓 head 往反方向走
  float axisLenHeadP = (primaryAxis == AXIS_COL) ? cols : rows;
  float axisLenHeadS = (secondaryAxis == AXIS_COL) ? cols : rows;

  float headP = (axisLenHeadP - ((frameCount * speed) % axisLenHeadP)) % axisLenHeadP;
  float headS = (axisLenHeadS - ((frameCount * speed * 0.73) % axisLenHeadS)) % axisLenHeadS;

  for (int i = 0; i < cols; i++) {
    for (int s = 0; s < rows; s++) {

      float axisLenP = (primaryAxis == AXIS_COL) ? cols : rows;
      float coordP   = (primaryAxis == AXIS_COL) ? i    : s;

      float distP;
      if (primaryAxis == AXIS_COL) distP = circularDist(coordP, headP, axisLenP);
      else                         distP = linearDist(coordP, headP);

      float vP = map(distP, 0, beamWidth, 100, 5);
      vP = constrain(vP, 5, 100);

      float out = vP;
      if (primaryAxis == AXIS_COL) {
        float heightFactor = map(s, 0, rows - 1, 1.0, 0.6);
        out *= heightFactor;
      }

      if (useSecondary) {
        float axisLenS = (secondaryAxis == AXIS_COL) ? cols : rows;
        float coordS   = (secondaryAxis == AXIS_COL) ? i    : s;

        float distS;
        if (secondaryAxis == AXIS_COL) distS = circularDist(coordS, headS, axisLenS);
        else                           distS = linearDist(coordS, headS);

        float vS = map(distS, 0, beamWidth, 100, 5);
        vS = constrain(vS, 5, 100);

        out = out * (vS / 100.0);
      }

      spiralBri[i][s] = constrain(out, 0, 100);
    }
  }
}

// 呼吸
void updateCalmSpiral() {
  float tt = frameCount * 0.02;
  float base = map(sin(tt), -1, 1, 25, 70);

  for (int i = 0; i < spiralCols; i++) {
    for (int s = 0; s < spiralRows; s++) {
      float offset = (i + s) * 0.12;
      float v = base + 8 * sin(tt + offset);
      spiralBri[i][s] = constrain(v, 0, 100);
    }
  }
}

// 星點
void updateSparkleSpiral() {
  // 先給一個暗底
  for (int i = 0; i < spiralCols; i++) {
    for (int s = 0; s < spiralRows; s++) {
      spiralBri[i][s] = max(0, spiralBri[i][s] * 0.90); // 慢慢衰減
    }
  }

  // 隨機點亮一些星點
  int sparks = 18; // 越大越多星點
  for (int k = 0; k < sparks; k++) {
    int i = int(random(spiralCols));
    int s = int(random(spiralRows));
    spiralBri[i][s] = 100;
  }
}

// 波浪
void updateWaveSpiral() {
  float t = frameCount * 0.08;

  for (int i = 0; i < spiralCols; i++) {
    float phaseX = i * 0.6;

    for (int s = 0; s < spiralRows; s++) {
      float phaseY = s * 0.25;

      // 以 primaryAxis 決定「波主要沿哪個方向」
      float v;
      if (primaryAxis == AXIS_COL) {
        // X 模式：左右為主（跟你原本最像）
        v = sin(t + phaseX + phaseY);
      } else {
        // Y 模式：上下為主（把 i/s 的權重對調）
        v = sin(t + phaseY + phaseX);
      }

      spiralBri[i][s] = map(v, -1, 1, 10, 100);
    }
  }
}

// 仰望
void updateLookUpSpiral() {
  float speed = 0.12;

  int cols = spiralCols;
  int rows = spiralRows;

  // 依軸決定 level 跑的長度（row 或 col）
  float level = (frameCount * speed) % ((primaryAxis == AXIS_ROW) ? (rows + 1) : (cols + 1));

  for (int i = 0; i < cols; i++) {
    for (int s = 0; s < rows; s++) {

      // 以 X/Y 決定「用哪個座標當成進度」
      float coord = (primaryAxis == AXIS_ROW) ? s : i;  // Y:看高度, X:看根序

      float bri;
      if (coord <= level) {
        float edge = abs(coord - level);
        bri = map(edge, 0, 1.5, 100, 70);
      } else {
        bri = 5;
      }

      spiralBri[i][s] = constrain(bri, 0, 100);
    }
  }
}

// 破碎
void updateBrokenSpiral() {
  float speedStep = 0.2;

  int cols = spiralCols;
  int rows = spiralRows;

  // 依 primaryAxis 決定「誰是根」(mainCount)、「誰是段」(segCount)
  int mainCount = (primaryAxis == AXIS_COL) ? cols : rows; // 要被逐步啟用的數量
  int segCount  = (primaryAxis == AXIS_COL) ? rows : cols; // 拖尾跑動的長度

  int step = int(frameCount * speedStep) % (mainCount + 1);

  // 固定洗牌順序（每次都同一套亂序）
  randomSeed(9999);
  int[] order = new int[mainCount];
  for (int i = 0; i < mainCount; i++) order[i] = i;

  for (int i = mainCount - 1; i > 0; i--) {
    int r = int(random(i + 1));
    int tmp = order[i];
    order[i] = order[r];
    order[r] = tmp;
  }

  float runSpeed = 0.15;
  float tailLen  = 2.0;

  // 先清背景（避免殘影）
  for (int i = 0; i < cols; i++) {
    for (int s = 0; s < rows; s++) {
      spiralBri[i][s] = 5;
    }
  }

  // 逐個 main（col or row）處理
  for (int k = 0; k < mainCount; k++) {

    boolean active = false;
    int rank = -1;

    // k 是否已被啟用（在前 step 名內）
    for (int t = 0; t < step; t++) {
      if (order[t] == k) {
        active = true;
        rank = t;
        break;
      }
    }

    if (!active) continue;

    // 每個啟用的 main，都有自己的 head（相位差 rank * 0.5）
    float head = (frameCount * runSpeed + rank * 0.5) % (segCount + tailLen);

    for (int s = 0; s < segCount; s++) {
      float dist = abs(s - head);

      float bri;
      if (dist <= tailLen) bri = map(dist, 0, tailLen, 100, 20);
      else                 bri = 5;

      bri = constrain(bri, 0, 100);

      // 寫回 spiralBri：依 primaryAxis 決定對應
      if (primaryAxis == AXIS_COL) {
        // X：main = col(k), seg = row(s)
        if (k >= 0 && k < cols && s >= 0 && s < rows) spiralBri[k][s] = max(spiralBri[k][s], bri);
      } else {
        // Y：main = row(k), seg = col(sিৱ
        if (s >= 0 && s < cols && k >= 0 && k < rows) spiralBri[s][k] = max(spiralBri[s][k], bri);
      }
    }
  }
}

// 甦醒
void updateWakeSpiral() {
  float phaseFrames = 30.0;

  int cols = spiralCols;
  int rows = spiralRows;

  // mainCount：要被逐根喚醒的是 col 或 row
  int mainCount = (primaryAxis == AXIS_COL) ? cols : rows;

  float allOnFrames = phaseFrames * mainCount;
  float pauseFrames = 40.0;

  float cycleFrames = allOnFrames + pauseFrames;
  float tt = frameCount % cycleFrames;

  // 固定亂序（每次循環順序都一樣）
  randomSeed(9999);
  int[] order = new int[mainCount];
  for (int i = 0; i < mainCount; i++) order[i] = i;

  for (int i = mainCount - 1; i > 0; i--) {
    int r = int(random(i + 1));
    int tmp = order[i];
    order[i] = order[r];
    order[r] = tmp;
  }

  // 先清底
  for (int i = 0; i < cols; i++) {
    for (int s = 0; s < rows; s++) {
      spiralBri[i][s] = 5;
    }
  }

  for (int k = 0; k < mainCount; k++) {
    // 找 k 在 order 裡的 rank
    int rank = 0;
    for (int i = 0; i < mainCount; i++) {
      if (order[i] == k) {
        rank = i;
        break;
      }
    }

    float start = rank * phaseFrames;
    float end   = start + phaseFrames;

    float bri;
    if (tt < start) {
      bri = 5;
    } else if (tt < end) {
      float p = (tt - start) / phaseFrames;
      bri = map(p, 0, 1, 5, 100);
    } else if (tt < allOnFrames) {
      bri = 100;
    } else {
      bri = 5;
    }

    // 寫回矩陣：X=整根(col)同亮；Y=整層(row)同亮
    if (primaryAxis == AXIS_COL) {
      int col = k;
      if (col >= 0 && col < cols) {
        for (int s = 0; s < rows; s++) spiralBri[col][s] = bri;
      }
    } else {
      int row = k;
      if (row >= 0 && row < rows) {
        for (int i = 0; i < cols; i++) spiralBri[i][row] = bri;
      }
    }
  }
}

// 開心
void updateJoySpiral() {
  float t = frameCount * 0.18;   // 節奏速度

  int cols = spiralCols;
  int rows = spiralRows;

  // 底光（不要全黑，才有溫度）
  float base = 5;

  // 節拍：每 beatFrames 幀一拍；每 4 拍一個重拍
  int beatFrames = 4;                        // 越小越快（3~6）
  int beatIndex = frameCount / beatFrames;   // 目前第幾拍
  boolean accent = (beatIndex % 4 == 0);     // 重拍

  // 每拍生成幾個點
  int hits = accent ? 18 : 10;
  float hitBri = accent ? 100 : 78;

  // 讓同一拍的點位置固定（穩定節奏），拍一換就跳到新位置
  randomSeed(3000 + beatIndex);

  // 先把整體往 base 收斂一點（短殘影）
  for (int i = 0; i < cols; i++) {
    for (int s = 0; s < rows; s++) {
      spiralBri[i][s] = lerp(spiralBri[i][s], base, 0.45);
    }
  }

  // 生成點狀「笑點」
  for (int k = 0; k < hits; k++) {
    int i = int(random(cols));

    // 高度偏中上（像歡樂往上飄），但仍會散佈
    float r = random(1);
    int s;
    if (r < 0.65) s = int(random(rows * 0.35, rows * 0.95));
    else          s = int(random(rows));

    // 點的亮度：帶一點隨機抖動
    float bri = hitBri * random(0.75, 1.0);

    // 核心
    spiralBri[i][s] = max(spiralBri[i][s], bri);

    // 小尾巴（上下 1~2 格）
    if (s - 1 >= 0)      spiralBri[i][s - 1] = max(spiralBri[i][s - 1], bri * 0.55);
    if (s + 1 < rows)    spiralBri[i][s + 1] = max(spiralBri[i][s + 1], bri * 0.55);

    if (accent) {
      // 重拍再多一點延伸
      if (s - 2 >= 0)   spiralBri[i][s - 2] = max(spiralBri[i][s - 2], bri * 0.35);
      if (s + 2 < rows) spiralBri[i][s + 2] = max(spiralBri[i][s + 2], bri * 0.35);
    }
  }

  // 全場笑意：淡淡的 wash（不搶點）
  float giggle = pow(sin(t) * 0.5 + 0.5, 4.0); // 0~1 尖峰
  float wash = 6 + 10 * giggle;                // 6~16
  float add = wash * 0.25;

  for (int i = 0; i < cols; i++) {
    for (int s = 0; s < rows; s++) {
      spiralBri[i][s] = max(spiralBri[i][s], add);
    }
  }
}

// 擁抱
void updateExpandSpiral() {
  float tt = frameCount * 0.04;

  int cols = spiralCols;
  int rows = spiralRows;

  // 以 primaryAxis 決定「哪一軸是擴散軸」
  int axisLen = (primaryAxis == AXIS_COL) ? cols : rows;

  float centerIndex = (axisLen - 1) / 2.0;
  float maxRadius = axisLen / 2.0 + 1;
  float radius = map(sin(tt), -1, 1, 0, maxRadius);

  for (int i = 0; i < cols; i++) {
    for (int s = 0; s < rows; s++) {

      // 用 col 或 row 當作擴散座標
      float coord = (primaryAxis == AXIS_COL) ? i : s;

      float dist = abs(coord - centerIndex);
      float edgeDiff = abs(dist - radius);

      float v = map(edgeDiff, 0, maxRadius, 100, 10);
      v = constrain(v, 10, 100);

      float out = v;

      // 保留你的高度衰減（讓上面稍暗）
      float heightFactor = map(s, 0, rows - 1, 1.0, 0.7);
      out *= heightFactor;

      spiralBri[i][s] = constrain(out, 0, 100);
    }
  }
}

// 全亮
void updateFullOnSpiral() {
  for (int i = 0; i < spiralCols; i++) {
    for (int s = 0; s < spiralRows; s++) {
      spiralBri[i][s] = 100;
    }
  }
}
