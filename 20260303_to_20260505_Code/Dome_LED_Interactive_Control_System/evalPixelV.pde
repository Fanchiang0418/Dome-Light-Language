// 底層亮度 × 圖樣遮罩 × 閃爍調制 × 模式覆蓋

// ===================== 全域參數：從明滅到 Wave =====================
boolean paramMode = true;  // true = 用參數主導(忽略 fxMode 的 spiralBri)
float globalMorph = 0.0; // 0..1：0 = 純整體明滅；1 = 純 wave

// ===================== UI 會直接綁到這些參數（你已經有就不用重複宣告）float spatialness, oscAmp, oscRate, oscFloor, oscK, oscPhase; int oscAxis, oscDir, oscShape; boolean paramMode, autoMorph; =====================
ControlP5 cp5;
boolean showUI = true;   // 可切換顯示
boolean camMouseEnabled = true;

// ===================== Unified Oscillator（統一參數）=====================
final int AXIS_NONE = -1;
final int AXIS_COLF = 0;   // 經度（colF）
final int AXIS_ROWF = 1;   // 高度（rowF）
final int AXIS_IDX  = 2;   // index（0..N-1）

// ===================== 新版參數 =====================
int brightCount = 5;       // 亮的顆數
int darkCount   = 3;       // 暗的顆數
int fadeCount = 2;   // 亮暗交界的漸層顆數
float moveSpeed = 1.0;     // 圖樣移動速度
float blinkSpeed = 1.0;    // 亮燈本身的閃爍/呼吸速度
float baseGlow = 0.08;     // 暗部底光 0~1
float darkGlow = 0.0;      // 暗區亮度 (原0.08)
float brightFloor = 0.7;    // 亮區最低亮度
float masterBrightness = 2.0;   // 整體亮暗總控

// ===================== 舊版參數 =====================
// 主要旋鈕：0=整體明滅（calm），1=空間wave
float spatialness = 0.0;     // 0..1  你要的 calm <-> wave

// 通用振盪器參數（同時描述 calm/wave）
float oscAmp   = 0.9;        // 0..1 調制強度
float oscRate  = 0.9;        // 時間速度
float oscFloor = 0.10;       // 底光（0..1）
float oscK     = 2.5;        // 空間頻率（波長，越大越密）
int   oscAxis  = AXIS_IDX;   // wave 用哪個空間軸（IDX/COLF/ROWF）
int   oscDir   = +1;         // +1/-1 方向
float oscPhase = 0.0;        // 相位偏移（可做轉場/對齊）
int oscShape = 0; // 波形形狀（可擴充）：0=sin(柔)、1=sharp(尖)、2=pulse(脈衝感)
boolean autoMorph = false; // 方便 debug：一鍵自動來回變形

// 0..1 -> 0..1（不同波形）
float shape01(float x01, int shape) {
  x01 = constrain(x01, 0, 1);
  if (shape == 0) {
    // sin 柔和：原樣
    return x01;
  } else if (shape == 1) {
    // sharp：尖一點（像 tension）
    return pow(x01, 3.0);
  } else {
    // pulse：更像脈衝（開闔）
    return (x01 > 0.65) ? 1.0 : 0.0;
  }
}

// 漸層控制
float patternMask01(int idx, float colF, float rowF, int totalCount) {
  if (brightCount <= 0 && darkCount <= 0 ) return 0.0;
  int cycle = max(1, brightCount + fadeCount + darkCount);

  float coord;
  if (oscAxis == AXIS_COLF) coord = colF;
  else if (oscAxis == AXIS_ROWF) coord = rowF;
  else coord = idx;

  float shift = frameCount * moveSpeed * (oscDir >= 0 ? 1 : -1);

  int k = floor(coord + shift);
  k = ((k % cycle) + cycle) % cycle;

  // 1) 亮區
  if (k < brightCount) {
    return 1.0;
  }

  // 2) 漸層區：從亮慢慢掉到暗
  int fadeStart = brightCount;
  int fadeEnd = brightCount + fadeCount;

  if (fadeCount > 0 && k < fadeEnd) {
    float u = (k - fadeStart + 1) / float(fadeCount + 1);
    return 1.0 - u;   // 從 1 慢慢降到接近 0
  }

  // 3) 暗區
  return 0.0;
}

