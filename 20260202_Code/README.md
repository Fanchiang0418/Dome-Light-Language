# Dome LED Light Simulation

本專案為 Dome 結構燈光模擬與 LED 控制邏輯測試工具，使用 Processing 製作。  
主要用於國科會計畫中，測試 Dome 結構上的 LED 燈條配置、燈光排列方式、燈光動畫語言、球面螺旋燈條效果，以及模型邊線與 LED 點位的對應關係。

本專案目前包含三支主要程式：

1. `Dome_LED_EdgeMapping.pde`  
   用於讀取 Dome 3D 模型、顯示模型邊線 ID，並將 LED 點位對應到指定模型邊線上。

2. `Dome_LED_LightingSimulation_BGModel.pde`  
   用於模擬不同燈光排列形式、燈光動畫效果，以及將背景 Dome 模型與燈光位置進行視覺對位。

3. `Dome_LED_SpiralMapping_FX.pde`  
   用於在 Dome 球面上建立螺旋 LED 點位，並測試多種球面螺旋燈光效果。

---

## 1. Dome_LED_EdgeMapping.pde

### 功能說明

此程式主要用於建立 Dome 模型邊線與 LED 燈點之間的對應關係。  
透過讀取 `dome2.obj` 模型，程式會將模型中的邊線整理成 `allEdges` 清單，並為每條邊線建立固定的 `edge id`。使用者可以透過畫面上的標籤、滑鼠 hover 或點選方式，確認每條模型邊線的編號。

完成邊線編號確認後，可以將需要放置 LED 的邊線 ID 填入 `ledEdgeIdx` 陣列中，程式便會依照指定的邊線位置繪製 LED 點位。

### 主要功能

- 載入 Dome 3D 模型：`dome2.obj`
- 建立模型所有邊線資料：`allEdges`
- 顯示模型邊線 ID
- 支援滑鼠 hover 顯示目前邊線 ID
- 支援滑鼠點選輸出邊線 ID
- 可指定 LED 對應的模型邊線
- 將每條 LED 邊線切分成多個 segment
- 可模擬 LED 亮度變化
- 使用 PeasyCam 進行 3D 視角旋轉與縮放

### 操作方式

| 按鍵 / 操作 | 功能 |
|---|---|
| 滑鼠拖曳 | 旋轉 3D 視角 |
| 滑鼠滾輪 | 縮放視角 |
| 滑鼠 hover | 顯示目前靠近的 edge id |
| 滑鼠點擊 | 在 console 印出選取的 edge id |
| `A` | 切換顯示全部邊線 / 底部斜邊 |
| `L` | 顯示或隱藏邊線標籤 |
| `+` / `-` | 調整標籤顯示密度 |

### 使用情境

這支程式適合用於實際製作前的 LED 位置確認。  
當需要把 LED 燈條安裝在 Dome 結構的特定邊線上時，可以先透過此程式確認模型中的邊線 ID，再將這些 ID 整理成 LED 對應清單，方便後續進行燈光控制與施工溝通。

---

## 2. Dome_LED_LightingSimulation_BGModel.pde

### 功能說明

此程式主要用於模擬 Dome 裝置中的 LED 燈光排列與動畫效果。  
程式提供多種燈光排列方式，例如一字排、圓弧、外傾圓弧、貝茲曲線、放射狀排列與圓環排列等。使用者可以透過鍵盤切換不同排列模式，也可以輸入關鍵字切換不同燈光語言。

程式同時支援載入背景 Dome 模型，方便將燈光模擬結果與實際 Dome 結構進行視覺對位。

### 主要功能

- 載入背景 Dome 模型：`dome2.obj`
- 支援背景模型平移、旋轉、縮放
- 支援背景模型顯示 / 隱藏
- 模擬多種 LED 燈條排列方式
- 模擬多種燈光動畫語言
- 支援滑鼠控制 3D 視角
- 支援文字輸入切換燈光效果
- 可作為提案、展示或施工前配置測試工具

### 燈光排列模式

| 按鍵 | 模式名稱 | 說明 |
|---|---|---|
| `1` | Parallel | 一字排排列 |
| `2` | Ring | 240° 直立圓弧排列 |
| `3` | Radiation | 240° 外傾放射排列 |
| `4` | Same_side | 240° 括號形貝茲弧線 |
| `5` | Center | 沿半徑方向內 / 外開的貝茲曲線 |
| `6` | Outward | 沿半徑方向外開的貝茲曲線 |
| `7` | Vertical_circle | 每根燈條形成垂直圓環 |

### 燈光語言模式

可在畫面左上角輸入關鍵字後按 Enter 切換效果。

