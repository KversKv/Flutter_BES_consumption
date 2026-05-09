import '../../../models/earbuds.dart';

const EarbudsChip kChip1306p = EarbudsChip(
  id: '1306p',
  process: 'hlmc22n',
  core: 'M33*2 + BTC',
  fullRamKb: 768.0,
  massProduction: true,
  sleep: SleepCurrent(
    vcoreM: 0.6,
    vcoreL: null,
    vana: 1.3,
    vhppa: 1.7,
    pdSleep256: null,
    pdSleepFull: null,
    deepSleep: 120.0,
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
    mute: 3.69,
    noisePink: 3.8,
    k1Hz: 17.06,
    call: 5.61,
    sniffPage: 0.4,
    powerOff: 0.003,
  ),
  bt: BtScene(
    btBase: 172.5,
    bleAdv500_9: 242.0,
    bleConn200_0: null,
    bleConn500_0: 219.4,
    btPagescan9: 312.5,
    btSniff200_0: null,
    btSniff500_0: 222.7,
  ),
  txSweep: [
    TxSweepVariant(
      label: 'VPA=1.3V',
      values: {-6: 13.8, -5: 13.9, -4: 14.0, -3: 14.6, -2: 15.1, -1: 15.2, 0: 15.5, 1: 15.4, 2: 16.1, 3: 16.7, 4: 16.5, 5: 17.6, 6: 18.6, 7: 19.4, 8: 20.0, 9: 21.0, 10: 24.0, 11: 26.0, 12: 30.0},
    ),
  ],
  rxVana: RxSweep(
    values: {0: 13.13, 1: 11.42, 2: 11.23, 3: 10.59, 4: 10.67, 5: 10.59, 6: 10.59, 7: 10.59},
    vana: 1.3,
  ),
  rxVsys: null,
  pa: AudioPa(
    db0: 13.950526,
    dbNeg20: 3.286,
    dbNegInf: 0.66,
  ),
);
