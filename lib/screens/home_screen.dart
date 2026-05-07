import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/action_button.dart';
import '../services/tesla_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TeslaApiService _apiService = TeslaApiService();
  
  // 상태 변수들
  bool _isLoading = true;
  String _carName = "My Model Y";
  int _batteryLevel = 0;
  double _remainingRange = 0;
  bool _isLocked = true;
  bool _isClimateOn = false;
  double _insideTemp = 0;
  double _outsideTemp = 0;
  double _odometer = 0;
  
  // 애니메이션 (차량 발광 효과)
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnimation = Tween(begin: 0.0, end: 12.0).animate(_glowController);
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchVehicleData();
      setState(() {
        _carName = data['display_name'] ?? "My Tesla";
        
        final chargeState = data['charge_state'] ?? {};
        _batteryLevel = chargeState['battery_level'] ?? 0;
        
        // Tesla API는 miles를 반환하므로 km로 변환 (* 1.60934)
        double rangeMiles = (chargeState['battery_range'] ?? chargeState['est_battery_range'] ?? 0).toDouble();
        _remainingRange = rangeMiles * 1.60934;
        
        final vehicleState = data['vehicle_state'] ?? {};
        _isLocked = vehicleState['locked'] ?? true;
        double odoMiles = (vehicleState['odometer'] ?? 0).toDouble();
        _odometer = odoMiles * 1.60934;
        
        final climateState = data['climate_state'] ?? {};
        _isClimateOn = climateState['is_climate_on'] ?? false;
        _insideTemp = (climateState['inside_temp'] ?? 0).toDouble();
        _outsideTemp = (climateState['outside_temp'] ?? 0).toDouble();
      });
    } catch (e) {
      debugPrint("API 로드 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleLock() async {
    final nextState = !_isLocked;
    setState(() => _isLocked = nextState);
    
    bool success = await _apiService.toggleLock(nextState);
    if (!success) {
      if(mounted) setState(() => _isLocked = !nextState);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('통신 실패: 다시 시도해주세요.')));
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nextState ? '차량이 잠겼습니다. 🔒' : '차량 문이 열렸습니다. 🔓')));
    }
  }

  void _openFrunk() async {
    bool success = await _apiService.openFrunk();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프렁크를 엽니다. 🚘')));
    }
  }

  void _toggleClimate() async {
    final nextState = !_isClimateOn;
    setState(() => _isClimateOn = nextState);

    bool success = await _apiService.toggleClimate(nextState);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nextState ? '에어컨을 켰습니다. ❄️ (22°C)' : '공조를 껐습니다.')));
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.person_crop_circle),
          onPressed: () {},
        ),
        title: Column(
          children: [
            Text(_carName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('주차됨', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _isLoading 
                ? const Center(child: Padding(
                  padding: EdgeInsets.only(top: 100.0),
                  child: CircularProgressIndicator(),
                ))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. 배터리 상태
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _batteryLevel > 20 ? CupertinoIcons.battery_75_percent : CupertinoIcons.battery_25_percent, 
                      color: _batteryLevel > 20 ? Colors.green : Colors.redAccent, 
                      size: 30
                    ),
                    const SizedBox(width: 8),
                    Text('$_batteryLevel%',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${_remainingRange.toInt()} km 주행 가능',
                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
                
                const SizedBox(height: 40),

                // 2. 차량 이미지
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!_isLocked)
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.4),
                              blurRadius: _glowAnimation.value * 3,
                              spreadRadius: _glowAnimation.value,
                            ),
                          if (_isClimateOn)
                            BoxShadow(
                              color: Colors.lightBlue.withValues(alpha: 0.3),
                              blurRadius: _glowAnimation.value * 4,
                              spreadRadius: _glowAnimation.value + 2,
                            ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.car_detailed, size: 130, color: Colors.white),
                      ),
                    );
                  }
                ),

                const SizedBox(height: 40),

                // 3. 퀵 상태 카드
                Row(
                  children: [
                    _buildStatusCard('실내', '${_insideTemp.toStringAsFixed(1)}°C',
                        CupertinoIcons.thermometer, Colors.orangeAccent),
                    const SizedBox(width: 10),
                    _buildStatusCard('실외', '${_outsideTemp.toStringAsFixed(1)}°C',
                        CupertinoIcons.cloud_sun, Colors.blueAccent),
                    const SizedBox(width: 10),
                    _buildStatusCard('주행', '${_odometer.toInt()} km',
                        CupertinoIcons.speedometer, Colors.purpleAccent),
                  ],
                ),

                const SizedBox(height: 32),

                // 4. 퀵 액션 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ActionButton(
                      icon: _isLocked ? CupertinoIcons.lock_fill : CupertinoIcons.lock_open_fill,
                      label: _isLocked ? '잠금' : '열림',
                      isActive: !_isLocked,
                      onTap: _toggleLock,
                    ),
                    ActionButton(
                      icon: CupertinoIcons.snow,
                      label: '공조',
                      isActive: _isClimateOn,
                      onTap: _toggleClimate,
                    ),
                    ActionButton(
                      icon: CupertinoIcons.arrow_up_to_line,
                      label: '프렁크',
                      onTap: _openFrunk,
                    ),
                    ActionButton(
                      icon: CupertinoIcons.bolt_fill,
                      label: '충전',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('충전 포트를 엽니다. ⚡')),
                        );
                      },
                    ),
                    ActionButton(
                      icon: Icons.volume_up_rounded,
                      label: '경적',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('빵! 🔊')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
