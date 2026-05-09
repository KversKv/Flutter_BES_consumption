import '../../../models/earbuds.dart';

const EarbudsChip kChip1607 = EarbudsChip(
  id: '1607',
  process: 'SS_N14',
  core: 'M55*3 + U55  + BTC',
  fullRamKb: 3712.0,
  massProduction: false,
  sleep: SleepCurrent(
    vcoreM: 0.65,
    vcoreL: 0.6,
    vana: 0.9,
    vhppa: 1.7,
    pdSleep256: null,
    pdSleepFull: null,
    deepSleep: null,
  ),
  mcuRun: [],
  scene: EarbudsScene(
    mute: 4.5,
    noisePink: 4.57,
    k1Hz: 19.227,
    call: 6.94,
    sniffPage: 0.3,
    powerOff: 0.002,
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
  txSweep: [
    TxSweepVariant(
      label: '3.3 + 1.7',
      values: {0: 23.0, 1: 24.0, 2: 24.0, 3: 26.0, 4: 27.0, 5: 28.0, 6: 30.0, 7: 32.0, 8: 34.0, 9: 36.0, 10: 38.0, 11: 41.0, 12: 44.0, 13: 47.0},
    ),
    TxSweepVariant(
      label: '1.7 + 0.9',
      values: {0: 20.0, 1: 20.0, 2: 21.0, 3: 22.0, 4: 22.0, 5: 23.0, 6: 24.0, 7: 25.0, 8: 27.0, 9: 36.0, 10: 38.0, 11: 41.0, 12: 44.0, 13: 47.0},
    ),
  ],
  rxVana: RxSweep(
    values: {0: 10.68, 1: 10.39, 2: 9.68, 3: 9.21, 4: 8.92, 5: 8.92, 6: 8.92, 7: 8.92},
    vana: 0.9,
  ),
  rxVsys: RxSweep(
    values: {1: 6.36, 2: 6.15, 3: 6.0, 4: 5.92, 5: 5.92, 6: 5.95, 7: 5.97},
  ),
  pa: AudioPa(
    db0: 15.34,
    dbNeg20: 2.17,
    dbNegInf: 0.558,
  ),
);
