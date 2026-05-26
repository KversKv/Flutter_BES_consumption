---

# 1. 单周期 BT sniffing 的正确波形结构

单个 sniff 周期的电流波形应抽象为：

```text
Sleep
→ Wake-up
→ Clock/RF settle
→ Clock drift guard
→ Main RX
→ RX/TX turnaround
→ TX
→ Extra RXmin × (Attempt - 1)
→ Processing / sleep entry
→ Sleep
```

也就是：

```text
|<---------------------------- Connect Interval ---------------------------->|

Sleep → Wake → Settle → Guard → Main RX → TX → RXmin × (Attempt-1) → Sleep
```

电流波形示意：

```text
I
^
|                                ┌──────────── TX packet ────────────┐
|                                │                                    │  I_tx(BT power)
|                 ┌──────────────┘                                    └──┐
|                 │ Main RX packet                                        │ ┌─┐ ┌─┐
|                 │                                                        │ │ │ │ │  RXmin × (Attempt-1)
|        ┌────────┘                                                        └─┘ └─┘
|        │ Wake / settle / guard
|________│____________________________________________________________________________
| Sleep                                                                       Sleep
+-----------------------------------------------------------------------------------> t
```

---

# 2. 参数与波形影响总表

| 参数 | 主要影响的波形区域     | 改变时间宽度？ | 改变电流高度？ | 正确影响逻辑                                              |
| ------ | ------------------------ | ---------------: | ---------------: | ----------------------------------------------------------- |
| **BT power**     | TX packet              |             否 |             是 | 决定 TX 电流高度，power 越高，TX 峰值越高                 |
| **Connect Interval**     | 整个周期、Sleep、Guard |             是 |             否 | 周期变长，sleep 通常变长；同时 clock drift guard 可能变长 |
| **Attempt**     | TX 后的 Extra RXmin    |             是 |             否 | `Attempt=N` 时，TX 后额外 RXmin 数量为 `N-1`                              |
| **Clock drift**     | Main RX 前的 guard     |             是 |             否 | drift 越大，提前醒来的 guard 越宽                         |
| **RX Payload**     | Main RX packet         |             是 |             否 | RX payload 越大，Main RX 持续时间越长                     |
| **TX Payload**     | TX packet              |             是 |             否 | TX payload 越大，TX packet 持续时间越长                   |
| **Packet type**     | Main RX、TX            |             是 |           可能 | 决定 RX/TX slot 数、速率、FEC、payload 上限和空中时间     |

---

# 3. 各参数对电流波形的具体影响

---

## 3.1 BT power

### 影响位置

```text
TX packet
```

### 影响方式

BT power 直接影响 TX 阶段的电流高度：

\[
I_{tx}=I_{tx}(BTpower)
\]

TX 能量为：

\[
E_{tx}
=
V \cdot I_{tx}(BTpower) \cdot T_{tx}
\]

### 波形变化

BT power 增大时：

```text
TX 电流平台变高，但 TX 持续时间不变。
```

示意：

```text
低 BT power:

Main RX ─────┐
             └── TX ──┐
                       └── RXmin...


高 BT power:

Main RX ─────┐
             └── TX ──┐
                 │    │
                 │    │
                 └────┘
                       └── RXmin...
```

### 结论

| 项目           | 影响       |
| ---------------- | ------------ |
| TX 电流高度    | 增大       |
| TX 持续时间    | 不直接改变 |
| Main RX        | 不直接改变 |
| RXmin          | 不直接改变 |
| 单周期峰值电流 | 增大       |
| 单周期 TX 能量 | 增大       |

---

## 3.2 Connect Interval

### 影响位置

```text
整个 sniff 周期、sleep 时间、clock drift guard
```

### 基本关系

\[
T_{cycle}=T_{CI}
\]

其中：

\[
T_{CI}=\text{Connect Interval}
\]

Sleep 时间：

\[
T_{sleep}=T_{CI}-T_{active}
\]

Connect Interval 增大时，通常表现为：

```text
active burst 形状基本不变，但 sleep 区域变长。
```

示意：

```text
短 CI:

|<------ CI ------>|
Sleep → RX → TX → RXmin → Sleep


长 CI:

|<--------------------------- CI --------------------------->|
Sleep........ → RX → TX → RXmin → ....................Sleep
```

### 与 Clock drift 的耦合

Connect Interval 越长，两端时钟漂移累积越大，因此 guard 可能变长：

\[
T_{guard}
=
T_{CI}
\times
\frac{ppm_{total}}{10^6}
+
T_{margin}
\]

所以 Connect Interval 有两个方向的影响：

