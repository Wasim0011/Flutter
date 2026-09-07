import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/push_notification_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? referralCode;

  const RegisterEvent({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.referralCode,
  });

  @override
  List<Object?> get props => [name, email, password, phone, referralCode];
}

class LogoutEvent extends AuthEvent {}

class LogoutAllEvent extends AuthEvent {}

class SendPhoneOtpEvent extends AuthEvent {
  final String phone;

  const SendPhoneOtpEvent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class VerifyPhoneOtpEvent extends AuthEvent {
  final String phone;
  final String code;
  final String? name;
  final String? referralCode;

  const VerifyPhoneOtpEvent({required this.phone, required this.code, this.name, this.referralCode});

  @override
  List<Object?> get props => [phone, code, name, referralCode];
}

class SendEmailOtpEvent extends AuthEvent {
  final String email;

  const SendEmailOtpEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class VerifyEmailOtpEvent extends AuthEvent {
  final String email;
  final String code;
  final String? name;
  final String? phone;
  final String? password;
  final String? referralCode;

  const VerifyEmailOtpEvent({
    required this.email,
    required this.code,
    this.name,
    this.phone,
    this.password,
    this.referralCode,
  });

  @override
  List<Object?> get props => [email, code, name, phone, password, referralCode];
}

class VerifyFirebaseTokenEvent extends AuthEvent {
  final String token;
  final String? phone;
  final String? name;
  final String? referralCode;

  const VerifyFirebaseTokenEvent({required this.token, this.phone, this.name, this.referralCode});

  @override
  List<Object?> get props => [token, phone, name, referralCode];
}

class UpdateProfileEvent extends AuthEvent {
  final String? name;
  final String? phone;
  final String? avatarPath;

  const UpdateProfileEvent({
    this.name,
    this.phone,
    this.avatarPath,
  });

  @override
  List<Object?> get props => [name, phone, avatarPath];
}

class FetchAuthConfigEvent extends AuthEvent {}

class DeleteAccountEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Emitted after OTP/Firebase verification when the account was just created.
/// The app should redirect to a profile completion screen.
class NewUserAuthenticated extends AuthState {
  final User user;
  final String? phone;

  const NewUserAuthenticated(this.user, {this.phone});

  @override
  List<Object?> get props => [user, phone];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class OtpSent extends AuthState {
  final String identifier; // phone or email
  final String type; // 'phone' or 'email'
  final Map<String, dynamic> data;

  const OtpSent({
    required this.identifier,
    required this.type,
    required this.data,
  });

  @override
  List<Object?> get props => [identifier, type, data];
}

class AuthConfigLoaded extends AuthState {
  final Map<String, dynamic> config;

  const AuthConfigLoaded(this.config);

  @override
  List<Object?> get props => [config];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Login _login;
  final Register _register;
  final Logout _logout;
  final LogoutAll _logoutAll;
  final CheckAuthStatus _checkAuthStatus;
  final GetCurrentUser _getCurrentUser;
  final UpdateProfile _updateProfile;
  final GetAuthConfig _getAuthConfig;
  final SendPhoneOtp _sendPhoneOtp;
  final VerifyPhoneOtp _verifyPhoneOtp;
  final SendEmailOtp _sendEmailOtp;
  final VerifyEmailOtp _verifyEmailOtp;
  final VerifyFirebaseToken _verifyFirebaseToken;
  final DeleteAccount _deleteAccount;

  AuthBloc(
    this._login,
    this._register,
    this._logout,
    this._logoutAll,
    this._checkAuthStatus,
    this._getCurrentUser,
    this._updateProfile,
    this._getAuthConfig,
    this._sendPhoneOtp,
    this._verifyPhoneOtp,
    this._sendEmailOtp,
    this._verifyEmailOtp,
    this._verifyFirebaseToken,
    this._deleteAccount,
  ) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<LogoutAllEvent>(_onLogoutAll);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<SendPhoneOtpEvent>(_onSendPhoneOtp);
    on<VerifyPhoneOtpEvent>(_onVerifyPhoneOtp);
    on<SendEmailOtpEvent>(_onSendEmailOtp);
    on<VerifyEmailOtpEvent>(_onVerifyEmailOtp);
    on<VerifyFirebaseTokenEvent>(_onVerifyFirebaseToken);
    on<FetchAuthConfigEvent>(_onFetchAuthConfig);
    on<DeleteAccountEvent>(_onDeleteAccount);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = _checkAuthStatus();

