import controlP5.*;
import peasy.*;
import java.util.*;
import processing.data.*;
import processing.sound.*;
import processing.serial.*;
Serial ledPort;
PFont uiFont;
PFont uiFontBold; // 粗體字

// ===================== 相機 / 模型 =====================
PeasyCam cam;
PShape model;

// 模型定位相關
PVector modelPos = new PVector(100, 200, -100);
float modelRotX = PI;
float modelScale = 1.0;
float modelRotY = 0.0;          // 固定轉到某個角度（弧度）
float modelSpinSpeed = 0.0;     // 每幀自轉速度（弧度/幀），0=不動

// ===================== LED Matrix allEdges id =====================
int[] ledEdgeIdx = {};
int numLights = ledEdgeIdx.length;   // columns
int numSegments = 20;                // rows
float[][] brightness = new float[numLights][numSegments];

// ===================== 邊線清單 =====================
ArrayList<Edge> allEdges = new ArrayList<>();
ArrayList<Edge> bottomDiagonals = new ArrayList<>();
float bottomBand  = 8; // 抓底部 高度帶寬（越小越嚴格）
float minDiagRise = 15; // 斜桿至少要有多少高度差（避免抓到水平邊）
float dotRadius = 3.0; // LED 像素大小

// ===================== 標籤選擇 =====================
boolean showEdgeLabels = false;
boolean labelAllEdges = false; // 按 A 切換
int labelStep = 1;
float pickThresh = 18;
PFont font;

// ===================== 動態效果 =====================
float t = 0;

// ===================== 介面互動 =====================
int hoverEdgeId = -1;
float hoverThresh = 16;   // hover 感應距離（像素），可調 12~25
float dotMin = 2;     // 最遠最小（像素）
float dotMax = 14;    // 最近最大（像素）

// ===================== 燈條排列 =====================
ArrayList<PVector> ribbonPath = new ArrayList<PVector>(); //彩帶
int spiralPixels = 700;     // 一條螺旋有幾個 pixel 點（越大越密）
float spiralSpeed = 1.2;    // 螺旋亮點跑的速度（越大越快）
float spiralSigma = 10.0;   // 亮點拖尾寬度（越大越柔）
float spiralBase = 6.0;     // 背景微亮（0~15）
float spiralPeak = 100.0;   // 亮點最亮（0~100）

// ===================== 只走球體的哪一段高度（0=最低, 1=最高），如果模型是 dome（半球），可以用 0.0~1.0；想避開最底可用 0.05~1.0  =====================
float spiralY0 = 0.02;
float spiralY1 = 0.98;

// ===================== 模型 bounds & 估算球參數  =====================
PVector bmin = new PVector();
PVector bmax = new PVector();
PVector sphereC = new PVector();
float sphereR = 200;

// ===================== 螺旋用的亮度矩陣（跟你 LED matrix 同概念） =====================
int spiralCols = 20;      // 一共有幾「根」
int spiralRows = 20;      // 每根有幾顆 pixel（高度分段）
float[][] spiralBri = new float[spiralCols][spiralRows];
boolean spiralSerpentine = true; // true=蛇形(一根往上下一根往下)

// ===================== 定義方向模式 =====================
final int AXIS_COL = 0;  // 左右（根/欄，i）
final int AXIS_ROW = 1;  // 上下（段/列，s）
int primaryAxis = AXIS_COL;   // 預設：左右掃
int secondaryAxis = AXIS_ROW; // 可選：加一個第二軸
boolean useSecondary = false; // 是否疊加第二軸

// ===================== 在首尾相接的一圈中，計算兩個位置的最短距離 =====================
float circularDist(float a, float b, float n) {
  float d = abs(a - b);
  return min(d, n - d);
}

// ===================== 一般直線排列中，兩個位置的距離  =====================
float linearDist(float a, float b) {
  return abs(a - b);
}

// ===================== 效果切換器 =====================
int fxMode = 0;
String[] fxNames = { "Cw", "Ccw", "Calm", "Sparkle", "Wave", "Lookup", "Broken", "Wake", "Joy", "Expand,", "FullOn"};
int FX_COUNT() {
  return fxNames.length;
}

// ===================== 顏色切換 =====================
float ledR = 0.0;
float ledG = 1.0;
float ledB = 0.0;

