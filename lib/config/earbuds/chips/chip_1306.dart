import '../../../models/earbuds.dart';

const EarbudsChip kChip1306 = EarbudsChip(
  id: '1306',
  process: 'hlmc22n',
  core: 'M33*2 + BTC',
  fullRamKb: 512.0,
  massProduction: true,
  sleep: SleepCurrent(
    vcoreM: 0.675,
    vcoreL: null,
    vana: 1.3,
    vhppa: 1.75,
    pdSleep256: null,
    pdSleepFull: null,
    deepSleep: 190.0,
  ),
  mcuRun: [
    RunCurrent(
      label: 'default',
      wfi24M: 2.16,
      cm24M: 2.43,
      cm48M: 2.88,
      cm96M: 4.48,
      cm192M: 8.45,
    ),
  ],
  scene: EarbudsScene(
    mute: 4.44,
    noisePink: 4.63,
    k1Hz: 18.0,
    call: 8.62,
    sniffPage: 0.41,
    powerOff: 0.007,
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
