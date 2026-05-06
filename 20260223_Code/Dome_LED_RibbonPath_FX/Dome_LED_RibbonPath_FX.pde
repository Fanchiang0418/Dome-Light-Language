import peasy.*;
import java.util.*;
PFont uiFont;

// ===================== 相機 / 模型 =====================
PeasyCam cam;
PShape model;

// 模型定位
PVector modelPos = new PVector(100, 200, -100);
float modelRotX = PI;
float modelScale = 1.0;
float modelRotY = 0.0;          // 固定轉到某個角度（弧度）
float modelSpinSpeed = 0.0;     // 每幀自轉速度（弧度/幀），0=不動

// ===================== LED Matrix 這裡視為 allEdges 的 id（編碼）=====================
int[] ledEdgeIdx = {
  //1140, 4211, 5362,  3202,  3451, 4290, 5447, 969, 688, 157,//第一行槓
  //1082, 4898, 2489, 2196, 2929, 3564, 4730, 862, 4669, 4840 ,3921, 1346, 3396,  3701, 2071, 2837 , 4571,  3100,  84, 2526 ,1262, 5029,  490, 1903, 2025,  //第一層
  //2416, 1329, 5490, 1720, 47, 3173, 4394, 4049, 1940, 5273, 3280, 2254, 2309, 1445, 4107,  //第二行槓
  //2135, 5322,   636,   1497,  2889, 4800,   221,   398,  1775, 2593, 3063,   725,   325,  2370, 3536, //第二層(右)
  //566, 1520,  1827,   1204,  3625, 3356,  3799,   804,   282, 5188, 3979, 3724, 4336, 905, 1656,//第二層(左)
  //5160, 4942, 432, 3008, 3881, 1039, 4455, 2660, 2779, 5998, 7988, 2721, 5093,7800, 4519, 4171,//第三行槓
  //8019,   8165, 12863,  6410, 11151, 6077, 13413, 12735, 14918, 12967, 9118,  9408, 10427, 10195, 14893,//第三層(右)
  //10626, 13892, 11993, 14069,  9539, 7274, 10299, 14808,  6874, 8733, 14197, 11917,  7900,  8092,  7222,//第三層(左)
  //9954, 13938, 13205, 12454, 14118, 13782, 6117, 10470, 12018, 7045, 13144, 9896, 10018, 8382, 13327,//第四行槓
  //10519, 6624, 5827, 9490, 11209, 9194, 14454, 6291, 8266, 10107, 13596, 5726, 5928, 8611, 9777,//第四層(右)
  //11682, 12906, 6816, 8428, 6245, 8321, 8654, 7399, 11355, 10986, 11813, 6709, 5772, 14222, 12213,//第四層(左)
  //10864, 9316, 9368, 8196, 12335, 9585, 7561, 14710, 8483, 5543, 10757, 13022, 12271, 8956, 14350,//第五行槓
  //5595, 7451, 6172, 9020, 13703, 9243, 11279, 6752, 13651, 7683, 11529, 10046, 10693,//第五層(右)
  //9707, 13831, 8846, 7149, 9655, 10351, 13541, 13492, 12082, 11041, 9090, 13254,//第五層(左)
  //6975, 6468, 5638, 7332, 12482, 14518, 10824, 11111, 12680, 14646,//第六行槓
  //8901, 7521, 11450, 12631, 7857, 10925, 6938,//第六層(右)
  //8794, 14600, 9829, 11630, 15003, 15052, 14777,//第六層(左)
  //14295, 6532, 14396, 11569, 13361,//第七行槓
  //6596, 7109, 11737,//第七層(右)
  //13071, 10574,//第七層(左)
};

int numLights = ledEdgeIdx.length;   // columns
int numSegments = 20;                // rows
float[][] brightness = new float[numLights][numSegments];

// ===================== 邊線清單 =====================
ArrayList<Edge> allEdges = new ArrayList<>();
ArrayList<Edge> bottomDiagonals = new ArrayList<>();

// 抓底部 高度帶寬（越小越嚴格）
float bottomBand  = 8;
// 斜桿至少要有多少高度差（避免抓到水平邊）
float minDiagRise = 15;

// LED 像素大小
float dotRadius = 3.0;

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
//ArrayList<PVector> spiral1 = new ArrayList<PVector>(); //螺旋
ArrayList<PVector> ribbonPath = new ArrayList<PVector>(); //彩帶

