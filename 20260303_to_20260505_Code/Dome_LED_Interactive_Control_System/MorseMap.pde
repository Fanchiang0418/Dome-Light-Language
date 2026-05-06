//摩斯密碼查表

HashMap<Character, String> morseMap = new HashMap<Character, String>(); // 字元 → 摩斯密碼的對照表
ArrayList<Integer> morseQueue = new ArrayList<Integer>(); // 存放接下來要播放的摩斯節奏內容
int morseNextFrame = 0; // 記錄下一次什麼時候可以播放 queue 裡的下一個項目

// 1 個時間單位 = 幾幀
int morseUnitFrames = 2;   // 定義摩斯密碼的 1 個時間單位等於幾幀
boolean morsePlaying = false; // 摩斯碼是否正在播放

// queue 裡的特殊值
//. 和 . 中間的間隔 → MORSE_GAP
//S 和 O 中間的間隔 → MORSE_LETTER_GAP

final int MORSE_GAP = 0;        // 符號間隔 (短停頓)
final int MORSE_LETTER_GAP = -1; // 字母間隔 (中停頓)
final int MORSE_WORD_GAP = -2;   // 單字間隔 (長停頓)

// 初始化摩斯密碼查表內容
void initMorseMap() {
  morseMap.put('A', ".-");
  morseMap.put('B', "-...");
  morseMap.put('C', "-.-.");
  morseMap.put('D', "-..");
  morseMap.put('E', ".");
  morseMap.put('F', "..-.");
  morseMap.put('G', "--.");
  morseMap.put('H', "....");
  morseMap.put('I', "..");
  morseMap.put('J', ".---");
  morseMap.put('K', "-.-");
  morseMap.put('L', ".-..");
  morseMap.put('M', "--");
  morseMap.put('N', "-.");
  morseMap.put('O', "---");
  morseMap.put('P', ".--.");
  morseMap.put('Q', "--.-");
  morseMap.put('R', ".-.");
  morseMap.put('S', "...");
  morseMap.put('T', "-");
  morseMap.put('U', "..-");
  morseMap.put('V', "...-");
  morseMap.put('W', ".--");
  morseMap.put('X', "-..-");
  morseMap.put('Y', "-.--");
  morseMap.put('Z', "--..");

  morseMap.put('0', "-----");
  morseMap.put('1', ".----");
  morseMap.put('2', "..---");
  morseMap.put('3', "...--");
  morseMap.put('4', "....-");
  morseMap.put('5', ".....");
  morseMap.put('6', "-....");
  morseMap.put('7', "--...");
  morseMap.put('8', "---..");
  morseMap.put('9', "----.");
}

// 把單一字元轉成摩斯碼，並加入播放佇列 morseQueue
void fireMorseChar(char ch) {
  ch = Character.toUpperCase(ch);

  if (!morseMap.containsKey(ch)) {
    println("No morse mapping for:", ch);
    return;
  }

  String code = morseMap.get(ch);
  println("[MORSE OK] char =", ch, " code =", code);

  for (int i = 0; i < code.length(); i++) {
    char sym = code.charAt(i);

    if (sym == '.') {
      println("  symbol . -> queue DOT");
      morseQueue.add(1);   // dot = 1 顆
    } else if (sym == '-') {
      println("  symbol - -> queue DASH");
      morseQueue.add(2);   // dash = 3 顆
    }

    // 符號與符號之間，加入短間隔（但最後一個符號後面不要加）
    if (i < code.length() - 1) {
      morseQueue.add(MORSE_GAP);
    }
  }
}

// 把整段文字轉成完整摩斯播放佇列，並開始播放
void fireMorseText(String text) {
  if (text == null) return;

  text = trim(text).toUpperCase();

  morseQueue.clear();

  for (int i = 0; i < text.length(); i++) {
    char ch = text.charAt(i);

    if (ch == ' ') {
      // 單字間隔
      morseQueue.add(MORSE_WORD_GAP);
      continue;
    }

    fireMorseChar(ch);

    // 如果下一個不是空白、也不是字串結尾，就加字母間隔
    if (i < text.length() - 1 && text.charAt(i + 1) != ' ') {
      morseQueue.add(MORSE_LETTER_GAP);
    }
  }

  morsePlaying = true;
  morseNextFrame = frameCount;

  println("[MORSE TEXT QUEUED] size =", morseQueue.size());
}

// 每幀檢查現在是否到了播放下一個摩斯事件的時間，若到了就從 queue 取出一項執行
void updateMorseQueue() {
  if (!morsePlaying) return;

  if (morseQueue == null || morseQueue.size() == 0) {
    morsePlaying = false;
    println("[MORSE DONE]");
    return;
  }

  if (frameCount < morseNextFrame) return;

  int item = morseQueue.remove(0);

  if (item > 0) {
    fireCountRunShot(item);
    println("[MORSE FIRE] len =", item);

    if (item == 1) {
      morseNextFrame = frameCount + 2;   // dot
    } else if (item == 2) {
      morseNextFrame = frameCount + 2;   // dash
    }
  } else if (item == MORSE_GAP) {
    // 符號間隔：1 單位
    println("[MORSE GAP] symbol gap");
    morseNextFrame = frameCount + 1 * morseUnitFrames;
  } else if (item == MORSE_LETTER_GAP) {
    // 字母間隔：3 單位
    println("[MORSE GAP] letter gap");
    morseNextFrame = frameCount + 3 * morseUnitFrames + 1;
  } else if (item == MORSE_WORD_GAP) {
    // 單字間隔：7 單位
    println("[MORSE GAP] word gap");
    morseNextFrame = frameCount + 7 * morseUnitFrames;
  }
}