// 取得空間座標 coord 0..1
float coord01FromAxis(int idx, float colF, float rowF) {
  if (oscAxis == AXIS_COLF) return colF / max(1e-6, float(spiralCols));
  if (oscAxis == AXIS_ROWF) return rowF / max(1e-6, float(spiralRows));
  // AXIS_IDX
  return idx / max(1.0, float(ribbonPath.size() - 1));
}

// 產生一個可共用的呼吸 / 閃爍亮度值
float sharedPulse01(float extraPhase) {
  float tt = frameCount * 0.02;
  float phase = tt * blinkSpeed + oscPhase + extraPhase;

  float x01 = 0.5 + 0.5 * sin(phase);
  x01 = shape01(x01, oscShape);

  float mod = baseGlow + (1.0 - baseGlow) * x01;
  return constrain(mod, 0, 1);
}

// 取得一般亮區使用的閃爍值
float blink01() {
  float tt = frameCount * 0.02;
  float phase = tt * blinkSpeed + oscPhase;

  float x01 = 0.5 + 0.5 * sin(phase);
  x01 = shape01(x01, oscShape);

  return constrain(x01, 0, 1);
}

// 先決定位置，再依亮暗圖樣與閃爍規則，算出這個點應有多亮
float evalPointV(PVector p, int idx, int totalCount) {

  if (paramMode && brightCount <= 0 && darkCount <= 0 ) {
    return 0;
  }

  if (p == null) return 0;

  // ===== 先算 colF / rowF =====
  float ang = atan2(p.z - sphereC.z, p.x - sphereC.x);
  float a01 = (ang + PI) / TWO_PI;
  a01 = 1.0 - a01;
  float colF = a01 * spiralCols;

  float y01 = (p.y - bmin.y) / max(1e-6, (bmax.y - bmin.y));
  float rowF = y01 * spiralRows;

  // ===== 底層亮度：沿用 spiralBri =====
  float bri = sampleSpiralBri(colF, rowF);

  float thick = 0.75;
  bri = max(bri, thick * sampleSpiralBri(colF + 0.6, rowF));
  bri = max(bri, thick * sampleSpiralBri(colF - 0.6, rowF));

  float v = paramMode ? 1.0 : constrain(bri / 100.0, 0, 1);

  float mask = patternMask01(idx, colF, rowF, totalCount);
  float blink = blink01();

  float mod = lerp(darkGlow, blink, mask);

  v *= mod;
  v *= masterBrightness;

  return constrain(v, 0, 1);
}

// 計算 ribbonPath 上某顆 LED 的最終亮度 (一般亮度算出來後，再看有沒有被特殊模式接管)
float evalPixelV(int idx) {
  if (ribbonPath == null || ribbonPath.size() == 0) return 0;
  if (idx < 0 || idx >= ribbonPath.size()) return 0;
  if (hiddenPixels.contains(idx)) return 0;

  PVector p = ribbonPath.get(idx);
  float v = evalPointV(p, idx, ribbonPath.size());

  // ===== Ribbon 專用 override / run mode =====
  Float ov = pixelOverride.get(idx);
  if (ov != null) v = constrain(ov, 0, 1);

  if (runIndexMode) {
    int head = currentRunHead();
    if (head >= 0) {
      int d = abs(idx - head);
      if (runTail <= 0) v = (d == 0) ? 1.0 : 0.0;
      else              v = (d > runTail) ? 0.0 : pow(1.0 - d / float(runTail), 2.0);
    }
  }

  if (runHoldMode && holdLit != null && idx < holdLit.length && holdLit[idx]) {
    v = 1.0;
  }

  if (countRunMode) {
    boolean hit = false;

    for (int i = 0; i < countRunShots.size(); i++) {
      CountRunShot shot = countRunShots.get(i);
      int head = floor(shot.head);

      if (shot.dir > 0) {
        int tail = head - shot.len + 1;
        if (idx >= tail && idx <= head) {
          hit = true;
          break;
        }
      } else {
        int tail = head + shot.len - 1;
        if (idx >= head && idx <= tail) {
          hit = true;
          break;
        }
      }
    }

    if (hit) v = sharedPulse01(0.0) * masterBrightness;
    else     v = 0.0;
  }

  float editableV = evalEditableShotV(idx);
  if (editableV >= 0) {
    v = max(v, editableV);
  }
  
  float micV = evalMicShotV(idx);
   if (micMode) {
   v = micV;
   }  

  return constrain(v, 0, 1);
}

