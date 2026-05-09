import '../../../models/earbuds.dart';

const EarbudsChip kChip1501 = EarbudsChip(
  id: '1501',
  process: 'tsmc22n',
  core: 'M33*3 + BTC',
  fullRamKb: 1824.0,
  massProduction: true,
  sleep: SleepCurrent(
    vcoreM: 0.675,
    vcoreL: null,
    vana: 1.3,
    vhppa: 1.7,
    pdSleep256: null,
    pdSleepFull: null,
    deepSleep: 182.0,
  ),
  mcuRun: [
    RunCurrent(
      label: 'default',
      wfi24M: 1.79,
      cm24M: 2.19,
      cm48M: 2.81,
      cm96M: 4.01,
      cm192M: 9.3,
    ),
  ],
  scene: EarbudsScene(
    mute: 4.93,
    noisePink: 5.12,
    k1Hz: 18.4,
    call: 8.2,
    sniffPage: 0.45,
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
  rxVsys: null,
  pa: AudioPa(
    db0: null,
    dbNeg20: null,
    dbNegInf: null,
  ),
);
