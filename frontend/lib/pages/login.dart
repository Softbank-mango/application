import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import '../l10n/app_localizations.dart'; // 필요한 경우 주석 해제

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String _errorMessage = '';
  bool _isLoading = false;

  // 이미지에서 분석한 Toss 스타일 색상
  final Color _tossPrimary = Color(0xFF678AFB); // 로그인/회원가입 버튼, 텍스트 버튼
  final Color _tossBackground = Color(0xFFF7F9FC); // 전체 배경색
  final Color _textFieldFill = Colors.white; // 입력 필드 배경색
  final Color _textColor = Color(0xFF333333); // 일반 텍스트 색상 (이미지 기반 추정)
  final Color _hintColor = Color(0xFF999999); // 힌트 텍스트 색상 (이미지 기반 추정)

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = '이메일과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.code == 'user-not-found'
            ? '가입되지 않은 이메일입니다.'
            : e.code == 'wrong-password'
            ? '비밀번호가 틀렸습니다.'
            : '로그인 실패: ${e.message}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = '이메일과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _emailController.text.trim(),
        'displayName': 'New User',
        'role': 'user', // 기본 역할 할당
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.code == 'email-already-in-use'
            ? '이미 사용 중인 이메일입니다.'
            : '회원가입 실패: ${e.message}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold의 기본 TextTheme을 사용하여 폰트 스타일을 맞춥니다.
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Scaffold(
      // 1. 그라데이션 배경을 적용하기 위해 Container로 감쌉니다.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEFF6FF), // 0% (좌상단)
              Color(0xFFFAF5FF), // 100% (우하단)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // 2. 데스크톱 웹을 위해 콘텐츠를 중앙에 배치합니다.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            // 3. (디자인 원칙) 폼의 최대 너비를 450px로 제한합니다.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // --- 4. 카드 바깥 영역 (상단) ---
                  // 이미지와 같이 로고, 타이틀은 카드 바깥에 위치합니다.
                  Image.asset('assets/logo.png', height: 80, width: 80, fit: BoxFit.contain,),
                  // 로컬 assets 경로에 따라 수정 필요
                  const SizedBox(height: 12),
                  Text(
                    'Deplight',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PaaS 대시보드 플랫폼에 로그인하세요.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: _textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- 5. 흰색 카드 영역 ---
                  // 이메일, 비밀번호, 버튼 등 폼 요소만 흰색 카드 안에 배치합니다.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white, // 흰색 카드 배경
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          label: '이메일',
                          hint: 'your@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: '비밀번호',
                          hint: '*********',
                          obscureText: true,
                        ),
                        const SizedBox(height: 8),

                        // 로그인 유지 / 비밀번호 찾기
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _rememberMe = newValue!;
                                      });
                                    },
                                    activeColor: _tossPrimary,
                                    materialTapTargetSize: MaterialTapTargetSize
                                        .shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  child: Text('로그인 상태 유지',
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: _textColor)),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                /* 비밀번호 찾기 로직 */
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('비밀번호 찾기', style: TextStyle(
                                  color: _tossPrimary, fontSize: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 오류 메시지
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // 로그인 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _tossPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              textStyle: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                                : const Text('로그인'),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 회원가입
                        TextButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: '계정이 없으신가요? ',
                              style: textTheme.bodyMedium?.copyWith(
                                  color: _hintColor, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: '회원가입',
                                  style: TextStyle(color: _tossPrimary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- 흰색 카드 영역 끝 ---

                  // --- 6. 카드 바깥 영역 (하단) ---
                  const SizedBox(height: 40),
                  Text(
                    'Firebase 인증을 통한 안전한 로그인',
                    style: textTheme.bodySmall?.copyWith(
                        color: _hintColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // (수정) TextField가 흰색 카드 위에 있으므로, 배경색을 _tossBackground로 변경
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    final textTheme = Theme
        .of(context)
        .textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            color: _textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: textTheme.bodyLarge?.copyWith(color: _textColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyLarge?.copyWith(
                color: _hintColor, fontSize: 16),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 18, horizontal: 16),
            filled: true,
            fillColor: _tossBackground,
            // (카드(흰색)와 구분되는 배경색)
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // (테두리 없음)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _tossPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            enabledBorder: OutlineInputBorder( // (기본 테두리 없음)
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}