// 計算節點模式下某個 mesh vertex 的亮度
float evalVertexV(int idx) {
  if (orderedMeshNodes == null || orderedMeshNodes.size() == 0) return 0;
  if (idx < 0 || idx >= orderedMeshNodes.size()) return 0;

  PVector p = orderedMeshNodes.get(idx);
  float v = evalPointV(p, idx, orderedMeshNodes.size());

  if (countRunMode) {
    boolean hit = false;

    for (int i = 0; i < countRunShots.size(); i++) {
      CountRunShot shot = countRunShots.get(i);
      int head = floor(shot.head);

      if (shot.dir > 0) {
        int tail = head - shot.len + 1;
        if (idx >= tail && idx <= head) {
          hit = true;
          break;
        }
      } else {
        int tail = head + shot.len - 1;
        if (idx >= head && idx <= tail) {
          hit = true;
          break;
        }
      }
    }

    if (hit) v = sharedPulse01(0.0) * masterBrightness;
    else     v = 0.0;
  }

  float editableV = evalEditableShotV(idx);
  if (editableV >= 0) {
    v = max(v, editableV);
  }


  float micV = evalMicShotV(idx);
  if (micMode) {
    v = micV;
  }


  return constrain(v, 0, 1);
}

// shot 個體化編輯系統
float evalEditableShotV(int idx) {
  if (!editableShotMode) return -1;
  if (editableShots == null || editableShots.size() == 0) return -1;

  float best = -1;

  for (int i = 0; i < editableShots.size(); i++) {
    EditableShot shot = editableShots.get(i);

    int head = floor(shot.head);
    int tail;

    if (shot.dir > 0) {
      tail = head - shot.len + 1;

      if (idx >= tail && idx <= head) {
        float v = shot.brightness;

        if (shot.id == selectedEditableShotId) {
          v = min(1.0, v + 0.25);
        }

        int distFromHead = head - idx;   // 0 表示最前面
        int solidLen = max(0, shot.len - shot.fadeLen);

        // 如果在 fade 區，就做漸層
        if (shot.fadeLen > 0 && distFromHead >= solidLen) {
          int fadePos = distFromHead - solidLen;   // 0,1,2...
          float t = map(fadePos, 0, max(1, shot.fadeLen), 1.0, 0.0);
          v *= constrain(t, 0, 1);
        }

        if (shot.blinkSpeed > 0) {
          float blink = 0.5 + 0.5 * sin(frameCount * shot.blinkSpeed);
          v *= blink;
        }

        if (v > best) best = v;
      }
    } else {
      tail = head + shot.len - 1;

      if (idx >= head && idx <= tail) {
        float v = shot.brightness;

        if (shot.id == selectedEditableShotId) {
          v = min(1.0, v + 0.25);
        }

        int distFromHead = idx - head;   // 0 表示最前面
        int solidLen = max(0, shot.len - shot.fadeLen);

        if (shot.fadeLen > 0 && distFromHead >= solidLen) {
          int fadePos = distFromHead - solidLen;
          float t = map(fadePos, 0, max(1, shot.fadeLen), 1.0, 0.0);
          v *= constrain(t, 0, 1);
        }

        if (shot.blinkSpeed > 0) {
          float blink = 0.5 + 0.5 * sin(frameCount * shot.blinkSpeed);
          v *= blink;
        }

        if (v > best) best = v;
      }
    }
  }

  return best;
}
