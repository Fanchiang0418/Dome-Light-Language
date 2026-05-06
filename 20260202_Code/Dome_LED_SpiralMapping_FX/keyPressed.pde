void keyPressed() {
  if (key == 'a' || key == 'A') labelAllEdges = !labelAllEdges; // 切換要標哪一組邊(顯示全部邊的 / 只顯示底部斜邊那圈)
  if (key == 'l' || key == 'L') showEdgeLabels = !showEdgeLabels; // 顯示邊的文字標籤
  if (key == '-') labelStep++; // 讓標籤變「更稀疏」
  if (key == '+' || key == '=') labelStep = max(1, labelStep - 1); // 讓標籤變「更密」
  if (key == 's' || key == 'S') spiralSolidMode = !spiralSolidMode; // 切換螺旋「全亮」或「流動」

  if (key == 'x' || key == 'X') primaryAxis = AXIS_COL;     // 左右
  if (key == 'y' || key == 'Y') primaryAxis = AXIS_ROW;     // 上下
  if (key == 'z' || key == 'Z') useSecondary = !useSecondary; // 開/關疊加第二軸

  if (key == 'n' || key == 'N') fxMode = (fxMode + 1) % FX_COUNT();
  if (key == 'p' || key == 'P') fxMode = (fxMode - 1 + FX_COUNT()) % FX_COUNT();
  
  // ===================== 顏色切換 =====================
  if (key == 'g' || key == 'G') { ledR = 0; ledG = 1; ledB = 0; } // 綠
  if (key == 'w' || key == 'W') { ledR = 1; ledG = 1; ledB = 1; } // 白
  
  println("fxMode =", fxMode, fxNames[fxMode]); // 一按就會印，確認有沒有反應

  println("labelAllEdges =", labelAllEdges,
    "labelStep =", labelStep,
    "showEdgeLabels =", showEdgeLabels);
}
