// 沿著 ribbonPath 索引移動的各種跑動燈光，單顆循環、累積點亮、同時存在多發亮段的 countRun 系統

// ===== 逐顆跑 (0~764) =====
boolean runIndexMode = false;   // 開/關跑馬
float runIndexSpeed = 1.0;      // 每幀跑幾顆 (1=每幀1顆；0.5=兩幀1顆；2=每幀2顆)
int runIndexMax = 764;          // 你要跑到 764
int runTail = 0;                // 拖尾長度(0=無拖尾；建議 8~40 可試)

// ===== 累積點亮（跑過就留亮）=====
boolean runHoldMode = false;     // 開關：跑過就留亮
float runHoldSpeed = 1.0;        // 每幀跑幾顆
int runHoldMax = 764;            // 0~764
boolean[] holdLit;               // 亮起來就保持
int prevHoldHead = -1;  // 用來偵測回到0

// 加一個小工具：計算「目前跑到哪一顆」
int currentRunHead() {
  int maxIdx = min(runIndexMax, ribbonPath.size() - 1);
  if (maxIdx < 0) return -1;
  int head = int((frameCount * runIndexSpeed) % (maxIdx + 1));
  return head;
}

// ===== 單圈多燈模式（輸入 N 顆，從 0 跑到 764，只跑一圈）=====
boolean countRunMode = false;      // UI 模式開關
int countRunCount = 5;             // 一次亮幾顆(單發)(多發)，新發射時預設長度（由輸入框決定）
float countRunBaseSpeed = 1.0;   // 基準速度
int countRunMax = 764;             // 終點

// UI 元件
Textfield countRunField; // 輸入長度或文字
Button countRunStartBtn; // 開始發射
Button countRunResetBtn; // 重設 / 清除
Toggle countRunToggle; // 模式開關

ArrayList<CountRunShot> countRunShots = new ArrayList<CountRunShot>(); // 儲存目前正在跑的所有 shot

// 儲存目前正在跑的所有 shot
class CountRunShot {
  float head;   // 目前最前面的 index
  int len;      // 這一發自己的長度
  int dir;      // +1 正向(0->764), -1 反向(764->0)

  CountRunShot(float h, int l, int d) {
    this.head = h;
    this.len = l;
    this.dir = d;
  }
}

// 回傳 countRun 目前實際使用的速度
float currentCountRunSpeed() {
  return countRunBaseSpeed * moveSpeed;
}

// 每幀更新所有 shot 的位置，並刪除已經完全離開範圍的 shot
void updateCountRun() {
  if (!countRunMode) return;
  if (countRunShots == null || countRunShots.size() == 0) return;

  int totalLen = getCurrentLayoutLength();
  if (totalLen <= 0) return;

  int maxIdx = min(countRunMax, getCurrentLayoutLastIndex());
  float moveSpeed = currentCountRunSpeed();

  for (int i = countRunShots.size() - 1; i >= 0; i--) {
    CountRunShot shot = countRunShots.get(i);

    shot.head += moveSpeed * shot.dir;

    int head = floor(shot.head);
    int tail;

    if (shot.dir > 0) {
      tail = head - shot.len + 1;
      if (tail > maxIdx) {
        countRunShots.remove(i);
      }
    } else {
      tail = head + shot.len - 1;
      if (tail < 0) {
        countRunShots.remove(i);
      }
    }
  }
}

// ===== shot 個體化編輯系統 =====
boolean editableShotMode = true;   // 新模式開關（先加著，之後 UI 再接）
int nextEditableShotId = 1;         // 每發 shot 的流水號
int selectedEditableShotId = -1;    // 目前選到哪一發，先保留

ArrayList<EditableShot> editableShots = new ArrayList<EditableShot>(); // 儲存發數的容器

// ===== editable shot 預設參數（給新發出去的 shot 用）=====
int editableShotDefaultLen = 6;          // 預設亮燈顆數
int editableShotDefaultFadeLen = 0;      // 預設漸層顆數
float editableShotDefaultBlinkSpeed = 0; // 預設閃爍速度
float editableShotDefaultBrightness = 1.0; // 預設整體亮度
float editableShotDefaultSpeed = 1.0;      // 預設移動速度

class EditableShot {
  int id;              // shot 編號
  float head;          // 目前頭部位置
  int len;             // 亮燈顆數
  int dir;             // 方向 +1 / -1

  int fadeLen;         // 漸層顆數
  float blinkSpeed;    // 閃爍速度
  float brightness;    // 整體亮度 0..1
  float speed;         // 這一發自己的移動速度

  EditableShot(int _id, float _head, int _len, int _dir,
    int _fadeLen, float _blinkSpeed, float _brightness, float _speed) {
    id = _id;
    head = _head;
    len = _len;
    dir = _dir;

    fadeLen = _fadeLen;
    blinkSpeed = _blinkSpeed;
    brightness = _brightness;
    speed = _speed;
  }
}

// ===== 發射一顆可個別編輯的 shot =====
void fireEditableShot(int n) {
  n = max(1, n);
  n = min(n, ribbonPath.size());

  int fireDir = editableShotDefaultDir;

  float startHead;
  if (fireDir > 0) {
    startHead = n - 1;
  } else {
    int maxIdx = min(countRunMax, getCurrentLayoutLastIndex());
    startHead = maxIdx;
  }

  EditableShot shot = new EditableShot(
    nextEditableShotId++,
    startHead,
    n,
    fireDir,
    editableShotDefaultFadeLen,
    editableShotDefaultBlinkSpeed,
    editableShotDefaultBrightness,
    editableShotDefaultSpeed
    );

  editableShots.add(shot);
  selectedEditableShotId = shot.id;
  syncEditableShotList();

  println("Fire editable shot => id =", shot.id,
    ", len =", shot.len,
    ", head =", shot.head,
    ", dir =", shot.dir);
}

