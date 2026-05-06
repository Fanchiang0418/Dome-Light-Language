# Dome LED Ribbon Path FX

本程式為 Dome 結構上的「彩帶式 LED 路徑」模擬工具，使用 Processing 製作。  
主要用途是將 LED 點位沿著 Dome 球面生成一條彩帶路徑，並加入出口 S 曲線、pixel 編號顯示、點位隱藏、燈效切換與模型邊線 ID 輔助標記。

這支程式是前一版 `Dome_LED_SpiralMapping_FX.pde` 的延伸版本。  
原本的核心是球面螺旋線，這一版進一步改成以 `ribbonPath` 作為主要路徑資料，讓 LED 更接近「彩帶」形式，而不是單純一條螺旋線。

---

## 程式檔案

建議檔名：

```text
Dome_LED_RibbonPath_FX.pde
```

若要標示國科會計畫與日期，也可以命名為：

```text
NSTC_Dome_LED_RibbonPath_FX_20260506.pde
```

---

## 功能說明

此程式會讀取 `dome3.obj` 模型，並從模型中抽取所有邊線資料，建立固定的 `edge id`。  
接著程式會根據模型的 bounding box 估算 Dome 的球心與半徑，再生成一條沿著 Dome 球面與內部空間延伸的彩帶式 LED 路徑。

彩帶路徑由兩個主要部分組成：

1. **球內 / 球面螺旋路徑**  
   由下往上繞行 Dome，形成主要的 LED 彩帶軌跡。

2. **出口 S 曲線**  
   從螺旋入口延伸出一段 S 型曲線，模擬彩帶從 Dome 結構延伸到外部或地面的路徑。

程式會將彩帶路徑上的 LED 點位映射到亮度矩陣 `spiralBri[col][row]`，並透過不同燈效函式控制亮度變化。

---

## 主要功能

- 載入 Dome 3D 模型：`dome3.obj`
- 抽取模型邊線並建立固定 edge id
- 計算模型 bounding box
- 估算 Dome 球心與半徑
- 生成彩帶式 LED 路徑 `ribbonPath`
- 支援球內螺旋路徑
- 支援底部半徑擴張
- 支援出口 S 曲線
- 支援彩帶多列厚度
- 支援貼合球面方向的點位偏移
- 支援隱藏指定 pixel
- 支援顯示 / 隱藏 LED pixel 編號
- 支援多種 LED 燈效
- 支援 X 軸 / Y 軸方向切換
- 支援第二軸疊加效果
- 支援 LED 顏色切換
- 支援模型邊線 ID 標記
- 支援滑鼠 hover 與點選 edge id
- 使用 PeasyCam 控制 3D 視角

---

## 程式核心概念

### 1. 建立模型邊線資料

程式會將整個 `PShape` 模型中的線段邊抽出來，並存成 `Edge(a, b, id)`。  
每一條邊都會得到一個固定的 `edge id`，方便在畫面上標記、hover 與點選。

主要相關函式：

```java
collectEdgesRecursive(model, allEdges);
```

---

### 2. 計算 Dome 的球心與半徑

程式會根據所有邊線端點計算出模型的最小座標與最大座標，形成 bounding box。  
再使用 bounding box 估算 Dome 的球心 `sphereC` 與水平半徑 `sphereR`。

主要相關函式：

```java
computeBoundsFromEdges(allEdges);
```

這些資料會用於後續生成貼近 Dome 球面或球內空間的彩帶路徑。

---

### 3. 建立彩帶式 LED 路徑

這一版程式的主要路徑資料是：

```java
ArrayList<PVector> ribbonPath = new ArrayList<PVector>();
```

`ribbonPath` 會儲存彩帶上的每一個 LED pixel 位置。  
程式會先生成球內螺旋，再視需求加上出口 S 曲線。

主要相關函式：

```java
buildSpiralsOnSphere();
prependExitLineFrom(ribbonPath.get(0));
```

---

### 4. 球內螺旋路徑

