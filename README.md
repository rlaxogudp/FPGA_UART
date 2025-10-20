# FPGA 시계, 초음파 센서, 온습도 센서 통합 시스템 (UART 연동)

[cite_start]본 프로젝트는 **하만세미콘아카데미 2기** 과정의 일환으로 진행된 4조의 팀 프로젝트입니다. [cite: 3, 4]

## 📌 1. 프로젝트 개요
[cite_start]본 프로젝트의 목적은 FPGA 보드(Basys 3)를 활용하여 **Watch/Stopwatch, DHT11 (온습도 센서), HC-SR04 (초음파 거리측정 센서)**의 세 가지 주요 기능을 통합 구현하는 것입니다. [cite: 11]

[cite_start]또한, PC와 FPGA 보드 간의 **UART 통신 시스템**을 설계하여 [cite: 11][cite_start], 센서에서 측정된 값(거리, 온도, 습도)이나 스톱워치/시계의 상태를 PC 터미널 프로그램(ComPortMaster)으로 전송하는 기능을 구현했습니다. [cite: 38]

## ✨ 2. 주요 기능
* [cite_start]**다중 모드 지원**: 슬라이드 스위치를 통해 3가지 주요 기능 (Watch/Stopwatch, SR04, DHT11)을 선택할 수 있습니다. [cite: 2086, 2189]
* **Watch / Stopwatch**:
    * [cite_start]**Watch**: 시간, 분, 초를 7-Segment에 표시합니다. [cite: 13, 16]
    * [cite_start]**Stopwatch**: Run, Stop, Clear 기능을 버튼으로 제어할 수 있습니다. [cite: 13, 120, 122, 123]
* **HC-SR04 거리 측정**:
    * [cite_start]초음파 센서를 이용해 물체와의 거리를 측정합니다. [cite: 14]
    * [cite_start]측정된 거리(cm)는 7-Segment에 표시됩니다. [cite: 47, 451, 454]
    * [cite_start]측정된 거리 값을 ASCII로 변환하여 UART를 통해 PC로 전송합니다. [cite: 806, 818]
* **DHT11 온습도 측정**:
    * [cite_start]온도와 습도를 측정하여 7-Segment에 번갈아 표시합니다. [cite: 15, 1079]
    * [cite_start]DHT-11의 고유한 단일 핀(Single-bus) 통신 프로토콜을 FSM으로 구현했습니다. [cite: 76, 1081]
    * [cite_start]40비트 데이터 패킷 수신 및 Checksum 검증을 통해 데이터 유효성을 확인합니다. [cite: 75, 77, 1355, 1658]
* **UART 통신**:
    * [cite_start]`UART_TOP` 모듈(Tx/Rx FIFO, Baud Tick Gen 포함)을 통해 PC와 데이터를 주고받습니다. [cite: 78-86]
    * [cite_start]Watch/Stopwatch 모드에서 PC의 키보드 입력을 받아 제어할 수 있습니다. [cite: 88, 89]

## 🛠️ 3. 개발 환경
* [cite_start]**FPGA Board**: Digilent Basys 3 [cite: 35] (AMD Artix-7 XC7A35T) [cite_start][cite: 36]
* [cite_start]**Design Tool**: Vivado 2020.2 [cite: 33]
* **Language**: Verilog (HDL)
* [cite_start]**Sensors**: HC-SR04 (초음파), DHT11 (온습도) [cite: 40, 57]
* [cite_start]**PC Terminal**: ComPortMaster [cite: 38]

## 📐 4. 시스템 아키텍처
[cite_start]최상위 `TOP` 모듈은 3개의 메인 모듈(Watch, SR04, DHT11)과 이들을 제어하는 `Control Unit`, 그리고 출력을 선택하는 `Mux_out`으로 구성됩니다. [cite: 2084, 2085]

### Control Unit (fpga_cu)
* [cite_start]슬라이드 스위치(`sw[4:0]`) 입력을 받아 어떤 모듈을 활성화할지 결정합니다. [cite: 2156, 2159]
* [cite_start]`sw[4]` (DHT11), `sw[3]` (SR04), `sw[2]` (Watch) 순서로 우선순위를 가지며 [cite: 2189][cite_start], 각 모듈의 `enable` 신호를 생성합니다. [cite: 2160, 2161, 2162]

