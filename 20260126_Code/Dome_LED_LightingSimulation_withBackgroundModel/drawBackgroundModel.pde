void drawBackgroundModel(PGraphics g) {
  g.pushMatrix();
  g.translate(bgPos.x, bgPos.y, bgPos.z);
  g.rotateX(bgRotX);
  g.rotateY(bgRotY);
  g.rotateZ(bgRotZ);

  g.scale(bgScale, -bgScale, bgScale); // ✅ 上下翻轉

  g.stroke(140);
  g.noFill();
  g.shape(bgModel);
  g.popMatrix();
}
