import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/send_auth_otp.dart';
import '../../domain/usecases/verify_auth_otp.dart';

/// ViewModel (MVVM + ChangeNotifier) untuk fitur Auth.
/// Hanya memanggil Use Cases, tidak pernah mengakses ApiService secara langsung.
class AuthViewModel extends ChangeNotifier {
  final LoginUser _loginUser;
  final SendAuthOtp _sendAuthOtp;
  final VerifyAuthOtp _verifyAuthOtp;
  final ResetPassword _resetPassword;

  AuthViewModel({
    required LoginUser loginUser,
    required SendAuthOtp sendAuthOtp,
    required VerifyAuthOtp verifyAuthOtp,
    required ResetPassword resetPassword,
  })  : _loginUser = loginUser,
        _sendAuthOtp = sendAuthOtp,
        _verifyAuthOtp = verifyAuthOtp,
        _resetPassword = resetPassword;

  bool _isRegisterMode = false;
  bool _isOtpStep = false;
  bool _isForgotStep = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isRegisterMode => _isRegisterMode;
  bool get isOtpStep => _isOtpStep;
  bool get isForgotStep => _isForgotStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _cleanError(Object e) => e
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Bad state: ', '');

  void switchMode(bool register) {
    _isRegisterMode = register;
    _isOtpStep = false;
    _isForgotStep = false;
    _errorMessage = null;
    notifyListeners();
  }

  void enterForgotPasswordMode() {
    _isForgotStep = true;
    _isOtpStep = false;
    _errorMessage = null;
    notifyListeners();
  }

  void exitSubStep() {
    _isOtpStep = false;
    _isForgotStep = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<AuthSession?> login({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _loginUser.execute(
        phone: phone,
        password: password,
      );
      return session;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtp({
    required String phone,
    required String type,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _sendAuthOtp.execute(phone: phone, type: type);
      _isOtpStep = true;
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthSession?> verifyRegistrationOtp({
    required String phone,
    required String otpCode,
    required String name,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _verifyAuthOtp.execute(
        phone: phone,
        otpCode: otpCode,
        name: name,
        password: password,
        isRegister: true,
      );
      return session;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitResetPassword({
    required String phone,
    required String otpCode,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _resetPassword.execute(
        phone: phone,
        otpCode: otpCode,
        newPassword: newPassword,
      );
      _isForgotStep = false;
      _isOtpStep = false;
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

