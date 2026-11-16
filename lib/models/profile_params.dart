enum Mode {advertisingTxOnly, advertisingTxRx, bleConnectionCentral, bleConnectionPeripheral, hdt }
enum Phy { le1M, le2M }

enum HdtModule { source, sink }

class ProfileParams {
  Mode mode;
  Phy phy;
  double txPowerDbm;
  double advIntervalMs;
  double connIntervalMs;
  int payloadBytes;
  int rxPayloadBytes;
  bool dle;
  bool eventLengthExt;
  int slaveLatency;
  int centralPpm;
  int peripheralPpm;
  bool lfRc;

  ProfileParams({
    required this.mode,
    required this.phy,
    required this.txPowerDbm,
    required this.advIntervalMs,
    required this.connIntervalMs,
    required this.payloadBytes,
    this.rxPayloadBytes = 0,
    this.dle = true,
    this.eventLengthExt = true,
    this.slaveLatency = 0,
    this.centralPpm = 20,
    this.peripheralPpm = 20,
    this.lfRc = false,
  });
}
