// 麥克風相關

AudioIn mic;
Amplitude amp;

boolean micMode = false;      // 麥克風模式開關
float micLevel = 0;           // 即時音量
float micLevelSmooth = 0;     // 平滑後音量
float micSmooth = 0.2;        // 0.1~0.3 可試
float micThreshold = 0.02;    // 講話門檻
float micBrightness = 0;      // 轉成燈光亮度 0..1

int micSegmentCenter = 20;   // 麥克風燈段中心位置
int micSegmentLen = 12;      // 麥克風燈段長度
float micFadePower = 1.5;    // 邊緣柔和程度

ArrayList<MicShot> micShots = new ArrayList<MicShot>();

int micShotLen = 5;              // 每次講話發出去的段長
float micShotSpeed = 2.5;        // 往前跑速度 (原1.0)
int micEmitIntervalMs = 120;     // 最短發射間隔
int lastMicEmitMs = 0;
float micShotFade = 0.6;         // 尾巴漸層比例 0~1

class MicShot {
  float head;        // 目前頭的位置
  int len;           // 這一段長度
  float brightness;  // 亮度 0..1
  float speed;       // 速度
  int dir;           // 方向 +1 / -1

  MicShot(float h, int l, float b, float s, int d) {
    head = h;
    len = l;
    brightness = b;
    speed = s;
    dir = d;
  }
}

// 有講話，亮度就出來、沒講話，亮度就是 0、音量越大，亮度越高
void updateMicInput() {
  if (!micMode) {
    micLevel = 0;
    micLevelSmooth = 0;
    micBrightness = 0;
    return;
  }

  micLevel = amp.analyze();
  micLevelSmooth = lerp(micLevelSmooth, micLevel, micSmooth);

  if (micLevelSmooth > micThreshold) {
    micBrightness = map(micLevelSmooth, micThreshold, 0.2, 0.1, 1.0);
    micBrightness = constrain(micBrightness, 0.1, 1.0);
  } else {
    micBrightness = 0;
  }
}

float evalMicTestV(int idx) {
  if (!micMode) return -1;
  if (micBrightness <= 0) return 0;

  int half = micSegmentLen / 2;
  int start = micSegmentCenter - half;
  int end   = micSegmentCenter + half;

  if (idx < start || idx > end) return 0;

  float dist = abs(idx - micSegmentCenter);
  float maxDist = max(1, half);

  float t = 1.0 - dist / maxDist;   // 中間=1, 邊緣接近0
  t = pow(constrain(t, 0, 1), micFadePower);

  return micBrightness * t;
}

void updateMicShots() {
  if (!micMode) {
    micShots.clear();
    return;
  }

  // 有聲音才發射
  if (micBrightness > 0 && millis() - lastMicEmitMs >= micEmitIntervalMs) {
    lastMicEmitMs = millis();

    int fireDir = (oscDir >= 0) ? +1 : -1;
    float startHead;

    if (fireDir > 0) {
      startHead = micShotLen - 1;
    } else {
      startHead = getCurrentLayoutLastIndex();
    }

    micShots.add(new MicShot(
      startHead,
      micShotLen,
      micBrightness,
      micShotSpeed,
      fireDir
      ));
  }

  // 更新每一段的位置
  // int maxIdx = min(testLedCount, ribbonPath.size()) - 1; // ~144
  int maxIdx = getCurrentLayoutLength() - 1;

  for (int i = micShots.size() - 1; i >= 0; i--) {
    MicShot s = micShots.get(i);
    s.head += s.speed * s.dir;

    int head = floor(s.head);
    int tail;

    if (s.dir > 0) {
      tail = head - s.len + 1;
      if (tail > maxIdx) {
        micShots.remove(i);
      }
    } else {
      tail = head + s.len - 1;
      if (tail < 0) {
        micShots.remove(i);
      }
    }
  }
}

float evalMicShotV(int idx) {
  if (!micMode) return -1;
  if (micShots == null || micShots.size() == 0) return 0;

  float best = 0;

  for (int i = 0; i < micShots.size(); i++) {
    MicShot s = micShots.get(i);

    int head = floor(s.head);

    if (s.dir > 0) {
      int tail = head - s.len + 1;

      if (idx >= tail && idx <= head) {
        int d = head - idx;   // 越接近頭部越亮
        float t = 1.0 - d / float(max(1, s.len - 1));

        // 尾巴漸層
        t = lerp(1.0 - micShotFade, 1.0, t);

        float v = s.brightness * constrain(t, 0, 1);
        if (v > best) best = v;
      }
    } else {
      int tail = head + s.len - 1;

      if (idx >= head && idx <= tail) {
        int d = idx - head;
        float t = 1.0 - d / float(max(1, s.len - 1));

        t = lerp(1.0 - micShotFade, 1.0, t);

        float v = s.brightness * constrain(t, 0, 1);
        if (v > best) best = v;
      }
    }
  }

  return best;
}
