import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../state/app_state.dart';
import '../../../../utils/validators.dart';
import '../viewmodels/auth_view_model.dart';

class AuthView extends StatefulWidget {
  final AppState state;
  final AuthViewModel? viewModel;

  const AuthView({
    super.key,
    required this.state,
    this.viewModel,
  });

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  late final AuthViewModel _viewModel;
  late final bool _ownsViewModel;

  final TextEditingController phone = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final TextEditingController otpCode = TextEditingController();
  final TextEditingController newPass = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? getIt<AuthViewModel>();
  }

  @override
  void dispose() {
    phone.dispose();
    name.dispose();
    pass.dispose();
    otpCode.dispose();
    newPass.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    _viewModel.clearError();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_viewModel.isForgotStep && !_viewModel.isRegisterMode) {
      final session = await _viewModel.login(
        phone: phone.text.trim(),
        password: pass.text.trim(),
      );
      if (session != null) {
        await widget.state.applySession(session);
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
      return;
    }

    if (_viewModel.isRegisterMode) {
      await _viewModel.sendOtp(phone: phone.text.trim(), type: 'register');
      return;
    }

    if (_viewModel.isForgotStep) {
      await _viewModel.sendOtp(phone: phone.text.trim(), type: 'forgot');
      return;
    }
  }

  Future<void> verifyAndSubmit() async {
    FocusScope.of(context).unfocus();
    _viewModel.clearError();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_viewModel.isForgotStep) {
      final ok = await _viewModel.submitResetPassword(
        phone: phone.text.trim(),
        otpCode: otpCode.text.trim(),
        newPassword: newPass.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah! Silakan masuk.'),
            backgroundColor: green,
          ),
        );
        otpCode.clear();
        newPass.clear();
        pass.clear();
      }
      return;
    }

    final session = await _viewModel.verifyRegistrationOtp(
      phone: phone.text.trim(),
      otpCode: otpCode.text.trim(),
      name: name.text.trim(),
      password: pass.text.trim(),
    );
    if (session != null) {
      await widget.state.applySession(session);
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void switchMode(bool isRegister) {
    _viewModel.switchMode(isRegister);
    name.clear();
    phone.clear();
    pass.clear();
    otpCode.clear();
    newPass.clear();
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final register = _viewModel.isRegisterMode;
        final isOtpStep = _viewModel.isOtpStep;
        final isForgotStep = _viewModel.isForgotStep;
        final busy = _viewModel.isLoading;
        final error = _viewModel.errorMessage;

        return Scaffold(
          backgroundColor: brown,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOMBOL BACK & HEADER ATAS
                      Row(
                        children: [
                          if (Navigator.of(context).canPop() ||
                              isOtpStep ||
                              isForgotStep) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: brown2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: border),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  if (isOtpStep || isForgotStep) {
                                    _viewModel.exitSubStep();
                                  } else if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                tooltip: 'Kembali',
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: green,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.center,
                            child: const Text('PL',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Puthu Lanang',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text('Mobile Smart Takeaway App',
                                  style: TextStyle(color: muted, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // LOGO TENGAH & JUDUL
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: green,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(Icons.local_fire_department,
                                    color: brown, size: 34),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isForgotStep
                                  ? 'Pulihkan Password'
                                  : (isOtpStep
                                      ? 'Verifikasi WhatsApp'
                                      : 'Puthu Lanang Malang'),
                              style: const TextStyle(
                                  color: cream,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isForgotStep
                                  ? 'Masukkan nomor WA untuk reset sandi'
                                  : (isOtpStep
                                      ? 'Masukkan 4 digit kode yang dikirim via WA'
                                      : 'Pelanggan End-User Mobile App'),
                              style: const TextStyle(
                                  color: gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // KARTU UTAMA FORM
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: brown2,
                          border: Border.all(color: border),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!isOtpStep && !isForgotStep) ...[
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: brown,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: busy
                                              ? null
                                              : () => switchMode(false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: !register
                                                  ? green
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4),
                                                child: Text(
                                                  'Masuk Akun',
                                                  style: TextStyle(
                                                      color: !register
                                                          ? Colors.white
                                                          : muted,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: busy
                                              ? null
                                              : () => switchMode(true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: register
                                                  ? green
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4),
                                                child: Text(
                                                  'Daftar Akun Baru',
                                                  style: TextStyle(
                                                      color: register
                                                          ? Colors.white
                                                          : muted,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              if (isOtpStep) ...[
                                _field(
                                  label: 'KODE OTP (4 DIGIT)',
                                  controller: otpCode,
                                  icon: Icons.lock_clock_outlined,
                                  keyboardType: TextInputType.number,
                                  hint: 'Masukkan kode OTP',
                                  inputFormatters: [
                                    ...Validators.digitsOnly,
                                    LengthLimitingTextInputFormatter(4)
                                  ],
                                  validator: (v) =>
                                      Validators.otp(v, length: 4),
                                ),
                                if (isForgotStep)
                                  _field(
                                    label: 'KATA SANDI BARU',
                                    controller: newPass,
                                    icon: Icons.lock_reset,
                                    obscure: true,
                                    hint: 'Password baru (min. 6 karakter)',
                                    validator: (v) => Validators.password(v,
                                        fieldName: 'Kata sandi baru',
                                        minLength: 6),
                                  ),
                              ] else ...[
                                if (register)
                                  _field(
                                    label: 'NAMA LENGKAP',
                                    controller: name,
                                    icon: Icons.person_outline,
                                    hint: 'Nama Anda',
                                    keyboardType: TextInputType.name,
                                    validator: (v) => Validators.name(v,
                                        fieldName: 'Nama lengkap'),
                                  ),
                                _field(
                                  label: 'NOMOR WHATSAPP',
                                  controller: phone,
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  hint: 'Nomor WhatsApp Anda',
                                  inputFormatters: Validators.digitsOnly,
                                  validator: (v) => Validators.phone(v),
                                ),
                                if (!isForgotStep)
                                  _field(
                                    label: register ? 'KATA SANDI' : 'PASSWORD',
                                    controller: pass,
                                    icon: Icons.lock_outline,
                                    obscure: true,
                                    hint: 'Kata Sandi Anda',
                                    validator: (v) => Validators.password(
                                      v,
                                      fieldName:
                                          register ? 'Kata sandi' : 'Password',
                                      minLength: register ? 6 : 0,
                                    ),
                                  ),
                                if (!register && !isForgotStep)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: busy
                                          ? null
                                          : () {
                                              pass.clear();
                                              _viewModel
                                                  .enterForgotPasswordMode();
                                            },
                                      child: const Text(
                                        'Lupa Password?',
                                        style: TextStyle(
                                            color: gold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],

                              if (error != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.redAccent
                                            .withValues(alpha: 0.30)),
                                  ),
                                  child: Text(error,
                                      style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12)),
                                ),

                              const SizedBox(height: 8),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: busy
                                      ? null
                                      : (isOtpStep ? verifyAndSubmit : submit),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        busy
                                            ? 'Memproses...'
                                            : isOtpStep
                                                ? (isForgotStep
                                                    ? 'Reset Password'
                                                    : 'Verifikasi & Daftar')
                                                : (!register
                                                    ? 'Masuk Sekarang'
                                                    : 'Kirim Kode OTP'),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('→',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required FormFieldValidator<String> validator,
    bool obscure = false,
    TextInputType? keyboardType,
    String? hint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(color: cream, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: muted.withValues(alpha: 0.5)),
              prefixIcon: Icon(icon, color: gold, size: 20),
              filled: true,
              fillColor: brown,
              border: outline(border),
              enabledBorder: outline(border),
              focusedBorder: outline(gold, 1.5),
              errorBorder: outline(Colors.redAccent),
              focusedErrorBorder: outline(Colors.redAccent, 1.5),
              errorStyle:
                  const TextStyle(color: Colors.redAccent, fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

