import '../../../models/earbuds.dart';

const EarbudsChip kChip1501p = EarbudsChip(
  id: '1501p',
  process: 'hlmc28n',
  core: 'M33*3 + BTC',
  fullRamKb: 1824.0,
  massProduction: true,
  sleep: SleepCurrent(
    vcoreM: 0.8,
    vcoreL: null,
    vana: 1.3,
    vhppa: 1.7,
    pdSleep256: null,
    pdSleepFull: null,
    deepSleep: 141.0,
  ),
  mcuRun: [
    RunCurrent(
      label: 'default',
      wfi24M: 1.28,
      cm24M: 1.6,
      cm48M: 2.06,
      cm96M: 3.31,
      cm192M: 6.13,
    ),
  ],
  scene: EarbudsScene(
    mute: 4.28,
    noisePink: 4.45,
    k1Hz: 17.1,
    call: 7.22,
    sniffPage: 0.35,
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
  rxVana: null,
  rxVsys: null,
  pa: AudioPa(
    db0: null,
    dbNeg20: null,
    dbNegInf: null,
  ),
);
