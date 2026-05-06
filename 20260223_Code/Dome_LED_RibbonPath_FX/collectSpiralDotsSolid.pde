// 全亮模式 (燈校)(未用到)
void collectSpiralDotsSolid(ArrayList<PVector> spiral, ArrayList<float[]> outDots, float bri100) {
  float v = constrain(bri100 / 100.0, 0, 1);

  for (int i = 0; i < spiral.size(); i++) {
    PVector p = spiral.get(i);

    float sx = screenX(p.x, p.y, p.z);
    float sy = screenY(p.x, p.y, p.z);
    float sz = screenZ(p.x, p.y, p.z);

    outDots.add(new float[]{sx, sy, sz, v});
  }
}