// ===================== Setup =====================
void setup() {
  fullScreen(P3D);
  //setupLedSerial(); //Esp32
  setupArtNet();

  // ===================== 麥克風 =====================
  mic = new AudioIn(this, 0);
  mic.start();
  amp = new Amplitude(this);
  amp.input(mic);
  for (int i = 0; i < ledSmooth.length; i++) {
    ledSmooth[i] = 0;
  }

  // ==================== 完全平面 Pixel Map 視窗大小（依最大列長度算） ====================
  flatView = createGraphics(flatW, flatH, P2D); //子畫面一
  int maxCols = 0;
  for (int r = 0; r < rowStart.length; r++) {
    maxCols = max(maxCols, rowEnd[r] - rowStart[r] + 1);
  }
  int pixelMapW = pixPad * 2 + maxCols * pixCell + pixelMapExtraW + pixelMapExtraLeft;
  int rowStep = pixCell + pixelRowGap;
  int pixelMapH = pixPad * 2 + rowStart.length * rowStep + pixelMapExtraH + pixelMapHeaderH;
  pixelMapView = createGraphics(pixelMapW, pixelMapH, P2D); //子畫面二

  // ==================== 相機/模型 ====================
  smooth(8);
  cam = new PeasyCam(this, 600);
  cam.setMinimumDistance(200);
  cam.setMaximumDistance(3000);
  model = loadShape("dome3.obj");
  model.disableStyle();

  // ==================== 第三種形式(節點) ====================
  meshNodes.clear();
  collectVerticesRecursive(model, meshNodes, vertexMergeEps);
  println("meshNodes =", meshNodes.size());
  buildOrderedMeshNodes(); // 模型節點按照「由下到上、每層再繞圈」排成一條可控制的序列
  applyManualNodeSwaps(); // 自動排好的節點順序，再手動微調幾個 index

  // ==================== 1) 建 allEdges（每條邊都有固定 id）====================
  allEdges.clear();
  collectEdgesRecursive(model, allEdges);
  println("allEdges =", allEdges.size());
  computeBoundsFromEdges(allEdges);
  buildSpiralsOnSphere();   // 生成兩條螺旋點

  // ====================  依據可用路徑範圍，建立 hold 狀態陣列（初始全為 false）  ====================
  int maxIdx = max(0, min(runHoldMax, ribbonPath.size() - 1));
  holdLit = new boolean[maxIdx + 1];
  for (int i = 0; i < holdLit.length; i++) holdLit[i] = false;

  // ==================== 2) 從 allEdges 篩 bottomDiagonals（底部斜桿） ====================
  bottomDiagonals = extractBottomDiagonals(allEdges, bottomBand, minDiagRise);
  println("bottomDiagonals =", bottomDiagonals.size());
  
  // ==================== 摩斯密碼 ====================
  initMorseMap();

  // ==================== 初始亮度 ====================
  for (int i = 0; i < numLights; i++) {
    for (int s = 0; s < numSegments; s++) brightness[i][s] = 10;
  }

  // ==================== 字體設置 ====================
  font = createFont("Arial", 12, true);
  uiFont = createFont("Microsoft JhengHei", 24, true);
  textFont(uiFont);
  uiFontBold = createFont("Microsoft JhengHei Bold", 24, true);

  // ==================== 滑桿設置 ===================
  cp5 = new ControlP5(this);
  cp5.setColorForeground(color(0, 180, 80));    // 一般綠
  cp5.setColorActive(color(0, 255, 120));       // 被點擊/啟用時更亮的綠
  cp5.setColorBackground(color(0, 70, 30));     // 深綠底
  cp5.setColorCaptionLabel(color(220));         // 標籤文字
  cp5.setColorValueLabel(color(255));           // 數值文字
  cp5.setFont(new ControlFont(uiFont, 16));  // 可改大一點
  cp5.setColorCaptionLabel(color(255));      // 可選：讓字更清楚
  cp5.setAutoDraw(false);   // PeasyCam，UI 建議自己在 HUD 裡畫

  // ==================== 介面選單 ====================
  Toggle paramT = cp5.addToggle("paramMode")
    .setPosition(20, 50)
    .setSize(52, 20)
    .setValue(paramMode)
    .setLabel("參數模式"); //paramMode
  paramT.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER);
  paramT.getCaptionLabel().setPaddingX(8);

  countRunToggle = cp5.addToggle("countRunMode")
    .setPosition(150, 50)
    .setSize(52, 20)
    .setValue(countRunMode)
    .setLabel("序列模式"); //countRunMode
  countRunToggle.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER);
  countRunToggle.getCaptionLabel().setPaddingX(8);

  Button flipB = cp5.addButton("flipDir")
    .setPosition(280, 50)
    .setSize(52, 20)
    .setLabel("反轉方向"); //flipDir
  flipB.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER);
  flipB.getCaptionLabel().setPaddingX(8);

  RadioButton rbLayout = cp5.addRadioButton("ledLayoutModeUI")
    .setPosition(20, 80)
    .setSize(52, 20)
    .setItemsPerRow(3)
    .setSpacingColumn(78)
    .addItem(" 彩帶形式", LAYOUT_RIBBON) //RIBBON
    .addItem(" 節點形式", LAYOUT_VERTEX); //VERTEX

  cp5.addSlider("brightCount")
    .setPosition(20, 110)
    .setSize(260, 18)
    .setRange(0.0, 30)
    .setValue(brightCount)
    .setDecimalPrecision(0)
    .setLabel("亮燈顆數");

  cp5.addSlider("darkCount")
    .setPosition(20, 140)
    .setSize(260, 18)
    .setRange(0.0, 30)
    .setValue(darkCount)
    .setDecimalPrecision(0)
    .setLabel("暗燈顆數");

  cp5.addSlider("fadeCount")
    .setPosition(20, 170)
    .setSize(260, 18)
    .setRange(0, 20)
    .setValue(fadeCount)
    .setDecimalPrecision(0)
    .setLabel("漸層顆數");

  cp5.addSlider("blinkSpeed")
    .setPosition(20, 200)
    .setSize(260, 18)
    .setRange(0.0, 5.0)
    .setValue(blinkSpeed)
    .setLabel("閃爍速度");

  cp5.addSlider("masterBrightness")
    .setPosition(20, 230)
    .setSize(260, 18)
    .setRange(0.0, 2.0)
    .setValue(masterBrightness)
    .setLabel("整體亮度");

  cp5.addSlider("moveSpeed")
    .setPosition(20, 260)
    .setSize(260, 18)
    .setRange(0.0, 20.0)
    .setValue(moveSpeed)
    .setLabel("移動速度");

  RadioButton rbAxis = cp5.addRadioButton("oscAxisUI")
    .setPosition(20, 290)
    .setSize(18, 18)
    .setItemsPerRow(3)
    .setSpacingColumn(60)
    .addItem("序列", AXIS_IDX) //IDX
    .addItem("左右", AXIS_COLF) //COL
    .addItem("上下 (作用軸)", AXIS_ROWF); //ROW
  rbAxis.activate(0); // 預設 IDX
  rbAxis.setLabel("axis");

  cp5.addSlider("ribbonTurns")
    .setPosition(20, 320)
    .setSize(260, 18)
    .setRange(1.0, 6.0) // 20
    .setValue(ribbonTurns)
    .setLabel("螺旋圈數");

  countRunField = cp5.addTextfield("countRunCountText")
    .setPosition(20, 350)
    .setSize(100, 20)
    .setAutoClear(false)
    .setText(str(countRunCount))
    .setLabel("輸入數字 / 字元"); //Count
  countRunField.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER);
  countRunField.getCaptionLabel().setPaddingX(190);   // 往右推
  countRunField.getCaptionLabel().setPaddingY(-8);    // 微調上下

  countRunStartBtn = cp5.addButton("startCountRun")
    .setPosition(140, 350)
    .setSize(70, 20)
    .setLabel("開始");

  countRunResetBtn = cp5.addButton("resetCountRun")
    .setPosition(230, 350)
    .setSize(70, 20)
    .setLabel("重置");

  setupEditableShotUI();
  setupEditableShotDefaultUI();
  syncEditableShotList();
  
  Toggle micT = cp5.addToggle("micModeUI")
    .setPosition(410, 50)
    .setSize(52, 20)
    .setValue(micMode)
    .setLabel("麥克風");
  micT.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER);
  micT.getCaptionLabel().setPaddingX(8);

  // ==================== 預設選項(介面) ====================
  rbLayout.activate(1); // 預設 RIBBON
  rbLayout.setLabel("layout"); // 給這組按鈕一個名字

  // ==================== 摩斯密碼 ====================
  loadCeremonyJsonAndPlay("ceremony.json");
  morseQueue.clear();
  morsePlaying = false;
  morseNextFrame = 0;
}

