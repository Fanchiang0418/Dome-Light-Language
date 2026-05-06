// 單顆 LED 呼叫

boolean manualMode = false;     // true = 全暗手動模式
float manualBaseBri = 0;        // 全暗底光 (0~10)

String inputBuf = "";            // 目前輸入中的數字字串
int manualPixel = -1;            // 目前指定亮的 index
float manualPixelBri = 1.0;      // 指定亮度(0..1)，1=全亮

// ===== 指定亮燈（override）=====
HashMap<Integer, Float> pixelOverride = new HashMap<Integer, Float>(); // idx -> 0..1
int selectedPixel = -1;           // 目前選到的 ribbon pixel index
float overrideValue = 1.0;        // 強制亮度（1.0=全亮）
float pickRadiusScreen = 18;      // 用螢幕距離挑選（可調 12~30）

int pickRibbonPixelByScreen(float mx, float my, float threshPx) {
  if (ribbonPath == null || ribbonPath.size() == 0) return -1;

  int best = -1;
  float bestD2 = threshPx * threshPx;

  for (int i = 0; i < ribbonPath.size(); i++) {
    if (hiddenPixels.contains(i)) continue;

    PVector p = ribbonPath.get(i);
    float sx = screenX(p.x, p.y, p.z);
    float sy = screenY(p.x, p.y, p.z);

    float d2 = sq(mx - sx) + sq(my - sy);
    if (d2 < bestD2) {
      bestD2 = d2;
      best = i;
    }
  }
  return best;
}