| 中文關鍵字 | 英文關鍵字 | 效果說明 |
|---|---|---|
| 平靜 | calm | 整體緩慢呼吸 |
| 波浪 | wave | 沿燈條產生流動波浪 |
| 緊張 | tense | 隨機閃爍與跳動 |
| 擴張 | expand | 從中心向外擴散 |
| 風 | wind | 像風吹過的亮度掃動 |
| 自由 | freedom / free | 類似粒子自由漂移 |
| 追尋 | seek / search | 一束光來回掃描 |
| 順時針 | clockwise / cw | 光點順時針移動 |
| 逆時針 | counterclockwise / ccw | 光點逆時針移動 |
| 仰望 | lookup / up | 從下往上亮起 |
| 俯視 / 俯瞰 | lookdown / down | 從上往下亮起 |
| 甦醒 / 萌發 | wake / spark / init | 燈條逐一亮起 |
| 破碎 | broken | 隨機啟動並產生破碎感 |

### 背景模型操作

| 按鍵 | 功能 |
|---|---|
| `M` | 顯示 / 隱藏背景模型 |
| `J` / `L` | 背景模型左右移動 |
| `I` / `K` | 背景模型上下移動 |
| `U` / `O` | 背景模型前後移動 |
| `[` / `]` | 縮小 / 放大背景模型 |
| `R` / `T` | 背景模型左右旋轉 |
| `W` / `S` | 快速調整背景模型遠近 |

### 相機操作

| 操作 | 功能 |
|---|---|
| 滑鼠拖曳 | 旋轉視角 |
| 滑鼠滾輪 | 縮放視角 |
| 方向鍵 | 微調視角角度 |

---

## 3. Dome_LED_SpiralMapping_FX.pde

### 功能說明

此程式主要用於模擬 Dome 結構上的「球面螺旋 LED 燈條」。  
程式會先讀取 `dome2.obj` 模型，計算模型的邊界範圍與近似球心，再根據球體高度與半徑，在 Dome 表面生成一條貼合球面的螺旋線。

這條螺旋線會被切分成多個 LED pixel 點，並透過欄列矩陣 `spiralBri[col][row]` 控制每個區域的亮度。  
使用者可以切換不同燈光效果，也可以透過鍵盤切換燈效方向、顏色、顯示模式與邊線標籤。

此程式同時保留模型邊線 ID 標記功能，方便在 Dome 結構上確認實際 LED 安裝位置。

### 主要功能

- 載入 Dome 3D 模型：`dome2.obj`
- 計算模型 bounding box
- 估算 Dome 球心與球面半徑
- 在球面上生成螺旋 LED 點位
- 將螺旋點位映射成欄列亮度矩陣
- 支援多種螺旋燈效模式
- 支援 X 軸 / Y 軸方向切換
- 支援第二軸疊加效果
- 支援 LED 顏色切換
- 支援模型邊線 ID 標記
- 支援滑鼠 hover 與點選 edge id
- 使用 PeasyCam 控制 3D 視角

### 程式核心概念

#### 1. 球面螺旋點位生成

程式會先根據模型邊界計算出 Dome 的近似球心 `sphereC` 與半徑 `sphereR`，接著沿著高度方向從下到上取樣多個點。

每個高度會對應到球面上的一個圓周半徑，再根據螺旋圈數 `spiralTurns` 計算角度，最後產生貼合球面的 3D 螺旋點位。

主要相關函式：

```java
computeBoundsFromEdges(allEdges);
buildSpiralsOnSphere();
```

#### 2. 螺旋 LED 矩陣控制

雖然螺旋線本身是一條連續的 3D 曲線，但程式會將它轉換成類似 LED Matrix 的控制方式：

```java
float[][] spiralBri = new float[spiralCols][spiralRows];
```

其中：

| 變數 | 說明 |
|---|---|
| `spiralCols` | 螺旋在水平方向分成幾欄 |
| `spiralRows` | 螺旋在高度方向分成幾段 |
| `spiralBri[col][row]` | 每一格 LED 區域的亮度 |

這樣可以讓燈效用「欄」與「列」的方式控制，方便設計順時針、上下流動、擴散、星點等動畫。

#### 3. 螺旋點位繪製

程式會把螺旋上的每個 3D 點投影到螢幕座標，再用 HUD 方式繪製成 2D 發光圓點。

主要相關函式：

```java
drawSpiralLEDs();
collectSpiralDotsByColumns();
sampleSpiralBri();
```

這種做法可以讓 LED 點在畫面上保持清楚可見，不會因為 3D 模型深度遮擋而消失。

### 燈光效果模式

使用 `N` / `P` 鍵可切換不同燈效模式。

| 模式名稱 | 說明 |
|---|---|
| `Cw` | 順時針掃光 |
| `Ccw` | 逆時針掃光 |
| `Calm` | 平靜呼吸燈 |
| `Sparkle` | 星點閃爍 |
| `Wave` | 波浪流動 |
| `Lookup` | 從下往上亮起 |
| `Broken` | 破碎式隨機啟動 |
| `Wake` | 逐步甦醒 |
| `Joy` | 開心、跳動、節奏感燈效 |
| `Expand` | 從中心向外擴張 |
| `FullOn` | 全亮模式 |

