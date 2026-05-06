// 當滑鼠靠近某條邊時（hoverEdgeId != -1），在滑鼠旁邊用 2D HUD 畫一個小黑底提示框，顯示「edge id: XXX」。

void drawHoverTooltip() {
  if (hoverEdgeId == -1) return;

  cam.beginHUD(); //讓你用螢幕座標畫 UI（跟 3D 場景分開）
  hint(DISABLE_DEPTH_TEST); //確保提示框永遠在最上層

  String msg = "edge id: " + hoverEdgeId;

  textAlign(LEFT, TOP);
  textSize(13);
  
  // 算提示框位置與大小
  float pad = 6;
  float tw = textWidth(msg);
  float x = mouseX + 12;
  float y = mouseY + 12;

  // 避免跑出畫面外
  if (x + tw + pad * 2 > width)  x = width - (tw + pad * 2) - 6;
  if (y + 18 + pad * 2 > height) y = height - (18 + pad * 2) - 6;

  // 畫黑底框，再畫白字
  noStroke();
  fill(0, 200);
  rectMode(CORNER);
  rect(x, y, tw + pad * 2, 18 + pad * 2, 6);

  fill(255);
  text(msg, x + pad, y + pad);
 
  // 收尾：恢復深度測試、結束 HUD
  hint(ENABLE_DEPTH_TEST);
  cam.endHUD();
}
