enum Mode { advertising, connected }
enum Phy { le1M, le2M, leCodedS8 }

class ProfileParams {
  Mode mode;
  Phy phy;
  double txPowerDbm;
  double advIntervalMs;
  double connIntervalMs;
  int payloadBytes;

  ProfileParams({
    required this.mode,
    required this.phy,
    required this.txPowerDbm,
    required this.advIntervalMs,
    required this.connIntervalMs,
    required this.payloadBytes,
  });
}
