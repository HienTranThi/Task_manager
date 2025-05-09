import 'package:flutter/material.dart';
import '../model/User.dart';
import '../db/UserDatabaseHelper.dart';
import 'register.dart';
import 'TaskListScreen.dart';
import 'Wellcome.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _usernameErrorText;
  String? _passwordErrorText;

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _usernameErrorText = null;
      _passwordErrorText = null;
    });
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed (synchronous).");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final identifier = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final loginResult = await UserDatabaseHelper.instance.loginUser(identifier, password);

      switch (loginResult.status) {
        case LoginResultStatus.success:
          if (loginResult.user != null) {
            _showMessage("Đăng nhập thành công! Chào ${loginResult.user!.username} (${loginResult.user!.role})");
            setState(() {
              _usernameErrorText = null;
              _passwordErrorText = null;
            });
            // TRUYỀN USER: Điều hướng và truyền đối tượng User đã đăng nhập
            Navigator.pushReplacement(
              context,
              // Đây là nơi cần thay đổi TaskListScreen để nhận user
              MaterialPageRoute(builder: (context) => Wellcome(loggedInUser: loginResult.user!)), // <-- Pass user
            );
          } else {
            _showMessage("Đăng nhập thành công nhưng không lấy được thông tin người dùng.");
            print("Login success but user object is null.");
          }
          break;
        case LoginResultStatus.userNotFound:
          setState(() {
            _usernameErrorText = "Tên đăng nhập hoặc email không tồn tại.";
            _passwordErrorText = null;
          });
          break;
        case LoginResultStatus.incorrectPassword:
          setState(() {
            _passwordErrorText = "Mật khẩu không đúng.";
            _usernameErrorText = null;
          });
          break;
        case LoginResultStatus.error:
          _showMessage("Đã xảy ra lỗi trong quá trình đăng nhập. Vui lòng thử lại.");
          setState(() {
            _usernameErrorText = null;
            _passwordErrorText = null;
          });
          break;
      }

    } catch (e) {
      _showMessage("Đã xảy ra lỗi ngoại lệ không mong muốn: ${e.toString()}");
      print("Unexpected login error: ${e.toString()}");
      setState(() {
        _usernameErrorText = null;
        _passwordErrorText = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
                        "Login",
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
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Tên đăng nhập hoặc Email',
                          hintText: 'Nhập tên đăng nhập hoặc email',
                          prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                          errorText: _usernameErrorText,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên đăng nhập hoặc email';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (_usernameErrorText != null) {
                            setState(() {
                              _usernameErrorText = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Nhập mật khẩu',
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
                          errorText: _passwordErrorText,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (_passwordErrorText != null) {
                            setState(() {
                              _passwordErrorText = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement Forgot Password logic
                          },
                          child: Text(
                            "Quên mật khẩu?",
                            style: TextStyle(
                              color: accentPurple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

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
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.facebook, size: 40, color: Colors.blue.shade700),
                            onPressed: () {
                              // TODO: Implement Facebook login
                            },
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: Icon(Icons.g_mobiledata, size: 45, color: Colors.red.shade700),
                            onPressed: () {
                              // TODO: Implement Google login
                            },
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: Icon(Icons.email, size: 40, color: Colors.red.shade400),
                            onPressed: () {
                              // TODO: Implement Email login option or link
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Tạo tài khoản? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegisterScreen()),
                              );
                            },
                            child: Text(
                              "Đăng kí",
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