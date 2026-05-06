// UI
void drawFxHUD() {
  cam.beginHUD();
  hint(DISABLE_DEPTH_TEST);

  String axisStr = (primaryAxis == AXIS_COL) ? "X軸" : "Y軸";
  String line1 = "目前效果：" + fxNames[fxMode];
  String line2 = "方向(X鍵/Y鍵)： " + axisStr;
  String line3 = "效果切換：N鍵/P鍵";

  float pad = 10;
  textSize(24);

  float w = max(textWidth(line1), textWidth(line2)) + pad * 2;
  float h = 44;                 // 兩行高度
  float x = 12, y = 12;

  noStroke();
  fill(0, 180);
  rect(x, y, w, h, 8);

  fill(255);
  textAlign(LEFT, TOP);
  text(line1, x + pad, y + 6);
  text(line2, x + pad, y + 50);
  text(line3, x + pad, y + 94);

  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}
