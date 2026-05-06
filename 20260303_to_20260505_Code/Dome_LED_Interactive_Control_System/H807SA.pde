// Processing → Art-Net → H807SA 控制器 → 實體 LED 燈條

import java.net.*;

// ===================== H807SA / Art-Net 設定 =====================
DatagramSocket artnetSocket;
InetAddress h807Ip;
String h807IpStr = "192.168.1.10";   // 你的 H807SA IP
int artnetPort = 6454;               // Art-Net UDP port
boolean artnetEnabled = true;

// ===================== LED 輸出控制 =====================
int testLedCount = 1200;
int lastSendMs = 0;

int sendIntervalMs = 16;  // 控制頻率、約 60fps
float[] ledSmooth = new float[testLedCount];
float smoothLerp = 0.25;

// UDP
void setupArtNet() {
  try {
    h807Ip = InetAddress.getByName(h807IpStr);
    artnetSocket = new DatagramSocket();
    println("[ARTNET OK] " + h807IpStr + ":" + artnetPort);
  }
  catch (Exception e) {
    println("[ARTNET ERROR] 無法建立 Art-Net 連線");
    e.printStackTrace();
    artnetEnabled = false;
  }
}

// 避免每一幀都亂送太快，檢查距離上次送資料有沒有超過 16ms，如果還沒到就不送
void trySendRibbonToH807() {
  if (millis() - lastSendMs < sendIntervalMs) return;
  lastSendMs = millis();
  sendRibbonToH807();
}

//核心函式
void sendRibbonToH807() {
  if (!artnetEnabled) return;
  if (artnetSocket == null || h807Ip == null) return;
  if (ribbonPath == null || ribbonPath.size() == 0) return;
   /*
   Art-Net 沒開 → 不送
   Socket 沒建立 → 不送
   H807SA IP 沒設定 → 不送
   ribbonPath 沒有點位 → 不送
   */

  // 確認都沒問題後，它會送 8 個 Universe
  for (int u = 0; u < 8; u++) {
    int start = u * 150;
    sendArtNetUniverse(u, start, 150);
  }
   /*
   Universe 0：第 0～149 顆
   Universe 1：第 150～299 顆
   Universe 2：第 300～449 顆
   Universe 3：第 450～599 顆
   Universe 4：第 600～749 顆
   Universe 5：第 750～899 顆
   Universe 6：第 900～1049 顆
   Universe 7：第 1050～1199 顆
   */
}

// Art-Net 封包內容
void sendArtNetUniverse(int universe, int startLed, int count) {
  int totalAvailable = testLedCount;

  if (startLed >= totalAvailable) return;

  int actualCount = min(count, totalAvailable - startLed);
  int channels = actualCount * 3;

  byte[] packet = new byte[18 + channels];

  // ===================== Art-Net Header =====================
  packet[0] = 'A';
  packet[1] = 'r';
  packet[2] = 't';
  packet[3] = '-';
  packet[4] = 'N';
  packet[5] = 'e';
  packet[6] = 't';
  packet[7] = 0x00;

  // OpCode = ArtDMX
  packet[8] = 0x00;
  packet[9] = 0x50;

  // Protocol version = 14
  packet[10] = 0x00;
  packet[11] = 0x0E;

  packet[12] = 0x00; // Sequence
  packet[13] = 0x00; // Physical

  // Universe
  packet[14] = (byte)(universe & 0xFF);
  packet[15] = (byte)((universe >> 8) & 0xFF);

  // Length
  packet[16] = (byte)((channels >> 8) & 0xFF);
  packet[17] = (byte)(channels & 0xFF);

  // ===================== LED Data =====================
  int idx = 18;

  for (int j = 0; j < actualCount; j++) {
    int physicalI = startLed + j;

    // 將 1200 顆實體 LED 映射到 765 個 ribbonPath 點
    int virtualI = int(map(
      physicalI,
      0,
      testLedCount - 1,
      0,
      ribbonPath.size() - 1
      ));

    virtualI = constrain(virtualI, 0, ribbonPath.size() - 1);

    float v = evalPixelV(virtualI);
    v = constrain(v, 0, 1);

    if (v < 0.02) v = 0;

    int r = int(255 * ledR * v);
    int g = int(255 * ledG * v);
    int b = int(255 * ledB * v);

    r = constrain(r, 0, 255);
    g = constrain(g, 0, 255);
    b = constrain(b, 0, 255);

    // RGB 色序
    packet[idx++] = (byte)r;
    packet[idx++] = (byte)g;
    packet[idx++] = (byte)b;
  }

  try {
    DatagramPacket dp = new DatagramPacket(packet, packet.length, h807Ip, artnetPort);
    artnetSocket.send(dp);
  }
  catch (Exception e) {
    println("[ARTNET SEND ERROR] universe = " + universe);
    e.printStackTrace();
  }
}

// 測試用：確認 H807SA 的 Universe / Port / RGB 色序是否正常。若硬體確認完成，可保留註解，不需要在正式輸出時呼叫。
/*
void sendTestUniverse(int universe, int count) {
  int channels = count * 3;
  byte[] packet = new byte[18 + channels];

  // ===================== Art-Net Header =====================
  packet[0] = 'A';
  packet[1] = 'r';
  packet[2] = 't';
  packet[3] = '-';
  packet[4] = 'N';
  packet[5] = 'e';
  packet[6] = 't';
  packet[7] = 0x00;

  packet[8] = 0x00;
  packet[9] = 0x50;

  packet[10] = 0x00;
  packet[11] = 0x0E;

  packet[12] = 0x00;
  packet[13] = 0x00;

  packet[14] = (byte)(universe & 0xFF);
  packet[15] = (byte)((universe >> 8) & 0xFF);

  packet[16] = (byte)((channels >> 8) & 0xFF);
  packet[17] = (byte)(channels & 0xFF);

  int idx = 18;

  for (int i = 0; i < count; i++) {
    int r = 0;
    int g = 0;
    int b = 0;

    // 每個 Universe 給不同亮度，方便看有沒有分出去
    if (universe == 0) {
      r = 255;
      g = 0;
      b = 0;
    } // Port1 紅
    if (universe == 1) {
      r = 0;
      g = 255;
      b = 0;
    } // Port2 綠
    if (universe == 2) {
      r = 0;
      g = 0;
      b = 255;
    } // Port3 藍
    if (universe == 3) {
      r = 255;
      g = 255;
      b = 0;
    } // Port4 黃
    if (universe == 4) {
      r = 0;
      g = 255;
      b = 255;
    } // Port5 青
    if (universe == 5) {
      r = 255;
      g = 0;
      b = 255;
    } // Port6 紫
    if (universe == 6) {
      r = 255;
      g = 120;
      b = 0;
    } // Port7 橘
    if (universe == 7) {
      r = 255;
      g = 255;
      b = 255;
    } // Port8 白

    // RGB 色序
    packet[idx++] = (byte)r;
    packet[idx++] = (byte)g;
    packet[idx++] = (byte)b;
  }

  try {
    DatagramPacket dp = new DatagramPacket(packet, packet.length, h807Ip, artnetPort);
    artnetSocket.send(dp);
  }
  catch (Exception e) {
    println("[ARTNET TEST SEND ERROR] universe = " + universe);
    e.printStackTrace();
  }
}
*/