| 路径                        | 对功耗影响                                    |
| ----------------------------- | ----------------------------------------------- |
| CI 增大 → sleep 变长       | 平均电流下降                                  |
| CI 增大 → drift guard 变长 | active 时间增加，功耗上升                     |
| 综合结果                    | 通常平均电流下降，但会被 guard 增长抵消一部分 |

---

## 3.3 Attempt

这是你修正后的关键点。

### 正确定义

\[
Attempt=N
\]

表示本周期一共有 N 次 RX 尝试，其中：

- 第 1 次是 Main RX；
- Main RX 之后有一次 TX；
- 后续为 `N-1` 次最短 RXmin；
- 这些 RXmin 不需要 TX。

所以：

\[
N_{extra\_rx}=Attempt-1
\]

### 波形位置

```text
TX 后面的 Extra RXmin
```

### 时间贡献

不考虑 RXmin 之间 gap 时：

\[
T_{attempt\_extra}
=
(Attempt-1)T_{rx\_min}
\]

考虑 gap 时：

\[
T_{attempt\_extra}
=
(Attempt-1)
\left(
T_{rx\_min}
+
T_{rx\_gap}
\right)
\]

### 波形示例

#### Attempt = 1

```text
Main RX → TX → Sleep
```

#### Attempt = 2

```text
Main RX → TX → RXmin → Sleep
```

#### Attempt = 3

```text
Main RX → TX → RXmin → RXmin → Sleep
```

#### Attempt = N

```text
Main RX → TX → RXmin × (N-1) → Sleep
```

### 对波形的影响

| 项目             | 影响       |
| ------------------ | ------------ |
| TX 出现时间      | 不直接改变 |
| TX 持续时间      | 不改变     |
| TX 电流高度      | 不改变     |
| TX 后 RXmin 数量 | 增加       |
| Sleep 开始时间   | 后移       |
| Sleep 时间       | 缩短       |
| 单周期 RX 能量   | 线性增加   |
| 单周期总能量     | 线性增加   |

### Attempt 的能量贡献

\[
E_{extra\_rx}
=
(Attempt-1)
\cdot
V
\cdot
I_{rx}
\cdot
T_{rx\_min}
\]

如果考虑 gap：

\[
E_{extra\_rx}
=
(Attempt-1)
\cdot
V
\cdot
\left(
I_{rx}T_{rx\_min}
+
I_{idle}T_{rx\_gap}
\right)
\]

### Attempt 每增加 1 的边际影响

\[
\Delta T_{active}
=
T_{rx\_min}
\]

\[
\Delta E
=
V
\cdot
I_{rx}
\cdot
T_{rx\_min}
\]

如果考虑 gap：

\[
\Delta T_{active}
=
T_{rx\_min}
+
T_{rx\_gap}
\]

\[
\Delta E
=
V
\cdot
\left(
I_{rx}T_{rx\_min}
+
I_{idle}T_{rx\_gap}
\right)
\]

---

## 3.4 Clock drift

### 影响位置

```text
Main RX 前的 guard window
```

Clock drift 用来补偿两端时钟误差。
为了不漏掉 anchor 附近的 Main RX，设备需要提前醒来。

### 计算关系

\[
T_{guard}
=
T_{CI}
\times
\frac{ppm_{total}}{10^6}
+
T_{margin}
\]

其中：

- $ppm_{total}$：本地和对端的总相对时钟漂移；
- $T_{margin}$：实现上的安全裕量。

### 波形影响

Clock drift 增大时：

```text
Main RX 前的 guard 变宽，设备更早进入 active/RX 状态。
```

示意：

```text
Drift 小:

Sleep → Wake → short guard → Main RX → TX → RXmin × (Attempt-1)


Drift 大:

Sleep → Wake → long guard → Main RX → TX → RXmin × (Attempt-1)
```

### 结论

| 项目           | 影响       |
| ---------------- | ------------ |
| 提前醒来时间   | 增大       |
| Guard 持续时间 | 增大       |
| Main RX 时间   | 不直接改变 |
| TX 时间        | 不直接改变 |
| RXmin 数量     | 不改变     |
| Sleep 时间     | 缩短       |
| 单周期能量     | 增大       |

---

## 3.5 RX Payload

### 影响位置

```text
Main RX packet
```

RX Payload 影响的是第一次完整 RX，也就是 Main RX。
它不影响 TX 后面的 RXmin。

### 计算关系

\[
T_{rx\_main}
=
f(PacketType, RXPayload)
\]

RX Payload 越大，Main RX 持续时间越长：

\[
E_{rx\_main}
=
V
\cdot
I_{rx}
\cdot
T_{rx\_main}
\]

### 波形影响

```text
RX Payload 小:

Guard → Main RX → TX → RXmin × (Attempt-1)
           短


RX Payload 大:

Guard → Main RX Main RX Main RX → TX → RXmin × (Attempt-1)
           更长
```

### 结论

