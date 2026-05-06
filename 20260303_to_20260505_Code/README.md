# Dome LED Interactive Control System

使用 **Processing** 製作的 Dome LED 互動燈光控制系統。整合了 Dome 3D 模型、彩帶式 LED 路徑、節點式 LED 顯示、參數化燈光控制、摩斯密碼轉譯、麥克風互動、平面預覽、像素排列圖，以及透過 **Art-Net** 輸出到 **H807SA 控制器** 的實體 LED 控制流程。

---

## 功能總覽

- 載入 Dome 3D 模型 `dome3.obj`
- 產生彩帶式 LED 路徑 `ribbonPath`
- 支援彩帶形式與節點形式兩種 LED 顯示模式
- 支援多種燈光參數控制
- 支援單段燈光發射與個別編輯
- 支援文字 / 數字輸入轉成跑燈效果
- 支援 AI says 文字內容轉成代碼，並轉成摩斯密碼，再轉成燈光
- 支援麥克風音量觸發燈光
- 支援 3D 模型 pixel id / node id 標記
- 支援平面視圖與像素排列圖
- 支援 Art-Net 輸出至 H807SA LED 控制器
- 可用於實體 LED 裝置測試與展示

---

## 建議檔案命名與資料夾結構

建議將主程式資料夾命名為：

```text
Dome_LED_Interactive_Control_System
```

主要 `.pde` 檔案可依照功能拆成多個分頁，例如：

```text
Dome_LED_Interactive_Control_System/
├── Dome_LED_Interactive_Control_System.pde
├── aiSays.pde
├── buildSpiralsOnSphere.pde
├── callBack.pde
├── collectEdgesRecursive.pde
├── collectSpiralDotsByColumns.pde
├── computeBoundsFromEdges.pde
├── drawEdgeLabels.pde
├── drawFxHUD.pde
├── drawHoverTooltip.pde
└── data/
    ├── dome3.obj
    └── ceremony.json
```

---

## 開發環境

使用 Processing 開發，建議使用 Processing 4。

需要安裝或啟用的 Library：

```text
ControlP5
PeasyCam
Processing Sound
Processing Serial
Java Net / UDP
```

程式中使用到的 import 包含：

```java
import controlP5.*;
import peasy.*;
import java.util.*;
import processing.data.*;
import processing.sound.*;
import processing.serial.*;
import java.net.*;
```

---

## 必要檔案

請確認 `data/` 資料夾中至少包含：

| 檔案 | 用途 |
|---|---|
| `dome3.obj` | Dome 3D 模型，用於邊線、節點、彩帶路徑與視覺預覽 |
| `ceremony.json` | 文字資料，提供 AI says 內容並轉成燈光的摩斯密碼 |

---

## 系統架構

整體流程可以理解為：

```text
Dome 3D 模型
↓
建立 vertex / ribbonPath
↓
選擇 LED 顯示模式：彩帶形式或節點形式
↓
套用參數化燈光、跑燈、摩斯、麥克風、單段編輯效果
↓
3D 視覺預覽 + 平面視圖 + 像素排列圖
↓
Art-Net 封包輸出
↓
H807SA 控制器
↓
實體 LED 燈條
```

---

## 1. 主程式與整合流程

主程式負責初始化整個系統，包含模型、相機、UI、麥克風、Art-Net、摩斯密碼、子畫面與 LED 控制邏輯。

### Setup 階段

`setup()` 中會執行：

- 開啟全螢幕 P3D
- 啟動 Art-Net
- 啟動麥克風輸入
- 建立平面視圖與像素排列圖
- 載入 `dome3.obj`
- 建立 mesh node 節點序列
- 建立 edge id 清單
- 計算模型 bounding box、球心與半徑
- 建立彩帶式 LED 路徑
- 初始化摩斯密碼查表
- 建立 ControlP5 UI
- 載入 `ceremony.json`

### Draw 階段

`draw()` 中每一幀會：

- 更新跑燈狀態
- 更新單段燈光 shot
- 更新摩斯密碼播放 queue
- 更新麥克風輸入與麥克風燈效
- 根據目前 LED 模式繪製 LED
- 顯示 AI says / 轉譯代碼
- 顯示 pixel label / node label
- 繪製平面視圖與像素排列圖
- 繪製 UI
- 透過 Art-Net 傳送 LED 資料到 H807SA