### Mux_out (U_OUT)
* [cite_start]`Control Unit`에서 생성된 `enable` 신호(start_dht, start_sr, start_watch)를 MUX의 선택(Select) 신호로 사용합니다. [cite: 2245, 2247, 2249]
* [cite_start]활성화된 모듈의 출력(FND, LED, UART TX)만을 최종 출력 포트로 연결합니다. [cite: 2304, 2315, 2322, 2330]

### 모듈별 리셋 (Trouble Shooting 1)
* [cite_start]**문제**: MUX로 출력을 제어할 때, 비활성화된 모듈이 이전에 출력하던 값을 FND가 계속 표시하는 현상이 발생했습니다. [cite: 2530, 2531, 2532]
* [cite_start]**해결**: 각 모듈의 Reset 신호를 `(rst | ~enable)`로 수정했습니다. [cite: 2534] [cite_start]모듈이 비활성화(`enable=0`)되면 리셋 상태가 되어 FND 출력을 초기화합니다. [cite: 2537, 2540, 2545]

## 💡 5. 핵심 설계 및 문제 해결

### SR04 FSM 및 ASCII Sender
* [cite_start]`sr04_controller`는 `IDLE` -> `START` (Trig 10us) -> `WAIT` (Echo 대기) -> `DIST` (Echo 펄스 폭 카운트)의 FSM으로 동작합니다. [cite: 461-471]
* [cite_start]측정된 거리 값(숫자)을 4자리 ASCII 코드로 변환하는 `datatoascii` 모듈을 구현했습니다. [cite: 372, 828]
* [cite_start]`Sender` 모듈은 변환된 32비트 ASCII 데이터를 8비트씩 4번에 나누어 UART TX FIFO로 `push`합니다. [cite: 280, 364, 365, 819]

### DHT11 프로토콜 FSM
* [cite_start]온습도 값을 40비트 직렬 데이터로 전송하는 DHT11의 복잡한 타이밍 기반 프로토콜을 FSM으로 구현했습니다. [cite: 1081, 1361]
* [cite_start]**FSM 상태**: `IDLE` -> `START` (MCU 20ms LOW) -> `WAIT` (센서 응답 대기) -> `SYNC LOW` (센서 80us LOW) -> `SYNC HIGH` (센서 80us HIGH) -> `DATA SYNC` (50us LOW) -> `DATA DETECT` (데이터 '0'/'1' 판별) -> `STOP` [cite: 1458-1677]
* [cite_start]`DATA DETECT` 상태에서 1us 틱 카운트가 50us를 넘는지 여부로 '0'과 '1'을 구별합니다. [cite: 1303, 1607, 1608]
* [cite_start]`STOP` 상태에서 40비트 수신 완료 후, Checksum을 검증하여 `valid` 신호를 생성합니다. [cite: 1356, 1643, 1658, 1674]

### 타이밍 위반 (WNS) 문제 해결 (Trouble Shooting 2)
* [cite_start]**문제**: SR04 모듈에서 거리 계산을 위한 나눗셈 연산(`dist_reg / 58`)이 한 클럭 내에 처리되지 못해 타이밍 요구사항(WNS)을 위반했습니다. [cite: 2551, 2567, 2568]
* [cite_start]**해결**: 파이프라이닝을 적용하여 연산을 두 클럭에 걸쳐 나누어 처리했습니다. [cite: 2573]
    1.  첫 번째 클럭: `dist_reg` 값을 58로 나눕니다.
    2.  [cite_start]두 번째 클럭: 나눗셈 결과를 `dist_div_reg` 레지스터에 저장하고 이 값을 출력합니다. [cite: 2556, 2562, 2571, 2574]
* [cite_start]**결과**: WNS(Worst Negative Slack)가 -1.627ns에서 3.866ns로 개선되어 타이밍 문제를 해결했습니다. [cite: 2568, 2572]

## 👥 6. 팀원
* [cite_start]**김은성** [cite: 4, 2623]
* [cite_start]**김태형** [cite: 4, 2624]
* [cite_start]**조민준** [cite: 4, 2622]
* [cite_start]**황석현** [cite: 4, 2621]
