// 當 UI 控制項被操作時，更新燈光系統對應的狀態

// 45度、更新螺旋圈數，並重建整條 ribbonPath
public void ribbonTurns(float v) {
  ribbonTurns = v;
  rebuildRibbonPathAndResetState();

  println("ribbonTurns =", ribbonTurns, " ribbonPath size =", ribbonPath.size());
}

// 重新建立整條 ribbonPath 彩帶路徑，並同步重置跑燈保留狀態、發射中的燈效、單點覆蓋與目前選取的 pixel，避免路徑更新後舊狀態對不上新的 LED 點位
void rebuildRibbonPathAndResetState() {
  buildSpiralsOnSphere();

  int maxIdx = max(0, min(runHoldMax, ribbonPath.size() - 1));
  holdLit = new boolean[maxIdx + 1];
  for (int i = 0; i < holdLit.length; i++) holdLit[i] = false;

  countRunShots.clear();
  pixelOverride.clear();
  manualPixel = -1;
  selectedPixel = -1;
}

// 接收 UI 開關狀態，決定是否讓彩帶路徑左右傾斜 30 度，並在切換後重建 ribbonPath、重置相關燈效狀態，最後印出目前傾斜設定方便除錯
/*
public void ribbonTiltLR45UI(boolean v) {
  ribbonTiltLR45 = v;
  ribbonTiltLRAng = ribbonTiltLR45 ?  radians(30) : 0.0;

  rebuildRibbonPathAndResetState();

  println("[RIBBON TILT LR] enable =", ribbonTiltLR45,
          " angle =", ribbonTiltLRAng);
}
*/

// 接收 UI 開關狀態，決定是否讓彩帶路徑繞 Y 軸旋轉 10 度，並在切換後重建 ribbonPath、重置相關燈效狀態，最後印出目前旋轉設定方便除錯
/*
public void ribbonRotateY45UI(boolean v) {
  ribbonRotateY45 = v;
  ribbonRotateYAng = ribbonRotateY45 ?  radians(10) : 0.0;   

  rebuildRibbonPathAndResetState();

  println("[RIBBON ROTATE Y] enable =", ribbonRotateY45,
          " angle =", ribbonRotateYAng);
}
*/

// 設定亮燈數量，且至少為 1
public void brightCount(float v) {
  brightCount = max(1, round(v));
}

// 設定暗燈數量，且不能小於 0
public void darkCount(float v) {
  darkCount = max(0, round(v));
}

// 從輸入框讀取文字，判斷是數字模式還是摩斯文字模式，並觸發對應播放
public void startCountRun(int v) {
  if (cp5 == null) return;

  Textfield tf = cp5.get(Textfield.class, "countRunCountText"); // 取得 UI 輸入框內容
  String txt = "";

  if (tf != null) txt = tf.getText();
  if (txt == null) txt = "";
  txt = trim(txt); // 去掉前後空白

  println("input = [" + txt + "]");

  if (txt.length() == 0) {
    println("輸入為空");
    return;
  }

  // 判斷是否全為數字，全是數字 → 數字模式，非數字 → 摩斯模式
  boolean isNumber = true;
  for (int i = 0; i < txt.length(); i++) {
    char ch = txt.charAt(i);
    if (!(ch >= '0' && ch <= '9')) {
      isNumber = false;
      break;
    }
  }

  if (isNumber) {
    int n = 1;
    try {
      n = Integer.parseInt(txt);
    }
    catch(Exception e) {
      println("輸入不是有效整數，改用 1");
      n = 1;
    }

    println("[NUMBER MODE] n = " + n);
    fireCountRunShot(n);
  } else {
    println("[MORSE MODE] text = " + txt);
    fireMorseText(txt);
  }
}

// 清除所有正在播放或保留中的 countRun shot
public void resetCountRun(int v) {
  countRunShots.clear();
  countRunMode = false;
  morseQueue.clear();
  morsePlaying = false;
  println("All countRun / morse shots cleared.");
}

// 切換 LED 版面配置模式
public void ledLayoutModeUI(int theValue) {
  ledLayoutMode = theValue;
}

// 依照目前的排列模式 ledLayoutMode，回傳當前可控制的 LED 點位總數；如果是節點模式就回傳 orderedMeshNodes 數量，否則回傳 ribbonPath 數量
int getCurrentLayoutLength() {
  if (ledLayoutMode == LAYOUT_VERTEX) {
    return (orderedMeshNodes == null) ? 0 : orderedMeshNodes.size();
  } else {
    return (ribbonPath == null) ? 0 : ribbonPath.size();
  }
}

// 取得目前 LED 排列模式下最後一顆可控制點位的 index；如果沒有點位，至少回傳 0，避免出現負數 index
int getCurrentLayoutLastIndex() {
  return max(0, getCurrentLayoutLength() - 1);
}