---

## 2. LED 顯示模式

程式目前支援兩種 LED 排列模式：

| 模式 | 常數 | 說明 |
|---|---|---|
| Ribbon | `LAYOUT_RIBBON` | 使用彩帶式路徑 `ribbonPath` 顯示 LED |
| Vertex | `LAYOUT_VERTEX` | 使用模型節點 `orderedMeshNodes` 顯示 LED |

目前 UI 中主要使用：

```text
彩帶形式
節點形式
```

---

## 3. 彩帶式 LED 路徑

彩帶路徑是本專案的核心。程式會根據 Dome 的球心 `sphereC` 與半徑 `sphereR`，建立一條在 Dome 內部 / 表面附近旋轉上升的彩帶路徑。

主要資料結構：

```java
ArrayList<PVector> ribbonPath = new ArrayList<PVector>();
```

### 彩帶路徑特色

- 可設定螺旋圈數 `ribbonTurns`
- 可設定起點外偏移 `ribbonOutOff`
- 可設定終點內偏移 `ribbonInOff`
- 可設定高度範圍 `ribbonY0` / `ribbonY1`
- 可加入底部半徑擴張 `bottomBoost`
- 可加入出口 S 曲線
- 最後重取樣成固定 765 個 pixel
- 可套用整體旋轉與左右傾斜

### 主要函式

```java
buildSpiralsOnSphere();
prependExitLineFrom();
resampleEqualDistance();
applyRibbonWrapTransforms();
```

---

## 4. 出口 S 曲線

彩帶路徑可以在入口端加上一段 S 型出口線，讓 LED 路徑從 Dome 內部延伸到外部或地面方向。

主要參數：

| 參數 | 說明 |
|---|---|
| `addExitLine` | 是否加入出口線 |
| `exitPixels` | 出口線 LED 點數 |
| `exitLen` | 出口線向外延伸距離 |
| `exitDrop` | 出口線往下掉的距離 |
| `sAmp` | S 曲線左右擺幅 |
| `sBias` | S 曲線轉折位置 |
| `sTight` | S 曲線集中程度 |

主要使用三次貝茲曲線建立平滑路徑：

```java
bezier3(p0, p1, p2, p3, t);
```

---

## 5. 彩帶厚度與貼球面顯示

彩帶將每個中心點展開成多列 LED，形成有寬度的彩帶。

主要參數：

| 參數 | 說明 |
|---|---|
| `ribbonThicknessRows` | 彩帶厚度列數 |
| `ribbonRowSpacing` | 每列間距 |
| `attachToSphere` | 是否貼合球面方向 |
| `attachBlend` | 貼球面混合程度 |
| `keepRibbonScreenWidth` | 是否補償螢幕視覺寬度 |

主要函式：

```java
collectSpiralDotsByColumns();
drawSpiralLEDs();
```

---

## 6. 節點式 LED 模式

程式抓取 OBJ 模型的 vertex，整理成節點式 LED 序列。

流程如下：

```text
collectVerticesRecursive()
↓
addUniqueVertex()
↓
buildOrderedMeshNodes()
↓
applyManualNodeSwaps()
↓
drawMeshNodeLEDs()
```

節點排序邏輯是：

```text
先依高度分層
再依照繞球心的角度排序
最後形成 orderedMeshNodes
```

讓節點式 LED 可以沿著 Dome 結構有順序地播放跑燈、波浪或麥克風效果。

---

## 7. 亮度與燈光控制系統

亮度系統負責計算每一顆 LED 最終要多亮。

整體邏輯為：

```text
基礎亮度
× 圖樣遮罩
× 閃爍調制
× 模式覆蓋
```

主要函式：

```java
evalPointV();
evalPixelV();
evalVertexV();
evalEditableShotV();
evalMicShotV();
```

其中：

| 函式 | 用途 |
|---|---|
| `evalPointV()` | 計算任意 3D 點的基礎亮度 |
| `evalPixelV()` | 計算 `ribbonPath` 上某顆 LED 的最終亮度 |
| `evalVertexV()` | 計算節點模式下某個 vertex 的最終亮度 |
| `evalEditableShotV()` | 計算單段可編輯 shot 對 LED 的影響 |
| `evalMicShotV()` | 計算麥克風觸發燈光對 LED 的影響 |

---

## 8. 參數化燈光控制