| 项目             | 影响       |
| ------------------ | ------------ |
| Main RX 持续时间 | 增大       |
| Main RX 电流高度 | 基本不变   |
| TX 出现时间      | 后移       |
| TX 持续时间      | 不直接改变 |
| RXmin 数量       | 不改变     |
| Sleep 时间       | 缩短       |
| 单周期 RX 能量   | 增大       |

---

## 3.6 TX Payload

### 影响位置

```text
TX packet
```

TX Payload 决定 TX packet 的持续时间。

### 计算关系

\[
T_{tx}
=
f(PacketType, TXPayload)
\]

TX 能量为：

\[
E_{tx}
=
V
\cdot
I_{tx}(BTpower)
\cdot
T_{tx}
\]

### 波形影响

```text
TX Payload 小:

Main RX → TX → RXmin × (Attempt-1)
          短


TX Payload 大:

Main RX → TX TX TX → RXmin × (Attempt-1)
          更长
```

### 与 BT power 的耦合

TX 阶段的波形由两个维度共同决定：

| 参数        | 控制内容                       |
| ------------- | -------------------------------- |
| BT power    | TX 电流高度                    |
| TX Payload  | TX 持续时间                    |
| Packet type | TX 速率、slot 数、payload 上限 |

因此：

\[
E_{tx}
\propto
I_{tx}(BTpower)
\times
T_{tx}(PacketType,TXPayload)
\]

### 结论

| 项目           | 影响       |
| ---------------- | ------------ |
| TX 持续时间    | 增大       |
| TX 电流高度    | 不直接改变 |
| RXmin 出现时间 | 后移       |
| RXmin 数量     | 不改变     |
| Sleep 时间     | 缩短       |
| 单周期 TX 能量 | 增大       |

---

## 3.7 Packet type

### 影响位置

```text
Main RX packet 和 TX packet
```

Packet type 是结构性参数，决定 Main RX 和 TX 的基本时序形态。

它通常决定：

1. 单包占用几个 slot；
2. 最大 RX Payload；
3. 最大 TX Payload；
4. BR/EDR 速率；
5. 是否带 FEC；
6. Main RX 和 TX 的空中时间；
7. 有时也会影响不同 PHY/调制下的电流。

### 基本关系

\[
T_{rx\_main}
=
f(PacketType,RXPayload)
\]

\[
T_{tx}
=
f(PacketType,TXPayload)
\]

Classic BT 一个 slot 为：

\[
T_{slot}=625\ \mu s
\]

常见 Packet type 的 slot 数：

\[
N_{slot}(PacketType)\in\{1,3,5\}
\]

包最大持续时间近似为：

\[
T_{pkt,max}
=
N_{slot}(PacketType)
\times
625\ \mu s
\]

### 波形影响

#### 1-slot packet

```text
Guard → RX → TX → RXmin × (Attempt-1)
```

#### 3-slot packet

```text
Guard → RX RX RX → TX TX TX → RXmin × (Attempt-1)
```

#### 5-slot packet

```text
Guard → RX RX RX RX RX → TX TX TX TX TX → RXmin × (Attempt-1)
```

### 对 RXmin 的影响

如果你的 RXmin 是固定最短监听窗口，则：

\[
T_{rx\_min}=\text{constant}
\]

Packet type 不直接影响 RXmin。

如果你的平台把 RXmin 定义为接收某种最短 packet，则可以写成：

\[
T_{rx\_min}=g(PacketType)
\]

但在通常简化模型中，建议先把 RXmin 作为固定常量。

---

# 4. 最终单周期建模公式

## 4.1 周期长度

\[
T_{cycle}=T_{CI}
\]

如果 Connect Interval 以 slot 为单位：

\[
T_{CI}
=
CI_{slot}
\times
625\ \mu s
\]

---

## 4.2 Guard 时间

\[
T_{guard}
=
T_{CI}
\times
\frac{ppm_{total}}{10^6}
+
T_{margin}
\]

---

## 4.3 Main RX 时间

\[
T_{rx\_main}
=
f(PacketType,RXPayload)
\]

---

## 4.4 TX 时间

\[
T_{tx}
=
f(PacketType,TXPayload)
\]

---

## 4.5 Extra RXmin 时间

\[
T_{extra\_rx}
=
(Attempt-1)T_{rx\_min}
\]

如果考虑 gap：

\[
T_{extra\_rx}
=
(Attempt-1)
\left(
T_{rx\_min}+T_{rx\_gap}
\right)
\]

---

## 4.6 Active 时间

不考虑 gap：

\[
T_{active}
=
T_{wakeup}
+
T_{settle}
+
T_{guard}
+
T_{rx\_main}
+
T_{turnaround}
+
T_{tx}
+
(Attempt-1)T_{rx\_min}
+
T_{process}
+
T_{sleep\_entry}
\]