// ===================== draw =====================
void draw() {
  fxMode = ((fxMode % FX_COUNT()) + FX_COUNT()) % FX_COUNT(); //保險
  background(15);
  modelRotY += modelSpinSpeed;

  // ===== 地板 =====
  pushMatrix();
  translate(0, 200, 0);
  rotateX(HALF_PI);
  noStroke();
  fill(40);
  rectMode(CENTER);
  rect(0, 0, 1600, 1600);
  popMatrix();

  // ===== 光源 =====
  lights();
  ambientLight(30, 30, 30);
  directionalLight(220, 220, 220, -0.4, -1.0, -0.2);

  // ===== 模型 + LED（同一套 transform）=====
  pushMatrix();
  translate(modelPos.x, modelPos.y, modelPos.z);
  rotateY(modelRotY);
  rotateX(modelRotX);
  scale(modelScale);

  // ===== 模型線框 =====
  stroke(50);
  strokeWeight(1.2);
  noFill();
  shape(model);

  // ===== 各種方法 =====
  updateCountRun();   // 單圈多燈模式更新
  updateEditableShots(); // 每一幀更新所有「單段燈光 shot」的位置，並把已經跑出範圍的 shot 刪掉
  updateMorseQueue(); // 摩斯密碼
  updateMicInput(); // 麥克風輸入
  updateMicShots(); // 麥克風輸出燈光

  // ===== 根據你現在選到的 ledLayoutMode，決定這一幀要用哪一種方式把 LED 畫出來 =====
  if (ledLayoutMode == LAYOUT_EDGE) {
    drawLEDOnEdgesById(allEdges);
  } else if (ledLayoutMode == LAYOUT_RIBBON) {
    pushMatrix();
    translate(ribbonPreviewOffsetX, 0, 0);   // 只調整 3D 預覽位置
    drawSpiralLEDs();
    popMatrix();
  } else if (ledLayoutMode == LAYOUT_VERTEX) {
    drawMeshNodeLEDs();
    drawMeshNodeLabels();
  }

  // ===== 模型線框 =====
  if (runHoldMode && holdLit != null && holdLit.length > 0) {
    int head = int((frameCount * runHoldSpeed) % holdLit.length);
    // 偵測一輪結束回到 0（wrap）：自動歸零
    if (prevHoldHead != -1 && head < prevHoldHead) {
      for (int i = 0; i < holdLit.length; i++) holdLit[i] = false;
    }
    holdLit[head] = true;
    prevHoldHead = head;
  }

  // ===== 選單介面 =====
  drawFxHUD();
  popMatrix();
  hoverEdgeId = findHoverEdgeId(allEdges, mouseX, mouseY, hoverThresh);
  drawEdgeLabels(labelAllEdges ? allEdges : bottomDiagonals); // Labels：按 A 切換顯示 allEdges / bottomDiagonals（顯示的永遠是 edge.id）
  t += 0.02;
  
  //  ===== autoMorph：讓你不用按鍵也能看到「明滅->wave」連續變形  =====
  if (autoMorph) {
    spatialness = 0.5 + 0.5 * sin(frameCount * 0.01);
  }
  
  // ===== 選單介面互動 =====
  drawHoverTooltip();

  // ===== 子畫面一 (右上角) =====
  if (showFlatView) {
    renderFlatViewRibbon();
    cam.beginHUD();
    hint(DISABLE_DEPTH_TEST);
    float pad = 12;
    float x = width - flatW - pad;
    float y = pad;
    image(flatView, x, y); // 畫 flatView
    
    // 用 flatView 實際尺寸畫邊框
    pushStyle();
    rectMode(CORNER);
    noFill();
    stroke(255, 180);
    strokeWeight(2);
    rect(x, y, flatView.width, flatView.height, 10);
    popStyle();

    // 標題
    fill(255, 220);
    textAlign(LEFT, TOP);
    textSize(18);
    textFont(uiFontBold);
    text("平面視圖", x + 8, y + 8);
    textFont(uiFont); // 畫完再切回原本字型
    hint(ENABLE_DEPTH_TEST);
    cam.endHUD();
  }

  // 子畫面二 (左下角)
  if (showPixelMapView) {
    renderPixelMapView();
    cam.beginHUD();
    hint(DISABLE_DEPTH_TEST);
    float pad2 = 12;
    float w2 = pixelMapView.width  * pixelMapScale;
    float h2 = pixelMapView.height * pixelMapScale;

    // 右對齊（用放大後寬度 w2）
    float x2 = (width - w2 - pad2) + pixelMapXOffset;

    // 如果 flatView 開著，就往下排
    float y2 = (showFlatView ? (pad2 + flatH + pad2) : pad2) + pixelMapYOffset;

    // 貼圖
    image(pixelMapView, x2, y2, w2, h2);

    // 外框
    pushStyle();
    rectMode(CORNER);
    noFill();
    stroke(255, 180);
    strokeWeight(2);
    rect(x2, y2, w2, h2, 10);
    popStyle();
    fill(255, 220);
    textAlign(LEFT, TOP);
    textSize(18);
    textFont(uiFontBold);
    text("像素排列圖", x2 + 8, y2 + 8 );
    textFont(uiFont);
    hint(ENABLE_DEPTH_TEST);
    cam.endHUD();
  }

  if (showUI) {
    cam.beginHUD();
    hint(DISABLE_DEPTH_TEST);
    boolean overUI = (cp5 != null && cp5.isMouseOver()); // 只要滑鼠在 cp5 控制元件上，就暫停 PeasyCam 的滑鼠操控
    if (overUI && camMouseEnabled) {
      cam.setActive(false);
      camMouseEnabled = false;
    } else if (!overUI && !camMouseEnabled) {
      cam.setActive(true);
      camMouseEnabled = true;
    }
    cp5.draw();
    fill(255, 220);
    textFont(uiFontBold);
    textSize(24);
    text("燈光參數", 20, 15);
    hint(ENABLE_DEPTH_TEST);
    cam.endHUD();
  }
  trySendRibbonToH807();
}
