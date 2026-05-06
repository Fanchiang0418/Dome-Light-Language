void keyPressed() {
  handleDisplayKeys();
  handleEffectKeys();
  handleColorKeys();
  handleManualAndOverrideKeys();
  handleInputBufferKeys();
  handleRunModeKeys();
  handleParamKeys();
  handleAISaysKeys();
  handleEditableShotKeys();
  handleNodeLabelKeys();
  handlePixelLabelKeys();
  mic();
  printKeyDebug();
}

// ===================== 1) 標籤 / 顯示 =====================
void handleDisplayKeys() {
  if (key == 'a' || key == 'A') labelAllEdges = !labelAllEdges;
  if (key == 'l' || key == 'L') showEdgeLabels = !showEdgeLabels;
  if (key == '-') labelStep++;
  if (key == '+' || key == '=') labelStep = max(1, labelStep - 1);
  if (key == 'k' || key == 'K') showPixelLabels = !showPixelLabels;

  if (key == 'v' || key == 'V') {
    showFlatView = !showFlatView;
    showPixelMapView = !showPixelMapView;
  }
}

// ===================== 2) 效果 / 軸向 =====================
void handleEffectKeys() {
  if (key == 'x' || key == 'X') primaryAxis = AXIS_COL;
  if (key == 'y' || key == 'Y') primaryAxis = AXIS_ROW;
  if (key == 'z' || key == 'Z') useSecondary = !useSecondary;
  // if (key == 'n' || key == 'N') fxMode = (fxMode + 1) % FX_COUNT();
  // if (key == 'p' || key == 'P') fxMode = (fxMode - 1 + FX_COUNT()) % FX_COUNT();
}

// ===================== 3) 顏色切換 =====================
void handleColorKeys() {
  if (key == 'g' || key == 'G') {
    ledR = 0;
    ledG = 1;
    ledB = 0;
  }

  if (key == 'w' || key == 'W') {
    ledR = 1;
    ledG = 1;
    ledB = 1;
  }
}

// ===================== 4) 手動 / override =====================
void handleManualAndOverrideKeys() {
  if (key == 'm' || key == 'M') {
    manualMode = !manualMode;
    println("manualMode =", manualMode);
  }

  if (key == 'o' || key == 'O') {
    if (selectedPixel != -1) {
      if (pixelOverride.containsKey(selectedPixel)) {
        pixelOverride.remove(selectedPixel);
        println("Override OFF:", selectedPixel, " total =", pixelOverride.size());
      } else {
        pixelOverride.put(selectedPixel, overrideValue);
        manualMode = true;
        println("Override ON :", selectedPixel, " total =", pixelOverride.size());
      }
    }
  }

  if (key == 'c' || key == 'C') {
    pixelOverride.clear();
    manualPixel = -1;
    println("All overrides cleared.");
  }
}

// ===================== 5) 數字輸入 =====================
void handleInputBufferKeys() {
  // 只保留給原本手動輸入 pixel 用
  if (key >= '0' && key <= '9') {
    inputBuf += key;
    println("inputBuf =", inputBuf);
  }

  if (keyCode == BACKSPACE) {
    if (inputBuf.length() > 0) {
      inputBuf = inputBuf.substring(0, inputBuf.length() - 1);
      println("inputBuf =", inputBuf);
    }
  }

  if (keyCode == ENTER || keyCode == RETURN) {
    if (inputBuf.length() > 0) {
      int idx = int(inputBuf);

      if (idx >= 0 && idx < ribbonPath.size()) {
        manualPixel = idx;
        pixelOverride.put(manualPixel, manualPixelBri);
        manualMode = true;
        println("Add pixel =", manualPixel, " total =", pixelOverride.size());
      } else {
        println("Index out of range:", idx, " (0 ~ " + (ribbonPath.size() - 1) + ")");
      }
    }
    inputBuf = "";
  }
}

