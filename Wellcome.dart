import 'package:flutter/material.dart';
import 'dart:math' as math; // Import math cho hàm sin và pi

import '../model/User.dart'; // Import User model
import 'TaskListScreen.dart'; // Import TaskListScreen

// Lớp đại diện cho một hình tròn (bóng bay)
class FloatingCircle {
  final double size; // Kích thước (bán kính) của hình tròn
  final Color color; // Màu của hình tròn
  final double startX; // Vị trí X ban đầu (ngang, từ 0.0 đến 1.0)
  final double speed; // Tốc độ di chuyển lên (từ 0.0 đến 1.0, 1.0 là nhanh nhất)
  final double startTime; // Thời điểm bắt đầu trong chu kỳ animation (từ 0.0 đến 1.0)

  FloatingCircle({
    required this.size,
    required this.color,
    required this.startX,
    required this.speed,
    required this.startTime,
  });
}

// Lớp CustomPainter để vẽ nhiều hình tròn chuyển động liên tục
class FloatingCirclesPainter extends CustomPainter {
  final Animation<double> animation; // Animation để điều khiển tiến trình chung (từ 0.0 đến 1.0)
  final List<FloatingCircle> circles; // Danh sách các hình tròn cần vẽ

  FloatingCirclesPainter({required this.animation, required this.circles}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Lặp qua từng hình tròn trong danh sách
    for (var circle in circles) {
      final paint = Paint()
        ..color = circle.color // Sử dụng màu của hình tròn
        ..style = PaintingStyle.fill; // Tô đầy hình tròn

      // Tính toán tiến trình animation riêng cho từng hình tròn dựa trên thời điểm bắt đầu của nó
      // (animation.value - circle.startTime + 1.0) % 1.0: Đảm bảo tiến trình lặp lại từ 0.0 đến 1.0
      // và bắt đầu từ circle.startTime trong mỗi chu kỳ animation chung.
      double individualProgress = (animation.value - circle.startTime + 1.0) % 1.0;

      // Áp dụng tốc độ để xác định mức độ di chuyển thực tế trong chu kỳ này
      double effectiveProgress = individualProgress * circle.speed;

      // Tính toán vị trí Y hiện tại của hình tròn
      // Bắt đầu từ dưới màn hình (size.height + circle.size) và di chuyển lên đến ngoài màn hình (-circle.size)
      // Khoảng cách di chuyển tối đa cần thiết là chiều cao màn hình cộng với 2 lần bán kính hình tròn
      double distanceToTravel = size.height + 2 * circle.size;

      // Khoảng cách đã di chuyển lên trong chu kỳ hiện tại
      double distanceTraveled = effectiveProgress * distanceToTravel;

      // Vị trí Y hiện tại: Bắt đầu từ dưới và trừ đi khoảng cách đã di chuyển
      final double currentY = size.height + circle.size - distanceTraveled;

      // Vị trí X hiện tại (giữ nguyên vị trí X ban đầu)
      final double currentX = circle.startX * size.width;

      // Chỉ vẽ hình tròn nếu nó vẫn còn trong hoặc gần màn hình
      // Kiểm tra cả giới hạn dưới và giới hạn trên
      if (currentY > -circle.size && currentY < size.height + circle.size) {
        canvas.drawCircle(Offset(currentX, currentY), circle.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FloatingCirclesPainter oldDelegate) {
    // Chỉ vẽ lại khi animation.value hoặc danh sách hình tròn thay đổi
    return oldDelegate.animation.value != animation.value || oldDelegate.circles != circles;
  }
}


class Wellcome extends StatefulWidget {
  final User loggedInUser;

  const Wellcome({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  _WellcomeState createState() => _WellcomeState();
}

// DÙNG TickerProviderStateMixin VÌ CÓ NHIỀU AnimationController
class _WellcomeState extends State<Wellcome> with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation; // ANIMATION CHO XOAY TEXT

  late AnimationController _circlesAnimationController; // CONTROLLER CHO ANIMATION CÁC HÌNH TRÒN
  late Animation<double> _circlesAnimation; // ANIMATION CHO CÁC HÌNH TRÒN

  List<FloatingCircle> _floatingCircles = []; // DANH SÁCH CÁC HÌNH TRÒN


  @override
  void initState() {
    super.initState();

    // Khởi tạo danh sách các hình tròn
    _generateFloatingCircles(30);

    // Controller cho Text Animation (Fade, Scale, và Rotation)
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Thời gian animation text
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeIn),
    );

    // Animation Scale (phóng to vượt đà rồi ổn định)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1), // Zoom in vượt đà
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0), // Thu nhỏ lại về kích thước cuối
        weight: 40,
      ),
    ]).animate(CurvedAnimation(parent: _textAnimationController, curve: Curves.easeOutCubic));

    // ANIMATION CHO XOAY TEXT
    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate( // Xoay nhẹ từ -0.1 radian về 0 (thẳng)
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeOut),
    );

    // CONTROLLER VÀ ANIMATION CHO CÁC HÌNH TRÒN CHUYỂN ĐỘNG LIÊN TỤC
    _circlesAnimationController = AnimationController(
      duration: const Duration(seconds: 20), // Thời gian của một chu kỳ animation (điều chỉnh tốc độ chung)
      vsync: this, // Dùng cùng TickerProvider
    )..repeat(); // Lặp lại animation liên tục từ 0.0 đến 1.0

    _circlesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _circlesAnimationController, curve: Curves.linear), // Sử dụng Linear để chuyển động đều
    );


    // Bắt đầu Text Animation sau delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textAnimationController.forward();
      }
    });

    // Delay chuyển màn hình
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => TaskListScreen(loggedInUser: widget.loggedInUser)),
              (Route<dynamic> route) => false,
        );
      }
    });
  }

  // Hàm tạo danh sách các hình tròn ngẫu nhiên
  void _generateFloatingCircles(int count) {
    final random = math.Random();
    _floatingCircles = List.generate(count, (index) {
      return FloatingCircle(
        size: 8.0 + random.nextDouble() * 18.0, // Kích thước ngẫu nhiên từ 8 đến 26
        color: Colors.white.withOpacity(0.1 + random.nextDouble() * 0.2), // Màu trắng trong suốt ngẫu nhiên (trong suốt hơn)
        startX: random.nextDouble(), // Vị trí X ban đầu ngẫu nhiên (từ 0.0 đến 1.0 tương ứng với chiều rộng màn hình)
        speed: 0.6 + random.nextDouble() * 0.4, // Tốc độ ngẫu nhiên từ 0.4 đến 1.0
        startTime: random.nextDouble(), // Thời điểm bắt đầu ngẫu nhiên trong chu kỳ animation (0.0 đến 1.0)
      );
    });
  }


  @override
  void dispose() {
    _textAnimationController.dispose();
    _circlesAnimationController.dispose(); // DISPOSE CONTROLLER CÁC HÌNH TRÒN
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Hiển thị phía sau Status Bar
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Giữ Gradient làm nền chung
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [
              Color(0xFF60BAFA), // Màu xanh dương bạn cung cấp
              Color(0xFFFFE562), // Màu vàng bạn cung cấp
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            tileMode: TileMode.clamp,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // CUSTOMPAINT VẼ NHIỀU HÌNH TRÒN CHUYỂN ĐỘNG LIÊN TỤC
            Positioned.fill( // Đảm bảo CustomPaint lấp đầy toàn bộ Stack (toàn màn hình)
              child: CustomPaint(
                painter: FloatingCirclesPainter(
                  animation: _circlesAnimation, // Truyền animation chung lặp lại
                  circles: _floatingCircles, // Truyền danh sách các hình tròn
                ),
              ),
            ),


            // Phần văn bản và các animation của văn bản (ở lớp trên)
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition( // Hiệu ứng phóng to/thu nhỏ
                scale: _scaleAnimation,
                // WRAP VỚI RotationTransition ĐỂ THÊM HIỆU ỨNG XOAY
                child: RotationTransition(
                  turns: _rotationAnimation, // Sử dụng animation xoay
                  child: Text(
                    'Xin chào!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      // fontFamily: 'Schyler', // Giữ nguyên font
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black12,
                          offset: Offset(0, 5.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
