

/// 耳机场景功耗模型
class Earbuds {
  final String chipId;
  final bool isMassProduction;
  final double vcoreM_Music;
  final double vcoreM_Call;
  final double vcoreL_Music;
  final double vcoreL_Call;
  final double vana;
  final double vhppa;

  final double currentMute;
  final double currentNoisePink;
  final double current1kHz;
  final double currentCall;
  final double currentIdle;
  final double currentPowerOff;

  Earbuds({
    required this.chipId,
    required this.isMassProduction,
    required this.vcoreM_Music,
    required this.vcoreM_Call,
    required this.vcoreL_Music,
    required this.vcoreL_Call,
    required this.vana,
    required this.vhppa,
    required this.currentMute,
    required this.currentNoisePink,
    required this.current1kHz,
    required this.currentCall,
    required this.currentIdle,
    required this.currentPowerOff,
  });
}

/// 示例数据
final List<Earbuds> demoEarbudsList = [
  Earbuds(
    chipId: '1503p',
    isMassProduction: false,
    vcoreM_Music:       0.7     ,
    vcoreM_Call:        0.7     ,
    vcoreL_Music:       0.7     ,
    vcoreL_Call:        0.7     ,
    vana:               1.2     ,
    vhppa:              1.7     ,
    currentMute:        4.22    ,
    currentNoisePink:   4.31    ,
    current1kHz:        17.3    ,
    currentCall:        5.77    ,
    currentIdle:        0.28    ,
    currentPowerOff:    0.004   ,
  ),
  Earbuds(
    chipId: '1503',
    isMassProduction: true,
    vcoreM_Music:       0.7     ,
    vcoreM_Call:        0.7     ,
    vcoreL_Music:       0.7     ,
    vcoreL_Call:        0.7     ,
    vana:               1.2     ,
    vhppa:              1.7     ,
    currentMute:        3.2     ,
    currentNoisePink:   3.31    ,
    current1kHz:        16.32   ,
    currentCall:        4.52    ,
    currentIdle:        0.25    ,
    currentPowerOff:    0.005   ,
  ),
  Earbuds(
    chipId: '1702',
    isMassProduction: false,
    vcoreM_Music:       0.65    ,
    vcoreM_Call:        0.65    ,
    vcoreL_Music:       0.55    ,
    vcoreL_Call:        0.55    ,
    vana:               1.1     ,
    vhppa:              1.7     ,
    currentMute:        3.3     ,
    currentNoisePink:   3.43    ,
    current1kHz:        16.85   ,
    currentCall:        4.5     ,
    currentIdle:        0.4     ,
    currentPowerOff:    0.004   ,
  ),

  Earbuds(
    chipId: '1700',
    isMassProduction: true,
    vcoreM_Music:       0.65    ,
    vcoreM_Call:        0.65    ,
    vcoreL_Music:       0.55    ,
    vcoreL_Call:        0.55    ,
    vana:               1.1     ,
    vhppa:              1.7     ,
    currentMute:        3.39    ,
    currentNoisePink:   3.47    ,
    current1kHz:        16.9    ,
    currentCall:        4.8     ,
    currentIdle:        0.34    ,
    currentPowerOff:    0.004   ,
  ),

  Earbuds(
    chipId: '1605',
    isMassProduction: false,
    vcoreM_Music:       0.65    ,
    vcoreM_Call:        0.65    ,
    vcoreL_Music:       0.55    ,
    vcoreL_Call:        0.55    ,
    vana:               1.1     ,
    vhppa:              1.7     ,
    currentMute:        3.45    ,
    currentNoisePink:   3.55    ,
    current1kHz:        17.3    ,
    currentCall:        4.8     ,
    currentIdle:        0.2     ,
    currentPowerOff:    0.004   ,
  ),

  Earbuds(
    chipId: '1603',
    isMassProduction: true,
    vcoreM_Music:       0.685   ,
    vcoreM_Call:        0.685   ,
    vcoreL_Music:       0.585   ,
    vcoreL_Call:        0.585   ,
    vana:               1.05    ,
    vhppa:              1.7     ,
    currentMute:        3.84    ,
    currentNoisePink:   4       ,
    current1kHz:        16.45   ,
    currentCall:        5       ,
    currentIdle:        0.25    ,
    currentPowerOff:    0.002   ,
  ),

    Earbuds(
    chipId: '1600',
    isMassProduction: true,
    vcoreM_Music:       0.7     ,
    vcoreM_Call:        0.7     ,
    vcoreL_Music:       0.7     ,
    vcoreL_Call:        0.7     ,
    vana:               1.2     ,
    vhppa:              1.7     ,
    currentMute:        4.35    ,
    currentNoisePink:   4.48    ,
    current1kHz:        17.44   ,
    currentCall:        5.71    ,
    currentIdle:        0.29    ,
    currentPowerOff:    0.001   ,
  ),



  Earbuds(
    chipId: '1502p',
    isMassProduction: true,
    vcoreM_Music:       0.75    ,
    vcoreM_Call:        0.8     ,
    vcoreL_Music:       0.7     ,
    vcoreL_Call:        0.75    ,
    vana:               1.2     ,
    vhppa:              1.7     ,
    currentMute:        4.55    ,
    currentNoisePink:   4.73    ,
    current1kHz:        17.82   ,
    currentCall:        6.73    ,
    currentIdle:        0.43    ,
    currentPowerOff:    0.002   ,
  ),
   Earbuds(
    chipId: '1502x',
    isMassProduction: true,
    vcoreM_Music:       0.75    ,
    vcoreM_Call:        0.75    ,
    vcoreL_Music:       0.75    ,
    vcoreL_Call:        0.75    ,
    vana:               1.3     ,
    vhppa:              1.7     ,
    currentMute:        4.45    ,
    currentNoisePink:   4.65    ,
    current1kHz:        18.3    ,
    currentCall:        6.62    ,
    currentIdle:        0.34    ,
    currentPowerOff:    0.006   ,
  ),

  Earbuds(
    chipId: '1307p',
    isMassProduction: true,
    vcoreM_Music:       0.75    ,
    vcoreM_Call:        0.8     ,
    vcoreL_Music:       0.75    ,
    vcoreL_Call:        0.8     ,
    vana:               1.3     ,
    vhppa:              1.7     ,
    currentMute:        4.58    ,
    currentNoisePink:   4.87    ,
    current1kHz:        19      ,
    currentCall:        8.57    ,
    currentIdle:        0.3     ,
    currentPowerOff:    0.003   ,
  ),

  Earbuds(
    chipId: '1307',
    isMassProduction: true,
    vcoreM_Music:       0.75    ,
    vcoreM_Call:        0.8     ,
    vcoreL_Music:       0.75    ,
    vcoreL_Call:        0.8     ,
    vana:               1.3     ,
    vhppa:              1.7     ,
    currentMute:        4.29    ,
    currentNoisePink:   4.39    ,
    current1kHz:        18.36   ,
    currentCall:        8.87    ,
    currentIdle:        0.26    ,
    currentPowerOff:    0.002   ,
  ),

  Earbuds(
    chipId: '1306p',
    isMassProduction: true,
    vcoreM_Music:       0.75    ,
    vcoreM_Call:        0.75    ,
    vcoreL_Music:       0.75    ,
    vcoreL_Call:        0.75    ,
    vana:               1.3     ,
    vhppa:              1.7     ,
    currentMute:        3.69    ,
    currentNoisePink:   3.8     ,
    current1kHz:        17.06   ,
    currentCall:        5.61    ,
    currentIdle:        0.4     ,
    currentPowerOff:    0.003   ,
  ),




  
];
