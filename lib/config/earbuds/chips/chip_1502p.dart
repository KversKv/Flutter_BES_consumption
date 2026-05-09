import '../../../models/earbuds.dart';

const EarbudsChip kChip1502p = EarbudsChip(
  id: '1502p',
  process: 'hlmc22n',
  core: 'M33*4 + BTC (DS上为M33*3)',
  fullRamKb: 2208.0,
  massProduction: true,
  sleep: SleepCurrent(
    vcoreM: null,
    vcoreL: null,
    vana: null,
    vhppa: null,
    pdSleep256: null,
    pdSleepFull: null,
    deepSleep: null,
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
    mute: 4.55,
    noisePink: 4.73,
    k1Hz: 17.82,
    call: 6.73,
    sniffPage: 0.43,
    powerOff: 0.002,
  ),
  bt: BtScene(
    btBase: 33.4,
    bleAdv500_9: null,
    bleConn200_0: null,
    bleConn500_0: 78.26,
    btPagescan9: 173.5,
    btSniff200_0: null,
    btSniff500_0: 96.66,
  ),
  txSweep: [
    TxSweepVariant(
      label: 'VPA=1.7V',
      values: {-1: 21.0, 0: 22.0, 1: 22.0, 2: 23.0, 3: 23.0, 4: 23.0, 5: 23.0, 6: 24.0, 7: 28.0, 8: 28.0, 9: 28.0, 10: 29.0, 11: 33.0, 12: 36.0, 13: 42.0},
    ),
    TxSweepVariant(
      label: 'VPA=1.2V',
      values: {0: 12.1, 1: 12.7, 2: 12.1, 3: 12.5, 4: 13.5, 5: 14.4, 6: 15.4, 7: 16.9, 8: 17.2, 9: 18.0, 10: 21.0, 11: 23.0, 12: 25.0},
    ),
  ],
  rxVana: RxSweep(
    values: {0: 12.15, 1: 10.64, 2: 10.4, 3: 9.8, 4: 9.8, 5: 9.8, 6: 9.8, 7: 9.8},
    vana: 1.3,
  ),
  rxVsys: null,
  pa: AudioPa(
    db0: 13.747895,
    dbNeg20: 3.166316,
    dbNegInf: 0.54,
  ),
);
