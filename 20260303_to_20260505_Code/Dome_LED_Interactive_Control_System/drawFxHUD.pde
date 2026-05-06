// UI 相關

// 顯示 AI 說的內容與轉譯代碼
void drawFxHUD() {
  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);
  pushStyle();

  noStroke();
  fill(0, 130, 30, 60);
  rect(300, 423, 560, 80, 10);

  fill(255);
  textSize(16);
  textAlign(LEFT, TOP);

  String showAISays = currentAISays;
  if (showAISays == null) showAISays = "";

  if (showAISays.length() > 28) {
    showAISays = showAISays.substring(0, 28) + "...";
  }

  String showCode = currentCodeText;
  if (showCode == null) showCode = "";

  text("AI 說 : " + showAISays, 28, 400);
  text("轉譯代碼 : " + showCode, 28, 430);

  popStyle();
  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}

// Shot 個體化編輯系統 UI
Group editableShotGroup;
Group editableShotDefaultGroup;

Slider editableShotBrightnessSlider;
Slider editableShotSpeedSlider;
Slider editableShotBlinkSlider;
Slider editableShotLenSlider;
Slider editableShotFadeSlider;

Slider editableShotDefaultLenSlider;
Slider editableShotDefaultFadeSlider;
Slider editableShotDefaultBrightnessSlider;
Slider editableShotDefaultSpeedSlider;
Slider editableShotDefaultBlinkSlider;

Button editableShotFireBtn;
Button editableShotClearBtn;
Button editableShotDefaultDirBtn;
Button editableShotReverseBtn;

ScrollableList editableShotListUI;

// 這些變數會被 ControlP5 slider 綁定，不建議刪
float editableShotUIBrightness = 1.0;
float editableShotUISpeed = 1.0;
float editableShotUIBlinkSpeed = 0.0;
float editableShotUILen = 3;
float editableShotUIFadeLen = 0;

int editableShotDefaultDir = 1;   // 1 = 正向, -1 = 反向