    if (isLoggedIn) {
      final result = await _getCurrentUser();
      result.fold(
        (failure) => emit(Unauthenticated()),
        (user) {
          emit(Authenticated(user));
          // Register FCM token on app start if logged in
          getIt<PushNotificationService>().uploadTokenToServer();
        },
      );
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await _login(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) {
        emit(Authenticated(authResult.user));
        // Register FCM token after login
        getIt<PushNotificationService>().uploadTokenToServer();
      },
    );
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await _register(
      name: event.name,
      email: event.email,
      password: event.password,
      phone: event.phone,
      referralCode: event.referralCode,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) {
        emit(Authenticated(authResult.user));
        // Register FCM token after registration
        getIt<PushNotificationService>().uploadTokenToServer();
      },
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _logout();
    emit(Unauthenticated());
  }

  Future<void> _onLogoutAll(LogoutAllEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _logoutAll();
    emit(Unauthenticated());
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<AuthState> emit) async {
    final currentState = state;
    // Allow update from both Authenticated and NewUserAuthenticated states
    if (currentState is! Authenticated && currentState is! NewUserAuthenticated) return;

    final result = await _updateProfile(
      name: event.name,
      phone: event.phone,
      avatarPath: event.avatarPath,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (updatedUser) {
        emit(Authenticated(updatedUser));
        // Re-upload FCM token now that we have a confirmed auth session
        getIt<PushNotificationService>().uploadTokenToServer();
      },
    );
  }

  Future<void> _onSendPhoneOtp(SendPhoneOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _sendPhoneOtp(event.phone);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (data) => emit(OtpSent(
        identifier: event.phone,
        type: 'phone',
        data: data,
      )),
    );
  }

  Future<void> _onVerifyPhoneOtp(VerifyPhoneOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _verifyPhoneOtp(event.phone, event.code, name: event.name, referralCode: event.referralCode);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) {
        if (authResult.isNewUser) {
          emit(NewUserAuthenticated(authResult.user, phone: event.phone));
        } else {
          emit(Authenticated(authResult.user));
        }
        // Delay slightly so storage write (token save) completes before upload
        Future.delayed(const Duration(milliseconds: 300), () {
          getIt<PushNotificationService>().uploadTokenToServer();
        });
      },
    );
  }

  Future<void> _onSendEmailOtp(SendEmailOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _sendEmailOtp(event.email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (data) => emit(OtpSent(
        identifier: event.email,
        type: 'email',
        data: data,
      )),
    );
  }

  Future<void> _onVerifyEmailOtp(VerifyEmailOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _verifyEmailOtp(
      event.email,
      event.code,
      name: event.name,
      phone: event.phone,
      password: event.password,
      referralCode: event.referralCode,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) {
        if (authResult.isNewUser) {
          emit(NewUserAuthenticated(authResult.user, phone: event.phone));
        } else {
          emit(Authenticated(authResult.user));
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          getIt<PushNotificationService>().uploadTokenToServer();
        });
      },
    );
  }

  Future<void> _onVerifyFirebaseToken(VerifyFirebaseTokenEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _verifyFirebaseToken(event.token, phone: event.phone, name: event.name, referralCode: event.referralCode);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) {
        if (authResult.isNewUser) {
          emit(NewUserAuthenticated(authResult.user, phone: event.phone));
        } else {
          emit(Authenticated(authResult.user));
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          getIt<PushNotificationService>().uploadTokenToServer();
        });
      },
    );
  }

  Future<void> _onFetchAuthConfig(FetchAuthConfigEvent event, Emitter<AuthState> emit) async {
    // Emit a dedicated loading state so pages show their config spinner.
    // Do NOT emit AuthLoading here — that state is shared with login/register
    // button spinners and would freeze the UI. Instead emit AuthConfigLoaded
    // directly; pages guard with their own _configLoaded flag.
    final result = await _getAuthConfig();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (config) => emit(AuthConfigLoaded(config)),
    );
  }

  Future<void> _onDeleteAccount(DeleteAccountEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _deleteAccount();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }
}