球內螺旋會沿著 Dome 高度由下往上繞行。  
每個點會根據高度、半徑、角度與內外偏移量計算出 3D 座標。

重要參數：

| 參數 | 說明 |
|---|---|
| `ribbonTurns` | 彩帶螺旋環繞圈數 |
| `ribbonOutOff` | 起點相對球面的外偏移 |
| `ribbonInOff` | 終點相對球面的內偏移 |
| `ribbonY0` | 彩帶開始高度比例 |
| `ribbonY1` | 彩帶結束高度比例 |
| `entranceAng` | 彩帶入口角度 |
| `bottomBoost` | 底部半徑額外擴張量 |
| `bottomSpan` | 底部擴張影響高度範圍 |
| `bottomPow` | 底部擴張集中程度 |

---

### 5. 出口 S 曲線

出口 S 曲線會從彩帶螺旋的入口端延伸出去，形成一段較自然的外部延伸路徑。  
程式使用 Bezier 曲線與等距重取樣，讓出口線段的 pixel 間距更平均。

主要相關函式：

```java
prependExitLineFrom(PVector start);
bezier3();
resampleEqualDistance();
removeTooClose();
```

重要參數：

| 參數 | 說明 |
|---|---|
| `addExitLine` | 是否加入出口線 |
| `exitPixels` | 出口線段 LED 點數 |
| `exitLen` | 出口線向外延伸距離 |
| `exitDrop` | 出口線下降量 |
| `exitAngOff` | 出口線水平轉向 |
| `sAmp` | S 曲線左右擺幅 |
| `sBias` | S 曲線轉折位置 |
| `sTight` | S 曲線集中程度 |
| `bendRadius` | 圓角轉彎半徑 |
| `bendPortion` | 圓角轉彎佔比 |

---

### 6. 彩帶厚度與貼球面方向

這一版程式不是只畫單點線，而是可以將路徑加厚成多列彩帶。  
每個路徑點會沿著計算出的偏移方向複製成多列，形成「有寬度」的 LED 彩帶。

重要參數：

| 參數 | 說明 |
|---|---|
| `ribbonThicknessRows` | 彩帶厚度列數 |
| `ribbonRowSpacing` | 每列之間的間距 |
| `attachToSphere` | 是否讓彩帶厚度方向貼合球面 |
| `attachBlend` | 原本方向與球面方向的混合比例 |
| `attachRadiusFactor` | 判斷是否貼近球面的範圍 |

主要相關函式：

```java
collectSpiralDotsByColumns();
sampleSpiralBri();
```

---

### 7. LED pixel 編號與隱藏功能

程式支援在畫面上顯示 `ribbonPath` 中每個 pixel 的 index，方便定位要調整或隱藏的點位。

主要相關變數：

```java
boolean showPixelLabels = true;
HashSet<Integer> hiddenPixels = new HashSet<Integer>();
```

可用於隱藏不需要顯示的 pixel，例如接點重疊、穿模、或不希望出現在畫面中的 LED 點。

主要相關函式：

```java
drawRibbonPixelLabels();
findNearestRibbonPixel();
```

---

## 燈光效果模式

使用 `N` / `P` 鍵可切換不同燈效模式。

| 模式名稱 | 說明 |
|---|---|
| `Cw` | 順時針掃光 |
| `Ccw` | 逆時針掃光 |
| `Calm` | 平靜呼吸燈 |
| `Sparkle` | 星點閃爍 |
| `Wave` | 波浪流動 |
| `Lookup` | 從下往上或依指定軸向亮起 |
| `Broken` | 破碎式隨機啟動 |
| `Wake` | 逐步甦醒 |
| `Joy` | 開心、跳動、節奏感燈效 |
| `Expand` | 從中心向外擴張 |
| `FullOn` | 全亮模式 |

主要相關函式：

```java
updateSpiralFX();
```

---

## 操作方式