考虑 gap：

\[
T_{active}
=
T_{wakeup}
+
T_{settle}
+
T_{guard}
+
T_{rx\_main}
+
T_{turnaround}
+
T_{tx}
+
(Attempt-1)
\left(
T_{rx\_min}+T_{rx\_gap}
\right)
+
T_{process}
+
T_{sleep\_entry}
\]

---

## 4.7 Sleep 时间

\[
T_{sleep}
=
T_{CI}
-
T_{active}
\]

如果：

\[
T_{active}>T_{CI}
\]

说明当前参数组合无法放入一个 sniff 周期，需要调整 Connect Interval、Attempt、payload 或 packet type。

---

## 4.8 单周期平均电流

不考虑 RXmin gap：

\[
I_{avg}
=
\frac{
I_{sleep}T_{sleep}
+
I_{wakeup}T_{wakeup}
+
I_{settle}T_{settle}
+
I_{rx}
\left[
T_{guard}
+
T_{rx\_main}
+
(Attempt-1)T_{rx\_min}
\right]
+
I_{tx}(BTpower)T_{tx}
+
I_{cpu}T_{process}
+
I_{idle}T_{sleep\_entry}
}{
T_{CI}
}
\]

考虑 RXmin gap：

\[
I_{avg}
=
\frac{
I_{sleep}T_{sleep}
+
I_{wakeup}T_{wakeup}
+
I_{settle}T_{settle}
+
I_{rx}
\left[
T_{guard}
+
T_{rx\_main}
+
(Attempt-1)T_{rx\_min}
\right]
+
I_{idle}(Attempt-1)T_{rx\_gap}
+
I_{tx}(BTpower)T_{tx}
+
I_{cpu}T_{process}
+
I_{idle}T_{sleep\_entry}
}{
T_{CI}
}
\]

---

# 5. 参数耦合关系总结

## 5.1 BT power × TX Payload × Packet type

决定 TX 能量：

\[
E_{tx}
=
V
\cdot
I_{tx}(BTpower)
\cdot
T_{tx}(PacketType,TXPayload)
\]

含义：

```text
BT power 决定 TX 高度；
TX Payload 决定 TX 宽度；
Packet type 决定 TX 的 slot 数、速率和 payload 上限。
```

---

## 5.2 RX Payload × Packet type

决定 Main RX 能量：

\[
E_{rx\_main}
=
V
\cdot
I_{rx}
\cdot
T_{rx\_main}(PacketType,RXPayload)
\]

含义：

```text
RX Payload 越大，Main RX 越宽；
Packet type 决定该 payload 用多少 airtime 承载。
```

---

## 5.3 Attempt × RXmin

决定 TX 后额外 RX 能量：

\[
E_{extra\_rx}
=
(Attempt-1)
\cdot
V
\cdot
I_{rx}
\cdot
T_{rx\_min}
\]

含义：

```text
Attempt 每增加 1，只增加一个 TX 后的 RXmin，不增加 TX。
```

---

## 5.4 Connect Interval × Clock drift

决定 guard 时间：

\[
T_{guard}
=
T_{CI}
\times
\frac{ppm_{total}}{10^6}
+
T_{margin}
\]

含义：

```text
Connect Interval 越长，clock drift 累积越大，guard 可能越宽。
```

---

# 6. 最终正确逻辑一句话版

这个 BT sniffing 场景下，单周期电流波形由以下逻辑决定：

```text
Connect Interval 决定周期总长度；
Clock drift 决定 Main RX 前的 guard 宽度；
RX Payload + Packet type 决定 Main RX 宽度；
TX Payload + Packet type 决定 TX 宽度；
BT power 决定 TX 高度；
Attempt=N 时，TX 后追加 N-1 个 RXmin。
```

最核心的 active 时间公式是：

\[
T_{active}
=
T_{wakeup}
+
T_{settle}
+
T_{guard}
+
T_{rx\_main}
+
T_{turnaround}
+
T_{tx}
+
(Attempt-1)T_{rx\_min}
+
T_{process}
+
T_{sleep\_entry}
\]

最核心的平均电流近似是：

\[
I_{avg}
\approx
\frac{
I_{rx}
\left[
T_{guard}
+
T_{rx\_main}
+
(Attempt-1)T_{rx\_min}
\right]
+
I_{tx}(BTpower)T_{tx}
+
I_{sleep}T_{sleep}
+
\text{other overhead}
}{
T_{CI}
}
\]

其中最容易影响功耗的组合通常是：

1. **BT power × TX Payload × Packet type**
2. **RX Payload × Packet type**
3. **Attempt - 1 个 RXmin**
4. **Clock drift × Connect Interval**
5. **Connect Interval 对 sleep 占比的影响**