// ===== 更新 editable shot 的位置 =====
void updateEditableShots() {
  if (!editableShotMode) return;
  if (editableShots == null || editableShots.size() == 0) return;

  int maxIdx = min(countRunMax, ribbonPath.size() - 1);
  if (maxIdx < 0) return;

  boolean listChanged = false;

  for (int i = editableShots.size() - 1; i >= 0; i--) {
    EditableShot shot = editableShots.get(i);

    shot.head += shot.speed * shot.dir;

    int head = floor(shot.head);
    int tail;

    if (shot.dir > 0) {
      tail = head - shot.len + 1;
      if (tail > maxIdx) {
        editableShots.remove(i);
        listChanged = true;
      }
    } else {
      tail = head + shot.len - 1;
      if (tail < 0) {
        editableShots.remove(i);
        listChanged = true;
      }
    }
  }

  if (selectedEditableShotId != -1 && getEditableShotById(selectedEditableShotId) == null) {
    selectedEditableShotId = -1;
  }

  if (listChanged) {
    syncEditableShotList();
  }
}

// 用 id 找 shot
EditableShot getEditableShotById(int targetId) {
  for (int i = 0; i < editableShots.size(); i++) {
    EditableShot s = editableShots.get(i);
    if (s.id == targetId) return s;
  }
  return null;
}

void selectNextEditableShot() {
  if (editableShots == null || editableShots.size() == 0) {
    selectedEditableShotId = -1;
    println("[EDITABLE] no shots to select");
    return;
  }

  // 如果還沒選，先選第一個
  if (selectedEditableShotId == -1) {
    selectedEditableShotId = editableShots.get(0).id;
    println("[EDITABLE] selected shot id =", selectedEditableShotId);
    return;
  }

  // 找目前選到的是第幾個
  for (int i = 0; i < editableShots.size(); i++) {
    if (editableShots.get(i).id == selectedEditableShotId) {
      int nextIndex = (i + 1) % editableShots.size();
      selectedEditableShotId = editableShots.get(nextIndex).id;
      println("[EDITABLE] selected shot id =", selectedEditableShotId);
      return;
    }
  }

  // 如果原本選的已經不在 list 裡，退回第一個
  selectedEditableShotId = editableShots.get(0).id;
  println("[EDITABLE] selected shot id =", selectedEditableShotId);
}

void selectPrevEditableShot() {
  if (editableShots == null || editableShots.size() == 0) {
    selectedEditableShotId = -1;
    println("[EDITABLE] no shots to select");
    return;
  }

  if (selectedEditableShotId == -1) {
    selectedEditableShotId = editableShots.get(editableShots.size() - 1).id;
    println("[EDITABLE] selected shot id =", selectedEditableShotId);
    return;
  }

  for (int i = 0; i < editableShots.size(); i++) {
    if (editableShots.get(i).id == selectedEditableShotId) {
      int prevIndex = (i - 1 + editableShots.size()) % editableShots.size();
      selectedEditableShotId = editableShots.get(prevIndex).id;
      println("[EDITABLE] selected shot id =", selectedEditableShotId);
      return;
    }
  }

  selectedEditableShotId = editableShots.get(editableShots.size() - 1).id;
  println("[EDITABLE] selected shot id =", selectedEditableShotId);
}

void editableShotBrightnessUp(float step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.brightness = constrain(s.brightness + step, 0, 1);
  println("[EDITABLE] shot", s.id, " brightness =", s.brightness);
}

void editableShotBrightnessDown(float step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.brightness = constrain(s.brightness - step, 0, 1);
  println("[EDITABLE] shot", s.id, " brightness =", s.brightness);
}

void editableShotSpeedUp(float step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.speed = max(0, s.speed + step);
  println("[EDITABLE] shot", s.id, " speed =", s.speed);
}

void editableShotSpeedDown(float step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.speed = max(0, s.speed - step);
  println("[EDITABLE] shot", s.id, " speed =", s.speed);
}

void editableShotLenUp(int step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.len = constrain(s.len + step, 1, ribbonPath.size());
  println("[EDITABLE] shot", s.id, " len =", s.len);
}

void editableShotLenDown(int step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.len = constrain(s.len - step, 1, ribbonPath.size());
  println("[EDITABLE] shot", s.id, " len =", s.len);

  // fadeLen 不要超過 len
  s.fadeLen = constrain(s.fadeLen, 0, s.len);
}

void editableShotFadeUp(int step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.fadeLen = constrain(s.fadeLen + step, 0, s.len);
  println("[EDITABLE] shot", s.id, " fadeLen =", s.fadeLen);
}

void editableShotFadeDown(int step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.fadeLen = constrain(s.fadeLen - step, 0, s.len);
  println("[EDITABLE] shot", s.id, " fadeLen =", s.fadeLen);
}

void editableShotBlinkUp(float step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.blinkSpeed = max(0, s.blinkSpeed + step);
  println("[EDITABLE] shot", s.id, " blinkSpeed =", s.blinkSpeed);
}

void editableShotBlinkDown(float step) {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) {
    println("[EDITABLE] no selected shot");
    return;
  }

  s.blinkSpeed = max(0, s.blinkSpeed - step);
  println("[EDITABLE] shot", s.id, " blinkSpeed =", s.blinkSpeed);
}
