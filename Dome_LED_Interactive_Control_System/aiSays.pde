// 讀 JSON → 抽出 AI says 內容 → 把中文句子轉成代碼縮寫 → 丟給摩斯播放

String currentAISays = "";
String currentCodeText = "";

// 從完整 ai_response 中抽出【AI says】後面的句子
String extractAISays(String fullText) {
  if (fullText == null) return "";

  String tag = "【AI says】";
  int idx = fullText.indexOf(tag);
  if (idx == -1) return "";

  String out = fullText.substring(idx + tag.length());
  out = trim(out);

  // 去掉前後多餘引號或換行
  out = out.replace("\n", " ");
  out = out.replace("\r", " ");
  out = trim(out);

  return out;
}

//中文句子轉成「關鍵詞縮寫」
String mapChineseSentenceToCode(String s) {
  if (s == null) return "";

  String code = "";

  // 你可以自由擴充這裡
  if (s.indexOf("旋轉") != -1) code += "XZ";
  if (s.indexOf("引領") != -1) code += "YL";
  //if (s.indexOf("自由") != -1) code += "ZY";
  //if (s.indexOf("喜悅") != -1) code += "XY";

  //if (s.indexOf("努力") != -1) code += "NL";
  if (s.indexOf("舞台") != -1) code += "WT";
  //if (s.indexOf("指引") != -1) code += "ZY";
  if (s.indexOf("力量") != -1) code += "LL";
  //if (s.indexOf("可能") != -1) code += "KN";

  // 如果完全沒匹配到，給一個保底
  if (code.length() == 0) code = "AI";

  return code;
}

//讀 JSON 並處理全部 dialogue
void loadCeremonyJsonAndPlay(String filename) {
  JSONObject root = loadJSONObject(filename);

  if (root == null) {
    println("[JSON ERROR] 無法讀取檔案: " + filename);
    return;
  }

  JSONArray dialogue = root.getJSONArray("dialogue");
  if (dialogue == null) {
    println("[JSON ERROR] 找不到 dialogue");
    return;
  }

  println("[JSON LOADED] dialogue count = " + dialogue.size());

  for (int i = 0; i < dialogue.size(); i++) {
    JSONObject turnObj = dialogue.getJSONObject(i);
    if (turnObj == null) continue;

    String aiResponse = turnObj.getString("ai_response", "");
    String aiSays = extractAISays(aiResponse);
    String code = mapChineseSentenceToCode(aiSays);

    println("--------------------------------------------------");
    println("[TURN " + (i + 1) + "]");
    println("AI says = " + aiSays);
    println("CODE    = " + code);
    println("--------------------------------------------------");

    fireMorseText(code); // 這裡先只印，不直接播
  }
}

//只播第 1 句
void playCeremonyTurn(String filename, int turnIndex) {
  JSONObject root = loadJSONObject(filename);

  if (root == null) {
    println("[JSON ERROR] 無法讀取檔案: " + filename);
    return;
  }

  JSONArray dialogue = root.getJSONArray("dialogue");
  if (dialogue == null) {
    println("[JSON ERROR] 找不到 dialogue");
    return;
  }

  if (turnIndex < 0 || turnIndex >= dialogue.size()) {
    println("[JSON ERROR] turnIndex 超出範圍: " + turnIndex);
    return;
  }

  JSONObject turnObj = dialogue.getJSONObject(turnIndex);
  String aiResponse = turnObj.getString("ai_response", "");
  String aiSays = extractAISays(aiResponse);
  String code = mapChineseSentenceToCode(aiSays);

  println("==================================================");
  println("[PLAY TURN " + (turnIndex + 1) + "]");
  println("AI says = " + aiSays);
  println("CODE    = " + code);
  println("==================================================");

  fireMorseText(code);

  currentAISays = aiSays;
  currentCodeText = code;
}