UI 中提供多個燈光參數：

| 參數 | 說明 |
|---|---|
| `brightCount` | 亮燈顆數 |
| `darkCount` | 暗燈顆數 |
| `fadeCount` | 亮暗交界的漸層顆數 |
| `blinkSpeed` | 閃爍 / 呼吸速度 |
| `masterBrightness` | 整體亮度 |
| `moveSpeed` | 圖樣移動速度 |
| `oscAxis` | 作用軸：序列 / 左右 / 上下 |
| `oscDir` | 移動方向 |

這些參數會影響圖樣遮罩與閃爍方式。

---

## 9. 跑燈與單段燈光系統

程式支援多種沿著 index 移動的燈光模式。

### Count Run

使用輸入框輸入數字後，可以發射指定長度的亮燈段。

例如輸入：

```text
12
```

代表發射一段長度為 12 顆 LED 的跑燈。

### Editable Shot

可發射一段可個別編輯的燈光段，每一段都有自己的：

- id
- 長度
- 方向
- 漸層長度
- 閃爍速度
- 整體亮度
- 移動速度

主要函式：

```java
fireEditableShot();
updateEditableShots();
getEditableShotById();
selectNextEditableShot();
selectPrevEditableShot();
```

---

## 10. 摩斯密碼與 AI says

程式內建摩斯密碼查表，可以將英文字母與數字轉成摩斯節奏，再轉成燈光段發射。

主要流程：

```text
讀取 ceremony.json
↓
抽出 ai_response 中的【AI says】
↓
把中文句子轉成代碼縮寫
↓
將代碼轉成摩斯密碼
↓
用燈光節奏播放
```

主要函式：

```java
initMorseMap();
fireMorseText();
updateMorseQueue();
extractAISays();
mapChineseSentenceToCode();
playCeremonyTurn();
```

目前中文關鍵詞對應範例：

| 關鍵詞 | 代碼 |
|---|---|
| 旋轉 | XZ |
| 引領 | YL |
| 舞台 | WT |
| 力量 | LL |
| 無匹配 | AI |

---

## 11. 麥克風互動

程式可使用麥克風音量觸發 LED 跑動。

麥克風流程：

```text
AudioIn 收音
↓
Amplitude 分析音量
↓
平滑音量
↓
超過門檻後產生 mic shot
↓
沿目前 LED 排列模式播放
```

主要參數：

| 參數 | 說明 |
|---|---|
| `micMode` | 麥克風模式開關 |
| `micThreshold` | 音量觸發門檻 |
| `micSmooth` | 音量平滑程度 |
| `micShotLen` | 每次聲音觸發的燈段長度 |
| `micShotSpeed` | 麥克風燈段移動速度 |
| `micEmitIntervalMs` | 最短發射間隔 |

主要函式：

```java
updateMicInput();
updateMicShots();
evalMicShotV();
```

---

## 12. Art-Net / H807SA 輸出

將 Processing 中的燈效輸出到 H807SA 控制器。

預設設定：

```java
String h807IpStr = "192.168.1.10";
int artnetPort = 6454;
int testLedCount = 1200;
```

輸出方式：

```text
1200 顆實體 LED
↓
分成 8 個 Universe
↓
每個 Universe 150 顆 LED
↓
每顆 RGB = 3 channels
↓
每 Universe 使用 450 channels
```

Universe 對應：

| Universe | LED 範圍 |
|---|---|
| 0 | 0–149 |
| 1 | 150–299 |
| 2 | 300–449 |
| 3 | 450–599 |
| 4 | 600–749 |
| 5 | 750–899 |
| 6 | 900–1049 |
| 7 | 1050–1199 |

主要函式：

```java
setupArtNet();
trySendRibbonToH807();
sendRibbonToH807();
sendArtNetUniverse();
```

---

## 13. 平面視圖與像素排列圖

程式提供兩個子畫面：

### 平面視圖

將 3D Dome 上的彩帶 LED 攤平成經緯度形式。

```java
renderFlatViewRibbon();
```

### 像素排列圖

依照指定 rowStart / rowEnd，將 765 個 pixel 排成對照用的像素圖。

```java
renderPixelMapView();
```

目前像素列範圍：

```java
int[] rowStart = { 0, 69, 138, 255, 371, 488, 604, 721 };
int[] rowEnd   = { 68, 137, 254, 370, 487, 603, 720, 764 };
```