| 按鍵 / 操作 | 功能 |
|---|---|
| 滑鼠拖曳 | 旋轉 3D 視角 |
| 滑鼠滾輪 | 縮放視角 |
| 滑鼠 hover | 顯示靠近的 edge id |
| 滑鼠點擊 | 在 console 印出選取的 edge id |
| `A` | 切換顯示全部邊線 / 底部斜邊 |
| `L` | 顯示或隱藏邊線標籤 |
| `+` / `-` | 調整邊線標籤顯示密度 |
| `N` | 切換到下一個燈效 |
| `P` | 切換到上一個燈效 |
| `X` | 將燈效方向切換為 X 軸 / 欄方向 |
| `Y` | 將燈效方向切換為 Y 軸 / 高度方向 |
| `Z` | 開啟或關閉第二軸疊加 |
| `G` | 將 LED 顏色切換為綠色 |
| `W` | 將 LED 顏色切換為白色 |
| `S` | 切換螺旋全亮 / 流動模式 |
| `K` | 顯示或隱藏 LED pixel 編號 |

---

## 重要參數整理

### 路徑與模型

| 參數 | 說明 |
|---|---|
| `modelPos` | 模型位置 |
| `modelRotX` | 模型 X 軸旋轉 |
| `modelRotY` | 模型 Y 軸旋轉 |
| `modelScale` | 模型縮放 |
| `modelSpinSpeed` | 模型自轉速度 |
| `sphereC` | 估算球心 |
| `sphereR` | 估算球半徑 |

### 彩帶路徑

| 參數 | 說明 |
|---|---|
| `spiralPixels` | 彩帶主路徑上的點數 |
| `ribbonTurns` | 彩帶螺旋圈數 |
| `ribbonOutOff` | 起點外偏移 |
| `ribbonInOff` | 終點內偏移 |
| `ribbonY0` | 起始高度 |
| `ribbonY1` | 結束高度 |
| `bottomBoost` | 底部擴張量 |

### 彩帶厚度

| 參數 | 說明 |
|---|---|
| `ribbonThicknessRows` | 彩帶厚度列數 |
| `ribbonRowSpacing` | 彩帶列間距 |
| `attachToSphere` | 是否貼合球面 |
| `attachBlend` | 貼球面混合比例 |

### 燈效控制

| 參數 | 說明 |
|---|---|
| `spiralCols` | 控制矩陣欄數 |
| `spiralRows` | 控制矩陣列數 |
| `primaryAxis` | 主要燈效方向 |
| `secondaryAxis` | 第二燈效方向 |
| `useSecondary` | 是否疊加第二軸 |
| `fxMode` | 目前燈效模式 |
| `ledR`, `ledG`, `ledB` | LED 顏色倍率 |

---

## 使用情境

這支程式適合用於 Dome 裝置中「彩帶式 LED」的視覺模擬與燈效測試。  
相較於單純的螺旋線，它更適合描述具有寬度、厚度、入口出口方向與特殊延伸路徑的 LED 造型。

可應用於：

- Dome 彩帶式 LED 路徑設計
- 球面 / 球內 LED 走線模擬
- 出口 S 曲線 LED 規劃
- LED pixel 編號與定位
- 隱藏或修正特定 pixel
- 燈效方向與節奏測試
- 實體施工前的視覺預覽
- 與老師、學弟妹或廠商溝通燈光邏輯

---

## 建議資料夾結構

```text
Dome_LED_RibbonPath_FX/
├── README.md
├── Dome_LED_RibbonPath_FX.pde
└── data/
    └── dome3.obj
```

---

## 開發環境

- Processing
- P3D renderer
- PeasyCam library
- OBJ 3D model：`dome3.obj`

---

## 備註

此程式目前主要作為 Dome 彩帶式 LED 路徑的模擬與視覺測試工具。  
後續若要串接實體 LED 硬體，可將 `ribbonPath` 中的 pixel index 與實際 LED 編號對應，再將 `spiralBri[col][row]` 的亮度資料轉換為實體燈條控制訊號。

可進一步串接：

- Arduino
- ESP32
- DMX
- Art-Net
- WLED
- 其他 addressable RGB LED 控制系統
