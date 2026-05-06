// 在模型表面上，沿著高度 y 從下到上，取很多個點，讓它們繞著中心轉很多圈，形成一條「貼在球面上的螺旋線」，把這些點存進 spiral1 供後面畫 LED 用。
void buildSpiralsOnSphere() {
  spiral1.clear();
  if (spiralPixels < 10) spiralPixels = 10;

  // 螺旋要走的高度範圍
  float yMin = lerp(bmin.y, bmax.y, spiralY0);
  float yMax = lerp(bmin.y, bmax.y, spiralY1);

  // 從底到頂走一遍
  for (int i = 0; i < spiralPixels; i++) {
    float tt = (spiralPixels == 1) ? 0 : i / float(spiralPixels - 1);

    float y = lerp(yMin, yMax, tt);
    float dy = y - sphereC.y;

    float rY2 = sphereR * sphereR - dy * dy;
    float rY = (rY2 <= 0) ? 0 : sqrt(rY2);

    float ang = TWO_PI * spiralTurns * tt;

    // 把「該高度的圓周座標」轉成 3D 點
    PVector p = new PVector(
      sphereC.x + rY * cos(ang),
      y,
      sphereC.z + rY * sin(ang)
      );

    spiral1.add(p);
  }
}
