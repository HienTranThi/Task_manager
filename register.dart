import 'package:flutter/material.dart';
import '../model/User.dart';
import '../db/UserDatabaseHelper.dart';
import 'package:sqflite/sqflite.dart';
class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>(); // Để kiểm tra tính hợp lệ của form
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // Controller for confirm password

  String? _registrationMessage;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;


  // Phương thức đăng ký tài khoản mới
  void _register() async {
    FocusScope.of(context).unfocus();
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    // Kiểm tra nếu form hợp lệ
    if (_formKey.currentState?.validate() ?? false) {
      if (password != confirmPassword) {
        _showMessage("Mật khẩu xác nhận không khớp!");
        return;
      }

      setState(() {
        _isLoading = true;
        _registrationMessage = null;
      });

      try {
        // Tạo đối tượng User mới từ các trường thông tin
        final User newUser = User(
          username: username,
          email: email,
          password: password,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        // Gọi phương thức đăng ký từ UserDatabaseHelper
        // Phương thức createUser trong UserDatabaseHelper giờ trả về Future<String>
        String resultMessage = await UserDatabaseHelper.instance.createUser(newUser);
        // Cập nhật thông báo đăng ký từ kết quả trả về
        setState(() {
          _registrationMessage = resultMessage;
        });
        _showMessage(resultMessage); // Hiển thị thông báo qua SnackBar

        // Nếu kết quả trả về là thông báo thành công, điều hướng về màn hình Login
        if (resultMessage.contains('thành công')) {
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pop(context);
          });
        }

      } on DatabaseException catch (e) {
        setState(() {
          _registrationMessage = "Lỗi cơ sở dữ liệu: ${e.toString()}";
        });
        _showMessage("Lỗi cơ sở dữ liệu: ${e.toString()}");
        print("Database Error during registration: ${e.toString()}");

      } catch (e) {
        setState(() {
          _registrationMessage = "Đã xảy ra lỗi khi đăng ký: ${e.toString()}";
        });
        _showMessage("Đã xảy ra lỗi khi đăng ký: ${e.toString()}"); // Hiển thị cả qua SnackBar
        print("Registration Error: ${e.toString()}"); // Log lỗi ra console
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Hàm hiển thị thông báo cho người dùng (sử dụng SnackBar nhất quán với màn hình Login)
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3), // Tăng thời gian hiển thị
      ),
    );
  }


  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Dispose confirm password controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color accentPurple = Color(0xFF6A1B9A);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE1BEE7),
              Color(0xFFBBDEFB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Đăng Ký Tài Khoản",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: accentPurple,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: "Tên đăng nhập",
                          prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Vui lòng nhập tên đăng nhập!";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600), // Email icon
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Vui lòng nhập email!";
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return "Email không hợp lệ!";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Mật khẩu",
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        ),
                        obscureText: !_isPasswordVisible, // Toggle visibility
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Vui lòng nhập mật khẩu!";
                          }

                           if (value.length < 6) {
                            return "Mật khẩu phải có ít nhất 6 ký tự";
                           }
                          return null;
                        },
                      ),
                      SizedBox(height: 16), // Spacing before confirm password

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: "Xác nhận mật khẩu",
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        ),
                        obscureText: !_isConfirmPasswordVisible, // Toggle visibility
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Vui lòng xác nhận mật khẩu!";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),


                      _isLoading
                          ? Center(child: CircularProgressIndicator(color: accentPurple))
                          : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFAB47BC),
                              Color(0xFF6A1B9A),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            "Đăng Ký",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Hiển thị thông báo đăng ký
                      if (_registrationMessage != null) ...[
                        SizedBox(height: 16),
                        Text(
                          _registrationMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: _registrationMessage!.contains('thành công') ? Colors.green.shade700 : Colors.red.shade700, // Darker shades for better contrast
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Đã có tài khoản? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Đăng nhập",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: accentPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