// ===================== 6) 跑動 / 累積模式 =====================
void handleRunModeKeys() {
  if (key == 't' || key == 'T') {
    runIndexMode = !runIndexMode;
    manualMode = runIndexMode;
    println("runIndexMode =", runIndexMode);
  }

  if (key == 'h' || key == 'H') {
    runHoldMode = !runHoldMode;
    manualMode = runHoldMode;
    println("runHoldMode =", runHoldMode);
  }

  if (key == 'r' || key == 'R') {
    if (holdLit != null) {
      for (int i = 0; i < holdLit.length; i++) holdLit[i] = false;
    }
    pixelOverride.clear();
    manualPixel = -1;
    prevHoldHead = -1;
    inputBuf = "";
    println("RESET: holdLit + overrides cleared.");
  }

  if (key == 'b' || key == 'B') {
    countRunMode = !countRunMode;
    println("countRunMode =", countRunMode);
  }
}

// ===================== 7) 參數化變形 =====================
void handleParamKeys() {
  if (key == 'q' || key == 'Q') paramMode = !paramMode;
  if (key == ',') spatialness = max(0, spatialness - 0.05);
  if (key == '.') spatialness = min(1, spatialness + 0.05);

  if (key == 'u' || key == 'U') autoMorph = !autoMorph;

  if (key == 'j' || key == 'J') {
    if (oscAxis == AXIS_IDX) oscAxis = AXIS_COLF;
    else if (oscAxis == AXIS_COLF) oscAxis = AXIS_ROWF;
    else oscAxis = AXIS_IDX;
  }

  if (key == 'i' || key == 'I') oscDir *= -1;

  if (key == '1') oscShape = 0;
  if (key == '2') oscShape = 1;
  if (key == '3') oscShape = 2;
}

// ===================== 8) AI says =====================
void handleAISaysKeys() {
  if (key == '6') playCeremonyTurn("ceremony.json", 0);
  if (key == '7') playCeremonyTurn("ceremony.json", 1);
}

// ===================== 9) shot 個體化編輯系統 =====================
void handleEditableShotKeys() {
  // [ : 上一發
  if (key == '[') {
    selectPrevEditableShot();
  }

  // ] : 下一發
  if (key == ']') {
    selectNextEditableShot();
  }

  // \ : 發一發 editable shot
  if (key == '\\') {
    fireEditableShot(editableShotDefaultLen);
  }

  // ; : 亮度增加
  if (key == ';') {
    editableShotBrightnessUp(0.1);
  }

  // ' : 亮度減少
  if (key == '\'') {
    editableShotBrightnessDown(0.1);
  }

  // / : 速度增加
  if (key == '/') {
    editableShotSpeedUp(0.2);
  }

  // ? : 速度減少（Shift + /）
  if (key == '?') {
    editableShotSpeedDown(0.2);
  }

  // { : 長度減少
  if (key == '{') {
    editableShotLenDown(1);
  }

  // } : 長度增加
  if (key == '}') {
    editableShotLenUp(1);
  }

  // < : fade 減少
  if (key == '<') {
    editableShotFadeDown(1);
  }

  // > : fade 增加
  if (key == '>') {
    editableShotFadeUp(1);
  }

  // : blinkSpeed 增加
  if (key == ':') {
    editableShotBlinkUp(0.05);
  }

  // " blinkSpeed 減少
  if (key == '"') {
    editableShotBlinkDown(0.05);
  }
}

// ===================== 10) 節點編號顯示/隱藏 =====================
void handleNodeLabelKeys() {
  if (key == 'n' || key == 'N') {
    showNodeLabels = !showNodeLabels;
    println("showNodeLabels = " + showNodeLabels);
  }
}

void handlePixelLabelKeys() {
  if (key == 'p' || key == 'P') {
    showPixelLabels = !showPixelLabels;
    println("showPixelLabels = " + showPixelLabels);
  }
}

// ===================== 11) 麥克風 =====================
void mic() {
  if (key == 'f' || key == 'F') {
    micMode = !micMode;
    println("micMode = " + micMode);
  }
}

// ===================== Debug =====================
void printKeyDebug() {
  println("fxMode =", fxMode, fxNames[fxMode]);
  println("labelAllEdges =", labelAllEdges,
    "labelStep =", labelStep,
    "showEdgeLabels =", showEdgeLabels,
    "showPixelLabels =", showPixelLabels);
}