// 單段燈光參數 UI
void setupEditableShotUI() {  
  editableShotGroup = cp5.addGroup("editableShotGroup")
    .setPosition(20, 493)
    .setWidth(308)
    .setBackgroundHeight(190)
    .setBarHeight(17)
    .setBackgroundColor(color(0, 120))
    .setLabel("單段燈光參數");

  editableShotLenSlider = cp5.addSlider("editableShotUILen")
    .setPosition(10, 10)
    .setSize(220, 18)
    .setRange(1, 30)
    .setValue(3)
    .setDecimalPrecision(0)
    .setLabel("亮燈顆數")
    .setGroup(editableShotGroup);

  editableShotFadeSlider = cp5.addSlider("editableShotUIFadeLen")
    .setPosition(10, 40)
    .setSize(220, 18)
    .setRange(0, 20)
    .setValue(0)
    .setDecimalPrecision(0)
    .setLabel("漸層顆數")
    .setGroup(editableShotGroup);

  editableShotBlinkSlider = cp5.addSlider("editableShotUIBlinkSpeed")
    .setPosition(10, 70)
    .setSize(220, 18)
    .setRange(0, 5)
    .setValue(0.0)
    .setLabel("閃爍速度")
    .setGroup(editableShotGroup);

  editableShotBrightnessSlider = cp5.addSlider("editableShotUIBrightness")
    .setPosition(10, 100)
    .setSize(220, 18)
    .setRange(0, 2)
    .setValue(1.0)
    .setLabel("整體亮度")
    .setGroup(editableShotGroup);

  editableShotSpeedSlider = cp5.addSlider("editableShotUISpeed")
    .setPosition(10, 130)
    .setSize(220, 18)
    .setRange(0, 20)
    .setValue(1.0)
    .setLabel("移動速度")
    .setGroup(editableShotGroup);

  editableShotListUI = cp5.addScrollableList("editableShotListUI")
    .setPosition(10, 160)
    .setSize(220, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .setLabel("燈光編號")
    .setGroup(editableShotGroup);

  editableShotReverseBtn = cp5.addButton("editableShotReverseSelected")
    .setPosition(240, 160)
    .setSize(58, 20)
    .setLabel("反轉")
    .setGroup(editableShotGroup);
}

// 同步目前選取的 shot 到 UI slider
void syncEditableShotUI() {
  EditableShot s = getEditableShotById(selectedEditableShotId);
  if (s == null) return;

  if (editableShotLenSlider != null && !editableShotLenSlider.isMousePressed()) {
    editableShotLenSlider.setValue(s.len);
  }

  if (editableShotFadeSlider != null && !editableShotFadeSlider.isMousePressed()) {
    editableShotFadeSlider.setValue(s.fadeLen);
  }

  if (editableShotBrightnessSlider != null && !editableShotBrightnessSlider.isMousePressed()) {
    editableShotBrightnessSlider.setValue(s.brightness);
  }

  if (editableShotSpeedSlider != null && !editableShotSpeedSlider.isMousePressed()) {
    editableShotSpeedSlider.setValue(s.speed);
  }

  if (editableShotBlinkSlider != null && !editableShotBlinkSlider.isMousePressed()) {
    editableShotBlinkSlider.setValue(s.blinkSpeed);
  }
}

// 更新 shot 清單
void syncEditableShotList() {
  if (editableShotListUI == null) return;

  editableShotListUI.clear();

  for (int i = 0; i < editableShots.size(); i++) {
    EditableShot s = editableShots.get(i);
    editableShotListUI.addItem("編號 " + s.id, s.id);
  }
}

// 預設單段燈光參數 UI
void setupEditableShotDefaultUI() {
  editableShotDefaultGroup = cp5.addGroup("editableShotDefaultGroup")
    .setPosition(342, 493)
    .setWidth(308)
    .setBackgroundHeight(190)
    .setBarHeight(17)
    .setBackgroundColor(color(0, 120))
    .setLabel("預設單段燈光參數");

  editableShotDefaultLenSlider = cp5.addSlider("editableShotDefaultLenUI")
    .setPosition(10, 10)
    .setSize(220, 18)
    .setRange(1, 30)
    .setValue(editableShotDefaultLen)
    .setDecimalPrecision(0)
    .setLabel("亮燈顆數")
    .setGroup(editableShotDefaultGroup);

  editableShotDefaultFadeSlider = cp5.addSlider("editableShotDefaultFadeLenUI")
    .setPosition(10, 40)
    .setSize(220, 18)
    .setRange(0, 20)
    .setValue(editableShotDefaultFadeLen)
    .setDecimalPrecision(0)
    .setLabel("漸層顆數")
    .setGroup(editableShotDefaultGroup);

  editableShotDefaultBlinkSlider = cp5.addSlider("editableShotDefaultBlinkSpeedUI")
    .setPosition(10, 70)
    .setSize(220, 18)
    .setRange(0, 5)
    .setValue(editableShotDefaultBlinkSpeed)
    .setLabel("閃爍速度")
    .setGroup(editableShotDefaultGroup);

  editableShotDefaultBrightnessSlider = cp5.addSlider("editableShotDefaultBrightnessUI")
    .setPosition(10, 100)
    .setSize(220, 18)
    .setRange(0, 2)
    .setValue(editableShotDefaultBrightness)
    .setLabel("整體亮度")
    .setGroup(editableShotDefaultGroup);

  editableShotDefaultSpeedSlider = cp5.addSlider("editableShotDefaultSpeedUI")
    .setPosition(10, 130)
    .setSize(220, 18)
    .setRange(0, 20)
    .setValue(editableShotDefaultSpeed)
    .setLabel("移動速度")
    .setGroup(editableShotDefaultGroup);

  editableShotFireBtn = cp5.addButton("editableShotFire")
    .setPosition(10, 160)
    .setSize(90, 20)
    .setLabel("開始")
    .setGroup(editableShotDefaultGroup);

  editableShotClearBtn = cp5.addButton("editableShotClearAll")
    .setPosition(110, 160)
    .setSize(90, 20)
    .setLabel("重置")
    .setGroup(editableShotDefaultGroup);

  editableShotDefaultDirBtn = cp5.addButton("editableShotToggleDefaultDir")
    .setPosition(210, 160)
    .setSize(90, 20)
    .setLabel("正向")
    .setGroup(editableShotDefaultGroup);

  updateEditableShotDefaultDirButton();
}

// 更新預設方向按鈕文字
void updateEditableShotDefaultDirButton() {
  if (editableShotDefaultDirBtn == null) return;

  if (editableShotDefaultDir > 0) {
    editableShotDefaultDirBtn.setLabel("正向");
  } else {
    editableShotDefaultDirBtn.setLabel("反向");
  }
}
