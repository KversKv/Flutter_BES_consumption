import '../../../models/earbuds.dart';

const EarbudsChip kChip1307 = EarbudsChip(
  id: '1307',
  process: 'hlmc22n',
  core: 'M33*1 + BTC',
  fullRamKb: 384.0,
  massProduction: true,
  sleep: SleepCurrent(
    vcoreM: 0.625,
    vcoreL: null,
    vana: 1.3,
    vhppa: 1.7,
    pdSleep256: null,
    pdSleepFull: null,
    deepSleep: 60.0,
  ),
  mcuRun: [
    RunCurrent(
      label: 'default',
      wfi24M: null,
      cm24M: null,
      cm48M: null,
      cm96M: null,
      cm192M: null,
    ),
  ],
  scene: EarbudsScene(
    mute: 4.29,
    noisePink: 4.39,
    k1Hz: 18.36,
    call: 8.87,
    sniffPage: 0.26,
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
      label: 'VPA=1.7V',
      values: {0: 27.0, 1: 28.0, 2: 28.0, 3: 29.0, 4: 30.0, 5: 30.0, 6: 32.0, 7: 34.0, 8: 35.0, 9: 37.0, 10: 39.0, 11: 43.0, 12: 48.0, 13: 54.0},
    ),
  ],
  rxVana: RxSweep(
    values: {0: 12.8, 1: 11.4, 2: 11.2, 3: 10.6, 4: 10.6, 5: 10.6, 6: 10.6, 7: 10.6},
    vana: 1.4,
  ),
  rxVsys: null,
  pa: AudioPa(
    db0: null,
    dbNeg20: null,
    dbNegInf: null,
  ),
);
