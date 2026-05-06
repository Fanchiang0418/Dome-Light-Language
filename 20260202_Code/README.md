# Dome LED Spiral Mapping FX

Dome 結構上的「球面螺旋 LED 燈條」模擬工具，使用 Processing 製作。  
主要用途是將 LED 點位沿著 Dome 球面生成螺旋路徑，並透過亮度矩陣控制不同的燈光效果。

---

## 主程式檔案

```text
Dome_LED_SpiralMapping_FX.pde
```

---

## 功能說明

此程式會讀取 `dome2.obj` 模型，並根據模型的邊界範圍估算出 Dome 的球心與半徑。  
接著程式會沿著 Dome 的高度方向，由下往上產生一條貼合球面的螺旋線，並將螺旋線切分成多個 LED pixel 點。

這些螺旋 LED 點位會被映射到一個欄列亮度矩陣中：

```java
float[][] spiralBri = new float[spiralCols][spiralRows];
```

透過這個矩陣，可以設計不同方向、不同節奏、不同情緒的燈光效果，例如順時針流動、逆時針流動、呼吸、波浪、星點閃爍、甦醒、破碎、全亮等。

---

## 主要功能

- 載入 Dome 3D 模型：`dome2.obj`
- 計算模型 bounding box
- 估算 Dome 球心與球面半徑
- 在 Dome 球面上生成螺旋 LED 點位
- 將螺旋點位映射成欄列亮度矩陣
- 支援多種螺旋燈光效果
- 支援 X 軸 / Y 軸方向切換
- 支援第二軸疊加效果
- 支援 LED 顏色切換
- 支援模型邊線 ID 標記
- 支援滑鼠 hover 顯示 edge id
- 支援滑鼠點選 edge id
- 使用 PeasyCam 控制 3D 視角

---

## 程式核心概念

### 1. 建立模型邊線資料

程式會先將 `PShape` 模型中的邊線全部抽出來，並存成 `Edge(a, b, id)`。  
每一條邊都會得到一個固定的 `edge id`，方便後續標記與點選。

主要相關函式：

```java
collectEdgesRecursive(model, allEdges);
```

---

### 2. 計算 Dome 的球心與半徑

程式會根據所有邊線的端點，計算出模型的最小座標與最大座標，也就是 bounding box。  
再透過 bounding box 估算 Dome 的球心 `sphereC` 與半徑 `sphereR`。

主要相關函式：

```java
computeBoundsFromEdges(allEdges);
```

---

### 3. 生成球面螺旋 LED 點位

程式會沿著高度方向從下到上取樣，並讓每個高度對應到球面上的圓周半徑。  
再根據螺旋圈數 `spiralTurns` 計算角度，產生貼合球面的 3D 螺旋點位。

主要相關函式：

```java
buildSpiralsOnSphere();
```

重要參數：

| 參數 | 說明 |
|---|---|
| `spiralPixels` | 螺旋上的 LED 點數，數值越大越密 |
| `spiralTurns` | 螺旋從底到頂繞幾圈 |
| `spiralY0` | 螺旋起始高度比例 |
| `spiralY1` | 螺旋結束高度比例 |

---

### 4. 將螺旋點位映射到亮度矩陣

螺旋線本身是一條連續的 3D 曲線，但程式會把它轉換成類似 LED Matrix 的控制方式。

```java
float[][] spiralBri = new float[spiralCols][spiralRows];
```

其中：

| 變數 | 說明 |
|---|---|
| `spiralCols` | 螺旋在水平方向分成幾欄 |
| `spiralRows` | 螺旋在高度方向分成幾段 |
| `spiralBri[col][row]` | 每一格 LED 區域的亮度 |

這樣可以用欄與列的方式設計燈效，例如左右掃光、上下掃光、中央擴張、逐層甦醒等。

主要相關函式：

```java
collectSpiralDotsByColumns();
sampleSpiralBri();
```

---

### 5. 繪製螺旋 LED

程式會把螺旋上的每個 3D 點轉換成螢幕座標，並使用 HUD 的方式畫出發光圓點。  
這樣可以讓 LED 點在畫面上保持清楚，不會因為 3D 深度遮擋而消失。

主要相關函式：

```java
drawSpiralLEDs();
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
| `Lookup` | 從下往上亮起 |
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
| `+` / `-` | 調整標籤顯示密度 |
| `N` | 切換到下一個燈效 |
| `P` | 切換到上一個燈效 |
| `X` | 將燈效方向切換為 X 軸 / 欄方向 |
| `Y` | 將燈效方向切換為 Y 軸 / 高度方向 |
| `Z` | 開啟或關閉第二軸疊加 |
| `G` | 將 LED 顏色切換為綠色 |
| `W` | 將 LED 顏色切換為白色 |
| `S` | 切換螺旋全亮 / 流動模式 |

---

## 重要參數

| 參數 | 說明 |
|---|---|
| `spiralPixels` | 一條螺旋上的 LED 點數 |
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

---

## 開發環境

- Processing
- P3D renderer
- PeasyCam library
- OBJ 3D model：`dome2.obj`
