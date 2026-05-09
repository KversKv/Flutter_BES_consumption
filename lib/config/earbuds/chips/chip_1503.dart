import '../../../models/earbuds.dart';

const EarbudsChip kChip1503 = EarbudsChip(
  id: '1503',
  process: 'tsmc22n',
  core: 'M33*2 + BTC',
  fullRamKb: 1408.0,
  massProduction: true,
  sleep: SleepCurrent(
    vcoreM: 0.6,
    vcoreL: 0.6,
    vana: 1.2,
    vhppa: 1.7,
    pdSleep256: 15.1,
    pdSleepFull: 20.0,
    deepSleep: 94.6,
  ),
  mcuRun: [
    RunCurrent(
      label: 'default',
      wfi24M: 0.88,
      cm24M: 1.04,
      cm48M: 1.31,
      cm96M: 1.84,
      cm192M: 4.59,
    ),
  ],
  scene: EarbudsScene(
    mute: 3.2,
    noisePink: 3.31,
    k1Hz: 16.32,
    call: 4.52,
    sniffPage: 0.25,
    powerOff: 0.005,
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
  rxVana: RxSweep(
    values: {0: 11.22, 1: 9.61, 2: 9.45, 3: 8.9, 4: 8.9, 5: 8.9, 6: 8.9, 7: 8.9},
    vana: 1.2,
  ),
  rxVsys: RxSweep(
    values: {1: 5.9, 2: 6.0, 3: 5.6, 4: 5.8, 5: 5.7, 6: 5.7, 7: 5.7},
  ),
  pa: AudioPa(
    db0: null,
    dbNeg20: null,
    dbNegInf: null,
  ),
);