### 操作方式

| 按鍵 / 操作 | 功能 |
|---|---|
| 滑鼠拖曳 | 旋轉 3D 視角 |
| 滑鼠滾輪 | 縮放視角 |
| 滑鼠 hover | 顯示靠近的 edge id |
| 滑鼠點擊 | 在 console 印出選取的 edge id |
| `A` | 切換顯示全部邊線 / 底部斜邊 |
| `L` | 顯示或隱藏邊線標籤 |
| `+` / `-` | 調整標籤顯示密度 |
| `N` | 切換到下一個燈效 |
| `P` | 切換到上一個燈效 |
| `X` | 將燈效方向切換為 X 軸 / 欄方向 |
| `Y` | 將燈效方向切換為 Y 軸 / 高度方向 |
| `Z` | 開啟或關閉第二軸疊加 |
| `G` | 將 LED 顏色切換為綠色 |
| `W` | 將 LED 顏色切換為白色 |
| `S` | 切換螺旋全亮 / 流動模式 |

### 重要參數

| 參數 | 說明 |
|---|---|
| `spiralPixels` | 一條螺旋上的 LED 點數，數值越大越密 |
| `spiralTurns` | 螺旋從底到頂繞幾圈 |
| `spiralSpeed` | 螺旋燈效流動速度 |
| `spiralSigma` | 亮點拖尾寬度 |
| `spiralBase` | 背景基礎亮度 |
| `spiralPeak` | 亮點最高亮度 |
| `spiralY0` | 螺旋起始高度比例 |
| `spiralY1` | 螺旋結束高度比例 |
| `spiralCols` | 螺旋控制矩陣的欄數 |
| `spiralRows` | 螺旋控制矩陣的列數 |
| `ledR`, `ledG`, `ledB` | LED 顏色倍率 |

### 使用情境

這支程式適合用於 Dome 裝置中「螺旋燈條」的視覺測試與燈效設計。  
當實體 Dome 上的燈條不是單純直線排列，而是沿著球面或半球面旋轉上升時，可以使用此程式模擬燈光如何在曲面上流動。

可應用於：

- Dome 球面螺旋燈條配置測試
- LED pixel 密度與螺旋圈數評估
- 燈效方向測試
- 燈光語言設計
- 實體施工前的視覺預覽
- 與老師、學弟妹或廠商溝通燈光邏輯

---

## 專案用途

本專案主要用於 Dome 燈光裝置的前期設計與測試，包含：

- LED 燈條數量與位置規劃
- Dome 模型與燈光點位對位
- Dome 球面螺旋燈條配置測試
- 燈光動畫語言測試
- 給老師、團隊或廠商理解燈光配置方式
- 後續硬體控制與實際施工前的模擬參考

---

## 硬體需求概念

後續若要將模擬結果轉換為實體燈光裝置，LED 硬體建議支援：

- 360 度全向發光
- RGB 全彩控制
- 單點控制 / 逐點控制
- 每顆 LED 可獨立設定顏色與亮度

---

## 檔案建議命名

建議使用以下命名方式：

```text
Dome_LED_EdgeMapping.pde
Dome_LED_LightingSimulation_BGModel.pde
Dome_LED_SpiralMapping_FX.pde
```

若要加入計畫名稱與日期，也可以使用：

```text
NSTC_Dome_LED_EdgeMapping_20260506.pde
NSTC_Dome_LED_LightingSimulation_BGModel_20260506.pde
NSTC_Dome_LED_SpiralMapping_FX_20260506.pde
```

---

## 建議資料夾結構

```text
Dome_LED_Project/
├── README.md
├── Dome_LED_EdgeMapping/
│   ├── Dome_LED_EdgeMapping.pde
│   └── data/
│       └── dome2.obj
├── Dome_LED_LightingSimulation_BGModel/
│   ├── Dome_LED_LightingSimulation_BGModel.pde
│   └── data/
│       └── dome2.obj
├── Dome_LED_SpiralMapping_FX/
│   ├── Dome_LED_SpiralMapping_FX.pde
│   └── data/
│       └── dome2.obj
```

---

## 開發環境

- Processing
- P3D renderer
- PeasyCam library
- OBJ 3D model：`dome2.obj`

---

## 備註

此專案目前仍屬於模擬與測試階段，主要目標是建立 Dome 結構、LED 點位、燈光排列方式、球面螺旋燈條與動畫語言之間的關係。

後續若要串接實體 LED 硬體，可將 `brightness[i][s]` 或 `spiralBri[col][row]` 的亮度資料轉換為實際 LED index，再輸出至 Arduino、ESP32、DMX、Art-Net 或其他 LED 控制系統。