---

## 14. 操作方式

### 顯示與標籤

| 按鍵 | 功能 |
|---|---|
| `A` | 切換顯示全部 edge 或底部斜邊 |
| `L` | 顯示 / 隱藏 edge id |
| `+` / `-` | 調整 edge label 密度 |
| `K` | 顯示 / 隱藏 ribbon pixel 編號 |
| `N` | 顯示 / 隱藏 node 編號 |
| `P` | 顯示 / 隱藏 pixel 編號 |
| `V` | 顯示 / 隱藏平面視圖與像素排列圖 |

### 燈光方向與顏色

| 按鍵 | 功能 |
|---|---|
| `X` | 設定主要軸為左右 / 欄方向 |
| `Y` | 設定主要軸為上下 / 列方向 |
| `Z` | 開關第二軸疊加 |
| `G` | LED 顏色切換為綠色 |
| `W` | LED 顏色切換為白色 |

### 手動與跑燈

| 按鍵 | 功能 |
|---|---|
| `M` | 開關手動模式 |
| `O` | 對選取 pixel 開關 override |
| `C` | 清除所有 override |
| `T` | 開關單點跑燈 |
| `H` | 開關跑過保持亮 |
| `R` | 重置 hold 與 override |
| `B` | 開關 countRunMode |

### 參數與波形

| 按鍵 | 功能 |
|---|---|
| `Q` | 開關參數模式 |
| `,` / `.` | 調整 spatialness |
| `U` | 開關 autoMorph |
| `J` | 切換作用軸 |
| `I` | 反轉方向 |
| `1` | 柔和 sin 波形 |
| `2` | sharp 波形 |
| `3` | pulse 波形 |

### AI says / 摩斯密碼

| 按鍵 | 功能 |
|---|---|
| `6` | 播放 ceremony 第 1 句 |
| `7` | 播放 ceremony 第 2 句 |

### Editable Shot

| 按鍵 | 功能 |
|---|---|
| `[` | 選上一個 shot |
| `]` | 選下一個 shot |
| `\\` | 發射一個 editable shot |
| `;` | 增加選取 shot 亮度 |
| `'` | 降低選取 shot 亮度 |
| `/` | 增加選取 shot 速度 |
| `?` | 降低選取 shot 速度 |
| `{` | 減少 shot 長度 |
| `}` | 增加 shot 長度 |
| `<` | 減少 fade |
| `>` | 增加 fade |
| `:` | 增加 blinkSpeed |
| `"` | 降低 blinkSpeed |

### 麥克風

| 按鍵 | 功能 |
|---|---|
| `F` | 開關麥克風模式 |

---

## 15. ControlP5 介面

畫面左側提供主要燈光控制 UI：

- 參數模式
- 序列模式
- 反轉方向
- 彩帶形式 / 節點形式
- 亮燈顆數
- 暗燈顆數
- 漸層顆數
- 閃爍速度
- 整體亮度
- 移動速度
- 作用軸
- 螺旋圈數
- 輸入數字 / 字元
- 開始 / 重置
- 單段燈光參數
- 預設單段燈光參數
- 麥克風開關

---

## 16. 實體 LED 對應

目前程式中的虛擬彩帶路徑固定為：

```text
765 個 ribbonPath pixel
```

Art-Net 輸出設定為：

```text
1200 顆實體 LED
```

程式會將 1200 顆實體 LED 依比例映射到 765 個虛擬點：

```java
int virtualI = int(map(
  physicalI,
  0,
  testLedCount - 1,
  0,
  ribbonPath.size() - 1
));
```

因此即使模擬點數與實體 LED 數量不同，也能保持整體燈效走向一致。

---

## 17. 使用注意事項

1. 執行前請確認 `dome3.obj` 放在 `data/` 資料夾。
2. 使用 AI says / 摩斯功能時，請確認 `ceremony.json` 放在 `data/` 資料夾。
3. 若要輸出到 H807SA，請確認電腦與控制器在同一網段。
4. 如果實體燈條顏色錯位，請檢查 Art-Net 輸出中的 RGB 色序：

```java
packet[idx++] = (byte)r;
packet[idx++] = (byte)g;
packet[idx++] = (byte)b;
```

常見可能需要改成 `GRB` 或其他色序。