// 建立一個新的 countRun shot，加入播放清單
void fireCountRunShot(int n) {
  int totalLen = getCurrentLayoutLength();
  if (totalLen <= 0) return;

  n = max(1, n);
  n = min(n, totalLen);

  countRunCount = n;
  countRunMode = true;

  int fireDir = (oscDir >= 0) ? +1 : -1;

  float startHead;
  if (fireDir > 0) {
    startHead = n - 1;
  } else {
    startHead = getCurrentLayoutLastIndex();   // 反向從目前排列形式的最後一顆開始
  }

  CountRunShot shot = new CountRunShot(startHead, n, fireDir);
  countRunShots.add(shot);

  runIndexMode = false;
  runHoldMode = false;
  manualMode = false;
  pixelOverride.clear();

  println("Fire shot => len = " + shot.len
    + ", head = " + shot.head
    + ", dir = " + shot.dir
    + ", totalLen = " + totalLen);
}

// 切換方向正負
public void flipDir(int v) {
  oscDir *= -1;
}

// 切換振盪/控制所使用的軸向
public void oscAxisUI(int theValue) {
  oscAxis = theValue;
}

// 切換振盪波形類型
public void oscShapeUI(int theValue) {
  oscShape = theValue;
}

// 設定 fade 數量或 fade 長度，且最小為 0
public void fadeCount(float v) {
  fadeCount = max(0, round(v));
}

// 設定亮度下限，限制在 0~1 之間
public void brightFloor(float v) {
  brightFloor = constrain(v, 0, 1);
}

// shot 個體化編輯系統 UI
public void editableShotUIBrightness(float v) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE UI] brightness: no selected shot");
    return;
  }
  s.brightness = constrain(v, 0, 1);
  println("[EDITABLE UI] shot", s.id, "brightness =", s.brightness);
}

// shot 個體化編輯系統 UI
public void editableShotUISpeed(float v) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) return;
  s.speed = max(0, v);
}

// shot 個體化編輯系統 UI
public void editableShotUIBlinkSpeed(float v) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) return;
  s.blinkSpeed = max(0, v);
}

// shot 個體化編輯系統 UI
public void editableShotUILen(float v) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) return;

  s.len = max(1, round(v));
  s.fadeLen = constrain(s.fadeLen, 0, s.len);
}

// shot 個體化編輯系統 UI
public void editableShotUIFadeLen(float v) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) return;

  s.fadeLen = constrain(round(v), 0, s.len);
}

// shot 個體化編輯系統 UI
public void editableShotFire() {
  editableShotDefaultFadeLen = constrain(editableShotDefaultFadeLen, 0, editableShotDefaultLen);
  fireEditableShot(editableShotDefaultLen);
}

// shot 個體化編輯系統 UI
public void editableShotClearAll() {
  editableShots.clear();
  selectedEditableShotId = -1;
  syncEditableShotList();
  println("[EDITABLE] all shots cleared");
}

// shot 個體化編輯系統 UI (預設值)
public void editableShotDefaultLenUI(float v) {
  editableShotDefaultLen = max(1, round(v));
  editableShotDefaultFadeLen = constrain(editableShotDefaultFadeLen, 0, editableShotDefaultLen);
}

// shot 個體化編輯系統 UI (預設值)
public void editableShotDefaultFadeLenUI(float v) {
  editableShotDefaultFadeLen = constrain(round(v), 0, editableShotDefaultLen);
}

// shot 個體化編輯系統 UI (預設值)
public void editableShotDefaultBrightnessUI(float v) {
  editableShotDefaultBrightness = constrain(v, 0, 1);
}

// shot 個體化編輯系統 UI (預設值)
public void editableShotDefaultSpeedUI(float v) {
  editableShotDefaultSpeed = max(0, v);
}

// shot 個體化編輯系統 UI (預設值)
public void editableShotDefaultBlinkSpeedUI(float v) {
  editableShotDefaultBlinkSpeed = max(0, v);
}

// 當使用者在 editableShotListUI 下拉清單中選擇某個燈光段時，讀取該項目的 shot id，設定為目前選取的 selectedEditableShotId，並關閉清單與印出除錯資訊
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(editableShotListUI)) {

    int itemIndex = int(theEvent.getValue());

    Map item = editableShotListUI.getItem(itemIndex);
    if (item != null) {
      int pickedId = ((Number) item.get("value")).intValue();
      selectedEditableShotId = pickedId;

      println("[EDITABLE LIST] itemIndex =", itemIndex,
        " picked shot id =", selectedEditableShotId);
    }

    editableShotListUI.close();
  }
}

// 切換預設單段燈光的移動方向，在「正向」與「反向」之間來回切換，同時更新 UI 按鈕文字並印出目前方向方便除錯
public void editableShotToggleDefaultDir() {
  editableShotDefaultDir *= -1;

  if (editableShotDefaultDirBtn != null) {
    if (editableShotDefaultDir > 0) {
      editableShotDefaultDirBtn.setLabel("正向");
    } else {
      editableShotDefaultDirBtn.setLabel("反向");
    }
  }

  println("[EDITABLE DEFAULT] dir =", editableShotDefaultDir);
}

// 將目前選取的單段燈光 EditableShot 移動方向反轉；如果沒有選到任何段落，就印出提示並停止執行
public void editableShotReverseSelected() {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot to reverse");
    return;
  }

  s.dir *= -1;

  println("[EDITABLE] shot", s.id, " reversed, dir =", s.dir);
}

// 接收 UI 傳來的數值 v，當 v > 0.5 時開啟麥克風模式 micMode，否則關閉，並在 console 印出目前狀態方便確認
public void micModeUI(float v) {
  micMode = (v > 0.5);
  println("micMode = " + micMode);
}