int spiralPixels = 700;     // 一條螺旋有幾個 pixel 點（越大越密）
float spiralTurns = 10.0;    // 從底到頂繞幾圈（彈簧層數）
float spiralSpeed = 1.2;    // 螺旋亮點跑的速度（越大越快）
float spiralSigma = 10.0;   // 亮點拖尾寬度（越大越柔）
float spiralBase = 6.0;     // 背景微亮（0~15）
float spiralPeak = 100.0;   // 亮點最亮（0~100）

// 只走球體的哪一段高度（0=最低, 1=最高）
// 如果你的模型是 dome（半球），可以用 0.0~1.0；想避開最底可用 0.05~1.0
float spiralY0 = 0.02;
float spiralY1 = 0.98;

// 模型 bounds & 估算球參數
PVector bmin = new PVector();
PVector bmax = new PVector();
PVector sphereC = new PVector();
float sphereR = 200;

// ===================== 000 =====================
boolean spiralSolidMode = true;  // true=全亮, false=流動
float spiralSolidBri = 100;      // 全亮亮度 0~100

// ===================== 螺旋用的亮度矩陣（跟你 LED matrix 同概念） =====================
int spiralCols = 20;      // 一共有幾「根」(像你圖上的一根一根)
int spiralRows = 20;      // 每根有幾顆 pixel（高度分段）
float[][] spiralBri = new float[spiralCols][spiralRows];

boolean spiralSerpentine = true; // true=蛇形(一根往上下一根往下)，更像你手繪

//  ===================== 定義方向模式 =====================
final int AXIS_COL = 0;  // 左右（根/欄，i）
final int AXIS_ROW = 1;  // 上下（段/列，s）

int primaryAxis = AXIS_COL;   // 預設：左右掃
int secondaryAxis = AXIS_ROW; // 可選：加一個第二軸
boolean useSecondary = false; // 是否疊加第二軸

float circularDist(float a, float b, float n) {
  float d = abs(a - b);
  return min(d, n - d);
}

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
  smooth(8);

  cam = new PeasyCam(this, 600);
  cam.setMinimumDistance(200);
  cam.setMaximumDistance(3000);

  model = loadShape("dome3.obj");
  model.disableStyle();

  // 1) 建 allEdges（每條邊都有固定 id）
  allEdges.clear();
  collectEdgesRecursive(model, allEdges);
  println("allEdges =", allEdges.size());

  computeBoundsFromEdges(allEdges);
  buildSpiralsOnSphere();   // 生成兩條螺旋點

  // 2) 從 allEdges 篩 bottomDiagonals（底部斜桿）
  bottomDiagonals = extractBottomDiagonals(allEdges, bottomBand, minDiagRise);
  println("bottomDiagonals =", bottomDiagonals.size());

  // 初始亮度
  for (int i = 0; i < numLights; i++) {
    for (int s = 0; s < numSegments; s++) brightness[i][s] = 10;
  }

  font = createFont("Arial", 12, true);

  uiFont = createFont("Microsoft JhengHei", 24, true); // Windows 常見
  // 或：uiFont = createFont("PingFang TC", 16, true); // macOS
  textFont(uiFont);

  // 隱藏 288~298 與 170~184
  for (int i = 287; i <= 299; i++) hiddenPixels.add(i);
  for (int i = 169; i <= 185; i++) hiddenPixels.add(i);
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

  // 模型線框
  stroke(50);
  strokeWeight(1.2);
  noFill();
  shape(model);

  // LED：用 allEdges 的 id 去找邊
  drawLEDOnEdgesById(allEdges);

  // 只算 spiralBri
  updateSpiralFX();

  // 加：畫 pixel 編號（一定要在同一套 transform 內）
  drawRibbonPixelLabels();

  // 新增：球面螺旋 LED
  drawSpiralLEDs();
  drawFxHUD();

  popMatrix();

  hoverEdgeId = findHoverEdgeId(allEdges, mouseX, mouseY, hoverThresh);

  // Labels：按 A 切換顯示 allEdges / bottomDiagonals（顯示的永遠是 edge.id）
  drawEdgeLabels(labelAllEdges ? allEdges : bottomDiagonals);

  updateCalm();
  t += 0.02;

  drawHoverTooltip();
}
