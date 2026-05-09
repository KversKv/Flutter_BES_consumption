import '../../../models/earbuds.dart';

const EarbudsChip kChip1600 = EarbudsChip(
  id: '1600',
  process: 'tsmc12n',
  core: 'M55*1 + M33*2 + HIFI4 + BTC',
  fullRamKb: 4096.0,
  massProduction: true,
  sleep: SleepCurrent(
    vcoreM: 0.6,
    vcoreL: null,
    vana: 1.2,
    vhppa: 1.7,
    pdSleep256: 30.9,
    pdSleepFull: null,
    deepSleep: 40.0,
  ),
  mcuRun: [
    RunCurrent(
      label: 'default',
      wfi24M: 1.07,
      cm24M: 1.21,
      cm48M: 1.47,
      cm96M: 1.93,
      cm192M: 4.48,
    ),
  ],
  scene: EarbudsScene(
    mute: 4.35,
    noisePink: 4.48,
    k1Hz: 17.44,
    call: 5.71,
    sniffPage: 0.29,
    powerOff: 0.001,
  ),
  bt: BtScene(
    btBase: null,
    bleAdv500_9: null,
    bleConn200_0: null,
    bleConn500_0: null,
    btPagescan9: null,
    btSniff200_0: null,
    btSniff500_0: null,
  ),
  txSweep: [],
  rxVana: null,
  rxVsys: RxSweep(
    values: {1: 5.0, 2: 4.1, 3: 4.1, 4: 4.1, 5: 4.1, 6: 4.1, 7: 4.1},
  ),
  pa: AudioPa(
    db0: null,
    dbNeg20: null,
    dbNegInf: null,
  ),
);
